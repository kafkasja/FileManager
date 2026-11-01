import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';

FileRef _file(int i, String name) => FileRef(
  id: 'f:$i',
  uri: 'content://x/$i',
  name: name,
  kind: FileKind.document,
  sizeBytes: 100,
  modifiedAt: DateTime.utc(2024).add(Duration(minutes: i)),
  folderPath: '/s/Download',
  origin: FileOrigin.local,
);

void main() {
  late AppDatabase db;
  late MediaIndexDao dao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = MediaIndexDao(db);
    await dao.upsertBatch([
      _file(1, 'Q3_report_final_2024.pdf'),
      _file(2, 'report_2023.pdf'),
      _file(3, '2024 taxes.pdf'),
      _file(4, 'sale 100% off.txt'),
      _file(5, 'sale 1000 off.txt'),
      _file(6, 'a_b.txt'),
      _file(7, 'axb.txt'),
      _file(8, 'Ölüdeniz.jpg'),
      _file(9, r'back\slash.txt'),
    ], 1);
  });
  tearDown(() => db.close());

  Future<Set<String>> ids(String name) async => {
    for (final f in (await dao.page(IndexQuery(nameContains: name))).items)
      f.id,
  };

  test('multi-word: every word must match, any order', () async {
    expect(await ids('report 2024'), {'f:1'});
    expect(await ids('2024 REPORT'), {'f:1'});
    expect(await ids('report'), {'f:1', 'f:2'});
    expect(await ids('2024'), {'f:1', 'f:3'});
    expect(await ids('report 2025'), isEmpty);
  });

  test('extra whitespace is ignored', () async {
    expect(await ids('  report \t  2024 '), {'f:1'});
    expect(await ids('   '), hasLength(9));
  });

  test('% and _ are literal', () async {
    expect(await ids('100%'), {'f:4'});
    expect(await ids('a_b'), {'f:6'});
    expect(await ids(r'\'), {'f:9'});
  });

  test('ö matches Ö (toLowerCase like name_lower)', () async {
    expect(await ids('ölü'), {'f:8'});
    expect(await ids('ÖLÜ'), {'f:8'});
  });

  test('count agrees with page', () async {
    expect(await dao.count(const IndexQuery(nameContains: 'report 2024')), 1);
  });

  // Step 7 measurement (plan §8): LIKE '%x%' is a full scan. Gate on a
  // mid-range device: p95 > 60 ms → FTS5 trigram. Desktop numbers here.
  test('50,000 rows: name search p50/p95', () async {
    const stems = ['IMG_', 'VID_', 'Screenshot_', 'invoice_', 'report_'];
    const exts = ['jpg', 'mp4', 'png', 'pdf', 'docx'];
    for (var start = 0; start < 50000; start += 5000) {
      await dao.upsertBatch([
        for (var i = start; i < start + 5000; i++)
          FileRef(
            id: 'b:$i',
            uri: 'content://b/$i',
            name:
                '${stems[i % 5]}2024${(i % 12 + 1).toString().padLeft(2, '0')}'
                '_$i.${exts[i % 5]}',
            kind: i % 5 == 1 ? FileKind.video : FileKind.image,
            sizeBytes: i,
            modifiedAt: DateTime.utc(2024).add(Duration(minutes: i)),
            folderPath: '/storage/emulated/0/DCIM/F${i % 40}',
            origin: FileOrigin.local,
          ),
      ], 2);
    }
    final results = <String, String>{};
    Future<void> bench(String what, IndexQuery q, {bool count = false}) async {
      final ms = <double>[];
      for (var run = 0; run < 25; run++) {
        final sw = Stopwatch()..start();
        if (count) {
          await dao.count(q);
        } else {
          await dao.page(q);
        }
        ms.add(sw.elapsedMicroseconds / 1000);
      }
      ms
        ..removeRange(0, 5) // warm-up
        ..sort();
      final p50 = ms[ms.length ~/ 2];
      final p95 = ms[(ms.length * 0.95).ceil() - 1];
      results[what] =
          'p50 ${p50.toStringAsFixed(1)} / p95 ${p95.toStringAsFixed(1)} ms';
      // Generous bound for CI hosts; the real gate is on a device.
      expect(p95, lessThan(250), reason: '$what p95 ${p95}ms');
    }

    // Rare word: scans every row, returns few.
    await bench('rare', const IndexQuery(nameContains: '49999'));
    // Common word: the first page fills early.
    await bench('common', const IndexQuery(nameContains: 'invoice'));
    // No match at all: the worst case.
    await bench('none', const IndexQuery(nameContains: 'zzzz'));
    await bench('two words', const IndexQuery(nameContains: 'report 202403'));
    await bench(
      'word + ext',
      const IndexQuery(nameContains: 'img', extensions: {'jpg'}),
    );
    await bench(
      'count common',
      const IndexQuery(nameContains: 'invoice'),
      count: true,
    );
    // Timing is reported in the test log for CHANGES.md.
    // ignore: avoid_print
    print('50k name search: $results');
  });
}
