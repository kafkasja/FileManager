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
      other.usbMassStorage == usbMassStorage;

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

/// The volume list and its live changes (Android: [VolumesChannel]).
abstract interface class VolumesPlatform {
  Future<List<VolumeInfo>> list();

  /// Android API level (decides SAF vs direct path).
  Future<int> sdkInt();

  /// Broadcast; the native callback/receiver runs while listened.
  Stream<VolumeEvent> events();
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
  Future<int> sdkInt() async =>
      _sdk ??= await _channel.invokeMethod<int>('sdkInt') ?? 0;

  @override
  Stream<VolumeEvent> events() => _events
      .receiveBroadcastStream()
      .where((e) => e is Map)
      .map((e) => parseVolumeEvent(e as Map<Object?, Object?>));
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
