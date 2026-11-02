import 'dart:io';
import 'dart:typed_data';

import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/apk_install/domain/apk_info.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'apk_platform.g.dart';

enum ApkFailure { invalid, noSpace, notFound, io }

/// An `.apk` couldn't be read (TASK-X5). Shown in the sheet, never
/// swallowed (rule 8).
@immutable
class ApkException implements Exception {
  const new(this.failure, this.message);

  final ApkFailure failure;
  final String message;

  @override
  String toString() => 'ApkException(${failure.name}): $message';
}

/// The Android side of X5 (`ApkSupport.kt` on the files channel).
abstract interface class ApkPlatform {
  /// Throws [ApkException].
  Future<ApkInfo> inspect(FileRef f);

  Future<bool> canInstall();

  /// False when the settings page can't be opened (API 24–25 have none).
  Future<bool> openPermissionSettings();

  /// False when no installer can open the file.
  Future<bool> install(String path);

  Future<void> discardCopy(String path);
}

class ChannelApkPlatform implements ApkPlatform {
  new(this._channel);

  final FilesChannel _channel;

  @override
  Future<ApkInfo> inspect(FileRef f) async {
    final content = f.uri.startsWith('content://');
    final MediaRow row;
    try {
      row = await _channel.inspectApk(
        path: content ? null : f.path,
        uri: content ? f.uri : null,
        sizeBytes: f.sizeBytes,
      );
    } on FilesChannelException catch (e) {
      throw ApkException(switch (e.code) {
        'INVALID_APK' => ApkFailure.invalid,
        'NO_SPACE' => ApkFailure.noSpace,
        'NOT_FOUND' => ApkFailure.notFound,
        _ => ApkFailure.io,
      }, '${e.code}: ${e.message}');
    }
    return apkInfoFromRow(row);
  }

  @override
  Future<bool> canInstall() => _channel.canInstallPackages();

  @override
  Future<bool> openPermissionSettings() =>
      _channel.openInstallPermissionSettings();

  @override
  Future<bool> install(String path) => _channel.installApk(path);

  @override
  Future<void> discardCopy(String path) => _channel.discardApkCopy(path);
}

/// Parses `inspectApk`'s map (see `ApkSupport.describe`).
ApkInfo apkInfoFromRow(MediaRow r) {
  final label = r['label'];
  final pkg = r['packageName'];
  final code = r['versionCode'];
  final path = r['path'];
  if (pkg is! String || code is! int || path is! String) {
    throw const ApkException(ApkFailure.invalid, 'incomplete package info');
  }
  final icon = r['iconPng'];
  return ApkInfo(
    label: label is String && label.isNotEmpty ? label : pkg,
    packageName: pkg,
    versionName: r['versionName'] as String? ?? '',
    versionCode: code,
    iconPng: icon is Uint8List ? icon : null,
    installedVisible: r['installedVisible'] == true,
    installedVersionName: r['installedVersionName'] as String?,
    installedVersionCode: r['installedVersionCode'] as int?,
    sameSigner: r['sameSigner'] as bool?,
    installPath: path,
    isCopy: r['isCopy'] == true,
  );
}

@Riverpod(keepAlive: true)
ApkPlatform apkPlatform(Ref ref) {
  if (Platform.isAndroid) return ChannelApkPlatform(FilesChannel());
  throw UnsupportedError('APK install is Android only');
}
