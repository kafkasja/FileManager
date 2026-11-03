#include "windows_channel.h"

#include <flutter/standard_method_codec.h>
#include <knownfolders.h>
#include <netlistmgr.h>
#include <objbase.h>
#include <sherrors.h>
#include <shlobj.h>
#include <shobjidl.h>
#include <wincodec.h>
#include <wrl/client.h>

#include <condition_variable>
#include <cstring>
#include <deque>
#include <map>
#include <mutex>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;
using Microsoft::WRL::ComPtr;

namespace {

// ---- errors ----

// Thrown by worker code; replied as PlatformException(code, message).
struct ChannelError : std::runtime_error {
  ChannelError(std::string code, const std::string& message)
      : std::runtime_error(message), code(std::move(code)) {}
  std::string code;
};

// ---- strings ----

std::wstring Wide(const std::string& utf8) {
  if (utf8.empty()) return std::wstring();
  int n = ::MultiByteToWideChar(CP_UTF8, 0, utf8.data(),
                                static_cast<int>(utf8.size()), nullptr, 0);
  std::wstring out(n, L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()),
                        out.data(), n);
  return out;
}

std::string Utf8(const std::wstring& wide) {
  if (wide.empty()) return std::string();
  int n = ::WideCharToMultiByte(CP_UTF8, 0, wide.data(),
                                static_cast<int>(wide.size()), nullptr, 0,
                                nullptr, nullptr);
  std::string out(n, '\0');
  ::WideCharToMultiByte(CP_UTF8, 0, wide.data(), static_cast<int>(wide.size()),
                        out.data(), n, nullptr, nullptr);
  return out;
}

std::string HrMessage(HRESULT hr) {
  wchar_t* text = nullptr;
  ::FormatMessageW(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
                       FORMAT_MESSAGE_IGNORE_INSERTS,
                   nullptr, static_cast<DWORD>(hr), 0,
                   reinterpret_cast<LPWSTR>(&text), 0, nullptr);
  std::string msg;
  if (text) {
    msg = Utf8(text);
    ::LocalFree(text);
    while (!msg.empty() && (msg.back() == '\n' || msg.back() == '\r')) {
      msg.pop_back();
    }
  }
  char hex[16];
  snprintf(hex, sizeof(hex), "0x%08lX", static_cast<unsigned long>(hr));
  return msg.empty() ? std::string(hex) : msg + " (" + hex + ")";
}

void Check(HRESULT hr, const char* what) {
  if (FAILED(hr)) {
    throw ChannelError("COM", std::string(what) + ": " + HrMessage(hr));
  }
}

bool SamePath(const std::wstring& a, const std::wstring& b) {
  return ::CompareStringOrdinal(a.c_str(), static_cast<int>(a.size()),
                                b.c_str(), static_cast<int>(b.size()),
                                TRUE) == CSTR_EQUAL;
}

std::wstring ItemName(IShellItem* item, SIGDN kind) {
  if (!item) return std::wstring();
  PWSTR name = nullptr;
  if (FAILED(item->GetDisplayName(kind, &name)) || !name) return std::wstring();
  std::wstring out(name);
  ::CoTaskMemFree(name);
  return out;
}

// File system path of an item, else its absolute parsing name.
std::wstring ItemPath(IShellItem* item) {
  std::wstring path = ItemName(item, SIGDN_FILESYSPATH);
  return path.empty() ? ItemName(item, SIGDN_DESKTOPABSOLUTEPARSING) : path;
}

int64_t FileTimeToMs(const FILETIME& ft) {
  ULARGE_INTEGER v;
  v.LowPart = ft.dwLowDateTime;
  v.HighPart = ft.dwHighDateTime;
  // 100 ns ticks since 1601-01-01 → ms since 1970-01-01.
  return static_cast<int64_t>((v.QuadPart - 116444736000000000ULL) / 10000ULL);
}

// ---- arguments ----

const EncodableMap& ArgsMap(const EncodableValue* args) {
  static const EncodableMap empty;
  if (!args) return empty;
  if (const auto* m = std::get_if<EncodableMap>(args)) return *m;
  return empty;
}

std::vector<std::wstring> StringList(const EncodableMap& args,
                                     const char* key) {
  std::vector<std::wstring> out;
  auto it = args.find(EncodableValue(key));
  if (it == args.end()) return out;
  if (const auto* list = std::get_if<EncodableList>(&it->second)) {
    for (const auto& v : *list) {
      if (const auto* s = std::get_if<std::string>(&v)) out.push_back(Wide(*s));
    }
  }
  return out;
}

std::wstring StringArg(const EncodableMap& args, const char* key) {
  auto it = args.find(EncodableValue(key));
  if (it == args.end()) return std::wstring();
  if (const auto* s = std::get_if<std::string>(&it->second)) return Wide(*s);
  return std::wstring();
}

