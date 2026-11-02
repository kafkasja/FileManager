import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/core/platform/volumes/mtp_channel.dart';
import 'package:kfm/core/platform/volumes/volumes_channel.dart';
import 'package:kfm/core/platform/volumes/volumes_providers.dart';
import 'package:kfm/core/utils/debouncer.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'places_repository.g.dart';

/// What the device reports right now (TASK-U1).
@immutable
class DeviceStorage {
  const new({
    required this.volumes,
    required this.cameras,
    required this.sdkInt,
  });

  static const empty = DeviceStorage(volumes: [], cameras: [], sdkInt: 0);

  final List<VolumeInfo> volumes;
  final List<UsbCamera> cameras;
  final int sdkInt;

  @override
  bool operator ==(Object other) =>
      other is DeviceStorage &&
      listEquals(other.volumes, volumes) &&
      listEquals(other.cameras, cameras) &&
      other.sdkInt == sdkInt;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(volumes), Object.hashAll(cameras), sdkInt);
}

/// Reads the volumes (and cameras) on listen and again after every state
/// event, debounced by [debounce] (a loose cable flaps). Reads run one at
/// a time, in order. A failed read is an error event; later events read
/// again.
Stream<DeviceStorage> watchDeviceStorage(
  VolumesPlatform volumes,
  MtpPlatform? mtp, {
  Duration debounce = const Duration(seconds: 1),
}) {
  late final StreamController<DeviceStorage> controller;
  final debouncer = Debouncer(debounce);
  final subs = <StreamSubscription<Object?>>[];
  var tail = Future<void>.value();

  Future<void> read() async {
    try {
      final list = await volumes.list();
      final cameras = mtp == null ? const <UsbCamera>[] : await mtp.list();
      final sdk = await volumes.sdkInt();
      if (!controller.isClosed) {
        controller.add(
          DeviceStorage(volumes: list, cameras: cameras, sdkInt: sdk),
        );
      }
    } on Object catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  void schedule() => debouncer.run(() => tail = tail.then((_) => read()));

  controller = StreamController<DeviceStorage>(
    onListen: () {
      subs.add(
        volumes.events().listen(
          (e) {
            if (e is VolumeStateChanged) schedule();
          },
          onError: (Object e, StackTrace st) {
            if (!controller.isClosed) controller.addError(e, st);
          },
        ),
      );
      if (mtp != null) {
        subs.add(
          mtp.changes().listen(
            (_) => schedule(),
            onError: (Object e, StackTrace st) {
              if (!controller.isClosed) controller.addError(e, st);
            },
          ),
        );
      }
      tail = tail.then((_) => read());
    },
    onCancel: () async {
      debouncer.cancel();
      for (final s in subs) {
        await s.cancel();
      }
      subs.clear();
      await tail;
    },
  );
  return controller.stream;
}

/// The device's volumes and cameras, live. Empty off Android.
@Riverpod(keepAlive: true)
Stream<DeviceStorage> deviceStorage(Ref ref) {
  final volumes = ref.watch(volumesPlatformProvider);
  if (volumes == null) return Stream.value(DeviceStorage.empty);
  return watchDeviceStorage(volumes, ref.watch(mtpPlatformProvider));
}

/// U1: SAF grants (volume uuid → tree URI).
@Riverpod(keepAlive: true)
Stream<Map<String, String>> externalSafGrants(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.externalSafGrants);

/// Every storage place, internal storage first. Recomputed when a volume
/// or camera changes, a grant is saved, or All files access flips (the
/// access method follows it; re-checked on resume). Errors surface as
/// `AsyncError` (rule 8).
@Riverpod(keepAlive: true)
Future<List<StoragePlace>> places(Ref ref) async {
  final access = await ref.watch(storageAccessControllerProvider.future);
  final canSeeAll = access.canSeeAllFiles;
  final grants = await ref.watch(externalSafGrantsProvider.future);
  final device = await ref.watch(deviceStorageProvider.future);
  return buildPlaces(
    volumes: device.volumes,
    cameras: device.cameras,
    safGrants: grants,
    canSeeAllFiles: canSeeAll,
    sdkInt: device.sdkInt,
  );
}

/// U1: indexed roots of volumes that aren't mounted now. Their rows are
/// hidden from every view (`MediaIndexDao.excludedRoots`), never deleted.
@Riverpod(keepAlive: true)
Future<Set<String>> unmountedRoots(Ref ref) async {
  final device = await ref.watch(deviceStorageProvider.future);
  if (ref.watch(volumesPlatformProvider) == null) return const {};
  final indexed = await ref.watch(mediaIndexDaoProvider).indexedVolumeRoots();
  return detachedRoots(indexed, device.volumes);
}

/// D4: the roots `PendingFolder.reconcile` looks in: internal storage plus
/// every mounted place reached by path (internal only off Android).
Future<List<String>> pendingFolderRoots(
  Ref ref, {
  required String primaryRoot,
}) async {
  final places = await ref.read(placesProvider.future);
  return {primaryRoot, ...mountedDirectPathRoots(places)}.toList();
}
