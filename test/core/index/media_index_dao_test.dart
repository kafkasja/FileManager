import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';

FileRef ref(
  int i, {
  FileKind kind = FileKind.image,
  String folder = '/s/DCIM',
  int? size,
  String? name,
}) => FileRef(
  id: 'ms:$i',
  uri: 'content://x/$i',
  name: name ?? 'IMG_$i.jpg',
  mimeType: kind == FileKind.image ? 'image/jpeg' : 'application/pdf',
  kind: kind,
  sizeBytes: size ?? i * 10,
  modifiedAt: DateTime.utc(2024).add(Duration(minutes: i)),
  folderPath: folder,
  origin: FileOrigin.local,
);

Future<List<String>> allIds(MediaIndexDao dao, IndexQuery q, int limit) async {
  final ids = <String>[];
  IndexCursor? cursor;
  do {
    final page = await dao.page(q, after: cursor, limit: limit);
    ids.addAll(page.items.map((f) => f.id));
    cursor = page.next;
  } while (cursor != null);
  return ids;
}

void main() {
  late AppDatabase db;
  late MediaIndexDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = MediaIndexDao(db);
  });
  tearDown(() => db.close());

  test('round-trips a FileRef', () async {
    final f = ref(1).copyWith(
      takenAt: DateTime.utc(2023, 5, 6),
      width: 4000,
      height: 3000,
      durationMs: 1200,
    );
    await dao.upsertBatch([f], 1);
    final back = (await dao.byId('ms:1'))!;
    expect(back, f);
    expect(back.takenAt, f.takenAt);
    expect(back.width, 4000);
    expect(back.durationMs, 1200);
    expect(back.sortDate, f.takenAt);
  });

  test(
    'keyset paging visits every row once, in order, for each sort',
    () async {
      // Duplicate sizes force the id tie-break.
      await dao.upsertBatch([
        for (var i = 0; i < 95; i++) ref(i, size: i % 7),
      ], 1);
      for (final sort in [
        FileSort.newestFirst,
        const FileSort(FileSortField.date, descending: false),
        const FileSort(FileSortField.size),
        const FileSort(FileSortField.size, descending: false),
        const FileSort(FileSortField.name, descending: false),
      ]) {
        final ids = await allIds(dao, IndexQuery(sort: sort), 10);
        expect(ids.toSet(), hasLength(95), reason: '$sort');
        expect(ids, hasLength(95), reason: '$sort');
      }
      final newest = await allIds(dao, IndexQuery.all, 10);
      expect(newest.first, 'ms:94');
      expect(newest.last, 'ms:0');
    },
  );

  test('filters: kinds, folder, subfolders, size, dates, name, mime', () async {
    await dao.upsertBatch([
      ref(1),
      ref(2, kind: FileKind.document, folder: '/s/Download'),
      ref(3, folder: '/s/DCIM/Camera'),
      ref(4, folder: '/s/DCIM_other'),
      ref(5, name: 'Holiday_beach.JPG'),
    ], 1);
    Future<Set<String>> ids(IndexQuery q) async =>
        (await allIds(dao, q, 100)).toSet();

    expect(await ids(const IndexQuery(kinds: {FileKind.document})), {'ms:2'});
    expect(await ids(const IndexQuery(folderPath: '/s/DCIM')), {
      'ms:1',
      'ms:5',
    });
    expect(
      await ids(
        const IndexQuery(folderPath: '/s/DCIM', includeSubfolders: true),
      ),
      {'ms:1', 'ms:3', 'ms:5'},
    );
    expect(await ids(const IndexQuery(minSizeBytes: 30, maxSizeBytes: 40)), {
      'ms:3',
      'ms:4',
    });
    expect(
      await ids(
        IndexQuery(
          from: DateTime.utc(2024).add(const Duration(minutes: 2)),
          to: DateTime.utc(2024).add(const Duration(minutes: 4)),
        ),
      ),
      {'ms:2', 'ms:3'},
    );
    expect(await ids(const IndexQuery(nameContains: 'BEACH')), {'ms:5'});
    expect(await ids(const IndexQuery(nameContains: '_')), hasLength(5));
    expect(await ids(const IndexQuery(mimePrefix: 'application/')), {'ms:2'});
  });

  test('count, totalBytes, byIds keeps order', () async {
    await dao.upsertBatch([ref(1), ref(2), ref(3)], 1);
    expect(await dao.count(IndexQuery.all), 3);
    expect(await dao.totalBytes(IndexQuery.all), 60);
    expect((await dao.byIds(['ms:3', 'ms:9', 'ms:1'])).map((f) => f.id), [
      'ms:3',
      'ms:1',
    ]);
  });

  test('deleteOlderThanGeneration only touches the given kinds/root', () async {
    await dao.upsertBatch([
      ref(1),
      ref(2, kind: FileKind.document),
      ref(3, folder: '/sd/DCIM'),
    ], 1);
    await dao.upsertBatch([ref(4)], 2);
    final removed = await dao.deleteOlderThanGeneration(
      2,
      kinds: {FileKind.image},
      rootPath: '/s',
    );
    expect(removed, 1);
    expect((await allIds(dao, IndexQuery.all, 50)).toSet(), {
      'ms:2',
      'ms:3',
      'ms:4',
    });
  });

  test('applyIdChange re-keys the row', () async {
    await dao.upsertBatch([ref(1)], 7);
    final moved = ref(1).copyWith(id: 'ms:100', folderPath: '/s/Pictures');
    await dao.applyIdChange(FileIdChange('ms:1', moved));
    expect(await dao.byId('ms:1'), isNull);
    expect((await dao.byId('ms:100'))?.folderPath, '/s/Pictures');
  });

  test('watchChanges fires once per burst', () async {
    final events = <int>[];
    final sub = dao.watchChanges().listen(events.add);
    addTearDown(sub.cancel);
    await dao.upsertBatch([ref(1)], 1);
    await dao.upsertBatch([ref(2)], 1);
    await Future<void>.delayed(
      MediaIndexDao.changeDebounce + const Duration(milliseconds: 200),
    );
    expect(events, hasLength(1));
  });

  test('50,000 rows: first and last pages are fast', () async {
    for (var start = 0; start < 50000; start += 5000) {
      await dao.upsertBatch([
        for (var i = start; i < start + 5000; i++)
          ref(i, kind: i.isEven ? FileKind.image : FileKind.video),
      ], 1);
    }
    const q = IndexQuery(kinds: {FileKind.image});
    final sw = Stopwatch()..start();
    final first = await dao.page(q);
    final firstMs = sw.elapsedMilliseconds;

    // Jump to near the end with a cursor (as a view scrolled far down would).
    final cursor = IndexCursor(
      DateTime.utc(2024)
          .add(const Duration(minutes: 400))
          .millisecondsSinceEpoch,
      'ms:400',
    );
    sw.reset();
    final last = await dao.page(q, after: cursor);
    final lastMs = sw.elapsedMilliseconds;

    expect(first.items, hasLength(200));
    expect(last.items, hasLength(200));
    // Plan target is <20 ms on device; generous bound for CI hosts.
    expect(firstMs, lessThan(100), reason: 'first page ${firstMs}ms');
    expect(lastMs, lessThan(100), reason: 'last page ${lastMs}ms');
    // Timing is reported in the test log for CHANGES.md.
    // ignore: avoid_print
    print('50k index: first page ${firstMs}ms, deep page ${lastMs}ms');
  });
}
