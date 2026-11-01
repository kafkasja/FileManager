import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/swipe/data/swipe_queue_repository.dart';
import 'package:kfm/features/swipe/data/swipe_queue_source.dart';

import '../../core/files/fake_file_source.dart';

void main() {
  late AppDatabase db;
  late MediaIndexDao index;
  late FakeFileSource files;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    index = MediaIndexDao(db);
    files = FakeFileSource();
  });

  tearDown(() => db.close());

  /// [count] indexed photos; dates ascending, so index order != list order.
  Future<List<String>> addMany(int count, {String prefix = 'p'}) async {
    final refs = [
      for (var i = 0; i < count; i++)
        files.addFile(
          '/s/DCIM/$prefix$i.jpg',
          modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
        ),
    ];
    await index.upsertBatch(refs, 1);
    return [for (final r in refs) r.id];
  }

  ListQueueSource source(
    List<(String, int?)> items, {
    int? groupCount,
    List<List<String>>? goneLog,
  }) => ListQueueSource(
    index,
    files,
    items,
    groupCount: groupCount,
    onGone: (gone) => goneLog?.add(gone),
  );

  List<(String, int?)> flat(List<String> ids) => [
    for (final id in ids) (id, null),
  ];

  test('pages the ids in the given order with a position cursor', () async {
    final ids = (await addMany(7)).reversed.toList()..shuffle();
    final q = source(flat(ids));
    expect(q.offersNewFiles, isFalse);

    final first = await q.window(skip: const {}, size: 3);
    expect([for (final f in first.files) f.id], ids.sublist(0, 3));
    expect(first.next, isNotNull);
    expect(first.next!.sortValue, 2);
    expect(first.next!.id, ids[2]);

    final second = await q.window(skip: const {}, after: first.next, size: 3);
    expect([for (final f in second.files) f.id], ids.sublist(3, 6));
    final third = await q.window(skip: const {}, after: second.next, size: 3);
    expect([for (final f in third.files) f.id], [ids[6]]);
    expect(third.next, isNull);
  });

  test('skips acted ids and keeps the order of the rest', () async {
    final ids = await addMany(6);
    final q = source(flat(ids));
    final w = await q.window(skip: {ids[0], ids[3]});
    expect([for (final f in w.files) f.id], [ids[1], ids[2], ids[4], ids[5]]);
    expect(w.next, isNull);
    expect(await q.remaining({ids[0], ids[3]}), 4);
  });

  test('a window fills up past skipped ids', () async {
    final ids = await addMany(6);
    final q = source(flat(ids));
    final w = await q.window(skip: {ids[0], ids[1]}, size: 3);
    expect([for (final f in w.files) f.id], [ids[2], ids[3], ids[4]]);
    expect(w.next, isNotNull);
  });

  test('an unindexed file that still exists is found by stat', () async {
    final ids = await addMany(2);
    final loose = files.addFile('/s/Private/x.jpg').id;
    final gone = <List<String>>[];
    final q = source(flat([ids[0], loose, ids[1]]), goneLog: gone);
    final w = await q.window(skip: const {});
    expect([for (final f in w.files) f.id], [ids[0], loose, ids[1]]);
    expect(gone, isEmpty);
  });

  test('gone ids are dropped, reported once and not counted', () async {
    final ids = await addMany(5);
    // Deleted outside KFM: neither in the index nor on disk.
    files.removeExternally(ids[1]);
    await index.deleteIds([ids[1]]);
    final gone = <List<String>>[];
    final q = source(flat([...ids, 'path:/nope.jpg']), goneLog: gone);

    expect(await q.remaining(const {}), 6); // not known before paging
    final w = await q.window(skip: const {});
    expect([for (final f in w.files) f.id], [ids[0], ids[2], ids[3], ids[4]]);
    expect(gone, [
      [ids[1], 'path:/nope.jpg'],
    ]);
    expect(await q.remaining(const {}), 4);

    // Paging again doesn't report them a second time.
    await q.window(skip: const {});
    expect(gone, hasLength(1));
  });

  test('a window of only gone ids goes on to the next live ones', () async {
    final ids = await addMany(4);
    ids.sublist(0, 2).forEach(files.removeExternally);
    await index.deleteIds(ids.sublist(0, 2));
    final q = source(flat(ids));
    final w = await q.window(skip: const {}, size: 2);
    expect([for (final f in w.files) f.id], ids.sublist(2));
    expect(w.next, isNull);
  });

  test('group positions count every member, swiped or not', () async {
    final ids = await addMany(10);
    final items = <(String, int?)>[
      for (final id in ids.sublist(0, 2)) (id, 0),
      for (final id in ids.sublist(2, 7)) (id, 1),
      for (final id in ids.sublist(7)) (id, 2),
    ];
    final q = source(items, groupCount: 3);

    final p = q.groupPositionOf(ids[5])!;
    expect((p.group, p.groupCount, p.index, p.groupSize), (2, 3, 4, 5));
    final first = q.groupPositionOf(ids[0])!;
    expect((first.group, first.index, first.groupSize), (1, 1, 2));
    final last = q.groupPositionOf(ids[9])!;
    expect((last.group, last.index, last.groupSize), (3, 3, 3));
    // Not a member (an undone main-deck file).
    expect(q.groupPositionOf('path:/other.jpg'), isNull);
    // A plain list has no group positions.
    expect(source(flat(ids)).groupPositionOf(ids[0]), isNull);
  });

  test('IndexQueueSource with no query is an empty deck', () async {
    await addMany(2);
    final q = IndexQueueSource(SwipeQueueRepository(index), index, null);
    final w = await q.window(skip: const {});
    expect(w.files, isEmpty);
    expect(w.next, isNull);
    expect(await q.remaining(const {}), 0);
  });

  test('IndexQueueSource pages the index query', () async {
    await addMany(3);
    final q = IndexQueueSource(
      SwipeQueueRepository(index),
      index,
      swipeQuery,
      offersNewFiles: false,
    );
    final w = await q.window(skip: const {});
    expect(w.files, hasLength(3));
    expect(await q.remaining({w.files.first.id}), 2);
    expect(q.groupPositionOf(w.files.first.id), isNull);
    expect(q.offersNewFiles, isFalse);
  });
}
