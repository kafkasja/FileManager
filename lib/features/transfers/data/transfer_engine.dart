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
import 'package:kfm/features/connect/data/known_devices_dao.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/upload_protocol.dart';
import 'package:kfm/features/transfers/data/chunked_uploader.dart';
import 'package:kfm/features/transfers/data/resumable_downloader.dart';
import 'package:kfm/features/transfers/data/transfer_run.dart';
import 'package:kfm/features/transfers/data/transfers_dao.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:kfm/features/transfers/domain/transfer_preprocessor.dart';

/// `<downloads>/<safe device name>`: where downloads from [peerName] go by
/// default (TASK-N9). The peer's name never escapes one folder segment.
String defaultDownloadFolder(String downloadsRoot, String peerName) =>
    '$downloadsRoot/${safeFolderName(peerName)}';

/// Client partials untouched this long are deleted at start (N10).
const Duration kStaleDownloadPartAge = Duration(days: 7);

/// What a failed try means (N10 precedence).
enum _Outcome {
  /// The device is gone: the job waits for it, no attempt is counted.
  connection,

  /// The connection is fine, this request failed: backoff.
  transient,

  /// One side is out of space: the job pauses until Resume.
  noSpace,

  /// Nothing a retry fixes: the file fails (Retry restarts it).
  permanent,
}

/// Pairing failures after which automatic reconnects stop until the next
/// connection event (the other device said no, or doesn't know us).
const Set<PairingFailure> _stopAutoReconnect = {
  PairingFailure.declined,
  PairingFailure.timedOut,
  PairingFailure.notAllowed,
  PairingFailure.keyChanged,
  PairingFailure.cancelled,
};

/// Runs Wi-Fi transfers (TASK-N9/N10) on the main isolate with chunked
/// async I/O (never a whole file in memory; hashes in worker isolates). Up
/// to [maxRunning] files at a time, only for the connected device (one
/// connection at a time), files of a job in `seq` order, oldest job first.
///
/// N10 resume rules, in this order:
/// 1. The device is gone (no client, a 401, or a network error whose quick
///    `GET /v1/session` probe fails) → the job is `paused(waitingForDevice)`
///    without counting an attempt; it resumes on the next connection to
///    that device (or a successful probe while still connected), and
///    remembered devices are reconnected automatically with backoff.
/// 2. The connection is fine but the request failed → the file retries
///    after [retryBase] × 2ⁿ (capped at [retryCap]); after [maxAttempts]
///    it fails with Retry.
/// 3. Out of space → `paused(noSpace)` until Resume.
/// 4. Pause → `paused(user)`; in-flight requests are aborted at once.
/// Partials (the local `dl-*.part`, the server's upload) are kept for all
/// four and deleted only on cancel, a permanent failure or completion.
class TransferEngine {
  new({
    required this._repo,
    required this._devices,
    required FileSource local,
    required this._http,
    required this._staging,
    required TransferPreprocessor preprocessor,
    required Future<void> Function(List<FileRef> files) addToIndex,
    this._onUnauthorized,
    this._reconnect,
    bool Function()? isForeground,
    Future<bool> Function(RemoteHttp http)? probe,
    Future<String> Function(PreparedSource p) hash = hashPrepared,
    int chunkBytes = kTransferChunkBytes,
    this.maxRunning = 2,
    this.liveInterval = const Duration(milliseconds: 250),
    this.persistInterval = const Duration(seconds: 2),
    this.retryBase = const Duration(seconds: 2),
    this.retryCap = const Duration(seconds: 60),
    this.maxAttempts = 10,
    this.reconnectBase = const Duration(seconds: 5),
    this.reconnectCap = const Duration(seconds: 60),
    Random? random,
  }) : _isForeground = isForeground ?? _always,
       _probe = probe ?? _sessionProbe {
    _downloader = ResumableDownloader(
      local: local,
      staging: _staging,
      save: _repo.saveFile,
      addToIndex: addToIndex,
    );
    _uploader = ChunkedUploader(
      local: local,
      preprocessor: preprocessor,
      save: _repo.saveFile,
      hash: hash,
      chunkBytes: chunkBytes,
      random: random,
    );
  }

  final TransfersRepository _repo;
  final KnownDevicesRepository _devices;

  /// The live connection's client for that fingerprint, or null.
  final RemoteHttp? Function(String peerFingerprint) _http;
  final Future<Directory> Function() _staging;
  final void Function()? _onUnauthorized;

