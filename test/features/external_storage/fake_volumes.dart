import 'dart:async';

import 'package:kfm/core/platform/volumes/mtp_channel.dart';
import 'package:kfm/core/platform/volumes/volumes_channel.dart';
import 'package:kfm/features/external_storage/data/saf_grants.dart';

const internalVolume = VolumeInfo(
  uuid: null,
  isPrimary: true,
  isRemovable: false,
  description: 'Internal shared storage',
  state: 'mounted',
  isMounted: true,
  rootPath: '/storage/emulated/0',
  totalBytes: 128 << 30,
  freeBytes: 40 << 30,
);

VolumeInfo sdVolume({
  String uuid = '1234-ABCD',
  bool mounted = true,
  String description = 'SanDisk SD card',
  DateTime? mountedAt,
}) => VolumeInfo(
  uuid: uuid,
  isPrimary: false,
  isRemovable: true,
  description: description,
  state: mounted ? 'mounted' : 'unmounted',
  isMounted: mounted,
  rootPath: mounted ? '/storage/$uuid' : null,
  totalBytes: mounted ? 64 << 30 : null,
  freeBytes: mounted ? 12 << 30 : null,
  mountedAt: mountedAt,
);

/// Scriptable [VolumesPlatform].
class FakeVolumes implements VolumesPlatform {
  new([List<VolumeInfo>? volumes]) : volumes = volumes ?? [internalVolume];

  List<VolumeInfo> volumes;
  int sdk = 34;
  int listCalls = 0;
  Error? listError;
  final _events = StreamController<VolumeEvent>.broadcast();

  @override
  Future<List<VolumeInfo>> list() async {
    listCalls++;
    if (listError case final e?) throw e;
    return List.of(volumes);
  }

  @override
  Future<int> sdkInt() async => sdk;

  @override
  Stream<VolumeEvent> events() => _events.stream;

  int settingsOpened = 0;

  @override
  Future<String?> openStorageSettings() async {
    settingsOpened++;
    return 'android.settings.INTERNAL_STORAGE_SETTINGS';
  }

  void emit(VolumeEvent e) => _events.add(e);

  Future<void> close() => _events.close();
}

class FakeMtp implements MtpPlatform {
  List<UsbCamera> cameras = [];
  final List<String> requested = [];
  final _changes = StreamController<void>.broadcast();

  @override
  Future<List<UsbCamera>> list() async => List.of(cameras);

  @override
  Future<bool> requestPermission(String deviceName) async {
    requested.add(deviceName);
    return true;
  }

  @override
  Stream<void> changes() => _changes.stream;

  void changed() => _changes.add(null);

  final List<String> closed = [];

  @override
  Future<bool> close(String deviceName) async {
    closed.add(deviceName);
    return true;
  }
}

class FakeSafTrees implements SafTreePlatform {
  ({String uri, String? treeDocumentId})? nextPick;
  final Set<String> persisted = {};
  bool persistWorks = true;
  bool rootValid = true;
  final List<String> calls = [];

  @override
  Future<({String uri, String? treeDocumentId})?> pickTree({
    String? uuid,
  }) async {
    calls.add('pick $uuid');
    return nextPick;
  }

  @override
  Future<bool> persistTree(String uri) async {
    calls.add('persist $uri');
    if (persistWorks) persisted.add(uri);
    return persistWorks;
  }

  @override
  Future<bool> releaseTree(String uri) async {
    calls.add('release $uri');
    return persisted.remove(uri);
  }

  @override
  Future<List<String>> persistedTrees() async => persisted.toList();

  @override
  Future<bool> validateTree(String uri) async =>
      persisted.contains(uri) && rootValid;
}