int64_t IntArg(const EncodableMap& args, const char* key, int64_t fallback) {
  auto it = args.find(EncodableValue(key));
  if (it == args.end()) return fallback;
  if (const auto* i = std::get_if<int32_t>(&it->second)) return *i;
  if (const auto* l = std::get_if<int64_t>(&it->second)) return *l;
  return fallback;
}

// ---- volumes / Recycle Bin availability ----

std::wstring VolumeRoot(const std::wstring& path) {
  wchar_t root[MAX_PATH + 1] = {};
  if (!::GetVolumePathNameW(path.c_str(), root, MAX_PATH)) return std::wstring();
  return root;
}

// Per-volume bin settings under
// HKCU\...\Explorer\BitBucket\Volume\{GUID}: NukeOnDelete, MaxCapacity (MB).
struct BinSettings {
  bool usable = false;
  // 0 = unknown.
  uint64_t maxBytes = 0;
};

BinSettings QueryBin(const std::wstring& root) {
  BinSettings s;
  if (root.empty()) return s;
  switch (::GetDriveTypeW(root.c_str())) {
    case DRIVE_FIXED:
    case DRIVE_REMOVABLE:
    case DRIVE_RAMDISK:
      break;
    default:  // remote, CD-ROM, unknown, no root
      return s;
  }
  SHQUERYRBINFO info = {};
  info.cbSize = sizeof(info);
  if (FAILED(::SHQueryRecycleBinW(root.c_str(), &info))) return s;
  s.usable = true;
  wchar_t volume[MAX_PATH] = {};
  if (::GetVolumeNameForVolumeMountPointW(root.c_str(), volume, MAX_PATH)) {
    // "\\?\Volume{GUID}\" → "{GUID}"
    std::wstring v(volume);
    auto open = v.find(L'{');
    auto close = v.find(L'}');
    if (open != std::wstring::npos && close != std::wstring::npos) {
      std::wstring key =
          L"Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\BitBucket\\"
          L"Volume\\" +
          v.substr(open, close - open + 1);
      DWORD value = 0;
      DWORD size = sizeof(value);
      if (::RegGetValueW(HKEY_CURRENT_USER, key.c_str(), L"NukeOnDelete",
                         RRF_RT_REG_DWORD, nullptr, &value,
                         &size) == ERROR_SUCCESS &&
          value != 0) {
        s.usable = false;
      }
      size = sizeof(value);
      if (::RegGetValueW(HKEY_CURRENT_USER, key.c_str(), L"MaxCapacity",
                         RRF_RT_REG_DWORD, nullptr, &value,
                         &size) == ERROR_SUCCESS) {
        s.maxBytes = static_cast<uint64_t>(value) * 1024ULL * 1024ULL;
      }
    }
  }
  return s;
}

// ---- results ----

const char* BinErrorFor(HRESULT hr) {
  switch (hr) {
    case HRESULT_FROM_WIN32(ERROR_SHARING_VIOLATION):
    case HRESULT_FROM_WIN32(ERROR_LOCK_VIOLATION):
    case COPYENGINE_E_SHARING_VIOLATION_SRC:
    case COPYENGINE_E_SHARING_VIOLATION_DEST:
      return "inUse";
    case HRESULT_FROM_WIN32(ERROR_FILE_NOT_FOUND):
    case HRESULT_FROM_WIN32(ERROR_PATH_NOT_FOUND):
    case COPYENGINE_E_PATH_NOT_FOUND_SRC:
      return "notFound";
    case E_ACCESSDENIED:
    case COPYENGINE_E_ACCESS_DENIED_SRC:
    case COPYENGINE_E_ACCESS_DENIED_DEST:
      return "permissionDenied";
    case COPYENGINE_S_USER_IGNORED:
    case COPYENGINE_E_USER_CANCELLED:
    case COPYENGINE_E_RECYCLE_UNKNOWN_ERROR:
    case COPYENGINE_E_RECYCLE_FORCE_NUKE:
    case COPYENGINE_E_RECYCLE_SIZE_TOO_BIG:
    case COPYENGINE_E_RECYCLE_PATH_TOO_LONG:
    case COPYENGINE_E_RECYCLE_BIN_NOT_FOUND:
      return "noTrash";
    default:
      return "ioError";
  }
}

// One path of a recycle/restore call.
struct ItemResult {
  std::wstring key;  // the path / trashId as the caller passed it
  std::wstring match;  // the item's own path, to recognise sink callbacks
  bool done = false;
  std::wstring landed;  // trashId (recycle) or new path (restore)
  std::string error;
  std::string message;
};

ItemResult* FindItem(std::vector<ItemResult>& items, IShellItem* item) {
  std::wstring path = ItemPath(item);
  if (path.empty()) return nullptr;
  for (auto& r : items) {
    if (!r.done && SamePath(r.match, path)) return &r;
  }
  return nullptr;
}

