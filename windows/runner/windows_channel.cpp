#include "windows_channel.h"

#include "clipboard_files.h"

#include <flutter/standard_method_codec.h>
// clang-format off
#include <windows.h>
#include <winioctl.h>
#include <setupapi.h>
#include <cfgmgr32.h>
#include <dbt.h>
// clang-format on
#include <knownfolders.h>
#include <netlistmgr.h>
#include <objbase.h>
#include <sherrors.h>
#include <shlobj.h>
#include <shobjidl.h>
#include <wincodec.h>
#include <wrl/client.h>

#include <condition_variable>
#include <cstdio>
#include <cstring>
#include <cwctype>
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

// ---- open / open with (desktop Browse) ----

EncodableValue OpenResult(const char* result, const std::string& message) {
  EncodableMap m;
  m[EncodableValue("result")] = EncodableValue(result);
  if (!message.empty()) m[EncodableValue("message")] = EncodableValue(message);
  return EncodableValue(m);
}

const char* OpenErrorFor(DWORD error) {
  switch (error) {
    case ERROR_NO_ASSOCIATION:
      return "noApp";
    case ERROR_FILE_NOT_FOUND:
    case ERROR_PATH_NOT_FOUND:
      return "notFound";
    case ERROR_CANCELLED:
      return "cancelled";
    default:
      return "failed";
  }
}

// The file's default app (Explorer's double-click): ShellExecuteEx with
// the default verb. No association → `noApp` (Dart then asks "Open with").
EncodableValue OpenFile(HWND window, const std::wstring& path) {
  SHELLEXECUTEINFOW info = {sizeof(info)};
  info.fMask = SEE_MASK_NOASYNC | SEE_MASK_FLAG_NO_UI;
  info.hwnd = window;
  info.lpFile = path.c_str();
  info.nShow = SW_SHOWNORMAL;
  if (::ShellExecuteExW(&info)) return OpenResult("opened", "");
  DWORD error = ::GetLastError();
  return OpenResult(OpenErrorFor(error), HrMessage(HRESULT_FROM_WIN32(error)));
}

