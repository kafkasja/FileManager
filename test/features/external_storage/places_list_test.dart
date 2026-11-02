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

  testWidgets('without All files access: explanation, a subfolder is '
      'refused, the drive root is kept', (tester) async {
    final volumes = FakeVolumes([internalVolume, sdVolume()]);
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
    expect(app.container.read(browseViewControllerProvider).folder, _sd);
  });
}
