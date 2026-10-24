import 'package:kfm/features/swipe/domain/swipe_action.dart';
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
