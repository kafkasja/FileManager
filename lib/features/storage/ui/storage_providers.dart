import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/core/platform/device_space.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/storage/data/storage_totals.dart';
import 'package:kfm/features/storage/domain/storage_category.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_providers.g.dart';

/// The big-file threshold, live (the section writes it).
@riverpod
Stream<int> storageBigFileThreshold(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.storageBigFileThresholdBytes);

/// Everything the Storage overview shows (TASK-C1). Auto-dispose: nothing
/// runs while the screen is closed. Re-runs on index changes (debounced).
@riverpod
Future<StorageOverview> storageOverview(Ref ref) async {
  ref.watch(mediaIndexChangesProvider);
  final access =
      ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ?? false;
  final scanning = ref.watch(indexStatusProvider).value is IndexScanning;
  final big = await ref.watch(storageBigFileThresholdProvider.future);
  final dao = ref.watch(mediaIndexDaoProvider);
  final now = DateTime.now();

  Future<DeviceSpace?> space() async {
    try {
      return await ref.read(deviceSpaceSourceProvider).read();
    } on Object {
      return null; // "Unknown"; the rest of the screen still works.
    }
  }

  final (totals, biggest, device) = await (
    Future.wait([
      for (final c in storageCategories(bigFileBytes: big))
        storageCategoryTotal(dao, c, now: now, canSeeAllFiles: access),
    ]),
    biggestFiles(dao, canSeeAllFiles: access),
    space(),
  ).wait;
  return StorageOverview(
    space: device,
    categories: [...totals]
      ..sort((a, b) => b.totalBytes.compareTo(a.totalBytes)),
    biggestFiles: biggest,
    scanning: scanning,
    allFilesAccess: access,
  );
}
