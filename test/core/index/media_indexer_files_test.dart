import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_change_source.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/index/media_indexer.dart';

import '../files/fake_file_source.dart';

/// Counts scans so a test can tell a stat from a walk.
class _CountingSource extends FakeFileSource {
  final List<FileQuery> scans = [];

  @override
  Stream<List<FileRef>> scan({FileQuery query = FileQuery.all}) {
    scans.add(query);
    return super.scan(query: query);
  }
}

/// TASK-N7 live sync: Files-table events reach the index.
void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late MediaIndexDao dao;
  late _CountingSource source;
  late MediaIndexer indexer;
  late bool canSeeAll;
  late DateTime now;

  const debounce = Duration(milliseconds: 20);
  const minInterval = Duration(milliseconds: 300);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    dao = MediaIndexDao(db);
    source = _CountingSource();
    canSeeAll = true;
    now = DateTime.utc(2026, 11);
    indexer = MediaIndexer(
      dao: dao,
      source: source,
      settings: SettingsRepository(db, queue),
      canSeeAllFiles: () => canSeeAll,
      clock: () => now,
      fileChangeDebounce: debounce,
      reconcileMinInterval: minInterval,
      hasNoMediaMarker: (folder) async => folder.endsWith('/Private'),
    );
  });

  tearDown(() async {
    await indexer.dispose();
    await queue.close();
    await db.close();
    await source.dispose();
  });

  Future<void> settle() async {
    await Future<void>.delayed(debounce * 3);
    await indexer.addFiles(const []);
  }

  Future<Set<String>> ids() async => {
    for (final f in (await dao.page(
      const IndexQuery(hidden: HiddenFilter.include),
      limit: 1000,
    )).items)
      f.id,
  };

  test('a new PDF is indexed from its path, without a walk', () async {
    source.addFile('/s/Download/a.pdf');
    indexer.onFileChange(
      const FilesTableChange(
        type: 'insert',
        path: '/s/Download/a.pdf',
        mediaType: 0,
      ),
      reconcileRoots: const ['/s/Download'],
    );
    await settle();
    expect(await ids(), {'path:/s/Download/a.pdf'});
    expect(source.scans, isEmpty);
  });

  test('media and missing All files access are skipped; dot and .nomedia '
      'folders are indexed as hidden, like the walker', () async {
    source
      ..addFile('/s/DCIM/p.jpg')
      ..addFile('/s/Download/.cache/x.pdf')
      ..addFile('/s/Download/Private/deep/y.pdf')
      ..addFile('/s/Download/z.pdf');
    indexer
      ..onFileChange(
        const FilesTableChange(
          type: 'insert',
          path: '/s/DCIM/p.jpg',
          mediaType: 1,
        ),
      )
      ..onFileChange(
        const FilesTableChange(
          type: 'insert',
          path: '/s/Download/.cache/x.pdf',
          mediaType: 0,
        ),
      )
      ..onFileChange(
        const FilesTableChange(
          type: 'update',
          path: '/s/Download/Private/deep/y.pdf',
          mediaType: 0,
        ),
      );
    await settle();
    expect(await ids(), {
      'path:/s/Download/.cache/x.pdf',
      'path:/s/Download/Private/deep/y.pdf',
    });
    expect((await dao.page(IndexQuery.all)).items, isEmpty, reason: 'hidden');

    canSeeAll = false;
    indexer.onFileChange(
      const FilesTableChange(
        type: 'insert',
        path: '/s/Download/z.pdf',
        mediaType: 0,
      ),
    );
    await settle();
    expect(await ids(), isNot(contains('path:/s/Download/z.pdf')));
  });

  test('a delete reconciles only the shared folders (scoped, by '
      'generation), at most once per interval', () async {
    final a = source.addFile('/s/Download/a.pdf');
    final b = source.addFile('/s/Download/b.pdf');
    final other = source.addFile('/s/Music/m.pdf');
    await dao.upsertBatch([a, b, other], 0);
    source
      ..removeExternally(a.id)
      ..removeExternally(other.id);
    indexer.onFileChange(
      const FilesTableChange(type: 'delete'),
      reconcileRoots: const ['/s/Download', '/s/Download/sub'],
    );
    await settle();
    // Gone under the shared root; the row elsewhere waits for a full scan.
    expect(await ids(), {b.id, other.id});
    expect(source.scans.map((q) => q.rootPath), ['/s/Download']);

    // A second delete right away waits for the interval.
    source.removeExternally(b.id);
    indexer.onFileChange(
      const FilesTableChange(type: 'delete'),
      reconcileRoots: const ['/s/Download'],
    );
    await settle();
    expect(source.scans, hasLength(1));
    now = now.add(minInterval);
    await Future<void>.delayed(minInterval + debounce * 3);
    await indexer.addFiles(const []);
    expect(source.scans, hasLength(2));
    expect(await ids(), {other.id});
  });

  test('a path that is gone again refreshes only its own folder, not '
      'recursively', () async {
    final a = source.addFile('/s/Download/a.pdf');
    final deeper = source.addFile('/s/Download/sub/old.pdf');
    await dao.upsertBatch([a, deeper], 0);
    source
      ..removeExternally(a.id)
      ..removeExternally(deeper.id);
    indexer.onFileChange(
      const FilesTableChange(
        type: 'update',
        path: '/s/Download/a.pdf',
        mediaType: 0,
      ),
      reconcileRoots: const ['/s/Download'],
    );
    await settle();
    await indexer.addFiles(const []);
    expect(await ids(), {deeper.id});
    expect(source.scans.single.rootPath, '/s/Download');
    expect(source.scans.single.recursive, isFalse);
  });

  test(
    "this device's own media deletes (indexed ms: ids) and deletes "
    'with no folder to reconcile (whole-volume share) scan nothing',
    () async {
      final pic = source.addFile('/s/DCIM/p.jpg').copyWith(id: 'ms:7');
      await dao.upsertBatch([pic], 0);
      indexer
        ..onFileChange(
          const FilesTableChange(type: 'update', id: 7),
          reconcileRoots: const ['/s/DCIM'],
        )
        ..onFileChange(const FilesTableChange(type: 'delete', id: 99));
      await settle();
      expect(source.scans, isEmpty);
    },
  );

  test('refreshFolder is scoped: rows outside the root stay', () async {
    final pic = source.addFile('/s/DCIM/p.jpg');
    await dao.upsertBatch([pic], 0);
    await indexer.refreshFolder('/s/Download');
    expect(await ids(), {pic.id});
    expect(source.scans.single.kinds, FileKind.values.toSet());
  });
}
