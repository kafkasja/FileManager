import 'dart:async';

import 'package:kfm/features/background_jobs/data/job_sources.dart';
import 'package:kfm/features/background_jobs/domain/job_progress.dart';
import 'package:kfm/features/connect/data/upload_store.dart';

class _File {
  new(this.size, this.received);

  int size;
  int received;
  bool completed = false;
  bool removed = false;

  bool get open => !completed && !removed;
}

class _Batch {
  new(this.owner, this.startedAt);

  final String owner;
  final DateTime startedAt;
  final Map<String, _File> files = {};
  DateTime lastActivity = DateTime.fromMillisecondsSinceEpoch(0);
}

/// X8: uploads other devices make into this one (the share server's
/// [UploadStore]), grouped per sending device into one "Receiving from …"
/// job. A group ends [idleEnd] after its last file finished (done, or
/// cancelled when nothing arrived), or [stallEnd] after the last chunk
/// while a file is still open (the sender paused or went away; its partial
/// stays for a resume).
class IncomingUploadsTracker {
  new({
    required Stream<UploadActivity> activity,
    required this._nameOf,
    DateTime Function()? clock,
    this.idleEnd = const Duration(seconds: 8),
    this.stallEnd = const Duration(seconds: 45),
    this.tick = const Duration(seconds: 2),
  }) : _clock = clock ?? DateTime.now {
    _sub = activity.listen(_on);
  }

  final String Function(String fingerprint) _nameOf;
  final DateTime Function() _clock;
  final Duration idleEnd;
  final Duration stallEnd;
  final Duration tick;

  late final StreamSubscription<UploadActivity> _sub;
  final Map<String, _Batch> _batches = {};
  final StreamController<List<JobProgress>> _out = StreamController.broadcast();
  Timer? _timer;
  List<JobProgress> _last = const [];

  /// Current groups (running) and groups that just ended (done/cancelled,
  /// reported once).
  Stream<List<JobProgress>> get jobs => _out.stream;
  List<JobProgress> get current => _last;

  void _on(UploadActivity a) {
    final now = _clock();
    final batch = _batches.putIfAbsent(
      a.ownerFingerprint,
      () => _Batch(a.ownerFingerprint, now),
    );
    final f =
        (batch..lastActivity = now).files.putIfAbsent(
            a.uploadId,
            () => _File(a.size, a.received),
          )
          ..size = a.size
          ..received = a.received;
    switch (a.phase) {
      case UploadPhase.progressed:
        break;
      case UploadPhase.completed:
        f.completed = true;
      case UploadPhase.removed:
        f.removed = true;
    }
    _timer ??= Timer.periodic(tick, (_) => check());
    _publish(const []);
  }

  /// Ends idle groups (the timer calls it; tests too).
  void check() {
    final now = _clock();
    final ended = <JobProgress>[];
    for (final b in _batches.values.toList()) {
      final idle = now.difference(b.lastActivity);
      final open = b.files.values.any((f) => f.open);
      if ((!open && idle >= idleEnd) || (open && idle >= stallEnd)) {
        _batches.remove(b.owner);
        final done = b.files.values.where((f) => f.completed).length;
        ended.add(
          _progressOf(b, done > 0 ? JobPhase.done : JobPhase.cancelled),
        );
      }
    }
    if (_batches.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
    if (ended.isNotEmpty) _publish(ended);
  }

  JobProgress _progressOf(_Batch b, JobPhase phase) {
    // A removed (cancelled) file no longer counts.
    final files = [
      for (final f in b.files.values)
        if (!f.removed) f,
    ];
    return JobProgress(
      key: '$incomingKeyPrefix${b.owner}@${b.startedAt.microsecondsSinceEpoch}',
      kind: JobKind.incoming,
      target: DeviceTarget(_nameOf(b.owner)),
      phase: phase,
      files: files.length,
      filesDone: files.where((f) => f.completed).length,
      bytesTotal: files.fold(0, (s, f) => s + f.size),
      bytesDone: files.fold(0, (s, f) => s + f.received),
      controllable: false,
    );
  }

  void _publish(List<JobProgress> ended) {
    _last = [
      for (final b in _batches.values) _progressOf(b, JobPhase.running),
      ...ended,
    ];
    _out.add(_last);
    // Ended groups are reported once.
    if (ended.isNotEmpty) {
      _last = [
        for (final b in _batches.values) _progressOf(b, JobPhase.running),
      ];
    }
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _sub.cancel();
    await _out.close();
  }
}
