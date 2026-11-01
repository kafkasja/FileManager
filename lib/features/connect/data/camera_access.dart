import 'dart:io';

import 'package:permission_handler/permission_handler.dart' as ph;

enum CameraPermission { granted, denied, permanentlyDenied }

/// Camera permission for "Scan QR" (TASK-N2): asked only when the user taps
/// it, never at start.
abstract interface class CameraAccess {
  /// Whether this platform has a QR scanner (`mobile_scanner` has no
  /// Windows support, so PC offers "Type code" only).
  bool get canScan;

  Future<CameraPermission> request();

  Future<void> openSettings();
}

class PlatformCameraAccess implements CameraAccess {
  const new();

  @override
  bool get canScan => Platform.isAndroid || Platform.isIOS;

  @override
  Future<CameraPermission> request() async {
    final status = await ph.Permission.camera.request();
    if (status.isGranted || status.isLimited) return CameraPermission.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return CameraPermission.permanentlyDenied;
    }
    return CameraPermission.denied;
  }

  @override
  Future<void> openSettings() async {
    await ph.openAppSettings();
  }
}
