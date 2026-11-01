import 'dart:async';
import 'dart:developer' as developer;
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:kfm/core/background/in_app_jobs.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/db/tables/image_signals_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';
import 'package:kfm/features/similar/data/similar_repository.dart';
import 'package:kfm/features/similar/domain/grouping.dart';
import 'package:kfm/features/similar/domain/signals.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'similar_scan_job.g.dart';

enum SimilarScanPhase { idle, hashing, grouping }

@immutable
class SimilarScanProgress {
  const new({required this.phase, this.done = 0, this.total = 0, this.error});

  static const SimilarScanProgress idle = SimilarScanProgress(
    phase: SimilarScanPhase.idle,
  );

  final SimilarScanPhase phase;

  /// Images checked in this run / to check in this run (hashing phase).
  final int done;
  final int total;

  /// The last run failed (rule 8); cleared by the next run.
  final Object? error;

  @override
  bool operator ==(Object other) =>
      other is SimilarScanProgress &&
      other.phase == phase &&
      other.done == done &&
      other.total == total &&
      other.error == error;

  @override
  int get hashCode => Object.hash(phase, done, total, error);
}

/// Runs [fn] off the UI isolate (default `Isolate.run`; tests run inline).
typedef BackgroundCompute = Future<R> Function<R>(FutureOr<R> Function() fn);

/// TASK-C2: hashes new/changed images (dHash + blur) and rebuilds the
/// near-duplicate groups. Resumable: work comes from image_signals vs
/// media_index, never from memory. Does nothing while `similarEnabled` is
/// off.
class SimilarScanJob implements BackgroundJob {
  new({
    required this._repo,
    required this._settings,
    this._thumbs = photoManagerThumbnail,
    this._compute = Isolate.run,
    this.batchSize = 200,
    this.batchPause = const Duration(milliseconds: 200),
  });

  static const int thumbSize = 256;

  final SimilarRepository _repo;
  final SettingsRepository _settings;

  /// MediaStore thumbnails, never DiskThumbnailCache (the user's cache
  /// stays untouched).
  final ThumbGenerator _thumbs;
  final BackgroundCompute _compute;
  final int batchSize;
  final Duration batchPause;

  final StreamController<SimilarScanProgress> _progress =
      StreamController.broadcast();
  SimilarScanProgress _current = SimilarScanProgress.idle;

  SimilarScanProgress get progress => _current;
  Stream<SimilarScanProgress> get progressStream => _progress.stream;

  @override
  String get name => 'similar';

  @override
  Future<void> run(JobContext ctx) async {
    if (!await _settings.read(AppSettings.similarEnabled)) return;
    try {
      await _run(ctx);
      _emit(SimilarScanProgress.idle);
    } catch (e) {
      _emit(SimilarScanProgress(phase: SimilarScanPhase.idle, error: e));
      rethrow;
    }
  }

  Future<void> _run(JobContext ctx) async {
    await _repo.deleteOrphans();
    final includeScreenshots = await _settings.read(
      AppSettings.similarIncludeScreenshots,
    );
    final total = await _repo.countPending(
      includeScreenshots: includeScreenshots,
    );
    var done = 0;
    var markedRegroup = false;
    SignalCursor? cursor;
    var finished = false;
    if (total > 0) {
      _emit(SimilarScanProgress(phase: SimilarScanPhase.hashing, total: total));
    }
    while (!ctx.shouldStop) {
      if (!await _settings.read(AppSettings.similarEnabled)) return;
      final batch = await _repo.nextBatch(
        includeScreenshots: includeScreenshots,
        after: cursor,
        limit: batchSize,
      );
      if (batch.isEmpty) {
        finished = true;
        break;
      }
      final last = batch.last;
      cursor = (sortDateMs: last.sortDate.millisecondsSinceEpoch, id: last.id);
      final writes = await _hashBatch(batch, ctx);
      if (writes.isNotEmpty && !markedRegroup) {
        markedRegroup = true;
        await _settings.write(AppSettings.similarRegroupNeeded, true);
      }
      await _repo.writeSignals(writes);
      done += writes.length;
      _emit(
        SimilarScanProgress(
          phase: SimilarScanPhase.hashing,
          done: done,
          total: total < done ? done : total,
        ),
      );
      if (ctx.shouldStop || writes.length < batch.length) break;
      if (batchPause > Duration.zero) await Future<void>.delayed(batchPause);
    }
    if (!finished || ctx.shouldStop) return;
    if (await _settings.read(AppSettings.similarRegroupNeeded)) {
      await _regroup(includeScreenshots);
    }
  }

