import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v11.dart' as v11;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v6.dart' as v6;
import 'generated/schema_v7.dart' as v7;
import 'generated/schema_v8.dart' as v8;
import 'generated/schema_v9.dart' as v9;

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
    await verifier.migrateAndValidate(db, db.schemaVersion);
    final rows = await db.select(db.settings).get();
    expect(rows.single.value, '"dark"');
    expect(await db.select(db.mediaIndex).get(), isEmpty);
  });

  for (var from = 1; from < 12; from++) {
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

  test('v6 -> v7 adds tags/favorites and keeps sessions + actions', () async {
    final schema = await verifier.schemaAt(6);
    final raw = v6.DatabaseAtV6(schema.newConnection());
    await raw.customStatement(
      'INSERT INTO sessions (layout, started_at, updated_at, is_active) '
      "VALUES ('{}', 1767225600, 1767225600, 1)",
    );
    await raw.customStatement(
      'INSERT INTO session_actions (session_id, seq, file_id, action_type, '
      "payload, previous_state, status, created_at) VALUES (1, 1, 'ms:1', "
      """'keep', '{}', '{"type":"keep"}', 'applied', 1767225600)""",
    );
    await raw.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);
    expect(await db.select(db.sessions).get(), hasLength(1));
    final actions = await db.select(db.sessionActions).get();
    expect(actions.single.fileId, 'ms:1');
    expect(await db.select(db.tags).get(), isEmpty);
    expect(await db.select(db.favorites).get(), isEmpty);
  });

  test('v7 -> v8 adds rename batches and keeps tags + sessions', () async {
    final schema = await verifier.schemaAt(7);
    final raw = v7.DatabaseAtV7(schema.newConnection());
    await raw.customStatement(
      'INSERT INTO sessions (layout, started_at, updated_at, is_active) '
      "VALUES ('{}', 1767225600, 1767225600, 1)",
    );
    await raw.customStatement(
      'INSERT INTO tags (name, color, created_at) '
      "VALUES ('Cats', 4282339765, 1767225600)",
    );
    await raw.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);
    expect(await db.select(db.sessions).get(), hasLength(1));
    expect((await db.select(db.tags).get()).single.name, 'Cats');
    expect(await db.select(db.renameBatches).get(), isEmpty);
  });

  test('v8 -> v9 backfills screenshot; other tables untouched', () async {
    final schema = await verifier.schemaAt(8);
    final raw = v8.DatabaseAtV8(schema.newConnection());
    for (final (id, folder, name, kind) in [
      ('a', '/s/Pictures/Screenshots', 'x.png', 0),
      ('b', '/s/DCIM/Camera', 'y.jpg', 0),
      ('c', '/s/Download', 'Screenshot_1.png', 0),
      ('d', '/s/DCIM/Screenshots', 'v.mp4', 1),
    ]) {
      await raw.customStatement(
        'INSERT INTO media_index (id, uri, name, name_lower, kind, size_bytes, '
        'modified_at_ms, sort_date_ms, folder_path, origin, indexed_at_ms, '
        "scan_generation) VALUES ('$id', 'u', '$name', '${name.toLowerCase()}', "
        "$kind, 1, 1, 1, '$folder', 0, 1, 1)",
      );
    }
    await raw.customStatement(
      "INSERT INTO tags (name, color, created_at) VALUES ('T', 1, 1)",
    );
    await raw.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);
    final rows = {
      for (final r in await db.select(db.mediaIndex).get()) r.id: r.screenshot,
    };
    expect(rows, {'a': true, 'b': false, 'c': true, 'd': false});
    expect(await db.select(db.tags).get(), hasLength(1));
  });

  test(
    'v9 -> v10: inactive sessions are ended, the active one stays open',
    () async {
      final schema = await verifier.schemaAt(9);
      final raw = v9.DatabaseAtV9(schema.newConnection());
      for (final active in [0, 0, 1]) {
        await raw.customStatement(
          'INSERT INTO sessions (layout, started_at, updated_at, is_active) '
          "VALUES ('{}', 1767225600, 1767229200, $active)",
        );
      }
      await raw.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, db.schemaVersion);
      final rows = await db.select(db.sessions).get();
      expect(rows.where((r) => r.endedAt != null), hasLength(2));
      expect(rows.singleWhere((r) => r.isActive).endedAt, equals(null));
      expect(await db.select(db.presets).get(), isEmpty);
    },
  );

  test('v11 -> v12 backfills trash_id of committed trash rows', () async {
    final schema = await verifier.schemaAt(11);
    final raw = v11.DatabaseAtV11(schema.newConnection());
    await raw.customStatement(
      'INSERT INTO sessions (layout, started_at, updated_at, is_active) '
      "VALUES ('{}', 1, 1, 1)",
    );
    await raw.customStatement(
      'INSERT INTO session_actions (session_id, seq, file_id, action_type, '
      "payload, previous_state, status, created_at) VALUES (1, 1, 'ms:1', "
      """'trash', '{}', '{"mode":"trash","trashedItem":{"trashId":"ms:1"}}', """
      "'committed', 1)",
    );
    await raw.customStatement(
      'INSERT INTO pending_deletes (action_id, session_id, file_id, mode, '
      'status, size_bytes, file_modified_at_ms, committed_mode, queued_at) '
      "VALUES (1, 1, 'ms:1', 'trash', 'committed', 10, 1, 'trash', 1)",
    );
    await raw.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);
    final row = (await db.select(db.pendingDeletes).get()).single;
    expect(row.trashId, 'ms:1');
    expect(row.leftTrashAt, equals(null));
  });
}