// E1/E3 "Show in folder": Explorer at the file's folder with the file
// selected. COM is set up here when the worker thread has none yet.
EncodableValue RevealInExplorer(const std::wstring& path) {
  HRESULT co = ::CoInitializeEx(
      nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
  HRESULT hr = E_FAIL;
  PIDLIST_ABSOLUTE pidl = ::ILCreateFromPathW(path.c_str());
  if (pidl) {
    hr = ::SHOpenFolderAndSelectItems(pidl, 0, nullptr, 0);
    ::ILFree(pidl);
  } else {
    hr = HRESULT_FROM_WIN32(ERROR_FILE_NOT_FOUND);
  }
  if (SUCCEEDED(co)) ::CoUninitialize();
  if (SUCCEEDED(hr)) return OpenResult("opened", "");
  return OpenResult("failed", HrMessage(hr));
}

// Windows' "Open with" chooser (`SHOpenWithDialog`, launches the pick).
EncodableValue OpenWith(HWND window, const std::wstring& path) {
  OPENASINFO info = {};
  info.pcszFile = path.c_str();
  info.oaifInFlags = OAIF_ALLOW_REGISTRATION | OAIF_REGISTER_EXT | OAIF_EXEC;
  HRESULT hr = ::SHOpenWithDialog(window, &info);
  if (SUCCEEDED(hr)) return OpenResult("opened", "");
  if (hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
    return OpenResult("cancelled", "");
  }
  if (HRESULT_FACILITY(hr) == FACILITY_WIN32) {
    return OpenResult(OpenErrorFor(HRESULT_CODE(hr)), HrMessage(hr));
  }
  return OpenResult("failed", HrMessage(hr));
}

// ---- drives (U1/U3 on Windows) ----

// GUID_DEVINTERFACE_DISK, defined here so no initguid/devguid dance is
// needed.
const GUID kDiskInterface = {0x53f56307, 0xb6bf, 0x11d0,
                             {0x94, 0xf2, 0x00, 0xa0, 0xc9, 0x1e, 0xfb, 0x8b}};

// RAII for CreateFileW handles.
struct Handle {
  HANDLE h = INVALID_HANDLE_VALUE;
  explicit Handle(HANDLE value) : h(value) {}
  ~Handle() {
    if (h != INVALID_HANDLE_VALUE) ::CloseHandle(h);
  }
  Handle(const Handle&) = delete;
  Handle& operator=(const Handle&) = delete;
  bool ok() const { return h != INVALID_HANDLE_VALUE; }
};

// `\\.\E:` opened without read/write access: enough for the storage IOCTLs
// and never blocks an eject (closed right away).
HANDLE OpenVolumeDevice(wchar_t letter) {
  wchar_t dev[] = L"\\\\.\\?:";
  dev[4] = letter;
  return ::CreateFileW(dev, 0, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                       OPEN_EXISTING, 0, nullptr);
}

const char* BusName(STORAGE_BUS_TYPE bus) {
  switch (bus) {
    case BusTypeUsb:
      return "usb";
    case BusTypeSd:
    case BusTypeMmc:
      return "sd";
    case BusType1394:
      return "firewire";
    case BusTypeSata:
    case BusTypeAta:
    case BusTypeNvme:
    case BusTypeRAID:
    case BusTypeSas:
    case BusTypeScsi:
      return "internal";
    case BusTypeFileBackedVirtual:
    case BusTypeVirtual:
      return "virtual";
    default:
      return "other";
  }
}

// Bus type of the disk behind [letter]; false when the IOCTL fails.
bool QueryBus(wchar_t letter, STORAGE_BUS_TYPE* bus, bool* removable_media) {
  Handle h(OpenVolumeDevice(letter));
  if (!h.ok()) return false;
  STORAGE_PROPERTY_QUERY query = {};
  query.PropertyId = StorageDeviceProperty;
  query.QueryType = PropertyStandardQuery;
  BYTE buffer[1024] = {};
  DWORD returned = 0;
  if (!::DeviceIoControl(h.h, IOCTL_STORAGE_QUERY_PROPERTY, &query,
                         sizeof(query), buffer, sizeof(buffer), &returned,
                         nullptr) ||
      returned < sizeof(STORAGE_DEVICE_DESCRIPTOR) - 1) {
    return false;
  }
  const auto* desc = reinterpret_cast<STORAGE_DEVICE_DESCRIPTOR*>(buffer);
  *bus = desc->BusType;
  *removable_media = desc->RemovableMedia != FALSE;
  return true;
}

bool DeviceNumberOf(HANDLE h, STORAGE_DEVICE_NUMBER* out) {
  DWORD returned = 0;
  return ::DeviceIoControl(h, IOCTL_STORAGE_GET_DEVICE_NUMBER, nullptr, 0, out,
                           sizeof(*out), &returned, nullptr) != FALSE;
}

wchar_t SystemLetter() {
  wchar_t system_dir[MAX_PATH] = {};
  ::GetSystemWindowsDirectoryW(system_dir, MAX_PATH);
  return static_cast<wchar_t>(::towupper(system_dir[0]));
}

// Removable media, or a disk on USB / SD / FireWire (USB hard disks report
// DRIVE_FIXED). Never the system drive.
bool IsEjectable(wchar_t letter, UINT type, bool has_bus,
                 STORAGE_BUS_TYPE bus) {
  if (letter == SystemLetter()) return false;
  return type == DRIVE_REMOVABLE ||
         (has_bus && (bus == BusTypeUsb || bus == BusTypeSd ||
                      bus == BusTypeMmc || bus == BusType1394));
}

// The drive letters present, in order.
EncodableValue ListDrives() {
  wchar_t system_letter = SystemLetter();
  DWORD mask = ::GetLogicalDrives();
  EncodableList out;
  for (int i = 0; i < 26; i++) {
    if (!(mask & (1u << i))) continue;
    wchar_t letter = static_cast<wchar_t>(L'A' + i);
    wchar_t root[] = L"?:\\";
    root[0] = letter;
    UINT type = ::GetDriveTypeW(root);
    if (type == DRIVE_NO_ROOT_DIR || type == DRIVE_UNKNOWN ||
        type == DRIVE_CDROM) {
      continue;
    }
    EncodableMap row;
    std::string path(1, static_cast<char>(letter));
    path += ":";
    row[EncodableValue("path")] = EncodableValue(path);
    row[EncodableValue("system")] = EncodableValue(letter == system_letter);
    if (type == DRIVE_REMOTE) {
      // Network drives: listed (so index rows on them never look detached)
      // but not queried: a disconnected share can block for seconds.
      row[EncodableValue("type")] = EncodableValue("remote");
      row[EncodableValue("mounted")] = EncodableValue(true);
      out.push_back(EncodableValue(std::move(row)));
      continue;
    }
    // A card reader slot without a card: no volume, not a place.
    UINT old_mode = ::SetErrorMode(SEM_FAILCRITICALERRORS);
    wchar_t label[MAX_PATH + 1] = {};
    wchar_t fs[MAX_PATH + 1] = {};
    DWORD serial = 0;
    BOOL has_volume = ::GetVolumeInformationW(root, label, MAX_PATH + 1,
                                              &serial, nullptr, nullptr, fs,
                                              MAX_PATH + 1);
    ULARGE_INTEGER free_bytes = {}, total_bytes = {};
    BOOL has_space =
        has_volume && ::GetDiskFreeSpaceExW(root, &free_bytes, &total_bytes,
                                            nullptr);
    ::SetErrorMode(old_mode);
    if (!has_volume) continue;
    STORAGE_BUS_TYPE bus = BusTypeUnknown;
    bool removable_media = false;
    bool has_bus = QueryBus(letter, &bus, &removable_media);
    bool removable = IsEjectable(letter, type, has_bus, bus);
    char uuid[16] = {};
    snprintf(uuid, sizeof(uuid), "%04X-%04X",
             static_cast<unsigned>(serial >> 16),
             static_cast<unsigned>(serial & 0xFFFF));
    row[EncodableValue("type")] =
        EncodableValue(type == DRIVE_REMOVABLE ? "removable" : "fixed");
    row[EncodableValue("removable")] = EncodableValue(removable);
    row[EncodableValue("mounted")] = EncodableValue(true);
    row[EncodableValue("uuid")] = EncodableValue(std::string(uuid));
    row[EncodableValue("label")] = EncodableValue(Utf8(label));
    row[EncodableValue("fileSystem")] = EncodableValue(Utf8(fs));
    row[EncodableValue("bus")] =
        EncodableValue(has_bus ? BusName(bus) : "other");
    if (has_space) {
      row[EncodableValue("totalBytes")] =
          EncodableValue(static_cast<int64_t>(total_bytes.QuadPart));
      row[EncodableValue("freeBytes")] =
          EncodableValue(static_cast<int64_t>(free_bytes.QuadPart));
    }
    out.push_back(EncodableValue(std::move(row)));
  }
  return EncodableValue(std::move(out));
}

// The disk device node behind [letter] (matched by storage device number
// over every present disk interface).
DEVINST DiskDevInstFor(wchar_t letter) {
  STORAGE_DEVICE_NUMBER wanted = {};
  {
    Handle h(OpenVolumeDevice(letter));
    if (!h.ok() || !DeviceNumberOf(h.h, &wanted)) return 0;
  }
  HDEVINFO info = ::SetupDiGetClassDevsW(
      &kDiskInterface, nullptr, nullptr, DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);
  if (info == INVALID_HANDLE_VALUE) return 0;
  DEVINST found = 0;
  SP_DEVICE_INTERFACE_DATA iface = {};
  iface.cbSize = sizeof(iface);
  for (DWORD i = 0; ::SetupDiEnumDeviceInterfaces(info, nullptr,
                                                  &kDiskInterface, i, &iface);
       i++) {
    DWORD size = 0;
    ::SetupDiGetDeviceInterfaceDetailW(info, &iface, nullptr, 0, &size,
                                       nullptr);
    if (size == 0) continue;
    std::vector<BYTE> buffer(size);
    auto* detail =
        reinterpret_cast<SP_DEVICE_INTERFACE_DETAIL_DATA_W*>(buffer.data());
    detail->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA_W);
    SP_DEVINFO_DATA dev = {};
    dev.cbSize = sizeof(dev);
    if (!::SetupDiGetDeviceInterfaceDetailW(info, &iface, detail, size,
                                            nullptr, &dev)) {
      continue;
    }
    Handle disk(::CreateFileW(detail->DevicePath, 0,
                              FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                              OPEN_EXISTING, 0, nullptr));
    STORAGE_DEVICE_NUMBER number = {};
    if (disk.ok() && DeviceNumberOf(disk.h, &number) &&
        number.DeviceType == wanted.DeviceType &&
        number.DeviceNumber == wanted.DeviceNumber) {
      found = dev.DevInst;
      break;
    }
  }
  ::SetupDiDestroyDeviceInfoList(info);
  return found;
}

