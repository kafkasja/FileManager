import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Desktop keyboard shortcuts (TASK-PL3). Every one also has a visible
/// button or menu entry (round 7: never keyboard-only).
abstract final class DesktopKeys {
  static const details = SingleActivator(
    LogicalKeyboardKey.keyI,
    control: true,
  );
  static const find = SingleActivator(LogicalKeyboardKey.keyF, control: true);
  static const undo = SingleActivator(LogicalKeyboardKey.keyZ, control: true);
  static const selectAll = SingleActivator(
    LogicalKeyboardKey.keyA,
    control: true,
  );
  static const history = SingleActivator(LogicalKeyboardKey.keyH);
  static const quickLook = SingleActivator(LogicalKeyboardKey.space);
  static const delete = SingleActivator(LogicalKeyboardKey.delete);
  static const deletePermanently = SingleActivator(
    LogicalKeyboardKey.delete,
    shift: true,
  );
  static const rename = SingleActivator(LogicalKeyboardKey.f2);
  static const keep = SingleActivator(LogicalKeyboardKey.keyK);

  /// "Ctrl+Z", "Shift+Del", "F2"… (key names as Windows prints them; the
  /// same in every language KFM ships).
  static String label(SingleActivator a) {
    final key = switch (a.trigger) {
      LogicalKeyboardKey.delete => 'Del',
      LogicalKeyboardKey.space => 'Space',
      LogicalKeyboardKey.enter => 'Enter',
      LogicalKeyboardKey.escape => 'Esc',
      LogicalKeyboardKey.arrowLeft => '←',
      LogicalKeyboardKey.arrowRight => '→',
      final k => k.keyLabel.toUpperCase(),
    };
    return [
      if (a.control) 'Ctrl',
      if (a.shift) 'Shift',
      if (a.alt) 'Alt',
      key,
    ].join('+');
  }

  /// A digit key 1–9 for the [i]th (0-based) extra action.
  static SingleActivator digit(int i) =>
      SingleActivator(LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i));

  static bool get ctrl => HardwareKeyboard.instance.isControlPressed;
  static bool get shift => HardwareKeyboard.instance.isShiftPressed;
}

/// "Search files (Ctrl+F)".
String shortcutHint(AppLocalizations l10n, String label, String keys) =>
    l10n.desktopShortcutHint(label, keys);

String desktopSectionLabel(AppLocalizations l10n, DesktopSection s) =>
    switch (s) {
      DesktopSection.sort => l10n.desktopNavSort,
      DesktopSection.browse => l10n.tabBrowse,
      DesktopSection.trash => l10n.tabTrash,
      DesktopSection.devices => l10n.desktopNavDevices,
      DesktopSection.settings => l10n.tabSettings,
    };
