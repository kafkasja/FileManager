import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:kfm/core/background/cancel_token.dart';
import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/temp_file_ledger.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/features/archive/data/archive_worker.dart';
import 'package:kfm/features/archive/domain/archive_job.dart';
import 'package:kfm/features/folders/data/file_operation_runner.dart';
import 'package:kfm/features/folders/ui/last_operation_undo.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'archive_service.g.dart';

/// Zip / unzip jobs (TASK-B5): one worker isolate per job, progress, cancel,
/// the temp ledger, the space check, and registering the results (F3 scan
/// → index → `LastOperationUndo`).
class ArchiveService {
  new({
    required this._source,
    required this._indexer,
    required this._indexDao,
    required this._writes,
    required this._lock,
    required this._ledger,
    required this._recordUndo,
    this.killAfter = const Duration(seconds: 2),
  });

  final FileSource _source;
  final MediaIndexer _indexer;
  final MediaIndexDao _indexDao;
  final DbWriteQueue _writes;
  final SerialLock _lock;
  final Future<TempFileLedger?> _ledger;
  final void Function(LastOperation op) _recordUndo;

  /// How long a cancelled worker gets to clean up before it is killed.
  final Duration killAfter;

  /// How often [run] polls its [CancelToken].
  static const cancelPoll = Duration(milliseconds: 100);

  /// Free space kept on top of the bytes a job writes.
  static const int spaceMargin = FileOperationRunner.spaceMargin;

  Future<void> _indexTail = Future<void>.value();

  /// Completes once every index update queued so far is written.
  Future<void> get indexSettled => _indexTail;

  /// The zip's entries, read from its central directory in a worker
  /// isolate (no file data). Throws [CorruptArchive] / [ArchiveIoError].
  Future<ArchiveListing> list(String zipPath) async =>
      await _spawn(ListRequest(zipPath), null, null, null) as ArchiveListing;

  /// Runs [job]. Checks free space first ([NotEnoughSpace]), then works in
  /// a temp file / folder listed in the temp ledger until the final rename.
  /// [cancel] is polled every [cancelPoll]; a worker that doesn't stop
  /// within [killAfter] is killed. Once the worker starts moving its result
  /// into place, cancel is ignored (a half-moved result would be lost).
  /// On success the new files are registered with F3, added to the index,
  /// and the undo is recorded ([ArchiveOutput.undoRecorded]). Throws
  /// [ArchiveError] subclasses.
  ///
  /// [replacing] (compress only: the collision dialog's Replace): the zip
  /// already at `job.outputPath`. The worker writes the new zip under a
  /// free name (`name (1).zip`); only then is [replacing] trashed and the
  /// new zip renamed to `job.outputPath`. If that trash is declined or
  /// fails, the old zip stays and the new one keeps its ` (1)` name
  /// ([ArchiveOutput.replaceFailed]).
  Future<ArchiveOutput> run(
    ArchiveJob job, {
    required CancelToken cancel,
    void Function(ArchiveProgress)? onProgress,
    FileRef? replacing,
  }) async {
    await _checkSpace(job);
    if (cancel.isCancelled) throw const ArchiveCancelled();
    final temp = await _tempFor(job);
    final ledger = await _ledger;
    await ledger?.add(temp);
    final ArchiveOutput output;
    try {
      output = await _spawn(job, temp, cancel, onProgress) as ArchiveOutput;
    } finally {
      // A killed worker leaves its temp: removed here, or (if that fails)
      // by the ledger at the next start.
      if (!await _gone(temp)) await _deleteQuietly(temp);
      if (await _gone(temp)) await ledger?.remove(temp);
    }
    var files = output.files;
    var replaceFailed = false;
    if (job is CompressJob && replacing != null && files.length == 1) {
      try {
        await trashForReplace(replacing);
        if (files.single != job.outputPath && await _gone(job.outputPath)) {
          await File(files.single).rename(job.outputPath);
          files = [job.outputPath];
        }
      } on FileOpException {
        replaceFailed = true;
      } on FileSystemException {
        // Trashed, but the rename failed: the new zip keeps its name.
      }
    }
    final refs = await _source.registerCreated(files);
    _indexAdd(refs);
    final op = switch (job) {
      CompressJob() => refs.isEmpty ? null : CompressDone(refs.single),
      ExtractJob(:final zipPath) =>
        refs.isEmpty && output.dirs.isEmpty
            ? null
            : ExtractDone(
                refs,
                output.dirs,
                zipPath: zipPath,
                stamps: [for (final r in refs) ExtractedStamp.of(r)],
              ),
    };
    // An extract that made nothing still clears the stored undo (it would
    // otherwise point at an older operation).
    if (op != null) {
      _recordUndo(op);
    } else if (job is ExtractJob) {
      _recordUndo(const ExtractDone([], []));
    }
    return ArchiveOutput(
      files: files,
      dirs: output.dirs,
      undoRecorded: op != null,
      replaceFailed: replaceFailed,
    );
  }

