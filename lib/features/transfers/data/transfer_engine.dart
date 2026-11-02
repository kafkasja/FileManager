import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:kfm/core/db/app_database.dart' show TransferFilesCompanion;
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/utils/random_id.dart';
import 'package:kfm/features/connect/data/known_devices_dao.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_file_id.dart';
import 'package:kfm/features/connect/domain/upload_protocol.dart';
import 'package:kfm/features/transfers/data/transfers_dao.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:kfm/features/transfers/domain/transfer_preprocessor.dart';

/// `<downloads>/<safe device name>`: where downloads from [peerName] go by
/// default (TASK-N9). The peer's name never escapes one folder segment.
String defaultDownloadFolder(String downloadsRoot, String peerName) =>
    '$downloadsRoot/${safeFolderName(peerName)}';

/// A file ended because the user cancelled it.
class _Cancelled implements Exception {
  const new();
}

/// A file failed with an engine code ([TransferErrors]).
class _Fail implements Exception {
  const new(this.code);

  final String code;
}

/// One running file.
class _Run {
  new(this.file, this.job);

  final TransferFile file;
  final TransferJob job;
  int bytes = 0;
  bool cancelled = false;
  String? uploadId;
  Future<void> Function()? _onCancel;
  final Stopwatch _clock = Stopwatch()..start();
  final List<(int, int)> _samples = [];
  int _persistedAtMs = 0;

  Future<void> cancel() async {
    if (cancelled) return;
    cancelled = true;
    await _onCancel?.call();
  }

  /// Bytes per second over the last 3 s.
  double get speed {
    if (_samples.length < 2) return 0;
    final (t0, b0) = _samples.first;
    final (t1, b1) = _samples.last;
    return t1 <= t0 ? 0 : (b1 - b0) * 1000 / (t1 - t0);
  }

  void sample() {
    final now = _clock.elapsedMilliseconds;
    _samples.add((now, bytes));
    while (_samples.length > 2 && now - _samples.first.$1 > 3000) {
      _samples.removeAt(0);
    }
  }
}

/// Runs Wi-Fi transfers (TASK-N9) on the main isolate with chunked async
/// I/O (never a whole file in memory). Up to [maxRunning] files at a time,
/// only for the connected device (one connection at a time), files of a
/// job in `seq` order, oldest job first. Progress: [live] at most every
/// [liveInterval], `bytesDone` persisted at most every [persistInterval]
/// (coalesced write). A failed file restarts from 0 on Retry (N10:
/// resume). Remote calls go through the live connection's pinned client.
class TransferEngine {
  new({
    required this._repo,
    required this._devices,
    required this._local,
    required this._http,
    required this._staging,
    required this._preprocessor,
    required this._addToIndex,
    this._onUnauthorized,
    this.maxRunning = 2,
    this.liveInterval = const Duration(milliseconds: 250),
    this.persistInterval = const Duration(seconds: 2),
    Random? random,
  }) : _random = random ?? Random.secure();

  final TransfersRepository _repo;
  final KnownDevicesRepository _devices;
  final FileSource _local;

  /// The live connection's client for that fingerprint, or null.
  final RemoteHttp? Function(String peerFingerprint) _http;
  final Future<Directory> Function() _staging;
  final TransferPreprocessor _preprocessor;
  final Future<void> Function(List<FileRef> files) _addToIndex;
  final void Function()? _onUnauthorized;
  final int maxRunning;
  final Duration liveInterval;
  final Duration persistInterval;
  final Random _random;

  final Map<int, _Run> _running = {};
  final StreamController<TransferLive> _live = StreamController.broadcast();
  TransferLive _current = TransferLive.empty;
  Timer? _liveTimer;
  StreamSubscription<void>? _inserts;
  String? _connected;
  bool _pumping = false;
  bool _pumpAgain = false;
  bool _disposed = false;

  /// Live bytes and speeds of running files.
  Stream<TransferLive> get live => _live.stream;
  TransferLive get currentLive => _current;

  /// Files running right now.
  int get runningCount => _running.length;

  /// App start: files left running fail (`interrupted`); new rows wake the
  /// engine.
  Future<void> start() async {
    await _repo.failRunning();
    _inserts = _repo.dao.fileInserts().listen((_) => pump());
    pump();
  }

  /// The connected device changed ([peerFingerprint] null = none). Queued
  /// files of that device start; running files of the old one fail on
  /// their own (the client is closed).
  void onConnection(String? peerFingerprint) {
    _connected = peerFingerprint;
    pump();
  }

