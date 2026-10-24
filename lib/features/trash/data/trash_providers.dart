import 'dart:developer' as developer;

import 'package:kfm/core/background/background_scheduler.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/rename/data/rename_providers.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/trash/data/trash_ledger.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trash_providers.g.dart';

/// The delete-mode setting (D1). New sessions copy it.
@Riverpod(keepAlive: true)
Stream<DeleteMode> deleteModeSetting(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.deleteMode)
    .map(DeleteMode.parse);

/// Pending-folder retention in days (D4), clamped to 1–90.
@Riverpod(keepAlive: true)
Stream<int> pendingRetentionDays(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.pendingFolderRetentionDays);

@Riverpod(keepAlive: true)
TrashLedger trashLedger(Ref ref) => TrashLedger(
  ref.watch(appDatabaseProvider),
  ref.watch(dbWriteQueueProvider),
  ref.watch(fileSourceProvider),
);

/// H2: a delete the pending folder couldn't take, with its file (null when
/// the file can't be found any more).
typedef UnavailableDelete = ({PendingDeleteRow row, FileRef? file});

/// H2: all such deletes, any session, newest first.
@riverpod
Stream<List<UnavailableDelete>> folderUnavailable(Ref ref) {
  final files = ref.watch(fileSourceProvider);
  return ref
      .watch(deleteQueueProvider)
      .watchFolderUnavailable()
      .asyncMap(
        (rows) async => [
          for (final r in rows) (row: r, file: await files.stat(r.fileId)),
        ],
      );
}

/// Once per app run, after storage access is granted. The order matters.
@Riverpod(keepAlive: true)
Future<int> startupMaintenance(Ref ref) async {
  final access = await ref.watch(storageAccessControllerProvider.future);
  if (!access.canUseSwipe) return 0;
  final folder = ref.read(pendingFolderProvider);
  final canUseFolder = folder != null && access.canSeeAllFiles;
  // 1. H2: files moved in just before a kill get rows, so H1's lookup sees
  // them.
  if (canUseFolder) await folder.reconcile([androidPrimaryRoot]);
  // 2. D2/H1: rows stuck in `committing` (also without All files access).
  await ref.read(deleteQueueProvider).recoverStuck();
  // P3: finish a rename batch a crash left half-way.
  await ref.read(renameRunnerProvider).recoverInterrupted();
  var purged = 0;
  if (canUseFolder) {
    // 3. D4: expired items; a success clears a stale background error.
    purged = await folder.purgeExpired();
    await ref
        .read(settingsRepositoryProvider)
        .write(AppSettings.pendingLastPurgeError, '');
    developer.log('purged $purged expired pending files', name: 'kfm.trash');
    // 4. H2: the daily job (after the purge, so a scheduler failure can't
    // stop it).
    await ref.read(backgroundSchedulerProvider)?.ensureDailyPurge();
  }
  // P8: notice files that left the trash (expired, emptied, restored).
  await ref.read(trashLedgerProvider).reconcileNow();
  return purged;
}
