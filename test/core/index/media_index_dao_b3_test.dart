import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/index/source_rule.dart';

const _root = '/storage/emulated/0';
const _camera = '$_root/DCIM/Camera';
const _whatsapp = '$_root/Android/media/com.whatsapp/WhatsApp/Media/Img';

FileRef _f(
  String path, {
  required int modifiedMs,
  int? takenMs,
  FileKind kind = FileKind.image,
}) {
  final slash = path.lastIndexOf('/');
  return FileRef(
    id: 'path:$path',
    uri: path,
    name: path.substring(slash + 1),
    kind: kind,
    sizeBytes: 1,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(modifiedMs, isUtc: true),
    takenAt: takenMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(takenMs, isUtc: true),
    folderPath: path.substring(0, slash),
    origin: FileOrigin.local,
  );
}

void main() {
  late AppDatabase db;
  late MediaIndexDao dao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = MediaIndexDao(db);
    await dao.upsertBatch([
      // takenAt wins over a later modifiedAt.
      _f('$_camera/c.jpg', takenMs: 1000, modifiedMs: 900000),
      // No takenAt: modifiedAt is the capture time.
      _f('$_camera/a.jpg', modifiedMs: 3000),
      // Same time as b.jpg: id breaks the tie.
      _f('$_camera/b.jpg', takenMs: 3000, modifiedMs: 3000),
      _f(
        '$_camera/v.mp4',
        takenMs: 2000,
        modifiedMs: 2000,
        kind: FileKind.video,
      ),
      _f('$_whatsapp/w.jpg', modifiedMs: 1500),
    ], 1);
  });
  tearDown(() => db.close());

  test('ordered by sort_date_ms, then id; takenAt ?? modifiedAt', () async {
    expect(await dao.captureTimes(IndexQuery.all), [
      ('path:$_camera/c.jpg', 1000),
      ('path:$_whatsapp/w.jpg', 1500),
      ('path:$_camera/v.mp4', 2000),
      ('path:$_camera/a.jpg', 3000),
      ('path:$_camera/b.jpg', 3000),
    ]);
  });

  test("ignores the query's own sort", () async {
    final times = await dao.captureTimes(
      const IndexQuery(sort: FileSort(FileSortField.name)),
    );
    expect(times.map((r) => r.$2), [1000, 1500, 2000, 3000, 3000]);
  });

  test('respects kinds', () async {
    expect(await dao.captureTimes(const IndexQuery(kinds: {FileKind.video})), [
      ('path:$_camera/v.mp4', 2000),
    ]);
  });

  test('respects source and folder filters', () async {
    expect(
      await dao.captureTimes(
        const IndexQuery(sources: {SourceBucket.whatsapp}),
      ),
      [('path:$_whatsapp/w.jpg', 1500)],
    );
    final camera = await dao.captureTimes(
      const IndexQuery(folderPath: _camera, kinds: {FileKind.image}),
    );
    expect(camera.map((r) => r.$1), [
      'path:$_camera/c.jpg',
      'path:$_camera/a.jpg',
      'path:$_camera/b.jpg',
    ]);
  });
}
