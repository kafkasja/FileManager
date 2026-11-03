import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/backup/data/backup_providers.dart';
import 'package:kfm/features/backup/data/backup_service.dart';
import 'package:kfm/features/backup/ui/backup_swipe_sync.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/ui/active_preset_controller.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';
import 'backup_test_utils.dart';

/// X6 follow-up (emulator check 2026-11-02): import → section undo →
/// import → snackbar undo left the deck on a deleted preset.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late AppDatabase db;
  late FakeFileSource files;
  late String backupJson;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tmp = Directory.systemTemp.createTempSync('kfm_backup_seq');
    db = AppDatabase(NativeDatabase.memory());
    files = FakeFileSource();
    for (var i = 0; i < 6; i++) {
      files.addFile(
        '/s/DCIM/Camera/p$i.jpg',
        modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
      );
    }
    // The backup: one preset, active.
    final src = AppDatabase(NativeDatabase.memory());
    final srcQueue = DbWriteQueue();
    final preset = await addPreset(src, 'Trip');
    await SettingsRepository(
      src,
      srcQueue,
    ).write(AppSettings.activePresetId, preset);
    backupJson = await BackupService(
      src,
      srcQueue,
      snapshotDir: () async => Directory('${tmp.path}/src'),
    ).exportJson();
    await srcQueue.close();
    await src.close();
  });

  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  Future<ProviderContainer> launch() async {
    SwipeDeckController.debugResetRestoreNotice();
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        fileSourceProvider.overrideWithValue(files),
        permissionServiceProvider.overrideWithValue(FakePermissionService()),
        mediaChangesProvider.overrideWithValue(const Stream.empty()),
        backupServiceProvider.overrideWith(
          (ref) => BackupService(
            ref.watch(appDatabaseProvider),
            ref.watch(dbWriteQueueProvider),
            snapshotDir: () async => Directory('${tmp.path}/backups'),
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    // The swipe tab stays mounted; nothing watches activePresetIdProvider
    // while Settings is shown.
    c.listen(swipeDeckControllerProvider, (_, _) {});
    await c.read(mediaIndexerProvider).start();
    await c.read(swipeDeckControllerProvider.future);
    return c;
  }

  Future<void> import(ProviderContainer c) async {
    final service = c.read(backupServiceProvider);
    final data = await service.decode(backupJson);
    final switchTo = await service.apply(
      await service.plan(data, importedSuffix: 'imported'),
      applySettings: true,
    );
    await syncSwipeAfterBackup(c, switchTo);
    await c.read(swipeDeckControllerProvider.future);
  }

  Future<void> undo(ProviderContainer c) async {
    await undoImportAndSync(c);
    await c.read(swipeDeckControllerProvider.future);
  }

  Future<int?> activeSessionPreset(ProviderContainer c) async =>
      (await c.read(sessionRepositoryProvider).active())?.presetId;

  Future<int> activeSetting(ProviderContainer c) =>
      c.read(settingsRepositoryProvider).read(AppSettings.activePresetId);

  Future<void> expectBasic(ProviderContainer c) async {
    expect(await db.select(db.presets).get(), isEmpty);
    expect(await activeSetting(c), 0);
    expect(await activeSessionPreset(c), isNull);
  }

  test('import, undo, import, undo: Basic every time', () async {
    final c = await launch();
    expect(await activeSessionPreset(c), isNull);

    await import(c);
    final first = (await db.select(db.presets).getSingle()).id;
    expect(await activeSetting(c), first);
    expect(await activeSessionPreset(c), first);

    await undo(c);
    await expectBasic(c);

    await import(c);
    final second = (await db.select(db.presets).getSingle()).id;
    expect(second, isNot(first));
    expect(await activeSetting(c), second);
    expect(await activeSessionPreset(c), second);

    await undo(c);
    await expectBasic(c);
    // The removed presets' sessions are closed, not left paused.
    final open = await (db.select(
      db.sessions,
    )..where((s) => s.endedAt.isNull())).get();
    expect(open.map((s) => s.presetId), everyElement(isNull));
  });

  test('undo returns to the pre-import preset when it still exists', () async {
    final c = await launch();
    final mine = await c
        .read(presetRepositoryProvider)
        .create(name: 'Mine', layout: SwipeLayout.basic);
    await c.read(activePresetControllerProvider.notifier).switchTo(mine);
    await c.read(swipeDeckControllerProvider.future);
    expect(await activeSessionPreset(c), mine);

    await import(c);
    expect(await activeSessionPreset(c), isNot(mine));
    await undo(c);
    expect(await activeSetting(c), mine);
    expect(await activeSessionPreset(c), mine);
  });

  test('a pre-import preset deleted after the import comes back', () async {
    final c = await launch();
    final mine = await c
        .read(presetRepositoryProvider)
        .create(name: 'Mine', layout: SwipeLayout.basic);
    await c.read(activePresetControllerProvider.notifier).switchTo(mine);
    await import(c);
    await c.read(presetRepositoryProvider).delete(mine);
    await undo(c);
    expect(await activeSetting(c), mine);
    expect(await activeSessionPreset(c), mine);
  });

  test(
    'a deck whose preset was deleted under it falls back to Basic',
    () async {
      final c = await launch();
      final basicSession = (await c.read(sessionRepositoryProvider).active())!;
      final trip = await c
          .read(presetRepositoryProvider)
          .create(name: 'Trip', layout: SwipeLayout.basic);
      await c.read(activePresetControllerProvider.notifier).switchTo(trip);
      await c.read(swipeDeckControllerProvider.future);
      // Removed behind the session machinery's back (the old undo bug).
      await (db.delete(db.presets)..where((p) => p.id.equals(trip))).go();
      c.invalidate(swipeDeckControllerProvider);
      await c.read(swipeDeckControllerProvider.future);
      expect(await activeSetting(c), 0);
      expect(
        (await c.read(sessionRepositoryProvider).active())!.id,
        basicSession.id,
      );
    },
  );
}
