import 'dart:io';

import 'package:kfm/core/files/android/files_channel.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_space.g.dart';

/// Total and free space of the primary volume (C1; X5 free-space check).
@immutable
class DeviceSpace {
  const new({required this.totalBytes, required this.freeBytes});

  final int totalBytes;
  final int freeBytes;

  int get usedBytes => totalBytes - freeBytes;
}

abstract interface class DeviceSpaceSource {
  Future<DeviceSpace> read();
}

/// Android: `StatFs` on the primary volume through FilesChannel.
class AndroidDeviceSpaceSource implements DeviceSpaceSource {
  new(this._channel);

  final FilesChannel _channel;

  @override
  Future<DeviceSpace> read() async {
    final s = await _channel.storageSpace();
    return DeviceSpace(totalBytes: s.totalBytes, freeBytes: s.freeBytes);
  }
}

/// Other platforms until PL1/PL2: unknown.
class UnsupportedDeviceSpaceSource implements DeviceSpaceSource {
  const new();

  @override
  Future<DeviceSpace> read() => Future.error(UnsupportedError('device space'));
}

@Riverpod(keepAlive: true)
DeviceSpaceSource deviceSpaceSource(Ref ref) => Platform.isAndroid
    ? AndroidDeviceSpaceSource(FilesChannel())
    : const UnsupportedDeviceSpaceSource();
