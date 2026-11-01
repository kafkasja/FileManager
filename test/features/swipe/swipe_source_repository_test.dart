import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/swipe/data/swipe_source_repository.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';

void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late SwipeSourceRepository repo;
  late int sessionId;
  final now = DateTime.utc(2026, 11);

  Future<int> session({bool ended = false}) => db
      .into(db.sessions)
      .insert(
        SessionsCompanion.insert(
          // A second open session needs another preset (P6 index).
          presetId: Value(ended ? 99 : null),
          layout: '{}',
          startedAt: now,
          updatedAt: now,
          isActive: !ended,
          endedAt: Value(ended ? now : null),
        ),
      );

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    repo = SwipeSourceRepository(db, queue, clock: () => now);
    sessionId = await session();
  });

  tearDown(() async {
    await queue.close();
    await db.close();
  });

  PreparedSource files(List<String> ids, {String title = 'Some files'}) =>
      PreparedSource(
        kind: SwipeSourceKind.files,
        origin: SwipeSourceOrigin.browse,
        title: title,
        items: [for (final id in ids) (id, null)],
        returnRoute: '/browse',
      );

  Future<List<SwipeSourceRow>> rows() => (db.select(
    db.swipeSources,
  )..orderBy([(s) => OrderingTerm.asc(s.id)])).get();

  test('open stores the row and items in order; openFor reads it', () async {
    final id = await repo.open(
      sessionId: sessionId,
      source: files(['c', 'a', 'b']),
      lastSeq: 7,
    );

    final open = await repo.openFor(sessionId);
    expect(open?.id, id);
    expect(open?.kind, SwipeSourceKind.files);
    expect(open?.origin, SwipeSourceOrigin.browse);
    expect(open?.title, 'Some files');
    expect(open?.itemCount, 3);
    expect(open?.openedAfterSeq, 7);
    expect(open?.returnRoute, '/browse');
    expect(open?.filter, isNull);
    expect(await repo.items(id), [('c', null), ('a', null), ('b', null)]);
  });

  test('groups keep their index and count', () async {
    final id = await repo.open(
      sessionId: sessionId,
      source: const PreparedSource(
        kind: SwipeSourceKind.groups,
        origin: SwipeSourceOrigin.similar,
        title: 'Duplicates',
        items: [('a', 0), ('b', 0), ('c', 1)],
        groupCount: 2,
      ),
      lastSeq: 0,
    );
    expect((await repo.openFor(sessionId))?.groupCount, 2);
    expect(await repo.items(id), [('a', 0), ('b', 0), ('c', 1)]);
  });

  test('more than one chunk of items (1,200) keeps every position', () async {
    final ids = [for (var i = 0; i < 1200; i++) 'f$i'];
    final id = await repo.open(
      sessionId: sessionId,
      source: files(ids),
      lastSeq: 0,
    );
    expect((await repo.items(id)).map((e) => e.$1), ids);
  });

  test('opening a second source replaces the first', () async {
    final first = await repo.open(
      sessionId: sessionId,
      source: files(['a', 'b']),
      lastSeq: 3,
    );
    final second = await repo.open(
      sessionId: sessionId,
      source: files(['c']),
      lastSeq: 5,
    );

    final all = await rows();
    expect(all.map((r) => r.id), [first, second]);
    expect(all.first.closedAtSeq, 5);
    expect(all.first.closedAt, isNotNull);
    expect(all.last.closedAt, isNull);
    expect(await repo.items(first), isEmpty);
    expect(await repo.items(second), [('c', null)]);
    expect((await repo.openFor(sessionId))?.id, second);
  });

  test('close sets closedAt/seq and drops items; mainFloor = max', () async {
    expect(await repo.mainFloor(sessionId), isNull);
    final a = await repo.open(
      sessionId: sessionId,
      source: files(['a']),
      lastSeq: 2,
    );
    await repo.close(a, lastSeq: 9);
    expect(await repo.openFor(sessionId), isNull);
    expect(await repo.items(a), isEmpty);
    expect((await rows()).single.closedAtSeq, 9);
    expect(await repo.mainFloor(sessionId), 9);

    final b = await repo.open(
      sessionId: sessionId,
      source: files(['b']),
      lastSeq: 9,
    );
    // An open source doesn't count.
    expect(await repo.mainFloor(sessionId), 9);
    await repo.close(b, lastSeq: 12);
    expect(await repo.mainFloor(sessionId), 12);
    expect(await repo.mainFloor(sessionId + 1), isNull);
  });

  test('recordOutside: closed outside row; skipped when nothing', () async {
    await repo.recordOutside(
      sessionId: sessionId,
      origin: SwipeSourceOrigin.similar,
      title: 'Clean duplicates',
      fromSeq: 4,
      toSeq: 4,
    );
    expect(await rows(), isEmpty);

    await repo.recordOutside(
      sessionId: sessionId,
      origin: SwipeSourceOrigin.similar,
      title: 'Clean duplicates',
      fromSeq: 4,
      toSeq: 7,
    );
    final row = (await rows()).single;
    expect(row.kind, SwipeSourceKind.outside);
    expect(row.openedAfterSeq, 4);
    expect(row.closedAtSeq, 7);
    expect(row.closedAt?.isAtSameMomentAs(now), isTrue);
    expect(await repo.openFor(sessionId), isNull);
    expect(await repo.mainFloor(sessionId), 7);
  });

  test('dropItems removes only the given ids of that source', () async {
    final id = await repo.open(
      sessionId: sessionId,
      source: files(['a', 'b', 'c']),
      lastSeq: 0,
    );
    await repo.dropItems(id, ['b', 'zzz']);
    expect(await repo.items(id), [('a', null), ('c', null)]);
  });

  test('prune: sources of ended sessions and items of closed ones', () async {
    final ended = await session(ended: true);
    final old = await repo.open(
      sessionId: ended,
      source: files(['x']),
      lastSeq: 0,
    );
    final live = await repo.open(
      sessionId: sessionId,
      source: files(['a']),
      lastSeq: 0,
    );
    // A crash between closing and deleting the items.
    await db.customStatement(
      'UPDATE swipe_sources SET closed_at = 1, closed_at_seq = 0 WHERE id = ?',
      [live],
    );

    await repo.prune();

    final all = await rows();
    expect(all.map((r) => r.id), [live]);
    expect(await repo.items(old), isEmpty);
    expect(await repo.items(live), isEmpty);
    expect(await db.select(db.swipeSourceItems).get(), isEmpty);
  });

  group('filter sources', () {
    Future<int> filterRow(String json) => repo.open(
      sessionId: sessionId,
      source: PreparedSource(
        kind: SwipeSourceKind.filter,
        origin: SwipeSourceOrigin.storage,
        title: 'Screenshots',
        filterJson: json,
      ),
      lastSeq: 6,
    );

    test('a valid filter is decoded', () async {
      const filter = FileFilter(kinds: {FileKind.image}, screenshotsOnly: true);
      await filterRow(jsonEncode(filter.toJson()));
      final open = await repo.openFor(sessionId);
      expect(open?.filter, filter);
      expect(open?.itemCount, 0);
    });

    for (final (what, json) in [
      ('corrupt JSON', '{not json'),
      ('not a map', '[1]'),
      ('bad types', '{"v": 1, "kinds": ["nope"]}'),
      (
        'an invalid filter (min > max)',
        jsonEncode(
          const FileFilter(minSizeBytes: 10, maxSizeBytes: 5).toJson(),
        ),
      ),
    ]) {
      test('$what closes the row and returns null', () async {
        await filterRow(json);
        expect(await repo.openFor(sessionId), isNull);
        final row = (await rows()).single;
        expect(row.closedAtSeq, 6);
        expect(row.closedAt, isNotNull);
      });
    }
  });

  test('a failed write reaches the caller (rule 8)', () async {
    // Empty title breaks the 1–80 length check.
    await expectLater(
      repo.open(
        sessionId: sessionId,
        source: files(['a'], title: ''),
        lastSeq: 0,
      ),
      throwsA(anything),
    );
    expect(await rows(), isEmpty);
    expect(await db.select(db.swipeSourceItems).get(), isEmpty);
  });
}