const char* VetoName(PNP_VETO_TYPE veto) {
  switch (veto) {
    case PNP_VetoOutstandingOpen:
    case PNP_VetoDevice:
    case PNP_VetoDriver:
    case PNP_VetoIllegalDeviceRequest:
      return "inUse";
    case PNP_VetoNonDisableable:
    case PNP_VetoLegacyDevice:
    case PNP_VetoLegacyDriver:
      return "notEjectable";
    default:
      return "failed";
  }
}

// `ejectDrive {path: "E:"}` → `{ok, error?}`. Asks Plug and Play to eject
// the disk's parent device (the USB stick / card reader). Windows shows its
// own "Safe to remove" / "in use" message (no veto buffer is passed).
EncodableValue EjectDrive(const std::wstring& path) {
  EncodableMap out;
  if (path.empty() || !::iswalpha(path[0])) {
    throw ChannelError("BAD_ARGS", "ejectDrive needs a drive like E:");
  }
  wchar_t letter = static_cast<wchar_t>(::towupper(path[0]));
  // Only what the drive list offers as removable: never ask Plug and Play
  // to remove the system disk or an internal one.
  {
    wchar_t root[] = L"?:\\";
    root[0] = letter;
    STORAGE_BUS_TYPE bus = BusTypeUnknown;
    bool removable_media = false;
    bool has_bus = QueryBus(letter, &bus, &removable_media);
    if (!IsEjectable(letter, ::GetDriveTypeW(root), has_bus, bus)) {
      out[EncodableValue("ok")] = EncodableValue(false);
      out[EncodableValue("error")] = EncodableValue("notEjectable");
      return EncodableValue(std::move(out));
    }
  }
  // Pending writes reach the device before it goes away.
  {
    wchar_t dev[] = L"\\\\.\\?:";
    dev[4] = letter;
    Handle volume(::CreateFileW(dev, GENERIC_READ | GENERIC_WRITE,
                                FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                                OPEN_EXISTING, 0, nullptr));
    if (volume.ok()) ::FlushFileBuffers(volume.h);
  }
  DEVINST disk = DiskDevInstFor(letter);
  DEVINST parent = 0;
  if (disk == 0 || ::CM_Get_Parent(&parent, disk, 0) != CR_SUCCESS) {
    out[EncodableValue("ok")] = EncodableValue(false);
    out[EncodableValue("error")] = EncodableValue("notEjectable");
    return EncodableValue(std::move(out));
  }
  PNP_VETO_TYPE veto = PNP_VetoTypeUnknown;
  CONFIGRET cr = CR_FAILURE;
  // A file just closed can still be held for a moment: try a few times.
  for (int attempt = 0; attempt < 3; attempt++) {
    veto = PNP_VetoTypeUnknown;
    cr = ::CM_Request_Device_EjectW(parent, &veto, nullptr, 0, 0);
    if (cr == CR_SUCCESS && veto == PNP_VetoTypeUnknown) break;
    ::Sleep(500);
  }
  bool ok = cr == CR_SUCCESS && veto == PNP_VetoTypeUnknown;
  out[EncodableValue("ok")] = EncodableValue(ok);
  if (!ok) {
    out[EncodableValue("error")] =
        EncodableValue(veto == PNP_VetoTypeUnknown ? "failed" : VetoName(veto));
  }
  return EncodableValue(std::move(out));
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

// ---- X8: taskbar button progress ----

// [state]: none | normal | paused | error | indeterminate; [value] 0..100.
// The ITaskbarList3 is created on first use (the taskbar button exists by
// then) and kept; failures are ignored (no taskbar, e.g. Explorer
// restarting).
static void SetTaskbarProgress(HWND window, const std::wstring& state, int value) {
  static Microsoft::WRL::ComPtr<ITaskbarList3> taskbar;
  if (!taskbar) {
    if (FAILED(::CoCreateInstance(CLSID_TaskbarList, nullptr,
                                  CLSCTX_INPROC_SERVER,
                                  IID_PPV_ARGS(&taskbar))) ||
        FAILED(taskbar->HrInit())) {
      taskbar.Reset();
      return;
    }
  }
  TBPFLAG flag = TBPF_NOPROGRESS;
  if (state == L"normal") flag = TBPF_NORMAL;
  if (state == L"paused") flag = TBPF_PAUSED;
  if (state == L"error") flag = TBPF_ERROR;
  if (state == L"indeterminate") flag = TBPF_INDETERMINATE;
  if (flag != TBPF_NOPROGRESS && flag != TBPF_INDETERMINATE) {
    if (value < 0) value = 0;
    if (value > 100) value = 100;
    taskbar->SetProgressValue(window, static_cast<ULONGLONG>(value), 100);
  }
  if (FAILED(taskbar->SetProgressState(window, flag))) taskbar.Reset();
}

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
  // PL3: files on the Windows clipboard, answered on this (window) thread.
  if (clipboard_files::Handles(method)) {
    clipboard_files::Handle(window_, method, args, *result);
    return;
  }
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
  } else if (method == "listDrives") {
    Run(*quick_, result, [] { return ListDrives(); });
  } else if (method == "openFile") {
    auto path = StringArg(args, "path");
    HWND window = window_;
    Run(*quick_, result, [window, path] { return OpenFile(window, path); });
  } else if (method == "revealInExplorer") {
    auto path = StringArg(args, "path");
    Run(*quick_, result, [path] { return RevealInExplorer(path); });
  } else if (method == "openWith") {
    auto path = StringArg(args, "path");
    HWND window = window_;
    Run(*quick_, result, [window, path] { return OpenWith(window, path); });
  } else if (method == "setTaskbarProgress") {
    // X8: transfers on the taskbar button (window thread: COM STA).
    SetTaskbarProgress(window_, StringArg(args, "state"),
                       static_cast<int>(IntArg(args, "value", 0)));
    result->Success(EncodableValue());
  } else if (method == "ejectDrive") {
    auto path = StringArg(args, "path");
    Run(*quick_, result, [path] { return EjectDrive(path); });
  } else {
    result->NotImplemented();
  }
}

void WindowsChannel::OnDeviceChange(WPARAM wparam, LPARAM lparam) {
  if (wparam != DBT_DEVICEARRIVAL && wparam != DBT_DEVICEREMOVECOMPLETE) {
    return;
  }
  const auto* header = reinterpret_cast<const DEV_BROADCAST_HDR*>(lparam);
  if (!header || header->dbch_devicetype != DBT_DEVTYP_VOLUME) return;
  if (channel_) channel_->InvokeMethod("volumesChanged", nullptr);
}

void WindowsChannel::OnPowerBroadcast(WPARAM wparam) {
  const char* state = nullptr;
  switch (wparam) {
    case PBT_APMSUSPEND:
      state = "suspend";
      break;
    case PBT_APMRESUMEAUTOMATIC:
      state = "resume";
      break;
    default:
      return;
  }
  if (channel_) {
    channel_->InvokeMethod(
        "power", std::make_unique<EncodableValue>(EncodableMap{
                     {EncodableValue("state"), EncodableValue(state)}}));
  }
}
