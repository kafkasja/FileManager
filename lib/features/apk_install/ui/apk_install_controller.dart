import 'dart:async';
import 'dart:developer' as developer;

import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/apk_install/data/apk_platform.dart';
import 'package:kfm/features/apk_install/domain/apk_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'apk_install_controller.g.dart';

/// What an Install tap led to.
enum ApkInstallOutcome {
  /// Android's installer is open; KFM does nothing more.
  handedOff,

  /// "Install unknown apps" is off for KFM: explain, then open settings.
  needsPermission,

  /// Back from settings and still off.
  permissionDenied,

  /// No app on the device opens package files.
  noInstaller,
}

/// An unreadable package stays unreadable: show the error, never re-copy.
Duration? _noRetry(int retryCount, Object error) => null;

/// The info sheet of one `.apk` (TASK-X5). Disposed with the sheet, which
/// also deletes a cache copy of a `content://` file.
@Riverpod(retry: _noRetry)
class ApkInstallController extends _$ApkInstallController {
  @override
  Future<ApkInfo> build(FileRef file) async {
    final platform = ref.watch(apkPlatformProvider);
    final info = await platform.inspect(file);
    if (info.isCopy) {
      ref.onDispose(
        () => unawaited(
          platform.discardCopy(info.installPath).catchError((
            Object e,
            StackTrace st,
          ) {
            developer.log(
              'could not delete the APK copy',
              name: 'kfm.apk',
              error: e,
              stackTrace: st,
            );
          }),
        ),
      );
    }
    return info;
  }

  /// Hands the file to the installer, or asks for the permission first.
  Future<ApkInstallOutcome> install() async {
    final info = await future;
    final platform = ref.read(apkPlatformProvider);
    if (!await platform.canInstall()) return ApkInstallOutcome.needsPermission;
    return await platform.install(info.installPath)
        ? ApkInstallOutcome.handedOff
        : ApkInstallOutcome.noInstaller;
  }

  /// Opens "Install unknown apps" for KFM. False when there's no such page.
  Future<bool> openPermissionSettings() =>
      ref.read(apkPlatformProvider).openPermissionSettings();

  /// Back from settings: installs when the permission is now on.
  Future<ApkInstallOutcome> resumeAfterSettings() async {
    if (!await ref.read(apkPlatformProvider).canInstall()) {
      return ApkInstallOutcome.permissionDenied;
    }
    return await install();
  }
}
