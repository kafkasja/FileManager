import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/platform/volumes/volumes_channel.dart';
import 'package:kfm/core/platform/volumes/volumes_providers.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';
import 'package:kfm/core/platform/windows/windows_volumes.dart';
import 'package:kfm/features/external_storage/data/places_watcher.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';

import 'fake_windows_channel.dart';

const _c = WindowsDrive(
  path: 'C:',
  isSystem: true,
  type: 'fixed',
  isRemovable: false,
  isMounted: true,
  uuid: '1111-2222',
  label: 'Windows',
  bus: 'internal',
  totalBytes: 500,
  freeBytes: 100,
);
const _d = WindowsDrive(
  path: 'D:',
  isSystem: false,
  type: 'fixed',
  isRemovable: false,
  isMounted: true,
  uuid: '3333-4444',
  label: 'Data',
  bus: 'internal',
);
const _usb = WindowsDrive(
  path: 'E:',
  isSystem: false,
  type: 'removable',
  isRemovable: true,
  isMounted: true,
  uuid: 'ABCD-1234',
  label: 'KINGSTON',
  bus: 'usb',
  totalBytes: 64,
  freeBytes: 12,
);
const _sd = WindowsDrive(
  path: 'F:',
  isSystem: false,
  type: 'removable',
  isRemovable: true,
  isMounted: true,
  uuid: '5555-6666',
  bus: 'sd',
);
const _net = WindowsDrive(
  path: 'Z:',
  isSystem: false,
  type: 'remote',
  isRemovable: false,
  isMounted: true,
);

void main() {
  test('drive rows parse from the channel', () {
    final d = WindowsDrive.fromRow(const {
      'path': 'e:',
      'system': false,
      'type': 'removable',
      'removable': true,
      'mounted': true,
      'uuid': 'ABCD-1234',
      'label': 'KINGSTON',
      'bus': 'usb',
      'totalBytes': 64,
      'freeBytes': 12,
    });
    expect(d, _usb);
  });

  test('native events parse; unknown ones are dropped', () {
    expect(parseWindowsEvent('volumesChanged', null), isA<VolumesChanged>());
    expect(
      (parseWindowsEvent('power', {'state': 'suspend'})! as PowerChanged).state,
      PowerState.suspend,
    );
    expect(
      (parseWindowsEvent('power', {'state': 'resume'})! as PowerChanged).state,
      PowerState.resume,
    );
    expect(parseWindowsEvent('power', {'state': 'x'}), isNull);
    expect(parseWindowsEvent('other', null), isNull);
  });

  test('drives become U1 places: system first, fixed and network drives '
      'as internal, sticks and cards removable', () async {
    final channel = FakeWindowsChannel()
      ..drives = [_c, _d, _usb, _sd, _net];
    final volumes = WindowsVolumes(channel);
    final places = buildPlaces(
      volumes: await volumes.list(),
      cameras: const [],
      safGrants: const {},
      canSeeAllFiles: true,
      sdkInt: await volumes.sdkInt(),
    );
    expect([for (final p in places) p.id], [
      kInternalPlaceId,
      '3333-4444',
      'ABCD-1234',
      '5555-6666',
      'Z:',
    ]);
    expect([for (final p in places) p.kind], [
      PlaceKind.internal,
      PlaceKind.internal,
      PlaceKind.usbDrive,
      PlaceKind.sdCard,
      PlaceKind.internal,
    ]);
    expect([for (final p in places) p.isRemovable], [
      false,
      false,
      true,
      true,
      false,
    ]);
    expect(places.every((p) => p.access == AccessMethod.directPath), isTrue);
    expect(places[2].rootPath, 'E:');
    expect(places[2].label, 'KINGSTON (E:)');
    expect(places[3].label, 'F:');
    expect(await readMountedRemovableRoots(volumes), ['E:', 'F:']);
  });

  test('a drive unplugged while indexed is detached; mounted drives are '
      'not', () async {
    final volumes = WindowsVolumes(FakeWindowsChannel()..drives = [_c, _d]);
    expect(detachedRoots({'C:', 'D:', 'E:'}, await volumes.list()), {'E:'});
  });

  test('volume events and wake-up re-read the drives; eject maps the '
      'native answer', () async {
    final channel = FakeWindowsChannel()..drives = [_c, _usb];
    final volumes = WindowsVolumes(channel);
    final events = <VolumeEvent>[];
    final sub = volumes.events().listen(events.add);
    addTearDown(sub.cancel);
    channel
      ..emit(const VolumesChanged())
      ..emit(const PowerChanged(PowerState.suspend))
      ..emit(const PowerChanged(PowerState.resume));
    await pumpEventQueue();
    expect(events, hasLength(2));
    expect(events.every((e) => e is VolumeStateChanged), isTrue);

    expect(volumes.ejectsDirectly, isTrue);
    expect(await volumes.eject('E:'), isNull);
    channel.ejectError = DriveEjectError.inUse;
    expect(await volumes.eject('E:'), VolumeEjectError.inUse);
    channel.ejectError = DriveEjectError.notEjectable;
    expect(await volumes.eject('E:'), VolumeEjectError.notEjectable);
    expect(channel.ejected, ['E:', 'E:', 'E:']);
  });

  test('the place locator maps paths on removable drives to their place '
      'and everything else to internal storage', () {
    final locator = WindowsPlaceLocator(() => {'E:': 'ABCD-1234'});
    expect(locator.placeOf('E:/DCIM'), 'ABCD-1234');
    expect(locator.placeOf('e:/DCIM/a.jpg'), 'ABCD-1234');
    expect(locator.placeOf('E:'), 'ABCD-1234');
    expect(locator.placeOf('C:/Users/me/Pictures'), kInternalPlaceId);
    expect(locator.placeOf('/storage/emulated/0'), kInternalPlaceId);
  });

  test('scanOnStart scans the removable places of the first list once',
      () async {
    final scanned = <String>[];
    final watcher = PlacesWatcher(
      scanRoot: (root) async => scanned.add(root),
      scanOnStart: true,
    );
    addTearDown(watcher.dispose);
    final places = buildPlaces(
      volumes: [for (final d in [_c, _usb]) volumeOfDrive(d)],
      cameras: const [],
      safGrants: const {},
      canSeeAllFiles: true,
      sdkInt: WindowsVolumes.directPathSdk,
    );
    watcher
      ..onPlaces(places)
      ..onPlaces(places);
    await pumpEventQueue();
    expect(scanned, ['E:']);
  });
}