// Collects PostDeleteItem / PostMoveItem per item.
class ProgressSink : public IFileOperationProgressSink {
 public:
  explicit ProgressSink(std::vector<ItemResult>& items) : items_(items) {}

  IFACEMETHODIMP QueryInterface(REFIID riid, void** ppv) override {
    if (riid == IID_IUnknown || riid == IID_IFileOperationProgressSink) {
      *ppv = static_cast<IFileOperationProgressSink*>(this);
      AddRef();
      return S_OK;
    }
    *ppv = nullptr;
    return E_NOINTERFACE;
  }
  IFACEMETHODIMP_(ULONG) AddRef() override { return ++refs_; }
  IFACEMETHODIMP_(ULONG) Release() override {
    ULONG r = --refs_;
    if (r == 0) delete this;
    return r;
  }

  IFACEMETHODIMP PostDeleteItem(DWORD, IShellItem* item, HRESULT hr,
                                IShellItem* newly_created) override {
    ItemResult* r = FindItem(items_, item);
    if (!r) return S_OK;
    r->done = true;
    // Success codes include COPYENGINE_S_DONT_PROCESS_CHILDREN (a recycled
    // item); COPYENGINE_S_USER_IGNORED means it was skipped.
    bool ok = SUCCEEDED(hr) && hr != COPYENGINE_S_USER_IGNORED;
    if (ok && newly_created) {
      r->landed = ItemPath(newly_created);
      if (r->landed.empty()) {
        r->error = "ioError";
        r->message = "recycled, but the bin item has no path";
      }
    } else if (ok) {
      // Not recycled: Windows deleted it for good (bin full / turned off
      // after the check, and the user agreed in Windows' own warning).
      r->error = "ioError";
      r->message = "Windows deleted the file permanently instead of recycling it";
    } else {
      r->error = BinErrorFor(hr);
      r->message = HrMessage(hr);
    }
    return S_OK;
  }

  IFACEMETHODIMP PostMoveItem(DWORD, IShellItem* item, IShellItem*, LPCWSTR,
                              HRESULT hr, IShellItem* newly_created) override {
    ItemResult* r = FindItem(items_, item);
    if (!r) return S_OK;
    r->done = true;
    if (SUCCEEDED(hr) && hr != COPYENGINE_S_USER_IGNORED && newly_created) {
      r->landed = ItemPath(newly_created);
    } else {
      r->error = SUCCEEDED(hr) ? "ioError" : BinErrorFor(hr);
      r->message = SUCCEEDED(hr) ? "not moved" : HrMessage(hr);
    }
    return S_OK;
  }

  IFACEMETHODIMP StartOperations() override { return S_OK; }
  IFACEMETHODIMP FinishOperations(HRESULT) override { return S_OK; }
  IFACEMETHODIMP PreRenameItem(DWORD, IShellItem*, LPCWSTR) override {
    return S_OK;
  }
  IFACEMETHODIMP PostRenameItem(DWORD, IShellItem*, LPCWSTR, HRESULT,
                                IShellItem*) override {
    return S_OK;
  }
  IFACEMETHODIMP PreMoveItem(DWORD, IShellItem*, IShellItem*,
                             LPCWSTR) override {
    return S_OK;
  }
  IFACEMETHODIMP PreCopyItem(DWORD, IShellItem*, IShellItem*,
                             LPCWSTR) override {
    return S_OK;
  }
  IFACEMETHODIMP PostCopyItem(DWORD, IShellItem*, IShellItem*, LPCWSTR,
                              HRESULT, IShellItem*) override {
    return S_OK;
  }
  IFACEMETHODIMP PreDeleteItem(DWORD, IShellItem*) override { return S_OK; }
  IFACEMETHODIMP PreNewItem(DWORD, IShellItem*, LPCWSTR) override {
    return S_OK;
  }
  IFACEMETHODIMP PostNewItem(DWORD, IShellItem*, LPCWSTR, LPCWSTR, DWORD,
                             HRESULT, IShellItem*) override {
    return S_OK;
  }
  IFACEMETHODIMP UpdateProgress(UINT, UINT) override { return S_OK; }
  IFACEMETHODIMP ResetTimer() override { return S_OK; }
  IFACEMETHODIMP PauseTimer() override { return S_OK; }
  IFACEMETHODIMP ResumeTimer() override { return S_OK; }

 private:
  ~ProgressSink() = default;
  std::vector<ItemResult>& items_;
  ULONG refs_ = 1;
};

const DWORD kQuietFlags = FOF_NOCONFIRMATION | FOF_SILENT | FOF_NOERRORUI |
                          FOF_NOCONFIRMMKDIR;

