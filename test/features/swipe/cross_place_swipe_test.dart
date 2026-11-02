import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/db/tables/pending_deletes_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/features/rename/data/rename_batch_repository.dart';
import 'package:kfm/features/rename/data/rename_runner.dart';
import 'package:kfm/features/session/data/session_repository.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/swipe/data/swipe_action_dispatcher.dart';
import 'package:kfm/features/swipe/data/swipe_file_ops.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/tags/data/favorites_repository.dart';
import 'package:kfm/features/tags/data/file_id_rekeyer.dart';
import 'package:kfm/features/tags/data/tag_repository.dart';
import 'package:kfm/features/trash/data/delete_queue.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';
import 'package:kfm/features/undo/domain/undo_service.dart';

import '../../core/files/routing_setup.dart';

/// U2: a swipe move to another place copies + verifies now and queues the
/// original's delete in D2 (last-10 rule); undo covers queued, trashed
/// and permanently deleted originals.
void main() {
  late Setup s;
  late AppDatabase db;
  late DbWriteQueue queue;
  late SessionRepository sessions;
  late UndoRepository undo;
  late DeleteQueue deletes;
  late UndoService undoService;
  late SwipeActionDispatcher dispatcher;
  late MediaIndexer indexer;
  late SwipeFileOps fileOps;
  late SerialLock lock;
  late FavoritesRepository favorites;

  setUp(() {
    s = Setup();
    s.safFake.addFolder('${s.usb}/Photos');
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    sessions = SessionRepository(db, queue);
    undo = UndoRepository(db, queue);
    final index = MediaIndexDao(db);
    lock = SerialLock();
    deletes = DeleteQueue(
      db: db,
      lock: lock,
      source: s.router,
      undo: undo,
      index: index,
    );
    indexer = MediaIndexer(
      dao: index,
      source: s.router,
      settings: SettingsRepository(db, queue),
      canSeeAllFiles: () => true,
    );
    final tags = TagRepository(db);
    favorites = FavoritesRepository(db);
    final renames = RenameBatchRepository(db);
    final rekeyer = FileIdRekeyer(db, queue);
    fileOps = SwipeFileOps(
      source: s.router,
      undo: undo,
      lock: lock,
      indexer: indexer,
      crossPlaceCopy: (file, target) async =>
          s.router.isCrossPlace(file, target)
          ? (await s.router.crossPlace.copyVerified(file, target)).copy
          : null,
      queueDelete: deletes.queueInTransaction,
      copyLabels: rekeyer.copyLabels,
    );
    undoService = UndoService(
      repo: undo,
      deletes: deletes,
      source: s.router,
      lock: lock,
      queue: queue,
      indexer: indexer,
      index: index,
      tags: tags,
      favorites: favorites,
      renames: renames,
      renameRunner: RenameRunner(
        source: s.router,
        repo: renames,
        undo: undo,
        lock: lock,
        indexer: indexer,
      ),
    );
    dispatcher = SwipeActionDispatcher(
      undo,
      deletes,
      fileOps: fileOps,
      tags: tags,
      favorites: favorites,
      renames: renames,
    );
  });

  tearDown(() async {
    await fileOps.dispose();
    await indexer.dispose();
    await deletes.dispose();
    await queue.close();
    await db.close();
    await s.dispose();
  });

  Future<Session> start({DeleteMode? mode}) async {
    final session = await sessions.getOrCreateActive(deleteMode: mode);
    await undo.prepare(session.id);
    return session;
  }

  Future<void> settle() async {
    await lock.run(() async {});
    await queue.flush();
  }

  const toStick = SwipeAction(
    SwipeActionType.moveTo,
    targetFolder: '/storage/ABCD-1234/Photos',
  );

  FileRef photo() =>
      s.android.addFile('${Setup.internal}/Pictures/a.jpg', bytes: [1, 2, 3]);

  test('the copy is verified now; the original waits in D2', () async {
    final session = await start();
    final f = photo();
    await favorites.addInTransaction(f.id);
    dispatcher.dispatch(session, f, toStick);
    await settle();
    expect(s.safFake.bytesAt('${s.usb}/Photos/a.jpg'), [1, 2, 3]);
    expect(await s.router.stat(f.id), isNotNull, reason: 'last-10 rule');
    final pending = await db.select(db.pendingDeletes).get();
    expect(pending.single.fileId, f.id);
    final top = (await undo.top(session.id))!;
    expect(top.previous, isA<CrossPlaceMovePreviousState>());
    final copyId = (top.previous as CrossPlaceMovePreviousState).copy.id;
    expect(await favorites.isFavorite(copyId), isTrue);
  });

  test('undo while queued: delete dropped, copy gone, original kept', () async {
    final session = await start();
    final f = photo();
    dispatcher.dispatch(session, f, toStick);
    await settle();
    final outcome = await undoService.undoLast(session.id);
    expect(outcome, isA<Undone>());
    expect(s.safFake.existsPath('${s.usb}/Photos/a.jpg'), isFalse);
    expect(await s.router.stat(f.id), isNotNull);
    expect(await db.select(db.pendingDeletes).get(), isEmpty);
  });

  test('commit trashes the original; undo restores it, copy gone', () async {
    final session = await start();
    final f = photo();
    dispatcher.dispatch(session, f, toStick);
    await settle();
    await deletes.commitAll(session.id);
    expect(await s.router.stat(f.id), isNull);
    expect(s.android.trash, hasLength(1));
    final top = (await undo.top(session.id))!;
    final previous = top.previous as CrossPlaceMovePreviousState;
    expect(previous.trashedItem, isNotNull, reason: 'merged at commit');

    final outcome = await undoService.undoLast(session.id) as Undone;
    expect(outcome.file?.id, f.id);
    expect(await s.router.stat(f.id), isNotNull);
    expect(s.safFake.existsPath('${s.usb}/Photos/a.jpg'), isFalse);
  });

  test('permanent: undo safely moves the copy back', () async {
    final session = await start(mode: DeleteMode.permanent);
    final f = photo();
    dispatcher.dispatch(session, f, toStick);
    await settle();
    await deletes.commitAll(session.id);
    final rows = await db.select(db.pendingDeletes).get();
    expect(rows.single.status, PendingDeleteStatus.committed);
    expect(await s.router.stat(f.id), isNull);

    final outcome = await undoService.undoLast(session.id) as Undone;
    expect(outcome.file?.folderPath, '${Setup.internal}/Pictures');
    expect(s.android.bytesOf(outcome.file!.id), [1, 2, 3]);
    expect(s.safFake.existsPath('${s.usb}/Photos/a.jpg'), isFalse);
  });

  test('a same-place move stays a plain move', () async {
    final session = await start();
    s.android.addFolder('${Setup.internal}/Holiday');
    final f = photo();
    dispatcher.dispatch(
      session,
      f,
      const SwipeAction(
        SwipeActionType.moveTo,
        targetFolder: '${Setup.internal}/Holiday',
      ),
    );
    await settle();
    expect(await db.select(db.pendingDeletes).get(), isEmpty);
    expect((await undo.top(session.id))!.previous, isA<MovePreviousState>());
  });
}
