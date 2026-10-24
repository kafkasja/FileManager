import 'dart:developer' as developer;
import 'dart:ui' show DartPluginRegistrant;

import 'package:kfm/core/background/background_scheduler.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_source_provider.dart'
    show androidPrimaryRoot, createAndroidPendingFolder;
import 'package:kfm/core/files/pending_folder.dart';
import 'package:workmanager/workmanager.dart';

/// H2: the daily pending-folder purge, in a headless engine started by
/// WorkManager. Own DB connection; no FilesChannel (not registered here).
@pragma('vm:entry-point')
void pendingPurgeDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task != BackgroundJobs.pendingPurgeTask) return true;
    DartPluginRegistrant.ensureInitialized(); // path_provider in this engine
    final db = AppDatabase.forWorker();
    final queue = DbWriteQueue();
    final settings = SettingsRepository(db, queue);
    try {
      return await runPendingPurge(
        settings,
        createAndroidPendingFolder(db, settings),
      );
    } finally {
      await queue.close(); // flushes the status writes
      await db.close();
    }
  });
}

/// The worker body, testable without WorkManager. True = done (WorkManager
/// won't retry), false = retry with back-off.
Future<bool> runPendingPurge(
  SettingsRepository settings,
  PendingFolder folder, {
  DateTime Function() clock = DateTime.now,
  String volumeRoot = androidPrimaryRoot,
}) async {
  try {
    await folder.reconcile([volumeRoot]);
    final purged = await folder.purgeExpired();
    await settings.write(
      AppSettings.pendingLastPurgeAt,
      clock().toUtc().toIso8601String(),
    );
    await settings.write(AppSettings.pendingLastPurgeError, '');
    developer.log('background purge: $purged', name: 'kfm.trash');
    return true;
  } on FileOpException catch (e) {
    // No write access (All files access turned off): retrying won't help
    // until the user grants it; the next daily run tries again. Shown in
    // Settings → Deleting.
    developer.log('background purge failed: $e', name: 'kfm.trash');
    await _recordError(settings, e.failure.name);
    return e.failure == FileOpFailure.permissionDenied;
  } on Object catch (e) {
    developer.log('background purge failed: $e', name: 'kfm.trash');
    await _recordError(settings, FileOpFailure.ioError.name);
    return false;
  }
}

/// Best effort: if the DB itself is the problem, the log line above is all
/// that is left. That is the only place an error can't reach the UI.
Future<void> _recordError(SettingsRepository settings, String code) async {
  try {
    await settings.write(AppSettings.pendingLastPurgeError, code);
  } on Object catch (e) {
    developer.log('could not store purge error: $e', name: 'kfm.trash');
  }
}
