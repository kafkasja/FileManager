import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/desktop/widgets/desktop_keys.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_buttons_row.dart';

/// One action button of the desktop Sort toolbar, with its key.
@immutable
class SortActionEntry {
  const new({required this.action, required this.key, this.direction});

  final SwipeAction action;

  /// Del for Trash, K for Keep, 1–9 for the others (in toolbar order).
  final SingleActivator key;

  /// The phone direction this action is mapped to (null = action bar).
  final SwipeDirection? direction;
}

/// The active layout's actions in the phone's button order (left, down,
/// up, right), then the P4 action bar; each action once.
List<SortActionEntry> sortActionEntries(SwipeLayout layout) {
  final seen = <SwipeAction>{};
  final ordered = <(SwipeAction, SwipeDirection?)>[
    for (final d in swipeButtonOrder)
      if (layout.actionFor(d) case final a?) (a, d),
    for (final a in layout.actionBar) (a, null),
  ];
  final entries = <SortActionEntry>[];
  var digit = 0;
  var trashKey = false;
  var keepKey = false;
  for (final (action, direction) in ordered) {
    if (!seen.add(action)) continue;
    final SingleActivator key;
    if (action.type == SwipeActionType.trash && !trashKey) {
      trashKey = true;
      key = DesktopKeys.delete;
    } else if (action.type == SwipeActionType.keep && !keepKey) {
      keepKey = true;
      key = DesktopKeys.keep;
    } else if (digit < 9) {
      key = DesktopKeys.digit(digit++);
    } else {
      continue;
    }
    entries.add(
      SortActionEntry(action: action, key: key, direction: direction),
    );
  }
  return entries;
}

/// The entry whose key `e` is (no modifiers), or null.
SortActionEntry? sortEntryForKey(List<SortActionEntry> entries, KeyEvent e) {
  final keys = HardwareKeyboard.instance;
  if (keys.isControlPressed || keys.isAltPressed || keys.isShiftPressed) {
    return null;
  }
  for (final entry in entries) {
    final k = entry.key.trigger;
    if (e.logicalKey == k) return entry;
    // Numpad digits and Backspace (laptops without Del) work too.
    if (k == LogicalKeyboardKey.delete &&
        e.logicalKey == LogicalKeyboardKey.backspace) {
      return entry;
    }
    final d = k.keyId - LogicalKeyboardKey.digit1.keyId;
    if (d >= 0 &&
        d < 9 &&
        e.logicalKey.keyId == LogicalKeyboardKey.numpad1.keyId + d) {
      return entry;
    }
  }
  return null;
}

/// The phone's action colours: trash red, keep green, others blue.
Color sortActionColor(BuildContext context, SwipeAction action) {
  final tokens = context.tokens;
  return switch (action.type) {
    SwipeActionType.trash => tokens.swipeTrash,
    SwipeActionType.keep => tokens.swipeKeep,
    _ => tokens.swipeOther,
  };
}
