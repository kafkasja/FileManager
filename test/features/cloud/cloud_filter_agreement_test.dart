import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/index_query_json.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/cloud/data/cloud_items_repository.dart';
import 'package:kfm/features/cloud/data/cloud_keywords.dart';
import 'package:kfm/features/cloud/domain/cloud_state.dart';
import 'package:kfm/features/filters/data/filter_query.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';

import 'cloud_test_seed.dart';

/// 2026-10-01 12:34:56.789 UTC: a non-zero ms part catches a seconds-vs-ms
/// mix-up.
final _modified = DateTime.utc(2026, 10, 1, 12, 34, 56, 789);

FileRef _file(String id, {int size = 100, int minute = 0}) => FileRef(
  id: id,
  uri: 'content://$id',
  name: '$id.jpg',
  kind: FileKind.image,
  sizeBytes: size,
  modifiedAt: _modified,
  takenAt: _modified.add(Duration(minutes: minute)),
  folderPath: '/storage/emulated/0/DCIM/Camera',
  origin: FileOrigin.local,
);

void main() {
  late AppDatabase db;
  late MediaIndexDao dao;
  late CloudItemsRepository items;
  late List<FileRef> files;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    dao = MediaIndexDao(db);
    items = CloudItemsRepository(db, DbWriteQueue());
    files = [
      for (final (i, id) in [
        'plain', // never uploaded
        'onCloud',
        'twoDests', // one unchanged, one changed
        'sizeChanged',
        'timeChanged',
        'olderVersion',
        'queued',
        'uploading',
        'failed',
        'verified',
        'removedDest',
      ].indexed)
        _file(id, minute: i),
    ];
    await dao.upsertBatch(files, 1);
    final drive = await seedDestination(db, 'Drive');
    final box = await seedDestination(db, 'Box');
    final gone = await seedDestination(db, 'Gone');
    await (db.update(
      db.cloudDestinations,
    )..where((d) => d.id.equals(gone))).write(
      CloudDestinationsCompanion(removedAt: Value(DateTime.utc(2026))),
    );
    FileRef f(String id) => files.firstWhere((x) => x.id == id);
    final ms = _modified.millisecondsSinceEpoch;
    await seedUpload(db, f('onCloud'), drive);
    await seedUpload(db, f('twoDests'), drive, modifiedAtMs: ms - 1);
    await seedUpload(db, f('twoDests'), box);
    await seedUpload(db, f('sizeChanged'), drive, sizeBytes: 99);
    await seedUpload(db, f('timeChanged'), drive, modifiedAtMs: ms - 1000);
    await seedUpload(db, f('olderVersion'), drive, modifiedAtMs: ms + 5000);
    await seedUpload(db, f('queued'), drive, status: CloudItemStatus.queued);
    await seedUpload(
      db,
      f('uploading'),
      drive,
      status: CloudItemStatus.uploading,
    );
    await seedUpload(db, f('failed'), drive, status: CloudItemStatus.failed);
    await seedUpload(
      db,
      f('verified'),
      drive,
      status: CloudItemStatus.verified,
    );
    await seedUpload(db, f('removedDest'), gone);
  });
  tearDown(() => db.close());

  Future<Set<String>> ids(IndexQuery q) async => {
    for (final f in (await dao.page(q, limit: 100)).items) f.id,
  };

  test('badge ⇔ filter: on cloud exactly where the badge says so', () async {
    final facts = await items.uploadFactsFor([for (final f in files) f.id]);
    final indexed = (await dao.page(IndexQuery.all, limit: 100)).items;
    final badges = {
      for (final f in indexed)
        f.id: cloudBadgeFor(
          uploads: facts[f.id] ?? const [],
          localSizeBytes: f.sizeBytes,
          localModifiedAtMs: f.modifiedAt.millisecondsSinceEpoch,
        ),
    };
    final onCloud = await ids(const IndexQuery(onCloud: true));
    final notOnCloud = await ids(const IndexQuery(onCloud: false));
    expect(onCloud, {'onCloud', 'twoDests', 'verified', 'removedDest'});
    for (final MapEntry(:key, :value) in badges.entries) {
      expect(onCloud.contains(key), value == CloudBadge.onCloud, reason: key);
    }
    expect(notOnCloud, {for (final f in files) f.id}.difference(onCloud));
    expect(badges['sizeChanged'], CloudBadge.changedSinceUpload);
    expect(badges['olderVersion'], CloudBadge.changedSinceUpload);
    expect(badges['failed'], CloudBadge.none);
    expect(badges['queued'], CloudBadge.none);
    expect(await dao.count(const IndexQuery(onCloud: true)), 4);
  });

  test('FileFilter.cloud and the cloud keywords give the same query', () {
    final now = DateTime(2026, 11);
    expect(
      toIndexQuery(
        const FileFilter(cloud: CloudFilterMode.onCloud),
        now: now,
      )?.onCloud,
      isTrue,
    );
    expect(
      toIndexQuery(
        const FileFilter(cloud: CloudFilterMode.notOnCloud),
        now: now,
      )?.onCloud,
      isFalse,
    );
    expect(toIndexQuery(FileFilter.none, now: now)?.onCloud, isNull);
    expect(cloudKeywords.resolve('on')!.apply(IndexQuery.all).onCloud, isTrue);
    expect(
      cloudKeywords.resolve('off')!.apply(IndexQuery.all).onCloud,
      isFalse,
    );
    expect(cloudKeywords.resolve('maybe'), isNull);
  });

  test('IndexQuery JSON keeps onCloud', () {
    for (final v in [true, false, null]) {
      final q = IndexQuery(onCloud: v);
      expect(indexQueryFromJson(indexQueryToJson(q)), q);
    }
  });

  group('FileFilter JSON', () {
    test('cloud round-trips as v2; without it v1 as before', () {
      const f = FileFilter(cloud: CloudFilterMode.notOnCloud);
      expect(f.toJson(), {'v': 2, 'cloud': 'notOnCloud'});
      expect(FileFilter.fromJson(f.toJson()), f);
      expect(FileFilter.none.toJson(), {'v': 1});
    });

    test('old v1 JSON decodes with cloud = any; v3 is rejected', () {
      expect(
        FileFilter.fromJson(const {'v': 1, 'favorites': true}).cloud,
        CloudFilterMode.any,
      );
      expect(() => FileFilter.fromJson(const {'v': 3}), throwsFormatException);
    });
  });
}
