import 'package:kfm/core/background/cancel_token.dart';
import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_operation_runner.g.dart';

/// Asked when the target folder already has a file named like [incoming].
/// Returns the choice and whether it applies to all remaining collisions
/// (B4's collision dialog; a dismissed dialog should answer
/// `(CollisionChoice.skip, false)`).
typedef CollisionResolver = Future<(CollisionChoice, bool)> Function(
  FileRef incoming,
  FileRef existing,
);

/// Thrown by [FileOperationRunner.run] before anything is copied when the
/// target volume doesn't have room ([neededBytes] includes the margin).
class NotEnoughSpaceException extends FileOpException {
  const new({required this.neededBytes, required this.freeBytes})
    : super(FileOpFailure.noSpace, 'needs $neededBytes, $freeBytes free');

  final int neededBytes;
  final int freeBytes;
}

/// Selection ids resolved to files the app may act on right now.
typedef ActionFiles = ({List<FileRef> files, int needAllFiles, int missing});

/// What an undo did.
@immutable
class UndoOutcome {
  const new({
    this.undone = 0,
    this.missing = 0,
    this.failed = const [],
    this.declined = false,
    this.cancelled = false,
  });

  final int undone;

  /// `after` files that no longer exist (changed elsewhere since).
  final int missing;
  final List<FileOpException> failed;

  /// The system consent / restore dialog was declined.
  final bool declined;
  final bool cancelled;
}

extension CompletedOperationX on CompletedOperation {
  /// H2: files a trash delete couldn't put in the pending folder. The UI
  /// offers "Delete permanently instead" for them.
  List<FileRef> get pendingFolderUnavailable => [
    for (final r in results)
      if (r.error?.failure == FileOpFailure.pendingFolderUnavailable) r.before,
  ];

  /// The whole op was refused by the consent / trash dialog.
  bool get declined =>
      results.any((r) => r.error?.failure == FileOpFailure.userCancelled);

  /// Whether `LastOperationUndo` can reverse anything of it. A failed
  /// Replace whose trashed file couldn't be put back keeps its `trashed`
  /// entry, so undo still restores it.
  bool get isUndoable => switch (op) {
    DeleteOp(permanent: true) => false,
    DeleteOp() => results.any((r) => r.trashed != null),
    _ => results.any((r) => r.after != null || r.trashed != null),
  };
}

/// Runs B4's Browse file operations file by file (TASK-B4 §5, §7) and their
/// undo (§8). Each file step holds [_lock] (`historyLockProvider`), so it
/// never overlaps an S2 undo or a D2 delete dialog; cancel is checked
/// between files.
///
/// Index updates run after the lock is released, on [_indexTail] (see
/// [_queueIndex]): `MediaIndexer` jobs are serial, so an upsert can wait
/// behind a running full scan, and it must not hold the lock that swipe
/// undo and delete commits need meanwhile.
class FileOperationRunner {
  new({
    required this._source,
    required this._indexer,
    required this._indexDao,
    required this._writes,
    required this._lock,
    required this._deleteMode,
    required this._canSeeAllFiles,
  });

  final FileSource _source;
  final MediaIndexer _indexer;
  final MediaIndexDao _indexDao;
  final DbWriteQueue _writes;
  final SerialLock _lock;
  final Future<DeleteMode> Function() _deleteMode;
  final bool Function() _canSeeAllFiles;

  Future<void> _indexTail = Future<void>.value();

  /// Completes once every index update queued so far is written (tests,
  /// callers that read the index right after an operation).
  Future<void> get indexSettled => _indexTail;

  /// Free space kept on top of the copied bytes.
  static const int spaceMargin = 50 * 1024 * 1024;

  /// Files per trash / delete / restore call (one system dialog each).
  static const deleteChunk = 500;

