import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'in_app_jobs.g.dart';

/// A resumable piece of in-app background work (C2 similar scan, C3 labels,
/// C5 groups). Contract: TASK-C3 §5.
abstract interface class BackgroundJob {
  String get name;

  /// Runs until done or [JobContext.shouldStop]; must check it between
  /// batches. Restarts from its own persisted state, never from memory.
  Future<void> run(JobContext ctx);
}

abstract interface class JobContext {
  bool get shouldStop;
}

class _RunContext implements JobContext {
  bool stopped = false;

  @override
  bool get shouldStop => stopped;
}

/// Runs registered jobs one at a time, only while the index is idle
/// (indexStatusProvider emits IndexIdle) and the app is resumed. Pausing the
/// app (or a new scan) sets shouldStop; resuming / idle again runs the queue
/// again. In-app only: H2's `BackgroundScheduler` (WorkManager) is the one
/// that runs while the app is closed.
class InAppJobRunner {
  final List<BackgroundJob> _jobs = [];
  bool _started = false;
  bool _disposed = false;
  bool _indexIdle = false;
  bool _resumed = true;
  _RunContext? _current;
  bool _again = false;
  Future<void>? _loop;

  /// Whether a job is running right now.
  bool get isRunning => _loop != null;

  bool get _mayRun => _started && !_disposed && _indexIdle && _resumed;

  /// Adds [job] at the end of the queue (once).
  void register(BackgroundJob job) {
    if (_jobs.contains(job)) return;
    _jobs.add(job);
    kick();
  }

  void unregister(BackgroundJob job) => _jobs.remove(job);

  /// Allows running; the provider calls it once.
  void start() {
    _started = true;
    kick();
  }

  /// Runs the queue again now when allowed (settings toggles such as
  /// "Find similar photos"). While a run is going, the queue runs once more
  /// after it.
  void kick() {
    if (!_mayRun) return;
    if (_loop != null) {
      _again = true;
      return;
    }
    _loop = _drain().whenComplete(() => _loop = null);
  }

  /// F5's index status: jobs run only while it is idle.
  void setIndexIdle({required bool idle}) {
    _indexIdle = idle;
    _changed();
  }

  /// App lifecycle: jobs run only while resumed.
  void setResumed({required bool resumed}) {
    _resumed = resumed;
    _changed();
  }

  void _changed() {
    if (_mayRun) {
      kick();
    } else {
      _current?.stopped = true;
      _again = false;
    }
  }

  /// Completes when the current run (if any) has finished. For tests and
  /// shutdown.
  Future<void> idle() async {
    while (_loop != null) {
      await _loop;
    }
  }

  Future<void> _drain() async {
    do {
      _again = false;
      for (final job in [..._jobs]) {
        if (!_mayRun) return;
        final ctx = _current = _RunContext();
        try {
          await job.run(ctx);
          // Jobs report their own errors to their UI state (rule 8); the
          // runner only keeps the others going.
          // ignore: avoid_catches_without_on_clauses
        } catch (e, st) {
          developer.log(
            'job ${job.name} failed',
            name: 'kfm.jobs',
            error: e,
            stackTrace: st,
          );
        } finally {
          _current = null;
        }
      }
    } while (_again && _mayRun);
  }

  void dispose() {
    _disposed = true;
    _current?.stopped = true;
    _jobs.clear();
  }
}

/// Lives as long as the app (watched in `App.build`), so its listeners are
/// never paused.
@Riverpod(keepAlive: true)
InAppJobRunner inAppJobRunner(Ref ref) {
  final runner = InAppJobRunner();
  final state = WidgetsBinding.instance.lifecycleState;
  runner.setResumed(resumed: state == null || _runsIn(state));
  final lifecycle = AppLifecycleListener(
    onStateChange: (s) => runner.setResumed(resumed: _runsIn(s)),
  );
  ref
    ..onDispose(() {
      lifecycle.dispose();
      runner.dispose();
    })
    ..listen(
      indexStatusProvider,
      (_, next) => runner.setIndexIdle(idle: next.value is IndexIdle),
      fireImmediately: true,
    );
  runner.start();
  return runner;
}

/// `inactive` (notification shade, dialogs) keeps running; hidden/paused
/// stop the jobs.
bool _runsIn(AppLifecycleState s) =>
    s == AppLifecycleState.resumed || s == AppLifecycleState.inactive;
