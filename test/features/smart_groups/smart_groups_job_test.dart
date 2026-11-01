import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/in_app_jobs.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/db/tables/smart_groups_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/smart_groups/data/exif_reader.dart';
import 'package:kfm/features/smart_groups/data/place_namer.dart';
import 'package:kfm/features/smart_groups/data/smart_groups_job.dart';
import 'package:kfm/features/smart_groups/data/smart_groups_repository.dart';
import 'package:kfm/features/smart_groups/domain/geo.dart';

class Ctx implements JobContext {
  @override
  bool shouldStop = false;
}

Future<R> inline<R>(FutureOr<R> Function() fn) async => await fn();

const home = GeoPoint(52.37, 4.90);
const paris = GeoPoint(48.85, 2.35);

class FakeExif implements ExifReader {
  final Map<String, GeoPoint> gps = {};
  final Set<String> front = {};
  final Set<String> failing = {};
  final List<String> reads = [];
  bool granted = true;
  void Function()? onRead;

  @override
  Future<List<ExifFacts>> read(List<String> fileIds) async {
    reads.addAll(fileIds);
    onRead?.call();
    return [
      for (final id in fileIds)
        if (failing.contains(id))
          ExifFacts(fileId: id, error: 'boom')
        else
          ExifFacts(
            fileId: id,
            lat: granted ? gps[id]?.lat : null,
            lng: granted ? gps[id]?.lng : null,
            frontCamera: front.contains(id),
            locationReadable: granted,
          ),
    ];
  }
}

class FakeNamer implements PlaceNamer {
  final List<GeoPoint> calls = [];
  String? answer = 'Paris';

  @override
  Future<String?> nameFor(double lat, double lng) async {
    calls.add(GeoPoint(lat, lng));
    return answer;
  }
}