  /// Loads B6 selection ids and keeps only files visible with today's
  /// access (`needAllFiles` = left out because All files access is missing,
  /// `missing` = no longer in the index). Never acts on the rest silently.
  Future<ActionFiles> loadForAction(List<String> ids) async {
    final refs = await _indexDao.byIds(ids);
    final all = _canSeeAllFiles();
    final visible = IndexQuery.all.visible(canSeeAllFiles: all);
    final files = <FileRef>[];
    var needAccess = 0;
    for (final f in refs) {
      final ok =
          all ||
          (visible != null &&
              !f.hidden &&
              (visible.kinds.isEmpty || visible.kinds.contains(f.kind)));
      if (ok) {
        files.add(f);
      } else {
        needAccess++;
      }
    }
    return (
      files: files,
      needAllFiles: needAccess,
      missing: ids.length - refs.length,
    );
  }

  /// A [DeleteOp] for [files] in the user's delete mode (D1). Permanent
  /// ones must be confirmed by the UI before [run].
  Future<DeleteOp> deleteOp(List<FileRef> files) async =>
      DeleteOp(files, permanent: await _deleteMode() == DeleteMode.permanent);

  /// Runs [op]. Per-file [FileOpException]s are collected and the batch
  /// goes on, except `noSpace` and `userCancelled`, which stop it. Throws
  /// [NotEnoughSpaceException] (nothing done) when a copy can't fit.
  /// [resolveCollision] is only asked for Move / Copy.
  Future<CompletedOperation> run(
    FileOperation op, {
    required CancelToken cancel,
    required CollisionResolver resolveCollision,
    void Function(OperationProgress)? onProgress,
  }) async {
    final progress = _Progress(op.files, onProgress);
    final results = <OpResult>[];
    final bool stopped;
    switch (op) {
      case DeleteOp(:final permanent):
        stopped = await _delete(op.files, permanent, cancel, progress, results);
      case MoveOp() || RenameOp():
        progress.emit();
        if (!await _source.requestWriteAccess(op.files)) {
          return _declined(op);
        }
        stopped = await _perFile(
          op,
          cancel,
          resolveCollision,
          progress,
          results,
        );
      case CopyOp() || DuplicateOp():
        await _checkSpace(op);
        progress.emit();
        stopped = await _perFile(
          op,
          cancel,
          resolveCollision,
          progress,
          results,
        );
    }
    final unreached = results.length < op.files.length;
    return CompletedOperation(
      op: op,
      results: List.unmodifiable(results),
      cancelled: !stopped && cancel.isCancelled && unreached,
      stoppedEarly: stopped && unreached,
    );
  }

  CompletedOperation _declined(FileOperation op) => CompletedOperation(
    op: op,
    results: [
      for (final f in op.files)
        _result(
          f,
          error: FileOpException(
            FileOpFailure.userCancelled,
            'write access declined',
            fileId: f.id,
          ),
        ),
    ],
    cancelled: false,
  );

  Future<void> _checkSpace(FileOperation op) async {
    final targets = switch (op) {
      CopyOp(:final targetFolder) => {targetFolder},
      _ => {for (final f in op.files) f.folderPath},
    };
    final needed =
        op.files.fold<int>(0, (sum, f) => sum + f.sizeBytes) + spaceMargin;
    for (final t in targets) {
      final free = await _source.freeBytes(t);
      if (free != null && free < needed) {
        throw NotEnoughSpaceException(neededBytes: needed, freeBytes: free);
      }
    }
  }

