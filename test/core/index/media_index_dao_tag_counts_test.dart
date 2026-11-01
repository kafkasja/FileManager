import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/tags/data/tag_repository.dart';
import 'package:kfm/features/tags/domain/tag.dart';

FileRef _file(String id, FileKind kind) => FileRef(
  id: id,
  uri: 'content://x/$id',
  name: '$id.${kind == FileKind.document ? 'pdf' : 'jpg'}',
  kind: kind,
  sizeBytes: 100,
  modifiedAt: DateTime.utc(2024),
  folderPath: '/s/DCIM',
  origin: FileOrigin.local,
);

void main() {
  late AppDatabase db;
  late MediaIndexDao dao;
  late TagRepository tags;
  late Tag holiday;
  late Tag work;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = MediaIndexDao(db);
    tags = TagRepository(db);
    await dao.upsertBatch([
      _file('img1', FileKind.image),
      _file('img2', FileKind.image),
      _file('doc1', FileKind.document),
    ], 1);
    holiday = await tags.create('Holiday', kTagColors.first);
    work = await tags.create('Work', kTagColors.first);
    await tags.addToFiles(holiday.id, ['img1', 'img2', 'doc1', 'gone']);
    await tags.addToFiles(work.id, ['doc1']);
  });
  tearDown(() => db.close());

  Stream<Map<int, int>> counts({required bool all}) =>
      dao.watchTagCounts(IndexQuery.all.visible(canSeeAllFiles: all));

  test('counts visible indexed files per tag', () async {
    // 'gone' isn't in media_index: not counted.
    expect(await counts(all: true).first, {holiday.id: 3, work.id: 1});
  });

  test('without All files access, documents are not counted', () async {
    expect(await counts(all: false).first, {holiday.id: 2});
  });

  test('null scope emits an empty map', () async {
    expect(await dao.watchTagCounts(null).first, isEmpty);
  });

  test('updates live when a tag is added', () async {
    final stream = counts(all: true);
    final expectation = expectLater(
      stream,
      emitsInOrder([
        {holiday.id: 3, work.id: 1},
        {holiday.id: 3, work.id: 2},
      ]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tags.addToFiles(work.id, ['img1']);
    await expectation;
  });

  test('updates live when an indexed file disappears', () async {
    final stream = counts(all: true);
    final expectation = expectLater(
      stream,
      emitsInOrder([
        {holiday.id: 3, work.id: 1},
        {holiday.id: 2},
      ]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await dao.deleteIds(['doc1']);
    await expectation;
  });
}