// Runs [op] with a sink over [items]; items the sink never saw fail.
void Perform(IFileOperation* op, std::vector<ItemResult>& items) {
  ProgressSink* sink = new ProgressSink(items);
  DWORD cookie = 0;
  Check(op->Advise(sink, &cookie), "Advise");
  HRESULT hr = op->PerformOperations();
  op->Unadvise(cookie);
  sink->Release();
  for (auto& r : items) {
    if (r.done) continue;
    r.done = true;
    if (r.error.empty()) {
      r.error = "ioError";
      r.message = FAILED(hr) ? HrMessage(hr) : "not processed";
    }
  }
}

EncodableValue ResultList(const std::vector<ItemResult>& items,
                          const char* key_name, const char* landed_name) {
  EncodableList out;
  for (const auto& r : items) {
    EncodableMap m;
    m[EncodableValue(key_name)] = EncodableValue(Utf8(r.key));
    if (r.error.empty()) {
      m[EncodableValue(landed_name)] = EncodableValue(Utf8(r.landed));
    } else {
      m[EncodableValue("error")] = EncodableValue(r.error);
      m[EncodableValue("message")] = EncodableValue(r.message);
    }
    out.emplace_back(std::move(m));
  }
  return EncodableValue(std::move(out));
}

ComPtr<IFileOperation> NewFileOperation(DWORD flags) {
  ComPtr<IFileOperation> op;
  Check(::CoCreateInstance(CLSID_FileOperation, nullptr, CLSCTX_ALL,
                           IID_PPV_ARGS(&op)),
        "CoCreateInstance(FileOperation)");
  Check(op->SetOperationFlags(flags), "SetOperationFlags");
  return op;
}

ComPtr<IShellItem> ItemFor(const std::wstring& path, HRESULT* hr_out) {
  ComPtr<IShellItem> item;
  *hr_out = ::SHCreateItemFromParsingName(path.c_str(), nullptr,
                                          IID_PPV_ARGS(&item));
  return item;
}

// ---- $I files (Recycle Bin metadata) ----

// Bin items are `$R<id>.<ext>` with a `$I<id>.<ext>` beside them holding the
// original path, size and deletion time (version 1: Vista–8.1, fixed 260
// chars; version 2: Windows 10+, length-prefixed).
struct BinInfo {
  std::wstring originalPath;
  int64_t size = 0;
  int64_t deletedAtMs = 0;
};

std::wstring InfoPathFor(const std::wstring& r_path) {
  auto slash = r_path.find_last_of(L'\\');
  size_t name = slash == std::wstring::npos ? 0 : slash + 1;
  if (r_path.size() < name + 2 || r_path.compare(name, 2, L"$R") != 0) {
    return std::wstring();
  }
  std::wstring i_path = r_path;
  i_path[name + 1] = L'I';
  return i_path;
}

