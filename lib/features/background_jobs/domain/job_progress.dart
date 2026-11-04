import 'package:meta/meta.dart';

/// What a background job does (TASK-X8): the notification title and the
/// end text follow from it.
enum JobKind {
  /// Upload to a device (N9, N12 sends).
  send,

  /// Download from a device.
  download,

  /// N11 upload-move.
  moveTo,

  /// N11 download-move.
  moveFrom,

  /// U2 copy between places on this device.
  localCopy,

  /// U2 move between places on this device.
  localMove,

  /// Another device uploads into this one's shared folders (server side).
  incoming,
}

/// Where a job's state ends up.
enum JobPhase { running, paused, done, failed, cancelled }

/// Who the job talks to: a device (by name) or a place on this device.
@immutable
sealed class JobTarget {
  const new();
}

final class DeviceTarget extends JobTarget {
  const new(this.name);

  final String name;

  @override
  bool operator ==(Object other) => other is DeviceTarget && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

final class PlaceTarget extends JobTarget {
  const new(this.placeId, this.folder);

  final String placeId;
  final String folder;

  @override
  bool operator ==(Object other) =>
      other is PlaceTarget &&
      other.placeId == placeId &&
      other.folder == folder;

  @override
  int get hashCode => Object.hash(placeId, folder);
}

/// One job's progress, the same shape for transfers, local jobs and
/// incoming uploads. [key] is unique across the three (`t:`, `l:`, `i:`).
@immutable
class JobProgress {
  const new({
    required this.key,
    required this.kind,
    required this.target,
    required this.phase,
    required this.files,
    required this.bytesTotal,
    required this.bytesDone,
    this.filesDone = 0,
    this.filesFailed = 0,
    this.controllable = true,
  });

  final String key;
  final JobKind kind;
  final JobTarget target;
  final JobPhase phase;
  final int files;
  final int filesDone;
  final int filesFailed;
  final int bytesTotal;
  final int bytesDone;

  /// Pause / Resume / Cancel apply (not to incoming uploads: the sender
  /// controls those).
  final bool controllable;

  bool get isRunning => phase == JobPhase.running;
  bool get isPaused => phase == JobPhase.paused;
  bool get isEnded =>
      phase == JobPhase.done ||
      phase == JobPhase.failed ||
      phase == JobPhase.cancelled;

  @override
  bool operator ==(Object other) =>
      other is JobProgress &&
      other.key == key &&
      other.kind == kind &&
      other.target == target &&
      other.phase == phase &&
      other.files == files &&
      other.filesDone == filesDone &&
      other.filesFailed == filesFailed &&
      other.bytesTotal == bytesTotal &&
      other.bytesDone == bytesDone &&
      other.controllable == controllable;

  @override
  int get hashCode => Object.hash(
    key,
    kind,
    target,
    phase,
    files,
    filesDone,
    filesFailed,
    bytesTotal,
    bytesDone,
    controllable,
  );
}

/// A job that ended in this run (done, failed or cancelled after it was
/// seen running or paused).
@immutable
class JobEnd {
  const new(this.job);

  final JobProgress job;
}

/// Every running or paused job, with the combined speed (bytes/s over
/// the last seconds). Published at most about once a second.
@immutable
class JobsSnapshot {
  const new({this.jobs = const [], this.bytesPerSecond = 0});

  /// Running and paused jobs, oldest first.
  final List<JobProgress> jobs;
  final double bytesPerSecond;

  static const empty = JobsSnapshot();

  List<JobProgress> get running => [
    for (final j in jobs)
      if (j.isRunning) j,
  ];

  List<JobProgress> get paused => [
    for (final j in jobs)
      if (j.isPaused) j,
  ];

  bool get isEmpty => jobs.isEmpty;
  bool get anyRunning => jobs.any((j) => j.isRunning);

  /// Totals of [of] (default: the running jobs).
  static int doneOf(Iterable<JobProgress> of) =>
      of.fold(0, (s, j) => s + j.bytesDone);
  static int totalOf(Iterable<JobProgress> of) =>
      of.fold(0, (s, j) => s + j.bytesTotal);

  /// 0..1 over [of]; files count when no sizes are known.
  static double fractionOf(Iterable<JobProgress> of) {
    final total = totalOf(of);
    if (total > 0) return (doneOf(of) / total).clamp(0, 1).toDouble();
    final files = of.fold(0, (s, j) => s + j.files);
    if (files == 0) return 0;
    final done = of.fold(0, (s, j) => s + j.filesDone + j.filesFailed);
    return (done / files).clamp(0, 1).toDouble();
  }

  /// Time left for the running jobs at the current speed; null = unknown.
  Duration? get timeLeft {
    final r = running;
    if (bytesPerSecond <= 0 || r.isEmpty) return null;
    final left = totalOf(r) - doneOf(r);
    if (left <= 0) return Duration.zero;
    return Duration(seconds: (left / bytesPerSecond).ceil().clamp(0, 359999));
  }

  @override
  bool operator ==(Object other) =>
      other is JobsSnapshot &&
      other.bytesPerSecond == bytesPerSecond &&
      _listEq(other.jobs, jobs);

  @override
  int get hashCode => Object.hash(Object.hashAll(jobs), bytesPerSecond);
}

bool _listEq(List<JobProgress> a, List<JobProgress> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
