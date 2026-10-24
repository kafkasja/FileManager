import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/tables/pending_deletes_table.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/trash_types.dart';

/// Whether files KFM put in the trash are still there (TASK-P8 stats:
/// "in trash" vs "freed").
class TrashLedger {
  new(this._db, this._queue, this._source, {this._clock = DateTime.now});

  final AppDatabase _db;
  final DbWriteQueue _queue;
  final FileSource _source;
  final DateTime Function() _clock;

  /// D5 restore / delete forever: known exactly, no guessing.
  Future<void> markLeft(Iterable<String> trashIds, TrashExit reason) {
    final ids = trashIds.toList();
    if (ids.isEmpty) return Future.value();
    return _queue.enqueue(
      null,
      () =>
          (_db.update(
            _db.pendingDeletes,
          )..where((p) => p.trashId.isIn(ids) & p.leftTrashAt.isNull())).write(
            PendingDeletesCompanion(
              leftTrashAt: Value(_clock()),
              leftTrashReason: Value(reason),
            ),
          ),
    );
  }

  /// Rows still "in trash" whose trashId isn't in [trashed] left the trash:
  /// the file exists again → restored, else → purged (emptied, expired).
  Future<void> reconcile(List<TrashedItem> trashed) async {
    final present = {for (final t in trashed) t.trashId};
    final rows =
        await (_db.select(_db.pendingDeletes)..where(
              (p) =>
                  p.status.equalsValue(PendingDeleteStatus.committed) &
                  p.trashId.isNotNull() &
                  p.leftTrashAt.isNull(),
            ))
            .get();
    final restored = <String>[];
    final purged = <String>[];
    for (final r in rows) {
      final id = r.trashId!;
      if (present.contains(id)) continue;
      (await _source.stat(r.fileId) != null ? restored : purged).add(id);
    }
    await markLeft(restored, TrashExit.restored);
    await markLeft(purged, TrashExit.purged);
  }

  /// [reconcile] with a fresh trash listing; a failing listing marks
  /// nothing (it must never turn everything into "freed").
  Future<void> reconcileNow() async {
    try {
      await reconcile(await _source.listTrashed());
    } on Object catch (e, st) {
      developer.log(
        'trash reconcile skipped',
        name: 'kfm.trash',
        error: e,
        stackTrace: st,
      );
    }
  }
}