  /// Returns true when a `noSpace` / `userCancelled` failure stopped the
  /// batch.
  Future<bool> _perFile(
    FileOperation op,
    CancelToken cancel,
    CollisionResolver resolveCollision,
    _Progress progress,
    List<OpResult> results,
  ) async {
    CollisionChoice? forAll;
    // Files this operation put in the target so far.
    final produced = <FileRef>[];
    for (final f in op.files) {
      if (cancel.isCancelled) return false;
      progress.emit(current: f.name);
      final target = switch (op) {
        MoveOp(:final targetFolder) ||
        CopyOp(:final targetFolder) => targetFolder,
        _ => null,
      };
      // Collision check (Move / Copy into another folder only).
      FileRef? existing;
      var choice = CollisionChoice.keepBoth;
      if (target != null && target != f.folderPath) {
        existing = await _source.statPath('$target/${f.name}');
        // Shared storage is case-insensitive: `/DCIM/cam` can be the
        // file's own folder. A file never collides with itself.
        if (existing != null && _sameFile(existing, f)) existing = null;
        if (existing != null) {
          final hit = existing;
          if (produced.any((p) => _sameFile(p, hit))) {
            // A file this same operation just moved / copied there (two
            // selected files with one name): never ask, never trash the
            // op's own output (undo would restore it into the target, not
            // where it came from). Always keep both.
            choice = CollisionChoice.keepBoth;
          } else if (forAll != null) {
            choice = forAll;
          } else {
            final (picked, applyToAll) = await resolveCollision(f, hit);
            choice = picked;
            if (applyToAll) forAll = picked;
          }
          if (cancel.isCancelled) return false;
        }
      }
      if (existing != null && choice == CollisionChoice.skip) {
        results.add(_result(f));
        progress.finished(f);
        continue;
      }
      final replace = existing != null && choice == CollisionChoice.replace
          ? existing
          : null;
      final r = await _lock.run(() => _step(op, f, replace));
      // Upsert: a move that kept its id emits no idChange, so the row's
      // folder would stay stale; a copy is a new row.
      if (r.after case final after?) {
        produced.add(after);
        _indexAdd([after]);
      }
      results.add(r);
      progress.finished(f);
      final failure = r.error?.failure;
      if (failure == FileOpFailure.noSpace ||
          failure == FileOpFailure.userCancelled) {
        return true;
      }
    }
    return false;
  }

  /// Same file: same id, or the same path ignoring case (shared storage is
  /// case-insensitive, so two such paths are one file there).
  static bool _sameFile(FileRef a, FileRef b) =>
      a.id == b.id || a.path.toLowerCase() == b.path.toLowerCase();

  /// One file, under the lock.
  Future<OpResult> _step(FileOperation op, FileRef f, FileRef? replace) async {
    TrashedItem? trashed;
    if (replace != null) {
      // Always to the trash (undoable, visible in D5), never overwritten.
      final res = await _source.trashBatch([replace]);
      final failure = res.userCancelled
          ? FileOpException(
              FileOpFailure.userCancelled,
              'replace declined',
              fileId: f.id,
            )
          : res.trashed.isEmpty
          ? res.failed.values.firstOrNull ??
                FileOpException(FileOpFailure.ioError, 'replace', fileId: f.id)
          : null;
      if (failure != null) {
        return _result(f, replaced: replace, error: failure);
      }
      trashed = res.trashed.single;
      _indexRemove([replace.id]);
    }
    try {
      final after = switch (op) {
        MoveOp(:final targetFolder) => await _source.move(f, targetFolder),
        CopyOp(:final targetFolder) => await _source.copy(f, targetFolder),
        DuplicateOp() => await _source.copy(f, f.folderPath),
        RenameOp(:final newName) => await _source.rename(f, newName),
        DeleteOp() => throw StateError('deletes run in batches'),
      };
      return _result(f, after: after, replaced: replace, trashed: trashed);
    } on Object catch (e, st) {
      // The replaced file goes back where it was. If that fails too it
      // stays in the result, so the op stays undoable and undo retries.
      final stillTrashed = trashed == null
          ? null
          : await _putBackReplaced(trashed);
      if (e is! FileOpException) Error.throwWithStackTrace(e, st);
      return _result(
        f,
        replaced: stillTrashed == null ? null : replace,
        trashed: stillTrashed,
        error: e,
      );
    }
  }

  /// Restores a Replace's trashed file after the main step failed (already
  /// under the lock). Returns [item] when it is still in the trash.
  Future<TrashedItem?> _putBackReplaced(TrashedItem item) async {
    try {
      final res = await _source.restoreBatch([item]);
      final back = res.restored[item.trashId];
      if (back == null) return item;
      _indexAdd([back]);
      return null;
    } on FileOpException {
      return item;
    }
  }

