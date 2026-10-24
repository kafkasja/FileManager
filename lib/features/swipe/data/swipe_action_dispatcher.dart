import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/trash/data/delete_queue.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';

/// Routes a swipe to the undo log (S2) and, for trash, the delete queue (D2),
/// without awaiting any I/O on the gesture path. Write failures surface on
/// the write queue's error stream (shell banner). P2 adds more action types.
class SwipeActionDispatcher {
  new(this._undo, this._deletes);

  final UndoRepository _undo;
  final DeleteQueue _deletes;

  /// Returns the action's seq.
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
        SwipeActionType.moveTo ||
        SwipeActionType.copyTo ||
        SwipeActionType.addTag ||
        SwipeActionType.favorite ||
        SwipeActionType.renameBatch ||
        SwipeActionType.sendToDevice => throw UnimplementedError(
          'swipe action ${action.type.name}: TASK-P2',
        ),
      };
}
