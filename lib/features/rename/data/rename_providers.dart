import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/features/rename/data/rename_batch_repository.dart';
import 'package:kfm/features/rename/data/rename_planner.dart';
import 'package:kfm/features/rename/data/rename_runner.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rename_providers.g.dart';

@Riverpod(keepAlive: true)
RenameBatchRepository renameBatchRepository(Ref ref) =>
    RenameBatchRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
RenameRunner renameRunner(Ref ref) => RenameRunner(
  source: ref.watch(fileSourceProvider),
  repo: ref.watch(renameBatchRepositoryProvider),
  undo: ref.watch(undoRepositoryProvider),
  lock: ref.watch(historyLockProvider),
  indexer: ref.watch(mediaIndexerProvider),
);

/// Files in the session's collecting batch (the "✎ N" pill).
@riverpod
Stream<int> renameBatchCount(Ref ref, int sessionId) =>
    ref.watch(renameBatchRepositoryProvider).watchCount(sessionId);

@Riverpod(keepAlive: true)
RenamePlanner renamePlanner(Ref ref) => RenamePlanner(
  ref.watch(fileSourceProvider),
  ref.watch(renameBatchRepositoryProvider),
  ref.watch(mediaIndexDaoProvider),
);
