import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:meta/meta.dart';

/// A failed queued write, published on [DbWriteQueue.errors].
@immutable
class DbWriteError {
  const new(this.coalesceKey, this.error, this.stackTrace);

  final String? coalesceKey;
  final Object error;
  final StackTrace stackTrace;
}

class _Job {
  new(this.coalesceKey, this.run);

  final String? coalesceKey;
  final Future<void> Function() run;
  final Completer<void> completer = Completer<void>();
}

/// Ordered, coalescing write queue. Features enqueue and continue
/// immediately; writes run one at a time in enqueue order (so the undo log
/// keeps action order) and failures go to [errors], never swallowed.
///
/// The F5 indexer isolate writes in bulk through its own connection and does
/// not use this queue.
class DbWriteQueue {
  static const _largeQueueWarning = 500;

  final Queue<_Job> _pending = Queue<_Job>();
  final StreamController<DbWriteError> _errors =
      StreamController<DbWriteError>.broadcast();
  Future<void>? _draining;
  bool _closed = false;

  Stream<DbWriteError> get errors => _errors.stream;

  /// Number of jobs waiting (not counting the one running).
  int get pendingCount => _pending.length;

  /// Queues [run]. If a job with the same non-null [coalesceKey] is still
  /// waiting, it is replaced and its future completes with the replacement.
  /// Pass null to never coalesce (undo-log appends MUST pass null).
  Future<void> enqueue(String? coalesceKey, Future<void> Function() run) {
    if (_closed) {
      return Future<void>.error(StateError('DbWriteQueue closed'));
    }
    final job = _Job(coalesceKey, run);
    if (coalesceKey != null) {
      final replaced = _pending
          .where((j) => j.coalesceKey == coalesceKey)
          .toList();
      for (final old in replaced) {
        _pending.remove(old);
        job.completer.future
            .then<void>(
              (_) => old.completer.complete(),
              onError: old.completer.completeError,
            )
            .ignore();
      }
    }
    _pending.add(job);
    if (_pending.length == _largeQueueWarning) {
      developer.log(
        'DbWriteQueue has $_largeQueueWarning pending writes',
        name: 'kfm.db',
      );
    }
    _draining ??= _drain();
    return job.completer.future;
  }

  /// Waits for every queued write (app pause, before a batch delete, tests).
  Future<void> flush() async {
    while (_draining != null) {
      await _draining;
    }
  }

  /// Rejects further writes, waits for queued ones, then closes [errors].
  Future<void> close() async {
    _closed = true;
    await flush();
    await _errors.close();
  }

  Future<void> _drain() async {
    // Let enqueue() return before the first write starts.
    await Future<void>.value();
    while (_pending.isNotEmpty) {
      final job = _pending.removeFirst();
      try {
        await job.run();
        job.completer.complete();
      } on Object catch (e, st) {
        _errors.add(DbWriteError(job.coalesceKey, e, st));
        job.completer.completeError(e, st);
      }
    }
    _draining = null;
  }
}

extension FireAndForget on Future<void> {
  /// For queued writes the caller doesn't await: the error is already
  /// published on [DbWriteQueue.errors], so don't report it twice.
  void fireAndForget() => ignore();
}
