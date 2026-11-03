#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

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
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  drag_drop_ = std::make_unique<DragDropChannel>(
      flutter_controller_->engine()->messenger(), GetHandle(),
      flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
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
