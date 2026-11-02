import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/db/tables/pending_deletes_table.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/features/connect/data/remote_file_source.dart';
import 'package:kfm/features/connect/data/remote_swipe_queue_source.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/rename/data/rename_batch_repository.dart';
import 'package:kfm/features/rename/data/rename_runner.dart';
import 'package:kfm/features/session/data/session_repository.dart';
import 'package:kfm/features/session/domain/remote_deck_root.dart';
import 'package:kfm/features/session/domain/session_source.dart';
import 'package:kfm/features/swipe/data/swipe_action_dispatcher.dart';
import 'package:kfm/features/swipe/data/swipe_file_ops.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/tags/data/favorites_repository.dart';
import 'package:kfm/features/tags/data/tag_repository.dart';
import 'package:kfm/features/trash/data/delete_queue.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';
import 'package:kfm/features/undo/domain/undo_service.dart';

import '../../core/files/fake_file_source.dart';

final String _fp = 'ab' * 32;

FileRef _remote(int i, {String root = 'r1', int minute = 0}) => FileRef(
  id: 'remote:$_fp:path:/a/p$i.jpg',
  uri: 'remote://$_fp/p$i',
  name: 'p$i.jpg',
  kind: FileKind.image,
  sizeBytes: 10,
  modifiedAt: DateTime.utc(2025, 1, 1, 0, minute),
  folderPath: '$root/DCIM',
  origin: FileOrigin.remote,
);

/// The other device: files by id; offline = every call is `unavailable`.
class _RemoteFake implements FileSource {
  final Map<String, FileRef> files = {};
  bool online = true;
  bool declineTrash = false;
  final List<List<String>> trashed = [];

  void _check() {
    if (!online) {
      throw const FileOpException(FileOpFailure.unavailable, 'offline');
    }
  }

  @override
  Future<FileRef?> stat(String id) async {
    _check();
    return files[id];
  }

  @override
  Future<TrashResult> trashBatch(List<FileRef> list) async {
    _check();
    if (declineTrash) {
      return const TrashResult(trashed: [], failed: {}, userCancelled: true);
    }
    trashed.add([for (final f in list) f.id]);
    final now = DateTime.utc(2026);
    return TrashResult(
      trashed: [
        for (final f in list)
          TrashedItem(
            trashId: 't-${f.id}',
            original: files.remove(f.id) ?? f,
            location: TrashLocation.systemTrash,
            trashedAt: now,
          ),
      ],
      failed: const {},
    );
  }

  @override
  Future<FileRef> restore(TrashedItem item) async =>
      throw const FileOpException(FileOpFailure.unsupported, 'restore');

  @override
  Future<void> deletePermanentlyBatch(List<FileRef> files) async =>
      throw const FileOpException(FileOpFailure.unsupported, 'permanent');

  @override
  Future<FileRef> copy(FileRef f, String targetFolder) async {
    _check();
    final copy = FileRef(
      id: '${f.id}-copy',
      uri: f.uri,
      name: f.name,
      kind: f.kind,
      sizeBytes: f.sizeBytes,
      modifiedAt: f.modifiedAt,
      folderPath: targetFolder,
      origin: FileOrigin.remote,
    );
    files[copy.id] = copy;
    return copy;
  }

  @override
  Future<List<TrashedItem>> listTrashed() async => const [];

  @override
  bool supports(FileOp op, FileRef f) => true;

  @override
  Stream<FileIdChange> get idChanges => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late SessionRepository sessions;
  late UndoRepository undo;
  late DeleteQueue deletes;
  late UndoService undoService;
  late SwipeActionDispatcher dispatcher;
  late FakeFileSource local;
  late _RemoteFake remote;
  late MediaIndexDao index;
  late MediaIndexer indexer;
  late SwipeFileOps fileOps;
  final trashCalls = <(FileSource, int)>[];

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    sessions = SessionRepository(db, queue);
    undo = UndoRepository(db, queue);
    local = FakeFileSource();
    remote = _RemoteFake();
    index = MediaIndexDao(db);
    trashCalls.clear();
    final lock = SerialLock();
    FileSource remoteFor(String id) {
      expect(id, remoteSourceId(_fp));
      return remote;
    }

