import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/desktop/shell/desktop_nav_pane.dart';
import 'package:kfm/desktop/shell/desktop_side_pane.dart';

/// The desktop shell's column widths, computed from the window instead of
/// measured with a LayoutBuilder (tooltips inside a LayoutBuilder hit the
/// overlay's 'size == theater.size' assert when the pane toggles).
abstract final class DesktopLayout {
  /// The details pane: a third of what the nav pane leaves, 220–340 px.
  static double detailsWidth(double rest) => (rest / 3).clamp(220, 340);

  /// What the nav pane and the details pane leave for the section's screen.
  static double contentWidth(BuildContext context, WidgetRef ref) {
    final window = MediaQuery.sizeOf(context).width;
    final details = ref.watch(desktopDetailsPaneProvider);
    final nav = ref.watch(desktopNavPaneShownProvider)
        ? ref.watch(desktopNavWidthProvider) + 5
        : 0.0;
    final rest = window - nav;
    return details ? rest - detailsWidth(rest) - 1 : rest;
  }

  /// Toolbars show icon buttons below [width] logical px of content (the
  /// threshold grows with the text size).
  static bool compact(BuildContext context, WidgetRef ref, double width) =>
      contentWidth(context, ref) <
      MediaQuery.textScalerOf(context).scale(width);
}
