import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v3.dart' as v3;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('fresh install creates the current schema', () async {
    final db = AppDatabase(DatabaseConnection(await verifier.startAt(1)));
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);
  });

  test('upgrade v1 -> v2 adds media_index and keeps settings rows', () async {
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

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);
    final rows = await db.select(db.settings).get();
    expect(rows.single.value, '"dark"');
    expect(await db.select(db.mediaIndex).get(), isEmpty);
  });

  for (var from = 1; from < 6; from++) {
    test('upgrade v$from -> current validates', () async {
      final db = AppDatabase(DatabaseConnection(await verifier.startAt(from)));
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, db.schemaVersion);
    });
  }

  test('v3 -> v4 keeps sessions; one active session is enforced', () async {
    final schema = await verifier.schemaAt(3);
    final old = v3.DatabaseAtV3(schema.newConnection());
    final now = DateTime.utc(2026);
    await old
        .into(old.sessions)
        .insert(
          v3.SessionsCompanion.insert(
            layout: '{}',
            // Raw column values: drift stores DateTime as epoch seconds.
            startedAt: now.millisecondsSinceEpoch ~/ 1000,
            updatedAt: now.millisecondsSinceEpoch ~/ 1000,
            isActive: 1,
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);
    expect(await db.select(db.sessions).get(), hasLength(1));
    await expectLater(
      db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              layout: '{}',
              startedAt: now,
              updatedAt: now,
              isActive: true,
            ),
          ),
      throwsA(anything),
    );
    final indexes = await db.customSelect('PRAGMA index_list(sessions)').get();
    expect(
      indexes.map((r) => r.read<String>('name')),
      contains('one_active_session'),
    );
  });
}
