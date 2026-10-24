import 'package:kfm/core/platform/permissions/storage_access.dart';

/// Checks and requests storage access. Android impl:
/// `AndroidPermissionService`; desktop: `GrantedPermissionService`.
abstract interface class PermissionService {
  Future<StorageAccess> check();

  /// Shows the system photos & videos permission dialog.
  Future<StorageAccess> requestMedia();

  /// Opens the "All files access" system page for this app; the result is
  /// read on resume.
  Future<void> openAllFilesAccessSettings();

  /// Opens the "Media management apps" special access page (API 31+).
  Future<void> openMediaManagementSettings();

  /// App details page (for [MediaAccess.permanentlyDenied]).
  Future<void> openAppSettings();
}

/// Platforms without runtime storage permissions (Windows, PL1).
class GrantedPermissionService implements PermissionService {
  const new();

  static const _all = StorageAccess(
    media: MediaAccess.granted,
    allFiles: AllFilesAccess.notRequired,
    mediaManagement: false,
  );

  @override
  Future<StorageAccess> check() async => _all;

  @override
  Future<StorageAccess> requestMedia() async => _all;

  @override
  Future<void> openAllFilesAccessSettings() async {}

  @override
  Future<void> openMediaManagementSettings() async {}

  @override
  Future<void> openAppSettings() async {}
}
