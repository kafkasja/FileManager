import 'dart:io';

import 'package:kfm/core/background/cancel_token.dart';
import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/features/archive/domain/archive_job.dart';
import 'package:kfm/features/folders/data/file_operation_runner.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'archive_undo.g.dart';

/// Undo of a compress / extract (TASK-B5): the created files go away, then
/// the folders an extract created are removed if they are empty now. Used
/// by `LastOperationUndo`.
///
/// Why extracted files are not all trashed: on Android 11+ the system trash
/// renames a media file in place (`.trashed-<ts>-name`), so a folder the
/// extract created would never be empty again and would stay behind. A file
/// that is unchanged since the extract (same size and modified time as
/// recorded then, [ExtractedStamp]) is a copy of what is still in the zip,
/// so while the zip exists it is deleted permanently: nothing is lost, it
/// can be extracted again. Changed files, and every file once the zip is
/// gone, are trashed as usual (undoable from the trash page).
class ArchiveUndo {
  new({
    required this._source,
    required this._indexer,
    required this._indexDao,
    required this._writes,
    required this._lock,
  });

  final FileSource _source;
  final MediaIndexer _indexer;
  final MediaIndexDao _indexDao;
  final DbWriteQueue _writes;
  final SerialLock _lock;

  /// Removes [files] (each re-checked first: gone ones count as missing),
  /// then deletes [dirs] deepest first, non-recursively: a folder the user
  /// put something into meanwhile stays. Extract undo passes the source
  /// [zipPath] and the extract-time [stamps] (index-aligned with [files]):
  /// see the class doc for which files are deleted rather than trashed.
  Future<UndoOutcome> undoCreated(
    List<FileRef> files, {
    List<String> dirs = const [],
    String? zipPath,
    List<ExtractedStamp> stamps = const [],
    CancelToken? cancel,
    void Function(OperationProgress)? onProgress,
  }) async {
    final zipThere = zipPath != null && await File(zipPath).exists();
    final live = <FileRef>[];
    final unchanged = <String>{};
    var missing = 0;
    for (var i = 0; i < files.length; i++) {
      final f = files[i];
      final now = await _source.stat(f.id) ?? await _source.statPath(f.path);
      if (now == null) {
        missing++;
        continue;
      }
      live.add(now);
      if (zipThere && i < stamps.length && stamps[i].matches(now)) {
        unchanged.add(now.id);
      }
    }
    final bytesTotal = live.fold<int>(0, (s, f) => s + f.sizeBytes);
    var done = 0;
    var bytesDone = 0;
    void emit() => onProgress?.call(
      OperationProgress(
        done: done,
        total: live.length,
        bytesDone: bytesDone,
        bytesTotal: bytesTotal,
      ),
    );
    emit();
    var undone = 0;
    final failed = <FileOpException>[];
    UndoOutcome stop({bool declined = false, bool cancelled = false}) =>
        UndoOutcome(
          undone: undone,
          missing: missing,
          failed: failed,
          declined: declined,
          cancelled: cancelled,
        );
    const chunkSize = FileOperationRunner.deleteChunk;
    for (var i = 0; i < live.length; i += chunkSize) {
      if (cancel?.isCancelled ?? false) return stop(cancelled: true);
      final chunk = live.sublist(
        i,
        i + chunkSize > live.length ? live.length : i + chunkSize,
      );
      final delete = [
        for (final f in chunk)
          if (unchanged.contains(f.id)) f,
      ];
      final trash = [
        for (final f in chunk)
          if (!unchanged.contains(f.id)) f,
      ];
      if (delete.isNotEmpty) {
        try {
          await _lock.run(() => _source.deletePermanentlyBatch(delete));
          await _removeFromIndex([for (final f in delete) f.id]);
          undone += delete.length;
        } on FileOpException catch (e) {
          if (e.failure == FileOpFailure.userCancelled) {
            return stop(declined: true);
          }
          failed.add(e);
        }
      }
      if (trash.isNotEmpty) {
        final res = await _lock.run(() => _source.trashBatch(trash));
        if (res.userCancelled) return stop(declined: true);
        await _removeFromIndex([for (final t in res.trashed) t.original.id]);
        undone += res.trashed.length;
        failed.addAll(res.failed.values);
      }
      done += chunk.length;
      bytesDone += chunk.fold<int>(0, (s, f) => s + f.sizeBytes);
      emit();
    }
    final byDepth = [...dirs]
      ..sort((a, b) => '/'.allMatches(b).length - '/'.allMatches(a).length);
    for (final d in byDepth) {
      try {
        await Directory(d).delete();
      } on FileSystemException {
        // Not empty (or already gone): it stays.
      }
    }
    return stop();
  }

  /// Waits for queued index upserts first (an empty `addFiles` is a
  /// barrier), so a late upsert can't bring the rows back.
  Future<void> _removeFromIndex(List<String> ids) async {
    if (ids.isEmpty) return;
    await _indexer.addFiles(const []);
    await _writes.enqueue(null, () => _indexDao.deleteIds(ids));
  }
}

@Riverpod(keepAlive: true)
ArchiveUndo archiveUndo(Ref ref) => ArchiveUndo(
  source: ref.watch(fileSourceProvider),
  indexer: ref.watch(mediaIndexerProvider),
  indexDao: ref.watch(mediaIndexDaoProvider),
  writes: ref.watch(dbWriteQueueProvider),
  lock: ref.watch(historyLockProvider),
);
