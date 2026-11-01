import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/index_query_json.dart';
import 'package:kfm/core/index/media_index_dao.dart';

final _base = DateTime.utc(2026, 10);

FileRef file(String id, {FileKind kind = FileKind.image, int minute = 0}) =>
    FileRef(
      id: id,
      uri: 'content://$id',
      name: '$id.${kind == FileKind.video ? 'mp4' : 'jpg'}',
      kind: kind,
      sizeBytes: 100,
      modifiedAt: _base,
      takenAt: _base.add(Duration(minutes: minute)),
      folderPath: '/storage/emulated/0/DCIM/Camera',
      origin: FileOrigin.local,
    );

/// TASK-C4: content search terms (`labelTerms`, `blurryOnly`).
void main() {
  late AppDatabase db;
  late MediaIndexDao dao;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    dao = MediaIndexDao(db);
  });
  tearDown(() => db.close());

  Future<void> labels(Map<String, List<String>> byFile) => db.customStatement(
    'INSERT INTO ai_labels (file_id, label, confidence) VALUES '
    '${[for (final MapEntry(:key, :value) in byFile.entries)
      for (final l in value) "('$key', '$l', 0.9)"].join(', ')}',
  );

  Future<Set<String>> ids(IndexQuery q) async => {
    for (final f in (await dao.page(q)).items) f.id,
  };

  group('labelTerms', () {
    setUp(() async {
      await dao.upsertBatch([
        file('cat', minute: 1),
        file('dog', minute: 2),
        file('blueBeach', minute: 3),
        file('beach', minute: 4),
        file('blue', minute: 5),
        file('catVideo', kind: FileKind.video, minute: 6),
      ], 1);
      await labels({
        'cat': ['cat', 'pet', 'animal'],
        'dog': ['dog', 'pet', 'animal'],
        'blueBeach': ['beach', 'color:blue', 'sea'],
        'beach': ['beach'],
        'blue': ['color:blue'],
        // Videos aren't labeled by C3; a stray row must not show it.
        'catVideo': ['cat'],
        // Orphan: the file is gone from the index (deleted/trashed).
        'gone': ['cat', 'beach', 'color:blue'],
      });
    });

    test('one term: files with that label (images only)', () async {
      const q = IndexQuery(
        labelTerms: [
          {'cat'},
        ],
      );
      expect(await ids(q), {'cat'});
      expect(await dao.count(q), 1);
    });

    test("labels inside a term are OR'ed (expansions)", () async {
      const q = IndexQuery(
        labelTerms: [
          {'animal', 'cat', 'dog'},
        ],
      );
      expect(await ids(q), {'cat', 'dog'});
    });

    test("terms are AND'ed: blue beach = both labels", () async {
      const q = IndexQuery(
        labelTerms: [
          {'color:blue'},
          {'beach'},
        ],
      );
      expect(await ids(q), {'blueBeach'});
      expect(await dao.count(q), 1);
    });

    test('orphan labels never show (rows come from media_index)', () async {
      const q = IndexQuery(
        labelTerms: [
          {'cat'},
          {'beach'},
        ],
      );
      expect(await ids(q), isEmpty);
    });

    test('combines with a name search (cat + name word)', () async {
      const q = IndexQuery(
        nameContains: 'do',
        labelTerms: [
          {'pet'},
        ],
      );
      expect(await ids(q), {'dog'});
    });

    test('an unknown label matches nothing (no error)', () async {
      const q = IndexQuery(
        labelTerms: [
          {'unicorn'},
        ],
      );
      expect(await ids(q), isEmpty);
    });

    test('labels work without All files access (images are media)', () {
      const q = IndexQuery(
        labelTerms: [
          {'cat'},
        ],
      );
      expect(q.visible(canSeeAllFiles: false), isNotNull);
    });
  });

  group('blurryOnly', () {
    setUp(() async {
      await dao.upsertBatch([
        file('sharp', minute: 1),
        file('blurry', minute: 2),
        file('failed', minute: 3),
        file('unscanned', minute: 4),
      ], 1);
      await db.customStatement(
        'INSERT INTO image_signals (file_id, status, d_hash, blur_score, '
        'file_modified_at_ms, algo_version) VALUES '
        "('sharp', 'ok', 1, 500.0, 1, 1), ('blurry', 'ok', 2, 20.0, 1, 1), "
        "('failed', 'failed', NULL, NULL, 1, 1), "
        "('gone', 'ok', 3, 1.0, 1, 1)",
      );
    });

    test("C2's predicate with the passed threshold", () async {
      expect(
        await ids(const IndexQuery(blurryOnly: true, blurThreshold: 100)),
        {'blurry'},
      );
      expect(
        await ids(const IndexQuery(blurryOnly: true, blurThreshold: 1000)),
        {'blurry', 'sharp'},
      );
    });

    test('no threshold = nothing (never a guess)', () async {
      expect(await ids(const IndexQuery(blurryOnly: true)), isEmpty);
    });
  });

  test('keyset paging over 10k label results: no gaps, no duplicates', () async {
    const n = 10000;
    await dao.upsertBatch([
      for (var i = 0; i < n; i++) file('f$i', minute: i % 500),
    ], 1);
    for (var i = 0; i < n; i += 1000) {
      await db.customStatement(
        'INSERT INTO ai_labels (file_id, label, confidence) VALUES '
        '${[for (var j = i; j < i + 1000; j++) "('f$j', 'sky', 0.5)"].join(', ')}',
      );
    }
    const q = IndexQuery(
      labelTerms: [
        {'sky'},
      ],
    );
    final seen = <String>[];
    IndexCursor? after;
    do {
      final page = await dao.page(q, after: after, limit: 300);
      seen.addAll(page.items.map((f) => f.id));
      after = page.next;
    } while (after != null);
    expect(seen, hasLength(n));
    expect(seen.toSet(), hasLength(n));
  });

  group('IndexQuery', () {
    test('labelTerms / blurryOnly take part in ==, hashCode and copyWith', () {
      const a = IndexQuery(
        labelTerms: [
          {'cat', 'pet'},
          {'color:blue'},
        ],
      );
      const b = IndexQuery(
        labelTerms: [
          {'pet', 'cat'},
          {'color:blue'},
        ],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      // Order of terms matters for equality only as a list (AND is
      // commutative, but the parser keeps typed order).
      expect(
        a ==
            const IndexQuery(
              labelTerms: [
                {'cat', 'pet'},
              ],
            ),
        isFalse,
      );
      expect(IndexQuery.all.copyWith(labelTerms: a.labelTerms), a);
      expect(
        IndexQuery.all.copyWith(blurryOnly: true, blurThreshold: () => 100),
        const IndexQuery(blurryOnly: true, blurThreshold: 100),
      );
      expect(
        const IndexQuery(blurryOnly: true, blurThreshold: 100) ==
            const IndexQuery(blurryOnly: true, blurThreshold: 90),
        isFalse,
      );
      expect(a.hasContentTerms, isTrue);
      expect(IndexQuery.all.hasContentTerms, isFalse);
    });

    test('recents JSON round-trips labelTerms and blurryOnly', () {
      const q = IndexQuery(
        nameContains: 'trip',
        labelTerms: [
          {'animal', 'cat', 'dog'},
          {'color:blue'},
        ],
        blurryOnly: true,
        blurThreshold: 120,
      );
      final back = indexQueryFromJson(indexQueryToJson(q));
      expect(back, q);
      // Old recents (no content keys) still load.
      expect(
        indexQueryFromJson(const {'v': 1, 'name': 'x'}),
        const IndexQuery(nameContains: 'x'),
      );
      expect(
        () => indexQueryFromJson(const {
          'v': 1,
          'labels': ['cat'],
        }),
        throwsFormatException,
      );
    });
  });

  // TASK-C4 step 5: 50k images × 10 labels (500k ai_labels rows).
  test(
    'benchmark: 2-term query, first page, 500k labels',
    () async {
      const images = 50000;
      const perImage = 10;
      // 33 labels like C3's vocabulary; a few common ones (colors, sky).
      final vocab = [
        'cat',
        'dog',
        'pet',
        'animal',
        'bird',
        'insect',
        'person',
        'crowd',
        'food',
        'fruit',
        'vegetable',
        'dessert',
        'beach',
        'sea',
        'lake',
        'mountain',
        'vehicle',
        'car',
        'bus',
        'truck',
        'bicycle',
        'motorcycle',
        'document',
        'color:red',
        'color:orange',
        'color:yellow',
        'color:green',
        'color:blue',
        'color:purple',
        'color:pink',
        'color:brown',
        'color:black',
        'color:white',
      ];
      final sw = Stopwatch()..start();
      for (var i = 0; i < images; i += 5000) {
        await dao.upsertBatch([
          for (var j = i; j < i + 5000; j++) file('img$j', minute: j),
        ], 1);
      }
      for (var i = 0; i < images; i += 500) {
        final rows = <String>[];
        for (var j = i; j < i + 500; j++) {
          // 10 distinct labels per image (step 3 over 33 labels), plus two
          // rare ones (1% and 0.5% of images) for the worst case: a
          // selective AND that has to walk most of media_index.
          final seen = <String>{
            for (var k = 0; k < perImage; k++)
              vocab[(j * 7 + k * 3) % vocab.length],
            if (j % 100 == 0) 'rare1',
            if (j % 200 == 0) 'rare2',
          };
          rows.addAll([for (final l in seen) "('img$j', '$l', 0.8)"]);
        }
        await db.customStatement(
          'INSERT INTO ai_labels (file_id, label, confidence) VALUES '
          '${rows.join(', ')}',
        );
      }
      final total = await db
          .customSelect('SELECT COUNT(*) AS c FROM ai_labels')
          .getSingle();
      final setup = sw.elapsedMilliseconds;

      Future<(int, int, int, int)> time(IndexQuery q) async {
        // Warm-up (statement prep), then the measured run.
        await dao.page(q);
        final t = Stopwatch()..start();
        final page = await dao.page(q);
        final first = t.elapsedMilliseconds;
        t.reset();
        final count = await dao.count(q);
        return (first, page.items.length, count, t.elapsedMilliseconds);
      }

      const common = IndexQuery(
        labelTerms: [
          {'color:blue'},
          {'beach'},
        ],
      );
      const rare = IndexQuery(
        labelTerms: [
          {'cat'},
          {'bus'},
        ],
      );
      const expanded = IndexQuery(
        labelTerms: [
          {'animal', 'cat', 'dog', 'bird', 'insect', 'pet'},
          {'color:white'},
        ],
      );
      const selective = IndexQuery(
        labelTerms: [
          {'rare1'},
          {'rare2'},
        ],
      );
      final results = {
        'rare1 rare2 (0.5%)': await time(selective),
        'blue beach': await time(common),
        'cat bus': await time(rare),
        'animal(6) white': await time(expanded),
      };

      // EXPLAIN QUERY PLAN of the page query (same SQL as dao.page).
      final select = dao.select(db.mediaIndex)
        ..where((t) => dao.whereFor(t, common))
        ..orderBy([
          (t) => OrderingTerm.desc(t.sortDateMs),
          (t) => OrderingTerm.desc(t.id),
        ])
        ..limit(200);
      final ctx = select.constructQuery();
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN ${ctx.sql}',
            variables: [for (final v in ctx.boundVariables) Variable(v)],
          )
          .get();
      // ignore: avoid_print, benchmark output for CHANGES.md
      print(
        'C4 benchmark: ${total.read<int>('c')} ai_labels rows, setup '
        '${setup}ms\n'
        '${[for (final MapEntry(:key, :value) in results.entries) '  $key: first page ${value.$1} ms (${value.$2} rows); count ${value.$3} in ${value.$4} ms'].join('\n')}\n'
        'EXPLAIN QUERY PLAN:\n'
        '${[for (final r in plan) '  ${r.read<String>('detail')}'].join('\n')}',
      );
      for (final MapEntry(:key, :value) in results.entries) {
        // Plan target is 200 ms on a phone; desktop CI has headroom.
        expect(value.$1, lessThan(200), reason: key);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
    // Opt-in (KFM_BENCH=1): its 500k inserts slow other timing tests
    // running in parallel.
    skip: Platform.environment['KFM_BENCH'] == null
        ? 'benchmark; run with KFM_BENCH=1'
        : false,
  );
}