  /// Thumbnails one by one on this isolate (platform calls), then one
  /// isolate run for the whole batch. Stops early on [JobContext.shouldStop]
  /// (only the processed files are written).
  Future<List<SignalWrite>> _hashBatch(
    List<FileRef> batch,
    JobContext ctx,
  ) async {
    final processed = <FileRef>[];
    final bytes = <(String, Uint8List)>[];
    final noThumb = <String, SignalStatus>{};
    for (final file in batch) {
      if (ctx.shouldStop) break;
      processed.add(file);
      try {
        final b = await _thumbs(file, thumbSize);
        if (b == null || b.isEmpty) {
          noThumb[file.id] = SignalStatus.unsupported;
        } else {
          bytes.add((file.id, b));
        }
        // A platform error for one file must not stop the scan.
        // ignore: avoid_catches_without_on_clauses
      } catch (e, st) {
        developer.log(
          'thumbnail failed: ${file.id}',
          name: 'kfm.similar',
          error: e,
          stackTrace: st,
        );
        noThumb[file.id] = SignalStatus.failed;
      }
    }
    final computed = {
      for (final c in await _computeSignalsWith(_compute, bytes)) c.fileId: c,
    };
    return [
      for (final f in processed)
        _toWrite(f, computed[f.id], noThumb[f.id] ?? SignalStatus.failed),
    ];
  }

  SignalWrite _toWrite(FileRef f, ComputedSignal? c, SignalStatus fallback) {
    final modifiedMs = f.modifiedAt.millisecondsSinceEpoch;
    if (c != null && c.ok) {
      return SignalWrite(
        fileId: f.id,
        status: SignalStatus.ok,
        dHash: c.dHash,
        blurScore: c.blurScore,
        fileModifiedAtMs: modifiedMs,
      );
    }
    if (c != null) {
      developer.log('decode failed: ${f.id}', name: 'kfm.similar');
    }
    return SignalWrite(
      fileId: f.id,
      status: c != null ? SignalStatus.failed : fallback,
      fileModifiedAtMs: modifiedMs,
    );
  }

  Future<void> _regroup(bool includeScreenshots) async {
    final strictness = await _settings.read(AppSettings.similarStrictness);
    _emit(const SimilarScanProgress(phase: SimilarScanPhase.grouping));
    final points = await _repo.groupingInput(
      includeScreenshots: includeScreenshots,
    );
    final groups = await _groupWith(
      _compute,
      points,
      maxDistanceFor(strictness),
    );
    final dateOf = {for (final p in points) p.fileId: p.sortDateMs};
    await _repo.replaceGroups([
      for (final g in groups)
        (
          members: g,
          sortDateMs: g
              .map((id) => dateOf[id]!)
              .reduce((a, b) => a > b ? a : b),
        ),
    ]);
    // A setting changed meanwhile → leave the flag set: the next run
    // groups again with the new value.
    final unchanged =
        await _settings.read(AppSettings.similarStrictness) == strictness &&
        await _settings.read(AppSettings.similarIncludeScreenshots) ==
            includeScreenshots;
    if (unchanged) {
      await _settings.write(AppSettings.similarRegroupNeeded, false);
    }
  }

  void _emit(SimilarScanProgress p) {
    _current = p;
    if (!_progress.isClosed) _progress.add(p);
  }

  void dispose() => unawaited(_progress.close());
}

// Top-level so the isolate closures capture only their arguments.
Future<List<ComputedSignal>> _computeSignalsWith(
  BackgroundCompute compute,
  List<(String, Uint8List)> batch,
) => batch.isEmpty
    ? Future.value(const <ComputedSignal>[])
    : compute(() => computeSignals(batch));

Future<List<List<String>>> _groupWith(
  BackgroundCompute compute,
  List<SignalPoint> points,
  int maxDistance,
) => compute(() => groupSimilar(points, maxDistance: maxDistance));

/// Registers the scan with the in-app runner (watched in `App.build`) and
/// kicks it when the user turns it on or a regroup is needed. Changing
/// strictness or the screenshot setting marks a regroup.
@Riverpod(keepAlive: true)
SimilarScanJob similarScanJob(Ref ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  final runner = ref.watch(inAppJobRunnerProvider);
  final job = SimilarScanJob(
    repo: ref.watch(similarRepositoryProvider),
    settings: settings,
  );
  runner.register(job);
  void regroup(Object _) =>
      settings.write(AppSettings.similarRegroupNeeded, true).fireAndForget();
  final subs = [
    settings.watch(AppSettings.similarEnabled).listen((on) {
      if (on) runner.kick();
    }),
    settings.watch(AppSettings.similarRegroupNeeded).listen((needed) {
      if (needed) runner.kick();
    }),
    settings.watch(AppSettings.similarStrictness).skip(1).listen(regroup),
    settings
        .watch(AppSettings.similarIncludeScreenshots)
        .skip(1)
        .listen(regroup),
  ];
  ref.onDispose(() {
    for (final s in subs) {
      unawaited(s.cancel());
    }
    runner.unregister(job);
    job.dispose();
  });
  return job;
}

/// Scan progress for the Similar screen ("Checking photos… done of total").
@riverpod
Stream<SimilarScanProgress> similarScanProgress(Ref ref) async* {
  final job = ref.watch(similarScanJobProvider);
  yield job.progress;
  yield* job.progressStream;
}