  /// The known_devices id of [peerFingerprint]; a device connected without
  /// "Remember" gets a temporary row (N6, removed with its last job).
  Future<String> deviceIdFor(String peerFingerprint, String peerName) async {
    final known = await _devices.byFingerprint(peerFingerprint);
    if (known != null) return known.id;
    final saved = await _devices.saveAfterPairing(
      PairedPeer(
        fingerprint: peerFingerprint,
        peerDeviceId: '',
        name: peerName,
        platform: '',
      ),
      temporary: true,
    );
    return saved.id;
  }

  /// One job downloading [remoteFiles] of [peerFingerprint] into
  /// [localFolder].
  Future<String> enqueueDownload(
    List<FileRef> remoteFiles, {
    required String peerFingerprint,
    required String peerName,
    required String localFolder,
  }) async {
    final deviceId = await deviceIdFor(peerFingerprint, peerName);
    final id = await _repo.createJob(
      deviceId: deviceId,
      direction: TransferDirection.download,
      targetPath: localFolder,
      files: [for (final f in remoteFiles) _newFile(f)],
    );
    pump();
    return id;
  }

  /// One job uploading local [files] to [peerFingerprint]'s root [rootId],
  /// folder [path].
  Future<String> enqueueUpload(
    List<FileRef> files, {
    required String peerFingerprint,
    required String peerName,
    required String rootId,
    required String path,
  }) async {
    final deviceId = await deviceIdFor(peerFingerprint, peerName);
    final id = await _repo.createJob(
      deviceId: deviceId,
      direction: TransferDirection.upload,
      targetRootId: rootId,
      targetPath: path,
      files: [for (final f in files) _newFile(f)],
    );
    pump();
    return id;
  }

  static NewTransferFile _newFile(FileRef f) => (
    sourceFileId: f.id,
    name: f.name,
    sizeBytes: f.sizeBytes,
    sourceModifiedAtMs: f.modifiedAt.millisecondsSinceEpoch,
  );

  /// Cancel: queued files end at once, running ones are aborted (their
  /// partials deleted on both sides). Finished files stay.
  Future<void> cancelJob(String jobId) async {
    await _repo.cancelQueued(jobId);
    for (final r in _running.values.toList()) {
      if (r.job.id == jobId) await r.cancel();
    }
  }

  Future<void> cancelFile(String jobId, int fileId) async {
    final run = _running[fileId];
    if (run != null) {
      await run.cancel();
    } else {
      await _repo.cancelQueued(jobId, fileId: fileId);
    }
  }

  /// Failed and cancelled files start again from 0.
  Future<void> retry(String jobId, {int? fileId}) async {
    await _repo.requeue(jobId, fileId: fileId);
    pump();
  }

  Future<int> clearFinished() => _repo.clearFinished();

  /// Starts queued files of the connected device up to [maxRunning].
  void pump() {
    if (_disposed) return;
    if (_pumping) {
      _pumpAgain = true;
      return;
    }
    _pumping = true;
    unawaited(_pump());
  }

  Future<void> _pump() async {
    try {
      do {
        _pumpAgain = false;
        final fp = _connected;
        final free = maxRunning - _running.length;
        if (fp == null || free <= 0 || _http(fp) == null) continue;
        final next = await _repo.dao.nextQueued(
          fp,
          limit: free,
          exclude: _running.keys.toSet(),
        );
        for (final q in next) {
          if (_disposed || _running.length >= maxRunning) break;
          if (_running.containsKey(q.file.id)) continue;
          final run = _Run(q.file, q.job);
          _running[q.file.id] = run;
          unawaited(
            _runFile(run).whenComplete(() {
              _running.remove(q.file.id);
              _publish();
              pump();
            }),
          );
        }
      } while (_pumpAgain && !_disposed);
    } on Object catch (e, st) {
      developer.log(
        'transfer pump failed',
        name: 'kfm.transfers',
        error: e,
        stackTrace: st,
      );
    } finally {
      _pumping = false;
    }
  }

