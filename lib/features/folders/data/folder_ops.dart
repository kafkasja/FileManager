import 'dart:async';

import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'folder_ops.g.dart';

/// A finished folder rename.
typedef FolderRenamed = ({String oldPath, String newPath, List<FileRef> files});

/// Folder create / rename for Browse (TASK-B4 §10). Rename needs All files
/// access: the UI calls `ensureAllFilesAccess` first (F3 throws
/// `permissionDenied` otherwise). Failures throw `FileOpException`.
class FolderOps {
  new({required this._source, required this._indexer, required this._lock});

  final FileSource _source;
  final MediaIndexer _indexer;
  final SerialLock _lock;

  /// Returns the new folder's path; throws `targetExists` / `invalidName`.
  Future<String> createFolder(String parentPath, String name) =>
      _source.createFolder(parentPath, name);

  /// Renames [folderPath] to [newName] and upserts every file inside, so
  /// rows whose id didn't change get the new folder (rows whose id changed
  /// are re-keyed through `idChanges`; stale ones go at the next full scan).
  /// Record the result with `LastOperationUndo.recordFolderRename` for undo.
  ///
  /// The upsert is queued after the lock is released and not awaited:
  /// `MediaIndexer` jobs are serial, so it can wait behind a running full
  /// scan (it reports its own failures as `IndexFailed`).
  Future<FolderRenamed> renameFolder(String folderPath, String newName) async {
    final result = await _lock.run(
      () => _source.renameFolder(folderPath, newName),
    );
    unawaited(_indexer.addFiles(result.files));
    return (oldPath: folderPath, newPath: result.path, files: result.files);
  }
}

@Riverpod(keepAlive: true)
FolderOps folderOps(Ref ref) => FolderOps(
  source: ref.watch(fileSourceProvider),
  indexer: ref.watch(mediaIndexerProvider),
  lock: ref.watch(historyLockProvider),
);
