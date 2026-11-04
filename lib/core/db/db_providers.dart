import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_startup_check.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'db_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
DbWriteQueue dbWriteQueue(Ref ref) {
  final queue = DbWriteQueue();
  ref.onDispose(queue.close);
  return queue;
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) => SettingsRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(dbWriteQueueProvider),
);

/// The F6 shell listens and shows a non-blocking "couldn't save" message.
@Riverpod(keepAlive: true)
Stream<DbWriteError> dbWriteErrors(Ref ref) =>
    ref.watch(dbWriteQueueProvider).errors;

/// Q6: what the startup check found (`main` overrides it with the result of
/// `checkDatabaseFile`); `DbStartupBanner` tells the user.
@Riverpod(keepAlive: true)
DbStartupReport dbStartupReport(Ref ref) => DbStartupReport.ok;
