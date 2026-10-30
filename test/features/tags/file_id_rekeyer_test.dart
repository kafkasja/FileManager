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
}
