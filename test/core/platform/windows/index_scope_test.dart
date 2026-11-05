import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/files/system_files.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';

import 'fake_windows_channel.dart';

WindowsDrive _drive(
  String path, {
  bool system = false,
  bool removable = false,
  String type = 'fixed',
}) => WindowsDrive(
  path: path,
  isSystem: system,
  type: type,
  isRemovable: removable,
  isMounted: true,
);

/// TASK-E2 §6: "Look everywhere" replaces "Folders KFM scans".
void main() {
  group('effectiveIndexScope (settings migration, no startup write)', () {
    test('never chosen: custom roots → chosen folders, else everywhere', () {
      expect(effectiveIndexScope('', const []), IndexScope.everywhere);
      expect(
        effectiveIndexScope('', const ['E:/Photos']),
        IndexScope.chosenFolders,
      );
    });
    test('a stored choice wins; unknown names → everywhere', () {
      expect(
        effectiveIndexScope('whereIAm', const ['E:/x']),
        IndexScope.whereIAm,
      );
      expect(
        effectiveIndexScope('everywhere', const ['E:/x']),
        IndexScope.everywhere,
      );
      expect(
        effectiveIndexScope('chosenFolders', const []),
        IndexScope.chosenFolders,
      );
      expect(
        effectiveIndexScope('bogus', const ['E:/x']),
        IndexScope.everywhere,
      );
    });
  });

  group('isWindowsSystemFolder', () {
    test('OS, program and app-data folders are skipped', () {
      for (final p in [
        'C:/Windows',
        'D:/Program Files',
        'C:/Program Files (x86)',
        'C:/ProgramData',
        r'D:/$Recycle.Bin',
        'E:/System Volume Information',
        'C:/Users/me/AppData',
        'D:/Photos/.KFMTrash',
      ]) {
        expect(isWindowsSystemFolder(p), isTrue, reason: p);
      }
    });
    test("the user's folders are kept", () {
      for (final p in [
        'C:/Users/me/Pictures',
        'D:/Photos/Windows', // only at a drive root
        'D:/Games',
        'C:/Users/me/Documents/Program Files notes',
      ]) {
        expect(isWindowsSystemFolder(p), isFalse, reason: p);
      }
    });
  });

  group('WindowsIndexRoots scopes', () {
    late AppDatabase db;
    late DbWriteQueue queue;
    late SettingsRepository settings;
    late FakeWindowsChannel channel;
    late WindowsIndexRoots roots;

    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(NativeDatabase.memory());
      queue = DbWriteQueue();
      settings = SettingsRepository(db, queue);
      channel =
          FakeWindowsChannel(
              known: {KnownFolder.pictures: 'C:/Users/me/Pictures'},
            )
            ..drives = [
              _drive('C:', system: true),
              _drive('D:'),
              _drive('E:', removable: true, type: 'removable'),
            ];
      roots = WindowsIndexRoots(
        settings: settings,
        channel: channel,
        environment: const {'USERPROFILE': r'C:\Users\me'},
      );
    });
    tearDown(() async {
      await queue.close();
      await db.close();
    });

    test(
      'fresh install: everywhere = the profile + other fixed drives',
      () async {
        expect(await roots.scope(), IndexScope.everywhere);
        expect(await roots.current(), ['C:/Users/me', 'D:']);
      },
    );

    test('an update with custom roots keeps them (chosen folders)', () async {
      await settings.write(AppSettings.windowsIndexRoots, ['F:/Media']);
      expect(await roots.scope(), IndexScope.chosenFolders);
      expect(await roots.current(), ['F:/Media']);
      // Turning Look everywhere on later keeps the list for "Choose folders".
      await roots.setScope(IndexScope.everywhere);
      expect(await roots.current(), ['C:/Users/me', 'D:']);
      expect(await roots.chosen(), ['F:/Media']);
    });

    test('where I am: only the open folders; watch follows them', () async {
      await roots.setScope(IndexScope.whereIAm);
      expect(await roots.current(), isEmpty);
      final seen = <List<String>>[];
      final sub = roots.watch().listen(seen.add);
      await pumpEventQueue();
      roots.setOpenFolders(['D:/Photos']);
      await pumpEventQueue();
      roots.setOpenFolders(['D:/Photos']); // same: no new value
      await pumpEventQueue();
      expect(await roots.current(), ['D:/Photos']);
      expect(seen.last, ['D:/Photos']);
      expect(seen.where((r) => r.isNotEmpty), hasLength(1));
      await roots.setScope(IndexScope.everywhere);
      await pumpEventQueue();
      expect(seen.last, ['C:/Users/me', 'D:']);
      await sub.cancel();
    });

    test('no drive list (native side missing): only the profile', () async {
      final bare = WindowsIndexRoots(
        settings: settings,
        channel: FakeWindowsChannel(missing: true),
        environment: const {'USERPROFILE': r'C:\Users\me'},
      );
      expect(await bare.current(), ['C:/Users/me']);
    });
  });
}
