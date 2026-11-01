import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/in_app_jobs.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/db/tables/image_signals_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/similar/data/similar_repository.dart';
import 'package:kfm/features/similar/data/similar_scan_job.dart';

import 'similar_test_utils.dart';

class Ctx implements JobContext {
  @override
  bool shouldStop = false;
}

Future<R> inline<R>(FutureOr<R> Function() fn) async => await fn();

void main() {
  late AppDatabase db;
  late SettingsRepository settings;
  late SimilarRepository repo;
  late List<String> thumbCalls;
  late Map<String, Uint8List?> thumbs;
  late Ctx ctx;
  void Function(String id)? onThumb;

  SimilarScanJob job({int batchSize = 200}) => SimilarScanJob(
    repo: repo,
    settings: settings,
    thumbs: (f, size) async {
      expect(size, 256);
      thumbCalls.add(f.id);
      onThumb?.call(f.id);
      if (f.id.startsWith('throw')) throw StateError('platform');
      return thumbs[f.id];
    },
    compute: inline,
    batchSize: batchSize,
    batchPause: Duration.zero,
  );

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    final queue = DbWriteQueue();
    settings = SettingsRepository(db, queue);
    repo = SimilarRepository(db, queue);
    thumbCalls = [];
    thumbs = {};
    ctx = Ctx();
    onThumb = null;
    await settings.write(AppSettings.similarEnabled, true);
  });
  tearDown(() => db.close());

  Future<Map<String, ImageSignalRow>> signals() async => {
    for (final r in await db.select(db.imageSignals).get()) r.fileId: r,
  };

  Future<List<List<String>>> groupItems() async {
    final groups = await (db.select(
      db.similarGroups,
    )..orderBy([(g) => OrderingTerm.desc(g.sortDateMs)])).get();
    return [
      for (final g in groups)
        [
          for (final i
              in await (db.select(db.similarGroupItems)
                    ..where((i) => i.groupId.equals(g.id))
                    ..orderBy([(i) => OrderingTerm.asc(i.position)]))
                  .get())
            i.fileId,
        ],
    ];
  }

  test('off: never fetches a thumbnail or touches the tables', () async {
    await settings.write(AppSettings.similarEnabled, false);
    await index(db, [photo('a')]);
    await job().run(ctx);
    expect(thumbCalls, isEmpty);
    expect(await signals(), isEmpty);
  });

  test('hashes visible images, groups look-alikes, best (sharpest) first; '
      'unrelated and hours-apart photos stay apart', () async {
    await index(db, [
      photo('burst1'),
      photo('burst2', minute: 1),
      photo('burstBlur', minute: 2),
      photo('other', minute: 3),
      photo('later', minute: 300),
      photo('shot', minute: 1, screenshot: true),
      photo('video', kind: FileKind.video),
    ]);
    thumbs
      ..['burst1'] = fixture('recompressed')
      ..['burst2'] = fixture('base')
      ..['burstBlur'] = fixture('blurred')
      ..['other'] = fixture('unrelated')
      ..['later'] = fixture('base');

    final j = job(batchSize: 2);
    final phases = <SimilarScanPhase>[];
    final sub = j.progressStream.listen((p) => phases.add(p.phase));
    await j.run(ctx);
    await Future<void>.delayed(Duration.zero); // broadcast delivers async
    await sub.cancel();

    expect(thumbCalls, ['later', 'other', 'burstBlur', 'burst2', 'burst1']);
    final rows = await signals();
    expect(rows.keys.toSet(), {
      'burst1',
      'burst2',
      'burstBlur',
      'other',
      'later',
    });
    expect(rows.values.every((r) => r.status == SignalStatus.ok), isTrue);
    expect(rows.values.every((r) => r.algoVersion == 1), isTrue);
    expect(await groupItems(), [
      ['burst2', 'burst1', 'burstBlur'],
    ]);
    expect(await settings.read(AppSettings.similarRegroupNeeded), isFalse);
    expect(phases, contains(SimilarScanPhase.hashing));
    expect(phases, contains(SimilarScanPhase.grouping));
    expect(phases.last, SimilarScanPhase.idle);
    expect(j.progress, SimilarScanProgress.idle);
  });

  test('null thumbnail → unsupported, error / corrupt → failed; '
      'none are retried, a changed file is', () async {
    await index(db, [
      photo('none', minute: 1),
      photo('throw1', minute: 2),
      photo('corrupt', minute: 3),
      photo('fine', minute: 4),
    ]);
    thumbs
      ..['corrupt'] = Uint8List.fromList([0xFF, 0xD8, 1, 2])
      ..['fine'] = fixture('base');
    await job().run(ctx);
    final rows = await signals();
    expect(rows['none']!.status, SignalStatus.unsupported);
    expect(rows['throw1']!.status, SignalStatus.failed);
    expect(rows['corrupt']!.status, SignalStatus.failed);
    expect(rows['fine']!.status, SignalStatus.ok);

    thumbCalls.clear();
    await job().run(ctx);
    expect(thumbCalls, isEmpty);

    await index(db, [photo('corrupt', minute: 3, modifiedMs: 99)]);
    thumbs['corrupt'] = fixture('base');
    await job().run(ctx);
    expect(thumbCalls, ['corrupt']);
    final again = await signals();
    expect(again['corrupt']!.status, SignalStatus.ok);
    expect(again['corrupt']!.fileModifiedAtMs, 99);
  });

  test(
    'stop: writes what was processed, no regroup; the next run resumes',
    () async {
      await index(db, [for (var i = 0; i < 5; i++) photo('p$i', minute: i)]);
      for (var i = 0; i < 5; i++) {
        thumbs['p$i'] = fixture('base');
      }
      onThumb = (id) {
        if (thumbCalls.length == 2) ctx.shouldStop = true;
      };
      await job().run(ctx);
      expect(thumbCalls, ['p4', 'p3']);
      expect((await signals()).keys.toSet(), {'p4', 'p3'});
      expect(await db.select(db.similarGroups).get(), isEmpty);
      expect(await settings.read(AppSettings.similarRegroupNeeded), isTrue);

      onThumb = null;
      ctx = Ctx();
      thumbCalls.clear();
      await job().run(ctx);
      expect(thumbCalls, ['p2', 'p1', 'p0']);
      expect(await groupItems(), hasLength(1));
      expect((await groupItems()).single, hasLength(5));
    },
  );

  test('turning it off mid-run stops before the next batch', () async {
    await index(db, [for (var i = 0; i < 4; i++) photo('p$i', minute: i)]);
    onThumb = (id) {
      if (id == 'p3') {
        settings.write(AppSettings.similarEnabled, false).ignore();
      }
    };
    await job(batchSize: 1).run(ctx);
    expect(thumbCalls, ['p3']);
  });

  test('cleanup removes rows of files gone from the index', () async {
    await index(db, [photo('a')]);
    await repo.writeSignals([
      const SignalWrite(
        fileId: 'gone',
        status: SignalStatus.unsupported,
        fileModifiedAtMs: 0,
      ),
    ]);
    await repo.dismiss(['gone']);
    await job().run(ctx);
    expect((await signals()).keys, ['a']);
    expect(await db.select(db.similarDismissed).get(), isEmpty);
  });

  test('regroupNeeded alone regroups with the current strictness', () async {
    await index(db, [photo('a'), photo('b', minute: 1)]);
    // Distance 8: grouped at normal (10), not at strict (6).
    await repo.writeSignals([
      const SignalWrite(
        fileId: 'a',
        status: SignalStatus.ok,
        dHash: 0,
        blurScore: 100,
        fileModifiedAtMs: 0,
      ),
      const SignalWrite(
        fileId: 'b',
        status: SignalStatus.ok,
        dHash: 0xFF,
        blurScore: 200,
        fileModifiedAtMs: 0,
      ),
    ]);
    await settings.write(AppSettings.similarRegroupNeeded, true);
    await job().run(ctx);
    expect(thumbCalls, isEmpty);
    expect(await groupItems(), [
      ['b', 'a'],
    ]);

    await settings.write(AppSettings.similarStrictness, 'strict');
    await settings.write(AppSettings.similarRegroupNeeded, true);
    await job().run(ctx);
    expect(await groupItems(), isEmpty);
    expect(await settings.read(AppSettings.similarRegroupNeeded), isFalse);
  });

  test('screenshots only with the setting on', () async {
    await index(db, [photo('shot', screenshot: true)]);
    thumbs['shot'] = fixture('base');
    await job().run(ctx);
    expect(thumbCalls, isEmpty);
    await settings.write(AppSettings.similarIncludeScreenshots, true);
    await job().run(ctx);
    expect(thumbCalls, ['shot']);
  });
}
