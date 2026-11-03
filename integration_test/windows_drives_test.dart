// Windows-only (TASK-PL1): the channel's drive list in the real runner.
// Run with
//   flutter test integration_test/windows_drives_test.dart -d windows
// Plugging a USB stick in / ejecting it needs a person (see the PL1 notes).
@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kfm/core/platform/volumes/volumes_channel.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';
import 'package:kfm/core/platform/windows/windows_volumes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('drives: the system drive is listed, mounted, not removable', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final channel = WindowsChannel();
      final drives = await channel.listDrives();
      final systemLetter = (Platform.environment['SystemDrive'] ?? 'C:')
          .toUpperCase();
      final system = drives.singleWhere((d) => d.isSystem);
      expect(system.path, systemLetter);
      expect(system.isMounted, isTrue);
      expect(system.isRemovable, isFalse);
      expect(system.totalBytes, greaterThan(0));
      expect(system.freeBytes, lessThanOrEqualTo(system.totalBytes!));
      expect(system.uuid, matches(RegExp(r'^[0-9A-F]{4}-[0-9A-F]{4}$')));
      for (final d in drives) {
        expect(d.path, matches(RegExp(r'^[A-Z]:$')));
      }

      final volumes = await WindowsVolumes(channel).list();
      expect(volumes.where((v) => v.isPrimary), hasLength(1));
      expect(volumes.first.rootPath, isNotNull);

      // The system drive is refused before Plug and Play is asked.
      expect(
        await channel.ejectDrive(systemLetter),
        DriveEjectError.notEjectable,
      );
      expect(
        VolumeEjectError.values.map((e) => e.name),
        containsAll(DriveEjectError.values.map((e) => e.name)),
      );
    });
  });
}
