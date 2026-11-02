import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:meta/meta.dart';

/// What undo needs to reverse an action (`session_actions.previousState`).
/// Covers every action type from day one so undo has no gaps later.
@immutable
sealed class PreviousState {
  const new();

  static PreviousState fromJson(SwipeActionType type, Map<String, Object?> j) =>
      switch (type) {
        SwipeActionType.keep => const NoPreviousState(),
        // Rows from before N9 have no transfer file.
        SwipeActionType.sendToDevice => switch (j['transferFileId']) {
          final int id => SendPreviousState(transferFileId: id),
          _ => const NoPreviousState(),
        },
        SwipeActionType.trash => TrashPreviousState(
          mode: j['mode'] as String? ?? 'trash',
          trashedItem: (j['trashedItem'] as Map?)?.cast<String, Object?>(),
        ),
        SwipeActionType.moveTo when j['kind'] == CrossPlaceMovePreviousState.kind =>
          CrossPlaceMovePreviousState.fromJson(j),
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

/// keep.
final class NoPreviousState extends PreviousState {
  const new();

  @override
  Map<String, Object?> toJson() => const {};
}

/// sendToDevice (N9): the queued transfer file undo removes.
final class SendPreviousState extends PreviousState {
  const new({required this.transferFileId});

  final int transferFileId;

  @override
  Map<String, Object?> toJson() => {'transferFileId': transferFileId};
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

/// U2: a swipe move to another place (SD card, USB drive): the copy is
/// verified, the original's delete is queued in D2's `pending_deletes`
/// like a trash swipe (so the last-10 rule holds). D2's commit adds [mode]
/// and [trashedItem] (`UndoRepository.markCommitted` merges them in).
final class CrossPlaceMovePreviousState extends PreviousState {
  const new({
    required this.source,
    required this.copy,
    required this.mode,
    this.trashedItem,
  });

  factory fromJson(Map<String, Object?> j) => CrossPlaceMovePreviousState(
    source: FileRef.fromJson((j['source']! as Map).cast<String, Object?>()),
    copy: FileRef.fromJson((j['copy']! as Map).cast<String, Object?>()),
    mode: j['mode'] as String? ?? 'trash',
    trashedItem: (j['trashedItem'] as Map?)?.cast<String, Object?>(),
  );

  static const kind = 'crossPlaceMove';

  /// The original as it was swiped.
  final FileRef source;

  /// The verified copy at the target.
  final FileRef copy;

  /// 'trash' | 'permanent': the queued delete's mode (after the commit:
  /// what was done).
  final String mode;

  /// Filled by D2 at commit (trash mode).
  final Map<String, Object?>? trashedItem;

  @override
  Map<String, Object?> toJson() => {
    'kind': kind,
    'source': source.toJson(),
    'copy': copy.toJson(),
    'mode': mode,
    if (trashedItem != null) 'trashedItem': trashedItem,
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
