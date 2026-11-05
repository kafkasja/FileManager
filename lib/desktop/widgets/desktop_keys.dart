import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Desktop keyboard shortcuts (TASK-PL3). Every one also has a visible
/// button or menu entry (round 7: never keyboard-only).
abstract final class DesktopKeys {
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
  static const favorite = SingleActivator(LogicalKeyboardKey.keyF);
  static const tag = SingleActivator(LogicalKeyboardKey.keyT);
  static const restore = SingleActivator(
    LogicalKeyboardKey.keyR,
    control: true,
  );

  // --- E3: File Explorer's keys ---------------------------------------------
  static const newTab = SingleActivator(LogicalKeyboardKey.keyT, control: true);
  static const closeTab = SingleActivator(
    LogicalKeyboardKey.keyW,
    control: true,
  );
  static const closeTabF4 = SingleActivator(
    LogicalKeyboardKey.f4,
    control: true,
  );
  static const nextTab = SingleActivator(LogicalKeyboardKey.tab, control: true);
  static const previousTab = SingleActivator(
    LogicalKeyboardKey.tab,
    control: true,
    shift: true,
  );
  static const reopenTab = SingleActivator(
    LogicalKeyboardKey.keyT,
    control: true,
    shift: true,
  );
  static const addressBar = SingleActivator(LogicalKeyboardKey.keyD, alt: true);
  static const addressBarL = SingleActivator(
    LogicalKeyboardKey.keyL,
    control: true,
  );
  static const addressBarF4 = SingleActivator(LogicalKeyboardKey.f4);
  static const searchE = SingleActivator(
    LogicalKeyboardKey.keyE,
    control: true,
  );
  static const searchF3 = SingleActivator(LogicalKeyboardKey.f3);
  static const refresh = SingleActivator(LogicalKeyboardKey.f5);
  static const back = SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true);
  static const forward = SingleActivator(
    LogicalKeyboardKey.arrowRight,
    alt: true,
  );
  static const up = SingleActivator(LogicalKeyboardKey.arrowUp, alt: true);
  static const newFolder = SingleActivator(
    LogicalKeyboardKey.keyN,
    control: true,
    shift: true,
  );
  static const copyAsPath = SingleActivator(
    LogicalKeyboardKey.keyC,
    control: true,
    shift: true,
  );

  /// Open with the default app (Quick look, like Enter in the list).
  static const open = SingleActivator(LogicalKeyboardKey.enter);
  static const properties = SingleActivator(
    LogicalKeyboardKey.enter,
    alt: true,
  );
  static const previewPane = SingleActivator(
    LogicalKeyboardKey.keyP,
    alt: true,
  );
  static const detailsPane = SingleActivator(
    LogicalKeyboardKey.keyP,
    alt: true,
    shift: true,
  );
  static const largeIconsView = SingleActivator(
    LogicalKeyboardKey.digit2,
    control: true,
    shift: true,
  );
  static const detailsView = SingleActivator(
    LogicalKeyboardKey.digit6,
    control: true,
    shift: true,
  );

  /// Second keys for an action whose button shows the first one
  /// (Explorer has several): alternate name → the shown key's name. The
  /// rule test (`desktop_keys_rule_test.dart`) checks every other key is
  /// shown on a button, tooltip or menu entry.
  static const alternates = {
    'closeTabF4': 'closeTab',
    'nextTab': 'newTab',
    'previousTab': 'newTab',
    'addressBarL': 'addressBar',
    'addressBarF4': 'addressBar',
    'searchE': 'find',
    'searchF3': 'find',
  };

  /// Keys shown through a variable (Sort's action entries carry theirs).
  static const shownDynamically = {'keep'};

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
      LogicalKeyboardKey.arrowUp => '↑',
      LogicalKeyboardKey.tab => 'Tab',
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
