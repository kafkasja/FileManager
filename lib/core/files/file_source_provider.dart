import 'dart:io';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/android/android_file_source.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/pending_folder.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_source_provider.g.dart';

/// Root of the primary shared storage volume on Android.
const androidPrimaryRoot = '/storage/emulated/0';

/// D4's hidden pending-delete folders (Android). Null elsewhere for now.
@Riverpod(keepAlive: true)
PendingFolder? pendingFolder(Ref ref) {
  if (!Platform.isAndroid) return null;
  final settings = ref.watch(settingsRepositoryProvider);
  final root = RegExp(r'^/storage/(emulated/\d+|[^/]+)');
  return PendingFolder(
    db: ref.watch(appDatabaseProvider),
    volumeRootOf: (path) =>
        root.firstMatch(path)?.group(0) ?? androidPrimaryRoot,
    retentionDays: () => settings.read(AppSettings.pendingFolderRetentionDays),
  );
}

/// The device's own storage. Tests override this with `FakeFileSource`.
@Riverpod(keepAlive: true)
FileSource fileSource(Ref ref) {
  if (Platform.isAndroid) {
    final source = AndroidFileSource(
      channel: FilesChannel(),
      canSeeAllFiles: () =>
          ref.read(storageAccessControllerProvider).value?.canSeeAllFiles ??
          false,
      pendingFolder: ref.watch(pendingFolderProvider),
    );
    ref.onDispose(source.dispose);
    return source;
  }
  throw UnsupportedError(
    'FileSource not implemented for ${Platform.operatingSystem} yet (PL1/PL2)',
  );
}
