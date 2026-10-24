import 'dart:async';

import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_source.dart';

/// Moves tags and favorites to a file's new id when a move/rename changes it
/// (`FileSource.idChanges`). Idempotent: copy rows to the new id (ignoring
/// ones already there), then drop the old id's rows.
class FileIdRekeyer {
  new(this._db, this._queue);

  final AppDatabase _db;
  final DbWriteQueue _queue;
  StreamSubscription<FileIdChange>? _sub;

  void start(Stream<FileIdChange> changes) {
    _sub ??= changes.listen((c) => rekey(c.oldId, c.newRef.id).fireAndForget());
  }

  Future<void> rekey(String oldId, String newId) {
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
      }),
    );
  }

  Future<void> dispose() async => await _sub?.cancel();
}
