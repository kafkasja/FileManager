import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/in_app_jobs.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/db/tables/ai_labels_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/ai_labels/data/ai_labels_repository.dart';
import 'package:kfm/features/ai_labels/data/ai_model_store.dart';
import 'package:kfm/features/ai_labels/data/label_worker.dart';
import 'package:kfm/features/ai_labels/data/labeling_job.dart';
import 'package:kfm/features/ai_labels/domain/label_map.dart';

import '../similar/similar_test_utils.dart';

class Ctx implements JobContext {
  @override
  bool shouldStop = false;
}

/// Labels by file id (the fake thumbnail carries the id as UTF-16 codes).
class FakeWorker implements LabelWorker {
  new(this.labelsFor);

  final List<LabelScore> Function(String id) labelsFor;
  bool closed = false;

  @override
  Future<List<LabelScore>> label(Uint8List jpeg) async {
    final id = String.fromCharCodes(jpeg);
    if (id.startsWith('crash')) throw const LabelWorkerCrashed('boom');
    if (id.startsWith('bad')) throw const LabelFailed('undecodable');
    return labelsFor(id);
  }

  @override
  Future<void> close() async => closed = true;
}

void main() {
  late AppDatabase db;
  late SettingsRepository settings;
  late AiLabelsRepository repo;
  late Ctx ctx;
  late List<String> thumbCalls;
  late int workersStarted;
  late List<FakeWorker> workers;
  late bool modelsPresent;
  late bool batteryOk;
  late bool supported;
  late DateTime now;
  void Function(String id)? onThumb;

  final models = AiModelBytes(classifier: Uint8List(1), detector: Uint8List(1));

  LabelingJob job({int batchSize = 50}) => LabelingJob(
    repo: repo,
    settings: settings,
    loadModels: () async => modelsPresent ? models : null,
    startWorker: (m) async {
      expect(m, same(models));
      workersStarted++;
      final w = FakeWorker((id) => [('cat', 0.9), ('color:blue', 0.4)]);
      workers.add(w);
      return w;
    },
    supported: () async => supported,
    batteryOk: () async => batteryOk,
    thumbs: (f, size) async {
      expect(size, LabelingJob.thumbSize);
      thumbCalls.add(f.id);
      onThumb?.call(f.id);
      if (f.id.startsWith('nothumb')) return null;
      return Uint8List.fromList(f.id.codeUnits);
    },
    batchSize: batchSize,
    batchPause: Duration.zero,
  );

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    final queue = DbWriteQueue();
    settings = SettingsRepository(db, queue);
    now = DateTime.utc(2026, 11);
    repo = AiLabelsRepository(db, queue, now: () => now);
    ctx = Ctx();
    thumbCalls = [];
    workersStarted = 0;
    workers = [];
    modelsPresent = true;
    batteryOk = true;
    supported = true;
    onThumb = null;
    await settings.write(AppSettings.aiLabelsEnabled, true);
  });
  tearDown(() => db.close());

  Future<Map<String, AiLabelStatusRow>> status() async => {
    for (final r in await db.select(db.aiLabelStatus).get()) r.fileId: r,
  };
  Future<Set<String>> labels() async => {
    for (final r in await db.select(db.aiLabels).get())
      '${r.fileId}:${r.label}',
  };

  test('off (default): nothing runs, no worker, no rows', () async {
    await settings.write(AppSettings.aiLabelsEnabled, false);
    await index(db, [photo('a')]);
    final j = job();
    await j.run(ctx);
    expect(thumbCalls, isEmpty);
    expect(workersStarted, 0);
    expect(j.workerRunning, isFalse);
    expect(await status(), isEmpty);
  });

  test('paused, low battery or unsupported: nothing runs', () async {
    await index(db, [photo('a')]);
    await settings.write(AppSettings.aiLabelsPaused, true);
    await job().run(ctx);
    await settings.write(AppSettings.aiLabelsPaused, false);
    batteryOk = false;
    await job().run(ctx);
    batteryOk = true;
    supported = false;
    await job().run(ctx);
    expect(thumbCalls, isEmpty);
    expect(workersStarted, 0);
    expect(await status(), isEmpty);
  });

  test('models missing or changed: stops with modelsMissing', () async {
    modelsPresent = false;
    await index(db, [photo('a')]);
    final j = job();
    await j.run(ctx);
    expect(j.errors.value, LabelingJobError.modelsMissing);
    expect(workersStarted, 0);
    expect(await status(), isEmpty);
  });

  test('labels images newest first, records failures once, resumes', () async {
    await index(db, [
      photo('old', minute: 1),
      photo('nothumb', minute: 2),
      photo('new', minute: 3),
      photo('doc', minute: 4, kind: FileKind.document),
      photo('bad', minute: 5),
    ]);
    final j = job();
    await j.run(ctx);
    expect(thumbCalls, ['bad', 'new', 'nothumb', 'old']);
    expect(workersStarted, 1);
    expect(workers.single.closed, isTrue);
    expect(j.workerRunning, isFalse);
    expect(await labels(), {
      'new:cat',
      'new:color:blue',
      'old:cat',
      'old:color:blue',
    });
    final s = await status();
    expect(s.keys, unorderedEquals(['old', 'nothumb', 'new', 'bad']));
    expect(s['new']!.outcome, AiLabelOutcome.labeled);
    expect(s['nothumb']!.outcome, AiLabelOutcome.failed);
    expect(s['nothumb']!.error, 'no thumbnail');
    expect(s['bad']!.outcome, AiLabelOutcome.failed);
    expect(s['nothumb']!.attempts, 1);
    expect(s['new']!.modelVersion, LabelingJob.modelVersion);
    expect(s['new']!.processedAtMs, now.millisecondsSinceEpoch);

    // Next launch: nothing is processed again, nothing changes.
    thumbCalls.clear();
    now = now.add(const Duration(hours: 1));
    await job().run(ctx);
    expect(thumbCalls, isEmpty);
    expect(workersStarted, 1);
    final again = await status();
    expect(again['nothumb']!.attempts, 1);
    expect(again['new']!.processedAtMs, s['new']!.processedAtMs);
  });

  test(
    'an older modelVersion relabels; an edit relabels only that file',
    () async {
      await index(db, [photo('a', minute: 1), photo('b', minute: 2)]);
      await job().run(ctx);
      // Simulate rows of an older model for 'a'.
      await db.customStatement(
        "UPDATE ai_label_status SET model_version = 0 WHERE file_id = 'a'",
      );
      thumbCalls.clear();
      await job().run(ctx);
      expect(thumbCalls, ['a']);
      // Editing 'b' changes its modified time.
      await index(db, [photo('b', minute: 2, modifiedMs: 5000)]);
      thumbCalls.clear();
      await job().run(ctx);
      expect(thumbCalls, ['b']);
      expect((await status())['b']!.fileModifiedAtMs, 5000);
    },
  );

  test('a failed file is retried only after it changes', () async {
    await index(db, [photo('nothumb1')]);
    await job().run(ctx);
    await job().run(ctx);
    expect(thumbCalls, ['nothumb1']);
    await index(db, [photo('nothumb1', modifiedMs: 7000)]);
    await job().run(ctx);
    expect(thumbCalls, ['nothumb1', 'nothumb1']);
    final row = (await status())['nothumb1']!;
    expect(row.attempts, 2);
    expect(row.outcome, AiLabelOutcome.failed);
  });

  test('turning labeling off stops within one batch', () async {
    await index(db, [for (var i = 0; i < 6; i++) photo('p$i', minute: i)]);
    onThumb = (id) {
      if (id == 'p5') {
        settings.write(AppSettings.aiLabelsEnabled, false).ignore();
      }
    };
    await job(batchSize: 2).run(ctx);
    expect(thumbCalls, ['p5', 'p4']);
    expect((await status()).keys, unorderedEquals(['p5', 'p4']));
  });

  test('shouldStop mid-batch saves only the processed files', () async {
    await index(db, [for (var i = 0; i < 4; i++) photo('p$i', minute: i)]);
    onThumb = (id) {
      if (id == 'p2') ctx.shouldStop = true;
    };
    await job().run(ctx);
    expect(thumbCalls, ['p3', 'p2']);
    expect((await status()).keys, unorderedEquals(['p3', 'p2']));
  });

  test('a worker crash fails the file and restarts once per batch', () async {
    await index(db, [
      photo('crash1', minute: 5),
      photo('ok1', minute: 4),
      photo('crash2', minute: 3),
      photo('ok2', minute: 2),
    ]);
    final j = job();
    await j.run(ctx);
    // crash1 → restart → ok1 → crash2 → second crash in the batch: stop.
    expect(workersStarted, 2);
    expect(j.errors.value, LabelingJobError.workerCrashed);
    final s = await status();
    expect(s.keys, unorderedEquals(['crash1', 'ok1', 'crash2']));
    expect(s['crash1']!.outcome, AiLabelOutcome.failed);
    expect(s['ok1']!.outcome, AiLabelOutcome.labeled);
    expect(workers.every((w) => w.closed), isTrue);
  });

  test('a worker that cannot start reports workerFailed', () async {
    await index(db, [photo('a')]);
    final j = LabelingJob(
      repo: repo,
      settings: settings,
      loadModels: () async => models,
      startWorker: (_) async => throw const LabelWorkerStartFailed('dlopen'),
      supported: () async => true,
      thumbs: (f, _) async => Uint8List.fromList(f.id.codeUnits),
      batchPause: Duration.zero,
    );
    await j.run(ctx);
    expect(j.errors.value, LabelingJobError.workerFailed);
    expect(await status(), isEmpty);
  });

  test('orphans are removed at the start of a run', () async {
    await index(db, [photo('a')]);
    await db.customStatement(
      'INSERT INTO ai_labels (file_id, label, confidence) VALUES '
      "('gone', 'cat', 0.5)",
    );
    await db.customStatement(
      'INSERT INTO ai_label_status (file_id, outcome, model_version, '
      "file_modified_at_ms, processed_at_ms) VALUES ('gone', 'labeled', 1, 0, 0)",
    );
    await job().run(ctx);
    expect(await labels(), {'a:cat', 'a:color:blue'});
    expect((await status()).keys, ['a']);
  });

  group('repository', () {
    test(
      'progress counts current-version rows with a matching mtime',
      () async {
        await index(db, [
          photo('a', minute: 1),
          photo('b', minute: 2),
          photo('c', minute: 3, kind: FileKind.video),
        ]);
        final progress = repo.watchProgress(LabelingJob.modelVersion);
        expect(
          await progress.first,
          const LabelingProgress(processed: 0, total: 2),
        );
        await job().run(ctx);
        expect(
          await progress.first,
          const LabelingProgress(processed: 2, total: 2),
        );
        expect((await progress.first).fraction, 1);
        await index(db, [photo('b', minute: 2, modifiedMs: 9)]);
        expect(
          await progress.first,
          const LabelingProgress(processed: 1, total: 2),
        );
        expect(LabelingProgress.empty.fraction, 1);
      },
    );

    test('failed count and reset', () async {
      await index(db, [photo('nothumb'), photo('a', minute: 1)]);
      await job().run(ctx);
      expect(await repo.watchFailedCount().first, 1);
      await repo.reset();
      expect(await status(), isEmpty);
      expect(await labels(), isEmpty);
      expect(await repo.watchFailedCount().first, 0);
    });

    test('long errors are cut to 200 characters', () async {
      await index(db, [photo('a')]);
      final work = (await repo.nextBatch(null, modelVersion: 1)).single;
      await repo.saveBatch([
        LabelResult.failed(work, 'x' * 500),
      ], modelVersion: 1);
      expect(
        (await status())['a']!.error,
        hasLength(AiLabelsRepository.maxErrorLength),
      );
    });
  });
}
