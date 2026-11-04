#include "startup_hints.h"

#include <knownfolders.h>
#include <shlobj.h>

#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

#pragma comment(lib, "version.lib")

namespace {

// A string of this exe's version resource (Runner.rc), e.g. CompanyName.
std::wstring VersionString(const wchar_t* name) {
  wchar_t exe[MAX_PATH];
  if (::GetModuleFileNameW(nullptr, exe, MAX_PATH) == 0) return L"";
  DWORD ignored = 0;
  DWORD size = ::GetFileVersionInfoSizeW(exe, &ignored);
  if (size == 0) return L"";
  std::vector<BYTE> data(size);
  if (!::GetFileVersionInfoW(exe, 0, size, data.data())) return L"";
  struct Translation {
    WORD language;
    WORD code_page;
  };
  Translation* translations = nullptr;
  UINT bytes = 0;
  if (!::VerQueryValueW(data.data(), L"\\VarFileInfo\\Translation",
                        reinterpret_cast<void**>(&translations), &bytes) ||
      bytes < sizeof(Translation)) {
    return L"";
  }
  wchar_t key[128];
  swprintf_s(key, L"\\StringFileInfo\\%04x%04x\\%s", translations[0].language,
             translations[0].code_page, name);
  wchar_t* value = nullptr;
  UINT length = 0;
  if (!::VerQueryValueW(data.data(), key, reinterpret_cast<void**>(&value),
                        &length) ||
      length == 0) {
    return L"";
  }
  return std::wstring(value);
}

// path_provider's application support folder.
std::wstring SupportFolder() {
  std::wstring company = VersionString(L"CompanyName");
  std::wstring product = VersionString(L"ProductName");
  if (product.empty()) return L"";
  PWSTR roaming = nullptr;
  if (FAILED(::SHGetKnownFolderPath(FOLDERID_RoamingAppData, 0, nullptr,
                                    &roaming))) {
    return L"";
  }
  std::wstring folder(roaming);
  ::CoTaskMemFree(roaming);
  if (!company.empty()) folder += L"\\" + company;
  return folder + L"\\" + product;
}

bool StartsWith(const std::string& s, const char* prefix) {
  return s.rfind(prefix, 0) == 0;
}

}  // namespace

StartupHints ReadStartupHints() {
  StartupHints hints;
  std::wstring folder = SupportFolder();
  if (folder.empty()) return hints;
  FILE* file = nullptr;
  if (_wfopen_s(&file, (folder + L"\\window_state.txt").c_str(), L"rb") != 0 ||
      !file) {
    return hints;
  }
  char buffer[512];
  size_t read = fread(buffer, 1, sizeof(buffer) - 1, file);
  fclose(file);
  buffer[read] = '\0';
  std::string text(buffer);
  size_t start = 0;
  while (start < text.size()) {
    size_t end = text.find('\n', start);
    if (end == std::string::npos) end = text.size();
    std::string line = text.substr(start, end - start);
    if (!line.empty() && line.back() == '\r') line.pop_back();
    start = end + 1;
    if (StartsWith(line, "bounds=")) {
      long x = 0, y = 0, w = 0, h = 0;
      if (sscanf_s(line.c_str() + 7, "%ld,%ld,%ld,%ld", &x, &y, &w, &h) == 4 &&
          w >= 800 && h >= 600 && w <= 100000 && h <= 100000 && x >= -200 &&
          y >= -50 && x <= 100000 && y <= 100000) {
        hints.bounds = RECT{x, y, w, h};
      }
    } else if (StartsWith(line, "background=") && line.size() == 17) {
      char* rest = nullptr;
      unsigned long rgb = strtoul(line.c_str() + 11, &rest, 16);
      if (rest && *rest == '\0') {
        hints.background =
            RGB((rgb >> 16) & 0xff, (rgb >> 8) & 0xff, rgb & 0xff);
      }
    }
  }
  return hints;
}
