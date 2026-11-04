#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include <memory>
#include <optional>

#include "drag_drop.h"
#include "win32_window.h"
#include "windows_channel.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  // [background] fills the window until Flutter's first frame (the last
  // run's colour; the system light/dark default without one).
  FlutterWindow(const flutter::DartProject& project,
                std::optional<COLORREF> background = std::nullopt);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // Painted until the Flutter view shows its first frame.
  HBRUSH background_ = nullptr;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // com.kaf.kfm/windows (TASK-PL1); destroyed before the controller.
  std::unique_ptr<WindowsChannel> windows_channel_;

  // com.kaf.kfm/dragdrop (TASK-PL3): Explorer drag & drop.
  std::unique_ptr<DragDropChannel> drag_drop_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