bool ReadBinInfo(const std::wstring& r_path, BinInfo* info) {
  std::wstring i_path = InfoPathFor(r_path);
  if (i_path.empty()) return false;
  HANDLE f = ::CreateFileW(i_path.c_str(), GENERIC_READ,
                           FILE_SHARE_READ | FILE_SHARE_DELETE, nullptr,
                           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (f == INVALID_HANDLE_VALUE) return false;
  std::vector<uint8_t> data(4096);
  DWORD read = 0;
  BOOL ok = ::ReadFile(f, data.data(), static_cast<DWORD>(data.size()), &read,
                       nullptr);
  ::CloseHandle(f);
  if (!ok || read < 24) return false;
  int64_t version, size;
  FILETIME ft;
  std::memcpy(&version, data.data(), 8);
  std::memcpy(&size, data.data() + 8, 8);
  std::memcpy(&ft, data.data() + 16, 8);
  const wchar_t* chars = nullptr;
  size_t max_chars = 0;
  if (version == 1) {
    chars = reinterpret_cast<const wchar_t*>(data.data() + 24);
    max_chars = (read - 24) / sizeof(wchar_t);
  } else if (version == 2 && read >= 28) {
    uint32_t len;
    std::memcpy(&len, data.data() + 24, 4);
    chars = reinterpret_cast<const wchar_t*>(data.data() + 28);
    max_chars = (std::min)(static_cast<size_t>(len),
                           static_cast<size_t>((read - 28) / sizeof(wchar_t)));
  } else {
    return false;
  }
  size_t n = 0;
  while (n < max_chars && chars[n] != L'\0') n++;
  if (n == 0) return false;
  info->originalPath.assign(chars, n);
  info->size = size;
  info->deletedAtMs = FileTimeToMs(ft);
  return true;
}

// ---- methods ----

EncodableValue KnownFolders() {
  struct Entry {
    const char* name;
    REFKNOWNFOLDERID id;
  };
  const Entry entries[] = {
      {"pictures", FOLDERID_Pictures},
      {"videos", FOLDERID_Videos},
      {"downloads", FOLDERID_Downloads},
      {"documents", FOLDERID_Documents},
  };
  EncodableMap out;
  for (const auto& e : entries) {
    PWSTR path = nullptr;
    if (SUCCEEDED(::SHGetKnownFolderPath(e.id, KF_FLAG_DEFAULT, nullptr,
                                         &path)) &&
        path) {
      out[EncodableValue(e.name)] = EncodableValue(Utf8(path));
    } else {
      out[EncodableValue(e.name)] = EncodableValue();
    }
    ::CoTaskMemFree(path);
  }
  return EncodableValue(std::move(out));
}

EncodableValue BinAvailable(const std::vector<std::wstring>& paths) {
  std::map<std::wstring, bool> by_root;
  EncodableMap out;
  for (const auto& p : paths) {
    std::wstring root = VolumeRoot(p);
    auto it = by_root.find(root);
    if (it == by_root.end()) {
      it = by_root.emplace(root, QueryBin(root).usable).first;
    }
    out[EncodableValue(Utf8(p))] = EncodableValue(it->second);
  }
  return EncodableValue(std::move(out));
}

EncodableValue Recycle(const std::vector<std::wstring>& paths) {
  std::vector<ItemResult> items(paths.size());
  std::map<std::wstring, BinSettings> by_root;
  ComPtr<IFileOperation> op =
      NewFileOperation(kQuietFlags | FOF_ALLOWUNDO | FOFX_RECYCLEONDELETE |
                       FOF_WANTNUKEWARNING);
  bool any = false;
  for (size_t i = 0; i < paths.size(); i++) {
    ItemResult& r = items[i];
    r.key = paths[i];
    WIN32_FILE_ATTRIBUTE_DATA attrs;
    if (!::GetFileAttributesExW(paths[i].c_str(), GetFileExInfoStandard,
                                &attrs)) {
      HRESULT hr = HRESULT_FROM_WIN32(::GetLastError());
      r.done = true;
      r.error = BinErrorFor(hr);
      r.message = HrMessage(hr);
      continue;
    }
    std::wstring root = VolumeRoot(paths[i]);
    auto it = by_root.find(root);
    if (it == by_root.end()) it = by_root.emplace(root, QueryBin(root)).first;
    uint64_t size = (static_cast<uint64_t>(attrs.nFileSizeHigh) << 32) |
                    attrs.nFileSizeLow;
    if (!it->second.usable ||
        (it->second.maxBytes != 0 && size > it->second.maxBytes)) {
      r.done = true;
      r.error = "noTrash";
      r.message = it->second.usable ? "too large for the Recycle Bin"
                                    : "this drive has no Recycle Bin";
      continue;
    }
    HRESULT hr;
    ComPtr<IShellItem> item = ItemFor(paths[i], &hr);
    if (FAILED(hr)) {
      r.done = true;
      r.error = BinErrorFor(hr);
      r.message = HrMessage(hr);
      continue;
    }
    r.match = ItemPath(item.Get());
    hr = op->DeleteItem(item.Get(), nullptr);
    if (FAILED(hr)) {
      r.done = true;
      r.error = BinErrorFor(hr);
      r.message = HrMessage(hr);
      continue;
    }
    any = true;
  }
  if (any) Perform(op.Get(), items);
  return ResultList(items, "path", "trashId");
}

EncodableValue ListBin() {
  ComPtr<IShellItem> bin;
  Check(::SHGetKnownFolderItem(FOLDERID_RecycleBinFolder, KF_FLAG_DEFAULT,
                               nullptr, IID_PPV_ARGS(&bin)),
        "Recycle Bin folder");
  ComPtr<IEnumShellItems> items;
  Check(bin->BindToHandler(nullptr, BHID_EnumItems, IID_PPV_ARGS(&items)),
        "enumerate Recycle Bin");
  EncodableList out;
  ComPtr<IShellItem> item;
  while (items->Next(1, item.ReleaseAndGetAddressOf(), nullptr) == S_OK) {
    std::wstring r_path = ItemName(item.Get(), SIGDN_FILESYSPATH);
    BinInfo info;
    // Items without readable metadata can't be restored by path: skipped.
    if (r_path.empty() || !ReadBinInfo(r_path, &info)) continue;
    EncodableMap m;
    m[EncodableValue("trashId")] = EncodableValue(Utf8(r_path));
    m[EncodableValue("originalPath")] = EncodableValue(Utf8(info.originalPath));
    m[EncodableValue("size")] = EncodableValue(info.size);
    m[EncodableValue("deletedAt")] = EncodableValue(info.deletedAtMs);
    WIN32_FILE_ATTRIBUTE_DATA attrs;
    if (::GetFileAttributesExW(r_path.c_str(), GetFileExInfoStandard,
                               &attrs)) {
      m[EncodableValue("modifiedAt")] =
          EncodableValue(FileTimeToMs(attrs.ftLastWriteTime));
    }
    out.emplace_back(std::move(m));
  }
  return EncodableValue(std::move(out));
}

EncodableValue RestoreFromBin(const std::vector<std::wstring>& trash_ids) {
  std::vector<ItemResult> items(trash_ids.size());
  ComPtr<IFileOperation> op =
      NewFileOperation(kQuietFlags | FOF_RENAMEONCOLLISION);
  bool any = false;
  for (size_t i = 0; i < trash_ids.size(); i++) {
    ItemResult& r = items[i];
    r.key = trash_ids[i];
    BinInfo info;
    if (!ReadBinInfo(trash_ids[i], &info)) {
      r.done = true;
      r.error = "notFound";
      r.message = "not in the Recycle Bin";
      continue;
    }
    auto slash = info.originalPath.find_last_of(L'\\');
    if (slash == std::wstring::npos) {
      r.done = true;
      r.error = "ioError";
      r.message = "bad original path";
      continue;
    }
    std::wstring folder = info.originalPath.substr(0, slash);
    std::wstring name = info.originalPath.substr(slash + 1);
    if (folder.size() == 2 && folder[1] == L':') folder += L'\\';
    // The original folder may be gone: recreated, as Explorer does.
    int made = ::SHCreateDirectoryExW(nullptr, folder.c_str(), nullptr);
    if (made != ERROR_SUCCESS && made != ERROR_ALREADY_EXISTS &&
        made != ERROR_FILE_EXISTS) {
      HRESULT hr = HRESULT_FROM_WIN32(made);
      r.done = true;
      r.error = BinErrorFor(hr);
      r.message = HrMessage(hr);
      continue;
    }
    HRESULT hr;
    ComPtr<IShellItem> src = ItemFor(trash_ids[i], &hr);
    ComPtr<IShellItem> dest;
    if (SUCCEEDED(hr)) dest = ItemFor(folder, &hr);
    if (SUCCEEDED(hr)) {
      r.match = ItemPath(src.Get());
      hr = op->MoveItem(src.Get(), dest.Get(), name.c_str(), nullptr);
    }
    if (FAILED(hr)) {
      r.done = true;
      r.error = BinErrorFor(hr);
      r.message = HrMessage(hr);
      continue;
    }
    any = true;
  }
  if (any) Perform(op.Get(), items);
  for (const auto& r : items) {
    // The bin entry's metadata goes with it.
    if (r.error.empty()) ::DeleteFileW(InfoPathFor(r.key).c_str());
  }
  return ResultList(items, "trashId", "path");
}

EncodableValue DeleteFromBin(const std::vector<std::wstring>& trash_ids) {
  ComPtr<IFileOperation> op = NewFileOperation(kQuietFlags);
  std::vector<std::wstring> queued;
  for (const auto& id : trash_ids) {
    if (InfoPathFor(id).empty()) {
      throw ChannelError("BAD_ARGS", "not a Recycle Bin item: " + Utf8(id));
    }
    HRESULT hr;
    ComPtr<IShellItem> item = ItemFor(id, &hr);
    if (FAILED(hr)) continue;  // already gone: the goal is reached
    Check(op->DeleteItem(item.Get(), nullptr), "DeleteItem");
    queued.push_back(id);
  }
  if (!queued.empty()) {
    HRESULT hr = op->PerformOperations();
    for (const auto& id : queued) {
      if (::GetFileAttributesW(id.c_str()) != INVALID_FILE_ATTRIBUTES) {
        throw ChannelError("IO", "could not delete " + Utf8(id) + ": " +
                                     HrMessage(FAILED(hr) ? hr : E_FAIL));
      }
    }
  }
  // The bin entry's metadata goes with it.
  for (const auto& id : trash_ids) ::DeleteFileW(InfoPathFor(id).c_str());
  return EncodableValue();
}

// PNG of the Shell's thumbnail, longest side <= size; empty when Windows has
// none.
EncodableValue Thumbnail(const std::wstring& path, int size) {
  if (size <= 0) size = 256;
  HRESULT hr;
  ComPtr<IShellItem> item = ItemFor(path, &hr);
  if (FAILED(hr)) return EncodableValue();
  ComPtr<IShellItemImageFactory> factory;
  if (FAILED(item.As(&factory))) return EncodableValue();
  HBITMAP bitmap = nullptr;
  if (FAILED(factory->GetImage(SIZE{size, size},
                               SIIGBF_THUMBNAILONLY | SIIGBF_BIGGERSIZEOK,
                               &bitmap)) ||
      !bitmap) {
    return EncodableValue();
  }
  // Photos often come back with an all-zero alpha channel: ignore it then.
  WICBitmapAlphaChannelOption alpha = WICBitmapIgnoreAlpha;
  DIBSECTION dib = {};
  if (::GetObjectW(bitmap, sizeof(dib), &dib) == sizeof(dib) &&
      dib.dsBm.bmBitsPixel == 32 && dib.dsBm.bmBits) {
    const uint8_t* px = static_cast<const uint8_t*>(dib.dsBm.bmBits);
    size_t count = static_cast<size_t>(dib.dsBm.bmWidth) *
                   static_cast<size_t>(std::abs(dib.dsBm.bmHeight));
    for (size_t i = 0; i < count; i++) {
      if (px[i * 4 + 3] != 0) {
        alpha = WICBitmapUsePremultipliedAlpha;
        break;
      }
    }
  }
  std::vector<uint8_t> bytes;
  try {
    ComPtr<IWICImagingFactory> wic;
    Check(::CoCreateInstance(CLSID_WICImagingFactory, nullptr,
                             CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&wic)),
          "WIC");
    ComPtr<IWICBitmap> wic_bitmap;
    Check(wic->CreateBitmapFromHBITMAP(bitmap, nullptr, alpha, &wic_bitmap),
          "CreateBitmapFromHBITMAP");
    ComPtr<IWICBitmapSource> source = wic_bitmap;
    UINT w = 0, h = 0;
    Check(wic_bitmap->GetSize(&w, &h), "GetSize");
    UINT longest = (std::max)(w, h);
    if (longest > static_cast<UINT>(size) && longest > 0) {
      UINT nw = (std::max)(1u, w * size / longest);
      UINT nh = (std::max)(1u, h * size / longest);
      ComPtr<IWICBitmapScaler> scaler;
      Check(wic->CreateBitmapScaler(&scaler), "scaler");
      Check(scaler->Initialize(source.Get(), nw, nh,
                               WICBitmapInterpolationModeFant),
            "scale");
      source = scaler;
    }
    WICPixelFormatGUID format = alpha == WICBitmapIgnoreAlpha
                                    ? GUID_WICPixelFormat24bppBGR
                                    : GUID_WICPixelFormat32bppBGRA;
    ComPtr<IWICFormatConverter> converter;
    Check(wic->CreateFormatConverter(&converter), "converter");
    Check(converter->Initialize(source.Get(), format, WICBitmapDitherTypeNone,
                                nullptr, 0.0, WICBitmapPaletteTypeCustom),
          "convert");
    ComPtr<IStream> stream;
    Check(::CreateStreamOnHGlobal(nullptr, TRUE, &stream), "stream");
    ComPtr<IWICBitmapEncoder> encoder;
    Check(wic->CreateEncoder(GUID_ContainerFormatPng, nullptr, &encoder),
          "PNG encoder");
    Check(encoder->Initialize(stream.Get(), WICBitmapEncoderNoCache),
          "encoder init");
    ComPtr<IWICBitmapFrameEncode> frame;
    Check(encoder->CreateNewFrame(&frame, nullptr), "frame");
    Check(frame->Initialize(nullptr), "frame init");
    UINT fw = 0, fh = 0;
    Check(converter->GetSize(&fw, &fh), "size");
    Check(frame->SetSize(fw, fh), "frame size");
    WICPixelFormatGUID frame_format = format;
    Check(frame->SetPixelFormat(&frame_format), "pixel format");
    Check(frame->WriteSource(converter.Get(), nullptr), "write");
    Check(frame->Commit(), "frame commit");
    Check(encoder->Commit(), "encoder commit");
    HGLOBAL global = nullptr;
    Check(::GetHGlobalFromStream(stream.Get(), &global), "HGLOBAL");
    STATSTG stat = {};
    Check(stream->Stat(&stat, STATFLAG_NONAME), "stat");
    const void* data = ::GlobalLock(global);
    if (data) {
      const uint8_t* b = static_cast<const uint8_t*>(data);
      bytes.assign(b, b + static_cast<size_t>(stat.cbSize.QuadPart));
      ::GlobalUnlock(global);
    }
  } catch (...) {
    ::DeleteObject(bitmap);
    throw;
  }
  ::DeleteObject(bitmap);
  if (bytes.empty()) return EncodableValue();
  return EncodableValue(std::move(bytes));
}