void main() {
  late AppDatabase db;
  late SettingsRepository settings;
  late SmartGroupsRepository repo;
  late MediaIndexDao dao;
  late FakeExif exif;
  late FakeNamer namer;
  late Ctx ctx;
  var granted = true;
  var paths = false;
  var now = DateTime.utc(2026, 11);

  SmartGroupsJob job({int batchSize = 200}) => SmartGroupsJob(
    repo: repo,
    settings: settings,
    exif: exif,
    namer: namer,
    locationGranted: () async => granted,
    canReadPaths: () async => paths,
    compute: inline,
    batchSize: batchSize,
    batchPause: Duration.zero,
    clock: () => now,
  );

  FileRef photo(String id, DateTime at, {int modifiedMs = 1}) => FileRef(
    id: id,
    uri: 'content://$id',
    name: '$id.jpg',
    kind: FileKind.image,
    sizeBytes: 100,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(modifiedMs, isUtc: true),
    takenAt: at,
    folderPath: '/storage/emulated/0/DCIM/Camera',
    origin: FileOrigin.local,
  );

  /// [n] photos at [at] over [days] days from [start], 9:00 onwards.
  Future<List<String>> shoot(
    String prefix,
    DateTime start,
    int n, {
    int days = 1,
    GeoPoint? at,
  }) async {
    final perDay = (n / days).ceil();
    final files = [
      for (var i = 0; i < n; i++)
        photo(
          'ms:$prefix${i.toString().padLeft(3, '0')}',
          start.add(
            Duration(
              days: i ~/ perDay,
              hours: 9,
              minutes: (i % perDay) * (720 ~/ perDay),
            ),
          ),
        ),
    ];
    await dao.upsertBatch(files, 1);
    if (at != null) {
      for (final (i, f) in files.indexed) {
        // Spread ~ 100 m around the spot.
        exif.gps[f.id] = GeoPoint(at.lat + (i % 5) * 0.0002, at.lng);
      }
    }
    return [for (final f in files) f.id];
  }

  Future<List<SmartGroupRow>> groups(SmartGroupKind kind) =>
      (db.select(db.smartGroups)
            ..where((g) => g.kind.equalsValue(kind))
            ..orderBy([(g) => OrderingTerm.asc(g.id)]))
          .get();

  Future<Set<String>> members(int groupId) async => {
    for (final i in await (db.select(
      db.smartGroupItems,
    )..where((i) => i.groupId.equals(groupId))).get())
      i.fileId,
  };

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    final queue = DbWriteQueue();
    settings = SettingsRepository(db, queue);
    repo = SmartGroupsRepository(db, queue);
    dao = MediaIndexDao(db);
    exif = FakeExif();
    namer = FakeNamer();
    ctx = Ctx();
    granted = true;
    paths = false;
    now = DateTime.utc(2026, 11);
    await settings.write(AppSettings.smartGroupsActivated, true);
  });
  tearDown(() => db.close());

  test('does nothing until Groups was opened once', () async {
    await settings.write(AppSettings.smartGroupsActivated, false);
    await shoot('h', DateTime(2026, 6), 20, at: home);
    await job().run(ctx);
    expect(exif.reads, isEmpty);
    expect(await db.select(db.mediaLocations).get(), isEmpty);
    expect(await db.select(db.smartGroups).get(), isEmpty);
  });

  test('builds a Paris place and trip; home is hidden from Places', () async {
    await shoot('h', DateTime(2026, 6), 40, at: home);
    final trip = await shoot(
      'p',
      DateTime(2026, 7, 10),
      21,
      days: 3,
      at: paris,
    );
    await job().run(ctx);

    final places = await groups(SmartGroupKind.place);
    expect(places, hasLength(1));
    expect(places.single.rank, 1);
    expect(places.single.centerLat, closeTo(paris.lat, 0.01));
    expect(await members(places.single.id), trip.toSet());
    final trips = await groups(SmartGroupKind.trip);
    expect(trips, hasLength(1));
    expect(await members(trips.single.id), trip.toSet());
    expect(trips.single.coverFileId, trip.last);
    expect(DateTime.fromMillisecondsSinceEpoch(trips.single.startAtMs).day, 10);
    expect(DateTime.fromMillisecondsSinceEpoch(trips.single.endAtMs).day, 12);
    // Setting off (default): no lookups.
    expect(namer.calls, isEmpty);
    expect(places.single.placeName, isNull);
  });

  test('a photo without GPS is read once (read_at_ms unchanged)', () async {
    await shoot('n', DateTime(2026, 6), 3);
    await job().run(ctx);
    expect(exif.reads, hasLength(3));
    final before = await db.select(db.mediaLocations).get();
    expect(before.every((r) => r.lat == null), isTrue);
    now = now.add(const Duration(hours: 1));
    await job().run(ctx);
    expect(exif.reads, hasLength(3));
    final after = await db.select(db.mediaLocations).get();
    expect(after.map((r) => r.readAtMs), before.map((r) => r.readAtMs));
  });

  test('an edited photo is read again', () async {
    final at = DateTime(2026, 6);
    await dao.upsertBatch([photo('ms:1', at)], 1);
    await job().run(ctx);
    await dao.upsertBatch([photo('ms:1', at, modifiedMs: 99)], 1);
    await job().run(ctx);
    expect(exif.reads, ['ms:1', 'ms:1']);
    final row = await db.select(db.mediaLocations).getSingle();
    expect(row.fileModifiedAtMs, 99);
  });

  test('denied: no places, trips by date; a grant re-reads GPS', () async {
    granted = false;
    exif.granted = false;
    await shoot('h', DateTime(2026, 6), 40, at: home);
    await shoot('p', DateTime(2026, 7, 10), 21, days: 3, at: paris);
    await job().run(ctx);
    expect(await groups(SmartGroupKind.place), isEmpty);
    // The 3-day run qualifies by the days rule.
    expect(await groups(SmartGroupKind.trip), hasLength(1));
    expect(exif.reads, hasLength(61));

    granted = true;
    exif.granted = true;
    await job().run(ctx);
    expect(exif.reads, hasLength(122));
    expect(await groups(SmartGroupKind.place), hasLength(1));
  });

  test('a renamed trip keeps its name after 10 more photos', () async {
    await shoot('h', DateTime(2026, 6), 40, at: home);
    await shoot('p', DateTime(2026, 7, 10), 15, days: 3, at: paris);
    await job().run(ctx);
    final trip = (await groups(SmartGroupKind.trip)).single;
    await repo.rename(trip.id, 'Paris weekend');

    // 10 more photos on the same days (ids sort after the first 15).
    final more = [
      for (var i = 0; i < 10; i++)
        photo('ms:q$i', DateTime(2026, 7, 11, 10, i * 5)),
    ];
    await dao.upsertBatch(more, 1);
    for (final f in more) {
      exif.gps[f.id] = paris;
    }
    await job().run(ctx);
    final after = (await groups(SmartGroupKind.trip)).single;
    expect(after.id, trip.id);
    expect(after.userTitle, 'Paris weekend');
    expect(after.itemCount, 25);
  });

  test('deleted photos leave their groups; the cover moves on', () async {
    await shoot('h', DateTime(2026, 6), 40, at: home);
    final trip = await shoot(
      'p',
      DateTime(2026, 7, 10),
      21,
      days: 3,
      at: paris,
    );
    await job().run(ctx);
    final before = (await groups(SmartGroupKind.trip)).single;
    expect(before.coverFileId, trip.last);

    await dao.deleteIds([trip.last]);
    await repo.deleteOrphans();
    final after = (await groups(SmartGroupKind.trip)).single;
    expect(after.coverFileId, trip[trip.length - 2]);
    expect(after.itemCount, 20);
    expect(await members(after.id), isNot(contains(trip.last)));
    expect(
      await (db.select(
        db.mediaLocations,
      )..where((l) => l.fileId.equals(trip.last))).get(),
      isEmpty,
    );

    await dao.deleteIds(trip);
    await repo.deleteOrphans();
    expect(await groups(SmartGroupKind.trip), isEmpty);
  });

  test('unchanged input skips the recompute (signature)', () async {
    await shoot('h', DateTime(2026, 6), 40, at: home);
    await shoot('p', DateTime(2026, 7, 10), 21, days: 3, at: paris);
    await job().run(ctx);
    expect(
      await settings.read(AppSettings.smartGroupsInputSignature),
      isNotEmpty,
    );
    await db.customStatement('DELETE FROM smart_groups');
    await job().run(ctx);
    expect(await db.select(db.smartGroups).get(), isEmpty);
  });

  test('online names: once per group, failures not retried', () async {
    await settings.write(AppSettings.smartGroupsOnlinePlaceNames, true);
    await shoot('h', DateTime(2026, 6), 40, at: home);
    await shoot('p', DateTime(2026, 7, 10), 21, days: 3, at: paris);
    namer.answer = null;
    await job().run(ctx);
    expect(namer.calls, hasLength(1));
    var place = (await groups(SmartGroupKind.place)).single;
    expect(place.placeName, isNull);
    expect(place.geocodedAtMs, isNotNull);
    await job().run(ctx);
    expect(namer.calls, hasLength(1));

    // Turned on again: failures are retried once.
    await repo.resetFailedLookups();
    namer.answer = 'Paris';
    await job().run(ctx);
    expect(namer.calls, hasLength(2));
    place = (await groups(SmartGroupKind.place)).single;
    expect(place.placeName, 'Paris');

    // A user title wins and survives.
    await repo.rename(place.id, 'Holiday');
    await job().run(ctx);
    place = (await groups(SmartGroupKind.place)).single;
    expect(place.userTitle, 'Holiday');
    expect(place.placeName, 'Paris');
  });

  test('read errors are counted and not retried every run', () async {
    await shoot('e', DateTime(2026, 6), 2);
    exif.failing.add('ms:e000');
    final j = job();
    await j.run(ctx);
    expect(j.progress.failedFiles, 1);
    await j.run(ctx);
    expect(exif.reads, hasLength(2));
  });

  test('path: images are skipped without All files access', () async {
    await dao.upsertBatch([photo('path:/sdcard/x.jpg', DateTime(2026, 6))], 1);
    await job().run(ctx);
    expect(exif.reads, isEmpty);
    paths = true;
    await job().run(ctx);
    expect(exif.reads, ['path:/sdcard/x.jpg']);
  });

  test('shouldStop ends the EXIF pass between batches', () async {
    await shoot('s', DateTime(2026, 6), 10);
    final j = job(batchSize: 4);
    exif.onRead = () => ctx.shouldStop = true;
    // Stops after the first batch; a later run finishes the rest.
    await j.run(ctx);
    expect(exif.reads, hasLength(4));
    ctx.shouldStop = false;
    exif.onRead = null;
    await j.run(ctx);
    expect(exif.reads.toSet(), hasLength(10));
  });
}
