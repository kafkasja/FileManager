import 'dart:async';
import 'dart:io';

import 'package:kfm/features/transfers/domain/transfer_job.dart';

/// A file ended because the user cancelled or paused it, or its device
/// went away (the engine knows which from the [TransferRun]).
class TransferStopped implements Exception {
  const new();
}

/// A file failed with an engine code ([TransferErrors]).
class TransferFailure implements Exception {
  const new(this.code);

  final String code;

  @override
  String toString() => 'TransferFailure($code)';
}

/// One running file (TASK-N9/N10): live bytes, the durable offset, and
/// the abort hook of its in-flight request.
class TransferRun {
  new(this.file, this.job, {this._onProgress});

  final TransferFile file;
  final TransferJob job;
  final void Function(TransferRun run)? _onProgress;

  /// Bytes moved so far (live).
  int bytes = 0;

  /// Bytes the receiving side has durably (upload: the server's
  /// `received`; download: bytes written to the local part).
  int confirmed = 0;
  bool cancelled = false;

  /// Paused by the user or because the device went away: partials stay.
  bool paused = false;

  /// The server upload handle in use.
  String? uploadId;

  /// Aborts the in-flight request (set by the stream helpers).
  Future<void> Function()? onAbort;

  final Stopwatch clock = Stopwatch()..start();
  final List<(int, int)> _samples = [];

  /// When `bytesDone` was last persisted (engine bookkeeping).
  int persistedAtMs = 0;

  bool get stopped => cancelled || paused;

  Future<void> cancel() async {
    if (stopped) return;
    cancelled = true;
    await onAbort?.call();
  }

  /// Network use stops at once; the partial is kept for a resume.
  Future<void> pause() async {
    if (stopped) return;
    paused = true;
    await onAbort?.call();
  }

  void progress(int value) {
    bytes = value;
    _onProgress?.call(this);
  }

  void confirm(int value) {
    confirmed = value;
    progress(value);
  }

  /// Bytes per second over the last 3 s.
  double get speed {
    if (_samples.length < 2) return 0;
    final (t0, b0) = _samples.first;
    final (t1, b1) = _samples.last;
    return t1 <= t0 ? 0 : (b1 - b0) * 1000 / (t1 - t0);
  }

  void sample() {
    final now = clock.elapsedMilliseconds;
    _samples.add((now, bytes));
    while (_samples.length > 2 && now - _samples.first.$1 > 3000) {
      _samples.removeAt(0);
    }
  }
}

/// Streams [src] into [raf] after [run]'s current bytes (one write at a
/// time; the source is paused meanwhile). Every written chunk counts as
/// confirmed. A cancel or pause aborts the request.
Future<void> pipeToFile(
  TransferRun run,
  Stream<List<int>> src,
  RandomAccessFile raf,
) {
  final done = Completer<void>();
  var pending = Future<void>.value();
  late final StreamSubscription<List<int>> sub;
  void end([Object? error]) {
    unawaited(
      pending.then<void>((_) {}, onError: (Object _) {}).whenComplete(() {
        if (done.isCompleted) return;
        if (error != null) {
          done.completeError(error);
        } else {
          done.complete();
        }
      }),
    );
  }

  sub = src.listen(
    (chunk) {
      sub.pause();
      pending = raf
          .writeFrom(chunk)
          .then<void>(
            (_) {
              run.confirm(run.confirmed + chunk.length);
              sub.resume();
            },
            onError: (Object e) {
              unawaited(sub.cancel());
              end(e);
            },
          );
    },
    onError: end,
    onDone: end,
    cancelOnError: true,
  );
  run.onAbort = () async {
    await sub.cancel();
    end(const TransferStopped());
  };
  // Stopped while the request was opening.
  if (run.stopped) unawaited(run.onAbort!());
  return done.future;
}

/// [src] with live progress from [base]; a cancel or pause ends it with an
/// error, which aborts the request it feeds.
Stream<List<int>> countedStream(
  TransferRun run,
  Stream<List<int>> src,
  int base,
) {
  var sent = base;
  late final StreamController<List<int>> out;
  StreamSubscription<List<int>>? sub;
  out = StreamController<List<int>>(
    onListen: () {
      final s = src.listen(
        (chunk) {
          out.add(chunk);
          sent += chunk.length;
          run.progress(sent);
        },
        onError: out.addError,
        onDone: () => unawaited(out.close()),
        cancelOnError: true,
      );
      sub = s;
      run.onAbort = () async {
        await s.cancel();
        if (!out.isClosed) {
          out.addError(const TransferStopped());
          unawaited(out.close());
        }
      };
      if (run.stopped) unawaited(run.onAbort!());
    },
    onPause: () => sub?.pause(),
    onResume: () => sub?.resume(),
    onCancel: () => sub?.cancel(),
  );
  return out.stream;
}