  Future<void> _runFile(_Run run) async {
    final f = run.file;
    final job = run.job;
    await _repo.setFile(
      f.id,
      job.id,
      TransferFilesCompanion(
        status: const Value(TransferFileStatus.running),
        bytesDone: const Value(0),
        error: const Value(null),
        attempts: Value(f.attempts + 1),
      ),
    );
    // Undone (a swipe send) between the pick and the status write.
    if (await _repo.dao.file(f.id) == null) return;
    _startLive();
    try {
      final target = job.direction == TransferDirection.download
          ? await _download(run)
          : await _upload(run);
      await _repo.setFile(
        f.id,
        job.id,
        TransferFilesCompanion(
          status: const Value(TransferFileStatus.done),
          bytesDone: Value(run.bytes),
          targetFileId: Value(target),
        ),
      );
    } on Object catch (e, st) {
      if (run.cancelled || e is _Cancelled) {
        await _repo.setFile(
          f.id,
          job.id,
          const TransferFilesCompanion(
            status: Value(TransferFileStatus.cancelled),
            bytesDone: Value(0),
          ),
        );
        return;
      }
      final code = _codeOf(e);
      if (code == ApiErrorCode.internal.wire) {
        developer.log(
          'transfer failed',
          name: 'kfm.transfers',
          error: e,
          stackTrace: st,
        );
      }
      await _repo.setFile(
        f.id,
        job.id,
        TransferFilesCompanion(
          status: const Value(TransferFileStatus.failed),
          bytesDone: Value(run.bytes),
          error: Value(code),
        ),
      );
    }
  }

  /// The stored error code of [e] (rule 8: every failure shows).
  String _codeOf(Object e) => switch (e) {
    _Fail(:final code) => code,
    RemoteApiException() => e.error.code,
    RemoteUnavailableException() ||
    IOException() ||
    StateError() => TransferErrors.unavailable,
    FileOpException(failure: FileOpFailure.noSpace) =>
      TransferErrors.noSpaceHere,
    FileOpException(failure: FileOpFailure.invalidName) =>
      ApiErrorCode.invalidName.wire,
    FileOpException(failure: FileOpFailure.unavailable) =>
      TransferErrors.unavailable,
    FileOpException(:final failure) => failure.name,
    _ => ApiErrorCode.internal.wire,
  };

  RemoteHttp _client(TransferJob job) =>
      _http(job.deviceFingerprint) ??
      (throw const _Fail(TransferErrors.unavailable));