EncodableValue NetworkIsPublic() {
  ComPtr<INetworkListManager> manager;
  Check(::CoCreateInstance(CLSID_NetworkListManager, nullptr, CLSCTX_ALL,
                           IID_PPV_ARGS(&manager)),
        "NetworkListManager");
  ComPtr<IEnumNetworks> networks;
  Check(manager->GetNetworks(NLM_ENUM_NETWORK_CONNECTED, &networks),
        "GetNetworks");
  ComPtr<INetwork> network;
  while (networks->Next(1, network.ReleaseAndGetAddressOf(), nullptr) ==
         S_OK) {
    NLM_NETWORK_CATEGORY category;
    if (SUCCEEDED(network->GetCategory(&category)) &&
        category == NLM_NETWORK_CATEGORY_PUBLIC) {
      return EncodableValue(true);
    }
  }
  return EncodableValue(false);
}

}  // namespace

// ---- worker pool ----

// Threads with their own STA. Shared state outlives the channel: on
// shutdown, queued work is dropped and running work finishes alone.
class WindowsChannel::WorkerPool {
 public:
  explicit WorkerPool(int threads) : state_(std::make_shared<State>()) {
    for (int i = 0; i < threads; i++) {
      std::thread([state = state_]() {
        ::CoInitializeEx(nullptr,
                         COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
        for (;;) {
          std::function<void()> task;
          {
            std::unique_lock<std::mutex> lock(state->mutex);
            state->ready.wait(
                lock, [&] { return state->stop || !state->tasks.empty(); });
            if (state->stop) break;
            task = std::move(state->tasks.front());
            state->tasks.pop_front();
          }
          task();
        }
        ::CoUninitialize();
      }).detach();
    }
  }

  ~WorkerPool() {
    {
      std::lock_guard<std::mutex> lock(state_->mutex);
      state_->stop = true;
      state_->tasks.clear();
    }
    state_->ready.notify_all();
  }

  void Post(std::function<void()> task) {
    {
      std::lock_guard<std::mutex> lock(state_->mutex);
      state_->tasks.push_back(std::move(task));
    }
    state_->ready.notify_one();
  }

 private:
  struct State {
    std::mutex mutex;
    std::condition_variable ready;
    std::deque<std::function<void()>> tasks;
    bool stop = false;
  };
  std::shared_ptr<State> state_;
};

// ---- channel ----

WindowsChannel::WindowsChannel(flutter::BinaryMessenger* messenger, HWND window)
    : window_(window),
      ops_(std::make_unique<WorkerPool>(1)),
      quick_(std::make_unique<WorkerPool>(4)),
      alive_(std::make_shared<bool>(true)) {
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, "com.kaf.kfm/windows",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
        HandleCall(call, std::move(result));
      });
}

