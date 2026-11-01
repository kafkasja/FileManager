import 'dart:async';
import 'dart:developer' as developer;
import 'dart:isolate';

import 'package:kfm/core/background/in_app_jobs.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/db/tables/smart_groups_table.dart';
import 'package:kfm/features/smart_groups/data/exif_reader.dart';
import 'package:kfm/features/smart_groups/data/place_namer.dart';
import 'package:kfm/features/smart_groups/data/smart_groups_repository.dart';
import 'package:kfm/features/smart_groups/domain/geo.dart';
import 'package:kfm/features/smart_groups/domain/place_clustering.dart';
import 'package:kfm/features/smart_groups/domain/trip_clustering.dart';
import 'package:meta/meta.dart';

/// Runs [fn] off the UI isolate (default `Isolate.run`; tests run inline).
typedef GroupsCompute = Future<R> Function<R>(FutureOr<R> Function() fn);

enum SmartGroupsPhase { idle, reading, grouping }

@immutable
class SmartGroupsProgress {
  const new({
    required this.phase,
    this.done = 0,
    this.total = 0,
    this.failedFiles = 0,
    this.error,
  });

  static const SmartGroupsProgress idle = SmartGroupsProgress(
    phase: SmartGroupsPhase.idle,
  );

  final SmartGroupsPhase phase;

  /// Images read in this run / to read in this run.
  final int done;
  final int total;

  /// Files whose EXIF couldn't be read in the last run (a count only).
  final int failedFiles;

  /// The last run failed (rule 8); cleared by the next run.
  final Object? error;

  @override
  bool operator ==(Object other) =>
      other is SmartGroupsProgress &&
      other.phase == phase &&
      other.done == done &&
      other.total == total &&
      other.failedFiles == failedFiles &&
      other.error == error;

  @override
  int get hashCode => Object.hash(phase, done, total, failedFiles, error);
}

/// Clustering result handed back from the isolate.
typedef GroupClusters = ({List<PlaceCluster> places, List<TripCluster> trips});

