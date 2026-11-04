import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:meta/meta.dart';

/// Chunks [hashStreamInIsolate] hands to its worker before it waits for
/// the worker to catch up (Q8: without a bound a fast source was read
/// ahead into memory, ~850 MB extra for a 1 GB file).
const int kHashChunksInFlight = 16;

/// SHA-256 of the file at [path] (bytes `[start, end)`), lowercase hex,
/// computed in a worker isolate (rule 4: the UI isolate never hashes).
/// Shared by N10 (sender hash), N11 (verify) and later U2/X3/C2.
Future<String> hashFileInIsolate(String path, {int? start, int? end}) =>
    Isolate.run(() async {
      final digest = await sha256.bind(File(path).openRead(start, end)).first;
      return digest.toString();
    });

/// SHA-256 of [f]: through its dart:io path when it has a readable one
/// (`/…` on Android, `C:/…` on Windows), otherwise [source]'s stream
/// (MediaStore content). Off the UI isolate.
Future<String> hashFileRef(FileRef f, FileSource source) async {
  if (File(f.path).isAbsolute && await File(f.path).exists()) {
    try {
      return await hashFileInIsolate(f.path);
    } on FileSystemException {
      // Not readable through dart:io (scoped storage): use the source.
    }
  }
  return await hashStreamInIsolate(source.openRead(f));
}

/// SHA-256 of [source] (for files without a dart:io path, e.g. MediaStore
/// content): the stream is read here, each chunk is handed to a worker
/// isolate as [TransferableTypedData], and the digest is computed there.
/// At most [kHashChunksInFlight] chunks wait for the worker: the source is
/// paused until it acknowledges them, so memory stays bounded however
/// large the file is.
Future<String> hashStreamInIsolate(Stream<List<int>> source) async {
  final results = ReceivePort();
  final errors = ReceivePort();
  final exits = ReceivePort();
  final ready = Completer<SendPort>();
  final done = Completer<String>();
  var inFlight = 0;
  Completer<void>? room;
  results.listen((m) {
    switch (m) {
      case final SendPort p:
        ready.complete(p);
      case final int acked:
        inFlight -= acked;
        if (inFlight < kHashChunksInFlight) {
          room?.complete();
          room = null;
        }
      case final String hex:
        if (!done.isCompleted) done.complete(hex);
    }
  });
  errors.listen((e) {
    if (done.isCompleted) return;
    final message = e is List && e.isNotEmpty ? '${e.first}' : '$e';
    done.completeError(StateError('hash isolate failed: $message'));
  });
  exits.listen((_) {
    if (!done.isCompleted) {
      done.completeError(StateError('hash isolate exited early'));
    }
  });
  final isolate = await Isolate.spawn(
    _hashWorker,
    results.sendPort,
    onError: errors.sendPort,
    onExit: exits.sendPort,
  );
  try {
    final worker = await Future.any([
      ready.future,
      done.future.then<SendPort>((_) => throw StateError('no worker')),
    ]);
    await for (final chunk in source) {
      if (chunk.isEmpty) continue;
      while (inFlight >= kHashChunksInFlight) {
        final wait = room ??= Completer<void>();
        // A failed worker ends the wait with its error.
        await Future.any([wait.future, done.future]);
      }
      worker.send(
        TransferableTypedData.fromList([
          if (chunk is Uint8List) chunk else Uint8List.fromList(chunk),
        ]),
      );
      inFlight++;
      debugOnHashChunkSent?.call(inFlight);
    }
    worker.send(null);
    return await done.future;
  } finally {
    results.close();
    errors.close();
    exits.close();
    isolate.kill();
  }
}

/// Test hook: called after each chunk is handed to the worker with the
/// number of chunks it hasn't acknowledged yet.
@visibleForTesting
void Function(int inFlight)? debugOnHashChunkSent;

void _hashWorker(SendPort out) {
  final inbox = ReceivePort();
  final sink = _DigestSink();
  final input = sha256.startChunkedConversion(sink);
  out.send(inbox.sendPort);
  inbox.listen((m) {
    if (m is TransferableTypedData) {
      input.add(m.materialize().asUint8List());
      out.send(1);
      return;
    }
    input.close();
    out.send(sink.value.toString());
    inbox.close();
  });
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
