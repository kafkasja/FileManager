import 'dart:async';
import 'dart:isolate';

import 'package:kfm/core/diagnostics/error_log.dart';

/// H5: [Isolate.spawn] that also sends the isolate's uncaught errors to the
/// error log ([ErrorLog.current], source `isolate`). The isolate's own
/// result/error protocol is unchanged; this only catches what escapes it.
/// The error port closes when the isolate exits.
Future<Isolate> spawnLogged<T>(
  void Function(T message) entry,
  T message, {
  String? debugName,
  ErrorLog? log,
}) async {
  final errors = RawReceivePort();
  final exit = RawReceivePort();
  void close() {
    errors.close();
    exit.close();
  }

  void onError(Object? pair) {
    // [error.toString(), stack.toString()] (see Isolate.addErrorListener).
    if (pair is! List || pair.length != 2) return;
    final target = log ?? ErrorLog.current;
    if (target == null) return;
    final stack = pair[1];
    target
        .record(
          ErrorLogEntry(
            at: DateTime.now().toUtc(),
            source: ErrorSource.isolate,
            error: '${debugName ?? 'isolate'}: ${pair[0]}',
            stack: stack is String ? StackTrace.fromString(stack) : null,
          ),
        )
        .ignore();
  }

  errors.handler = onError;
  exit.handler = (_) => close();
  try {
    return await Isolate.spawn<T>(
      entry,
      message,
      debugName: debugName,
      onError: errors.sendPort,
      onExit: exit.sendPort,
    );
  } on Object {
    close();
    rethrow;
  }
}
