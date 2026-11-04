import 'dart:async';
import 'dart:developer' as developer;

import 'package:kfm/features/background_jobs/domain/job_notice.dart';
import 'package:kfm/features/background_jobs/domain/job_progress.dart';
import 'package:kfm/features/connect/data/share_background.dart';
import 'package:meta/meta.dart';

/// Action keys coming back from the platform (notification buttons, tray
/// menu): [NoticeAction] names, plus these.
abstract final class PresenceKeys {
  /// Android 15: the `dataSync` time limit ran out (`onTimeout`).
  static const timeout = 'timeout';

  /// The notification was tapped: open Transfers.
  static const open = 'open';
}

/// Which notification channel a notice goes to (Android).
enum PresenceChannel { sharing, progress, results }

/// One channel's name and description, in KFM's language (re-registered
/// with every notice, so a language switch renames it).
@immutable
class PresenceChannelTexts {
  const new(this.channel, this.name, [this.description = '']);

  final PresenceChannel channel;
  final String name;
  final String description;

  @override
  bool operator ==(Object other) =>
      other is PresenceChannelTexts &&
      other.channel == channel &&
      other.name == name &&
      other.description == description;

  @override
  int get hashCode => Object.hash(channel, name, description);
}

/// The ongoing (foreground-service) notification / tray state.
@immutable
class OngoingPresence {
  const new({
    required this.sharing,
    required this.jobs,
    required this.title,
    required this.text,
    required this.channel,
    this.percent,
    this.paused = false,
    this.actions = const [],
  });

  /// Keeps sharing alive (`connectedDevice`).
  final bool sharing;

  /// Keeps jobs alive (`dataSync`).
  final bool jobs;
  final String title;
  final String text;
  final PresenceChannelTexts channel;

  /// 0..100, null = no progress bar.
  final int? percent;

  /// Every job is paused (Windows taskbar: paused state).
  final bool paused;

  /// Button key and label.
  final List<(String, String)> actions;

  @override
  bool operator ==(Object other) =>
      other is OngoingPresence &&
      other.sharing == sharing &&
      other.jobs == jobs &&
      other.title == title &&
      other.text == text &&
      other.channel == channel &&
      other.percent == percent &&
      other.paused == paused &&
      _samePairs(other.actions, actions);

  @override
  int get hashCode => Object.hash(
    sharing,
    jobs,
    title,
    text,
    channel,
    percent,
    paused,
    Object.hashAll(actions),
  );

  @override
  String toString() =>
      'OngoingPresence(sharing: $sharing, jobs: $jobs, $title | $text | '
      '$percent | $actions)';
}

/// A dismissible notice: paused jobs, or jobs that ended.
@immutable
class NoticePresence {
  const new({
    required this.title,
    required this.text,
    required this.channel,
    this.percent,
    this.actions = const [],
  });

  final String title;
  final String text;
  final PresenceChannelTexts channel;
  final int? percent;
  final List<(String, String)> actions;

  @override
  bool operator ==(Object other) =>
      other is NoticePresence &&
      other.title == title &&
      other.text == text &&
      other.channel == channel &&
      other.percent == percent &&
      _samePairs(other.actions, actions);

  @override
  int get hashCode =>
      Object.hash(title, text, channel, percent, Object.hashAll(actions));

  @override
  String toString() => 'NoticePresence($title | $text | $actions)';
}

