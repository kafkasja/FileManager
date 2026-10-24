import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/tables/pending_deletes_table.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/trash/domain/delete_batch_policy.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';
import 'package:meta/meta.dart';

/// Counts for the banner and the session-end summary.
@immutable
class PendingDeleteSummary {
  const new({
    required this.queued,
    required this.failed,
    required this.committed,
    required this.committedBytes,
    this.folderUnavailable = 0,
  });

  static const empty = PendingDeleteSummary(
    queued: 0,
    failed: 0,
    committed: 0,
    committedBytes: 0,
  );

  final int queued;

  /// All failed rows, [folderUnavailable] included.
  final int failed;
  final int committed;
  final int committedBytes;

  /// H2: failed because the pending-delete folder can't be used.
  final int folderUnavailable;
}

/// Result of one commit run.
@immutable
class CommitResult {
  const new({
    this.committed = 0,
    this.failed = 0,
    this.bytes = 0,
    this.userCancelled = false,
    this.folderUnavailable = 0,
  });

  final int committed;
  final int failed;
  final int bytes;

  /// H2: of [failed], files the pending-delete folder couldn't take.
  final int folderUnavailable;

  /// The user declined the system dialog: rows went back to queued.
  final bool userCancelled;
}

/// Deferred, batched deletes (TASK-D2). Shares [SerialLock] with undo so a
/// commit and an undo never interleave.
class DeleteQueue {
  new({
    required this._db,
    required this._lock,
    required this._source,
    required this._undo,
    required this._index,
    this._policy = const DeleteBatchPolicy(),
    this._clock = DateTime.now,
  });

  final AppDatabase _db;
  final SerialLock _lock;
  final FileSource _source;
  final UndoRepository _undo;
  final MediaIndexDao _index;
  final DeleteBatchPolicy _policy;
  final DateTime Function() _clock;

  final StreamController<Object> _errors = StreamController<Object>.broadcast();

  /// After a declined/failed batch, wait until this many deletes are
  /// eligible before trying again during the session (per session).
  final Map<int, int> _retryAt = {};

  /// Commit failures that aren't per-file (e.g. platform not supported yet).
  Stream<Object> get errors => _errors.stream;

  /// Runs inside the transaction that records the trash action (S2).
  Future<void> queueInTransaction({
    required int actionId,
    required int sessionId,
    required FileRef file,
    required DeleteMode mode,
  }) => _db
      .into(_db.pendingDeletes)
      .insert(
        PendingDeletesCompanion.insert(
          actionId: actionId,
          sessionId: sessionId,
          fileId: file.id,
          mode: mode.name,
          status: PendingDeleteStatus.queued,
          sizeBytes: file.sizeBytes,
          fileModifiedAtMs: file.modifiedAt.millisecondsSinceEpoch,
          queuedAt: _clock(),
        ),
      );

  /// Undo of an uncommitted delete: nothing touched the disk, drop the row.
  Future<void> unqueue(int actionId) =>
      (_db.delete(_db.pendingDeletes)..where(
            (p) =>
                p.actionId.equals(actionId) &
                p.status.isNotInValues([PendingDeleteStatus.committed]),
          ))
          .go();

  /// After each swipe: commits when enough deletes are outside the safe zone.
  /// Never throws (the swipe path doesn't await it); problems go to [errors].
  Future<CommitResult> maybeCommit(int sessionId) => _lock.run(() async {
    try {
      final eligible = await _undo.committableDeletes(sessionId);
      if (!_policy.shouldCommitDuringSession(eligible.length) ||
          eligible.length < (_retryAt[sessionId] ?? 0)) {
        return const CommitResult();
      }
      final rows = await _rowsForActions([for (final a in eligible) a.id]);
      final result = await _commit(rows);
      if (result.userCancelled || result.committed == 0) {
        _retryAt[sessionId] = eligible.length + _policy.threshold;
      } else {
        _retryAt.remove(sessionId);
      }
      return result;
    } on Object catch (e) {
      _report(e);
      return const CommitResult();
    }
  });

  /// The banner's Retry: deletes outside the safe zone, now, ignoring the
  /// batch size and the back-off.
  Future<CommitResult> commitEligible(int sessionId) => _lock.run(() async {
    _retryAt.remove(sessionId);
    final eligible = await _undo.committableDeletes(sessionId);
    final failedRows =
        await (_db.select(_db.pendingDeletes)..where(
              (p) =>
                  p.sessionId.equals(sessionId) &
                  p.status.equalsValue(PendingDeleteStatus.failed),
            ))
            .get();
    final rows = [
      ...await _rowsForActions([for (final a in eligible) a.id]),
      ...failedRows.where((r) => eligible.any((a) => a.id == r.actionId)),
    ];
    return await _commit(rows);
  });

