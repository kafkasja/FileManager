import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/setting_key.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';

enum _Fruit { apple, pear }

void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late SettingsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    repo = SettingsRepository(db, queue);
  });

  tearDown(() async {
    await queue.close();
    await db.close();
  });

  test('missing setting returns its default', () async {
    expect(await repo.read(AppSettings.themeMode), 'system');
    expect(await repo.read(AppSettings.pendingFolderRetentionDays), 7);
  });

  test('round-trips every key type', () async {
    final flag = SettingKey.boolean('flag', defaultValue: false);
    final count = SettingKey.integer('count', 1);
    final text = SettingKey.string('text', 'a');
    final fruit = SettingKey.enumeration('fruit', _Fruit.apple, _Fruit.values);

    await repo.write(flag, true);
    await repo.write(count, 42);
    await repo.write(text, 'héllo "quoted"');
    await repo.write(fruit, _Fruit.pear);

    expect(await repo.read(flag), isTrue);
    expect(await repo.read(count), 42);
    expect(await repo.read(text), 'héllo "quoted"');
    expect(await repo.read(fruit), _Fruit.pear);
  });

  test('corrupt JSON returns the default without throwing', () async {
    await db
        .into(db.settings)
        .insert(
          SettingsCompanion.insert(
            key: AppSettings.themeMode.name,
            value: 'not json',
          ),
        );
    expect(await repo.read(AppSettings.themeMode), 'system');
  });

  test('wrong JSON type returns the default', () async {
    await db
        .into(db.settings)
        .insert(
          SettingsCompanion.insert(
            key: AppSettings.pendingFolderRetentionDays.name,
            value: '"seven"',
          ),
        );
    expect(await repo.read(AppSettings.pendingFolderRetentionDays), 7);
  });

  test('watch emits the new value after a write', () async {
    final values = repo.watch(AppSettings.themeMode);
    final expectation = expectLater(values, emitsInOrder(['system', 'dark']));
    await Future<void>.delayed(Duration.zero);
    await repo.write(AppSettings.themeMode, 'dark');
    await expectation;
  });

  test('reset brings back the default', () async {
    await repo.write(AppSettings.sameTimeWindowSeconds, 30);
    await repo.reset(AppSettings.sameTimeWindowSeconds);
    expect(await repo.read(AppSettings.sameTimeWindowSeconds), 5);
  });

  test('foreign keys are on and journal mode is readable', () async {
    final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(fk.read<int>('foreign_keys'), 1);
    final sync = await db.customSelect('PRAGMA synchronous').getSingle();
    expect(sync.read<int>('synchronous'), 2, reason: 'FULL (V1 bug 4)');
    // In-memory databases report "memory"; on disk F2 sets WAL.
    expect(await db.journalMode(), 'memory');
  });

  group('on disk', () {
    late Directory dir;

    AppDatabase openFileDb() => AppDatabase(
      NativeDatabase(
        File('${dir.path}/kfm.sqlite'),
        setup: AppDatabase.setupConnection,
      ),
    );

    setUp(() async {
      // The in-memory db from the outer setUp is a separate database.
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      dir = await Directory.systemTemp.createTemp('kfm_db_test');
    });

    tearDown(() async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
      await dir.delete(recursive: true);
    });

    test('opens in WAL mode', () async {
      final fileDb = openFileDb();
      addTearDown(fileDb.close);
      expect(await fileDb.journalMode(), 'wal');
    });

    test('a written setting survives closing and reopening', () async {
      final first = openFileDb();
      final firstQueue = DbWriteQueue();
      await SettingsRepository(
        first,
        firstQueue,
      ).write(AppSettings.themeMode, 'dark');
      await firstQueue.close();
      await first.close();

      final second = openFileDb();
      addTearDown(second.close);
      final reopened = SettingsRepository(second, DbWriteQueue());
      expect(await reopened.read(AppSettings.themeMode), 'dark');
    });
  });
}
