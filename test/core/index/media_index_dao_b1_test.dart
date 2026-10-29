import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/index/source_rule.dart';

const _root = '/storage/emulated/0';

FileRef _f(
  String path, {
  FileKind kind = FileKind.image,
  bool hidden = false,
  int? width,
  int? height,
}) {
  final slash = path.lastIndexOf('/');
  return FileRef(
    id: 'path:$path',
    uri: path,
    name: path.substring(slash + 1),
    kind: kind,
    sizeBytes: 1,
    modifiedAt: DateTime.utc(2024),
    folderPath: path.substring(0, slash),
    origin: FileOrigin.local,
    hidden: hidden,
    width: width,
    height: height,
  );
}

void main() {
  late AppDatabase db;
  late MediaIndexDao dao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = MediaIndexDao(db);
    await dao.upsertBatch([
      _f('$_root/DCIM/Camera/a.jpg', width: 4000, height: 3000),
      _f('$_root/DCIM/Camera/wide.jpg', width: 8000, height: 2000),
      _f('$_root/DCIM/Camera/PANO_1.jpg'),
      _f('$_root/DCIM/Tapo/t.jpg'),
      _f('$_root/DCIM/loose.jpg'),
      _f(
        '$_root/Android/media/com.whatsapp/WhatsApp/Media/Docs/r.PDF',
        kind: FileKind.document,
      ),
      _f('$_root/Android/media/com.whatsapp/WhatsApp/Media/Img/w.jpg'),
      _f('$_root/Download/x.zip', kind: FileKind.archive),
      _f('$_root/Notes/.secret.txt', kind: FileKind.document, hidden: true),
      _f('$_root/.cache/c.jpg', hidden: true),
      _f('/storage/1A2B-3C4D/DCIM/Camera/sd.jpg'),
    ], 1);
  });
  tearDown(() => db.close());

  Future<Set<String>> names(IndexQuery q) async =>
      (await dao.page(q)).items.map((f) => f.name).toSet();

  test('hidden rows are excluded by default, shown on request', () async {
    expect(await names(IndexQuery.all), isNot(contains('c.jpg')));
    expect(await dao.count(IndexQuery.all), 9);
    expect(await names(const IndexQuery(hidden: HiddenFilter.only)), {
      '.secret.txt',
      'c.jpg',
    });
    expect(await dao.count(const IndexQuery(hidden: HiddenFilter.include)), 11);
    expect((await dao.byId('path:$_root/.cache/c.jpg'))!.hidden, isTrue);
  });

  test('sources, combined with kinds', () async {
    expect(await names(const IndexQuery(sources: {SourceBucket.whatsapp})), {
      'r.PDF',
      'w.jpg',
    });
    expect(
      await names(
        const IndexQuery(
          sources: {SourceBucket.whatsapp},
          kinds: {FileKind.document},
        ),
      ),
      {'r.PDF'},
    );
    expect(await names(const IndexQuery(sources: {SourceBucket.camera})), {
      'a.jpg',
      'wide.jpg',
      'PANO_1.jpg',
      'sd.jpg',
    });
  });

  test('extensions are lower case without the dot', () async {
    expect(await names(const IndexQuery(extensions: {'pdf'})), {'r.PDF'});
  });

  test('panoramas: PANO_ names or 2:1', () async {
    expect(await names(const IndexQuery(panoramaOnly: true)), {
      'wide.jpg',
      'PANO_1.jpg',
    });
  });

  test('folders: volumes, then children with subfolder counts', () async {
    final roots = await dao.folders(scope: IndexQuery.all);
    expect(roots, [
      const FolderEntry(_root, 8),
      const FolderEntry('/storage/1A2B-3C4D', 1),
    ]);
    final top = await dao.folders(parent: _root, scope: IndexQuery.all);
    expect(top.map((e) => (e.name, e.fileCount)), [
      ('Android', 2),
      ('DCIM', 5),
      ('Download', 1),
    ]);
    // The type scope applies; the scope's own folder is ignored.
    final images = await dao.folders(
      parent: '$_root/DCIM',
      scope: const IndexQuery(
        kinds: {FileKind.image},
        folderPath: '$_root/Download',
      ),
    );
    expect(images.map((e) => (e.name, e.fileCount)), [
      ('Camera', 3),
      ('Tapo', 1),
    ]);
    // Hidden folders only while hidden files are shown.
    final withHidden = await dao.folders(
      parent: _root,
      scope: const IndexQuery(hidden: HiddenFilter.include),
    );
    expect(withHidden.map((e) => e.name), contains('.cache'));
  });

  test('folderSummaries without scope lists every folder (P2)', () async {
    expect(await dao.folderSummaries(), hasLength(9));
  });

  test('copyWith clears nullable fields', () {
    const q = IndexQuery(folderPath: '/x', minSizeBytes: 5, tagged: true);
    final cleared = q.copyWith(
      folderPath: () => null,
      minSizeBytes: () => null,
      tagged: () => null,
    );
    expect(cleared, IndexQuery.all);
    expect(q.copyWith(kinds: {FileKind.image}).folderPath, '/x');
  });

  test('hidden-only is invisible without All files access', () {
    expect(
      const IndexQuery(hidden: HiddenFilter.only)
          .visible(canSeeAllFiles: false),
      isNull,
    );
  });

  test('50,000 rows: Browse queries stay fast', () async {
    const folders = [
      'DCIM/Camera',
      'DCIM/Screenshots',
      'Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images',
      'Download',
      'DCIM/Tapo',
      'Pictures/Insta',
      '.hiddenapp',
    ];
    for (var start = 0; start < 50000; start += 5000) {
      await dao.upsertBatch([
        for (var i = start; i < start + 5000; i++)
          _f(
            '$_root/${folders[i % folders.length]}/f$i.jpg',
            hidden: i % folders.length == 6,
            width: 4000,
            height: i % 50 == 0 ? 1000 : 3000,
          ),
      ], 1);
    }
    final timings = <String, int>{};
    Future<void> time(String what, Future<Object?> Function() run) async {
      final sw = Stopwatch()..start();
      await run();
      timings[what] = sw.elapsedMilliseconds;
    }

    await time('all', () => dao.page(IndexQuery.all));
    await time(
      'whatsapp',
      () => dao.page(const IndexQuery(sources: {SourceBucket.whatsapp})),
    );
    await time(
      'hidden',
      () => dao.page(const IndexQuery(hidden: HiddenFilter.only)),
    );
    await time(
      'panoramas',
      () => dao.page(const IndexQuery(panoramaOnly: true)),
    );
    await time(
      'folders',
      () => dao.folders(parent: '$_root/DCIM', scope: IndexQuery.all),
    );
    await time('count', () => dao.count(IndexQuery.all));
    // Timing is reported in the test log for CHANGES.md.
    // ignore: avoid_print
    print('50k Browse: $timings');
    for (final MapEntry(:key, :value) in timings.entries) {
      // Plan target 50 ms on device; generous bound for CI hosts.
      expect(value, lessThan(250), reason: '$key ${value}ms');
    }
  });
}