  /// Queues index work in call order, off the lock (see the class doc).
  /// `MediaIndexer` reports its own failures (`IndexFailed`); deletes go
  /// through [_writes], which publishes theirs on `dbWriteErrorsProvider`.
  void _queueIndex(Future<void> Function() job) {
    _indexTail = _indexTail
        .then((_) => job())
        .then<void>((_) {}, onError: (Object _) {});
  }

  void _indexAdd(List<FileRef> files) {
    if (files.isEmpty) return;
    _queueIndex(() => _indexer.addFiles(files));
  }

  /// Waits for every indexer job queued before it (an empty `addFiles` is a
  /// barrier), so an earlier queued upsert can't bring the row back.
  void _indexRemove(List<String> ids) {
    if (ids.isEmpty) return;
    _queueIndex(() async {
      await _indexer.addFiles(const []);
      await _writes.enqueue(null, () => _indexDao.deleteIds(ids));
    });
  }

  /// Returns true when a declined dialog stopped the batch.
  Future<bool> _delete(
    List<FileRef> files,
    bool permanent,
    CancelToken cancel,
    _Progress progress,
    List<OpResult> results,
  ) async {
    progress.emit();
    for (var i = 0; i < files.length; i += deleteChunk) {
      if (cancel.isCancelled) return false;
      final end = i + deleteChunk > files.length
          ? files.length
          : i + deleteChunk;
      final chunk = files.sublist(i, end);
      progress.emit(current: chunk.first.name);
      final stop = await _lock.run(
        () => permanent
            ? _deletePermanently(chunk, results)
            : _trash(chunk, results),
      );
      chunk.forEach(progress.finished);
      if (stop) return true;
    }
    return false;
  }

  /// Returns true when the batch must stop (dialog declined).
  Future<bool> _trash(List<FileRef> chunk, List<OpResult> results) async {
    final res = await _source.trashBatch(chunk);
    if (res.userCancelled) {
      for (final f in chunk) {
        results.add(
          _result(
            f,
            error: FileOpException(
              FileOpFailure.userCancelled,
              'trash declined',
              fileId: f.id,
            ),
          ),
        );
      }
      return true;
    }
    final byId = {for (final t in res.trashed) t.original.id: t};
    _indexRemove(byId.keys.toList());
    for (final f in chunk) {
      final item = byId[f.id];
      results.add(
        _result(
          f,
          trashed: item,
          // X1: a shared-in copy deleted directly counts as done.
          error: item != null || res.removed.contains(f.id)
              ? null
              : res.failed[f.id] ??
                    FileOpException(
                      FileOpFailure.ioError,
                      'not trashed',
                      fileId: f.id,
                    ),
        ),
      );
    }
    return false;
  }

  Future<bool> _deletePermanently(
    List<FileRef> chunk,
    List<OpResult> results,
  ) async {
    try {
      await _source.deletePermanentlyBatch(chunk);
    } on FileOpException catch (e) {
      // The batch may have deleted part of the chunk before it threw: the
      // files that are gone now count as deleted, only the rest failed.
      final gone = <String>[];
      for (final f in chunk) {
        if (await _isGone(f)) {
          gone.add(f.id);
          results.add(_result(f));
        } else {
          results.add(_result(f, error: e));
        }
      }
      _indexRemove(gone);
      return e.failure == FileOpFailure.userCancelled;
    }
    _indexRemove([for (final f in chunk) f.id]);
    for (final f in chunk) {
      results.add(_result(f));
    }
    return false;
  }

  /// Whether [f] no longer exists (a failed stat counts as still there).
  Future<bool> _isGone(FileRef f) async {
    try {
      return await _source.stat(f.id) == null &&
          await _source.statPath(f.path) == null;
    } on FileOpException {
      return false;
    }
  }

  // ---- undo (§8) ----

  /// Reverses [done]. Each `after` file is re-checked first; missing ones
  /// are counted, the rest undone. Permanent deletes can't be undone.
  Future<UndoOutcome> undo(
    CompletedOperation done, {
    CancelToken? cancel,
    void Function(OperationProgress)? onProgress,
  }) {
    final token = cancel ?? CancelToken();
    return switch (done.op) {
      DeleteOp(permanent: true) => Future.value(const UndoOutcome()),
      DeleteOp() => _undoDelete(done, token, onProgress),
      MoveOp() || RenameOp() => _undoMoveRename(done, token, onProgress),
      CopyOp() || DuplicateOp() => _undoCopy(done, token, onProgress),
    };
  }