/// TASK-C5 §5: orphans → EXIF pass → recompute (only when the input
/// changed) → match + replace → online place names. Does nothing until the
/// Groups screen was opened once (`smartGroupsActivated`). Resumable: work
/// comes from media_locations vs media_index, never from memory.
class SmartGroupsJob implements BackgroundJob {
  new({
    required this._repo,
    required this._settings,
    required this._exif,
    required this._namer,
    required this._locationGranted,
    required this._canReadPaths,
    this._compute = Isolate.run,
    this.batchSize = 200,
    this.batchPause = const Duration(milliseconds: 100),
    this.maxLookupsPerRun = 20,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SmartGroupsRepository _repo;
  final SettingsRepository _settings;
  final ExifReader _exif;
  final PlaceNamer _namer;
  final Future<bool> Function() _locationGranted;

  /// `path:` images can be read (All files access).
  final Future<bool> Function() _canReadPaths;
  final GroupsCompute _compute;
  final int batchSize;
  final Duration batchPause;
  final int maxLookupsPerRun;
  final DateTime Function() _clock;

  final StreamController<SmartGroupsProgress> _progress =
      StreamController.broadcast();
  SmartGroupsProgress _current = SmartGroupsProgress.idle;

  SmartGroupsProgress get progress => _current;
  Stream<SmartGroupsProgress> get progressStream => _progress.stream;

  @override
  String get name => 'smartGroups';

  @override
  Future<void> run(JobContext ctx) async {
    if (!await _settings.read(AppSettings.smartGroupsActivated)) return;
    try {
      final failed = await _run(ctx);
      _emit(
        SmartGroupsProgress(phase: SmartGroupsPhase.idle, failedFiles: failed),
      );
    } catch (e) {
      _emit(SmartGroupsProgress(phase: SmartGroupsPhase.idle, error: e));
      rethrow;
    }
  }

  /// Returns how many files couldn't be read.
  Future<int> _run(JobContext ctx) async {
    // 1. Orphans.
    await _repo.deleteOrphans();
    if (ctx.shouldStop) return 0;

    // 2. EXIF pass.
    final granted = await _locationGranted();
    final paths = await _canReadPaths();
    final total = await _repo.countExifWork(locationGranted: granted);
    var done = 0;
    var failed = 0;
    ExifCursor? cursor;
    if (total > 0) {
      _emit(SmartGroupsProgress(phase: SmartGroupsPhase.reading, total: total));
    }
    while (!ctx.shouldStop) {
      final batch = await _repo.nextExifBatch(
        locationGranted: granted,
        after: cursor,
        limit: batchSize,
      );
      if (batch.isEmpty) break;
      final last = batch.last;
      cursor = (sortDateMs: last.sortDateMs, id: last.id);
      // Without All files access `path:` images are skipped this run.
      final ids = [
        for (final w in batch)
          if (w.id.startsWith('ms:') || (paths && w.id.startsWith('path:')))
            w.id,
      ];
      if (ids.isNotEmpty) {
        final facts = await _exif.read(ids);
        failed += facts.where((f) => f.error != null).length;
        await _repo.writeLocations(facts, {
          for (final w in batch) w.id: w.modifiedAtMs,
        }, nowMs: _clock().millisecondsSinceEpoch);
      }
      done += batch.length;
      _emit(
        SmartGroupsProgress(
          phase: SmartGroupsPhase.reading,
          done: done,
          total: total < done ? done : total,
          failedFiles: failed,
        ),
      );
      if (batch.length < batchSize) break;
      if (batchPause > Duration.zero) await Future<void>.delayed(batchPause);
    }
    if (ctx.shouldStop) return failed;
    if (failed > 0) {
      developer.log('EXIF failed for $failed files', name: 'kfm.groups');
    }

    // 3. Recompute only when the input changed.
    final signature = '${await _repo.inputSignature()}:$granted';
    if (signature !=
        await _settings.read(AppSettings.smartGroupsInputSignature)) {
      _emit(
        SmartGroupsProgress(
          phase: SmartGroupsPhase.grouping,
          failedFiles: failed,
        ),
      );
      await _recompute(withGps: granted);
      await _settings.write(AppSettings.smartGroupsInputSignature, signature);
    }
    if (ctx.shouldStop) return failed;

    // 5. Online place names (setting on only).
    await _nameNewPlaces(ctx);
    return failed;
  }

  Future<void> _recompute({required bool withGps}) async {
    final input = await _repo.clusterInput(withGps: withGps);
    final clusters = await _clusterWith(_compute, input);
    final dateOf = {for (final r in input) r.id: r.sortDateMs};
    String newest(List<String> ids) => ids.reduce((a, b) {
      final da = dateOf[a]!;
      final db = dateOf[b]!;
      return db > da || (db == da && b.compareTo(a) > 0) ? b : a;
    });
    final shown = kHideLargestPlace
        ? clusters.places.skip(1).toList()
        : clusters.places;
    final places = [
      for (final (i, p) in shown.indexed)
        SmartGroupDraft(
          rank: i + 1,
          startAtMs: p.memberIds.map((id) => dateOf[id]!).reduce(_min),
          endAtMs: p.memberIds.map((id) => dateOf[id]!).reduce(_max),
          center: p.center,
          coverFileId: newest(p.memberIds),
          memberIds: p.memberIds,
        ),
    ];
    final trips = [
      for (final t in clusters.trips)
        SmartGroupDraft(
          rank: 0,
          startAtMs: t.startAtMs,
          endAtMs: t.endAtMs,
          center: t.center,
          coverFileId: t.newestId,
          memberIds: t.memberIds,
        ),
    ];
    await _repo.replaceGroups(SmartGroupKind.place, places);
    await _repo.replaceGroups(SmartGroupKind.trip, trips);
  }

  Future<void> _nameNewPlaces(JobContext ctx) async {
    if (!await _settings.read(AppSettings.smartGroupsOnlinePlaceNames)) return;
    final todo = await _repo.placesToName(limit: maxLookupsPerRun);
    for (final g in todo) {
      if (ctx.shouldStop) return;
      // Re-checked per lookup: turning the setting off stops at once.
      if (!await _settings.read(AppSettings.smartGroupsOnlinePlaceNames)) {
        return;
      }
      final name = await _namer.nameFor(g.centerLat!, g.centerLng!);
      await _repo.setPlaceName(
        g.id,
        name,
        nowMs: _clock().millisecondsSinceEpoch,
      );
    }
  }

  void _emit(SmartGroupsProgress p) {
    _current = p;
    if (!_progress.isClosed) _progress.add(p);
  }

  void dispose() => unawaited(_progress.close());
}

int _min(int a, int b) => a < b ? a : b;
int _max(int a, int b) => a > b ? a : b;

// Top-level so the isolate closure captures only its argument.
Future<GroupClusters> _clusterWith(
  GroupsCompute compute,
  List<ClusterInputRow> input,
) => compute(() => clusterAll(input));

/// Places first (their largest cluster is the trips' home), then trips.
GroupClusters clusterAll(List<ClusterInputRow> input) {
  final gps = [
    for (final r in input)
      if (r.lat != null && r.lng != null) PlacePoint(r.id, r.lat!, r.lng!),
  ];
  final places = clusterPlaces(gps);
  final home = places.isNotEmpty
      ? places.first.center
      : mostCommonCell([for (final p in gps) GeoPoint(p.lat, p.lng)]);
  final trips = clusterTrips([
    for (final r in input)
      TimedPoint(r.id, r.sortDateMs, lat: r.lat, lng: r.lng),
  ], home: home);
  return (places: places, trips: trips);
}