  /// Where "Extract here" puts [zipPath]'s files: the zip's folder plus
  /// the zip's base name (`photos.zip` → `photos`), made unique
  /// (`photos (1)`). Not created.
  Future<String> extractHereTarget(String zipPath) async {
    final folder = parentOf(zipPath);
    final base = splitExtension(nameOf(zipPath)).$1;
    var candidate = '$folder/$base';
    for (var i = 1; !await _gone(candidate); i++) {
      candidate = '$folder/$base ($i)';
    }
    return candidate;
  }

  /// Null when [files] can be zipped: all local (`ms:` / `path:`) on
  /// internal storage. Else a short reason code (`'notLocal'`) the UI maps
  /// to "Can't zip files from this place yet".
  String? compressBlockReason(List<FileRef> files) {
    for (final f in files) {
      final localId = f.id.startsWith('ms:') || f.id.startsWith('path:');
      if (f.origin != FileOrigin.local || !localId) return notLocalReason;
    }
    return null;
  }

  static const notLocalReason = 'notLocal';

  /// Null when a zip can be written into [folderPath] (Save to… / Extract
  /// to…): internal storage only, like [compressBlockReason]. Else
  /// [notLocalReason].
  String? destinationBlockReason(String folderPath) =>
      isInternalStoragePath(folderPath) ? null : notLocalReason;

  /// `/storage/emulated/<user>` and below (not SD cards / USB drives).
  static bool isInternalStoragePath(String path) =>
      RegExp(r'^/storage/emulated/\d+(/|$)').hasMatch(path);

  /// The collision dialog's Replace: trashes the existing zip (undoable
  /// from the trash page) and drops it from the index. Throws
  /// [FileOpException] (`userCancelled` when the system dialog is
  /// declined).
  Future<void> trashForReplace(FileRef existing) async {
    final res = await _lock.run(() => _source.trashBatch([existing]));
    if (res.userCancelled) {
      throw FileOpException(
        FileOpFailure.userCancelled,
        'replace declined',
        fileId: existing.id,
      );
    }
    if (res.trashed.isEmpty) {
      throw res.failed.values.firstOrNull ??
          FileOpException(
            FileOpFailure.ioError,
            'not trashed',
            fileId: existing.id,
          );
    }
    final ids = [for (final t in res.trashed) t.original.id];
    _queueIndex(() async {
      await _indexer.addFiles(const []);
      await _writes.enqueue(null, () => _indexDao.deleteIds(ids));
    });
  }

  // ---- helpers ----

  Future<void> _checkSpace(ArchiveJob job) async {
    final (String folder, int bytes) = switch (job) {
      CompressJob(:final outputPath, :final sourcePaths) => (
        parentOf(outputPath),
        await _sizeOf(sourcePaths),
      ),
      ExtractJob(:final zipPath, :final targetFolder, :final entryNames) => (
        await _gone(targetFolder) ? parentOf(targetFolder) : targetFolder,
        (await list(zipPath)).selectedSize(entryNames),
      ),
    };
    final free = await _source.freeBytes(folder);
    final needed = bytes + spaceMargin;
    if (free != null && free < needed) throw NotEnoughSpace(needed, free);
  }

  /// Sum of file sizes under [paths] (folders walked, links not followed).
  static Future<int> _sizeOf(List<String> paths) async {
    var total = 0;
    for (final p in paths) {
      final stat = await FileStat.stat(p);
      if (stat.type == FileSystemEntityType.file) {
        total += stat.size;
      } else if (stat.type == FileSystemEntityType.directory) {
        await for (final e in Directory(
          p,
        ).list(recursive: true, followLinks: false)) {
          if (e is File) total += await e.length();
        }
      }
    }
    return total;
  }

