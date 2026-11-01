import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:kfm/core/background/in_app_jobs.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';
import 'package:kfm/features/ai_labels/data/ai_labels_repository.dart';
import 'package:kfm/features/ai_labels/data/ai_model_store.dart';
import 'package:kfm/features/ai_labels/data/label_worker.dart';

/// Job-level problems, shown as one error line in Settings (rule 8).
enum LabelingJobError {
  /// A model file is missing or changed ("Download again").
  modelsMissing,

  /// The worker (native library / interpreters) couldn't start.
  workerFailed,

  /// The worker crashed twice in one batch.
  workerCrashed,
}

/// Starts the label worker with verified model bytes.
typedef LabelWorkerStarter = Future<LabelWorker> Function(AiModelBytes models);

/// TASK-C3 §5: labels new/changed images, newest first, in batches of 50.
/// Resumable: work comes from ai_label_status vs media_index, never from
/// memory. Does nothing while labeling is off, paused, unsupported, the
/// models aren't installed, or the battery is low and not charging.
class LabelingJob implements BackgroundJob {
  new({
    required this._repo,
    required this._settings,
    required this._loadModels,
    required this._startWorker,
    required this._supported,
    this._thumbs = photoManagerThumbnail,
    this._batteryOk = _alwaysOk,
    this.batchSize = 50,
    this.batchPause = const Duration(milliseconds: 300),
  });

  /// Bump when a model file or label_map.json changes (forces relabeling).
  static const int modelVersion = 1;
  static const int thumbSize = 320;
  static const int lowBatteryPercent = 20;

  final AiLabelsRepository _repo;
  final SettingsRepository _settings;

  /// `AiModelStore.loadVerified` (null = missing or changed).
  final Future<AiModelBytes?> Function() _loadModels;
  final LabelWorkerStarter _startWorker;

  /// The API 26 gate (TASK-C3 §1).
  final Future<bool> Function() _supported;

  /// MediaStore thumbnails, never DiskThumbnailCache (the user's cache
  /// stays untouched).
  final ThumbGenerator _thumbs;

  /// Not (battery < 20% and not charging).
  final Future<bool> Function() _batteryOk;
  final int batchSize;
  final Duration batchPause;

  final ValueNotifier<LabelingJobError?> errors = ValueNotifier(null);

  /// Whether the worker isolate is up (tests: "nothing runs while off").
  bool get workerRunning => _worker != null;

  LabelWorker? _worker;

  static Future<bool> _alwaysOk() async => true;

  @override
  String get name => 'ai_labels';

  Future<bool> _mayRun() async =>
      await _settings.read(AppSettings.aiLabelsEnabled) &&
      !await _settings.read(AppSettings.aiLabelsPaused) &&
      await _batteryOk();

  @override
  Future<void> run(JobContext ctx) async {
    if (!await _mayRun() || !await _supported()) return;
    // Nothing to do: don't load 10 MB of models.
    if ((await _repo.nextBatch(
      null,
      modelVersion: modelVersion,
      limit: 1,
    )).isEmpty) {
      await _repo.deleteOrphans();
      return;
    }
    final models = await _loadModels();
    if (models == null) {
      errors.value = LabelingJobError.modelsMissing;
      return;
    }
    try {
      await _repo.deleteOrphans();
      await _run(ctx, models);
    } finally {
      await _closeWorker();
    }
  }

  Future<void> _run(JobContext ctx, AiModelBytes models) async {
    LabelCursor? cursor;
    while (!ctx.shouldStop && await _mayRun()) {
      final batch = await _repo.nextBatch(
        cursor,
        modelVersion: modelVersion,
        limit: batchSize,
      );
      if (batch.isEmpty) return;
      cursor = batch.last.cursor;
      final results = <LabelResult>[];
      var restarted = false;
      var stop = false;
      for (final work in batch) {
        if (ctx.shouldStop) break;
        final jpeg = await _thumbnail(work);
        if (jpeg == null) {
          results.add(LabelResult.failed(work, 'no thumbnail'));
          continue;
        }
        final worker = await _ensureWorker(models);
        if (worker == null) {
          stop = true;
          break;
        }
        try {
          results.add(LabelResult.labeled(work, await worker.label(jpeg)));
          errors.value = null;
        } on LabelWorkerCrashed catch (e) {
          results.add(LabelResult.failed(work, '$e'));
          await _closeWorker();
          // Restart once per batch, then stop with an error.
          if (restarted) {
            errors.value = LabelingJobError.workerCrashed;
            stop = true;
            break;
          }
          restarted = true;
        } on Object catch (e) {
          results.add(LabelResult.failed(work, '$e'));
        }
      }
      await _repo.saveBatch(results, modelVersion: modelVersion);
      if (stop || ctx.shouldStop) return;
      if (batchPause > Duration.zero) await Future<void>.delayed(batchPause);
    }
  }

  Future<Uint8List?> _thumbnail(LabelWork work) async {
    try {
      final b = await _thumbs(work.file, thumbSize);
      return b == null || b.isEmpty ? null : b;
      // A platform error for one file must not stop the run.
      // ignore: avoid_catches_without_on_clauses
    } catch (e, st) {
      developer.log(
        'thumbnail failed: ${work.file.id}',
        name: 'kfm.ai_labels',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<LabelWorker?> _ensureWorker(AiModelBytes models) async {
    final existing = _worker;
    if (existing != null) return existing;
    try {
      return _worker = await _startWorker(models);
    } on Object catch (e, st) {
      developer.log(
        'label worker failed to start',
        name: 'kfm.ai_labels',
        error: e,
        stackTrace: st,
      );
      errors.value = LabelingJobError.workerFailed;
      return null;
    }
  }

  Future<void> _closeWorker() async {
    final w = _worker;
    _worker = null;
    await w?.close();
  }

  void dispose() {
    unawaited(_closeWorker());
    errors.dispose();
  }
}
