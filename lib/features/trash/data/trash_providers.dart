import 'dart:developer' as developer;

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/rename/data/rename_providers.dart';
import 'package:kfm/features/session/data/session_providers.dart';
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

/// Once per app run, after storage access is granted: rows stuck in
/// `committing` (D2), rebuild the pending-folder table if app data was
/// cleared, and purge expired pending items (D4). The daily background
/// purge (WorkManager) is not built yet.
@Riverpod(keepAlive: true)
Future<int> startupMaintenance(Ref ref) async {
  final access = await ref.watch(storageAccessControllerProvider.future);
  if (!access.canUseSwipe) return 0;
  await ref.read(deleteQueueProvider).recoverStuck();
  // P3: finish a rename batch a crash left half-way.
  await ref.read(renameRunnerProvider).recoverInterrupted();
  final folder = ref.read(pendingFolderProvider);
  if (folder == null || !access.canSeeAllFiles) return 0;
  await folder.rebuildIfEmpty([androidPrimaryRoot]);
  final purged = await folder.purgeExpired();
  developer.log('purged $purged expired pending files', name: 'kfm.trash');
  return purged;
}
