import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// One storage volume as Android reports it (TASK-U1, `VolumesChannel.kt`).
@immutable
class VolumeInfo {
  const new({
    required this.uuid,
    required this.isPrimary,
    required this.isRemovable,
    required this.description,
    required this.state,
    required this.isMounted,
    this.rootPath,
    this.totalBytes,
    this.freeBytes,
    this.usbMassStorage = false,
    this.isFixed = false,
    this.bus,
    this.mountedAt,
  });

  factory fromRow(Map<Object?, Object?> r) {
    String? str(Object? v) => v is String && v.isNotEmpty ? v : null;
    int? integer(Object? v) => v is int ? v : null;
    return VolumeInfo(
      uuid: str(r['uuid']),
      isPrimary: r['primary'] == true,
      isRemovable: r['removable'] == true,
      description: str(r['description']) ?? '',
      state: str(r['state']) ?? 'unknown',
      isMounted: r['mounted'] == true,
      rootPath: str(r['path']),
      totalBytes: integer(r['totalBytes']),
      freeBytes: integer(r['freeBytes']),
      usbMassStorage: r['usbMassStorage'] == true,
      mountedAt: switch (integer(r['mountedAtMs'])) {
        final ms? => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
        null => null,
      },
    );
  }

  /// Null for the primary volume (and odd non-primary ones).
  final String? uuid;
  final bool isPrimary;
  final bool isRemovable;

  /// `StorageVolume.getDescription` ("SanDisk SD card", "USB drive").
  final String description;

  /// `Environment.MEDIA_*` (`mounted`, `unmounted`, `ejecting`…).
  final String state;
  final bool isMounted;

  /// Null when unmounted or unknown.
  final String? rootPath;
  final int? totalBytes;
  final int? freeBytes;

  /// A USB mass-storage device was attached when the list was read.
  final bool usbMassStorage;

  /// Windows (PL1): a non-system drive that stays in the PC (second disk,
  /// network drive): a place like internal storage, never ejected.
  final bool isFixed;

  /// Windows (PL1): the disk's bus (`usb`, `sd`, …) when known; decides the
  /// place kind before the description does.
  final String? bus;

  /// U2 (h): when it was mounted (`MountTimesReceiver.kt`; the boot time
  /// when no mount was recorded). Null when unmounted or unknown.
  final DateTime? mountedAt;

  @override
  bool operator ==(Object other) =>
      other is VolumeInfo &&
      other.uuid == uuid &&
      other.isPrimary == isPrimary &&
      other.isRemovable == isRemovable &&
      other.description == description &&
      other.state == state &&
      other.isMounted == isMounted &&
      other.rootPath == rootPath &&
      other.totalBytes == totalBytes &&
      other.freeBytes == freeBytes &&
      other.usbMassStorage == usbMassStorage &&
      other.isFixed == isFixed &&
      other.bus == bus &&
      other.mountedAt == mountedAt;

  @override
  int get hashCode => Object.hash(
    uuid,
    isPrimary,
    isRemovable,
    description,
    state,
    isMounted,
    rootPath,
    totalBytes,
    freeBytes,
    usbMassStorage,
    isFixed,
    bus,
    mountedAt,
  );
}

/// A live event of `com.kaf.kfm/volumes/events`.
@immutable
sealed class VolumeEvent {
  const new();
}

/// A volume changed state (mounted, ejecting, unmounted, removed…).
class VolumeStateChanged extends VolumeEvent {
  const new({required this.uuid, required this.state});

  final String? uuid;
  final String state;
}

/// A USB device with a mass-storage interface was attached (U1 format
/// help: shown when no volume mounts soon after).
class UsbMassStorageAttached extends VolumeEvent {
  const new();
}

/// Why [VolumesPlatform.eject] didn't eject.
enum VolumeEjectError {
  /// Another program still has files open on the volume.
  inUse,

  /// The device can't be ejected.
  notEjectable,
  failed,
}

/// The volume list and its live changes (Android: [VolumesChannel],
/// Windows: `WindowsVolumes`).
abstract interface class VolumesPlatform {
  Future<List<VolumeInfo>> list();

  /// Android API level (decides SAF vs direct path).
  Future<int> sdkInt();

  /// Broadcast; the native callback/receiver runs while listened.
  Stream<VolumeEvent> events();

  /// U3: opens the system storage screen (where the user taps Eject).
  /// Returns the settings action that opened.
  Future<String?> openStorageSettings();

  /// U3 on Windows: the app ejects the volume itself ([eject]) instead of
  /// handing off to [openStorageSettings].
  bool get ejectsDirectly;

  /// Ejects the volume at [rootPath]; null when it was ejected. Only when
  /// [ejectsDirectly].
  Future<VolumeEjectError?> eject(String rootPath);
}

/// Typed wrapper around `com.kaf.kfm/volumes` (+ `/events`).
class VolumesChannel implements VolumesPlatform {
  new({MethodChannel? channel, EventChannel? events})
    : _channel = channel ?? const MethodChannel(name),
      _events = events ?? const EventChannel(eventsName);

  static const name = 'com.kaf.kfm/volumes';
  static const eventsName = 'com.kaf.kfm/volumes/events';

  final MethodChannel _channel;
  final EventChannel _events;
  int? _sdk;

  @override
  Future<List<VolumeInfo>> list() async {
    final rows =
        await _channel.invokeListMethod<Map<Object?, Object?>>('list') ??
        const [];
    return rows.map(VolumeInfo.fromRow).toList(growable: false);
  }

  @override
  Future<String?> openStorageSettings() =>
      _channel.invokeMethod<String>('openStorageSettings');

  @override
  Future<int> sdkInt() async =>
      _sdk ??= await _channel.invokeMethod<int>('sdkInt') ?? 0;

  /// Android apps can't unmount volumes.
  @override
  bool get ejectsDirectly => false;

  @override
  Future<VolumeEjectError?> eject(String rootPath) =>
      throw UnsupportedError('Android ejects in the system settings');

  /// One platform stream for every listener: each `receiveBroadcastStream()`
  /// call replaces the channel's message handler, so a second one would
  /// silently take the events away from the first (U3 emulator check:
  /// places stopped refreshing once the watcher listened too).
  late final Stream<VolumeEvent> _shared = _events
      .receiveBroadcastStream()
      .where((e) => e is Map)
      .map((e) => parseVolumeEvent(e as Map<Object?, Object?>));

  @override
  Stream<VolumeEvent> events() => _shared;
}

@visibleForTesting
VolumeEvent parseVolumeEvent(Map<Object?, Object?> e) {
  if (e['usbMassStorage'] == true) return const UsbMassStorageAttached();
  final uuid = e['uuid'];
  final state = e['state'];
  return VolumeStateChanged(
    uuid: uuid is String ? uuid : null,
    state: state is String ? state : 'unknown',
  );
}