  /// `KnownDeviceConnector.reconnect` (N6): returns once connected.
  final Future<void> Function(String peerFingerprint)? _reconnect;
  final bool Function() _isForeground;
  final Future<bool> Function(RemoteHttp http) _probe;
  late final ResumableDownloader _downloader;
  late final ChunkedUploader _uploader;

  final int maxRunning;
  final Duration liveInterval;
  final Duration persistInterval;
  final Duration retryBase;
  final Duration retryCap;
  final int maxAttempts;
  final Duration reconnectBase;
  final Duration reconnectCap;

  final Map<int, TransferRun> _running = {};
  final StreamController<TransferLive> _live = StreamController.broadcast();
  final Set<Timer> _retryTimers = {};
  TransferLive _current = TransferLive.empty;
  Timer? _liveTimer;
  Timer? _recoveryTimer;
  StreamSubscription<void>? _inserts;
  String? _connected;
  bool _autoReconnect = false;
  bool _reconnecting = false;
  int _recoveryFailures = 0;
  bool _pumping = false;
  bool _pumpAgain = false;
  bool _disposed = false;

  static bool _always() => true;

  /// One quick `GET /v1/session`: is the link alive right now?
  static Future<bool> _sessionProbe(RemoteHttp http) async {
    try {
      await http.getJson<void>(
        ApiRoutes.session,
        decode: (_) {},
        timeout: const Duration(seconds: 5),
      );
      return true;
    } on Object {
      return false;
    }
  }

  /// Live bytes and speeds of running files.
  Stream<TransferLive> get live => _live.stream;
  TransferLive get currentLive => _current;

  /// Files running right now.
  int get runningCount => _running.length;

  /// App start: files left running are queued again and their jobs wait
  /// for the device (N10); stale client partials go; new rows wake the
  /// engine.
  Future<void> start() async {
    await _repo.recoverRunning();
    await _purgeStaleParts();
    _inserts = _repo.dao.fileInserts().listen((_) => pump());
    _scheduleRecovery();
    pump();
  }

