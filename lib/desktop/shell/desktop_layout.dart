import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';

/// The desktop shell's column widths, computed from the window instead of
/// measured with a LayoutBuilder (tooltips inside a LayoutBuilder hit the
/// overlay's 'size == theater.size' assert when the pane toggles).
abstract final class DesktopLayout {
  static const sidebarWidth = 232.0;
  static const sidebarCollapsedWidth = 60.0;

  /// Below this window width an open details pane collapses the sidebar
  /// to icons (800 px minimum window).
  static const narrowWindow = 1000.0;

  static bool sidebarForcedCollapsed(double window, {required bool details}) =>
      details && window < narrowWindow;

  /// The details pane: a third of what the sidebar leaves, 220–340 px.
  static double detailsWidth(double rest) => (rest / 3).clamp(220, 340);

  /// What the sidebar and the details pane leave for the section's screen.
  static double contentWidth(BuildContext context, WidgetRef ref) {
    final window = MediaQuery.sizeOf(context).width;
    final details = ref.watch(desktopDetailsPaneProvider);
    final collapsed =
        sidebarForcedCollapsed(window, details: details) ||
        ref.watch(desktopSidebarCollapsedProvider);
    // + 1: the divider after the sidebar (and before the pane).
    final rest =
        window - (collapsed ? sidebarCollapsedWidth : sidebarWidth) - 1;
    return details ? rest - detailsWidth(rest) - 1 : rest;
  }

  /// Toolbars show icon buttons below [width] logical px of content (the
  /// threshold grows with the text size).
  static bool compact(BuildContext context, WidgetRef ref, double width) =>
      contentWidth(context, ref) <
      MediaQuery.textScalerOf(context).scale(width);
}
