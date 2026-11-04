#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "startup_hints.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  // Speed: the last run's bounds and background colour, so the window can
  // appear at once while the engine starts (startup_hints.h).
  StartupHints hints = ReadStartupHints();
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 800);
  if (hints.bounds) {
    const RECT& b = *hints.bounds;
    // A monitor that is gone: keep the default place.
    RECT probe{b.left, b.top, b.left + b.right, b.top + b.bottom};
    if (::MonitorFromRect(&probe, MONITOR_DEFAULTTONULL) != nullptr) {
      origin = Win32Window::Point(b.left, b.top);
      size = Win32Window::Size(b.right, b.bottom);
    }
  }

  FlutterWindow window(project, hints.background);
  if (!window.Create(L"KFM", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  // Speed: the loop only ends when Dart quits (window_manager `destroy`),
  // after it hid the window and landed every queued DB write (SQLite runs
  // in WAL mode with synchronous=FULL, so committed data is on disk).
  // Tearing the engine down took ~5 s with the window still on screen;
  // nothing is left to save, so end the process right here.
  ::TerminateProcess(::GetCurrentProcess(), EXIT_SUCCESS);

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
