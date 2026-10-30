import 'package:kfm/features/rename/data/rename_batch_repository.dart';
import 'package:kfm/features/session/data/session_repository.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/trash/data/delete_queue.dart';
import 'package:meta/meta.dart';

/// What the user ticked in the Clear… sheet (SE3; B6 adds the selection).
@immutable
class ClearRequest {
  const new({
    this.resetLayout = false,
    this.newSession = false,
    this.clearSelection = false,
  });

  final bool resetLayout;
  final bool newSession;
  final bool clearSelection;

  bool get isEmpty => !resetLayout && !newSession && !clearSelection;
}

@immutable
class ClearResult {
  const new({
    this.layoutBefore,
    this.sessionEnded = false,
    this.commit = const CommitResult(),
    this.selectionCleared = 0,
  });

  /// The layout before a reset, for the snackbar's Undo.
  final SwipeLayout? layoutBefore;

  /// False when a new session was asked for but deletes are still queued
  /// (declined dialog / failure): the session stays active.
  final bool sessionEnded;
  final CommitResult commit;

  /// B6: files cleared from the selection (snackbar Undo restores them).
  final int selectionCleared;
}

/// SE3: reset action buttons and/or end the session (committing its
/// pending deletes first, without asking: decided by the user).
class ClearSessionUseCase {
  new(this._sessions, this._deletes, {this._renames, this._clearSelection});

  final SessionRepository _sessions;
  final DeleteQueue _deletes;

  /// P3: a collecting rename batch is dropped when the session ends.
  final RenameBatchRepository? _renames;

  /// B6: Clear all of the selection (keeps its Undo snapshot); returns how
  /// many were cleared.
  final Future<int> Function()? _clearSelection;

  Future<ClearResult> execute(Session session, ClearRequest request) async {
    final cleared = request.clearSelection
        ? await _clearSelection?.call() ?? 0
        : 0;
    SwipeLayout? before;
    if (request.resetLayout && session.layout != SwipeLayout.basic) {
      before = session.layout;
      await _sessions.saveLayout(session.id, SwipeLayout.basic);
    }
    if (!request.newSession) {
      return ClearResult(layoutBefore: before, selectionCleared: cleared);
    }

    await _sessions.flush();
    final commit = await _deletes.commitAll(session.id);
    if (await _deletes.stillQueued(session.id) > 0) {
      return ClearResult(
        layoutBefore: before,
        commit: commit,
        selectionCleared: cleared,
      );
    }
    await _renames?.discardForSession(session.id);
    await _sessions.endActive();
    return ClearResult(
      layoutBefore: before,
      sessionEnded: true,
      commit: commit,
      selectionCleared: cleared,
    );
  }

  /// Snackbar Undo of a layout reset.
  Future<void> undoLayoutReset(int sessionId, SwipeLayout before) =>
      _sessions.saveLayout(sessionId, before);
}
