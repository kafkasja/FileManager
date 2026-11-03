#include "clipboard_files.h"

#include <shellapi.h>
#include <shlobj.h>

#include <cstring>
#include <vector>

namespace clipboard_files {
namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

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

// Another program may hold the clipboard for a moment.
bool OpenWithRetry(HWND owner) {
  for (int i = 0; i < 10; i++) {
    if (::OpenClipboard(owner)) return true;
    ::Sleep(15);
  }
  return false;
}

UINT PreferredDropEffectFormat() {
  static const UINT format =
      ::RegisterClipboardFormatW(CFSTR_PREFERREDDROPEFFECT);
  return format;
}

// CF_HDROP: DROPFILES + a double-null-terminated list of wide paths.
HGLOBAL MakeDropFiles(const std::vector<std::wstring>& paths) {
  size_t chars = 1;
  for (const auto& p : paths) chars += p.size() + 1;
  const size_t bytes = sizeof(DROPFILES) + chars * sizeof(wchar_t);
  HGLOBAL mem = ::GlobalAlloc(GMEM_MOVEABLE | GMEM_ZEROINIT, bytes);
  if (!mem) return nullptr;
  auto* drop = static_cast<DROPFILES*>(::GlobalLock(mem));
  if (!drop) {
    ::GlobalFree(mem);
    return nullptr;
  }
  drop->pFiles = sizeof(DROPFILES);
  drop->fWide = TRUE;
  auto* out = reinterpret_cast<wchar_t*>(reinterpret_cast<BYTE*>(drop) +
                                         sizeof(DROPFILES));
  for (const auto& p : paths) {
    std::memcpy(out, p.c_str(), p.size() * sizeof(wchar_t));
    out += p.size() + 1;  // the zeroed memory ends each path
  }
  ::GlobalUnlock(mem);
  return mem;
}

HGLOBAL MakeDword(DWORD value) {
  HGLOBAL mem = ::GlobalAlloc(GMEM_MOVEABLE, sizeof(DWORD));
  if (!mem) return nullptr;
  auto* d = static_cast<DWORD*>(::GlobalLock(mem));
  if (!d) {
    ::GlobalFree(mem);
    return nullptr;
  }
  *d = value;
  ::GlobalUnlock(mem);
  return mem;
}

// `setFiles {paths, cut}` → the clipboard sequence number after the write
// (0 when the clipboard couldn't be opened).
EncodableValue SetFiles(HWND window, const EncodableMap& args) {
  std::vector<std::wstring> paths;
  bool cut = false;
  for (const auto& [k, v] : args) {
    const auto* key = std::get_if<std::string>(&k);
    if (!key) continue;
    if (*key == "paths") {
      if (const auto* list = std::get_if<EncodableList>(&v)) {
        for (const auto& item : *list) {
          if (const auto* s = std::get_if<std::string>(&item)) {
            paths.push_back(Wide(*s));
          }
        }
      }
    } else if (*key == "cut") {
      if (const auto* b = std::get_if<bool>(&v)) cut = *b;
    }
  }
  if (paths.empty()) return EncodableValue(0);
  HGLOBAL drop = MakeDropFiles(paths);
  // Explorer's own values: a cut is MOVE, a copy COPY | LINK.
  HGLOBAL effect =
      MakeDword(cut ? DROPEFFECT_MOVE : (DROPEFFECT_COPY | DROPEFFECT_LINK));
  if (!drop || !effect || !OpenWithRetry(window)) {
    if (drop) ::GlobalFree(drop);
    if (effect) ::GlobalFree(effect);
    return EncodableValue(0);
  }
  ::EmptyClipboard();
  // After a successful SetClipboardData the system owns the memory.
  const bool ok = ::SetClipboardData(CF_HDROP, drop) != nullptr;
  if (!ok) ::GlobalFree(drop);
  if (!::SetClipboardData(PreferredDropEffectFormat(), effect)) {
    ::GlobalFree(effect);
  }
  ::CloseClipboard();
  return EncodableValue(
      ok ? static_cast<int64_t>(::GetClipboardSequenceNumber()) : 0);
}

// `files` → {paths: [String], cut: bool, sequence: int}; paths is empty
// when the clipboard holds no files.
EncodableValue Files(HWND window) {
  EncodableList paths;
  bool cut = false;
  const int64_t sequence = ::GetClipboardSequenceNumber();
  if (::IsClipboardFormatAvailable(CF_HDROP) && OpenWithRetry(window)) {
    if (HANDLE h = ::GetClipboardData(CF_HDROP)) {
      auto drop = static_cast<HDROP>(h);
      const UINT n = ::DragQueryFileW(drop, 0xFFFFFFFF, nullptr, 0);
      for (UINT i = 0; i < n; i++) {
        const UINT len = ::DragQueryFileW(drop, i, nullptr, 0);
        std::wstring path(len, L'\0');
        ::DragQueryFileW(drop, i, path.data(), len + 1);
        paths.emplace_back(Utf8(path));
      }
    }
    if (HANDLE e = ::GetClipboardData(PreferredDropEffectFormat())) {
      if (auto* d = static_cast<DWORD*>(::GlobalLock(e))) {
        cut = (*d & DROPEFFECT_MOVE) != 0 && (*d & DROPEFFECT_COPY) == 0;
        ::GlobalUnlock(e);
      }
    }
    ::CloseClipboard();
  }
  return EncodableValue(EncodableMap{
      {EncodableValue("paths"), EncodableValue(paths)},
      {EncodableValue("cut"), EncodableValue(cut)},
      {EncodableValue("sequence"), EncodableValue(sequence)},
  });
}

// `clear` → null: empties the clipboard (after a cut was pasted, like
// Explorer does).
EncodableValue Clear(HWND window) {
  if (OpenWithRetry(window)) {
    ::EmptyClipboard();
    ::CloseClipboard();
  }
  return EncodableValue();
}

}  // namespace

bool Handles(const std::string& method) {
  return method == "clipboardSetFiles" || method == "clipboardFiles" ||
         method == "clipboardClear";
}

void Handle(HWND window, const std::string& method, const EncodableMap& args,
            flutter::MethodResult<EncodableValue>& result) {
  if (method == "clipboardSetFiles") {
    result.Success(SetFiles(window, args));
  } else if (method == "clipboardFiles") {
    result.Success(Files(window));
  } else if (method == "clipboardClear") {
    result.Success(Clear(window));
  } else {
    result.NotImplemented();
  }
}

}  // namespace clipboard_files