  /// Session end (Done / clear): everything still queued or failed,
  /// including the last 10 swipes.
  Future<CommitResult> commitAll(int sessionId) => _lock.run(() async {
    final rows =
        await (_db.select(_db.pendingDeletes)..where(
              (p) =>
                  p.sessionId.equals(sessionId) &
                  p.status.isInValues([
                    PendingDeleteStatus.queued,
                    PendingDeleteStatus.failed,
                  ]),
            ))
            .get();
    return await _commit(rows);
  });

  /// Deletes of [sessionId] still waiting (queued or committing).
  Future<int> stillQueued(int sessionId) async {
    final count = _db.pendingDeletes.id.count();
    final row =
        await (_db.selectOnly(_db.pendingDeletes)
              ..addColumns([count])
              ..where(
                _db.pendingDeletes.sessionId.equals(sessionId) &
                    _db.pendingDeletes.status.isInValues([
                      PendingDeleteStatus.queued,
                      PendingDeleteStatus.committing,
                    ]),
              ))
            .getSingle();
    return row.read<int>(count) ?? 0;
  }

  /// Startup (and deck build): rows stuck in `committing` because the app or
  /// its activity died mid-batch, e.g. while the system dialog was open (H1).
  /// File still there → queued again. File gone → committed; a trash-mode
  /// row gets its TrashedItem from the system trash / pending folder so undo
  /// can still restore it. Returns the number of rows recovered.
  Future<int> recoverStuck() => _lock.run(() async {
    final stuck =
        await (_db.select(_db.pendingDeletes)..where(
              (p) => p.status.equalsValue(PendingDeleteStatus.committing),
            ))
            .get();
    final trashed = _TrashLookup(this);
    for (final row in stuck) {
      if (await _source.stat(row.fileId) != null) {
        await _setStatus([row.id], PendingDeleteStatus.queued);
      } else {
        await _markCommitted(row, await trashed.itemFor(row));
      }
    }
    return stuck.length;
  });

  Stream<PendingDeleteSummary> watchSummary(int sessionId) =>
      (_db.select(
        _db.pendingDeletes,
      )..where((p) => p.sessionId.equals(sessionId))).watch().map((rows) {
        var queued = 0;
        var failed = 0;
        var committed = 0;
        var bytes = 0;
        var unavailable = 0;
        for (final r in rows) {
          switch (r.status) {
            case PendingDeleteStatus.queued:
            case PendingDeleteStatus.committing:
              queued++;
            case PendingDeleteStatus.failed:
              failed++;
              if (r.failureReason == _unavailableCode) unavailable++;
            case PendingDeleteStatus.committed:
              committed++;
              bytes += r.sizeBytes;
          }
        }
        return PendingDeleteSummary(
          queued: queued,
          failed: failed,
          committed: committed,
          committedBytes: bytes,
          folderUnavailable: unavailable,
        );
      });

  /// H2: deletes the pending folder couldn't take, any session, newest
  /// first. They wait for Keep / Delete permanently (or a Retry).
  Stream<List<PendingDeleteRow>> watchFolderUnavailable() =>
      (_db.select(_db.pendingDeletes)
            ..where(
              (p) =>
                  p.status.equalsValue(PendingDeleteStatus.failed) &
                  p.failureReason.equals(_unavailableCode),
            )
            ..orderBy([(p) => OrderingTerm.desc(p.queuedAt)]))
          .watch();

  /// H2: the user chose "Delete permanently" for files the pending folder
  /// couldn't take. A file changed since the swipe is never deleted.
  Future<CommitResult> deleteUnavailablePermanently(
    List<int> rowIds,
  ) => _lock.run(() async {
    final rows = await _unavailableRows(rowIds);
    if (rows.isEmpty) return const CommitResult();
    await _setStatus([
      for (final r in rows) r.id,
    ], PendingDeleteStatus.committing);
    var committed = 0;
    var failed = 0;
    var bytes = 0;
    final toDelete = <(PendingDeleteRow, FileRef)>[];
    for (final row in rows) {
      final current = await _source.stat(row.fileId);
      if (current == null) {
        await _markCommitted(row, null, mode: DeleteMode.permanent.name);
        committed++;
        bytes += row.sizeBytes;
      } else if (current.modifiedAt.millisecondsSinceEpoch !=
          row.fileModifiedAtMs) {
        await _markFailed(row, 'file changed since it was swiped');
        failed++;
      } else {
        toDelete.add((row, current));
      }
    }
    if (toDelete.isEmpty) {
      return CommitResult(committed: committed, failed: failed, bytes: bytes);
    }
    try {
      await _source.deletePermanentlyBatch([for (final (_, f) in toDelete) f]);
    } on Object catch (e) {
      for (final (row, _) in toDelete) {
        await _markFailed(row, _unavailableCode);
      }
      final cancelled =
          e is FileOpException && e.failure == FileOpFailure.userCancelled;
      if (!cancelled) _report(e);
      return CommitResult(
        committed: committed,
        failed: failed + toDelete.length,
        bytes: bytes,
        userCancelled: cancelled,
        folderUnavailable: toDelete.length,
      );
    }
    for (final (row, _) in toDelete) {
      await _markCommitted(row, null, mode: DeleteMode.permanent.name);
      committed++;
      bytes += row.sizeBytes;
    }
    return CommitResult(committed: committed, failed: failed, bytes: bytes);
  });

