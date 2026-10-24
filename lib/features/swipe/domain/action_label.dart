import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/tags/domain/tag.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// The one place swipe labels come from ("→ Trash", "→ Holiday"…), so the
/// toast, undo history and P2 never drift apart (S4).
String actionLabel(
  AppLocalizations l,
  SwipeAction a, {
  DeleteMode deleteMode = DeleteMode.trash,
  String? tagName,
  String? deviceName,
}) => switch (a.type) {
  SwipeActionType.trash =>
    deleteMode == DeleteMode.permanent ? l.labelDelete : l.labelTrash,
  SwipeActionType.keep => l.labelKept,
  SwipeActionType.moveTo => l.labelMovedTo(_short(_leaf(a.targetFolder))),
  SwipeActionType.copyTo => l.labelCopiedTo(_short(_leaf(a.targetFolder))),
  SwipeActionType.addTag => l.labelTagged(_short(tagName ?? '')),
  SwipeActionType.favorite => l.labelFavorite,
  SwipeActionType.renameBatch => l.labelRenameBatch,
  SwipeActionType.sendToDevice => l.labelSentTo(_short(deviceName ?? '')),
};

String _leaf(String? path) {
  final parts = (path ?? '')
      .split(RegExp(r'[\\/]'))
      .where((s) => s.isNotEmpty)
      .toList();
  return parts.isEmpty ? '' : parts.last;
}

/// Long names are cut to 24 characters in the pill.
String _short(String s) => s.length <= 24 ? s : '${s.substring(0, 23)}…';

String swipeDirectionName(AppLocalizations l, SwipeDirection d) => switch (d) {
  SwipeDirection.left => l.swipeDirectionLeft,
  SwipeDirection.right => l.swipeDirectionRight,
  SwipeDirection.up => l.swipeDirectionUp,
  SwipeDirection.down => l.swipeDirectionDown,
};

/// A picker option ("Move to folder…").
String swipeTypeName(
  AppLocalizations l,
  SwipeActionType? type,
  DeleteMode mode,
) => switch (type) {
  null => l.swipeActionNothing,
  SwipeActionType.trash =>
    mode == DeleteMode.permanent ? l.swipeActionDelete : l.swipeActionTrash,
  SwipeActionType.keep => l.swipeActionKeep,
  SwipeActionType.moveTo => l.swipeActionMoveTo,
  SwipeActionType.copyTo => l.swipeActionCopyTo,
  SwipeActionType.addTag => l.swipeActionAddTag,
  SwipeActionType.favorite => l.swipeActionFavorite,
  SwipeActionType.renameBatch => l.swipeActionRenameBatch,
  // Not assignable yet (Phase 5): shown only if a stored layout has it.
  SwipeActionType.sendToDevice => actionLabel(l, SwipeAction(type)),
};

/// What a direction does, as a name ("Move to Holiday"), not a result label.
String swipeActionName(
  AppLocalizations l,
  SwipeAction? a,
  DeleteMode mode, {
  Map<int, Tag> tags = const {},
}) => switch (a?.type) {
  SwipeActionType.moveTo => l.swipeActionMoveToNamed(_leafOf(a!.targetFolder)),
  SwipeActionType.copyTo => l.swipeActionCopyToNamed(_leafOf(a!.targetFolder)),
  SwipeActionType.addTag => switch (tags[a!.tagId]) {
    final tag? => l.swipeActionTagNamed(tag.name),
    null => l.swipeActionTagMissing,
  },
  final type => swipeTypeName(l, type, mode),
};

String _leafOf(String? path) {
  final parts = (path ?? '').split('/').where((p) => p.isNotEmpty);
  return parts.isEmpty ? '' : parts.last;
}
