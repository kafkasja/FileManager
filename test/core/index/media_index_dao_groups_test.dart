import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';

final _base = DateTime.utc(2026, 10);

FileRef file(
  String id, {
  String folder = '/storage/emulated/0/DCIM/Camera',
  FileKind kind = FileKind.image,
  int minute = 0,
}) => FileRef(
  id: id,
  uri: 'content://$id',
  name: '$id.${kind == FileKind.document ? 'pdf' : 'jpg'}',
  kind: kind,
  sizeBytes: 100,
  modifiedAt: _base,
  takenAt: _base.add(Duration(minutes: minute)),
  folderPath: folder,
  origin: FileOrigin.local,
);

void main() {
  late AppDatabase db;
  late MediaIndexDao dao;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    dao = MediaIndexDao(db);
    await dao.upsertBatch([
      file('cam', minute: 1),
      file('selfieFolder', folder: '/storage/emulated/0/DCIM/Selfies'),
      file('selfieUpper', folder: '/storage/emulated/0/Pictures/SELFIES'),
      file('notSelfie', folder: '/storage/emulated/0/Pictures/Selfies old'),
      file('front', minute: 2),
      file(
        'videoInSelfies',
        folder: '/storage/emulated/0/DCIM/Selfies',
        kind: FileKind.video,
      ),
      file(
        'doc',
        folder: '/storage/emulated/0/Download',
        kind: FileKind.document,
      ),
    ], 1);
    await db.customStatement(
      'INSERT INTO media_locations (file_id, file_modified_at_ms, '
      'front_camera, location_readable, read_at_ms) VALUES '
      "('front', 1, 1, 1, 1), ('cam', 1, 0, 1, 1)",
    );
  });
  tearDown(() => db.close());

  Future<Set<String>> ids(IndexQuery q) async => {
    for (final f in (await dao.page(q)).items) f.id,
  };

  test('selfies: folder …/Selfies (any case) or EXIF front camera', () async {
    const q = IndexQuery(selfiesOnly: true);
    expect(await ids(q), {'selfieFolder', 'selfieUpper', 'front'});
    expect(await dao.count(q), 3);
  });

  test('documents: kind document; hidden without All files access', () async {
    const q = IndexQuery(documentsGroup: true);
    expect(await ids(q), {'doc'});
    // visible() limits to media kinds: no documents without access.
    expect(await ids(q.visible(canSeeAllFiles: false)!), isEmpty);
  });

  test('documents (C3): plus images labeled "document"', () async {
    await db.customStatement(
      'INSERT INTO ai_labels (file_id, label, confidence) VALUES '
      "('cam', 'document', 0.6), ('front', 'cat', 0.9), "
      "('videoInSelfies', 'document', 0.9)",
    );
    const q = IndexQuery(documentsGroup: true);
    // Videos never match (images only); a label alone isn't enough.
    expect(await ids(q), {'doc', 'cam'});
    expect(await dao.count(q), 2);
    // Without All files access the labeled photos still show.
    expect(await ids(q.visible(canSeeAllFiles: false)!), {'cam'});
  });

  test("smartGroupId: only that group's members", () async {
    await db.customStatement(
      'INSERT INTO smart_groups (id, kind, rank, start_at_ms, end_at_ms, '
      "cover_file_id, item_count) VALUES (1, 'trip', 0, 1, 2, 'cam', 2), "
      "(2, 'place', 1, 1, 2, 'doc', 1)",
    );
    await db.customStatement(
      'INSERT INTO smart_group_items (group_id, file_id) VALUES '
      "(1, 'cam'), (1, 'front'), (2, 'doc')",
    );
    const q = IndexQuery(smartGroupId: 1);
    expect(await ids(q), {'cam', 'front'});
    // Keyset paging works on it like on any query.
    final first = await dao.page(q, limit: 1);
    final second = await dao.page(q, after: first.next, limit: 1);
    expect({first.items.single.id, second.items.single.id}, {'cam', 'front'});
  });

  test('the new fields take part in equality', () {
    const a = IndexQuery(smartGroupId: 1);
    expect(a, const IndexQuery(smartGroupId: 1));
    expect(a == const IndexQuery(smartGroupId: 2), isFalse);
    expect(
      const IndexQuery(selfiesOnly: true).hashCode,
      const IndexQuery(selfiesOnly: true).hashCode,
    );
    expect(a.copyWith(smartGroupId: () => null), IndexQuery.all);
    expect(
      IndexQuery.all.copyWith(documentsGroup: true),
      const IndexQuery(documentsGroup: true),
    );
  });
}
