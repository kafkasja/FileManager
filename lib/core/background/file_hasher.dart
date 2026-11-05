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
  final session = await HashSession.start(blockBytes: 0);
  try {
    await for (final chunk in source) {
      await session.add(chunk);
    }
    return await session.close();
  } finally {
    session.dispose();
  }
}

/// Bytes [HashSession.add] collects before it hands them to the worker
/// (fewer isolate messages for 64 KiB network chunks).
const int kHashBlockBytes = 1024 * 1024;

/// A running SHA-256 in a worker isolate, fed while bytes are sent or
/// received (TASK-E1: no second read of a 312 MB file after the transfer).
/// The hash state can't be saved, so a resumed transfer re-feeds the part
/// already on disk with [addFile] first. At most [kHashChunksInFlight]
/// blocks wait for the worker ([add] waits for room), so memory stays
/// bounded.
class HashSession {
  new _(this._isolate, this._worker, this._ports, this._blockBytes);

  /// Starts the worker. [blockBytes] 0 sends every chunk as it comes.
  static Future<HashSession> start({int blockBytes = kHashBlockBytes}) async {
    final results = ReceivePort();
    final errors = ReceivePort();
    final exits = ReceivePort();
    final ready = Completer<SendPort>();
    final early = Completer<SendPort>();
    HashSession? session;
    results.listen((m) {
      switch (m) {
        case final SendPort p:
          ready.complete(p);
        case final int acked:
          session?._acked(acked);
        case final String hex:
          session?._finish(hex);
      }
    });
    void fail(Object e) {
      final s = session;
      if (s != null) {
        s._fail(e);
      } else if (!early.isCompleted) {
        early.completeError(e);
      }
    }

    errors.listen((e) {
      final message = e is List && e.isNotEmpty ? '${e.first}' : '$e';
      fail(StateError('hash isolate failed: $message'));
    });
    exits.listen((_) => fail(StateError('hash isolate exited early')));
    final isolate = await Isolate.spawn(
      _hashWorker,
      results.sendPort,
      onError: errors.sendPort,
      onExit: exits.sendPort,
    );
    final SendPort worker;
    try {
      worker = await Future.any([ready.future, early.future]);
    } on Object {
      results.close();
      errors.close();
      exits.close();
      isolate.kill();
      rethrow;
    }
    return session = HashSession._(isolate, worker, [
      results,
      errors,
      exits,
    ], blockBytes);
  }

  final Isolate _isolate;
  final SendPort _worker;
  final List<ReceivePort> _ports;
  final int _blockBytes;
  // Chunks waiting to be sent as one block (copied once, when sent).
  final List<TypedData> _buffer = [];
  int _buffered = 0;
  final Completer<String> _done = Completer<String>();
  int _inFlight = 0;
  Completer<void>? _room;
  bool _closed = false;
  bool _disposed = false;

  /// Bytes fed so far.
  int get length => _length;
  int _length = 0;

  void _acked(int n) {
    _inFlight -= n;
    if (_inFlight < kHashChunksInFlight) {
      _room?.complete();
      _room = null;
    }
  }

  void _finish(String hex) {
    if (!_done.isCompleted) _done.complete(hex);
  }

  void _fail(Object e) {
    if (!_done.isCompleted) _done.completeError(e);
    _room?.complete();
    _room = null;
  }

  Future<void> _waitForRoom() async {
    while (_inFlight >= kHashChunksInFlight && !_done.isCompleted) {
      final wait = _room ??= Completer<void>();
      await wait.future;
    }
    // A failed worker ends every wait with its error.
    if (_done.isCompleted) await _done.future;
  }

  Future<void> _send(Object message) async {
    await _waitForRoom();
    _worker.send(message);
    _inFlight++;
    debugOnHashChunkSent?.call(_inFlight);
  }

  Future<void> _flushBuffer() async {
    if (_buffer.isEmpty) return;
    final block = TransferableTypedData.fromList(List.of(_buffer));
    _buffer.clear();
    _buffered = 0;
    await _send(block);
  }

  /// Feeds [bytes]. A `Uint8List` is kept until its block is sent: the
  /// caller must not change it (stream chunks never are).
  Future<void> add(List<int> bytes) async {
    if (_closed) throw StateError('HashSession closed');
    if (bytes.isEmpty) return;
    _length += bytes.length;
    if (_blockBytes <= 0) {
      await _send(
        TransferableTypedData.fromList([
          if (bytes is Uint8List) bytes else Uint8List.fromList(bytes),
        ]),
      );
      return;
    }
    _buffer.add(bytes is Uint8List ? bytes : Uint8List.fromList(bytes));
    _buffered += bytes.length;
    if (_buffered >= _blockBytes) await _flushBuffer();
  }

  /// Feeds bytes `[start, end)` of the file at [path]; the worker reads
  /// them itself (a resume's prefix).
  Future<void> addFile(String path, int start, int end) async {
    if (_closed) throw StateError('HashSession closed');
    if (end <= start) return;
    await _flushBuffer();
    _length += end - start;
    await _send(<Object>[path, start, end]);
  }

  /// The lowercase hex digest of everything fed.
  Future<String> close() async {
    if (_closed) return await _done.future;
    _closed = true;
    await _flushBuffer();
    await _waitForRoom();
    _worker.send(null);
    return await _done.future;
  }

  /// Ends the worker (after [close], or to give up).
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _ports.forEach(_closePort);
    _isolate.kill();
    if (!_done.isCompleted) {
      _done.completeError(StateError('HashSession disposed'));
      // Nobody may be listening.
      _done.future.ignore();
    }
  }
}

void _closePort(ReceivePort p) => p.close();

/// Test hook: called after each chunk is handed to the worker with the
/// number of chunks it hasn't acknowledged yet.
@visibleForTesting
void Function(int inFlight)? debugOnHashChunkSent;

void _hashWorker(SendPort out) {
  final inbox = ReceivePort();
  final sink = _DigestSink();
  final input = sha256.startChunkedConversion(sink);
  out.send(inbox.sendPort);
  // In order: a file range is read completely before the next block.
  var chain = Future<void>.value();
  inbox.listen((m) {
    chain = chain.then((_) async {
      if (m is TransferableTypedData) {
        input.add(m.materialize().asUint8List());
        out.send(1);
        return;
      }
      if (m is List<Object>) {
        final file = File(m[0] as String);
        await file.openRead(m[1] as int, m[2] as int).forEach(input.add);
        out.send(1);
        return;
      }
      input.close();
      out.send(sink.value.toString());
      inbox.close();
    });
  });
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
