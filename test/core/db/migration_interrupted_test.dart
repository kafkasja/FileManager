import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v20.dart' as v20;

/// The app is killed in the middle of a schema upgrade (Q5): every step of
/// `onUpgrade` ran, the process dies before the upgrade commits.
class _KilledMidUpgrade extends AppDatabase {
  new(super.executor, {required this.stepsBeforeKill});

  /// How many `Migrator` calls run before the "kill".
  final int stepsBeforeKill;

  @override
  MigrationStrategy get migration {
    final real = super.migration;
    return MigrationStrategy(
      onCreate: real.onCreate,
      onUpgrade: (m, from, to) async {
        var steps = 0;
        final counting = _CountingMigrator(this, () {
          if (++steps > stepsBeforeKill) throw const _Killed();
        });
        await real.onUpgrade(counting, from, to);
        throw const _Killed();
      },
      beforeOpen: real.beforeOpen,
    );
  }
}

class _Killed implements Exception {
  const new();
}

/// A real [Migrator] that calls [_tick] before each DDL step.
class _CountingMigrator extends Migrator {
  new(super.database, this._tick);

  final void Function() _tick;

  @override
  Future<void> createTable(TableInfo<Table, dynamic> table) {
    _tick();
    return super.createTable(table);
  }

  @override
  Future<void> createIndex(Index index) {
    _tick();
    return super.createIndex(index);
  }

  @override
  Future<void> addColumn(
    TableInfo<Table, dynamic> table,
    GeneratedColumn column,
  ) {
    _tick();
    return super.addColumn(table, column);
  }
}

void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  for (final steps in [0, 1, 3, 10, 1000]) {
    test('killed after $steps upgrade steps (v1): the next start upgrades '
        'cleanly and keeps the data', () async {
      final schema = await verifier.schemaAt(1);
      final old = v1.DatabaseAtV1(schema.newConnection());
      await old
          .into(old.settings)
          .insert(
            const v1.SettingsCompanion(
              key: Value('themeMode'),
              value: Value('"dark"'),
            ),
          );
      await old.close();

      final dying = _KilledMidUpgrade(
        schema.newConnection(),
        stepsBeforeKill: steps,
      );
      await expectLater(
        dying.customSelect('SELECT 1').get(),
        throwsA(anything),
      );
      await dying.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, db.schemaVersion);
      final rows = await db.select(db.settings).get();
      expect(rows.single.value, '"dark"');
    });
  }

  test(
    'killed mid-upgrade from v20 on a real file (WAL): next start ok',
    () async {
      final dir = Directory.systemTemp.createTempSync('kfm_mig_kill');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/kfm.sqlite');
      final schema = await verifier.schemaAt(20);
      // Copy the v20 schema into a real file database.
      final seed = v20.DatabaseAtV20(schema.newConnection());
      await seed.customStatement(
        "VACUUM INTO '${file.path.replaceAll("'", "''")}'",
      );
      await seed.close();
      final onDisk = v20.DatabaseAtV20(NativeDatabase(file));
      await onDisk.customStatement(
        "INSERT INTO settings(key, value) VALUES ('themeMode', '\"dark\"')",
      );
      await onDisk.customStatement('PRAGMA user_version = 20');
      await onDisk.close();

      final dying = _KilledMidUpgrade(
        NativeDatabase(file, setup: AppDatabase.setupConnection),
        stepsBeforeKill: 2,
      );
      await expectLater(
        dying.customSelect('SELECT 1').get(),
        throwsA(anything),
      );
      await dying.close();

      final db = AppDatabase(
        NativeDatabase(file, setup: AppDatabase.setupConnection),
      );
      addTearDown(db.close);
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), db.schemaVersion);
      final rows = await db.select(db.settings).get();
      expect(rows.single.value, '"dark"');
    },
  );
}
