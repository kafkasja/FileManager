import 'package:intl/intl.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/background_jobs/domain/job_progress.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:meta/meta.dart';

/// Buttons of the job notification (Android) / tray (Windows).
enum NoticeAction { pause, resume, cancel, stopSharing }

/// What one notification shows (TASK-X8), already in KFM's language. Pure:
/// built by [ongoingNotice] / [pausedNotice] / [endNotice].
@immutable
class JobNotice {
  const new({
    required this.title,
    required this.text,
    this.percent,
    this.actions = const [],
    this.failed = false,
  });

  final String title;
  final String text;

  /// 0..100 for a determinate bar; null = no bar.
  final int? percent;
  final List<NoticeAction> actions;

  /// An end notice with failed files (a tap opens Transfers either way).
  final bool failed;

  @override
  bool operator ==(Object other) =>
      other is JobNotice &&
      other.title == title &&
      other.text == text &&
      other.percent == percent &&
      other.failed == failed &&
      _sameActions(other.actions, actions);

  @override
  int get hashCode =>
      Object.hash(title, text, percent, failed, Object.hashAll(actions));

  @override
  String toString() => 'JobNotice($title | $text | $percent% | $actions)';
}

bool _sameActions(List<NoticeAction> a, List<NoticeAction> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Language-dependent formatting for the notices: [l10n] and its [locale]
/// (`nl` → "1,2 GB", `tr` → "%38"); [placeName] names a U2 target place.
@immutable
class NoticeFormat {
  const new({
    required this.l10n,
    required this.locale,
    required this.placeName,
  });

  final AppLocalizations l10n;
  final String locale;
  final String Function(PlaceTarget target) placeName;

  String bytes(int n) => formatBytes(n, locale: locale);

  /// "38%" / "%38".
  String percent(double fraction) =>
      NumberFormat.percentPattern(locale).format(_percentOf(fraction) / 100);

  /// "4 min", "1 h 5 min", "40 s".
  String timeLeft(Duration d) {
    if (d.inSeconds < 60) return l10n.jobsSeconds(d.inSeconds);
    final minutes = (d.inSeconds / 60).ceil();
    if (minutes < 60) return l10n.jobsMinutes(minutes);
    return l10n.jobsHoursMinutes(minutes ~/ 60, minutes % 60);
  }

  String targetName(JobTarget t) => switch (t) {
    DeviceTarget(:final name) => name,
    final PlaceTarget p => placeName(p),
  };

  /// "Sending 3 files to PC", "Copying 120 files to SD card", …
  String title(JobProgress j) {
    final name = targetName(j.target);
    return switch (j.kind) {
      JobKind.send => l10n.transferUploadQueued(j.files, name),
      JobKind.download => l10n.transferDownloadQueued(j.files, name),
      JobKind.moveTo => l10n.transferMoveQueued(j.files, name),
      JobKind.moveFrom => l10n.transferMoveDownloadQueued(j.files, name),
      JobKind.localCopy => l10n.externalJobTitleCopy(j.files, name),
      JobKind.localMove => l10n.externalJobTitleMove(j.files, name),
      JobKind.incoming => l10n.jobsReceivingFrom(j.files, name),
    };
  }

  /// "1.2 GB of 4.5 GB".
  String progressLine(Iterable<JobProgress> jobs) => l10n.jobsProgressLine(
    bytes(JobsSnapshot.doneOf(jobs)),
    bytes(JobsSnapshot.totalOf(jobs)),
  );
}

int _percentOf(double fraction) => (fraction * 100).floor().clamp(0, 100);

/// The ongoing notification while jobs run; null when none runs.
/// One job: its own title; several: "2 transfers · 38 %". Text: "1.2 GB of
/// 4.5 GB · 12 MB/s · 4 min left".
JobNotice? ongoingNotice(JobsSnapshot s, NoticeFormat f) {
  final running = s.running;
  if (running.isEmpty) return null;
  final fraction = JobsSnapshot.fractionOf(running);
  final title = running.length == 1
      ? f.title(running.single)
      : f.l10n.jobsCombinedTitle(running.length, f.percent(fraction));
  final total = JobsSnapshot.totalOf(running);
  final parts = <String>[];
  if (total > 0) parts.add(f.progressLine(running));
  if (s.bytesPerSecond > 0) {
    parts.add(f.l10n.jobsSpeedLine(f.bytes(s.bytesPerSecond.round())));
    if (s.timeLeft case final left?) {
      parts.add(f.l10n.jobsTimeLeft(f.timeLeft(left)));
    }
  }
  return JobNotice(
    title: title,
    text: parts.isEmpty ? f.l10n.jobsWaiting : parts.join(' · '),
    percent: _percentOf(fraction),
    actions: running.any((j) => j.controllable)
        ? const [NoticeAction.pause, NoticeAction.cancel]
        : const [],
  );
}

/// Shown (dismissible) when nothing runs but jobs are paused. [timeout]:
/// Android's background time limit paused them: "Paused, open KFM to
/// continue" (no Resume: only KFM in the foreground may continue).
JobNotice? pausedNotice(
  JobsSnapshot s,
  NoticeFormat f, {
  bool timeout = false,
}) {
  final paused = s.paused;
  if (paused.isEmpty || s.anyRunning) return null;
  final title = paused.length == 1
      ? f.l10n.jobsPausedOne(f.title(paused.single))
      : f.l10n.jobsPausedMany(paused.length);
  final total = JobsSnapshot.totalOf(paused);
  return JobNotice(
    title: title,
    text: timeout || total == 0
        ? f.l10n.jobsPausedOpenKfm
        : f.progressLine(paused),
    percent: _percentOf(JobsSnapshot.fractionOf(paused)),
    actions: timeout || !paused.any((j) => j.controllable)
        ? const []
        : const [NoticeAction.resume, NoticeAction.cancel],
  );
}

/// The dismissible notice after jobs end ("Sent 3 files to PC", "1 file
/// failed · Tap to see"); null when every one was cancelled.
JobNotice? endNotice(List<JobEnd> ends, NoticeFormat f) {
  final jobs = [
    for (final e in ends)
      if (e.job.phase != JobPhase.cancelled) e.job,
  ];
  if (jobs.isEmpty) return null;
  final failed = jobs.fold(0, (s, j) => s + j.filesFailed);
  final done = jobs.fold(0, (s, j) => s + j.filesDone);
  final String title;
  if (jobs.length == 1) {
    final j = jobs.single;
    title = done == 0 && failed > 0
        ? f.l10n.jobsEndFailedTitle(1)
        : _endTitle(j, f);
  } else {
    title = done == 0 && failed > 0
        ? f.l10n.jobsEndFailedTitle(jobs.length)
        : f.l10n.jobsEndMany(jobs.length);
  }
  return JobNotice(
    title: title,
    text: failed > 0
        ? f.l10n.jobsEndFailed(failed)
        : f.bytes(JobsSnapshot.totalOf(jobs)),
    failed: failed > 0,
  );
}

String _endTitle(JobProgress j, NoticeFormat f) {
  final name = f.targetName(j.target);
  final n = j.filesDone;
  return switch (j.kind) {
    JobKind.send => f.l10n.jobsEndSent(n, name),
    JobKind.download || JobKind.incoming => f.l10n.jobsEndReceived(n, name),
    JobKind.moveTo || JobKind.localMove => f.l10n.jobsEndMovedTo(n, name),
    JobKind.moveFrom => f.l10n.jobsEndMovedFrom(n, name),
    JobKind.localCopy => f.l10n.jobsEndCopied(n, name),
  };
}
