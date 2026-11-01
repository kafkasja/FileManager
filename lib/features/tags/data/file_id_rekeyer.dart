import 'dart:async';

import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_source.dart';

/// Moves every file-id keyed row to a file's new id when a move/rename
/// changes it (`FileSource.idChanges`): tags, favorites, reviewed labels and
/// (H4) undo log, queued deletes and rename batch items, (B6) the
/// selection and its Clear all snapshot, (SS1) swipe source items, (C2) image signals, similar group items and
/// dismissals, (C5) EXIF rows, smart group members and covers, (C3) AI labels and their
/// status. Idempotent: copy
/// rows to the new id (ignoring ones already there), then drop the old id's
/// rows.
class FileIdRekeyer {
  new(this._db, this._queue);

  final AppDatabase _db;
  final DbWriteQueue _queue;
  StreamSubscription<FileIdChange>? _sub;

  void start(Stream<FileIdChange> changes) {
    _sub ??= changes.listen(
      (c) => rekey(
        c.oldId,
        c.newRef.id,
        newModifiedMs: c.newRef.modifiedAt.millisecondsSinceEpoch,
      ).fireAndForget(),
    );
  }

  Future<void> rekey(String oldId, String newId, {int? newModifiedMs}) {
    if (oldId == newId) return Future.value();
    return _queue.enqueue(
      null,
      () => _db.transaction(() async {
        await _db.customStatement(
          'INSERT OR IGNORE INTO file_tags (file_id, tag_id, added_at) '
          'SELECT ?, tag_id, added_at FROM file_tags WHERE file_id = ?',
          [newId, oldId],
        );
        await _db.customStatement('DELETE FROM file_tags WHERE file_id = ?', [
          oldId,
        ]);
        await _db.customStatement(
          'INSERT OR IGNORE INTO favorites (file_id, added_at) '
          'SELECT ?, added_at FROM favorites WHERE file_id = ?',
          [newId, oldId],
        );
        await _db.customStatement('DELETE FROM favorites WHERE file_id = ?', [
          oldId,
        ]);
        // P7: a move doesn't make a file "edited": labels follow it.
        await _db.customStatement(
          'UPDATE reviewed_labels SET file_id = ?, '
          'file_modified_at_ms = COALESCE(?, file_modified_at_ms) '
          'WHERE file_id = ?',
          [newId, newModifiedMs, oldId],
        );
        // H4: undo and queued deletes look the file up by this id. Committed
        // rows are history (P8 reads them by trash id).
        await _db.customStatement(
          'UPDATE session_actions SET file_id = ? '
          "WHERE file_id = ? AND status <> 'committed'",
          [newId, oldId],
        );
        // KFM moved it, the user didn't edit it: keep the delete valid.
        await _db.customStatement(
          'UPDATE pending_deletes SET file_id = ?, '
          'file_modified_at_ms = COALESCE(?, file_modified_at_ms) '
          "WHERE file_id = ? AND status IN ('queued', 'committing')",
          [newId, newModifiedMs, oldId],
        );
        // `file_id` is the stable key while a batch applies/reverts (the
        // runner tracks `current_file_id` itself): re-key only collecting
        // batches. PK (batch_id, file_id): a leftover means the new id was
        // already in the batch.
        await _db.customStatement(
          'UPDATE OR IGNORE rename_batch_items '
          'SET file_id = ?, current_file_id = ? WHERE file_id = ? AND '
          'batch_id IN (SELECT id FROM rename_batches '
          "WHERE status = 'collecting')",
          [newId, newId, oldId],
        );
        await _db.customStatement(
          'DELETE FROM rename_batch_items WHERE file_id = ? AND '
          'batch_id IN (SELECT id FROM rename_batches '
          "WHERE status = 'collecting')",
          [oldId],
        );
        // SS1: an open list source keeps the file at its position. PK is
        // (source_id, position): a plain UPDATE can't conflict.
        await _db.customStatement(
          'UPDATE swipe_source_items SET file_id = ? WHERE file_id = ?',
          [newId, oldId],
        );
        // C2: a move doesn't make a photo different: signals follow it
        // (no recompute); group membership and dismissals too.
        await _db.customStatement(
          'UPDATE OR REPLACE image_signals SET file_id = ?, '
          'file_modified_at_ms = COALESCE(?, file_modified_at_ms) '
          'WHERE file_id = ?',
          [newId, newModifiedMs, oldId],
        );
        for (final table in ['similar_group_items', 'similar_dismissed']) {
          await _db.customStatement(
            'UPDATE OR IGNORE $table SET file_id = ? WHERE file_id = ?',
            [newId, oldId],
          );
          await _db.customStatement('DELETE FROM $table WHERE file_id = ?', [
            oldId,
          ]);
        }
        // C5: a move isn't an edit: EXIF follows the file (not read again);
        // so do group membership and covers.
        await _db.customStatement(
          'INSERT OR IGNORE INTO media_locations (file_id, '
          'file_modified_at_ms, lat, lng, front_camera, location_readable, '
          'read_at_ms) SELECT ?, COALESCE(?, file_modified_at_ms), lat, lng, '
          'front_camera, location_readable, read_at_ms FROM media_locations '
          'WHERE file_id = ?',
          [newId, newModifiedMs, oldId],
        );
        await _db.customStatement(
          'DELETE FROM media_locations WHERE file_id = ?',
          [oldId],
        );
        await _db.customStatement(
          'UPDATE OR IGNORE smart_group_items SET file_id = ? WHERE file_id = ?',
          [newId, oldId],
        );
        await _db.customStatement(
          'DELETE FROM smart_group_items WHERE file_id = ?',
          [oldId],
        );
        await _db.customStatement(
          'UPDATE smart_groups SET cover_file_id = ? WHERE cover_file_id = ?',
          [newId, oldId],
        );
        // C3: a move isn't an edit: labels and the status row follow the
        // file, so it isn't labeled again.
        await _db.customStatement(
          'INSERT OR IGNORE INTO ai_labels (file_id, label, confidence) '
          'SELECT ?, label, confidence FROM ai_labels WHERE file_id = ?',
          [newId, oldId],
        );
        await _db.customStatement('DELETE FROM ai_labels WHERE file_id = ?', [
          oldId,
        ]);
        await _db.customStatement(
          'INSERT OR IGNORE INTO ai_label_status (file_id, outcome, '
          'model_version, file_modified_at_ms, attempts, error, '
          'processed_at_ms) SELECT ?, outcome, model_version, '
          'COALESCE(?, file_modified_at_ms), attempts, error, processed_at_ms '
          'FROM ai_label_status WHERE file_id = ?',
          [newId, newModifiedMs, oldId],
        );
        await _db.customStatement(
          'DELETE FROM ai_label_status WHERE file_id = ?',
          [oldId],
        );
        // B6: the selection keeps the file's place in the order.
        for (final table in ['selection_items', 'selection_snapshots']) {
          await _db.customStatement(
            'INSERT OR IGNORE INTO $table (file_id, seq, added_at) '
            'SELECT ?, seq, added_at FROM $table WHERE file_id = ?',
            [newId, oldId],
          );
          await _db.customStatement('DELETE FROM $table WHERE file_id = ?', [
            oldId,
          ]);
        }
      }),
    );
  }

  Future<void> dispose() async => await _sub?.cancel();
}
