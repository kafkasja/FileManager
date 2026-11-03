import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/platform/volumes/mtp_channel.dart';
import 'package:kfm/core/platform/volumes/volumes_channel.dart';
import 'package:kfm/core/platform/volumes/volumes_providers.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';

import 'fake_volumes.dart';

void main() {
  List<StoragePlace> build({
    List<VolumeInfo>? volumes,
    List<UsbCamera> cameras = const [],
    Map<String, String> grants = const {},
    bool canSeeAll = true,
    int sdk = 34,
  }) => buildPlaces(
    volumes: volumes ?? [sdVolume(), internalVolume],
    cameras: cameras,
    safGrants: grants,
    canSeeAllFiles: canSeeAll,
    sdkInt: sdk,
  );

  test('internal storage first, removable after, cameras last', () {
    final places = build(
      cameras: const [
        UsbCamera(
          deviceName: '/dev/bus/usb/001/002',
          hasPermission: false,
          product: 'EOS',
        ),
      ],
    );
    expect(places.map((p) => p.id), [
      kInternalPlaceId,
      '1234-ABCD',
      'mtp:/dev/bus/usb/001/002',
    ]);
    expect(places[0].kind, PlaceKind.internal);
    expect(places[0].access, AccessMethod.directPath);
    expect(places[1].kind, PlaceKind.sdCard);
    expect(places[1].rootPath, '/storage/1234-ABCD');
    expect(places[1].freeBytes, 12 << 30);
    expect(places[2].kind, PlaceKind.camera);
    expect(places[2].access, AccessMethod.mtp);
    expect(places[2].needsPermission, isTrue);
    expect(places[2].volumeUuid, isNull);
    expect(places[1].volumeUuid, '1234-ABCD');
  });

  test('access method follows the API level and All files access', () {
    StoragePlace sd({required bool all, required int sdk}) =>
        build(canSeeAll: all, sdk: sdk, grants: {'1234-ABCD': 'tree'})[1];
    expect(sd(all: true, sdk: 34).access, AccessMethod.directPath);
    expect(sd(all: true, sdk: 34).treeUri, isNull);
    expect(sd(all: false, sdk: 34).access, AccessMethod.saf);
    expect(sd(all: false, sdk: 34).treeUri, 'tree');
    expect(sd(all: true, sdk: 29).access, AccessMethod.saf);
    expect(build(canSeeAll: false)[1].needsGrant, isTrue);
  });

  test('kind from the description, else an attached USB device', () {
    PlaceKind kind(String d, {bool usb = false}) => placeKindOf(
      VolumeInfo(
        uuid: 'X',
        isPrimary: false,
        isRemovable: true,
        description: d,
        state: 'mounted',
        isMounted: true,
        usbMassStorage: usb,
      ),
    );
    expect(kind('SanDisk SD card'), PlaceKind.sdCard);
    expect(kind('Generic USB drive'), PlaceKind.usbDrive);
    expect(kind('USB storage', usb: true), PlaceKind.usbDrive);
    expect(kind('Disk'), PlaceKind.unknown);
    expect(kind('Disk', usb: true), PlaceKind.usbDrive);
    // "sd" inside a word isn't an SD card.
    expect(kind('Wisdom'), PlaceKind.unknown);
  });

  test('mounted direct-path roots feed D4 reconcile', () {
    expect(mountedDirectPathRoots(build()), [
      '/storage/emulated/0',
      '/storage/1234-ABCD',
    ]);
    expect(mountedDirectPathRoots(build(canSeeAll: false)), [
      '/storage/emulated/0',
    ]);
    expect(
      mountedDirectPathRoots(build(volumes: [sdVolume(mounted: false)])),
      isEmpty,
    );
  });

  test('detached roots: indexed, not mounted, never internal', () {
    final indexed = {'/storage/1234-ABCD', '/storage/AAAA-BBBB'};
    expect(detachedRoots(indexed, [internalVolume, sdVolume()]), {
      '/storage/AAAA-BBBB',
    });
    expect(
      detachedRoots({...indexed, '/storage/emulated'}, [internalVolume]),
      indexed,
    );
  });

  test('direct-path removable roots: mounted cards on API 30+ only', () async {
    final volumes = FakeVolumes([
      internalVolume,
      sdVolume(),
      sdVolume(uuid: 'AAAA-BBBB', mounted: false),
    ]);
    addTearDown(volumes.close);
    expect(await readDirectPathRemovableRoots(volumes), ['/storage/1234-ABCD']);
    volumes.sdk = 29; // SAF only there
    expect(await readDirectPathRemovableRoots(volumes), isEmpty);
  });

  test('parseVolumeEvent', () {
    expect(
      parseVolumeEvent({'usbMassStorage': true}),
      isA<UsbMassStorageAttached>(),
    );
    final e = parseVolumeEvent({'uuid': 'X', 'state': 'ejecting'});
    expect(e, isA<VolumeStateChanged>());
    expect((e as VolumeStateChanged).state, 'ejecting');
  });
}