  /// H2: try the pending folder again (e.g. after All files access was
  /// granted), for every session.
  Future<CommitResult> retryUnavailable() => _lock.run(() async {
    final rows =
        await (_db.select(_db.pendingDeletes)..where(
              (p) =>
                  p.status.equalsValue(PendingDeleteStatus.failed) &
                  p.failureReason.equals(_unavailableCode),
            ))
            .get();
    return await _commit(rows);
  });

  /// H2: "Keep": the file stays, the swipe counts as undone, nothing is
  /// deleted.
  Future<void> keepUnavailable(List<int> rowIds) => _lock.run(() async {
    final rows = await _unavailableRows(rowIds);
    await _db.transaction(() async {
      for (final row in rows) {
        await (_db.delete(
          _db.pendingDeletes,
        )..where((p) => p.id.equals(row.id))).go();
        await _undo.markUndone(row.actionId);
      }
    });
  });

  Future<List<PendingDeleteRow>> _unavailableRows(List<int> rowIds) =>
      (_db.select(_db.pendingDeletes)..where(
            (p) =>
                p.id.isIn(rowIds) &
                p.status.equalsValue(PendingDeleteStatus.failed) &
                p.failureReason.equals(_unavailableCode),
          ))
          .get();

  /// Stable `failure_reason` for H2 rows (other failures keep free text).
  static final String _unavailableCode =
      FileOpFailure.pendingFolderUnavailable.name;

  Future<void> dispose() => _errors.close();

  /// To the UI (snackbar) and the device log (diagnosing real phones).
  void _report(Object error) {
    debugPrint('kfm.trash: commit failed: $error');
    if (!_errors.isClosed) _errors.add(error);
  }

  // ---- commit ----

  Future<CommitResult> _commit(List<PendingDeleteRow> rows) async {
    if (rows.isEmpty) return const CommitResult();
    await _setStatus([
      for (final r in rows) r.id,
    ], PendingDeleteStatus.committing);

    var committed = 0;
    var failed = 0;
    var bytes = 0;
    var cancelled = false;
    var unavailable = 0;

    // Re-check every file: gone already = goal reached; changed = never
    // delete something the user didn't see.
    final toDelete = <DeleteMode, List<(PendingDeleteRow, FileRef)>>{};
    final trashed = _TrashLookup(this);
    for (final row in rows) {
      final current = await _source.stat(row.fileId);
      if (current == null) {
        // Gone already (trashed elsewhere, or an interrupted earlier batch
        // that the system did carry out): keep its trash item for undo.
        await _markCommitted(row, await trashed.itemFor(row));
        committed++;
        bytes += row.sizeBytes;
      } else if (current.modifiedAt.millisecondsSinceEpoch !=
          row.fileModifiedAtMs) {
        await _markFailed(row, 'file changed since it was swiped');
        failed++;
      } else {
        (toDelete[DeleteMode.parse(row.mode)] ??= []).add((row, current));
      }
    }

    for (final MapEntry(key: mode, value: batch) in toDelete.entries) {
      final files = [for (final (_, f) in batch) f];
      try {
        if (mode == DeleteMode.permanent) {
          await _source.deletePermanentlyBatch(files);
          for (final (row, _) in batch) {
            await _markCommitted(row, null);
            committed++;
            bytes += row.sizeBytes;
          }
          continue;
        }
        final result = await _source.trashBatch(files);
        if (result.userCancelled) {
          cancelled = true;
          await _setStatus([
            for (final (r, _) in batch) r.id,
          ], PendingDeleteStatus.queued);
          continue;
        }
        final trashedById = {for (final t in result.trashed) t.original.id: t};
        for (final (row, file) in batch) {
          final error = result.failed[file.id];
          if (trashedById[file.id] case final item?) {
            await _markCommitted(row, item);
            committed++;
            bytes += row.sizeBytes;
          } else if (error?.failure == FileOpFailure.notFound) {
            await _markCommitted(row, null);
            committed++;
            bytes += row.sizeBytes;
          } else if (error?.failure == FileOpFailure.pendingFolderUnavailable) {
            // H2: not deleted; the user picks Keep / Delete permanently.
            await _markFailed(row, _unavailableCode);
            failed++;
            unavailable++;
          } else {
            await _markFailed(row, error?.message ?? 'not trashed');
            failed++;
          }
        }
      } on FileOpException catch (e) {
        if (e.failure == FileOpFailure.userCancelled) {
          cancelled = true;
          await _setStatus([
            for (final (r, _) in batch) r.id,
          ], PendingDeleteStatus.queued);
        } else {
          await _requeueWithError(batch, e);
        }
      } on Object catch (e) {
        // Not a per-file problem (e.g. trash not supported yet): keep the
        // rows queued so nothing is lost, and report it.
        await _requeueWithError(batch, e);
      }
    }
    return CommitResult(
      committed: committed,
      failed: failed,
      bytes: bytes,
      userCancelled: cancelled,
      folderUnavailable: unavailable,
    );
  }