    deletes = DeleteQueue(
      db: db,
      lock: lock,
      source: local,
      undo: undo,
      index: index,
      remoteSource: remoteFor,
      trash: (s, files) {
        trashCalls.add((s, files.length));
        return s.trashBatch(files);
      },
    );
    indexer = MediaIndexer(
      dao: index,
      source: local,
      settings: SettingsRepository(db, queue),
      canSeeAllFiles: () => true,
    );
    final renames = RenameBatchRepository(db);
    fileOps = SwipeFileOps(
      source: local,
      undo: undo,
      lock: lock,
      indexer: indexer,
      remoteSource: remoteFor,
    );
    undoService = UndoService(
      repo: undo,
      deletes: deletes,
      source: local,
      remoteSource: remoteFor,
      lock: lock,
      queue: queue,
      indexer: indexer,
      index: index,
      tags: TagRepository(db),
      favorites: FavoritesRepository(db),
      renames: renames,
      renameRunner: RenameRunner(
        source: local,
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
      tags: TagRepository(db),
      favorites: FavoritesRepository(db),
      renames: renames,
    );
  });

  tearDown(() async {
    await fileOps.dispose();
    await indexer.dispose();
    await deletes.dispose();
    await queue.close();
    await db.close();
  });

  const root = RemoteDeckRoot(rootId: 'r1', path: 'DCIM', device: 'Phone');

  Future<List<PendingDeleteRow>> pending() => (db.select(
    db.pendingDeletes,
  )..orderBy([(p) => OrderingTerm.asc(p.id)])).get();

  group('sessions per source', () {
    test('a remote session is trash mode and leaves the local one alone; '
        'discard removes its rows', () async {
      await SettingsRepository(db, queue).write(
        // D1: even a "delete permanently" setting.
        AppSettings.deleteMode,
        'permanent',
      );
      final mine = await sessions.getOrCreateActive();
      await undo.prepare(mine.id);
      dispatcher.dispatch(
        mine,
        local.addFile('/s/DCIM/x.jpg'),
        SwipeAction.trash,
      );

      final theirs = await sessions.startRemote(_fp, root);
      expect(theirs.sourceId, remoteSourceId(_fp));
      expect(theirs.deleteMode, DeleteMode.trash);
      expect(theirs.presetId, isNull);
      expect(RemoteDeckRoot.decode(theirs.filterJson), root);
      expect((await sessions.active())!.id, mine.id);
      expect((await sessions.active(sourceId: theirs.sourceId))!.id, theirs.id);

      // Again (another folder): the same session, the new folder.
      const other = RemoteDeckRoot(rootId: 'r1', path: 'Pictures');
      final again = await sessions.startRemote(_fp, other);
      expect(again.id, theirs.id);
      expect(RemoteDeckRoot.decode(again.filterJson), other);

      await undo.prepare(theirs.id);
      final f = _remote(1);
      remote.files[f.id] = f;
      dispatcher.dispatch(theirs, f, SwipeAction.trash);
      await queue.flush();
      expect(await pending(), hasLength(2));

      await sessions.discard(theirs.id);
      expect(await sessions.active(sourceId: theirs.sourceId), isNull);
      final left = await pending();
      expect(left.single.sessionId, mine.id);
      expect(await undo.stack(theirs.id), isEmpty);
      expect(remote.trashed, isEmpty);
      expect(remote.files, contains(f.id));
    });

    test('ending the remote session keeps the local one active', () async {
      final mine = await sessions.getOrCreateActive();
      final theirs = await sessions.startRemote(_fp, root);
      await sessions.endActive(sourceId: theirs.sourceId);
      expect(await sessions.active(sourceId: theirs.sourceId), isNull);
      expect((await sessions.active())!.id, mine.id);
    });
  });

  group('remote deletes (D2)', () {
    Future<int> swipeLeft(int count) async {
      final s = await sessions.startRemote(_fp, root);
      await undo.prepare(s.id);
      for (var i = 0; i < count; i++) {
        final f = _remote(i);
        remote.files[f.id] = f;
        dispatcher.dispatch(s, f, SwipeAction.trash);
      }
      await queue.flush();
      return s.id;
    }

    test('commit trashes on the device through the swipe hook', () async {
      final id = await swipeLeft(3);
      final result = await deletes.commitAll(id);
      expect(result.committed, 3);
      expect(trashCalls.single.$1, same(remote));
      expect(remote.trashed.single, hasLength(3));
      expect(
        (await pending()).map((r) => r.status),
        everyElement(PendingDeleteStatus.committed),
      );
    });

    test('offline: rows stay queued, sourceUnavailable, no error', () async {
      final id = await swipeLeft(3);
      remote.online = false;
      final errors = <Object>[];
      deletes.errors.listen(errors.add);
      final result = await deletes.commitAll(id);
      expect(result.sourceUnavailable, isTrue);
      expect(result.committed, 0);
      expect(
        (await pending()).map((r) => r.status),
        everyElement(PendingDeleteStatus.queued),
      );
      expect(errors, isEmpty);
      remote.online = true;
      expect((await deletes.commitAll(id)).committed, 3);
    });

    test('recoverStuck while offline requeues without throwing', () async {
      await swipeLeft(2);
      await db
          .update(db.pendingDeletes)
          .write(
            const PendingDeletesCompanion(
              status: Value(PendingDeleteStatus.committing),
            ),
          );
      remote.online = false;
      expect(await deletes.recoverStuck(), 2);
      expect(
        (await pending()).map((r) => r.status),
        everyElement(PendingDeleteStatus.queued),
      );
    });

    test('a file changed on the device is reported, never trashed', () async {
      final id = await swipeLeft(1);
      final f = _remote(0);
      remote.files[f.id] = _remote(0, minute: 5);
      final result = await deletes.commitAll(id);
      expect(result.failed, 1);
      expect(remote.trashed, isEmpty);
      expect(
        (await pending()).single.failureReason,
        'file changed since it was swiped',
      );
      expect(f.id, isNotEmpty);
    });

    test('declined on the device: nothing trashed, rows queued', () async {
      final id = await swipeLeft(2);
      remote.declineTrash = true;
      final result = await deletes.commitAll(id);
      expect(result.userCancelled, isTrue);
      expect(
        (await pending()).map((r) => r.status),
        everyElement(PendingDeleteStatus.queued),
      );
    });

    test('a committed remote trash undoes to "restore it there"', () async {
      final id = await swipeLeft(1);
      await deletes.commitAll(id);
      final outcome = await undoService.undoLast(id);
      expect(
        outcome,
        isA<UndoFailed>().having(
          (o) => o.error,
          'error',
          isA<FileOpException>().having(
            (e) => e.failure,
            'failure',
            FileOpFailure.unsupported,
          ),
        ),
      );
    });

    test('undo of a remote copy trashes the copy on the device', () async {
      final s = await sessions.startRemote(_fp, root);
      await undo.prepare(s.id);
      final f = _remote(1);
      remote.files[f.id] = f;
      final events = fileOps.events.first;
      dispatcher.dispatch(
        s,
        f,
        const SwipeAction(SwipeActionType.copyTo, targetFolder: 'r1/Backup'),
      );
      await events;
      await queue.flush();
      expect(remote.files, contains('${f.id}-copy'));
      // Never indexed on this device.
      expect(await index.byId('${f.id}-copy'), isNull);
      final outcome = await undoService.undoLast(s.id);
      expect(outcome, isA<Undone>());
      expect(remote.trashed.single, ['${f.id}-copy']);
      expect(remote.files, contains(f.id));
    });
  });

  group('RemoteQueueSource', () {
    test(
      '3 pages, page 2 fully excluded: the window of 50 still fills',
      () async {
        final pages = [
          [for (var i = 0; i < 30; i++) _remote(i)],
          [for (var i = 30; i < 60; i++) _remote(i)],
          [for (var i = 60; i < 90; i++) _remote(i)],
        ];
        final asked = <String?>[];
        Future<RemotePage> pager(
          RemoteQueryDto q, {
          String? cursor,
          int limit = 30,
        }) async {
          expect(q.rootId, 'r1');
          expect(q.path, 'DCIM');
          expect(q.includeSubfolders, isTrue);
          asked.add(cursor);
          final i = cursor == null ? 0 : int.parse(cursor);
          return RemotePage(
            items: pages[i],
            nextCursor: i + 1 < pages.length ? '${i + 1}' : null,
            total: i == 0 ? 90 : null,
          );
        }

        final excluded = {for (final f in pages[1]) f.id};
        final source = RemoteQueueSource(
          pager,
          root,
          exclude: (files) async => {
            for (final f in files)
              if (excluded.contains(f.id)) f.id,
          },
          pageSize: 30,
        );
        final skip = {pages[0].first.id};
        final w = await source.window(skip: skip, size: 50);
        expect(asked, [null, '1', '2']);
        expect(w.files, hasLength(59));
        expect(w.files.any((f) => excluded.contains(f.id)), isFalse);
        expect(w.files.any((f) => skip.contains(f.id)), isFalse);
        expect(w.next, isNull);
        expect(await source.remaining(skip), 90 - 30 - 1);
      },
    );

    test('stops at the window size and hands back the cursor', () async {
      Future<RemotePage> pager(
        RemoteQueryDto q, {
        String? cursor,
        int limit = 30,
      }) async => RemotePage(
        items: [
          for (var i = 0; i < 30; i++) _remote(i + (cursor ?? '0').length),
        ],
        nextCursor: 'more',
        total: 1000,
      );
      final source = RemoteQueueSource(pager, root, pageSize: 30);
      final w = await source.window(skip: const {}, size: 20);
      expect(w.files, hasLength(30));
      expect(w.next, isA<IndexCursor>());
      expect(w.next!.sortValue, 'more');
    });
  });

  group('remote swipe rules', () {
    final f = _remote(1);
    const rules = RemoteSwipeRules(roots: {'r1': false, 'ro': true});

    SwipeActionProblem? check(SwipeAction a, {FileRef? file}) =>
        SwipeActionDispatcher.problemFor(
          a,
          const {},
          remote: rules,
          file: file ?? f,
        );

    test('move targets must be writable folders on the device', () {
      expect(
        check(const SwipeAction(SwipeActionType.moveTo, targetFolder: '/x')),
        SwipeActionProblem.folderNotOnSource,
      );
      expect(
        check(const SwipeAction(SwipeActionType.copyTo, targetFolder: 'ro/a')),
        SwipeActionProblem.folderNotOnSource,
      );
      expect(
        check(const SwipeAction(SwipeActionType.copyTo, targetFolder: 'zz')),
        SwipeActionProblem.folderNotOnSource,
      );
      expect(
        check(const SwipeAction(SwipeActionType.moveTo, targetFolder: 'r1/b')),
        isNull,
      );
    });

    test('read-only folder: no trash or move; keep and copy are fine', () {
      final ro = _remote(2, root: 'ro');
      expect(check(SwipeAction.trash, file: ro), SwipeActionProblem.readOnly);
      expect(
        check(
          const SwipeAction(SwipeActionType.moveTo, targetFolder: 'r1/b'),
          file: ro,
        ),
        SwipeActionProblem.readOnly,
      );
      expect(check(SwipeAction.keep, file: ro), isNull);
      expect(
        check(
          const SwipeAction(SwipeActionType.copyTo, targetFolder: 'r1/b'),
          file: ro,
        ),
        isNull,
      );
    });

    test('rename batch is not offered; offline rules check nothing', () {
      expect(
        check(const SwipeAction(SwipeActionType.renameBatch)),
        SwipeActionProblem.notOnDevice,
      );
      expect(
        SwipeActionDispatcher.problemFor(
          SwipeAction.trash,
          const {},
          remote: const RemoteSwipeRules(),
          file: _remote(3, root: 'ro'),
        ),
        isNull,
      );
    });
  });

  test('sourceIdOfFile / peerOfSourceId', () {
    expect(sourceIdOfFile(_remote(1).id), remoteSourceId(_fp));
    expect(sourceIdOfFile('path:/s/a.jpg'), kLocalSourceId);
    expect(sourceIdOfFile('ms:12'), kLocalSourceId);
    expect(peerOfSourceId(remoteSourceId(_fp)), _fp);
    expect(peerOfSourceId(kLocalSourceId), isNull);
    expect(TrashPreviousState(mode: DeleteMode.trash.name).mode, 'trash');
  });
}