  /// The connected device changed ([peerFingerprint] null = none). The old
  /// device's jobs wait for it (their running files stop, partials kept);
  /// the new device's waiting jobs resume. [autoReconnect]: whether the
  /// engine may reconnect by itself (not after the user's Disconnect or a
  /// revoke).
  void onConnection(String? peerFingerprint, {bool autoReconnect = false}) {
    final previous = _connected;
    _connected = peerFingerprint;
    _autoReconnect = peerFingerprint == null && autoReconnect;
    if (previous != null && previous != peerFingerprint) {
      unawaited(_deviceLost(previous));
    }
    if (peerFingerprint != null) {
      _recoveryFailures = 0;
      unawaited(_resumeWaiting(peerFingerprint));
    }
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
    _scheduleRecovery();
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

  /// Cancel: queued files end at once, running ones are aborted; every
  /// partial of the job is deleted on both sides. Finished files stay.
  Future<void> cancelJob(String jobId) async {
    final job = await _repo.dao.job(jobId);
    await _repo.cancelQueued(jobId);
    for (final r in _running.values.toList()) {
      if (r.job.id == jobId) await r.cancel();
    }
    if (job != null) {
      for (final f in job.files) {
        if (!_running.containsKey(f.id) &&
            (f.status == TransferFileStatus.queued ||
                f.status == TransferFileStatus.failed)) {
          await _discardPartials(job, f);
        }
      }
    }
  }

  Future<void> cancelFile(String jobId, int fileId) async {
    final run = _running[fileId];
    if (run != null) {
      await run.cancel();
      return;
    }
    await _repo.cancelQueued(jobId, fileId: fileId);
    final job = await _repo.dao.job(jobId);
    final f = job?.files.where((f) => f.id == fileId).firstOrNull;
    if (job != null && f != null) await _discardPartials(job, f);
  }

  /// Pause (N10): running files stop at once, their partials stay; the
  /// job doesn't start again until [resumeJob], even after a reconnect.
  Future<void> pauseJob(String jobId) async {
    await _repo.pauseJob(jobId, TransferPauseReason.user);
    for (final r in _running.values.toList()) {
      if (r.job.id == jobId) await r.pause();
    }
  }

  /// Continue (N10): from where each file stopped. Without a connection to
  /// its device the job waits for it (and may reconnect by itself).
  Future<void> resumeJob(String jobId) async {
    final job = await _repo.dao.job(jobId);
    if (job == null) return;
    if (_connected == job.deviceFingerprint) {
      await _repo.resumeJob(jobId);
    } else {
      await _repo.resumeJob(jobId);
      await _repo.pauseJob(jobId, TransferPauseReason.waitingForDevice);
      _scheduleRecovery();
    }
    pump();
  }

  /// "Reconnect" on a waiting job: N6's reconnect to [peerFingerprint]
  /// (the accept prompt shows on the other device unless it always allows
  /// us). Throws [PairingException] for the caller to show (rule 8).
  Future<void> reconnect(String peerFingerprint) async {
    final connect = _reconnect;
    if (connect == null) {
      throw const PairingException(PairingFailure.offline);
    }
    _reconnecting = true;
    try {
      await connect(peerFingerprint);
    } finally {
      _reconnecting = false;
    }
  }

  /// Failed and cancelled files start again (a failed file resumes from
  /// its partial when one is left).
  Future<void> retry(String jobId, {int? fileId}) async {
    await _repo.requeue(jobId, fileId: fileId);
    pump();
  }

  Future<int> clearFinished() async {
    final finished = [
      for (final j in await _repo.dao.jobs())
        if (j.isFinished) j,
    ];
    final n = await _repo.clearFinished();
    for (final j in finished) {
      for (final f in j.files) {
        if (f.status == TransferFileStatus.failed) {
          await _discardPartials(j, f);
        }
      }
    }
    return n;
  }

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
          now: _repo.now(),
        );
        for (final q in next) {
          if (_disposed || _running.length >= maxRunning) break;
          if (_running.containsKey(q.file.id)) continue;
          final run = TransferRun(q.file, q.job, onProgress: _progress);
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

  Future<void> _runFile(TransferRun run) async {
    final f = run.file;
    final job = run.job;
    run
      ..bytes = f.bytesDone
      ..confirmed = f.bytesDone;
    await _repo.setFile(
      f.id,
      job.id,
      const TransferFilesCompanion(
        status: Value(TransferFileStatus.running),
        error: Value(null),
        nextRetryAt: Value(null),
      ),
    );
    // Undone (a swipe send) or paused between the pick and the write.
    final now = await _repo.dao.job(job.id);
    if (now == null || !now.files.any((x) => x.id == f.id)) return;
    if (now.status == TransferStatus.paused) run.paused = true;
    _startLive();
    try {
      if (run.paused) throw const TransferStopped();
      final http =
          _http(job.deviceFingerprint) ??
          (throw const TransferFailure(TransferErrors.unavailable));
      final target = job.direction == TransferDirection.download
          ? await _downloader.run(run, http)
          : await _uploader.run(run, http);
      await _repo.setFile(
        f.id,
        job.id,
        TransferFilesCompanion(
          status: const Value(TransferFileStatus.done),
          bytesDone: Value(run.confirmed),
          targetFileId: Value(target),
          attempts: const Value(0),
        ),
      );
    } on Object catch (e, st) {
      await _onFailure(run, e, st);
    }
  }

  Future<void> _onFailure(TransferRun run, Object e, StackTrace st) async {
    final f = run.file;
    final job = run.job;
    if (run.cancelled) {
      await _repo.setFile(
        f.id,
        job.id,
        const TransferFilesCompanion(
          status: Value(TransferFileStatus.cancelled),
          bytesDone: Value(0),
        ),
      );
      await _discardPartials(job, f, uploadId: run.uploadId);
      return;
    }
    if (run.paused) {
      await _requeue(run);
      return;
    }
    final code = _codeOf(e);
    final outcome = await _classify(run, e);
    switch (outcome) {
      case _Outcome.connection:
        await _requeue(run, error: code);
        await _repo.pauseJob(job.id, TransferPauseReason.waitingForDevice);
        _scheduleRecovery();
      case _Outcome.noSpace:
        await _requeue(run, error: code);
        await _repo.pauseJob(job.id, TransferPauseReason.noSpace);
      case _Outcome.transient:
        final attempts = f.attempts + 1;
        if (attempts >= maxAttempts) {
          await _fail(run, code, attempts: attempts);
          return;
        }
        final delay = _backoff(retryBase, retryCap, attempts - 1);
        await _requeue(
          run,
          error: code,
          attempts: attempts,
          nextRetryAt: _repo.now().add(delay),
        );
        late final Timer t;
        t = Timer(delay, () {
          _retryTimers.remove(t);
          pump();
        });
        _retryTimers.add(t);
      case _Outcome.permanent:
        if (code == ApiErrorCode.internal.wire) {
          developer.log(
            'transfer failed',
            name: 'kfm.transfers',
            error: e,
            stackTrace: st,
          );
        }
        await _fail(run, code);
        await _discardPartials(job, f, uploadId: run.uploadId);
    }
  }

  /// Back to `queued`, keeping what the other side has.
  Future<void> _requeue(
    TransferRun run, {
    String? error,
    int? attempts,
    DateTime? nextRetryAt,
  }) => _repo.setFile(
    run.file.id,
    run.job.id,
    TransferFilesCompanion(
      status: const Value(TransferFileStatus.queued),
      bytesDone: Value(run.confirmed),
      error: Value(error),
      attempts: attempts == null ? const Value.absent() : Value(attempts),
      nextRetryAt: Value(nextRetryAt),
    ),
  );

  Future<void> _fail(TransferRun run, String code, {int? attempts}) =>
      _repo.setFile(
        run.file.id,
        run.job.id,
        TransferFilesCompanion(
          status: const Value(TransferFileStatus.failed),
          bytesDone: Value(run.confirmed),
          error: Value(code),
          attempts: attempts == null ? const Value(0) : Value(attempts),
          nextRetryAt: const Value(null),
        ),
      );

  /// Deletes [f]'s partial: the local part of a download, the other
  /// device's upload (best effort, when connected).
  Future<void> _discardPartials(
    TransferJob job,
    TransferFile f, {
    String? uploadId,
  }) async {
    if (job.direction == TransferDirection.download) {
      await _downloader.discard(f.id);
      return;
    }
    final id = uploadId ?? f.uploadId;
    if (id == null) return;
    await _repo.saveFile(
      f.id,
      const TransferFilesCompanion(uploadId: Value(null), bytesDone: Value(0)),
    );
    final http = _http(job.deviceFingerprint);
    if (http != null) unawaited(ChunkedUploader.discardRemote(http, id));
  }

  /// The stored error code of [e] (rule 8: every failure shows).
  String _codeOf(Object e) => switch (e) {
    TransferFailure(:final code) => code,
    RemoteApiException() => e.error.code,
    RemoteUnavailableException() ||
    IOException() ||
    TimeoutException() ||
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

  Future<_Outcome> _classify(TransferRun run, Object e) async {
    switch (e) {
      case TransferFailure(:final code):
        return switch (code) {
          TransferErrors.noSpaceHere => _Outcome.noSpace,
          TransferErrors.unavailable => _Outcome.connection,
          TransferErrors.incomplete ||
          TransferErrors.sourceChanged => await _networkOutcome(run),
          _ => _Outcome.permanent,
        };
      case RemoteApiException(:final code, :final status):
        if (code == ApiErrorCode.unauthorized) {
          _onUnauthorized?.call();
          return _Outcome.connection;
        }
        if (code == ApiErrorCode.insufficientStorage) return _Outcome.noSpace;
        // 410: the other device ended the stream (stop sharing, revoke).
        if (code == ApiErrorCode.cancelled) return await _networkOutcome(run);
        if (status >= 500 ||
            code == ApiErrorCode.busy ||
            code == ApiErrorCode.conflict ||
            code == ApiErrorCode.tooManyAttempts) {
          return _Outcome.transient;
        }
        return _Outcome.permanent;
      case RemoteUnavailableException(:final reason):
        if (reason == RemoteUnavailableReason.badResponse) {
          return _Outcome.transient;
        }
        return await _networkOutcome(run);
      case IOException() || TimeoutException() || StateError():
        return await _networkOutcome(run);
      case FileOpException(:final failure):
        return switch (failure) {
          FileOpFailure.noSpace => _Outcome.noSpace,
          FileOpFailure.unavailable => _Outcome.transient,
          _ => _Outcome.permanent,
        };
      default:
        return _Outcome.permanent;
    }
  }

  /// A network-type error: the device is gone unless a quick probe of the
  /// live connection answers.
  Future<_Outcome> _networkOutcome(TransferRun run) async {
    final http = _http(run.job.deviceFingerprint);
    if (http == null) return _Outcome.connection;
    return await _probe(http) ? _Outcome.transient : _Outcome.connection;
  }

  static Duration _backoff(Duration base, Duration cap, int n) {
    final ms = base.inMilliseconds * pow(2, min(n, 20));
    return Duration(milliseconds: min(ms.toInt(), cap.inMilliseconds));
  }

  // ---- device lost / back ----

  Future<void> _deviceLost(String fp) async {
    try {
      await _repo.pauseActiveOfDevice(fp, TransferPauseReason.waitingForDevice);
    } on Object catch (e) {
      developer.log('jobs not paused: $e', name: 'kfm.transfers');
    }
    for (final r in _running.values.toList()) {
      if (r.job.deviceFingerprint == fp) await r.pause();
    }
    _scheduleRecovery();
  }

  Future<void> _resumeWaiting(String fp) async {
    try {
      final ids = await _repo.dao.pausedJobsOf(
        fp,
        TransferPauseReason.waitingForDevice,
      );
      for (final id in ids) {
        await _repo.resumeJob(id);
      }
      if (ids.isNotEmpty) pump();
    } on Object catch (e) {
      developer.log('jobs not resumed: $e', name: 'kfm.transfers');
    }
  }

  /// Ticks while jobs wait for a device: a probe while still connected, an
  /// automatic reconnect (remembered devices, foreground) otherwise. No
  /// timer runs while nothing waits.
  void _scheduleRecovery() => unawaited(_maybeScheduleRecovery());

  Future<void> _maybeScheduleRecovery() async {
    if (_disposed || _recoveryTimer != null) return;
    try {
      if ((await _repo.dao.waitingDevices()).isEmpty) {
        _recoveryFailures = 0;
        return;
      }
    } on Object catch (e) {
      developer.log('recovery not scheduled: $e', name: 'kfm.transfers');
      return;
    }
    if (_disposed || _recoveryTimer != null) return;
    _recoveryTimer = Timer(
      _backoff(reconnectBase, reconnectCap, _recoveryFailures),
      () {
        _recoveryTimer = null;
        unawaited(_recover());
      },
    );
  }

  Future<void> _recover() async {
    if (_disposed) return;
    final List<({String fingerprint, bool temporary})> waiting;
    try {
      waiting = await _repo.dao.waitingDevices();
    } on Object catch (e) {
      developer.log('recovery failed: $e', name: 'kfm.transfers');
      return;
    }
    if (waiting.isEmpty) {
      _recoveryFailures = 0;
      return;
    }
    final fp = _connected;
    if (fp != null) {
      // One connection at a time: other devices wait for the user.
      if (!waiting.any((w) => w.fingerprint == fp)) return;
      final http = _http(fp);
      if (http != null && await _probe(http)) {
        _recoveryFailures = 0;
        await _resumeWaiting(fp);
        return;
      }
    } else {
      final connect = _reconnect;
      final target = waiting.where((w) => !w.temporary).firstOrNull;
      if (!_autoReconnect || connect == null || target == null) return;
      if (_isForeground() && !_reconnecting) {
        _reconnecting = true;
        try {
          await connect(target.fingerprint);
          // `onConnection` resumes its jobs.
          _recoveryFailures = 0;
          return;
        } on PairingException catch (e) {
          if (_stopAutoReconnect.contains(e.failure)) {
            _autoReconnect = false;
            return;
          }
        } on Object catch (e) {
          developer.log('reconnect failed: $e', name: 'kfm.transfers');
        } finally {
          _reconnecting = false;
        }
      }
      if (_connected != null) return;
    }
    _recoveryFailures++;
    _scheduleRecovery();
  }

  /// Client parts without a file that may still resume, or untouched for
  /// [kStaleDownloadPartAge], are deleted.
  Future<void> _purgeStaleParts() async {
    try {
      final dir = await _staging();
      if (!await dir.exists()) return;
      final keep = await _repo.dao.unfinishedFileIds();
      final now = DateTime.now();
      await for (final e in dir.list()) {
        final name = e.uri.pathSegments.last;
        if (e is! File || !name.startsWith('dl-') || !name.endsWith('.part')) {
          continue;
        }
        final id = int.tryParse(name.substring(3, name.length - 5));
        final stale =
            now.difference(await e.lastModified()) > kStaleDownloadPartAge;
        if (id == null || !keep.contains(id) || stale) await e.delete();
      }
    } on Object catch (e) {
      developer.log('stale parts not purged: $e', name: 'kfm.transfers');
    }
  }

  // ---- progress ----

  void _progress(TransferRun run) {
    final now = run.clock.elapsedMilliseconds;
    if (now - run.persistedAtMs >= persistInterval.inMilliseconds) {
      run.persistedAtMs = now;
      _repo.setProgress(run.file.id, run.confirmed).fireAndForget();
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
    _recoveryTimer?.cancel();
    for (final t in _retryTimers) {
      t.cancel();
    }
    _retryTimers.clear();
    await _inserts?.cancel();
    // Running files are left as they are: the next start queues them
    // again and they resume.
    await _live.close();
  }
}
