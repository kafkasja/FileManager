import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/filters/data/filter_query.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/tags/data/favorites_repository.dart';
import 'package:kfm/features/tags/data/tag_repository.dart';

FileRef _ref(
  String id, {
  FileKind kind = FileKind.image,
  String folder = '/s/DCIM/Camera',
  String? name,
  int sizeMb = 1,
  DateTime? date,
}) => FileRef(
  id: id,
  uri: 'content://$id',
  name: name ?? '$id.${kind == FileKind.video ? 'mp4' : 'jpg'}',
  kind: kind,
  sizeBytes: sizeMb << 20,
  modifiedAt: date ?? DateTime(2026, 5, 10),
  folderPath: folder,
  origin: FileOrigin.local,
);

void main() {
  late AppDatabase db;
  late MediaIndexDao dao;
  final now = DateTime(2026, 6, 1, 9); // the 1st of the month

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = MediaIndexDao(db);
    await dao.upsertBatch([
      _ref('shot', folder: '/s/Pictures/Screenshots'),
      _ref('named', folder: '/s/Download', name: 'Screenshot_1.png'),
      _ref('photo'),
      _ref('bigvid', kind: FileKind.video, sizeMb: 80),
      _ref('smallvid', kind: FileKind.video, sizeMb: 5),
      _ref('today', date: DateTime(2026, 6, 1, 8)),
      _ref('lastmonth', date: DateTime(2026, 5, 31, 23)),
      _ref('doc', kind: FileKind.document, folder: '/s/Download'),
    ], 1);
  });
  tearDown(() => db.close());

  Future<Set<String>> ids(FileFilter f) async {
    final q = toIndexQuery(f, now: now);
    if (q == null) return {};
    final page = await dao.page(q, limit: 100);
    return {for (final r in page.items) r.id};
  }

  test('no filter = every image and video', () async {
    expect(await ids(FileFilter.none), {
      'shot',
      'named',
      'photo',
      'bigvid',
      'smallvid',
      'today',
      'lastmonth',
    });
  });

  test('screenshots only', () async {
    expect(await ids(const FileFilter(screenshotsOnly: true)), {
      'shot',
      'named',
    });
  });

  test('videos over 50 MB', () async {
    expect(
      await ids(
        const FileFilter(kinds: {FileKind.video}, minSizeBytes: 50 << 20),
      ),
      {'bigvid'},
    );
  });

  test('this month on the 1st keeps only files from that day', () async {
    expect(await ids(const FileFilter(date: DateThisMonth())), {'today'});
  });

  test('a date range is inclusive of both days', () async {
    expect(
      await ids(
        FileFilter(
          date: DateRange(DateTime(2026, 5, 31), DateTime(2026, 5, 31)),
        ),
      ),
      {'lastmonth'},
    );
  });

  test('one folder', () async {
    expect(
      await ids(const FileFilter(folderPaths: {'/s/Pictures/Screenshots'})),
      {'shot'},
    );
  });

  test('tagged / untagged / specific tags / favorites', () async {
    final tags = TagRepository(db);
    final cats = await tags.create('Cats', 1);
    final dogs = await tags.create('Dogs', 2);
    await db.transaction(() async {
      await tags.addInTransaction('photo', cats.id);
      await tags.addInTransaction('bigvid', dogs.id);
      await FavoritesRepository(db).addInTransaction('shot');
    });
    expect(await ids(const FileFilter(tagMode: TagFilterMode.tagged)), {
      'photo',
      'bigvid',
    });
    expect(
      await ids(const FileFilter(tagMode: TagFilterMode.untagged)),
      isNot(contains('photo')),
    );
    expect(
      await ids(FileFilter(tagMode: TagFilterMode.hasTags, tagIds: {dogs.id})),
      {'bigvid'},
    );
    expect(await ids(const FileFilter(favoritesOnly: true)), {'shot'});
  });

  test('documents in swipe mode match nothing (never "all")', () async {
    expect(
      toIndexQuery(const FileFilter(kinds: {FileKind.document}), now: now),
      isNull,
    );
  });

  test('countAmong counts only matching ids', () async {
    final q = toIndexQuery(const FileFilter(screenshotsOnly: true), now: now)!;
    expect(await dao.countAmong(q, ['shot', 'photo', 'gone']), 1);
    expect(await dao.countAmong(IndexQuery.all, []), 0);
  });
}