WindowsChannel::~WindowsChannel() {
  alive_.reset();
  if (channel_) channel_->SetMethodCallHandler(nullptr);
}

void WindowsChannel::RunPosted(LPARAM lparam) {
  auto* fn = reinterpret_cast<std::function<void()>*>(lparam);
  if (!fn) return;
  (*fn)();
  delete fn;
}

void WindowsChannel::Run(WorkerPool& pool, Result result,
                         std::function<EncodableValue()> work) {
  HWND window = window_;
  std::weak_ptr<bool> alive = alive_;
  pool.Post([window, alive, result, work = std::move(work)]() {
    std::function<void()> reply;
    try {
      EncodableValue value = work();
      reply = [alive, result, value = std::move(value)]() {
        if (alive.lock()) result->Success(value);
      };
    } catch (const ChannelError& e) {
      std::string code = e.code, message = e.what();
      reply = [alive, result, code, message]() {
        if (alive.lock()) result->Error(code, message);
      };
    } catch (const std::exception& e) {
      std::string message = e.what();
      reply = [alive, result, message]() {
        if (alive.lock()) result->Error("NATIVE", message);
      };
    }
    auto* posted = new std::function<void()>(std::move(reply));
    if (!::PostMessageW(window, kRunOnPlatformThreadMessage, 0,
                        reinterpret_cast<LPARAM>(posted))) {
      delete posted;  // window gone: nobody to answer
    }
  });
}