  Future<UndoOutcome> _undoMoveRename(
    CompletedOperation done,
    CancelToken cancel,
    void Function(OperationProgress)? onProgress,
  ) async {
    final pairs = <(OpResult, FileRef)>[];
    // Replaced files of failed steps that couldn't be put back then.
    final orphans = <TrashedItem>[];
    var missing = 0;
    for (final r in done.results) {
      final after = r.after;
      if (after == null) {
        if (r.trashed case final t?) orphans.add(t);
        continue;
      }
      final now = await _source.stat(after.id);
      if (now == null) {
        missing++;
      } else {
        pairs.add((r, now));
      }
    }
    if (pairs.isNotEmpty &&
        !await _source.requestWriteAccess([for (final p in pairs) p.$2])) {
      return UndoOutcome(missing: missing, declined: true);
    }
    final progress = _Progress([for (final p in pairs) p.$2], onProgress)
      ..emit();
    final failed = <FileOpException>[];
    final restoreReplaced = <TrashedItem>[...orphans];
    var undone = 0;
    var cancelled = false;
    for (final (r, now) in pairs) {
      if (cancel.isCancelled) {
        cancelled = true;
        break;
      }
      progress.emit(current: now.name);
      try {
        final back = await _lock.run(() async {
          var back = now;
          if (done.op is MoveOp) {
            back = await _source.move(now, r.before.folderPath);
          }
          if (back.name != r.before.name) {
            // Storage is case-insensitive: for a case-only rename
            // (img.jpg -> IMG.jpg) the file itself answers at the old path.
            final hit = await _source.statPath(r.before.path);
            if (hit == null || _sameFile(hit, back)) {
              back = await _source.rename(back, r.before.name);
            } else if (done.op is RenameOp) {
              // Nothing happened: the old name belongs to another file now.
              throw FileOpException(
                FileOpFailure.targetExists,
                r.before.path,
                fileId: back.id,
              );
            }
          }
          return back;
        });
        _indexAdd([back]);
        undone++;
        if (r.trashed case final t?) restoreReplaced.add(t);
      } on FileOpException catch (e) {
        failed.add(e);
      }
      progress.finished(now);
    }
    final restore = await _restore(restoreReplaced);
    return UndoOutcome(
      undone: undone,
      missing: missing,
      failed: [...failed, ...restore.failed],
      declined: restore.declined,
      cancelled: cancelled,
    );
  }

  Future<UndoOutcome> _undoCopy(
    CompletedOperation done,
    CancelToken cancel,
    void Function(OperationProgress)? onProgress,
  ) async {
    final copies = <FileRef>[];
    var missing = 0;
    final replaced = <TrashedItem>[];
    for (final r in done.results) {
      // Also a failed step's replaced file that couldn't be put back then.
      if (r.trashed case final t?) replaced.add(t);
      final after = r.after;
      if (after == null) continue;
      final now = await _source.stat(after.id);
      if (now == null) {
        missing++;
      } else {
        copies.add(now);
      }
    }
    final progress = _Progress(copies, onProgress)..emit();
    final failed = <FileOpException>[];
    var undone = 0;
    var declined = false;
    var cancelled = false;
    for (var i = 0; i < copies.length; i += deleteChunk) {
      if (cancel.isCancelled) {
        cancelled = true;
        break;
      }
      final end = i + deleteChunk > copies.length
          ? copies.length
          : i + deleteChunk;
      final chunk = copies.sublist(i, end);
      final res = await _lock.run(() => _source.trashBatch(chunk));
      _indexRemove([for (final t in res.trashed) t.original.id]);
      chunk.forEach(progress.finished);
      if (res.userCancelled) {
        declined = true;
        break;
      }
      undone += res.trashed.length;
      failed.addAll(res.failed.values);
    }
    // Replaced files come back only once the copies over them are gone.
    final restore = declined || cancelled
        ? (restored: 0, failed: const <FileOpException>[], declined: false)
        : await _restore(replaced);
    return UndoOutcome(
      undone: undone,
      missing: missing,
      failed: [...failed, ...restore.failed],
      declined: declined || restore.declined,
      cancelled: cancelled,
    );
  }

