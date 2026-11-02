import 'dart:typed_data';

import 'package:meta/meta.dart';

/// What an `.apk` is, next to what's installed (TASK-X5).
@immutable
class ApkInfo {
  const new({
    required this.label,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.installedVisible,
    required this.installPath,
    this.isCopy = false,
    this.iconPng,
    this.installedVersionName,
    this.installedVersionCode,
    this.sameSigner,
  });

  final String label;
  final String packageName;
  final String versionName;
  final int versionCode;
  final Uint8List? iconPng;

  /// False: another app's package that Android hides from KFM (API 30+
  /// package visibility). Then "installed?" is unknown, not "no".
  final bool installedVisible;
  final String? installedVersionName;
  final int? installedVersionCode;

  /// Null when not installed / not visible / not comparable.
  final bool? sameSigner;

  /// The file handed to the installer: the original, or ([isCopy]) a cache
  /// copy that is deleted when the sheet closes.
  final String installPath;
  final bool isCopy;

  bool get isInstalled => installedVersionCode != null;
  bool get isUpdate => isInstalled && versionCode > installedVersionCode!;
  bool get isDowngrade => isInstalled && versionCode < installedVersionCode!;
  bool get isSameVersion => isInstalled && versionCode == installedVersionCode;
  bool get signerMismatch => sameSigner == false;

  /// Not installed, and KFM could have seen it if it were: a new app.
  bool get isNewApp => !isInstalled && installedVisible;
}
