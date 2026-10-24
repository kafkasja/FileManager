import 'package:kfm/features/session/data/session_repository.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/trash/data/delete_queue.dart';
import 'package:meta/meta.dart';

/// What the user ticked in the Clear… sheet (SE3). Selection clearing comes
/// with B6.
@immutable
class ClearRequest {
  const new({this.resetLayout = false, this.newSession = false});

  final bool resetLayout;
  final bool newSession;

  bool get isEmpty => !resetLayout && !newSession;
}

@immutable
class ClearResult {
  const new({
    this.layoutBefore,
    this.sessionEnded = false,
    this.commit = const CommitResult(),
  });

  /// The layout before a reset, for the snackbar's Undo.
  final SwipeLayout? layoutBefore;

  /// False when a new session was asked for but deletes are still queued
  /// (declined dialog / failure): the session stays active.
  final bool sessionEnded;
  final CommitResult commit;
}

/// SE3: reset action buttons and/or end the session (committing its
/// pending deletes first, without asking: decided by the user).
class ClearSessionUseCase {
  new(this._sessions, this._deletes);

  final SessionRepository _sessions;
  final DeleteQueue _deletes;

  Future<ClearResult> execute(Session session, ClearRequest request) async {
    SwipeLayout? before;
    if (request.resetLayout && session.layout != SwipeLayout.basic) {
      before = session.layout;
      await _sessions.saveLayout(session.id, SwipeLayout.basic);
    }
    if (!request.newSession) return ClearResult(layoutBefore: before);

    await _sessions.flush();
    final commit = await _deletes.commitAll(session.id);
    if (await _deletes.stillQueued(session.id) > 0) {
      return ClearResult(layoutBefore: before, commit: commit);
    }
    await _sessions.endActive();
    return ClearResult(
      layoutBefore: before,
      sessionEnded: true,
      commit: commit,
    );
  }

  /// Snackbar Undo of a layout reset.
  Future<void> undoLayoutReset(int sessionId, SwipeLayout before) =>
      _sessions.saveLayout(sessionId, before);
}