  /// Where files that vanished from normal queries are now, keyed by the
  /// FileRef.id they had before (H1). The newest item wins when the same id
  /// was trashed twice. Null when the trash can't be listed (reported).
  Future<Map<String, TrashedItem>?> _trashedByOriginalId() async {
    try {
      final byId = <String, TrashedItem>{};
      for (final item in await _source.listTrashed()) {
        final seen = byId[item.original.id];
        if (seen == null || item.trashedAt.isAfter(seen.trashedAt)) {
          byId[item.original.id] = item;
        }
      }
      return byId;
    } on Object catch (e) {
      _report(e);
      return null;
    }
  }

  Future<void> _requeueWithError(
    List<(PendingDeleteRow, FileRef)> batch,
    Object error,
  ) async {
    await _setStatus([
      for (final (r, _) in batch) r.id,
    ], PendingDeleteStatus.queued);
    _report(error);
  }

  /// [mode] overrides the row's mode with what actually happened (H2:
  /// "Delete permanently instead" on a trash-mode row).
  Future<void> _markCommitted(
    PendingDeleteRow row,
    TrashedItem? item, {
    String? mode,
  }) async {
    final done = mode ?? row.mode;
    await _db.transaction(() async {
      await (_db.update(
        _db.pendingDeletes,
      )..where((p) => p.id.equals(row.id))).write(
        PendingDeletesCompanion(
          status: const Value(PendingDeleteStatus.committed),
          committedMode: Value(done),
          committedAt: Value(_clock()),
          failureReason: const Value(null),
          trashId: Value(done == 'trash' ? item?.trashId : null),
        ),
      );
      await _undo.markCommitted(
        row.actionId,
        TrashPreviousState(mode: done, trashedItem: item?.toJson()),
      );
    });
    await _index.deleteIds([row.fileId]);
  }

  Future<void> _markFailed(PendingDeleteRow row, String reason) =>
      (_db.update(_db.pendingDeletes)..where((p) => p.id.equals(row.id))).write(
        PendingDeletesCompanion(
          status: const Value(PendingDeleteStatus.failed),
          failureReason: Value(reason),
        ),
      );

  Future<void> _setStatus(List<int> ids, PendingDeleteStatus status) =>
      (_db.update(_db.pendingDeletes)..where((p) => p.id.isIn(ids))).write(
        PendingDeletesCompanion(status: Value(status)),
      );

  Future<List<PendingDeleteRow>> _rowsForActions(List<int> actionIds) =>
      (_db.select(_db.pendingDeletes)..where(
            (p) =>
                p.actionId.isIn(actionIds) &
                p.status.equalsValue(PendingDeleteStatus.queued),
          ))
          .get();
}

/// Lists the trash at most once per run, and only when a trash-mode row's
/// file is gone.
class _TrashLookup {
  new(this._queue);

  final DeleteQueue _queue;
  Map<String, TrashedItem>? _byId;
  var _listed = false;

  Future<TrashedItem?> itemFor(PendingDeleteRow row) async {
    if (DeleteMode.parse(row.mode) != DeleteMode.trash) return null;
    if (!_listed) {
      _listed = true;
      _byId = await _queue._trashedByOriginalId();
    }
    return _byId?[row.fileId];
  }
}
