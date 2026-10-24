import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:meta/meta.dart';

/// What undo needs to reverse an action (`session_actions.previousState`).
/// Covers every action type from day one so undo has no gaps later.
@immutable
sealed class PreviousState {
  const new();

  static PreviousState fromJson(SwipeActionType type, Map<String, Object?> j) =>
      switch (type) {
        SwipeActionType.keep ||
        SwipeActionType.sendToDevice => const NoPreviousState(),
        SwipeActionType.trash => TrashPreviousState(
          mode: j['mode'] as String? ?? 'trash',
          trashedItem: (j['trashedItem'] as Map?)?.cast<String, Object?>(),
        ),
        SwipeActionType.moveTo => MovePreviousState(
          folderPath: j['folderPath']! as String,
          fileIdBefore: j['fileIdBefore']! as String,
        ),
        SwipeActionType.copyTo => CopyPreviousState(
          createdFileId: j['createdFileId']! as String,
        ),
        SwipeActionType.addTag => TagPreviousState(
          tagId: j['tagId']! as int,
          hadTag: j['hadTag']! as bool,
        ),
        SwipeActionType.favorite => FavoritePreviousState(
          wasFavorite: j['wasFavorite']! as bool,
        ),
        SwipeActionType.renameBatch => RenamePreviousState(
          batchId: j['batchId']! as int,
          op: RenameOp.values.asNameMap()[j['op']] ?? RenameOp.add,
          added: j['added'] as bool? ?? true,
        ),
      };

  Map<String, Object?> toJson();
}

/// keep, sendToDevice.
final class NoPreviousState extends PreviousState {
  const new();

  @override
  Map<String, Object?> toJson() => const {};
}

final class TrashPreviousState extends PreviousState {
  const new({required this.mode, this.trashedItem});

  /// 'trash' | 'permanent'.
  final String mode;

  /// Filled by D2 at commit (TrashedItem JSON), used by undo to restore.
  final Map<String, Object?>? trashedItem;

  @override
  Map<String, Object?> toJson() => {
    'mode': mode,
    if (trashedItem != null) 'trashedItem': trashedItem,
  };
}

final class MovePreviousState extends PreviousState {
  const new({required this.folderPath, required this.fileIdBefore});

  final String folderPath;
  final String fileIdBefore;

  @override
  Map<String, Object?> toJson() => {
    'folderPath': folderPath,
    'fileIdBefore': fileIdBefore,
  };
}

final class CopyPreviousState extends PreviousState {
  const new({required this.createdFileId});

  final String createdFileId;

  @override
  Map<String, Object?> toJson() => {'createdFileId': createdFileId};
}

final class TagPreviousState extends PreviousState {
  const new({required this.tagId, required this.hadTag});

  final int tagId;
  final bool hadTag;

  @override
  Map<String, Object?> toJson() => {'tagId': tagId, 'hadTag': hadTag};
}

final class FavoritePreviousState extends PreviousState {
  const new({required this.wasFavorite});

  final bool wasFavorite;

  @override
  Map<String, Object?> toJson() => {'wasFavorite': wasFavorite};
}

/// P3: `add` = a file swiped into the batch; `apply` = the whole batch was
/// renamed (one row, so one undo reverts it).
enum RenameOp { add, apply }

final class RenamePreviousState extends PreviousState {
  const new({required this.batchId, required this.op, this.added = true});

  final int batchId;
  final RenameOp op;

  /// op == add: false when the file was already in the batch (undo then
  /// removes nothing).
  final bool added;

  @override
  Map<String, Object?> toJson() => {
    'batchId': batchId,
    'op': op.name,
    if (op == RenameOp.add) 'added': added,
  };
}