void WindowsChannel::HandleCall(
    const flutter::MethodCall<EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> unique_result) {
  Result result(std::move(unique_result));
  const std::string& method = call.method_name();
  const EncodableMap& args = ArgsMap(call.arguments());
  if (method == "knownFolders") {
    Run(*quick_, result, [] { return KnownFolders(); });
  } else if (method == "binAvailable") {
    auto paths = StringList(args, "paths");
    Run(*quick_, result, [paths] { return BinAvailable(paths); });
  } else if (method == "recycle") {
    auto paths = StringList(args, "paths");
    Run(*ops_, result, [paths] { return Recycle(paths); });
  } else if (method == "listBin") {
    Run(*ops_, result, [] { return ListBin(); });
  } else if (method == "restoreFromBin") {
    auto ids = StringList(args, "trashIds");
    Run(*ops_, result, [ids] { return RestoreFromBin(ids); });
  } else if (method == "deleteFromBin") {
    auto ids = StringList(args, "trashIds");
    Run(*ops_, result, [ids] { return DeleteFromBin(ids); });
  } else if (method == "thumbnail") {
    auto path = StringArg(args, "path");
    int size = static_cast<int>(IntArg(args, "size", 256));
    Run(*quick_, result, [path, size] { return Thumbnail(path, size); });
  } else if (method == "networkIsPublic") {
    Run(*quick_, result, [] { return NetworkIsPublic(); });
  } else {
    result->NotImplemented();
  }
}
