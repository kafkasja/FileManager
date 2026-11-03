import 'dart:async';

import 'package:kfm/core/platform/volumes/volumes_channel.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';

/// U1–U3 on Windows (TASK-PL1): drive letters as volumes. The system drive
/// is the primary volume; other fixed and network drives are fixed places;
/// USB sticks, SD cards and USB disks are removable and ejected by the app
/// ([ejectsDirectly]). Live changes come from `WM_DEVICECHANGE` (and a
/// re-read after the PC wakes up).
class WindowsVolumes implements VolumesPlatform {
  new(this._channel);

  final WindowsChannel _channel;

  /// Places treat every volume as reachable by path (API 30+ on Android).
  static const directPathSdk = 1000;

  @override
  Future<List<VolumeInfo>> list() async => [
    for (final d in await _channel.listDrives()) volumeOfDrive(d),
  ];

  @override
  Future<int> sdkInt() async => directPathSdk;

  @override
  Stream<VolumeEvent> events() => _channel.events
      .where(
        (e) =>
            e is VolumesChanged ||
            (e is PowerChanged && e.state == PowerState.resume),
      )
      .map((_) => const VolumeStateChanged(uuid: null, state: 'changed'));

  /// Windows has no storage screen to hand off to.
  @override
  Future<String?> openStorageSettings() async => null;

  @override
  bool get ejectsDirectly => true;

  @override
  Future<VolumeEjectError?> eject(String rootPath) async =>
      switch (await _channel.ejectDrive(rootPath)) {
        null => null,
        DriveEjectError.inUse => VolumeEjectError.inUse,
        DriveEjectError.notEjectable => VolumeEjectError.notEjectable,
        DriveEjectError.failed => VolumeEjectError.failed,
      };
}

/// [d] as a U1 volume: `rootPath` = `E:`, `uuid` = the volume serial (the
/// drive letter for network drives), description "Label (E:)" or "E:".
VolumeInfo volumeOfDrive(WindowsDrive d) {
  final label = d.label.trim();
  return VolumeInfo(
    uuid: d.isSystem ? null : (d.uuid ?? d.path),
    isPrimary: d.isSystem,
    isRemovable: d.isRemovable,
    description: label.isEmpty ? d.path : '$label (${d.path})',
    state: d.isMounted ? 'mounted' : 'unmounted',
    isMounted: d.isMounted,
    rootPath: d.path,
    totalBytes: d.totalBytes,
    freeBytes: d.freeBytes,
    usbMassStorage: d.bus == 'usb',
    isFixed: !d.isSystem && !d.isRemovable,
    bus: d.bus,
  );
}
