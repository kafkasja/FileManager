import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/core/platform/volumes/volumes_channel.dart';
import 'package:kfm/core/platform/volumes/volumes_providers.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/browse/ui/browse_screen.dart';
import 'package:kfm/features/external_storage/data/saf_grants.dart';
import 'package:kfm/features/external_storage/data/volume_activity_tracker.dart';
import 'package:kfm/features/external_storage/ui/place_browser_screen.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';
import '../../helpers/pump_app.dart';
import 'fake_volumes.dart';

const _sd = '/storage/1234-ABCD';

Future<void> _openBrowse(WidgetTester tester) async {
  await tester.tap(find.text('Browse'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no Places section with internal storage only', (tester) async {
    final volumes = FakeVolumes();
    addTearDown(volumes.close);
    await pumpApp(
      tester,
      overrides: [
        volumesPlatformProvider.overrideWithValue(volumes),
        mtpPlatformProvider.overrideWithValue(null),
      ],
    );
    await _openBrowse(tester);
    expect(find.text('Places'), findsNothing);
  });

  testWidgets('an SD card shows with free/total; tapping opens its folder; '
      'plug and unplug show snackbars', (tester) async {
    final volumes = FakeVolumes([internalVolume, sdVolume()]);
    addTearDown(volumes.close);
    final files = FakeFileSource()..addFile('$_sd/DCIM/a.jpg');
    final app = await pumpApp(
      tester,
      files: files,
      overrides: [
        volumesPlatformProvider.overrideWithValue(volumes),
        mtpPlatformProvider.overrideWithValue(null),
      ],
    );
    await _openBrowse(tester);
    expect(find.text('Places'), findsOneWidget);
    expect(find.text('Internal storage'), findsWidgets);
    expect(find.text('SanDisk SD card'), findsOneWidget);
    expect(
      find.text('${formatBytes(12 << 30)} free of ${formatBytes(64 << 30)}'),
      findsOneWidget,
    );

    // All files access is granted on API 34: direct path, no picker.
    await tester.tap(find.text('SanDisk SD card'));
    await tester.pumpAndSettle();
    expect(app.container.read(browseViewControllerProvider).folder, _sd);
    expect(find.byType(BrowseScreen), findsOneWidget);
    // U2 follow-up: the breadcrumb uses the same name as Places.
    expect(find.text('SD card or USB (1234-ABCD)'), findsNothing);
    expect(find.text('SanDisk SD card'), findsWidgets);

    // Unplugged: Browse leaves the card's folder, "Storage removed".
    volumes
      ..volumes = [internalVolume]
      ..emit(const VolumeStateChanged(uuid: '1234-ABCD', state: 'removed'));
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump();
    await tester.pump();
    expect(find.text('Storage removed'), findsOneWidget);
    expect(app.container.read(browseViewControllerProvider).folder, isNull);
    // Entrance animation, then the 4 s display time.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Plugged in again: "<label> connected · Open".
    volumes
      ..volumes = [internalVolume, sdVolume()]
      ..emit(const VolumeStateChanged(uuid: '1234-ABCD', state: 'mounted'));
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump();
    await tester.pump();
    expect(find.text('SanDisk SD card connected'), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, 'Open'), findsOneWidget);
    // Let the 30 s re-scan timer and the snackbar run out.
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
  });

  testWidgets('U1 (f): API 30+ without All files access explains it, '
      'opens its page and then the card by path (no SAF picker)', (
    tester,
  ) async {
    final volumes = FakeVolumes([internalVolume, sdVolume()]);
    addTearDown(volumes.close);
    final trees = FakeSafTrees();
    final perms = FakePermissionService(
      grantedAccess.copyWith(allFiles: AllFilesAccess.notGranted),
    );
    final app = await pumpApp(
      tester,
      files: FakeFileSource()..addFile('$_sd/DCIM/a.jpg'),
      permissions: perms,
      overrides: [
        volumesPlatformProvider.overrideWithValue(volumes),
        mtpPlatformProvider.overrideWithValue(null),
        safTreePlatformProvider.overrideWithValue(trees),
      ],
    );
    await _openBrowse(tester);

    // Cancelled: nothing opens, no picker.
    await tester.tap(find.text('SanDisk SD card'));
    await tester.pumpAndSettle();
    expect(find.text('Open SanDisk SD card'), findsOneWidget);
    expect(find.text('Allow access to SanDisk SD card'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(perms.calls, isNot(contains('openAllFilesAccessSettings')));

    // Came back without turning it on: told so, still nothing opens.
    await tester.tap(find.text('SanDisk SD card'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'All files access is still off, so SanDisk SD card can’t be '
        'opened.',
      ),
      findsOneWidget,
    );
    expect(app.container.read(browseViewControllerProvider).folder, isNull);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    // Turned on in the system page: the card opens by path.
    await tester.tap(find.text('SanDisk SD card'));
    await tester.pumpAndSettle();
    perms.current = grantedAccess;
    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();
    expect(
      perms.calls.where((c) => c == 'openAllFilesAccessSettings'),
      hasLength(2),
    );
    expect(trees.calls, isEmpty);
    expect(app.container.read(browseViewControllerProvider).folder, _sd);
    expect(find.byType(PlaceBrowserScreen), findsNothing);
    // Let the access change's re-scan timers run out.
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
  });

  testWidgets('API 29 without All files access: explanation, a subfolder is '
      'refused, the drive root is kept', (tester) async {
    final volumes = FakeVolumes([internalVolume, sdVolume()])..sdk = 29;
    addTearDown(volumes.close);
    final trees = FakeSafTrees();
    final app = await pumpApp(
      tester,
      permissions: FakePermissionService(
        grantedAccess.copyWith(allFiles: AllFilesAccess.notGranted),
      ),
      overrides: [
        volumesPlatformProvider.overrideWithValue(volumes),
        mtpPlatformProvider.overrideWithValue(null),
        safTreePlatformProvider.overrideWithValue(trees),
      ],
    );
    await _openBrowse(tester);
    await tester.tap(find.text('SanDisk SD card'));
    await tester.pumpAndSettle();
    expect(find.text('Allow access to SanDisk SD card'), findsOneWidget);

    trees.nextPick = (uri: 'sub', treeDocumentId: '1234-ABCD:DCIM');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Pick the drive itself'), findsOneWidget);
    expect(trees.persisted, isEmpty);

    trees.nextPick = (uri: 'root', treeDocumentId: '1234-ABCD:');
    await tester.tap(find.text('Pick again'));
    await tester.pumpAndSettle();
    expect(trees.calls, ['pick 1234-ABCD', 'pick 1234-ABCD', 'persist root']);
    expect(
      await app.container
          .read(settingsRepositoryProvider)
          .read(AppSettings.externalSafGrants),
      {'1234-ABCD': 'root'},
    );
    // U2: a SAF volume opens in the place browser (scan-based).
    expect(find.byType(PlaceBrowserScreen), findsOneWidget);
  });

  testWidgets('U3: Eject on an idle SD card hands off to settings and '
      'confirms once it is gone', (tester) async {
    final volumes = FakeVolumes([internalVolume, sdVolume()]);
    addTearDown(volumes.close);
    final app = await pumpApp(
      tester,
      files: FakeFileSource(),
      overrides: [
        volumesPlatformProvider.overrideWithValue(volumes),
        mtpPlatformProvider.overrideWithValue(null),
      ],
    );
    await _openBrowse(tester);
    expect(find.byKey(const ValueKey('eject-primary')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('eject-1234-ABCD')));
    await tester.pumpAndSettle();
    expect(find.text('Eject SanDisk SD card'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('eject-open-settings')));
    await tester.pumpAndSettle();
    expect(volumes.settingsOpened, 1);
    VolumeActivity activity() =>
        app.container.read(volumeActivityTrackerProvider);
    expect(activity().isEjecting('1234-ABCD'), isTrue);

    // Ejected in the system screen: the volume goes away.
    volumes
      ..volumes = [internalVolume]
      ..emit(const VolumeStateChanged(uuid: '1234-ABCD', state: 'unmounted'));
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump();
    await tester.pump();
    expect(find.text('SanDisk SD card can be safely removed'), findsOneWidget);
    expect(find.text('Storage removed'), findsNothing);
    expect(activity().isEjecting('1234-ABCD'), isFalse);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });

  testWidgets('PL1: a platform that ejects directly (Windows) ejects without '
      'the settings hand-off', (tester) async {
    final volumes = FakeVolumes([internalVolume, sdVolume()])
      ..ejectsDirectly = true;
    addTearDown(volumes.close);
    final app = await pumpApp(
      tester,
      files: FakeFileSource(),
      overrides: [
        volumesPlatformProvider.overrideWithValue(volumes),
        mtpPlatformProvider.overrideWithValue(null),
      ],
    );
    await _openBrowse(tester);
    await tester.tap(find.byKey(const ValueKey('eject-1234-ABCD')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('eject-open-settings')), findsNothing);
    expect(volumes.ejected, [_sd]);
    expect(volumes.settingsOpened, 0);
    VolumeActivity activity() =>
        app.container.read(volumeActivityTrackerProvider);
    expect(activity().isEjecting('1234-ABCD'), isTrue);

    volumes
      ..volumes = [internalVolume]
      ..emit(const VolumeStateChanged(uuid: null, state: 'changed'));
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump();
    await tester.pump();
    expect(find.text('SanDisk SD card can be safely removed'), findsOneWidget);
    expect(activity().isEjecting('1234-ABCD'), isFalse);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });

  testWidgets('PL1: a refused direct eject cancels it and says the drive is '
      'in use', (tester) async {
    final volumes = FakeVolumes([internalVolume, sdVolume()])
      ..ejectsDirectly = true
      ..ejectError = VolumeEjectError.inUse;
    addTearDown(volumes.close);
    final app = await pumpApp(
      tester,
      files: FakeFileSource(),
      overrides: [
        volumesPlatformProvider.overrideWithValue(volumes),
        mtpPlatformProvider.overrideWithValue(null),
      ],
    );
    await _openBrowse(tester);
    await tester.tap(find.byKey(const ValueKey('eject-1234-ABCD')));
    await tester.pumpAndSettle();
    expect(volumes.ejected, [_sd]);
    expect(
      find.text(
        'SanDisk SD card is still in use by another program. '
        'Close it and try again.',
      ),
      findsOneWidget,
    );
    expect(
      app.container
          .read(volumeActivityTrackerProvider)
          .isEjecting('1234-ABCD'),
      isFalse,
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });
}
