import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/tables/session_actions_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';
import 'package:meta/meta.dart';

/// Last N swipes (of any kind) that are never physically deleted yet.
const kUndoSafeZone = 10;

/// One row of the undo log.
@immutable
class SessionAction {
  const new({
    required this.id,
    required this.sessionId,
    required this.seq,
    required this.fileId,
    required this.action,
    required this.previous,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final int sessionId;
  final int seq;
  final String fileId;
  final SwipeAction action;
  final PreviousState previous;
  final ActionStatus status;
  final DateTime createdAt;
}

/// The undo log (TASK-S2). `seq` is assigned in memory so very fast swipes
/// keep their order even though the writes are asynchronous.
class UndoRepository {
  new(this._db, this._queue, {this._clock = DateTime.now});

  final AppDatabase _db;
  final DbWriteQueue _queue;
  final DateTime Function() _clock;
  final Map<int, int> _nextSeq = {};

  /// Must run once per session before [record] (loads the highest seq).
  Future<void> prepare(int sessionId) async {
    if (_nextSeq.containsKey(sessionId)) return;
    await _queue.flush();
    final max = _db.sessionActions.seq.max();
    final row =
        await (_db.selectOnly(_db.sessionActions)
              ..addColumns([max])
              ..where(_db.sessionActions.sessionId.equals(sessionId)))
            .getSingle();
    _nextSeq[sessionId] = (row.read(max) ?? 0) + 1;
  }

  /// Appends an `applied` row without waiting for the disk. [alsoInTransaction]
  /// runs in the same transaction with the new row id (D2 queues the delete
  /// there). Returns the seq. Failures go to the write queue's error stream.
  int record(
    int sessionId,
    FileRef file,
    SwipeAction action,
    PreviousState previous, {
    Future<void> Function(int actionId)? alsoInTransaction,
  }) {
    final seq = reserveSeq(sessionId);
    _write(
      seq,
      sessionId,
      file.id,
      action,
      () async => previous,
      alsoInTransaction,
    );
    return seq;
  }

  /// Tag/favorite (P2): the change and its [PreviousState] are computed in
  /// the same queued transaction as the undo row. Returns the seq.
  int recordWith(
    int sessionId,
    FileRef file,
    SwipeAction action, {
    required Future<PreviousState> Function() applyInTransaction,
  }) {
    final seq = reserveSeq(sessionId);
    _write(seq, sessionId, file.id, action, applyInTransaction, null);
    return seq;
  }

  /// Move/copy (P2): the seq is taken at swipe time (keeps swipe order);
  /// [recordAt] writes the row once the file operation has finished. A
  /// failed operation leaves a gap, which is fine: seq only orders.
  int reserveSeq(int sessionId) {
    final next = _nextSeq[sessionId];
    if (next == null) {
      throw StateError('UndoRepository.prepare($sessionId) not called');
    }
    _nextSeq[sessionId] = next + 1;
    return next;
  }

  void recordAt(
    int seq,
    int sessionId,
    String fileId,
    SwipeAction action,
    PreviousState previous,
  ) => _write(seq, sessionId, fileId, action, () async => previous, null);

  void _write(
    int seq,
    int sessionId,
    String fileId,
    SwipeAction action,
    Future<PreviousState> Function() previous,
    Future<void> Function(int actionId)? alsoInTransaction,
  ) {
    final createdAt = _clock();
    _queue
        .enqueue(
          null, // every action is kept: never coalesce
          () => _db.transaction(() async {
            final state = await previous();
            final id = await _db
                .into(_db.sessionActions)
                .insert(
                  SessionActionsCompanion.insert(
                    sessionId: sessionId,
                    seq: seq,
                    fileId: fileId,
                    actionType: action.type.name,
                    payload: jsonEncode(action.toJson()),
                    previousState: jsonEncode(state.toJson()),
                    status: ActionStatus.applied,
                    createdAt: createdAt,
                  ),
                );
            await _writeLabel(id, sessionId, fileId, action, createdAt);
            await alsoInTransaction?.call(id);
          }),
        )
        .fireAndForget();
  }

  /// The undo stack (applied + committed rows), newest first.
  Future<List<SessionAction>> stack(int sessionId, {int? limit}) async {
    final query = _stackQuery(sessionId);
    if (limit != null) query.limit(limit);
    return (await query.get()).map(_toAction).toList();
  }

  Future<SessionAction?> top(int sessionId) async {
    final rows = await stack(sessionId, limit: 1);
    return rows.isEmpty ? null : rows.single;
  }

  Stream<int> watchUndoableCount(int sessionId) {
    final count = _db.sessionActions.id.count();
    return (_db.selectOnly(_db.sessionActions)
          ..addColumns([count])
          ..where(_inStack(_db.sessionActions, sessionId)))
        .watchSingle()
        .map((r) => r.read(count) ?? 0);
  }

  /// File ids with a non-undone action in the session (the deck skips them),
  /// plus copies a `copyTo` swipe made (they are never offered either).
  Future<Set<String>> actedFileIds(int sessionId) async {
    final t = _db.sessionActions;
    const created = CustomExpression<String>(
      r"json_extract(previous_state, '$.createdFileId')",
    );
    final rows =
        await (_db.selectOnly(t)
              ..addColumns([t.fileId, t.actionType, created])
              ..where(_inStack(t, sessionId)))
            .get();
    return {
      for (final r in rows) ...[
        r.read(t.fileId)!,
        if (r.read(t.actionType) == SwipeActionType.copyTo.name)
          ?r.read(created),
      ],
    };
  }

  /// Applied trash actions deeper than [safeZone] in the undo stack (depth
  /// counts every non-undone action), oldest first. One query.
  Future<List<SessionAction>> committableDeletes(
    int sessionId, {
    int safeZone = kUndoSafeZone,
  }) async {
    final all = await stack(sessionId);
    return all
        .skip(safeZone)
        .where(
          (a) =>
              a.status == ActionStatus.applied &&
              a.action.type == SwipeActionType.trash,
        )
        .toList()
        .reversed
        .toList();
  }

  /// Also drops the action's reviewed label (P7), so an older label for the
  /// same file applies again.
  Future<void> markUndone(int actionId) => _db.transaction(() async {
    await (_db.update(
      _db.sessionActions,
    )..where((a) => a.id.equals(actionId))).write(
      const SessionActionsCompanion(status: Value(ActionStatus.undone)),
    );
    await (_db.delete(
      _db.reviewedLabels,
    )..where((l) => l.actionId.equals(actionId))).go();
  });

  /// D2 commit: status + the trashed item undo will restore from.
  Future<void> markCommitted(int actionId, PreviousState previous) =>
      (_db.update(
        _db.sessionActions,
      )..where((a) => a.id.equals(actionId))).write(
        SessionActionsCompanion(
          status: const Value(ActionStatus.committed),
          previousState: Value(jsonEncode(previous.toJson())),
        ),
      );

  /// D5: a file restored from the trash page is no longer "deleted" in the
  /// active session's undo log.
  Future<void> markUndoneByFileId(int sessionId, String fileId) =>
      _db.transaction(() async {
        Expression<bool> match($SessionActionsTable a) =>
            a.sessionId.equals(sessionId) &
            a.fileId.equals(fileId) &
            a.actionType.equals(SwipeActionType.trash.name) &
            a.status.equalsValue(ActionStatus.committed);
        final ids =
            await (_db.selectOnly(_db.sessionActions)
                  ..addColumns([_db.sessionActions.id])
                  ..where(match(_db.sessionActions)))
                .map((r) => r.read(_db.sessionActions.id)!)
                .get();
        await (_db.update(_db.sessionActions)..where(match)).write(
          const SessionActionsCompanion(status: Value(ActionStatus.undone)),
        );
        await (_db.delete(
          _db.reviewedLabels,
        )..where((l) => l.actionId.isIn(ids))).go();
      });

  /// P7: "this file was reviewed in this preset", written with the action
  /// row. No index row (file unknown) → no label: it simply counts as not
  /// reviewed.
  Future<void> _writeLabel(
    int actionId,
    int sessionId,
    String fileId,
    SwipeAction action,
    DateTime at,
  ) => _db.customStatement(
    'INSERT INTO reviewed_labels (action_id, file_id, preset_key, '
    'action_type, action_detail, reviewed_at, file_modified_at_ms) '
    'SELECT ?, mi.id, COALESCE(s.preset_id, 0), ?, '
    'COALESCE(?, (SELECT name FROM tags WHERE id = ?)), ?, '
    'mi.modified_at_ms FROM sessions s JOIN media_index mi ON mi.id = ? '
    'WHERE s.id = ?',
    [
      actionId,
      action.type.name,
      _leaf(action.targetFolder),
      action.tagId,
      at.millisecondsSinceEpoch ~/ 1000,
      fileId,
      sessionId,
    ],
  );

  static String? _leaf(String? path) {
    if (path == null) return null;
    final parts = path.split('/').where((p) => p.isNotEmpty);
    return parts.isEmpty ? null : parts.last;
  }

  Future<SessionAction?> byId(int actionId) async {
    final row = await (_db.select(
      _db.sessionActions,
    )..where((a) => a.id.equals(actionId))).getSingleOrNull();
    return row == null ? null : _toAction(row);
  }

  SimpleSelectStatement<$SessionActionsTable, SessionActionRow> _stackQuery(
    int sessionId,
  ) => _db.select(_db.sessionActions)
    ..where((a) => _inStack(a, sessionId))
    ..orderBy([(a) => OrderingTerm.desc(a.seq)]);

  static Expression<bool> _inStack($SessionActionsTable a, int sessionId) =>
      a.sessionId.equals(sessionId) &
      a.status.equalsValue(ActionStatus.undone).not();

  static SessionAction _toAction(SessionActionRow r) {
    final action = SwipeAction.fromJson(
      (jsonDecode(r.payload) as Map).cast<String, Object?>(),
    );
    return SessionAction(
      id: r.id,
      sessionId: r.sessionId,
      seq: r.seq,
      fileId: r.fileId,
      action: action,
      previous: PreviousState.fromJson(
        action.type,
        (jsonDecode(r.previousState) as Map).cast<String, Object?>(),
      ),
      status: r.status,
      createdAt: r.createdAt,
    );
  }
}
