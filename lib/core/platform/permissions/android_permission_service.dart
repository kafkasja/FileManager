import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/platform/permissions/permission_service.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:photo_manager/photo_manager.dart';

/// Android: photo_manager for the media dialog (handles API 34 "Select
/// photos"), permission_handler for "don't ask again" and All files access,
/// FilesChannel.kt for Media management.
class AndroidPermissionService implements PermissionService {
  new(this._channel, this._settings);

  final FilesChannel _channel;
  final SettingsRepository _settings;
  int? _sdk;

  static const _option = PermissionRequestOption();

  Future<int> _sdkInt() async => _sdk ??= await _channel.sdkInt();

  @override
  Future<StorageAccess> check() async {
    final sdk = await _sdkInt();
    final state = await PhotoManager.getPermissionState(requestOption: _option);
    return StorageAccess(
      media: await _mediaAccess(state, sdk),
      allFiles: sdk < 30
          ? AllFilesAccess.notRequired
          : (await ph.Permission.manageExternalStorage.status).isGranted
          ? AllFilesAccess.granted
          : AllFilesAccess.notGranted,
      mediaManagement: await _channel.canManageMedia(),
      mediaManagementSupported: sdk >= 31,
    );
  }

  @override
  Future<StorageAccess> requestMedia() async {
    await _settings.write(AppSettings.mediaPermissionAsked, true);
    await PhotoManager.requestPermissionExtend();
    return await check();
  }

  @override
  Future<void> openAllFilesAccessSettings() async {
    // Opens ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION for this app.
    await ph.Permission.manageExternalStorage.request();
  }

  @override
  Future<void> openMediaManagementSettings() async {
    await _channel.openMediaManagementSettings();
  }

  @override
  Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }

  Future<MediaAccess> _mediaAccess(PermissionState state, int sdk) async {
    switch (state) {
      case PermissionState.authorized:
        return MediaAccess.granted;
      case PermissionState.limited:
        return MediaAccess.limited;
      case PermissionState.notDetermined:
      case PermissionState.restricted:
      case PermissionState.denied:
        final permission = sdk >= 33
            ? ph.Permission.photos
            : ph.Permission.storage;
        if ((await permission.status).isPermanentlyDenied) {
          return MediaAccess.permanentlyDenied;
        }
        // Android can't tell "never asked" from "denied once".
        return await _settings.read(AppSettings.mediaPermissionAsked)
            ? MediaAccess.denied
            : MediaAccess.unknown;
    }
  }
}
