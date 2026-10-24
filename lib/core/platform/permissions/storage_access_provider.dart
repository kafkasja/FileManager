import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/platform/permissions/android_permission_service.dart';
import 'package:kfm/core/platform/permissions/permission_service.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_access_provider.g.dart';

@Riverpod(keepAlive: true)
PermissionService permissionService(Ref ref) => Platform.isAndroid
    ? AndroidPermissionService(
        FilesChannel(),
        ref.watch(settingsRepositoryProvider),
      )
    : const GrantedPermissionService();

/// Current storage access. Re-checked whenever the app returns to the
/// foreground (the user may have changed it in system settings).
@Riverpod(keepAlive: true)
class StorageAccessController extends _$StorageAccessController {
  @override
  Future<StorageAccess> build() {
    final service = ref.watch(permissionServiceProvider);
    final listener = AppLifecycleListener(onResume: ref.invalidateSelf);
    ref.onDispose(listener.dispose);
    return service.check();
  }

  Future<void> requestMedia() async {
    state = const AsyncLoading<StorageAccess>();
    state = await AsyncValue.guard(
      () => ref.read(permissionServiceProvider).requestMedia(),
    );
  }

  /// Re-reads the current access (e.g. after a system settings page closed).
  Future<StorageAccess> recheck() {
    ref.invalidateSelf();
    return future;
  }

  Future<void> openAllFilesSettings() =>
      ref.read(permissionServiceProvider).openAllFilesAccessSettings();

  Future<void> openMediaManagementSettings() =>
      ref.read(permissionServiceProvider).openMediaManagementSettings();

  Future<void> openAppSettings() =>
      ref.read(permissionServiceProvider).openAppSettings();
}

/// "Not now" on the All files access sheet, remembered for this app run only.
@Riverpod(keepAlive: true)
class AllFilesNotNow extends _$AllFilesNotNow {
  @override
  bool build() => false;

  void set() => state = true;
}
