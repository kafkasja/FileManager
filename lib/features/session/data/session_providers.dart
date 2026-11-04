import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/rename/data/rename_providers.dart';
import 'package:kfm/features/session/data/session_repository.dart';
import 'package:kfm/features/swipe/data/file_source_resolver.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';
import 'package:kfm/features/trash/data/delete_queue.dart';
import 'package:kfm/features/trash/data/no_trash_confirmer.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/domain/undo_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_providers.g.dart';

@Riverpod(keepAlive: true)
SessionRepository sessionRepository(Ref ref) => SessionRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(dbWriteQueueProvider),
);

/// Shared by undo (S2) and delete commits (D2).
@Riverpod(keepAlive: true)
SerialLock historyLock(Ref ref) => SerialLock();

@Riverpod(keepAlive: true)
UndoRepository undoRepository(Ref ref) => UndoRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(dbWriteQueueProvider),
);

@Riverpod(keepAlive: true)
DeleteQueue deleteQueue(Ref ref) {
  final queue = DeleteQueue(
    db: ref.watch(appDatabaseProvider),
    lock: ref.watch(historyLockProvider),
    source: ref.watch(fileSourceProvider),
    undo: ref.watch(undoRepositoryProvider),
    index: ref.watch(mediaIndexDaoProvider),
    // N8: rows of remote sessions commit through that device.
    remoteSource: (id) => ref.read(fileSourceResolverProvider)(id),
    trash: FileSourceResolver.swipeTrash,
    // PL1: a Windows drive without a Recycle Bin asks first.
    confirmNoTrash: ref.watch(noTrashConfirmerProvider).confirm,
    // Q3: a revoked or partial photo permission hides files that exist.
    seesAllMedia: () async =>
        (await ref.read(permissionServiceProvider).check()).media ==
        MediaAccess.granted,
  );
  ref.onDispose(queue.dispose);
  return queue;
}

/// PL1: the UI side of [DeleteQueue]'s no-Recycle-Bin question
/// (`NoTrashPrompter` in the app shell answers it).
@Riverpod(keepAlive: true)
NoTrashConfirmer noTrashConfirmer(Ref ref) => NoTrashConfirmer();

@Riverpod(keepAlive: true)
UndoService undoService(Ref ref) => UndoService(
  repo: ref.watch(undoRepositoryProvider),
  deletes: ref.watch(deleteQueueProvider),
  source: ref.watch(fileSourceProvider),
  remoteSource: (id) => ref.read(fileSourceResolverProvider)(id),
  lock: ref.watch(historyLockProvider),
  queue: ref.watch(dbWriteQueueProvider),
  indexer: ref.watch(mediaIndexerProvider),
  index: ref.watch(mediaIndexDaoProvider),
  tags: ref.watch(tagRepositoryProvider),
  favorites: ref.watch(favoritesRepositoryProvider),
  renames: ref.watch(renameBatchRepositoryProvider),
  renameRunner: ref.watch(renameRunnerProvider),
  // N9: undo of a swipe send removes it while it is still queued.
  cancelQueuedSend: (id) =>
      ref.read(transfersRepositoryProvider).deleteQueuedFile(id),
);

/// Commit problems that aren't per file (shown as a snackbar).
@Riverpod(keepAlive: true)
Stream<Object> deleteQueueErrors(Ref ref) =>
    ref.watch(deleteQueueProvider).errors;

@Riverpod(keepAlive: true)
Stream<int> undoableCount(Ref ref, int sessionId) =>
    ref.watch(undoRepositoryProvider).watchUndoableCount(sessionId);

@Riverpod(keepAlive: true)
Stream<PendingDeleteSummary> pendingDeleteSummary(Ref ref, int sessionId) =>
    ref.watch(deleteQueueProvider).watchSummary(sessionId);