  Future<UndoOutcome> _undoDelete(
    CompletedOperation done,
    CancelToken cancel,
    void Function(OperationProgress)? onProgress,
  ) async {
    final items = [for (final r in done.results) ?r.trashed];
    final progress = _Progress([for (final i in items) i.original], onProgress)
      ..emit();
    var undone = 0;
    final failed = <FileOpException>[];
    for (var i = 0; i < items.length; i += deleteChunk) {
      if (cancel.isCancelled) {
        return UndoOutcome(undone: undone, failed: failed, cancelled: true);
      }
      final end = i + deleteChunk > items.length
          ? items.length
          : i + deleteChunk;
      final chunk = items.sublist(i, end);
      final res = await _restore(chunk);
      for (final item in chunk) {
        progress.finished(item.original);
      }
      if (res.declined) {
        return UndoOutcome(undone: undone, failed: failed, declined: true);
      }
      undone += res.restored;
      failed.addAll(res.failed);
    }
    // Trashed items that are gone from the trash count as missing.
    final missing = failed
        .where((e) => e.failure == FileOpFailure.notFound)
        .length;
    return UndoOutcome(
      undone: undone,
      missing: missing,
      failed: [
        for (final e in failed)
          if (e.failure != FileOpFailure.notFound) e,
      ],
    );
  }

  Future<_Restored> _restore(List<TrashedItem> items) async {
    if (items.isEmpty) {
      return (restored: 0, failed: const <FileOpException>[], declined: false);
    }
    final res = await _lock.run(() => _source.restoreBatch(items));
    _indexAdd(res.restored.values.toList());
    return (
      restored: res.restored.length,
      failed: res.failed.values.toList(),
      declined: res.userCancelled,
    );
  }

  static OpResult _result(
    FileRef before, {
    FileRef? after,
    FileRef? replaced,
    TrashedItem? trashed,
    FileOpException? error,
  }) => (
    before: before,
    after: after,
    replaced: replaced,
    trashed: trashed,
    error: error,
  );
}

typedef _Restored = ({
  int restored,
  List<FileOpException> failed,
  bool declined,
});

/// Counts finished files and bytes for [OperationProgress].
class _Progress {
  new(List<FileRef> files, this._onProgress)
    : _total = files.length,
      _bytesTotal = files.fold(0, (s, f) => s + f.sizeBytes);

  final void Function(OperationProgress)? _onProgress;
  final int _total;
  final int _bytesTotal;
  int _done = 0;
  int _bytesDone = 0;

  void emit({String? current}) => _onProgress?.call(
    OperationProgress(
      done: _done,
      total: _total,
      bytesDone: _bytesDone,
      bytesTotal: _bytesTotal,
      current: current,
    ),
  );

  void finished(FileRef f) {
    _done++;
    _bytesDone += f.sizeBytes;
    emit();
  }
}

@Riverpod(keepAlive: true)
FileOperationRunner fileOperationRunner(Ref ref) => FileOperationRunner(
  source: ref.watch(fileSourceProvider),
  indexer: ref.watch(mediaIndexerProvider),
  indexDao: ref.watch(mediaIndexDaoProvider),
  writes: ref.watch(dbWriteQueueProvider),
  lock: ref.watch(historyLockProvider),
  // Read straight from the settings (what `deleteModeSettingProvider`
  // parses): awaiting that StreamProvider's `.future` with no listener
  // hangs in Riverpod 3 (paused provider).
  deleteMode: () async => DeleteMode.parse(
    await ref.read(settingsRepositoryProvider).read(AppSettings.deleteMode),
  ),
  canSeeAllFiles: () =>
      ref.read(storageAccessControllerProvider).value?.canSeeAllFiles ?? false,
);