bool _samePairs(List<(String, String)> a, List<(String, String)> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Kinds of dismissible notices (one slot each).
enum NoticeSlot { paused, ended }

/// The platform side (Android foreground service + notifications,
/// Windows tray + taskbar, nothing elsewhere).
abstract interface class PresencePort {
  /// Starts (or updates) what keeps KFM alive. Throws when the system
  /// refuses to start it.
  Future<void> showOngoing(OngoingPresence p);

  /// Nothing to keep alive any more.
  Future<void> stopOngoing();

  Future<void> showNotice(NoticeSlot slot, NoticePresence n);
  Future<void> cancelNotice(NoticeSlot slot);

  /// Asks for the notification permission once (Android 13+), from a
  /// user action.
  Future<void> askNotificationsOnce();

  /// Button keys ([NoticeAction] names, [PresenceKeys]).
  Stream<String> get actions;
}

/// Pause / resume / cancel one job by its [JobProgress.key].
abstract interface class JobControls {
  Future<void> pause(String key);
  Future<void> resume(String key);
  Future<void> cancel(String key);
}

/// TASK-X8: one place decides what keeps KFM running in the background and
/// what the notification (or tray) shows: sharing (N5b) and jobs
/// (transfers, local jobs, incoming uploads) share one foreground service
/// and one ongoing notification. It starts with the first running job or
/// sharing and stops with the last; paused-only jobs leave a dismissible
/// "Paused" notice; ended jobs a dismissible end notice. Texts come from
/// the format callback (KFM's language, read at every render: [refresh] after a
/// language switch).
class BackgroundPresence {
  new({
    required this._port,
    required this._controls,
    required this._format,
    required Stream<JobsSnapshot> snapshots,
    required Stream<JobEnd> ends,
    JobsSnapshot initial = JobsSnapshot.empty,
    this.endBatch = const Duration(milliseconds: 1500),
    this._onError,
  }) : _snapshot = initial {
    _subs
      ..add(snapshots.listen(_onSnapshot))
      ..add(ends.listen(_onEnd))
      ..add(_port.actions.listen((k) => unawaited(_onAction(k))));
    if (!_snapshot.isEmpty) _scheduleRender();
  }

  final PresencePort _port;
  final JobControls _controls;
  final NoticeFormat Function() _format;
  final void Function(Object error, StackTrace stack)? _onError;

  /// Ends this close together become one notice ("2 transfers finished").
  final Duration endBatch;

  final List<StreamSubscription<Object?>> _subs = [];
  final StreamController<void> _stopSharing = StreamController.broadcast();
  final StreamController<void> _open = StreamController.broadcast();
  JobsSnapshot _snapshot;
  ShareNotificationTexts? _sharing;
  final List<JobEnd> _pendingEnds = [];
  Timer? _endTimer;

  /// Jobs paused by Android's time limit: they continue when KFM is back
  /// in the foreground.
  final Set<String> _timedOut = {};

  OngoingPresence? _shownOngoing;

  /// What the system last refused to start for (not retried every second).
  String? _refused;
  NoticePresence? _shownPaused;
  Future<void> _chain = Future<void>.value();
  bool _renderQueued = false;
  bool _askedPermission = false;
  bool _disposed = false;

  /// "Stop sharing" from the notification or tray.
  Stream<void> get stopSharingRequests => _stopSharing.stream;

  /// The notification was tapped: open Transfers.
  Stream<void> get openRequests => _open.stream;

  JobsSnapshot get snapshot => _snapshot;

  /// Whether jobs were paused by the time limit (tests).
  @visibleForTesting
  Set<String> get timedOut => Set.unmodifiable(_timedOut);

  /// Sharing starts or its text changes ([texts]) or it stops (null).
  /// Throws when the system refuses to start the service for sharing (the
  /// share controller falls back to stop-on-background).
  Future<void> setSharing(ShareNotificationTexts? texts) async {
    final starting = _sharing == null && texts != null;
    _sharing = texts;
    if (starting) {
      await _port.askNotificationsOnce();
      _askedPermission = true;
    }
    final done = _render(rethrowSharing: starting);
    await done;
  }

  /// The language changed: everything shown is rendered again.
  void refresh() {
    _shownOngoing = null;
    _shownPaused = null;
    _scheduleRender();
  }

  /// KFM is in the foreground again: jobs the time limit paused continue.
  Future<void> onForeground() async {
    if (_timedOut.isEmpty) return;
    final keys = _timedOut.toList();
    _timedOut.clear();
    for (final k in keys) {
      await _guard(() => _controls.resume(k));
    }
    _scheduleRender();
  }

  void _onSnapshot(JobsSnapshot s) {
    final wasRunning = _snapshot.anyRunning;
    _snapshot = s;
    // Ended or gone: nothing to continue later.
    _timedOut.removeWhere((k) => !s.jobs.any((j) => j.key == k));
    if (!wasRunning && s.anyRunning && !_askedPermission) {
      _askedPermission = true;
      unawaited(_guard(_port.askNotificationsOnce));
    }
    _scheduleRender();
  }

  void _onEnd(JobEnd e) {
    _pendingEnds.add(e);
    _endTimer ??= Timer(endBatch, () {
      _endTimer = null;
      final ends = List.of(_pendingEnds);
      _pendingEnds.clear();
      unawaited(_showEnd(ends));
    });
  }

  Future<void> _showEnd(List<JobEnd> ends) => _enqueue(() async {
    final f = _format();
    final notice = endNotice(ends, f);
    if (notice == null) return;
    await _port.showNotice(
      NoticeSlot.ended,
      NoticePresence(
        title: notice.title,
        text: notice.text,
        channel: _resultsChannel(f),
      ),
    );
  });

  Future<void> _onAction(String key) async {
    final keys = [for (final j in _snapshot.jobs) j];
    switch (key) {
      case 'pause':
        for (final j in keys) {
          if (j.isRunning && j.controllable) {
            await _guard(() => _controls.pause(j.key));
          }
        }
      case 'resume':
        _timedOut.clear();
        for (final j in keys) {
          if (j.isPaused && j.controllable) {
            await _guard(() => _controls.resume(j.key));
          }
        }
      case 'cancel':
        _timedOut.clear();
        for (final j in keys) {
          if (j.controllable) await _guard(() => _controls.cancel(j.key));
        }
      case 'stopSharing':
        _stopSharing.add(null);
      case PresenceKeys.open:
        _open.add(null);
      case PresenceKeys.timeout:
        // Android has already dropped `dataSync`; jobs stop cleanly (a
        // partial file stays and resumes later) until KFM is opened.
        for (final j in keys) {
          if (j.isRunning && j.controllable) {
            _timedOut.add(j.key);
            await _guard(() => _controls.pause(j.key));
          }
        }
        _scheduleRender();
    }
  }

  Future<void> _guard(Future<void> Function() f) async {
    try {
      await f();
    } on Object catch (e, st) {
      developer.log('background job action failed: $e', name: 'kfm.jobs');
      _onError?.call(e, st);
    }
  }

  void _scheduleRender() {
    if (_renderQueued || _disposed) return;
    _renderQueued = true;
    unawaited(_render());
  }

  Future<void> _enqueue(Future<void> Function() f) {
    final next = _chain.then((_) => _disposed ? null : f());
    _chain = next.then<void>(
      (_) {},
      onError: (Object e, StackTrace st) {
        developer.log('presence update failed: $e', name: 'kfm.jobs');
        _onError?.call(e, st);
      },
    );
    return next;
  }

  Future<void> _render({bool rethrowSharing = false}) {
    final done = _enqueue(() async {
      _renderQueued = false;
      final f = _format();
      final s = _snapshot;
      final timeout = _timedOut.isNotEmpty;
      // After Android's time limit no `dataSync` until KFM is in front.
      final job = timeout ? null : ongoingNotice(s, f);
      final sharing = _sharing;
      OngoingPresence? ongoing;
      if (job != null) {
        ongoing = OngoingPresence(
          sharing: sharing != null,
          jobs: true,
          title: job.title,
          text: job.text,
          percent: job.percent,
          channel: _progressChannel(f),
          actions: [
            ..._labels(job.actions, f),
            if (sharing != null) ('stopSharing', sharing.stop),
          ],
        );
      } else if (sharing != null) {
        ongoing = OngoingPresence(
          sharing: true,
          jobs: false,
          title: sharing.title,
          text: sharing.text,
          channel: PresenceChannelTexts(
            PresenceChannel.sharing,
            sharing.channel,
          ),
          actions: [('stopSharing', sharing.stop)],
        );
      }
      if (ongoing != _shownOngoing) {
        if (ongoing == null) {
          _shownOngoing = null;
          await _port.stopOngoing();
        } else {
          final shape = _shapeOf(ongoing, s);
          if (shape != _refused || rethrowSharing) {
            try {
              await _port.showOngoing(ongoing);
              _shownOngoing = ongoing;
              _refused = null;
            } on Object {
              // Refused (e.g. started from the background): jobs still run
              // while the process lives; tried again when the jobs change.
              _shownOngoing = null;
              _refused = shape;
              rethrow;
            }
          }
        }
      }
      final paused = pausedNotice(s, f, timeout: timeout);
      final pausedShown = paused == null
          ? null
          : NoticePresence(
              title: paused.title,
              text: paused.text,
              percent: paused.percent,
              channel: _progressChannel(f),
              actions: _labels(paused.actions, f),
            );
      if (pausedShown != _shownPaused) {
        _shownPaused = pausedShown;
        if (pausedShown == null) {
          await _port.cancelNotice(NoticeSlot.paused);
        } else {
          await _port.showNotice(NoticeSlot.paused, pausedShown);
        }
      }
    });
    return rethrowSharing ? done : done.then<void>((_) {}, onError: (_) {});
  }

  static String _shapeOf(OngoingPresence p, JobsSnapshot s) =>
      [p.sharing, for (final j in s.running) j.key].join(',');

  static List<(String, String)> _labels(
    List<NoticeAction> actions,
    NoticeFormat f,
  ) => [
    for (final a in actions)
      (
        a.name,
        switch (a) {
          NoticeAction.pause => f.l10n.transferPause,
          NoticeAction.resume => f.l10n.transferResume,
          NoticeAction.cancel => f.l10n.transferCancel,
          NoticeAction.stopSharing => f.l10n.shareNotificationStop,
        },
      ),
  ];

  static PresenceChannelTexts _progressChannel(NoticeFormat f) =>
      PresenceChannelTexts(
        PresenceChannel.progress,
        f.l10n.jobsChannelProgress,
        f.l10n.jobsChannelProgressDescription,
      );

  static PresenceChannelTexts _resultsChannel(NoticeFormat f) =>
      PresenceChannelTexts(
        PresenceChannel.results,
        f.l10n.jobsChannelResults,
        f.l10n.jobsChannelResultsDescription,
      );

  Future<void> dispose() async {
    _disposed = true;
    _endTimer?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    await _stopSharing.close();
    await _open.close();
  }
}
