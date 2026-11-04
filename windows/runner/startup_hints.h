#ifndef RUNNER_STARTUP_HINTS_H_
#define RUNNER_STARTUP_HINTS_H_

#include <windows.h>

#include <optional>

// What the last run left for the next start (TASK-PL3 speed fixes): the
// window's bounds and the app's background colour, so the window can be
// shown at once, in the right place and colour, while the Flutter engine is
// still starting (~1.2 s on a typical PC).
//
// Dart writes `<RoamingAppData>\<CompanyName>\<ProductName>\window_state.txt`
// (path_provider's application support folder) with lines
// `bounds=<x>,<y>,<w>,<h>` (logical pixels) and `background=<RRGGBB>`
// (lib/core/platform/windows/startup_hints.dart).
struct StartupHints {
  std::optional<RECT> bounds;  // left, top, width (right), height (bottom)
  std::optional<COLORREF> background;
};

StartupHints ReadStartupHints();

#endif  // RUNNER_STARTUP_HINTS_H_
