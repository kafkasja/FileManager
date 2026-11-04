import 'dart:async';

import 'package:kfm/features/background_jobs/domain/job_progress.dart';

/// Merges the job sources (transfers, local jobs, incoming uploads) into
/// one [JobsSnapshot] stream (TASK-X8):
/// - a job joining, leaving, pausing or resuming publishes at once;
/// - byte progress publishes at most every [interval] (the Android
///   notification is updated from it: ~1/s stays clear of rate limits);
/// - the combined speed is measured over the last [speedWindow];
/// - paused jobs are listed only after they ran in this run;
/// - a job seen running in this run that ends is reported once on [ends].
class JobProgressAggregator {
  new({
    this.interval = const Duration(seconds: 1),
    this.speedWindow = const Duration(seconds: 6),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration interval;
  final Duration speedWindow;
  final DateTime Function() _clock;

  final Map<String, List<JobProgress>> _sources = {};
  final Map<String, List<(DateTime, int)>> _samples = {};
  final Set<String> _seen = {};
  final StreamController<JobsSnapshot> _snapshots =
      StreamController.broadcast();
  final StreamController<JobEnd> _ends = StreamController.broadcast();
  JobsSnapshot _current = JobsSnapshot.empty;
  DateTime? _lastEmit;
  Timer? _pending;
  bool _disposed = false;

  Stream<JobsSnapshot> get snapshots => _snapshots.stream;
  Stream<JobEnd> get ends => _ends.stream;
  JobsSnapshot get current => _current;

  /// Replaces everything [source] reports (finished jobs may stay listed;
  /// each end is reported once).
  void update(String source, List<JobProgress> jobs) {
    if (_disposed) return;
    _sources[source] = jobs;
    final now = _clock();
    final active = <JobProgress>[];
    for (final list in _sources.values) {
      for (final j in list) {
        if (j.isEnded) {
          if (_seen.remove(j.key)) _ends.add(JobEnd(j));
          _samples.remove(j.key);
          continue;
        }
        // Paused jobs count only once they ran in this run: a job left
        // waiting from an earlier day neither shows nor notifies.
        if (j.isPaused && !_seen.contains(j.key)) continue;
        _seen.add(j.key);
        active.add(j);
        if (j.isRunning) {
          final s = _samples.putIfAbsent(j.key, () => []);
          if (s.isEmpty || s.last.$2 != j.bytesDone) s.add((now, j.bytesDone));
          final cut = now.subtract(speedWindow);
          // Keep one sample older than the window as its start.
          while (s.length > 2 && s[1].$1.isBefore(cut)) {
            s.removeAt(0);
          }
        } else {
          _samples.remove(j.key);
        }
      }
    }
    final keys = {for (final j in active) j.key};
    _samples.removeWhere((k, _) => !keys.contains(k));
    _seen.removeWhere((k) => !keys.contains(k));
    final next = JobsSnapshot(jobs: active, bytesPerSecond: _speed(now));
    // Nothing changed (e.g. a DB write of another column): no timer.
    if (_lastEmit != null && next == _current) return;
    final structural = !_sameShape(next, _current);
    _current = next;
    if (structural) {
      _emit();
      return;
    }
    final last = _lastEmit;
    if (last == null || now.difference(last) >= interval) {
      _emit();
    } else {
      _pending ??= Timer(interval - now.difference(last), () {
        _pending = null;
        _emit();
      });
    }
  }

  double _speed(DateTime now) {
    var total = 0.0;
    for (final s in _samples.values) {
      if (s.length < 2) continue;
      final first = s.first;
      // Seconds since the oldest kept sample (until now: a stall slows the
      // speed down instead of freezing it).
      final dt = now.difference(first.$1).inMilliseconds / 1000;
      if (dt < 0.5) continue;
      final bytes = s.last.$2 - first.$2;
      if (bytes > 0) total += bytes / dt;
    }
    return total;
  }

  void _emit() {
    _pending?.cancel();
    _pending = null;
    if (_disposed) return;
    _lastEmit = _clock();
    _snapshots.add(_current);
  }

  static bool _sameShape(JobsSnapshot a, JobsSnapshot b) {
    if (a.jobs.length != b.jobs.length) return false;
    for (var i = 0; i < a.jobs.length; i++) {
      final x = a.jobs[i];
      final y = b.jobs[i];
      if (x.key != y.key ||
          x.phase != y.phase ||
          x.files != y.files ||
          x.target != y.target) {
        return false;
      }
    }
    return true;
  }

  Future<void> dispose() async {
    _disposed = true;
    _pending?.cancel();
    await _snapshots.close();
    await _ends.close();
  }
}
