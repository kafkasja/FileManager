import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/storage/data/storage_totals.dart';
import 'package:kfm/features/storage/domain/storage_category.dart';

const _root = '/storage/emulated/0';
const int _mb = 1024 * 1024;
const _wa = '$_root/Android/media/com.whatsapp/WhatsApp/Media';

void main() {
  late AppDatabase db;
  late MediaIndexDao dao;
  final now = DateTime.utc(2026, 11);

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    dao = MediaIndexDao(db);
  });

  tearDown(() => db.close());

  var n = 0;
  FileRef ref(
    String path,
    int bytes, {
    required FileKind kind,
    bool hidden = false,
  }) {
    final i = path.lastIndexOf('/');
    n++;
    return FileRef(
      id: 'path:$path',
      uri: path,
      name: path.substring(i + 1),
      kind: kind,
      sizeBytes: bytes,
      modifiedAt: DateTime.utc(2025, 1, 1, 0, n),
      folderPath: path.substring(0, i),
      origin: FileOrigin.local,
      hidden: hidden,
    );
  }

  /// Videos 10+20 MB, screenshots 1+2 MB, a 120 MB PDF, WhatsApp (image
  /// 3 MB, video 5 MB, hidden Sent image 4 MB, PDF 1 MB), Downloads (jpg
  /// 2 MB, zip 7 MB).
  Future<void> seed() => dao.upsertBatch([
    ref('$_root/DCIM/Camera/v1.mp4', 10 * _mb, kind: FileKind.video),
    ref('$_root/DCIM/Camera/v2.mp4', 20 * _mb, kind: FileKind.video),
    ref('$_root/Pictures/Screenshots/s1.png', _mb, kind: FileKind.image),
    ref('$_root/Pictures/Screenshots/s2.png', 2 * _mb, kind: FileKind.image),
    ref('$_root/Documents/big.pdf', 120 * _mb, kind: FileKind.document),
    ref('$_wa/WhatsApp Images/w1.jpg', 3 * _mb, kind: FileKind.image),
    ref('$_wa/WhatsApp Video/w2.mp4', 5 * _mb, kind: FileKind.video),
    ref(
      '$_wa/WhatsApp Images/Sent/w3.jpg',
      4 * _mb,
      kind: FileKind.image,
      hidden: true,
    ),
    ref('$_wa/WhatsApp Documents/w4.pdf', _mb, kind: FileKind.document),
    ref('$_root/Download/d1.jpg', 2 * _mb, kind: FileKind.image),
    ref('$_root/Download/d2.zip', 7 * _mb, kind: FileKind.archive),
  ], 1);

  Future<Map<StorageCategoryId, StorageCategoryTotal>> totals({
    required bool access,
    int big = 100 * _mb,
  }) async => {
    for (final c in storageCategories(bigFileBytes: big))
      c.id: await storageCategoryTotal(
        dao,
        c,
        now: now,
        canSeeAllFiles: access,
      ),
  };

  void expectTotal(
    StorageCategoryTotal t, {
    required int count,
    required int bytes,
    required int swipeable,
    bool needsAccess = false,
  }) {
    final id = t.category.id;
    expect(t.fileCount, count, reason: '$id count');
    expect(t.totalBytes, bytes, reason: '$id bytes');
    expect(t.swipeableCount, swipeable, reason: '$id swipeable');
    expect(t.needsAccess, needsAccess, reason: '$id needsAccess');
  }

  test(
    'with All files access: every kind counts; hidden WhatsApp in bytes '
    'but not swipeable; the PDF-only big files row has nothing to swipe',
    () async {
      await seed();
      final t = await totals(access: true);
      expectTotal(
        t[StorageCategoryId.videos]!,
        count: 3,
        bytes: 35 * _mb,
        swipeable: 3,
      );
      expectTotal(
        t[StorageCategoryId.screenshots]!,
        count: 2,
        bytes: 3 * _mb,
        swipeable: 2,
      );
      expectTotal(
        t[StorageCategoryId.bigFiles]!,
        count: 1,
        bytes: 120 * _mb,
        swipeable: 0,
      );
      expectTotal(
        t[StorageCategoryId.whatsapp]!,
        count: 4,
        bytes: 13 * _mb,
        swipeable: 2,
      );
      expectTotal(
        t[StorageCategoryId.downloads]!,
        count: 2,
        bytes: 9 * _mb,
        swipeable: 1,
      );
    },
  );

  test('without access: media only, Downloads needs access', () async {
    await seed();
    final t = await totals(access: false);
    expectTotal(
      t[StorageCategoryId.videos]!,
      count: 3,
      bytes: 35 * _mb,
      swipeable: 3,
    );
    expectTotal(
      t[StorageCategoryId.bigFiles]!,
      count: 0,
      bytes: 0,
      swipeable: 0,
    );
    // The hidden Sent image still counts (rows exist from an earlier scan
    // with access); the PDF doesn't.
    expectTotal(
      t[StorageCategoryId.whatsapp]!,
      count: 3,
      bytes: 12 * _mb,
      swipeable: 2,
    );
    expectTotal(
      t[StorageCategoryId.downloads]!,
      count: 1,
      bytes: 2 * _mb,
      swipeable: 1,
      needsAccess: true,
    );
  });

  test('a lower threshold widens Big files', () async {
    await seed();
    final t = await totals(access: true, big: 5 * _mb);
    // 10 + 20 + 120 + 5 + 7 MB.
    expectTotal(
      t[StorageCategoryId.bigFiles]!,
      count: 5,
      bytes: 162 * _mb,
      swipeable: 3,
    );
  });

  test('a documents-only category: no swipeable files; without access the '
      'totals query is null → needs access', () async {
    await seed();
    const docs = StorageCategory(
      id: StorageCategoryId.bigFiles,
      filter: FileFilter(kinds: {FileKind.document}),
    );
    expect(storageSwipeQuery(docs, now: now), isNull);
    expect(storageTotalsQuery(docs, now: now, canSeeAllFiles: false), isNull);
    expectTotal(
      await storageCategoryTotal(dao, docs, now: now, canSeeAllFiles: true),
      count: 2,
      bytes: 121 * _mb,
      swipeable: 0,
    );
    expectTotal(
      await storageCategoryTotal(dao, docs, now: now, canSeeAllFiles: false),
      count: 0,
      bytes: 0,
      swipeable: 0,
      needsAccess: true,
    );
  });

  test('empty index: zeros, no crash', () async {
    final t = await totals(access: true);
    for (final total in t.values) {
      expectTotal(total, count: 0, bytes: 0, swipeable: 0);
    }
  });

  test('biggest files: top 20 by size, hidden excluded, media only without '
      'access', () async {
    await seed();
    await dao.upsertBatch([
      for (var i = 1; i <= 25; i++)
        ref('$_root/DCIM/Bulk/b$i.jpg', i * 100 * 1024, kind: FileKind.image),
    ], 1);
    final all = await biggestFiles(dao, canSeeAllFiles: true);
    expect(all, hasLength(20));
    final sizes = [for (final f in all) f.sizeBytes];
    expect(sizes, [...sizes]..sort((a, b) => b.compareTo(a)));
    expect(all.first.name, 'big.pdf');
    expect(all.map((f) => f.name), isNot(contains('w3.jpg')));

    final media = await biggestFiles(dao, canSeeAllFiles: false);
    expect(media.first.name, 'v2.mp4');
    expect(
      media.where(
        (f) => f.kind == FileKind.document || f.kind == FileKind.archive,
      ),
      isEmpty,
    );
    expect(media.map((f) => f.name), isNot(contains('w3.jpg')));
  });
}
