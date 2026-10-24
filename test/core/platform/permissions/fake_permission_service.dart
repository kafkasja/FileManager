import 'package:kfm/core/platform/permissions/permission_service.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';

const grantedAccess = StorageAccess(
  media: MediaAccess.granted,
  allFiles: AllFilesAccess.granted,
  mediaManagement: false,
  mediaManagementSupported: true,
);

/// Scriptable [PermissionService] for tests.
class FakePermissionService implements PermissionService {
  new([this.current = grantedAccess]);

  StorageAccess current;

  /// What [requestMedia] turns [current] into.
  MediaAccess onRequest = MediaAccess.granted;

  /// When set, [check] throws it.
  StateError? checkError;

  final List<String> calls = [];

  @override
  Future<StorageAccess> check() async {
    calls.add('check');
    if (checkError case final error?) throw error;
    return current;
  }

  @override
  Future<StorageAccess> requestMedia() async {
    calls.add('requestMedia');
    return current = current.copyWith(media: onRequest);
  }

  @override
  Future<void> openAllFilesAccessSettings() async {
    calls.add('openAllFilesAccessSettings');
  }

  @override
  Future<void> openMediaManagementSettings() async {
    calls.add('openMediaManagementSettings');
  }

  @override
  Future<void> openAppSettings() async {
    calls.add('openAppSettings');
  }
}
