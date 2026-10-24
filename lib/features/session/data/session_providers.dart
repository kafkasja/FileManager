import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/features/session/data/session_repository.dart';
import 'package:kfm/features/trash/data/delete_queue.dart';
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
  );
  ref.onDispose(queue.dispose);
  return queue;
}

@Riverpod(keepAlive: true)
UndoService undoService(Ref ref) => UndoService(
  repo: ref.watch(undoRepositoryProvider),
  deletes: ref.watch(deleteQueueProvider),
  source: ref.watch(fileSourceProvider),
  lock: ref.watch(historyLockProvider),
  queue: ref.watch(dbWriteQueueProvider),
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
