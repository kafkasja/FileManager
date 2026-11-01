import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/tables/pending_deletes_table.dart';
import 'package:kfm/core/db/tables/rename_batches_table.dart';
import 'package:kfm/core/db/tables/session_actions_table.dart';
import 'package:kfm/features/tags/data/file_id_rekeyer.dart';

void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late FileIdRekeyer rekeyer;
  late int sessionId;
  final now = DateTime.utc(2026, 10, 29);

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    rekeyer = FileIdRekeyer(db, queue);
    sessionId = await db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            layout: '{}',
            startedAt: now,
            updatedAt: now,
            isActive: true,
          ),
        );
  });

  tearDown(() => db.close());

  Future<int> action(String fileId, int seq, ActionStatus status) => db
      .into(db.sessionActions)
      .insert(
        SessionActionsCompanion.insert(
          sessionId: sessionId,
          seq: seq,
          fileId: fileId,
          actionType: 'trash',
          payload: '{}',
          previousState: '{}',
          status: status,
          createdAt: now,
        ),
      );

  Future<void> pending(int actionId, String fileId, PendingDeleteStatus s) => db
      .into(db.pendingDeletes)
      .insert(
        PendingDeletesCompanion.insert(
          actionId: actionId,
          sessionId: sessionId,
          fileId: fileId,
          mode: 'trash',
          status: s,
          sizeBytes: 1,
          fileModifiedAtMs: 100,
          queuedAt: now,
        ),
      );

  Future<int> batch(RenameBatchStatus status) => db
      .into(db.renameBatches)
      .insert(
        RenameBatchesCompanion.insert(
          sessionId: sessionId,
          status: status,
          createdAt: now,
        ),
      );

  Future<void> item(int batchId, String fileId, int position) => db
      .into(db.renameBatchItems)
      .insert(
        RenameBatchItemsCompanion.insert(
          batchId: batchId,
          fileId: fileId,
          position: position,
          folderPath: '/s/DCIM',
          originalName: '$fileId.jpg',
          currentFileId: fileId,
          currentName: '$fileId.jpg',
        ),
      );

  test('undo log, queued deletes and collecting rename items follow the new '
      'id; committed rows keep theirs', () async {
    final queued = await action('a', 1, ActionStatus.applied);
    await pending(queued, 'a', PendingDeleteStatus.queued);
    final done = await action('a', 2, ActionStatus.committed);
    await pending(done, 'a', PendingDeleteStatus.committed);
    final collecting = await batch(RenameBatchStatus.collecting);
    await item(collecting, 'a', 1);

    await rekeyer.rekey('a', 'b', newModifiedMs: 200);

    final actions = await db.select(db.sessionActions).get();
    expect({for (final a in actions) a.id: a.fileId}, {queued: 'b', done: 'a'});
    final deletes = await db.select(db.pendingDeletes).get();
    final byAction = {for (final d in deletes) d.actionId: d};
    expect(byAction[queued]!.fileId, 'b');
    expect(byAction[queued]!.fileModifiedAtMs, 200);
    expect(byAction[done]!.fileId, 'a');
    expect(byAction[done]!.fileModifiedAtMs, 100);
    final items = await db.select(db.renameBatchItems).get();
    expect(items.single.fileId, 'b');
    expect(items.single.currentFileId, 'b');
  });

  test(
    'a rename item whose new id is already in the batch is merged',
    () async {
      final collecting = await batch(RenameBatchStatus.collecting);
      await item(collecting, 'a', 1);
      await item(collecting, 'b', 2);

      await rekeyer.rekey('a', 'b');

      final items = await db.select(db.renameBatchItems).get();
      expect(items.map((i) => (i.fileId, i.position)), [('b', 2)]);
    },
  );

  test('items of an applying batch keep their stable key', () async {
    final applying = await batch(RenameBatchStatus.applying);
    await item(applying, 'a', 1);

    await rekeyer.rekey('a', 'b');

    expect((await db.select(db.renameBatchItems).get()).single.fileId, 'a');
  });

  test('an id in no table changes nothing', () async {
    final id = await action('x', 1, ActionStatus.applied);
    await rekeyer.rekey('a', 'b');
    await queue.flush();
    final row = await (db.select(
      db.sessionActions,
    )..where((a) => a.id.equals(id))).getSingle();
    expect(row.fileId, 'x');
  });

  test('selection and its snapshot keep the file in place', () async {
    for (final table in ['selection_items', 'selection_snapshots']) {
      await db.customStatement(
        'INSERT INTO $table (file_id, seq, added_at) '
        "VALUES ('a', 7, 1), ('z', 8, 1)",
      );
    }
    await db
        .into(db.favorites)
        .insert(FavoritesCompanion.insert(fileId: 'a', addedAt: now));

    await rekeyer.rekey('a', 'b');

    final items = await db.select(db.selectionItems).get();
    expect({for (final r in items) r.fileId: r.seq}, {'b': 7, 'z': 8});
    final snapshot = await db.select(db.selectionSnapshots).get();
    expect({for (final r in snapshot) r.fileId: r.seq}, {'b': 7, 'z': 8});
    expect((await db.select(db.favorites).get()).single.fileId, 'b');
  });

  test('swipe source items keep their position (SS1)', () async {
    await db.customStatement(
      'INSERT INTO swipe_sources (id, session_id, kind, origin, title, '
      "opened_after_seq, opened_at) VALUES (1, ?, 'files', 'other', 't', 0, 1)",
      [sessionId],
    );
    await db.customStatement(
      'INSERT INTO swipe_source_items (source_id, position, file_id) '
      "VALUES (1, 0, 'z'), (1, 1, 'a'), (1, 2, 'y')",
    );

    await rekeyer.rekey('a', 'b');

    final rows = await (db.select(
      db.swipeSourceItems,
    )..orderBy([(i) => OrderingTerm.asc(i.position)])).get();
    expect(rows.map((r) => r.fileId), ['z', 'b', 'y']);
  });

  test('similar signals, group items and dismissals follow the file (C2)', () async {
    await db.customStatement(
      'INSERT INTO image_signals (file_id, status, d_hash, blur_score, '
      "file_modified_at_ms, algo_version) VALUES ('a', 'ok', 42, 150.0, 5, 1)",
    );
    await db.customStatement(
      'INSERT INTO similar_groups (id, suggested_file_id, member_count, '
      "sort_date_ms, created_at) VALUES (1, 'a', 2, 1, 1), (2, 'b', 2, 1, 1)",
    );
    // Group 2 already holds the new id: the old row is dropped, not doubled.
    await db.customStatement(
      'INSERT INTO similar_group_items (group_id, file_id, position) VALUES '
      "(1, 'a', 0), (1, 'z', 1), (2, 'a', 1), (2, 'b', 0)",
    );
    await db.customStatement(
      'INSERT INTO similar_dismissed (file_id, dismissed_at) '
      "VALUES ('a', 1), ('b', 1)",
    );

    await rekeyer.rekey('a', 'b', newModifiedMs: 9);

    final signal = (await db.select(db.imageSignals).get()).single;
    expect(signal.fileId, 'b');
    expect(signal.dHash, 42);
    expect(signal.fileModifiedAtMs, 9);
    final items = await db.select(db.similarGroupItems).get();
    expect(
      {for (final i in items) '${i.groupId}:${i.fileId}'},
      {'1:b', '1:z', '2:b'},
    );
    final dismissed = await db.select(db.similarDismissed).get();
    expect(dismissed.map((d) => d.fileId), ['b']);
  });

  test(
    'EXIF rows, smart group members and covers follow the file (C5)',
    () async {
      await db.customStatement(
        'INSERT INTO media_locations (file_id, file_modified_at_ms, lat, lng, '
        'front_camera, location_readable, read_at_ms) VALUES '
        "('a', 5, 48.8, 2.3, 1, 1, 77)",
      );
      await db.customStatement(
        'INSERT INTO smart_groups (id, kind, rank, start_at_ms, end_at_ms, '
        "cover_file_id, item_count) VALUES (1, 'trip', 0, 1, 2, 'a', 2), "
        "(2, 'place', 1, 1, 2, 'b', 2)",
      );
      await db.customStatement(
        'INSERT INTO smart_group_items (group_id, file_id) VALUES '
        "(1, 'a'), (1, 'z'), (2, 'a'), (2, 'b')",
      );

      await rekeyer.rekey('a', 'b', newModifiedMs: 9);

      final loc = (await db.select(db.mediaLocations).get()).single;
      expect(loc.fileId, 'b');
      expect(loc.lat, 48.8);
      expect(loc.frontCamera, isTrue);
      // Moved, not edited: the new modified time, the old read time.
      expect(loc.fileModifiedAtMs, 9);
      expect(loc.readAtMs, 77);
      final items = await db.select(db.smartGroupItems).get();
      expect(
        {for (final i in items) '${i.groupId}:${i.fileId}'},
        {'1:b', '1:z', '2:b'},
      );
      final groups = await (db.select(
        db.smartGroups,
      )..orderBy([(g) => OrderingTerm.asc(g.id)])).get();
      expect(groups.map((g) => g.coverFileId), ['b', 'b']);
    },
  );
}
