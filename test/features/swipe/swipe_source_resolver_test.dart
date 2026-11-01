import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/swipe/data/swipe_source_resolver.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';

import '../../core/files/fake_file_source.dart';

void main() {
  late AppDatabase db;
  late MediaIndexDao index;
  late FakeFileSource files;
  late SwipeSourceResolver resolver;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    index = MediaIndexDao(db);
    files = FakeFileSource();
    resolver = SwipeSourceResolver(
      index,
      files,
      clock: () => DateTime.utc(2026, 11),
    );
  });

  tearDown(() => db.close());

  var n = 0;

  /// Adds a file to the fake and (unless [indexed] is false) the index.
  Future<String> add(String name, {bool indexed = true}) async {
    final f = files.addFile(
      '/s/DCIM/${n++}_$name',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, n),
    );
    if (indexed) await index.upsertBatch([f], 1);
    return f.id;
  }

  Future<List<String>> addMany(int count, String ext) async {
    final refs = [
      for (var i = 0; i < count; i++)
        files.addFile(
          '/s/DCIM/${n++}.$ext',
          modifiedAt: DateTime.utc(2025, 1, 1, 0, 0, n),
        ),
    ];
    await index.upsertBatch(refs, 1);
    return [for (final r in refs) r.id];
  }

  FilesSourceRequest list(List<String> ids, {String title = 'List'}) =>
      FilesSourceRequest(
        origin: SwipeSourceOrigin.search,
        title: title,
        fileIds: ids,
        returnRoute: '/browse/search',
      );

  group('files', () {
    test('keeps the caller order, de-duplicates, drops empty ids', () async {
      final a = await add('a.jpg');
      final b = await add('b.mp4');
      final c = await add('c.jpg');
      final (prepared, result) = await resolver.prepare(
        list([c, a, '', c, b, a]),
      );
      expect(prepared?.kind, SwipeSourceKind.files);
      expect(prepared?.items, [(c, null), (a, null), (b, null)]);
      expect(prepared?.groupCount, isNull);
      expect(prepared?.returnRoute, '/browse/search');
      expect(prepared?.origin, SwipeSourceOrigin.search);
      final opened = result as SwipeSourceOpened;
      expect(opened.files, 3);
      expect(opened.skippedNotMedia, 0);
      expect(opened.skippedMissing, 0);
      expect(opened.truncated, isFalse);
    });

    test('empty list → NotOpened(empty)', () async {
      final (prepared, result) = await resolver.prepare(list(['', '']));
      expect(prepared, isNull);
      expect(
        (result as SwipeSourceNotOpened).problem,
        SwipeSourceProblem.empty,
      );
    });

    test('only PDFs → NotOpened(noMedia)', () async {
      final ids = [await add('a.pdf'), await add('b.pdf')];
      final (prepared, result) = await resolver.prepare(list(ids));
      expect(prepared, isNull);
      expect(
        (result as SwipeSourceNotOpened).problem,
        SwipeSourceProblem.noMedia,
      );
    });

    test('only missing ids → NotOpened(empty)', () async {
      final (_, result) = await resolver.prepare(list(['path:/gone.jpg']));
      expect(
        (result as SwipeSourceNotOpened).problem,
        SwipeSourceProblem.empty,
      );
    });

    test('counts non-media and missing; stat finds unindexed ids', () async {
      final photo = await add('a.jpg');
      final pdf = await add('b.pdf');
      final unindexed = await add('c.jpg', indexed: false);
      final (prepared, result) = await resolver.prepare(
        list([pdf, 'path:/gone.jpg', photo, unindexed]),
      );
      expect(prepared?.items, [(photo, null), (unindexed, null)]);
      final opened = result as SwipeSourceOpened;
      expect(opened.files, 2);
      expect(opened.skippedNotMedia, 1);
      expect(opened.skippedMissing, 1);
    });

    test('at most 500 stat lookups; the rest count as missing', () async {
      final ids = [
        for (var i = 0; i < 520; i++) await add('u$i.jpg', indexed: false),
      ];
      final (prepared, result) = await resolver.prepare(list(ids));
      expect(prepared?.items.map((e) => e.$1), ids.take(500));
      expect((result as SwipeSourceOpened).skippedMissing, 20);
    });

    test('12,000 ids → the first 10,000, truncated', () async {
      final ids = await addMany(12000, 'jpg');
      final (prepared, result) = await resolver.prepare(list(ids));
      expect(prepared?.items, hasLength(kMaxSourceItems));
      expect(prepared?.items.last.$1, ids[kMaxSourceItems - 1]);
      final opened = result as SwipeSourceOpened;
      expect(opened.files, kMaxSourceItems);
      expect(opened.truncated, isTrue);
      expect(opened.skippedMissing, 0);
    });

    test('the title is trimmed and cut to 80 with …', () async {
      final a = await add('a.jpg');
      var (prepared, _) = await resolver.prepare(list([a], title: '  Hi  '));
      expect(prepared?.title, 'Hi');
      (prepared, _) = await resolver.prepare(list([a], title: 'x' * 100));
      expect(prepared?.title, '${'x' * 79}…');
      expect(prepared?.title.length, 80);
    });
  });

  group('groups', () {
    test('keeps group order, drops emptied groups, renumbers', () async {
      final a = await add('a.jpg');
      final b = await add('b.jpg');
      final pdf = await add('c.pdf');
      final c = await add('d.mp4');
      final (prepared, result) = await resolver.prepare(
        GroupsSourceRequest(
          origin: SwipeSourceOrigin.similar,
          title: 'Duplicates',
          groups: [
            [a, b],
            [pdf],
            const [],
            [c, a],
          ],
        ),
      );
      expect(prepared?.kind, SwipeSourceKind.groups);
      expect(prepared?.items, [(a, 0), (b, 0), (c, 1)]);
      expect(prepared?.groupCount, 2);
      final opened = result as SwipeSourceOpened;
      expect(opened.files, 3);
      expect(opened.skippedNotMedia, 1);
    });

    test('no groups → NotOpened(empty)', () async {
      final (_, result) = await resolver.prepare(
        const GroupsSourceRequest(
          origin: SwipeSourceOrigin.similar,
          title: 'Duplicates',
          groups: [],
        ),
      );
      expect(
        (result as SwipeSourceNotOpened).problem,
        SwipeSourceProblem.empty,
      );
    });
  });

  group('filter', () {
    FilterSourceRequest req(FileFilter f) => FilterSourceRequest(
      origin: SwipeSourceOrigin.storage,
      title: 'Clean up',
      filter: f,
      returnRoute: '/storage',
    );

    test('matches → Opened(files: count) with the filter JSON', () async {
      await add('a.jpg');
      await add('b.mp4');
      await add('c.pdf');
      const filter = FileFilter(kinds: {FileKind.image});
      final (prepared, result) = await resolver.prepare(req(filter));
      expect(prepared?.kind, SwipeSourceKind.filter);
      expect(prepared?.items, isEmpty);
      expect(prepared?.returnRoute, '/storage');
      expect(
        FileFilter.fromJson(
          jsonDecode(prepared!.filterJson!) as Map<String, Object?>,
        ),
        filter,
      );
      expect((result as SwipeSourceOpened).files, 1);
    });

    test('no filter = all photos and videos (swipe base)', () async {
      await add('a.jpg');
      await add('b.mp4');
      await add('c.pdf');
      final (_, result) = await resolver.prepare(req(FileFilter.none));
      expect((result as SwipeSourceOpened).files, 2);
    });

    test('invalid (min > max) → NotOpened(invalidFilter)', () async {
      await add('a.jpg');
      final (prepared, result) = await resolver.prepare(
        req(const FileFilter(minSizeBytes: 10, maxSizeBytes: 5)),
      );
      expect(prepared, isNull);
      expect(
        (result as SwipeSourceNotOpened).problem,
        SwipeSourceProblem.invalidFilter,
      );
    });

    test('0 matches or outside swipe kinds → NotOpened(noMatches)', () async {
      await add('a.pdf');
      for (final f in [
        const FileFilter(kinds: {FileKind.image}),
        const FileFilter(kinds: {FileKind.document}),
      ]) {
        final (prepared, result) = await resolver.prepare(req(f));
        expect(prepared, isNull);
        expect(
          (result as SwipeSourceNotOpened).problem,
          SwipeSourceProblem.noMatches,
        );
      }
    });
  });
}
