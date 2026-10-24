import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/rename/data/rename_batch_repository.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/swipe/data/swipe_file_ops.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/tags/data/favorites_repository.dart';
import 'package:kfm/features/tags/data/tag_repository.dart';
import 'package:kfm/features/tags/domain/tag.dart';
import 'package:kfm/features/trash/data/delete_queue.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';

/// Routes a swipe to the undo log (S2) and, for trash, the delete queue (D2),
/// without awaiting any I/O on the gesture path. Write failures surface on
/// the write queue's error stream (shell banner); move/copy failures on
/// [SwipeFileOps.events].
class SwipeActionDispatcher {
  new(
    this._undo,
    this._deletes, {
    required this._fileOps,
    required this._tags,
    required this._favorites,
    required this._renames,
  });

  final UndoRepository _undo;
  final DeleteQueue _deletes;
  final SwipeFileOps _fileOps;
  final TagRepository _tags;
  final FavoritesRepository _favorites;
  final RenameBatchRepository _renames;

  /// Types the deck can dispatch; others act as unmapped (spring back).
  static const Set<SwipeActionType> supported = {
    SwipeActionType.trash,
    SwipeActionType.keep,
    SwipeActionType.moveTo,
    SwipeActionType.copyTo,
    SwipeActionType.addTag,
    SwipeActionType.favorite,
    SwipeActionType.renameBatch,
  };

  /// Synchronous pre-check (no I/O). A missing folder is only found by the
  /// file operation itself.
  static SwipeActionProblem? problemFor(
    SwipeAction action,
    Map<int, Tag> tags,
  ) {
    if (!supported.contains(action.type)) {
      return SwipeActionProblem.unsupported;
    }
    if (action.type == SwipeActionType.addTag &&
        !tags.containsKey(action.tagId)) {
      return SwipeActionProblem.tagMissing;
    }
    if ((action.type == SwipeActionType.moveTo ||
            action.type == SwipeActionType.copyTo) &&
        action.targetFolder == null) {
      return SwipeActionProblem.unsupported;
    }
    return null;
  }

  /// Returns the action's seq. Call only when [problemFor] is null.
  int dispatch(Session session, FileRef file, SwipeAction action) =>
      switch (action.type) {
        SwipeActionType.keep => _undo.record(
          session.id,
          file,
          action,
          const NoPreviousState(),
        ),
        SwipeActionType.trash => _undo.record(
          session.id,
          file,
          action,
          TrashPreviousState(mode: session.deleteMode.name),
          alsoInTransaction: (actionId) => _deletes.queueInTransaction(
            actionId: actionId,
            sessionId: session.id,
            file: file,
            mode: session.deleteMode,
          ),
        ),
        SwipeActionType.addTag => _undo.recordWith(
          session.id,
          file,
          action,
          applyInTransaction: () =>
              _tags.addInTransaction(file.id, action.tagId!),
        ),
        SwipeActionType.favorite => _undo.recordWith(
          session.id,
          file,
          action,
          applyInTransaction: () => _favorites.addInTransaction(file.id),
        ),
        SwipeActionType.moveTo ||
        SwipeActionType.copyTo => _fileOps.run(session.id, file, action),
        SwipeActionType.renameBatch => _undo.recordWith(
          session.id,
          file,
          action,
          applyInTransaction: () => _renames.addInTransaction(session.id, file),
        ),
        SwipeActionType.sendToDevice => throw StateError(
          'not dispatchable: ${action.type.name}',
        ),
      };
}
