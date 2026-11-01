import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/index/source_rule.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v11.dart' as v11;
import 'generated/schema_v12.dart' as v12;
import 'generated/schema_v13.dart' as v13;
import 'generated/schema_v14.dart' as v14;
import 'generated/schema_v15.dart' as v15;
import 'generated/schema_v16.dart' as v16;
import 'generated/schema_v17.dart' as v17;
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

  for (var from = 1; from < 18; from++) {
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

  test('v12 -> v13 backfills source and extension; hidden = 0', () async {
    final schema = await verifier.schemaAt(12);
    final raw = v12.DatabaseAtV12(schema.newConnection());
    for (final (id, folder, name, kind) in [
      (
        'a',
        '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/'
            'WhatsApp Images',
        'IMG-1.jpg',
        0,
      ),
      ('b', '/storage/emulated/0/Download', 'a.PDF', 3),
      ('c', '/storage/emulated/0/DCIM/Camera', 'x.jpg', 0),
      ('d', '/storage/emulated/0/DCIM/Tapo', 'noext', 0),
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
      for (final r in await db.select(db.mediaIndex).get())
        r.id: (r.source, r.extension, r.hidden),
    };
    expect(rows, {
      'a': (SourceBucket.whatsapp, 'jpg', false),
      'b': (SourceBucket.downloads, 'pdf', false),
      'c': (SourceBucket.camera, 'jpg', false),
      'd': (SourceBucket.none, '', false),
    });
    expect(await db.select(db.tags).get(), hasLength(1));
  });

  test('v13 -> v14 adds empty selection tables; data intact', () async {
    final schema = await verifier.schemaAt(13);
    final raw = v13.DatabaseAtV13(schema.newConnection());
    await raw.customStatement(
      'INSERT INTO media_index (id, uri, name, name_lower, kind, size_bytes, '
      'modified_at_ms, sort_date_ms, folder_path, origin, indexed_at_ms, '
      "scan_generation, source, hidden, extension) VALUES ('a', 'u', 'x.jpg', "
      "'x.jpg', 0, 1, 1, 1, '/s/DCIM', 0, 1, 1, 0, 0, 'jpg')",
    );
    await raw.customStatement(
      "INSERT INTO favorites (file_id, added_at) VALUES ('a', 1)",
    );
    await raw.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);
    expect(await db.select(db.mediaIndex).get(), hasLength(1));
    expect(await db.select(db.favorites).get(), hasLength(1));
    expect(await db.select(db.selectionItems).get(), isEmpty);
    expect(await db.select(db.selectionSnapshots).get(), isEmpty);
  });

  test('v14 -> v15 adds empty swipe source tables; data intact', () async {
    final schema = await verifier.schemaAt(14);
    final raw = v14.DatabaseAtV14(schema.newConnection());
    await raw.customStatement(
      'INSERT INTO sessions (id, layout, delete_mode, cursor, started_at, '
      "updated_at, is_active) VALUES (1, '{}', 'trash', 3, 1, 1, 1)",
    );
    await raw.customStatement(
      'INSERT INTO session_actions (session_id, seq, file_id, action_type, '
      "payload, previous_state, status, created_at) VALUES (1, 1, 'a', "
      "'trash', '{}', '{}', 'applied', 1)",
    );
    await raw.customStatement(
      'INSERT INTO pending_deletes (action_id, file_id, session_id, mode, '
      'status, size_bytes, file_modified_at_ms, queued_at) '
      "VALUES (1, 'a', 1, 'trash', 'queued', 5, 1, 1)",
    );
    await raw.customStatement(
      "INSERT INTO selection_items (file_id, seq, added_at) VALUES ('a', 1, 1)",
    );
    await raw.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);
    expect((await db.select(db.sessions).getSingle()).cursor, 3);
    expect(await db.select(db.sessionActions).get(), hasLength(1));
    expect(await db.select(db.pendingDeletes).get(), hasLength(1));
    expect(await db.select(db.selectionItems).get(), hasLength(1));
    expect(await db.select(db.swipeSources).get(), isEmpty);
    expect(await db.select(db.swipeSourceItems).get(), isEmpty);
  });

  group('swipe_sources constraints (v15)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(DatabaseConnection(await verifier.startAt(14)));
      await verifier.migrateAndValidate(db, db.schemaVersion);
      await db.customStatement(
        'INSERT INTO sessions (id, layout, delete_mode, cursor, started_at, '
        "updated_at, is_active) VALUES (1, '{}', 'trash', 0, 1, 1, 1)",
      );
    });
    tearDown(() => db.close());

    Future<void> insert({
      String kind = 'files',
      String? filterJson,
      int? groupCount,
      int? closedAtSeq,
      int? closedAt,
    }) => db.customStatement(
      'INSERT INTO swipe_sources (session_id, kind, origin, title, '
      'filter_json, group_count, opened_after_seq, closed_at_seq, opened_at, '
      "closed_at) VALUES (1, ?, 'other', 't', ?, ?, 0, ?, 1, ?)",
      [kind, filterJson, groupCount, closedAtSeq, closedAt],
    );

    test('a second open source per session is rejected', () async {
      await insert();
      await expectLater(insert(), throwsA(anything));
      // Closed rows don't count.
      await insert(closedAtSeq: 0, closedAt: 2);
      expect(await db.select(db.swipeSources).get(), hasLength(2));
    });

    test('an open outside row is rejected; a closed one is fine', () async {
      await expectLater(insert(kind: 'outside'), throwsA(anything));
      await insert(kind: 'outside', closedAtSeq: 0, closedAt: 2);
    });

    test('a filter row needs filter_json, others must not have it', () async {
      await expectLater(insert(kind: 'filter'), throwsA(anything));
      await expectLater(insert(filterJson: '{}'), throwsA(anything));
      await insert(kind: 'filter', filterJson: '{}');
    });

    test('group_count only for groups; closed_at pairs with seq', () async {
      await expectLater(insert(kind: 'groups'), throwsA(anything));
      await expectLater(insert(closedAt: 2), throwsA(anything));
      await insert(kind: 'groups', groupCount: 2);
    });
  });

  test('v15 -> v16 adds empty similar tables; data intact', () async {
    final schema = await verifier.schemaAt(15);
    final raw = v15.DatabaseAtV15(schema.newConnection());
    await raw.customStatement(
      'INSERT INTO sessions (id, layout, delete_mode, cursor, started_at, '
      "updated_at, is_active) VALUES (1, '{}', 'trash', 3, 1, 1, 1)",
    );
    await raw.customStatement(
      'INSERT INTO swipe_sources (session_id, kind, origin, title, '
      "opened_after_seq, opened_at) VALUES (1, 'files', 'other', 't', 0, 1)",
    );
    await raw.customStatement(
      'INSERT INTO swipe_source_items (source_id, position, file_id) '
      "VALUES (1, 0, 'a')",
    );
    await raw.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);
    expect((await db.select(db.sessions).getSingle()).cursor, 3);
    expect(await db.select(db.swipeSources).get(), hasLength(1));
    expect(await db.select(db.swipeSourceItems).get(), hasLength(1));
    expect(await db.select(db.imageSignals).get(), isEmpty);
    expect(await db.select(db.similarGroups).get(), isEmpty);
    expect(await db.select(db.similarGroupItems).get(), isEmpty);
    expect(await db.select(db.similarDismissed).get(), isEmpty);
  });

  group('image_signals constraints (v16)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(DatabaseConnection(await verifier.startAt(15)));
      await verifier.migrateAndValidate(db, db.schemaVersion);
    });
    tearDown(() => db.close());

    Future<void> insert(String id, String status, int? hash, double? blur) =>
        db.customStatement(
          'INSERT INTO image_signals (file_id, status, d_hash, blur_score, '
          'file_modified_at_ms, algo_version) VALUES (?, ?, ?, ?, 1, 1)',
          [id, status, hash, blur],
        );

    test(
      'ok needs a hash and a blur score; failed must not have them',
      () async {
        await expectLater(insert('a', 'ok', null, 1), throwsA(anything));
        await expectLater(insert('b', 'ok', 1, null), throwsA(anything));
        await expectLater(insert('c', 'failed', 1, 1), throwsA(anything));
        await insert('d', 'ok', -5, 12.5);
        await insert('e', 'failed', null, null);
        await insert('f', 'unsupported', null, null);
        expect(await db.select(db.imageSignals).get(), hasLength(3));
      },
    );

    test('deleting a group cascades to its items', () async {
      await db.customStatement(
        'INSERT INTO similar_groups (id, suggested_file_id, member_count, '
        "sort_date_ms, created_at) VALUES (1, 'a', 2, 1, 1)",
      );
      await db.customStatement(
        'INSERT INTO similar_group_items (group_id, file_id, position) '
        "VALUES (1, 'a', 0), (1, 'b', 1)",
      );
      await db.customStatement('DELETE FROM similar_groups');
      expect(await db.select(db.similarGroupItems).get(), isEmpty);
    });
  });

  test('v16 -> v17 adds empty smart group tables; data intact', () async {
    final schema = await verifier.schemaAt(16);
    final raw = v16.DatabaseAtV16(schema.newConnection());
    await raw.customStatement(
      'INSERT INTO image_signals (file_id, status, d_hash, blur_score, '
      "file_modified_at_ms, algo_version) VALUES ('a', 'ok', 1, 2.5, 1, 1)",
    );
    await raw.customStatement(
      'INSERT INTO similar_groups (id, suggested_file_id, member_count, '
      "sort_date_ms, created_at) VALUES (1, 'a', 2, 1, 1)",
    );
    await raw.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);
    expect(await db.select(db.imageSignals).get(), hasLength(1));
    expect(await db.select(db.similarGroups).get(), hasLength(1));
    expect(await db.select(db.mediaLocations).get(), isEmpty);
    expect(await db.select(db.smartGroups).get(), isEmpty);
    expect(await db.select(db.smartGroupItems).get(), isEmpty);
  });

  group('smart group constraints (v17)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(DatabaseConnection(await verifier.startAt(16)));
      await verifier.migrateAndValidate(db, db.schemaVersion);
    });
    tearDown(() => db.close());

    Future<void> location(String id, double? lat, double? lng) =>
        db.customStatement(
          'INSERT INTO media_locations (file_id, file_modified_at_ms, lat, '
          'lng, front_camera, location_readable, read_at_ms) '
          'VALUES (?, 1, ?, ?, 0, 1, 1)',
          [id, lat, lng],
        );

    test('lat/lng are both set or both null, and in range', () async {
      await expectLater(location('a', 1, null), throwsA(anything));
      await expectLater(location('b', 91, 0), throwsA(anything));
      await expectLater(location('c', 0, 181), throwsA(anything));
      await location('d', null, null);
      await location('e', 52.1, 4.3);
      expect(await db.select(db.mediaLocations).get(), hasLength(2));
    });

    test('end >= start; deleting a group cascades to its items', () async {
      await expectLater(
        db.customStatement(
          'INSERT INTO smart_groups (kind, rank, start_at_ms, end_at_ms, '
          "cover_file_id, item_count) VALUES ('trip', 0, 5, 1, 'a', 1)",
        ),
        throwsA(anything),
      );
      await db.customStatement(
        'INSERT INTO smart_groups (id, kind, rank, start_at_ms, end_at_ms, '
        "cover_file_id, item_count) VALUES (1, 'place', 1, 1, 5, 'a', 2)",
      );
      await db.customStatement(
        'INSERT INTO smart_group_items (group_id, file_id) '
        "VALUES (1, 'a'), (1, 'b')",
      );
      await db.customStatement('DELETE FROM smart_groups');
      expect(await db.select(db.smartGroupItems).get(), isEmpty);
    });
  });

  test('v17 -> v18 adds empty AI label tables; data intact', () async {
    final schema = await verifier.schemaAt(17);
    final raw = v17.DatabaseAtV17(schema.newConnection());
    await raw.customStatement(
      'INSERT INTO media_locations (file_id, file_modified_at_ms, '
      "front_camera, location_readable, read_at_ms) VALUES ('a', 1, 0, 1, 1)",
    );
    await raw.customStatement(
      'INSERT INTO image_signals (file_id, status, d_hash, blur_score, '
      "file_modified_at_ms, algo_version) VALUES ('a', 'ok', 1, 2.5, 1, 1)",
    );
    await raw.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);
    expect(await db.select(db.mediaLocations).get(), hasLength(1));
    expect(await db.select(db.imageSignals).get(), hasLength(1));
    expect(await db.select(db.aiLabels).get(), isEmpty);
    expect(await db.select(db.aiLabelStatus).get(), isEmpty);
    final indexes = await db.customSelect('PRAGMA index_list(ai_labels)').get();
    expect(
      indexes.map((r) => r.read<String>('name')),
      contains('ai_labels_label'),
    );
  });

  group('AI label constraints (v18)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(DatabaseConnection(await verifier.startAt(17)));
      await verifier.migrateAndValidate(db, db.schemaVersion);
    });
    tearDown(() => db.close());

    Future<void> label(String id, String label, double confidence) =>
        db.customStatement(
          'INSERT INTO ai_labels (file_id, label, confidence) VALUES (?, ?, ?)',
          [id, label, confidence],
        );

    test(
      'confidence is 0..1, label is 1..64 chars, one row per label',
      () async {
        await expectLater(label('a', 'cat', 1.5), throwsA(anything));
        await expectLater(label('a', 'cat', -0.1), throwsA(anything));
        // Length is drift's (Dart-side) validation.
        for (final bad in ['', 'x' * 65]) {
          await expectLater(
            db
                .into(db.aiLabels)
                .insert(
                  AiLabelsCompanion.insert(
                    fileId: 'a',
                    label: bad,
                    confidence: 0.5,
                  ),
                ),
            throwsA(anything),
          );
        }
        await label('a', 'cat', 0.9);
        await expectLater(label('a', 'cat', 0.8), throwsA(anything));
        await label('a', 'color:blue', 0);
        expect(await db.select(db.aiLabels).get(), hasLength(2));
      },
    );

    test('one status row per file; attempts defaults to 1', () async {
      await db.customStatement(
        'INSERT INTO ai_label_status (file_id, outcome, model_version, '
        "file_modified_at_ms, processed_at_ms) VALUES ('a', 'failed', 1, 5, 9)",
      );
      final row = await db.select(db.aiLabelStatus).getSingle();
      expect(row.attempts, 1);
      expect(row.outcome.name, 'failed');
      await expectLater(
        db.customStatement(
          'INSERT INTO ai_label_status (file_id, outcome, model_version, '
          "file_modified_at_ms, processed_at_ms) VALUES ('a', 'labeled', 1, 5, 9)",
        ),
        throwsA(anything),
      );
    });
  });
}