  /// Compress: `.kfm-tmp-<hex>.zip` next to the output. Extract: a hidden
  /// folder inside the target when it exists (entries are renamed into it),
  /// else next to it (the folder is renamed to the target).
  static Future<String> _tempFor(ArchiveJob job) async => switch (job) {
    CompressJob(:final outputPath) => tempPathIn(
      parentOf(outputPath),
      extension: '.zip',
    ),
    ExtractJob(:final targetFolder) =>
      await _gone(targetFolder)
          ? tempPathIn(parentOf(targetFolder))
          : tempPathIn(targetFolder),
  };

  static Future<void> _deleteQuietly(String path) async {
    try {
      if (await FileSystemEntity.isDirectory(path)) {
        await Directory(path).delete(recursive: true);
      } else {
        await File(path).delete();
      }
    } on FileSystemException {
      // Still open (Windows) or already gone: the ledger keeps it.
    }
  }

  static Future<bool> _gone(String path) async =>
      await FileSystemEntity.type(path, followLinks: false) ==
      FileSystemEntityType.notFound;

  void _queueIndex(Future<void> Function() job) {
    _indexTail = _indexTail
        .then((_) => job())
        .then<void>((_) {}, onError: (Object _) {});
  }

  /// Off the caller's path: `MediaIndexer` jobs are serial and can wait
  /// behind a full scan. It reports its own failures (`IndexFailed`).
  void _indexAdd(List<FileRef> refs) {
    if (refs.isEmpty) return;
    _queueIndex(() => _indexer.addFiles(refs));
  }

  /// One worker isolate for [request]; returns its result or throws its
  /// [ArchiveError].
  Future<Object> _spawn(
    Object request,
    String? temp,
    CancelToken? cancel,
    void Function(ArchiveProgress)? onProgress,
  ) async {
    final port = ReceivePort();
    final result = Completer<Object>();
    SendPort? commands;
    Isolate? isolate;
    Timer? poll;
    Timer? kill;
    var cancelSent = false;
    var moving = false;

    void finish(Object value, {bool error = false}) {
      if (result.isCompleted) return;
      if (error) {
        result.completeError(value);
      } else {
        result.complete(value);
      }
    }

    port.listen((m) {
      switch (m) {
        case final SendPort p:
          commands = p;
          if (cancelSent) p.send(archiveCancelCommand);
        case final ArchiveProgress p:
          if (!cancelSent) onProgress?.call(p);
        case archiveMovingMessage:
          // Not cancellable from here on: a kill now would lose files
          // already moved into place.
          moving = true;
          kill?.cancel();
        case final ArchiveError e:
          finish(e, error: true);
        case final Object r when r is ArchiveListing || r is ArchiveOutput:
          finish(r);
        case [final Object? error, _]:
          // Uncaught error in the isolate (onError).
          finish(ArchiveIoError('', '$error'), error: true);
        case null:
          // onExit.
          finish(
            cancelSent && !moving
                ? const ArchiveCancelled()
                : const ArchiveIoError('', 'worker exited'),
            error: true,
          );
      }
    });

    if (cancel != null) {
      poll = Timer.periodic(cancelPoll, (_) {
        if (cancelSent || moving || !cancel.isCancelled) return;
        cancelSent = true;
        commands?.send(archiveCancelCommand);
        kill = Timer(killAfter, () {
          isolate?.kill(priority: Isolate.immediate);
          finish(const ArchiveCancelled(), error: true);
        });
      });
    }

    try {
      isolate = await Isolate.spawn<ArchiveWorkerArgs>(
        archiveWorkerMain,
        (request: request, tempPath: temp, reply: port.sendPort),
        onError: port.sendPort,
        onExit: port.sendPort,
        debugName: 'kfm-archive',
      );
      // A result always follows the worker's "moving": a cancel sent
      // before that either stopped the worker (ArchiveCancelled) or got
      // it killed; one that came later is ignored, and the result stands.
      return await result.future;
    } finally {
      poll?.cancel();
      kill?.cancel();
      port.close();
    }
  }
}

@Riverpod(keepAlive: true)
ArchiveService archiveService(Ref ref) => ArchiveService(
  source: ref.watch(fileSourceProvider),
  indexer: ref.watch(mediaIndexerProvider),
  indexDao: ref.watch(mediaIndexDaoProvider),
  writes: ref.watch(dbWriteQueueProvider),
  lock: ref.watch(historyLockProvider),
  ledger: ref.watch(tempFileLedgerProvider.future),
  recordUndo: (op) =>
      ref.read(lastOperationUndoProvider.notifier).recordArchive(op),
);
