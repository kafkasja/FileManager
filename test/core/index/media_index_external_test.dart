import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_change_source.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/index/media_indexer.dart';

import '../files/fake_file_source.dart';
import 'media_index_dao_test.dart' show ref;

/// U1: rows of a detached volume are hidden, never deleted by scans.
void main() {
  const sd = '/storage/1234-ABCD';
  const internal = '/storage/emulated/0';

  group('MediaIndexDao', () {
    late AppDatabase db;
    late MediaIndexDao dao;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      dao = MediaIndexDao(db);
      await dao.upsertBatch([
        ref(1, folder: '$internal/DCIM'),
        ref(2, folder: '$sd/DCIM'),
        ref(3, folder: sd),
        // Same prefix, other volume: not hidden.
        ref(4, folder: '${sd}0/DCIM'),
      ], 1);
    });
    tearDown(() => db.close());

    Future<Set<String>> visible([IndexQuery q = IndexQuery.all]) async => {
      for (final f in (await dao.page(q, limit: 100)).items) f.id,
    };

    test('excluded roots are left out of pages, counts and folders', () async {
      dao.setExcludedRoots({sd});
      expect(await visible(), {'ms:1', 'ms:4'});
      expect(await dao.count(IndexQuery.all), 2);
      final roots = await dao.folders(scope: IndexQuery.all);
      expect(roots.map((f) => f.path), isNot(contains(sd)));
      final summaries = await dao.folderSummaries();
      expect(summaries.map((s) => s.path), isNot(contains('$sd/DCIM')));
      // Unfiltered lookups still see them.
      expect(await dao.byId('ms:2'), isNotNull);

      dao.setExcludedRoots(const {});
      expect(await visible(), hasLength(4));
    });

    test('changing the excluded roots ticks the change stream', () async {
      final ticks = <int>[];
      final sub = dao.watchChanges().listen(ticks.add);
      addTearDown(sub.cancel);
      dao.setExcludedRoots({sd});
      await Future<void>.delayed(
        MediaIndexDao.changeDebounce + const Duration(milliseconds: 100),
      );
      expect(ticks, isNotEmpty);
    });

    test('indexedVolumeRoots lists removable roots only', () async {
      expect(await dao.indexedVolumeRoots(), {sd, '${sd}0'});
    });

    test('deleteOlderThanGeneration keeps rows under keepUnder', () async {
      final removed = await dao.deleteOlderThanGeneration(
        2,
        kinds: FileKind.values.toSet(),
        keepUnder: {sd},
      );
      expect(removed, 2); // ms:1 and ms:4
      expect(await dao.byId('ms:2'), isNotNull);
      expect(await dao.byId('ms:3'), isNotNull);
    });
  });

  group('MediaIndexer', () {
    late AppDatabase db;
    late DbWriteQueue queue;
    late MediaIndexDao dao;
    late FakeFileSource source;
    late StreamController<MediaChange> changes;
    late Set<String> detached;
    late MediaIndexer indexer;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      queue = DbWriteQueue();
      dao = MediaIndexDao(db);
      source = FakeFileSource();
      changes = StreamController<MediaChange>();
      detached = {};
      indexer = MediaIndexer(
        dao: dao,
        source: source,
        settings: SettingsRepository(db, queue),
        canSeeAllFiles: () => true,
        changes: changes.stream,
        clock: () => DateTime.utc(2026, 11, 2, 12),
        keepRoots: () async => detached,
      );
    });
    tearDown(() async {
      await indexer.dispose();
      await changes.close();
      await queue.close();
      await db.close();
    });

    test('a full scan while the card is out deletes none of its rows; '
        'they are back after re-insert', () async {
      source
        ..addFile('$internal/DCIM/a.jpg')
        ..addFile('$sd/DCIM/b.jpg');
      await indexer.start();
      expect(await dao.count(IndexQuery.all), 2);

      source.removeExternally('path:$sd/DCIM/b.jpg');
      detached = {sd};
      await indexer.fullScan();
      expect(await dao.byId('path:$sd/DCIM/b.jpg'), isNotNull);

      // Back in: the next scan sees it again, nothing was lost.
      detached = {};
      source.addFile('$sd/DCIM/b.jpg');
      await indexer.fullScan();
      expect(await dao.count(IndexQuery.all), 2);
    });

    test('a failing keepRoots fails the scan before deleting', () async {
      source.addFile('$sd/DCIM/b.jpg');
      final failing = MediaIndexer(
        dao: dao,
        source: source,
        settings: SettingsRepository(db, queue),
        canSeeAllFiles: () => true,
        keepRoots: () async => throw StateError('volumes unreadable'),
      );
      addTearDown(failing.dispose);
      await indexer.start();
      source.removeExternally('path:$sd/DCIM/b.jpg');
      await failing.fullScan();
      expect(failing.current, isA<IndexFailed>());
      expect(await dao.byId('path:$sd/DCIM/b.jpg'), isNotNull);
    });

    test('live deletes of files on a detached volume are ignored', () async {
      await dao.upsertBatch([
        ref(10, folder: '$sd/DCIM'),
        ref(11, folder: '$internal/DCIM'),
      ], 1);
      detached = {sd};
      indexer
        ..onMediaChange(const MediaChange(type: 'delete', id: 10))
        ..onMediaChange(const MediaChange(type: 'delete', id: 11));
      await Future<void>.delayed(
        MediaIndexer.changeDebounce + const Duration(milliseconds: 200),
      );
      await indexer.incremental(); // waits for the queued job
      expect(await dao.byId('ms:10'), isNotNull);
      expect(await dao.byId('ms:11'), isNull);
    });

    test('scanRoot adds old files under a mounted root', () async {
      await indexer.start();
      source.addFile('$sd/DCIM/old.jpg', modifiedAt: DateTime.utc(2010));
      await indexer.incremental();
      expect(await dao.byId('path:$sd/DCIM/old.jpg'), isNull);
      await indexer.scanRoot(sd);
      expect(await dao.byId('path:$sd/DCIM/old.jpg'), isNotNull);
    });
  });
}
