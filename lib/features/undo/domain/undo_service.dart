import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/tables/session_actions_table.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/trash/data/delete_queue.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';
import 'package:meta/meta.dart';

@immutable
sealed class UndoOutcome {
  const new();
}

/// The stack was empty.
class NothingToUndo extends UndoOutcome {
  const new();
}

/// Undone; the file can be shown again.
class Undone extends UndoOutcome {
  const new(this.action, {this.restoredFromTrash = false});

  final SessionAction action;
  final bool restoredFromTrash;
}

/// A committed permanent delete: can't come back. The stack moved past it.
class PermanentlyDeleted extends UndoOutcome {
  const new(this.action);

  final SessionAction action;
}

/// The inverse failed. [movedPast] = the row was marked undone anyway so the
/// stack can't get stuck (file missing etc.); false = retry possible (e.g.
/// the user declined the restore dialog).
class UndoFailed extends UndoOutcome {
  const new(this.action, this.error, {required this.movedPast});

  final SessionAction action;
  final Object error;
  final bool movedPast;
}

/// Undo semantics (TASK-S2). Runs under the lock shared with D2 commits.
class UndoService {
  new({
    required this._repo,
    required this._deletes,
    required this._source,
    required this._lock,
    required this._queue,
  });

  final UndoRepository _repo;
  final DeleteQueue _deletes;
  final FileSource _source;
  final SerialLock _lock;
  final DbWriteQueue _queue;

  Future<UndoOutcome> undoLast(int sessionId) => _lock.run(() async {
    // Recorded swipes may still be in the write queue.
    await _queue.flush();
    final top = await _repo.top(sessionId);
    if (top == null) return const NothingToUndo();
    return await _undo(top);
  });

  /// Undoes everything newer than and including [seq] (history sheet).
  Future<List<UndoOutcome>> undoUntil(int sessionId, int seq) async {
    final outcomes = <UndoOutcome>[];
    while (true) {
      final outcome = await _lock.run(() async {
        await _queue.flush();
        final top = await _repo.top(sessionId);
        if (top == null || top.seq < seq) return const NothingToUndo();
        return await _undo(top);
      });
      if (outcome is NothingToUndo) break;
      outcomes.add(outcome);
      if (outcome is UndoFailed && !outcome.movedPast) break;
    }
    return outcomes;
  }

  Future<UndoOutcome> _undo(SessionAction a) async {
    try {
      switch (a.action.type) {
        case SwipeActionType.keep:
        case SwipeActionType.sendToDevice:
          break;
        case SwipeActionType.trash:
          if (a.status == ActionStatus.applied) {
            await _deletes.unqueue(a.id);
          } else {
            final previous = a.previous as TrashPreviousState;
            final item = previous.trashedItem;
            if (previous.mode == 'permanent' || item == null) {
              await _repo.markUndone(a.id);
              return PermanentlyDeleted(a);
            }
            await _source.restore(TrashedItem.fromJson(item));
            await _repo.markUndone(a.id);
            return Undone(a, restoredFromTrash: true);
          }
        case SwipeActionType.moveTo:
        case SwipeActionType.copyTo:
        case SwipeActionType.addTag:
        case SwipeActionType.favorite:
        case SwipeActionType.renameBatch:
          throw UnimplementedError('undo of ${a.action.type.name}: TASK-P2/P3');
      }
      await _repo.markUndone(a.id);
      return Undone(a);
    } on FileOpException catch (e) {
      final retryable = e.failure == FileOpFailure.userCancelled;
      if (!retryable) await _repo.markUndone(a.id);
      return UndoFailed(a, e, movedPast: !retryable);
    } on Object catch (e) {
      // Not built yet (restore before D3/D5, P2 actions): keep the row so
      // the user can undo it once it works. Anything else: move past.
      final retryable = e is UnimplementedError;
      if (!retryable) await _repo.markUndone(a.id);
      return UndoFailed(a, e, movedPast: !retryable);
    }
  }
}