  /// Runs a remote call; a 401 ends the connection (N5).
  Future<T> _remote<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on RemoteApiException catch (e) {
      if (e.code == ApiErrorCode.unauthorized) _onUnauthorized?.call();
      rethrow;
    }
  }

  // ---- download ----

  Future<String> _download(_Run run) async {
    final f = run.file;
    final job = run.job;
    validateFileName(f.name);
    final http = _client(job);
    final serverId = parseRemoteFileId(f.sourceFileId).serverId;
    final dir = await _staging();
    final free = await _local.freeBytes(dir.path);
    if (free != null && free < f.sizeBytes + kTransferSpaceMarginBytes) {
      throw const _Fail(TransferErrors.noSpaceHere);
    }
    final part = File('${dir.path}/dl-${f.id}.part');
    try {
      final res = await _remote(
        () => http.getStream(ApiRoutes.fileContent(serverId)),
      );
      if (run.cancelled) {
        unawaited(res.listen(null).cancel());
        throw const _Cancelled();
      }
      final expected = res.contentLength >= 0 ? res.contentLength : null;
      final raf = await part.open(mode: FileMode.write);
      try {
        await _pipe(run, res, raf);
      } finally {
        await raf.close();
      }
      if (run.cancelled) throw const _Cancelled();
      if (expected != null && run.bytes != expected) {
        throw const _Fail(TransferErrors.incomplete);
      }
      final ref = await _local.importFile(
        part,
        targetFolder: job.targetPath,
        name: f.name,
      );
      unawaited(
        _addToIndex([ref]).catchError(
          (Object e) => developer.log(
            'downloaded file not indexed: $e',
            name: 'kfm.transfers',
          ),
        ),
      );
      return ref.id;
    } finally {
      try {
        if (await part.exists()) await part.delete();
      } on FileSystemException catch (e) {
        developer.log('partial not deleted: $e', name: 'kfm.transfers');
      }
    }
  }

  /// Streams [src] into [raf] (one write at a time; the source is paused
  /// meanwhile). Cancel aborts the request.
  Future<void> _pipe(_Run run, Stream<List<int>> src, RandomAccessFile raf) {
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
                _progress(run, run.bytes + chunk.length);
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
    run._onCancel = () async {
      await sub.cancel();
      end(const _Cancelled());
    };
    // Cancelled while the request was opening.
    if (run.cancelled) unawaited(run._onCancel!());
    return done.future;
  }

  // ---- upload ----

  Future<String> _upload(_Run run) async {
    final f = run.file;
    final job = run.job;
    final http = _client(job);
    final rootId = job.targetRootId;
    if (rootId == null) throw _Fail(ApiErrorCode.forbiddenPath.wire);
    final source = await _local.stat(f.sourceFileId);
    if (source == null) throw const _Fail(TransferErrors.sourceGone);
    final prepared = await _preprocessor.prepare(source, _local);
    final uploadId = randomHexId(_random);
    run.uploadId = uploadId;
    var completed = false;
    try {
      if (run.cancelled) throw const _Cancelled();
      await _remote(
        () => http.postJson(
          ApiRoutes.uploads,
          CreateUploadDto(
            uploadId: uploadId,
            rootId: rootId,
            path: job.targetPath,
            name: f.name,
            size: prepared.sizeBytes,
          ).toJson(),
          decode: UploadStatusDto.fromJson,
        ),
      );
      var offset = 0;
      final size = prepared.sizeBytes;
      while (offset < size) {
        if (run.cancelled) throw const _Cancelled();
        final end = min(offset + kTransferChunkBytes, size);
        final status = await _remote(
          () => http.putStream(
            ApiRoutes.uploadChunk(uploadId),
            _counted(run, prepared.read(offset, end), offset),
            end - offset,
            decode: UploadStatusDto.fromJson,
            query: {'offset': '$offset'},
          ),
        );
        if (status.received != end) {
          throw const _Fail(TransferErrors.incomplete);
        }
        offset = end;
        _progress(run, offset);
      }
      if (run.cancelled) throw const _Cancelled();
      final done = await _remote(
        () => http.postJson(
          ApiRoutes.uploadComplete(uploadId),
          const <String, Object?>{},
          decode: UploadCompletedDto.fromJson,
          // Publishing a large file on the other device takes a while.
          timeout: const Duration(minutes: 5),
        ),
      );
      completed = true;
      return done.finalId;
    } finally {
      if (!completed) {
        // Best effort: N10's cleanup removes what is left.
        unawaited(
          http
              .deleteJson<void>(ApiRoutes.upload(uploadId), decode: (_) {})
              .then<void>((_) {}, onError: (Object _) {}),
        );
      }
      try {
        await prepared.cleanup();
      } on Object catch (e) {
        developer.log('prepared file not cleaned: $e', name: 'kfm.transfers');
      }
    }
  }

  /// [src] with progress from [base]; a cancel ends it with an error, which
  /// aborts the request.
  Stream<List<int>> _counted(_Run run, Stream<List<int>> src, int base) {
    var sent = base;
    late final StreamController<List<int>> out;
    StreamSubscription<List<int>>? sub;
    out = StreamController<List<int>>(
      onListen: () {
        // Cancelled in onCancel and by the run's cancel.
        final s = src.listen(
          (chunk) {
            out.add(chunk);
            sent += chunk.length;
            _progress(run, sent);
          },
          onError: out.addError,
          onDone: () => unawaited(out.close()),
          cancelOnError: true,
        );
        sub = s;
        run._onCancel = () async {
          await s.cancel();
          if (!out.isClosed) {
            out.addError(const _Cancelled());
            unawaited(out.close());
          }
        };
        if (run.cancelled) unawaited(run._onCancel!());
      },
      onPause: () => sub?.pause(),
      onResume: () => sub?.resume(),
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  // ---- progress ----

  void _progress(_Run run, int bytes) {
    run.bytes = bytes;
    final now = run._clock.elapsedMilliseconds;
    if (now - run._persistedAtMs >= persistInterval.inMilliseconds) {
      run._persistedAtMs = now;
      _repo.setProgress(run.file.id, bytes).fireAndForget();
    }
  }

  void _startLive() {
    _liveTimer ??= Timer.periodic(liveInterval, (_) => _publish());
  }

  void _publish() {
    if (_disposed) return;
    final speeds = <String, double>{};
    for (final r in _running.values) {
      r.sample();
      speeds[r.job.id] = (speeds[r.job.id] ?? 0) + r.speed;
    }
    _current = TransferLive(
      bytes: {for (final r in _running.values) r.file.id: r.bytes},
      bytesPerSecond: speeds,
    );
    _live.add(_current);
    if (_running.isEmpty) {
      _liveTimer?.cancel();
      _liveTimer = null;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _liveTimer?.cancel();
    await _inserts?.cancel();
    // Running files are left as they are: the next start marks them
    // `interrupted`.
    await _live.close();
  }
}
