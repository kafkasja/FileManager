import 'dart:io';

import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/files/android/android_file_source.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/files/cross_place_ops.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/mtp/mtp_file_source.dart';
import 'package:kfm/core/files/pending_folder.dart';
import 'package:kfm/core/files/place_guard.dart';
import 'package:kfm/core/files/routing_file_source.dart';
import 'package:kfm/core/files/saf/saf_channel.dart';
import 'package:kfm/core/files/saf/saf_file_source.dart';
import 'package:kfm/core/files/saf/saf_pending_folder.dart';
import 'package:kfm/core/files/staging_dir.dart';
import 'package:kfm/core/files/temp_file_ledger.dart';
import 'package:kfm/core/files/windows/windows_file_source.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/core/platform/volumes/volumes_providers.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:kfm/features/external_storage/data/tracked_file_source.dart';
import 'package:kfm/features/external_storage/data/volume_activity_tracker.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_source_provider.g.dart';

/// Root of the primary shared storage volume on Android.
const androidPrimaryRoot = '/storage/emulated/0';

/// D4's hidden pending-delete folders (Android). Null elsewhere for now.
@Riverpod(keepAlive: true)
PendingFolder? pendingFolder(Ref ref) {
  if (!Platform.isAndroid) return null;
  return createAndroidPendingFolder(
    ref.watch(appDatabaseProvider),
    ref.watch(settingsRepositoryProvider),
    guard: ref.watch(volumeActivityTrackerProvider.notifier).run,
  );
}

/// Shared by the provider and the H2 background worker.
PendingFolder createAndroidPendingFolder(
  AppDatabase db,
  SettingsRepository settings, {
  PlaceGuard? guard,
}) {
  final root = RegExp(r'^/storage/(emulated/\d+|[^/]+)');
  return PendingFolder(
    db: db,
    volumeRootOf: (path) =>
        root.firstMatch(path)?.group(0) ?? androidPrimaryRoot,
    retentionDays: () => settings.read(AppSettings.pendingFolderRetentionDays),
    guard: guard,
  );
}

/// SAF trees of mounted, granted places (U1 grants are volume roots, so
/// the tree's document id is `<uuid>:`).
List<SafTree> safTreesOf(List<StoragePlace> places) => [
  for (final p in places)
    if (p.isMounted && p.access == AccessMethod.saf)
      if ((p.rootPath, p.treeUri) case (final root?, final tree?))
        SafTree(root: root, treeUri: tree, rootDoc: '${p.id}:'),
];

/// The SAF trees KFM can use right now (kept current from `placesProvider`
/// without rebuilding the file source).
@Riverpod(keepAlive: true)
SafLocator safLocator(Ref ref) {
  var trees = const <SafTree>[];
  ref.listen(placesProvider, (_, next) {
    if (next.value case final places?) trees = safTreesOf(places);
  }, fireImmediately: true);
  return SafLocator(() => trees);
}

/// D4 on SAF volumes (TASK-U2). Null off Android.
@Riverpod(keepAlive: true)
SafPendingFolder? safPendingFolder(Ref ref) {
  if (!Platform.isAndroid) return null;
  final settings = ref.watch(settingsRepositoryProvider);
  return SafPendingFolder(
    db: ref.watch(appDatabaseProvider),
    channel: SafChannel(),
    locator: ref.watch(safLocatorProvider),
    retentionDays: () => settings.read(AppSettings.pendingFolderRetentionDays),
    guard: ref.watch(volumeActivityTrackerProvider.notifier).run,
  );
}

/// Every place KFM can reach: device storage, SAF volumes and cameras
/// behind one [RoutingFileSource] (TASK-U2), wrapped in U3's
/// [TrackedFileSource]. Tests override this with
/// `FakeFileSource`.
@Riverpod(keepAlive: true)
FileSource fileSource(Ref ref) {
  if (Platform.isAndroid) {
    final android = AndroidFileSource(
      channel: FilesChannel(),
      canSeeAllFiles: () =>
          ref.read(storageAccessControllerProvider).value?.canSeeAllFiles ??
          false,
      pendingFolder: ref.watch(pendingFolderProvider),
      tempLedger: ref.watch(tempFileLedgerProvider.future),
      // U1: full scans walk mounted SD cards / USB drives too.
      removableRoots: switch (ref.watch(volumesPlatformProvider)) {
        final volumes? => () => readDirectPathRemovableRoots(volumes),
        null => () async => const <String>[],
      },
    );
    final locator = ref.watch(safLocatorProvider);
    final saf = SafFileSource(
      channel: SafChannel(),
      trees: () => locator.trees,
      pendingFolder: ref.watch(safPendingFolderProvider),
    );
    final source = RoutingFileSource(
      android: android,
      saf: saf,
      mtp: MtpFileSource(channel: MtpObjectsChannel()),
      crossPlace: (self) => CrossPlaceOps(
        sourceOfId: self.sourceForId,
        sourceOfFolder: self.sourceForFolder,
        staging: transferStagingDir,
      ),
    );
    ref.onDispose(() async {
      await source.dispose();
      await saf.dispose();
      await android.dispose();
    });
    // U3: every call touching a removable place is counted for Eject.
    return TrackedFileSource(
      inner: source,
      tracker: ref.watch(volumeActivityTrackerProvider.notifier),
    );
  }
  if (isWindowsHost) {
    // PL1: dart:io + the Recycle Bin channel. No pending folder (the bin
    // takes every kind), no SAF/MTP places.
    final roots = ref.watch(windowsIndexRootsProvider);
    final windows = WindowsFileSource(
      channel: ref.watch(windowsChannelProvider),
      indexRoots: roots.current,
      tempLedger: ref.watch(tempFileLedgerProvider.future),
    );
    ref.onDispose(windows.dispose);
    return windows;
  }
  throw UnsupportedError(
    'FileSource not implemented for ${Platform.operatingSystem} yet (PL2)',
  );
}

/// Where "New folder…" goes when no folder is selected (P2 folder picker).
/// Windows: the Pictures known folder (its profile path; the channel's
/// answer may differ for a redirected folder, which only matters as a
/// starting point).
@Riverpod(keepAlive: true)
String defaultNewFolderParent(Ref ref) => isWindowsHost
    ? fallbackKnownFolders(Platform.environment)[KnownFolder.pictures] ??
          '$androidPrimaryRoot/Pictures'
    : '$androidPrimaryRoot/Pictures';
