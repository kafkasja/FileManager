import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_startup_check.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Q6: the database file is damaged, missing its WAL or locked at start.
void main() {
  late Directory dir;
  late File dbFile;
  final at = DateTime.utc(2026, 11, 4, 12, 30, 15, 7);

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    dir = await Directory.systemTemp.createTemp('kfm_startup_check');
    dbFile = File('${dir.path}/kfm.sqlite');
  });

  tearDown(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
    await dir.delete(recursive: true);
  });

  AppDatabase open() =>
      AppDatabase(NativeDatabase(dbFile, setup: AppDatabase.setupConnection));

  /// A real KFM database with some rows, closed.
  Future<void> seed({int rows = 500}) async {
    final db = open();
    await db.transaction(() async {
      for (var i = 0; i < rows; i++) {
        await db.customStatement(
          "INSERT INTO settings(key, value) VALUES ('k$i', '${'x' * 300}')",
        );
      }
    });
    await db.close();
  }

  Future<String> themeAfterReopen() async {
    final db = open();
    final queue = DbWriteQueue();
    try {
      final repo = SettingsRepository(db, queue);
      await repo.write(AppSettings.themeMode, 'dark');
      return await repo.read(AppSettings.themeMode);
    } finally {
      await queue.close();
      await db.close();
    }
  }

  List<String> names() =>
      [for (final e in dir.listSync()) p.basename(e.path)]..sort();

  test('no database yet: ok, nothing created', () async {
    final r = await checkDatabaseFile(dbFile, now: () => at);
    expect(r.state, DbStartupState.ok, reason: r.detail);
    expect(dir.listSync(), isEmpty);
  });

  test('a healthy database (with its WAL) is left alone', () async {
    await seed();
    // Keep a connection open so the WAL still holds committed pages.
    final raw = sqlite3.open(dbFile.path)
      ..execute("INSERT INTO settings(key, value) VALUES ('wal', '1')");
    final before = dbFile.lengthSync();
    final r = await checkDatabaseFile(dbFile, now: () => at);
    raw.close();
    expect(r.state, DbStartupState.ok, reason: r.detail);
    expect(dbFile.lengthSync(), greaterThanOrEqualTo(before));
    final db = open();
    addTearDown(db.close);
    final n = await db
        .customSelect('SELECT count(*) AS c FROM settings')
        .getSingle();
    expect(n.read<int>('c'), 501);
  });

  test('a zero-byte file is an empty database (ok)', () async {
    dbFile.writeAsBytesSync(const []);
    final r = await checkDatabaseFile(dbFile, now: () => at);
    expect(r.state, DbStartupState.ok, reason: r.detail);
    expect(await themeAfterReopen(), 'dark');
  });

  test('garbage file: moved aside with its WAL/SHM, fresh db works', () async {
    await seed();
    final len = dbFile.lengthSync();
    final rnd = Random(7);
    dbFile.writeAsBytesSync(List.generate(len, (_) => rnd.nextInt(256)));
    File('${dbFile.path}-wal').writeAsBytesSync(List.filled(5000, 3));
    File('${dbFile.path}-shm').writeAsBytesSync(List.filled(32768, 1));

    final r = await checkDatabaseFile(dbFile, now: () => at);
    expect(r.state, DbStartupState.reset, reason: r.detail);
    expect(r.backupName, 'kfm.sqlite.broken-20261104-123015-007');
    expect(names(), [
      'kfm.sqlite-shm.broken-20261104-123015-007',
      'kfm.sqlite-wal.broken-20261104-123015-007',
      'kfm.sqlite.broken-20261104-123015-007',
    ]);
    // The damaged bytes are kept as they were.
    expect(
      File('${dir.path}/kfm.sqlite.broken-20261104-123015-007').lengthSync(),
      len,
    );
    expect(await themeAfterReopen(), 'dark');
    // A second start finds the new database healthy.
    final again = await checkDatabaseFile(dbFile, now: () => at);
    expect(again.state, DbStartupState.ok);
  });

  test('truncated file (half its pages): reset', () async {
    await seed(rows: 3000);
    final bytes = dbFile.readAsBytesSync();
    dbFile.writeAsBytesSync(bytes.sublist(0, bytes.length ~/ 2));
    final r = await checkDatabaseFile(dbFile, now: () => at);
    expect(r.state, DbStartupState.reset, reason: r.detail);
    expect(await themeAfterReopen(), 'dark');
  });

  test('header smashed (first page zeroed past the magic): reset', () async {
    await seed();
    final bytes = dbFile.readAsBytesSync();
    for (var i = 0; i < 100; i++) {
      bytes[i] = 0;
    }
    dbFile.writeAsBytesSync(bytes);
    final r = await checkDatabaseFile(dbFile, now: () => at);
    expect(r.state, DbStartupState.reset, reason: r.detail);
  });

  test('a WAL without its database is moved aside (never replayed)', () async {
    File('${dbFile.path}-wal').writeAsBytesSync(List.filled(4096, 9));
    final r = await checkDatabaseFile(dbFile, now: () => at);
    expect(r.state, DbStartupState.reset, reason: r.detail);
    expect(File('${dbFile.path}-wal').existsSync(), isFalse);
    expect(await themeAfterReopen(), 'dark');
  });

  test('WAL deleted while the app was down: ok, committed data kept', () async {
    await seed();
    File('${dbFile.path}-wal').deleteIfExists();
    final r = await checkDatabaseFile(dbFile, now: () => at);
    expect(r.state, DbStartupState.ok, reason: r.detail);
    expect(await themeAfterReopen(), 'dark');
  });

  test(
    'locked by another process mid-write: not moved, still readable',
    () async {
      await seed();
      final other = sqlite3.open(dbFile.path)
        ..execute('PRAGMA journal_mode = WAL')
        ..execute('BEGIN EXCLUSIVE')
        ..execute("INSERT INTO settings(key, value) VALUES ('lock', '1')");
      addTearDown(other.close);
      final r = await checkDatabaseFile(dbFile, now: () => at);
      expect(r.state, DbStartupState.ok, reason: r.detail);
      expect(names(), contains('kfm.sqlite'));
      expect(names().where((n) => n.contains('broken')), isEmpty);
      other.execute('ROLLBACK');
    },
  );

  test('a path that cannot be opened is unavailable, never moved', () async {
    Directory(dbFile.path).createSync(); // a folder named kfm.sqlite
    final r = await checkDatabaseFile(dbFile, now: () => at);
    expect(r.state, DbStartupState.unavailable, reason: r.detail);
    expect(Directory(dbFile.path).existsSync(), isTrue);
    expect(names(), ['kfm.sqlite']);
  });

  test(
    'only the newest $kBrokenDbCopiesKept damaged copies are kept',
    () async {
      for (var i = 0; i < 4; i++) {
        dbFile.writeAsStringSync('not a database $i ${'z' * 200}');
        File('${dbFile.path}-wal').writeAsStringSync('w$i');
        final r = await checkDatabaseFile(
          dbFile,
          now: () => at.add(Duration(minutes: i)),
        );
        expect(r.state, DbStartupState.reset, reason: r.detail);
      }
      // (The read-only probe may add an -shm file; it is moved along.)
      expect(names().where((n) => !n.contains('-shm')), [
        'kfm.sqlite-wal.broken-20261104-123215-007',
        'kfm.sqlite-wal.broken-20261104-123315-007',
        'kfm.sqlite.broken-20261104-123215-007',
        'kfm.sqlite.broken-20261104-123315-007',
      ]);
    },
  );

  test('other files in the folder are never touched', () async {
    final photo = File('${dir.path}/IMG_0001.jpg')..writeAsBytesSync([1, 2]);
    dbFile.writeAsStringSync('garbage');
    await checkDatabaseFile(dbFile, now: () => at);
    expect(photo.readAsBytesSync(), [1, 2]);
  });
}

extension on File {
  void deleteIfExists() {
    if (existsSync()) deleteSync();
  }
}
