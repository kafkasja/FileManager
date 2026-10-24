import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/db/tables/pending_deletes_table.dart';
import 'package:kfm/core/db/tables/session_actions_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/session/data/session_repository.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/swipe/data/swipe_action_dispatcher.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/trash/data/delete_queue.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/domain/undo_service.dart';

import '../core/files/fake_file_source.dart';

/// Fake whose trash can be told to fail like the system dialog would.
class _TrashFake extends FakeFileSource {
  bool cancelTrash = false;
  int trashCalls = 0;

  @override
  Future<TrashResult> trashBatch(List<FileRef> files) async {
    trashCalls++;
    if (cancelTrash) {
      return const TrashResult(trashed: [], failed: {}, userCancelled: true);
    }
    return await super.trashBatch(files);
  }
}

void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late SessionRepository sessions;
  late UndoRepository undo;
  late DeleteQueue deletes;
  late UndoService undoService;
  late SwipeActionDispatcher dispatcher;
  late _TrashFake source;
  late MediaIndexDao index;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    sessions = SessionRepository(db, queue);
    undo = UndoRepository(db, queue);
    source = _TrashFake();
    index = MediaIndexDao(db);
    final lock = SerialLock();
    deletes = DeleteQueue(
      db: db,
      lock: lock,
      source: source,
      undo: undo,
      index: index,
    );
    undoService = UndoService(
      repo: undo,
      deletes: deletes,
      source: source,
      lock: lock,
      queue: queue,
    );
    dispatcher = SwipeActionDispatcher(undo, deletes);
  });

  tearDown(() async {
    await deletes.dispose();
    await queue.close();
    await db.close();
  });

  Future<Session> start({DeleteMode? mode}) async {
    final s = await sessions.getOrCreateActive(deleteMode: mode);
    await undo.prepare(s.id);
    return s;
  }

  FileRef photo(int i) => source.addFile(
    '/s/DCIM/p$i.jpg',
    modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
  );

  Future<List<PendingDeleteRow>> pending() => (db.select(
    db.pendingDeletes,
  )..orderBy([(p) => OrderingTerm.asc(p.id)])).get();

  group('SessionRepository', () {
    test('one active session; reused until ended', () async {
      final a = await sessions.getOrCreateActive();
      final b = await sessions.getOrCreateActive();
      expect(b.id, a.id);
      expect(a.layout, SwipeLayout.basic);
      expect(a.deleteMode, DeleteMode.trash);
      await sessions.endActive();
      final c = await sessions.getOrCreateActive();
      expect(c.id, isNot(a.id));
    });

    test('new sessions take the saved layout and delete mode', () async {
      final settings = SettingsRepository(db, queue);
      await settings.write(AppSettings.deleteMode, 'permanent');
      final s = await sessions.getOrCreateActive();
      expect(s.deleteMode, DeleteMode.permanent);
      const custom = SwipeLayout(
        directions: {SwipeDirection.down: SwipeAction.keep},
      );
      await sessions.saveLayout(s.id, custom);
      expect((await sessions.active())!.layout, custom);
      await sessions.endActive();
      expect((await sessions.getOrCreateActive()).layout, custom);
    });

    test('cursor saves are debounced into one write', () async {
      final s = await sessions.getOrCreateActive();
      for (var i = 1; i <= 20; i++) {
        sessions.saveCursor(s.id, i, 'f$i');
      }
      expect((await sessions.active())!.cursor, 0);
      await sessions.flush();
      final saved = (await sessions.active())!;
      expect(saved.cursor, 20);
      expect(saved.cursorFileId, 'f20');
    });
  });

  group('undo log', () {
    test(
      'records keeps and trashes with in-memory seq; trash queues a delete',
      () async {
        final s = await start();
        expect(dispatcher.dispatch(s, photo(1), SwipeAction.keep), 1);
        expect(dispatcher.dispatch(s, photo(2), SwipeAction.trash), 2);
        await queue.flush();
        final stack = await undo.stack(s.id);
        expect(stack.map((a) => a.seq), [2, 1]);
        expect(stack.first.status, ActionStatus.applied);
        final rows = await pending();
        expect(rows.single.fileId, 'path:/s/DCIM/p2.jpg');
        expect(rows.single.status, PendingDeleteStatus.queued);
      },
    );

    test(
      'undo of a queued trash removes the pending row, touches no file',
      () async {
        final s = await start();
        final f = photo(1);
        dispatcher.dispatch(s, f, SwipeAction.trash);
        final outcome = await undoService.undoLast(s.id);
        expect(outcome, isA<Undone>());
        expect(await pending(), isEmpty);
        expect(await source.stat(f.id), isNotNull);
        expect(await undo.top(s.id), isNull);
        expect(await undoService.undoLast(s.id), isA<NothingToUndo>());
      },
    );

    test('12 swipes, 12 undos: every row undone, no file deleted', () async {
      final s = await start();
      for (var i = 0; i < 12; i++) {
        dispatcher.dispatch(
          s,
          photo(i),
          i.isEven ? SwipeAction.trash : SwipeAction.keep,
        );
      }
      final undone = <String>[];
      for (var i = 0; i < 12; i++) {
        final o = await undoService.undoLast(s.id) as Undone;
        undone.add(o.action.fileId);
      }
      expect(undone.first, 'path:/s/DCIM/p11.jpg');
      expect(undone.last, 'path:/s/DCIM/p0.jpg');
      expect(await pending(), isEmpty);
      expect(source.files, hasLength(12));
    });

    test('safe zone: only trash deeper than 10 swipes (of any kind)', () async {
      final s = await start();
      // seq 1..25: trash on odd seq.
      for (var i = 1; i <= 25; i++) {
        dispatcher.dispatch(
          s,
          photo(i),
          i.isOdd ? SwipeAction.trash : SwipeAction.keep,
        );
      }
      await queue.flush();
      final committable = await undo.committableDeletes(s.id);
      expect(committable.map((a) => a.seq), [1, 3, 5, 7, 9, 11, 13, 15]);

      for (var i = 0; i < 3; i++) {
        await undoService.undoLast(s.id);
      }
      final after = await undo.committableDeletes(s.id);
      expect(after.map((a) => a.seq).last, 11);
    });
  });

  group('delete queue', () {
    Future<Session> swipeLeft(int n, {DeleteMode? mode}) async {
      final s = await start(mode: mode);
      for (var i = 0; i < n; i++) {
        dispatcher.dispatch(s, photo(i), SwipeAction.trash);
      }
      await queue.flush();
      return s;
    }

    test('9 trash swipes: 9 queued, nothing deleted', () async {
      final s = await swipeLeft(9);
      expect((await deletes.maybeCommit(s.id)).committed, 0);
      expect(await pending(), hasLength(9));
      expect(source.trashCalls, 0);
    });

    test('60 trash swipes: 50 committed in one batch, last 10 kept', () async {
      final s = await swipeLeft(60);
      final r = await deletes.maybeCommit(s.id);
      expect(r.committed, 50);
      expect(source.trashCalls, 1);
      final rows = await pending();
      expect(
        rows.where((r) => r.status == PendingDeleteStatus.committed),
        hasLength(50),
      );
      expect(
        rows.where((r) => r.status == PendingDeleteStatus.queued),
        hasLength(10),
      );
      final committed = (await undo.stack(s.id))
          .where((a) => a.status == ActionStatus.committed);
      expect(committed.map((a) => a.seq).reduce((a, b) => a > b ? a : b), 50);

      final done = await deletes.commitAll(s.id);
      expect(done.committed, 10);
      expect(source.files, isEmpty);
    });

    test(
      'declined dialog: rows back to queued, no retry on every swipe',
      () async {
        final s = await swipeLeft(60);
        source.cancelTrash = true;
        final r = await deletes.maybeCommit(s.id);
        expect(r.userCancelled, isTrue);
        expect(
          (await pending()).every(
            (r) => r.status == PendingDeleteStatus.queued,
          ),
          isTrue,
        );
        dispatcher.dispatch(s, photo(100), SwipeAction.trash);
        await queue.flush();
        await deletes.maybeCommit(s.id);
        expect(source.trashCalls, 1, reason: 'backs off until 50 more');

        source.cancelTrash = false;
        expect((await deletes.commitEligible(s.id)).committed, 51);
      },
    );

    test(
      'a file gone already counts as committed; a changed one fails',
      () async {
        final s = await swipeLeft(2);
        source
          ..removeExternally('path:/s/DCIM/p0.jpg')
          ..addFile('/s/DCIM/p1.jpg', modifiedAt: DateTime.utc(2030));
        final r = await deletes.commitAll(s.id);
        expect(r.committed, 1);
        expect(r.failed, 1);
        final failed = (await pending()).singleWhere(
          (r) => r.status == PendingDeleteStatus.failed,
        );
        expect(failed.failureReason, contains('changed'));
      },
    );

    test('a platform error keeps rows queued and is reported', () async {
      final s = await start();
      final broken = DeleteQueue(
        db: db,
        lock: SerialLock(),
        source: _Unsupported(),
        undo: undo,
        index: index,
      );
      addTearDown(broken.dispose);
      final brokenErrors = <Object>[];
      final sub2 = broken.errors.listen(brokenErrors.add);
      addTearDown(sub2.cancel);
      dispatcher.dispatch(s, photo(1), SwipeAction.trash);
      await queue.flush();
      final r = await broken.commitAll(s.id);
      expect(r.committed, 0);
      await Future<void>.delayed(Duration.zero);
      expect(brokenErrors.single, isA<UnimplementedError>());
      expect((await pending()).single.status, PendingDeleteStatus.queued);
    });

    test('undo of a committed trash restores it from the trash', () async {
      final s = await swipeLeft(1);
      await deletes.commitAll(s.id);
      expect(source.files, isEmpty);
      final outcome = await undoService.undoLast(s.id);
      expect(outcome, isA<Undone>());
      expect((outcome as Undone).restoredFromTrash, isTrue);
      expect(source.files, hasLength(1));
    });

    test(
      'permanent mode: undo of a committed delete says so and moves on',
      () async {
        final s = await swipeLeft(1, mode: DeleteMode.permanent);
        await deletes.commitAll(s.id);
        expect(await undoService.undoLast(s.id), isA<PermanentlyDeleted>());
        expect(await undo.top(s.id), isNull);
      },
    );

    test(
      'rows stuck in committing are recovered from the disk state',
      () async {
        await swipeLeft(2);
        await db
            .update(db.pendingDeletes)
            .write(
              const PendingDeletesCompanion(
                status: Value(PendingDeleteStatus.committing),
              ),
            );
        source.removeExternally('path:/s/DCIM/p0.jpg');
        await deletes.recoverStuck();
        final rows = await pending();
        expect(rows[0].status, PendingDeleteStatus.committed);
        expect(rows[1].status, PendingDeleteStatus.queued);
      },
    );
  });
}

class _Unsupported extends FakeFileSource {
  @override
  Future<TrashResult> trashBatch(List<FileRef> files) =>
      throw UnimplementedError('TASK-D3');

  @override
  Future<FileRef?> stat(String id) async => FileRef(
    id: id,
    uri: id,
    name: 'p1.jpg',
    kind: FileKind.image,
    sizeBytes: 3,
    modifiedAt: DateTime.utc(2025, 1, 1, 0, 1),
    folderPath: '/s/DCIM',
    origin: FileOrigin.local,
  );
}
