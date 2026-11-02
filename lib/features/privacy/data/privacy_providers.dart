import 'dart:io';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/privacy/data/copying_location_stripper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'privacy_providers.g.dart';

/// `<cache>/privacy`: stripped copies (the FileProvider's `cache-path`
/// serves them to the share sheet).
Future<Directory> privacyCacheDir() async =>
    Directory('${(await getTemporaryDirectory()).path}/privacy');

/// Android: MediaStore items through the resolver (the original with
/// `ACCESS_MEDIA_LOCATION`), other files from their path. Elsewhere a
/// plain copy.
Future<void> copyOriginalBytes(FileRef f, String outPath) async {
  if (Platform.isAndroid) {
    await FilesChannel().copyOriginal(
      path: f.path,
      outPath: outPath,
      contentUri: f.uri.startsWith('content://') ? f.uri : null,
    );
    return;
  }
  await File(f.path).copy(outPath);
}

/// Removes location before files leave the device (TASK-X2).
@Riverpod(keepAlive: true)
CopyingLocationStripper locationStripper(Ref ref) =>
    CopyingLocationStripper(root: privacyCacheDir, copy: copyOriginalBytes);

/// Settings → Privacy → "Remove location when sharing".
@riverpod
Stream<bool> privacyStripLocation(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.privacyStripLocation);

/// App start: deletes stripped copies of earlier runs (shares stay until
/// then: the receiving app may read them late).
@Riverpod(keepAlive: true)
Future<int> privacyStartupCleanup(Ref ref) {
  // A margin for file systems that keep whole seconds.
  final started = DateTime.now().subtract(const Duration(seconds: 2));
  return ref.read(locationStripperProvider).purgeOlderThan(started);
}
