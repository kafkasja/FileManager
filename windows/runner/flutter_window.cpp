#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {

// Windows' "app mode" (Settings > Personalization > Colors).
bool SystemUsesLightTheme() {
  DWORD light = 1;
  DWORD size = sizeof(light);
  ::RegGetValueW(
      HKEY_CURRENT_USER,
      L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
      L"AppsUseLightTheme", RRF_RT_REG_DWORD, nullptr, &light, &size);
  return light != 0;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project,
                             std::optional<COLORREF> background)
    : project_(project) {
  // Material 3 surface colours of KFM's default (blue) theme.
  COLORREF colour = background.value_or(
      SystemUsesLightTheme() ? RGB(0xF9, 0xF9, 0xFF) : RGB(0x11, 0x13, 0x18));
  background_ = ::CreateSolidBrush(colour);
}

FlutterWindow::~FlutterWindow() {
  if (background_) ::DeleteObject(background_);
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  // Speed: the engine takes ~1.2 s to start (the same for an empty Flutter
  // app on this PC). Show the window now, painted in the app's background
  // colour (WM_ERASEBKGND below); the Flutter view appears with its first
  // frame.
  this->Show();
  ::UpdateWindow(GetHandle());

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  windows_channel_ = std::make_unique<WindowsChannel>(
      flutter_controller_->engine()->messenger(), GetHandle());
  HWND view = flutter_controller_->view()->GetNativeWindow();
  SetChildContent(view);
  ::ShowWindow(view, SW_HIDE);
  drag_drop_ = std::make_unique<DragDropChannel>(
      flutter_controller_->engine()->messenger(), GetHandle(),
      flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([view]() {
    ::ShowWindow(view, SW_SHOW);
    ::SetFocus(view);
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  drag_drop_ = nullptr;
  windows_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Replies of the windows channel's worker threads (platform thread only).
  if (message == WindowsChannel::kRunOnPlatformThreadMessage) {
    WindowsChannel::RunPosted(lparam);
    return 0;
  }
  // Drive and power events for Dart (TASK-PL1); the messages go on to
  // Flutter and the default handling as usual.
  if (windows_channel_) {
    if (message == WM_DEVICECHANGE) {
      windows_channel_->OnDeviceChange(wparam, lparam);
    } else if (message == WM_POWERBROADCAST) {
      windows_channel_->OnPowerBroadcast(wparam);
    }
  }
  // Minimum window size 800x600 (logical pixels).
  if (message == WM_GETMINMAXINFO) {
    UINT dpi = ::GetDpiForWindow(hwnd);
    auto* info = reinterpret_cast<MINMAXINFO*>(lparam);
    info->ptMinTrackSize.x = ::MulDiv(800, dpi, 96);
    info->ptMinTrackSize.y = ::MulDiv(600, dpi, 96);
    return 0;
  }
  // Until the first frame: the app's background colour, not a white flash.
  if (message == WM_ERASEBKGND && background_) {
    RECT rect;
    ::GetClientRect(hwnd, &rect);
    ::FillRect(reinterpret_cast<HDC>(wparam), &rect, background_);
    return 1;
  }
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
