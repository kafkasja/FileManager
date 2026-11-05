import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/connect/data/known_devices_dao.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_file_id.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/session/domain/session_source.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/transfers/data/chunked_uploader.dart';
import 'package:kfm/features/transfers/data/resumable_downloader.dart';
import 'package:kfm/features/transfers/data/swipe_sends.dart';
import 'package:kfm/features/transfers/data/transfer_engine.dart';
import 'package:kfm/features/transfers/data/transfers_dao.dart';
import 'package:kfm/features/transfers/data/verified_move_impl.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:kfm/features/transfers/domain/transfer_preprocessor.dart';
import 'package:kfm/features/transfers/domain/verified_move.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

import '../../core/files/fake_file_source.dart';

final String _fp = 'ab' * 32;
const _dl = '/storage/emulated/0/Download/Phone';

/// Response headers of a fake content response.
class _Headers implements HttpHeaders {
  new(this._map);

  final Map<String, String> _map;

  @override
  String? value(String name) => _map[name.toLowerCase()];

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// A content response the test feeds by hand (hold = an in-flight file).
class _Held extends Stream<List<int>> implements HttpClientResponse {
  new(
    this.contentLength, {
    this.statusCode = 200,
    Map<String, String> headers = const {},
  }) : headers = _Headers(headers);

  final StreamController<List<int>> c = StreamController<List<int>>();
  bool cancelled = false;

  @override
  final int contentLength;

  @override
  final int statusCode;

  @override
  final HttpHeaders headers;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    c.onCancel = () => cancelled = true;
    return c.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

typedef _Call = ({
  String method,
  String path,
  Map<String, String> query,
  Object? body,
});

String _etagOf(String serverId) => '"e-$serverId"';

/// The other device: per-prefix JSON answers, held content streams, ranged
/// content with an ETag.
class _Http implements RemoteHttp {
  final List<_Call> calls = [];
  final Map<String, _Held> held = {};
  final Set<String> heldUsed = {};
  final Map<String, List<int>> contents = {};
  final Map<String, ApiErrorCode> failContent = {};

  /// Request headers of every content request.
  final List<Map<String, String>> contentHeaders = [];
  FutureOr<Map<String, Object?>> Function(_Call call)? json;

  int running = 0;
  int maxRunning = 0;

  @override
  Uri get base => Uri.parse('https://192.168.1.20:4433');

  @override
  String? bearerToken;

  Future<T> _json<T>(
    String method,
    String path,
    Object? body,
    T Function(Map<String, Object?>) decode, [
    Map<String, String> query = const {},
  ]) async {
    final call = (method: method, path: path, query: query, body: body);
    calls.add(call);
    return decode(await json?.call(call) ?? const {});
  }

  @override
  Future<T> getJson<T>(
    String path, {
    required T Function(Map<String, Object?> json) decode,
    Map<String, String> query = const {},
    Duration? timeout,
  }) => _json('GET', path, null, decode, query);

  /// Timeouts the client passed to `postJson`, by path.
  final Map<String, Duration?> postTimeouts = {};

  @override
  Future<T> postJson<T>(
    String path,
    Object? body, {
    required T Function(Map<String, Object?> json) decode,
    Duration? timeout,
  }) {
    postTimeouts[path] = timeout;
    return _json('POST', path, body, decode);
  }

  @override
  Future<T> deleteJson<T>(
    String path, {
    required T Function(Map<String, Object?> json) decode,
  }) => _json('DELETE', path, null, decode);

  @override
  Future<T> putStream<T>(
    String path,
    Stream<List<int>> body,
    int length, {
    required T Function(Map<String, Object?> json) decode,
    Map<String, String> query = const {},
  }) async {
    final bytes = <int>[];
    await body.forEach(bytes.addAll);
    return await _json('PUT', path, bytes, decode, query);
  }

  @override
  Future<HttpClientResponse> getStream(
    String path, {
    Map<String, String> query = const {},
    Map<String, String> headers = const {},
  }) async {
    calls.add((method: 'GET', path: path, query: query, body: null));
    contentHeaders.add(headers);
    final serverId = Uri.decodeComponent(path.split('/')[3]);
    if (failContent[serverId] case final code?) {
      throw RemoteApiException(code.status, ApiErrorDto(code.wire, ''));
    }
    running++;
    if (running > maxRunning) maxRunning = running;
    // A held response answers the first request only.
    final h = heldUsed.add(serverId) ? held[serverId] : null;
    if (h != null) {
      unawaited(h.c.done.whenComplete(() => running--));
      return h;
    }
    final bytes = contents[serverId] ?? const [];
    final etag = _etagOf(serverId);
    final range = headers[HttpHeaders.rangeHeader];
    var start = 0;
    if (range != null && headers[HttpHeaders.ifRangeHeader] == etag) {
      start = int.parse(range.substring(6, range.length - 1));
    }
    final body = bytes.sublist(start);
    final r = _Held(
      body.length,
      statusCode: start > 0 ? 206 : 200,
      headers: {
        'etag': etag,
        if (start > 0)
          'content-range': 'bytes $start-${bytes.length - 1}/${bytes.length}',
      },
    );
    unawaited(() async {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      r.c.add(body);
      running--;
      await r.c.close();
    }());
    return r;
  }

  @override
  void close() {}
}

/// A stateful upload server for [_Http.json]: create / status / chunk /
/// complete / delete like N10's routes.
class _UploadServer {
  final Map<String, List<int>> uploads = {};
  final Map<String, int> sizes = {};
  final List<String> deleted = [];
  final List<Map<String, Object?>> completes = [];

  /// Called before each PUT is applied; may throw.
  void Function(int putIndex, _Call call)? beforePut;
  int puts = 0;

  /// N11: complete answers the hash of what arrived (like a verifying
  /// server); [mismatches] completes answer 409 `verification_failed`.
  bool verify = false;
  int mismatches = 0;

  /// Q8: the next completes fail like a dropped link (after publishing:
  /// the answer is lost, a repeat gets the same file).
  int lostCompleteAnswers = 0;
  final Set<String> published = {};

  Map<String, Object?> handle(_Call c) {
    final parts = c.path.split('/');
    if (c.method == 'GET' && c.path == ApiRoutes.session) return const {};
    if (c.method == 'GET' && c.path.endsWith('/sha256')) return const {};
    if (c.method == 'POST' && c.path == ApiRoutes.uploads) {
      final body = c.body! as Map<String, Object?>;
      final id = body['uploadId']! as String;
      uploads.putIfAbsent(id, () => []);
      sizes[id] = body['size']! as int;
      return {'received': uploads[id]!.length, 'size': sizes[id]};
    }
    final id = parts.length > 3 ? parts[3] : '';
    if (!uploads.containsKey(id)) {
      throw RemoteApiException(
        404,
        ApiErrorDto(ApiErrorCode.notFound.wire, ''),
      );
    }
    if (c.method == 'GET') {
      return {'received': uploads[id]!.length, 'size': sizes[id]};
    }
    if (c.method == 'DELETE') {
      uploads.remove(id);
      deleted.add(id);
      return const {};
    }
    if (c.method == 'PUT') {
      beforePut?.call(puts++, c);
      final offset = int.parse(c.query['offset']!);
      if (offset != uploads[id]!.length) {
        throw RemoteApiException(
          409,
          ApiErrorDto(ApiErrorCode.conflict.wire, ''),
        );
      }
      uploads[id]!.addAll(c.body! as List<int>);
      return {'received': uploads[id]!.length};
    }
    if (c.method == 'POST' && c.path.endsWith('/complete')) {
      completes.add(c.body! as Map<String, Object?>);
      published.add(id);
      if (lostCompleteAnswers > 0) {
        lostCompleteAnswers--;
        throw const RemoteUnavailableException(RemoteUnavailableReason.network);
      }
      if (mismatches > 0) {
        mismatches--;
        uploads.remove(id);
        throw RemoteApiException(
          409,
          ApiErrorDto(ApiErrorCode.verificationFailed.wire, ''),
        );
      }
      return {
        'finalId': 'ms:$id',
        if (verify) 'sha256': sha256.convert(uploads[id]!).toString(),
      };
    }
    return const {};
  }
}

FileRef _remote(String serverId, {int size = 3, String? name}) => FileRef(
  id: remoteFileId(_fp, serverId),
  uri: 'remote://x',
  name: name ?? '${serverId.replaceAll(':', '')}.jpg',
  kind: FileKind.image,
  sizeBytes: size,
  modifiedAt: DateTime.utc(2026),
  folderPath: 'cam',
  origin: FileOrigin.remote,
);

void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late TransfersRepository repo;
  late KnownDevicesRepository devices;
  late FakeFileSource local;
  late _Http http;
  late Directory staging;
  late TransferEngine engine;
  late List<List<FileRef>> indexed;
  RemoteHttp? connected;
  var probeOk = true;
  late List<String> reconnects;
  Future<void> Function(String fp)? onReconnect;

  TransferEngine newEngine({
    TransferPreprocessor preprocessor = const IdentityPreprocessor(),
    int chunkBytes = 4,
    VerifiedMove? verifiedMove,
    Future<String> Function(PreparedSource p) hash = hashPrepared,
  }) => TransferEngine(
    repo: repo,
    devices: devices,
    local: local,
    http: (fp) => fp == _fp ? connected : null,
    staging: () async => staging,
    preprocessor: preprocessor,
    addToIndex: (f) async => indexed.add(f),
    reconnect: (fp) async {
      reconnects.add(fp);
      await onReconnect?.call(fp);
    },
    probe: (_) async => probeOk,
    verifiedMove:
        verifiedMove ??
        LocalVerifiedMove(
          source: local,
          lock: SerialLock(),
          removeFromIndex: (ids) async {},
        ),
    chunkBytes: chunkBytes,
    hash: hash,
    liveInterval: const Duration(milliseconds: 20),
    persistInterval: Duration.zero,
    retryBase: const Duration(milliseconds: 2),
    retryCap: const Duration(milliseconds: 8),
    reconnectBase: const Duration(milliseconds: 10),
    reconnectCap: const Duration(milliseconds: 40),
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    repo = TransfersRepository(TransfersDao(db), queue);
    devices = KnownDevicesRepository(KnownDevicesDao(db), queue);
    local = FakeFileSource()..addFolder(_dl);
    http = _Http();
    connected = http;
    probeOk = true;
    reconnects = [];
    onReconnect = null;
    indexed = [];
    staging = await Directory.systemTemp.createTemp('kfm_engine');
    engine = newEngine();
    await engine.start();
    engine.onConnection(_fp);
  });

  tearDown(() async {
    await engine.dispose();
    await queue.close();
    await db.close();
    await local.dispose();
    if (await staging.exists()) await staging.delete(recursive: true);
  });

  Future<TransferJob> until(
    String id,
    bool Function(TransferJob j) test, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final end = DateTime.now().add(timeout);
    while (true) {
      await queue.flush();
      final job = await repo.dao.job(id);
      if (job != null && test(job)) return job;
      if (DateTime.now().isAfter(end)) {
        fail(
          'timed out: ${job?.status} ${job?.pauseReason} '
          '${job?.files.map((f) => '${f.status.name}:${f.error}')}',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  List<String> parts() => [
    for (final e in staging.listSync()) e.uri.pathSegments.last,
  ];

  Iterable<_Call> contentCalls() =>
      http.calls.where((c) => c.path.endsWith('/content'));

  Future<String> rememberDevice() async => (await devices.saveAfterPairing(
    PairedPeer(
      fingerprint: _fp,
      peerDeviceId: 'p',
      name: 'Phone',
      platform: 'android',
    ),
    temporary: false,
  )).id;

  group('downloads', () {
    test('N12b: a download of an offer reports which files arrived', () async {
      http.contents['ms:0'] = [1, 2, 3];
      final offerId = 'c' * 32;
      final id = await engine.enqueueDownload(
        [_remote('ms:0'), _remote('ms:gone')],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
        inboxOfferId: offerId,
      );
      http.failContent['ms:gone'] = ApiErrorCode.notFound;
      final job = await until(id, (j) => j.isFinished);
      expect(job.inboxOfferId, offerId);
      for (var i = 0; i < 100; i++) {
        if (http.calls.any((c) => c.path.endsWith('/finished'))) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      final report = http.calls.singleWhere(
        (c) => c.path == ApiRoutes.inboxFinished(offerId),
      );
      expect(report.body, {
        'done': [0],
        'failed': [1],
      });
    });

    test('2 at a time, seq order; all land in the folder; no partials '
        'left', () async {
      for (var i = 0; i < 4; i++) {
        http.contents['ms:$i'] = [i, i, i];
      }
      final id = await engine.enqueueDownload(
        [for (var i = 0; i < 4; i++) _remote('ms:$i')],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      final job = await until(id, (j) => j.status == TransferStatus.done);
      expect(http.maxRunning, 2);
      final order = [
        for (final c in contentCalls())
          Uri.decodeComponent(c.path.split('/')[3]),
      ];
      expect(order, ['ms:0', 'ms:1', 'ms:2', 'ms:3']);
      for (var i = 0; i < 4; i++) {
        expect((await local.stat('path:$_dl/ms$i.jpg'))?.sizeBytes, 3);
      }
      expect(job.files.map((f) => f.targetFileId), everyElement(isNotNull));
      expect(parts(), isEmpty);
      expect(indexed, hasLength(4));
      // Not remembered before: a temporary row now exists for the job.
      final row = await devices.byFingerprint(_fp);
      expect(row?.isTemporary, isTrue);
    });

    test('cancel: running and queued files end, finished stay, no '
        'partials', () async {
      http
        ..contents['ms:0'] = [1, 2, 3]
        ..held['ms:1'] = _Held(10)
        ..held['ms:2'] = _Held(10);
      final id = await engine.enqueueDownload(
        [
          _remote('ms:0'),
          _remote('ms:1', size: 10),
          _remote('ms:2', size: 10),
          _remote('ms:3'),
        ],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      await until(id, (j) => j.files[0].status == TransferFileStatus.done);
      final h1 = http.held['ms:1']!..c.add([1, 2, 3, 4]);
      await until(
        id,
        (j) =>
            j.files[1].status == TransferFileStatus.running &&
            j.files[2].status == TransferFileStatus.running,
      );
      expect(parts(), isNotEmpty);
      await engine.cancelJob(id);
      final job = await until(id, (j) => j.status == TransferStatus.cancelled);
      expect(job.files.map((f) => f.status), [
        TransferFileStatus.done,
        TransferFileStatus.cancelled,
        TransferFileStatus.cancelled,
        TransferFileStatus.cancelled,
      ]);
      expect(h1.cancelled, isTrue);
      expect(await local.stat('path:$_dl/ms0.jpg'), isNotNull);
      expect(await local.stat('path:$_dl/ms1.jpg'), isNull);
      // Let the cancelled runs clean up.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(parts(), isEmpty);
    });

    test('a permanent failure keeps going; Retry starts it again', () async {
      http
        ..failContent['ms:0'] = ApiErrorCode.notFound
        ..contents['ms:0'] = [9, 9]
        ..contents['ms:1'] = [1];
      final id = await engine.enqueueDownload(
        [_remote('ms:0', size: 2), _remote('ms:1', size: 1)],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      var job = await until(id, (j) => j.isFinished);
      expect(job.status, TransferStatus.failed);
      expect(job.files[0].error, 'not_found');
      expect(job.files[1].status, TransferFileStatus.done);
      http.failContent.clear();
      await engine.retry(id);
      job = await until(id, (j) => j.status == TransferStatus.done);
      expect(job.files[0].attempts, 0);
      expect((await local.stat('path:$_dl/ms0.jpg'))?.sizeBytes, 2);
    });

    test('a peer file name that escapes the folder fails invalid_name; '
        'nothing is written', () async {
      http.contents['ms:0'] = [1];
      final id = await engine.enqueueDownload(
        [_remote('ms:0', name: 'a/b.jpg'), _remote('ms:1', name: '..')],
        peerFingerprint: _fp,
        peerName: '../evil',
        localFolder: defaultDownloadFolder(
          '/storage/emulated/0/Download',
          '../evil',
        ),
      );
      final job = await until(id, (j) => j.isFinished);
      expect(job.files.map((f) => f.error), ['invalid_name', 'invalid_name']);
      expect(job.targetPath, '/storage/emulated/0/Download/_evil');
      expect(local.calls.where((c) => c.startsWith('importFile')), isEmpty);
      expect(parts(), isEmpty);
    });

    test('not enough space here: paused (noSpace) before anything is '
        'fetched; Resume checks again', () async {
      local.freeBytesValue = 1000;
      http.contents['ms:0'] = [1, 2, 3];
      final id = await engine.enqueueDownload(
        [_remote('ms:0')],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      var job = await until(id, (j) => j.status == TransferStatus.paused);
      expect(job.pauseReason, TransferPauseReason.noSpace);
      expect(job.files.single.error, TransferErrors.noSpaceHere);
      expect(contentCalls(), isEmpty);
      // A reconnect doesn't resume it.
      engine.onConnection(_fp);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect((await repo.dao.job(id))!.status, TransferStatus.paused);
      local.freeBytesValue = null;
      await engine.resumeJob(id);
      job = await until(id, (j) => j.status == TransferStatus.done);
      expect(job.pauseReason, isNull);
    });

    test('queued while not connected; starts on the next connection', () async {
      connected = null;
      engine.onConnection(null);
      http.contents['ms:0'] = [1];
      final id = await engine.enqueueDownload(
        [_remote('ms:0', size: 1)],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect((await repo.dao.job(id))!.status, TransferStatus.queued);
      connected = http;
      engine.onConnection(_fp);
      await until(id, (j) => j.status == TransferStatus.done);
    });
  });

  group('N10 pause and resume', () {
    test('Pause stops the download at once and keeps the part; Resume asks '
        'for the rest with Range + If-Range and appends it', () async {
      final bytes = List<int>.generate(10, (i) => i + 1);
      http
        ..contents['ms:0'] = bytes
        ..held['ms:0'] = _Held(10, headers: {'etag': _etagOf('ms:0')});
      final id = await engine.enqueueDownload(
        [_remote('ms:0', size: 10)],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      await until(id, (j) => j.status == TransferStatus.running);
      final h = http.held['ms:0']!;
      h.c.add(bytes.sublist(0, 4));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await engine.pauseJob(id);
      var job = await until(
        id,
        (j) =>
            j.status == TransferStatus.paused &&
            j.files.single.status == TransferFileStatus.queued,
      );
      expect(h.cancelled, isTrue);
      expect(job.pauseReason, TransferPauseReason.user);
      expect(job.files.single.bytesDone, 4);
      expect(job.files.single.etag, _etagOf('ms:0'));
      final part = File('${staging.path}/dl-${job.files.single.id}.part');
      expect(await part.readAsBytes(), bytes.sublist(0, 4));

      await engine.resumeJob(id);
      job = await until(id, (j) => j.status == TransferStatus.done);
      expect(http.contentHeaders.last, {
        HttpHeaders.rangeHeader: 'bytes=4-',
        HttpHeaders.ifRangeHeader: _etagOf('ms:0'),
      });
      expect(
        local.bytesOf('path:$_dl/ms0.jpg'),
        bytes,
        reason: 'the resumed part is stitched in order',
      );
      expect(parts(), isEmpty);
    });

    test('a changed file (another ETag) starts over from 0', () async {
      final bytes = List<int>.generate(6, (i) => i + 1);
      http
        ..contents['ms:0'] = bytes
        ..held['ms:0'] = _Held(6, headers: {'etag': '"old"'});
      final id = await engine.enqueueDownload(
        [_remote('ms:0', size: 6)],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      await until(id, (j) => j.status == TransferStatus.running);
      final h = http.held['ms:0']!;
      h.c.add([9, 9, 9]);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await engine.pauseJob(id);
      await until(id, (j) => j.status == TransferStatus.paused);
      await engine.resumeJob(id);
      await until(id, (j) => j.status == TransferStatus.done);
      // If-Range "old" doesn't match: the server sent everything (200).
      expect(local.bytesOf('path:$_dl/ms0.jpg'), bytes);
    });

    test('the device leaves mid-file: the job waits for it (no attempt); '
        'reconnecting resumes from the part', () async {
      final bytes = List<int>.generate(8, (i) => i + 1);
      http
        ..contents['ms:0'] = bytes
        ..held['ms:0'] = _Held(8, headers: {'etag': _etagOf('ms:0')});
      final id = await engine.enqueueDownload(
        [_remote('ms:0', size: 8)],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      await until(id, (j) => j.status == TransferStatus.running);
      final h = http.held['ms:0']!;
      h.c.add(bytes.sublist(0, 3));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      connected = null;
      engine.onConnection(null);
      var job = await until(
        id,
        (j) =>
            j.status == TransferStatus.paused &&
            j.files.single.status == TransferFileStatus.queued,
      );
      expect(job.pauseReason, TransferPauseReason.waitingForDevice);
      expect(job.files.single.attempts, 0);
      expect(job.files.single.bytesDone, 3);
      expect(parts(), isNotEmpty);
      connected = http;
      engine.onConnection(_fp);
      job = await until(id, (j) => j.status == TransferStatus.done);
      expect(local.bytesOf('path:$_dl/ms0.jpg'), bytes);
    });

    test('a network error while the probe fails waits for the device; the '
        'same error with a healthy link backs off', () async {
      http.held['ms:0'] = _Held(5);
      final id = await engine.enqueueDownload(
        [_remote('ms:0', size: 5)],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      await until(id, (j) => j.status == TransferStatus.running);
      probeOk = false;
      (http.held['ms:0']!).c.addError(
        const RemoteUnavailableException(RemoteUnavailableReason.network),
      );
      final job = await until(id, (j) => j.status == TransferStatus.paused);
      expect(job.pauseReason, TransferPauseReason.waitingForDevice);
      expect(job.files.single.attempts, 0);
      // The link comes back while still connected: the recovery probe
      // resumes it.
      http.contents['ms:0'] = [1, 2, 3, 4, 5];
      probeOk = true;
      await until(id, (j) => j.status == TransferStatus.done);
    });

    test('a paused-by-user job stays paused after a reconnect; a '
        'paused-by-network job resumes', () async {
      http
        ..held['ms:0'] = _Held(4)
        ..contents['ms:0'] = [1, 2, 3, 4]
        ..contents['ms:1'] = [5, 6];
      final mine = await engine.enqueueDownload(
        [_remote('ms:0', size: 4)],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      await until(mine, (j) => j.status == TransferStatus.running);
      await engine.pauseJob(mine);
      await until(mine, (j) => j.status == TransferStatus.paused);
      connected = null;
      engine.onConnection(null);
      final other = await engine.enqueueDownload(
        [_remote('ms:1', size: 2)],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      await repo.pauseJob(other, TransferPauseReason.waitingForDevice);
      connected = http;
      engine.onConnection(_fp);
      await until(other, (j) => j.status == TransferStatus.done);
      final still = (await repo.dao.job(mine))!;
      expect(still.status, TransferStatus.paused);
      expect(still.pauseReason, TransferPauseReason.user);
    });

    test('500 again and again: 10 attempts with backoff, then failed with '
        'Retry; nothing loops forever', () async {
      http.failContent['ms:0'] = ApiErrorCode.internal;
      final id = await engine.enqueueDownload(
        [_remote('ms:0')],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      final job = await until(id, (j) => j.isFinished);
      expect(job.status, TransferStatus.failed);
      expect(job.files.single.error, 'internal');
      expect(job.files.single.attempts, 10);
      expect(contentCalls(), hasLength(10));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(contentCalls(), hasLength(10));
    });

    test('restart: running files are queued again and wait for the device; '
        'stale client parts go, live ones stay', () async {
      connected = null;
      engine.onConnection(null);
      final d = await engine.deviceIdFor(_fp, 'Phone');
      final id = await repo.createJob(
        deviceId: d,
        direction: TransferDirection.download,
        targetPath: _dl,
        files: [
          (sourceFileId: 'x', name: 'x', sizeBytes: 9, sourceModifiedAtMs: 0),
        ],
      );
      final fileId = (await repo.dao.job(id))!.files.single.id;
      await repo.setFile(
        fileId,
        id,
        const TransferFilesCompanion(
          status: Value(TransferFileStatus.running),
          bytesDone: Value(4),
        ),
      );
      File('${staging.path}/dl-$fileId.part').writeAsBytesSync([1, 2, 3, 4]);
      File('${staging.path}/dl-999.part').writeAsBytesSync([1]);
      await engine.dispose();
      engine = newEngine();
      await engine.start();
      final after = (await repo.dao.job(id))!;
      expect(after.status, TransferStatus.paused);
      expect(after.pauseReason, TransferPauseReason.waitingForDevice);
      expect(after.files.single.status, TransferFileStatus.queued);
      expect(after.files.single.bytesDone, 4);
      expect(parts(), ['dl-$fileId.part']);
    });

    test('a remembered device is reconnected by itself after a lost link; '
        'never after Disconnect', () async {
      await rememberDevice();
      connected = null;
      engine.onConnection(null);
      http.contents['ms:0'] = [1, 2];
      final id = await engine.enqueueDownload(
        [_remote('ms:0', size: 2)],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      await repo.pauseJob(id, TransferPauseReason.waitingForDevice);
      // The user's Disconnect: no automatic reconnect.
      engine.onConnection(null);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(reconnects, isEmpty);
      onReconnect = (fp) async {
        connected = http;
        engine.onConnection(fp);
      };
      engine.onConnection(null, autoReconnect: true);
      await until(id, (j) => j.status == TransferStatus.done);
      expect(reconnects, [_fp]);
    });

    test('a declined automatic reconnect stops the automatic tries', () async {
      await rememberDevice();
      connected = null;
      final id = await engine.enqueueDownload(
        [_remote('ms:0')],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      await repo.pauseJob(id, TransferPauseReason.waitingForDevice);
      onReconnect = (_) async =>
          throw const PairingException(PairingFailure.declined);
      engine.onConnection(null, autoReconnect: true);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(reconnects, [_fp]);
    });
  });

  test('Q8: the complete timeout grows with the file (the other device '
      'hashes it twice and may copy it)', () {
    expect(completeTimeoutFor(0), const Duration(minutes: 5));
    expect(completeTimeoutFor(1000000000), const Duration(minutes: 5));
    // 4.5 GB took ~4.8 min on the phone: well above that.
    expect(
      completeTimeoutFor(4500000000),
      greaterThan(const Duration(minutes: 7)),
    );
  });

  test('Q8: IdentityPreprocessor reads the real length and hashes from disk '
      'for absolute Windows paths too', () async {
    final dir = await Directory.systemTemp.createTemp('kfm_prep');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}${Platform.pathSeparator}a.bin')
      ..writeAsBytesSync([1, 2, 3, 4]);
    final path = file.absolute.path.replaceAll(r'\', '/');
    final ref = FileRef(
      id: 'path:$path',
      uri: Uri.file(file.path).toString(),
      name: 'a.bin',
      kind: FileKind.other,
      sizeBytes: 99, // stale: the length on disk wins
      modifiedAt: DateTime.utc(2026),
      folderPath: path.substring(0, path.lastIndexOf('/')),
      origin: FileOrigin.local,
    );
    final p = await const IdentityPreprocessor().prepare(ref, local);
    expect(p.sizeBytes, 4);
    expect(p.path, path);
  });

  group('uploads', () {
    late _UploadServer server;

    setUp(() {
      server = _UploadServer();
      http.json = server.handle;
    });

    List<_Call> puts() => [
      for (final c in http.calls)
        if (c.method == 'PUT') c,
    ];

    test('create → chunks → complete; the final id and the sender hash are '
        'stored', () async {
      final bytes = [1, 2, 3, 4, 5, 6];
      final f = local.addFile('/storage/emulated/0/DCIM/a.jpg', bytes: bytes);
      final id = await engine.enqueueUpload(
        [f],
        peerFingerprint: _fp,
        peerName: 'PC',
        rootId: 'cam',
        path: 'sub',
      );
      final job = await until(id, (j) => j.status == TransferStatus.done);
      final file = job.files.single;
      expect(file.targetFileId, 'ms:${file.uploadId}');
      final create = http.calls.firstWhere((c) => c.path == ApiRoutes.uploads);
      expect(create.body, containsPair('rootId', 'cam'));
      expect(create.body, containsPair('path', 'sub'));
      expect(create.body, containsPair('name', 'a.jpg'));
      expect(create.body, containsPair('size', 6));
      expect(puts().map((c) => c.query['offset']), ['0', '4']);
      expect(server.uploads[file.uploadId], bytes);
      final sha = sha256.convert(bytes).toString();
      expect(file.senderSha256, sha);
      expect(server.completes.single, {'sha256': sha});
      expect(http.calls.where((c) => c.method == 'DELETE'), isEmpty);
    });

    test('the link drops mid-upload: the job waits; after the reconnect it '
        "continues from the server's received and the bytes match", () async {
      final bytes = List<int>.generate(10, (i) => 10 + i);
      final f = local.addFile('/storage/emulated/0/DCIM/a.jpg', bytes: bytes);
      server.beforePut = (i, _) {
        if (i == 1) {
          connected = null;
          engine.onConnection(null);
          throw const RemoteUnavailableException(
            RemoteUnavailableReason.network,
          );
        }
      };
      final id = await engine.enqueueUpload(
        [f],
        peerFingerprint: _fp,
        peerName: 'PC',
        rootId: 'cam',
        path: '',
      );
      var job = await until(
        id,
        (j) =>
            j.status == TransferStatus.paused &&
            j.files.single.status == TransferFileStatus.queued,
      );
      expect(job.pauseReason, TransferPauseReason.waitingForDevice);
      expect(job.files.single.bytesDone, 4);
      final uploadId = job.files.single.uploadId;
      expect(uploadId, isNotNull);
      connected = http;
      engine.onConnection(_fp);
      job = await until(id, (j) => j.status == TransferStatus.done);
      expect(
        http.calls.where(
          (c) => c.method == 'GET' && c.path == ApiRoutes.upload(uploadId!),
        ),
        isNotEmpty,
      );
      expect(puts().map((c) => c.query['offset']), ['0', '4', '4', '8']);
      expect(server.uploads[uploadId], bytes);
      expect(server.uploads, hasLength(1), reason: 'one upload, resumed');
    });

    test('Q8: a lost complete answer: the retry asks for the status, keeps '
        'the sender hash and completes again; no byte is sent twice', () async {
      var hashes = 0;
      await engine.dispose();
      engine = newEngine(
        hash: (p) {
          hashes++;
          return hashPrepared(p);
        },
      );
      await engine.start();
      engine.onConnection(_fp);
      server.lostCompleteAnswers = 1;
      final bytes = [1, 2, 3, 4, 5, 6];
      final f = local.addFile('/storage/emulated/0/DCIM/a.jpg', bytes: bytes);
      final id = await engine.enqueueUpload(
        [f],
        peerFingerprint: _fp,
        peerName: 'PC',
        rootId: 'cam',
        path: '',
      );
      final job = await until(id, (j) => j.status == TransferStatus.done);
      final file = job.files.single;
      expect(file.status, TransferFileStatus.done);
      expect(puts().map((c) => c.query['offset']), ['0', '4']);
      expect(server.completes, hasLength(2));
      expect(server.uploads, hasLength(1), reason: 'never re-uploaded');
      // E1: hashed while sending, never read again; the retry reuses the
      // stored hash.
      expect(hashes, 0, reason: 'the stored sender hash is reused');
      final uploadId = file.uploadId!;
      expect(
        http.calls
            .where(
              (c) => c.method == 'GET' && c.path == ApiRoutes.upload(uploadId),
            )
            .length,
        1,
      );
      expect(
        http.postTimeouts[ApiRoutes.uploadComplete(uploadId)],
        const Duration(minutes: 5),
      );
    });

    test(
      'Q8: a copy shows "verifying" while the other device checks it',
      () async {
        final hold = Completer<void>();
        http.json = (c) async {
          if (c.path.endsWith('/complete')) await hold.future;
          return server.handle(c);
        };
        final f = local.addFile(
          '/storage/emulated/0/DCIM/a.jpg',
          bytes: [1, 2, 3],
        );
        final id = await engine.enqueueUpload(
          [f],
          peerFingerprint: _fp,
          peerName: 'PC',
          rootId: 'cam',
          path: '',
        );
        final job = await until(
          id,
          (j) => j.files.single.status == TransferFileStatus.verifying,
        );
        expect(job.mode, TransferMode.copy);
        hold.complete();
        await until(id, (j) => j.status == TransferStatus.done);
      },
    );

    test('409: the client re-syncs to the server offset; no corrupted '
        'output', () async {
      final bytes = [1, 2, 3, 4, 5, 6];
      final f = local.addFile('/storage/emulated/0/DCIM/a.jpg', bytes: bytes);
      server.beforePut = (i, c) {
        // The first chunk arrived but its answer was lost: the server is
        // already at 4 when the client sends offset 0 again.
        if (i == 0) {
          final id = c.path.split('/')[3];
          server.uploads[id]!.addAll(bytes.sublist(0, 4));
        }
      };
      final id = await engine.enqueueUpload(
        [f],
        peerFingerprint: _fp,
        peerName: 'PC',
        rootId: 'cam',
        path: '',
      );
      final job = await until(id, (j) => j.status == TransferStatus.done);
      expect(server.uploads[job.files.single.uploadId], bytes);
      expect(puts().map((c) => c.query['offset']), ['0', '4']);
    });

    test('507 pauses the job (noSpace); Resume continues', () async {
      final f = local.addFile('/storage/emulated/0/DCIM/a.jpg');
      var full = true;
      server.beforePut = (_, _) {
        if (full) {
          throw RemoteApiException(
            507,
            ApiErrorDto(ApiErrorCode.insufficientStorage.wire, ''),
          );
        }
      };
      final id = await engine.enqueueUpload(
        [f],
        peerFingerprint: _fp,
        peerName: 'PC',
        rootId: 'cam',
        path: '',
      );
      final job = await until(id, (j) => j.status == TransferStatus.paused);
      expect(job.pauseReason, TransferPauseReason.noSpace);
      expect(job.files.single.error, 'insufficient_storage');
      full = false;
      await engine.resumeJob(id);
      await until(id, (j) => j.status == TransferStatus.done);
    });

    test('a source edited mid-upload starts over from 0; nothing is '
        'stitched', () async {
      final f = local.addFile(
        '/storage/emulated/0/DCIM/a.jpg',
        bytes: [1, 2, 3, 4, 5, 6],
        modifiedAt: DateTime.utc(2026),
      );
      final edited = [7, 7, 7, 7, 7, 7, 7];
      server.beforePut = (i, _) {
        if (i == 1) {
          local.addFile(
            '/storage/emulated/0/DCIM/a.jpg',
            bytes: edited,
            modifiedAt: DateTime.utc(2026, 2),
          );
        }
      };
      final id = await engine.enqueueUpload(
        [f],
        peerFingerprint: _fp,
        peerName: 'PC',
        rootId: 'cam',
        path: '',
      );
      final job = await until(id, (j) => j.status == TransferStatus.done);
      final file = job.files.single;
      expect(server.deleted, hasLength(1), reason: 'the old upload went');
      expect(server.uploads[file.uploadId], edited);
      expect(file.sizeBytes, 7);
      expect(file.senderSha256, sha256.convert(edited).toString());
    });

    test('a refused upload (403) fails "forbidden_path" and the partial '
        'is deleted on the other device', () async {
      final f = local.addFile('/storage/emulated/0/DCIM/a.jpg');
      server.beforePut = (_, _) => throw RemoteApiException(
        403,
        ApiErrorDto(ApiErrorCode.forbiddenPath.wire, ''),
      );
      final id = await engine.enqueueUpload(
        [f],
        peerFingerprint: _fp,
        peerName: 'PC',
        rootId: 'cam',
        path: '',
      );
      final job = await until(id, (j) => j.isFinished);
      expect(job.files.single.error, 'forbidden_path');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        http.calls.where((c) => c.method == 'DELETE').single.path,
        startsWith('/v1/uploads/'),
      );
    });

    test(
      'the preprocessor decides what is sent; its temp file is cleaned',
      () async {
        final f = local.addFile('/storage/emulated/0/DCIM/a.jpg');
        var cleaned = false;
        await engine.dispose();
        engine = newEngine(preprocessor: _Stripper(() => cleaned = true));
        await engine.start();
        engine.onConnection(_fp);
        final id = await engine.enqueueUpload(
          [f],
          peerFingerprint: _fp,
          peerName: 'PC',
          rootId: 'cam',
          path: '',
        );
        await until(id, (j) => j.status == TransferStatus.done);
        final create = http.calls.firstWhere(
          (c) => c.path == ApiRoutes.uploads,
        );
        expect(create.body, containsPair('size', 2));
        expect(puts().single.body, [7, 7]);
        expect(cleaned, isTrue);
      },
    );
  });

  group('jobs and devices', () {
    test('clear finished removes the job and its temporary device', () async {
      http.contents['ms:0'] = [1];
      final id = await engine.enqueueDownload(
        [_remote('ms:0', size: 1)],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      await until(id, (j) => j.status == TransferStatus.done);
      expect(await engine.clearFinished(), 1);
      expect(await repo.dao.jobs(), isEmpty);
      expect(await devices.byFingerprint(_fp), isNull);
    });

    test('a remembered device stays; removing it removes its jobs', () async {
      final d = await rememberDevice();
      connected = null;
      engine.onConnection(null);
      await engine.enqueueDownload(
        [_remote('ms:0')],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      expect(await repo.dao.countForDevice(d), 1);
      await devices.remove(d);
      expect(await repo.dao.jobs(), isEmpty);
      expect(await db.select(db.transferFiles).get(), isEmpty);
    });
  });

  group('swipe sends (sendToDevice)', () {
    late String deviceId;
    late Session session;

    setUp(() async {
      deviceId = (await devices.saveAfterPairing(
        PairedPeer(
          fingerprint: _fp,
          peerDeviceId: 'p',
          name: 'PC',
          platform: 'windows',
        ),
        temporary: false,
      )).id;
      connected = null;
      engine.onConnection(null);
      final now = DateTime.utc(2026);
      final sid = await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              layout: '{}',
              startedAt: now,
              updatedAt: now,
              isActive: true,
            ),
          );
      session = Session(
        id: sid,
        layout: SwipeLayout.basic,
        deleteMode: DeleteMode.trash,
        cursor: 0,
        startedAt: now,
        updatedAt: now,
      );
    });

    Future<int> send(Session s, FileRef f, SwipeAction a) => db.transaction(
      () => swipeSendQueue(
        repo.dao,
        downloadsRoot: '/storage/emulated/0/Download',
      )(s, f, a),
    );

    test('a local session collects uploads in one job; undo removes a '
        'queued file', () async {
      final action = SwipeAction(
        SwipeActionType.sendToDevice,
        deviceId: deviceId,
        targetFolder: 'cam/Phone',
      );
      final a = local.addFile('/storage/emulated/0/DCIM/a.jpg');
      final b = local.addFile('/storage/emulated/0/DCIM/b.jpg');
      final first = await send(session, a, action);
      final second = await send(session, b, action);
      final jobs = await repo.dao.jobs();
      expect(jobs, hasLength(1));
      final job = jobs.single;
      expect(job.direction, TransferDirection.upload);
      expect(job.targetRootId, 'cam');
      expect(job.targetPath, 'Phone');
      expect(job.swipeSessionId, session.id);
      expect(job.files.map((f) => f.seq), [0, 1]);
      expect(await repo.deleteQueuedFile(second), isTrue);
      expect((await repo.dao.job(job.id))!.files, hasLength(1));
      expect(await repo.deleteQueuedFile(first), isTrue);
      expect(await repo.dao.jobs(), isEmpty);
    });

    test('a started file is not removed ("Already sent")', () async {
      final f = local.addFile('/storage/emulated/0/DCIM/a.jpg');
      final id = await send(
        session,
        f,
        SwipeAction(
          SwipeActionType.sendToDevice,
          deviceId: deviceId,
          targetFolder: 'cam',
        ),
      );
      final job = (await repo.dao.jobs()).single;
      await repo.setFile(
        id,
        job.id,
        const TransferFilesCompanion(status: Value(TransferFileStatus.running)),
      );
      expect(await repo.deleteQueuedFile(id), isFalse);
    });

    test(
      "that device's own session downloads into Download/<device>",
      () async {
        final remoteSession = Session(
          id: session.id,
          layout: SwipeLayout.basic,
          deleteMode: DeleteMode.trash,
          cursor: 0,
          startedAt: session.startedAt,
          updatedAt: session.updatedAt,
          sourceId: remoteSourceId(_fp),
        );
        await send(
          remoteSession,
          _remote('ms:5'),
          SwipeAction(SwipeActionType.sendToDevice, deviceId: deviceId),
        );
        final job = (await repo.dao.jobs()).single;
        expect(job.direction, TransferDirection.download);
        expect(job.targetPath, '/storage/emulated/0/Download/PC');
        expect(job.files.single.sourceFileId, remoteFileId(_fp, 'ms:5'));
      },
    );
  });

  group('N11 safe move', () {
    String shaOf(List<int> b) => sha256.convert(b).toString();

    Iterable<_Call> trashCalls() =>
        http.calls.where((c) => c.path == ApiRoutes.filesTrash);

    /// The other device: sender hashes of its contents; trash answers
    /// [trash] (default: everything trashed).
    void serveMoves({
      FutureOr<Map<String, Object?>> Function(TrashRequestDto body)? trash,
    }) {
      http.json = (c) {
        if (c.path.endsWith('/sha256')) {
          final serverId = Uri.decodeComponent(c.path.split('/')[3]);
          return {'sha256': shaOf(http.contents[serverId]!)};
        }
        if (c.path == ApiRoutes.filesTrash) {
          final body = TrashRequestDto.fromJson(
            c.body! as Map<String, Object?>,
          );
          return trash?.call(body) ??
              {
                'trashed': [
                  for (final id in body.ids)
                    {
                      'id': id,
                      'trashId': 't-$id',
                      'location': 'systemTrash',
                      'trashedAtMs': 1,
                    },
                ],
              };
        }
        return const {};
      };
    }

    bool settled(TransferJob j) =>
        j.allFilesEnded &&
        j.files.every(
          (f) => f.status != TransferFileStatus.done || f.sourceOutcome != null,
        );

    test('download-move: verified copies land; one verifiedMove trash with '
        'hashes and received sizes; originals trashed there', () async {
      http
        ..contents['ms:0'] = [1, 2, 3]
        ..contents['ms:1'] = [4, 5, 6, 7];
      serveMoves();
      final id = await engine.enqueueDownload(
        [_remote('ms:0'), _remote('ms:1', size: 4)],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
        mode: TransferMode.move,
      );
      final job = await until(id, settled);
      expect(job.mode, TransferMode.move);
      expect(job.deleteMode, isNull);
      expect(local.bytesOf('path:$_dl/ms0.jpg'), [1, 2, 3]);
      expect(local.bytesOf('path:$_dl/ms1.jpg'), [4, 5, 6, 7]);
      expect(trashCalls(), hasLength(1));
      final body = TrashRequestDto.fromJson(
        trashCalls().single.body! as Map<String, Object?>,
      );
      expect(body.reason, TrashReason.verifiedMove);
      expect(body.ids, ['ms:0', 'ms:1']);
      expect(body.sizeById, {'ms:0': 3, 'ms:1': 4});
      expect(body.sha256ById['ms:1'], shaOf([4, 5, 6, 7]));
      for (final f in job.files) {
        expect(f.sourceOutcome, SourceOutcome.trashed);
        expect(f.receiverSha256, f.senderSha256);
      }
      expect(parts(), isEmpty);
    });

    test('a copy never asks to trash anything', () async {
      http.contents['ms:0'] = [1, 2, 3];
      serveMoves();
      final id = await engine.enqueueDownload(
        [_remote('ms:0')],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      final job = await until(id, (j) => j.status == TransferStatus.done);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(trashCalls(), isEmpty);
      expect(job.files.single.receiverSha256, isNull);
    });

    test('corruption: retried once from 0, then "verification failed"; '
        'nothing is trashed, no copy or part is left', () async {
      addTearDown(() => ResumableDownloader.corruptBeforeVerify = null);
      ResumableDownloader.corruptBeforeVerify = (path) async =>
          File(path).writeAsBytesSync(const [9, 9, 9]);
      http.contents['ms:0'] = [1, 2, 3];
      serveMoves();
      final id = await engine.enqueueDownload(
        [_remote('ms:0')],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
        mode: TransferMode.move,
      );
      final job = await until(id, (j) => j.status == TransferStatus.failed);
      expect(job.files.single.error, TransferErrors.verificationFailed);
      expect(contentCalls(), hasLength(2));
      expect(trashCalls(), isEmpty);
      expect(await local.statPath('$_dl/ms0.jpg'), isNull);
      expect(parts(), isEmpty);
    });

    test('one corrupted try: the retry verifies and the original is '
        'trashed', () async {
      var corruptions = 1;
      addTearDown(() => ResumableDownloader.corruptBeforeVerify = null);
      ResumableDownloader.corruptBeforeVerify = (path) async {
        if (corruptions-- > 0) File(path).writeAsBytesSync(const [9]);
      };
      http.contents['ms:0'] = [1, 2, 3];
      serveMoves();
      final id = await engine.enqueueDownload(
        [_remote('ms:0')],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
        mode: TransferMode.move,
      );
      final job = await until(id, settled);
      expect(job.files.single.sourceOutcome, SourceOutcome.trashed);
      expect(contentCalls(), hasLength(2));
    });

    test('the link drops before the check: paused with the whole part; '
        'after the reconnect only the check runs, then the trash', () async {
      http.contents['ms:0'] = [1, 2, 3];
      var down = true;
      serveMoves();
      final serve = http.json!;
      http.json = (c) {
        if (down && c.path.endsWith('/sha256')) {
          throw const SocketException('gone');
        }
        return serve(c);
      };
      probeOk = false;
      final id = await engine.enqueueDownload(
        [_remote('ms:0')],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
        mode: TransferMode.move,
      );
      var job = await until(
        id,
        (j) =>
            j.status == TransferStatus.paused &&
            j.files.single.status == TransferFileStatus.queued,
      );
      expect(job.pauseReason, TransferPauseReason.waitingForDevice);
      expect(job.files.single.bytesDone, 3);
      expect(parts(), hasLength(1));
      expect(trashCalls(), isEmpty);
      down = false;
      probeOk = true;
      engine
        ..onConnection(null)
        ..onConnection(_fp);
      job = await until(id, settled);
      expect(contentCalls(), hasLength(1));
      expect(job.files.single.sourceOutcome, SourceOutcome.trashed);
    });

    test('the other device refuses a changed original: B keeps its copy, '
        '"kept (changed)"', () async {
      http.contents['ms:0'] = [1, 2, 3];
      serveMoves(
        trash: (b) => {
          'trashed': <Object?>[],
          'failed': {'ms:0': 'verification_failed'},
        },
      );
      final id = await engine.enqueueDownload(
        [_remote('ms:0')],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
        mode: TransferMode.move,
      );
      final job = await until(id, settled);
      expect(job.files.single.sourceOutcome, SourceOutcome.keptChanged);
      expect(local.bytesOf('path:$_dl/ms0.jpg'), [1, 2, 3]);
    });

    test("the trash request can't reach the device: pending; sent again on "
        'the next connection', () async {
      http.contents['ms:0'] = [1, 2, 3];
      var reachable = false;
      serveMoves();
      final serve = http.json!;
      http.json = (c) {
        if (!reachable && c.path == ApiRoutes.filesTrash) {
          throw const SocketException('gone');
        }
        return serve(c);
      };
      final id = await engine.enqueueDownload(
        [_remote('ms:0')],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
        mode: TransferMode.move,
      );
      await until(id, (j) => j.status == TransferStatus.done);
      await until(id, (j) => trashCalls().isNotEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      var job = (await repo.dao.job(id))!;
      expect(job.files.single.originalPending, isTrue);
      reachable = true;
      engine
        ..onConnection(null)
        ..onConnection(_fp);
      job = await until(id, settled);
      expect(job.files.single.sourceOutcome, SourceOutcome.trashed);
    });

    test('a second move of a moved file: "already moved"', () async {
      http.failContent['ms:0'] = ApiErrorCode.notFound;
      serveMoves();
      final id = await engine.enqueueDownload(
        [_remote('ms:0')],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
        mode: TransferMode.move,
      );
      final job = await until(id, (j) => j.allFilesEnded);
      expect(job.files.single.status, TransferFileStatus.skipped);
      expect(job.files.single.error, TransferErrors.alreadyMoved);
      expect(trashCalls(), isEmpty);
    });

    test('cancel after a file verified: its original is kept '
        '(cancelled)', () async {
      http
        ..contents['ms:0'] = [1, 2, 3]
        ..held['ms:1'] = _Held(3);
      serveMoves();
      final id = await engine.enqueueDownload(
        [_remote('ms:0'), _remote('ms:1')],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
        mode: TransferMode.move,
      );
      await until(id, (j) => j.files.first.receiverSha256 != null);
      await engine.cancelJob(id);
      final job = await until(id, (j) => j.allFilesEnded);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(
        (await repo.dao.job(id))!.files.first.sourceOutcome,
        SourceOutcome.keptCancelled,
      );
      expect(job.files.last.status, TransferFileStatus.cancelled);
      expect(trashCalls(), isEmpty);
    });

    group('upload-move', () {
      late _UploadServer server;

      setUp(() {
        server = _UploadServer()..verify = true;
        http.json = server.handle;
      });

      test('verified on the other device; one trashBatch here with the '
          "job's delete mode", () async {
        final a = local.addFile('/storage/emulated/0/DCIM/a.jpg');
        final b = local.addFile(
          '/storage/emulated/0/DCIM/b.jpg',
          bytes: const [4, 5],
        );
        final id = await engine.enqueueUpload(
          [a, b],
          peerFingerprint: _fp,
          peerName: 'PC',
          rootId: 'cam',
          path: '',
          mode: TransferMode.move,
        );
        final job = await until(id, settled);
        expect(job.deleteMode, DeleteMode.trash);
        expect(local.calls.where((c) => c.startsWith('trashBatch')), [
          'trashBatch ${a.id},${b.id}',
        ]);
        expect(job.files.map((f) => f.sourceOutcome), [
          SourceOutcome.trashed,
          SourceOutcome.trashed,
        ]);
        expect(await local.stat(a.id), isNull);
        expect(local.trash, hasLength(2));
      });

      test(
        'permanent (snapshotted on the job): one deletePermanentlyBatch',
        () async {
          final a = local.addFile('/storage/emulated/0/DCIM/a.jpg');
          final id = await engine.enqueueUpload(
            [a],
            peerFingerprint: _fp,
            peerName: 'PC',
            rootId: 'cam',
            path: '',
            mode: TransferMode.move,
            deleteMode: DeleteMode.permanent,
          );
          final job = await until(id, settled);
          expect(job.deleteMode, DeleteMode.permanent);
          expect(local.calls, contains('deletePermanentlyBatch ${a.id}'));
          expect(
            job.files.single.sourceOutcome,
            SourceOutcome.deletedPermanently,
          );
          expect(local.trash, isEmpty);
        },
      );

      test('two mismatches: "verification failed", the original is '
          'untouched', () async {
        server.mismatches = 2;
        final a = local.addFile('/storage/emulated/0/DCIM/a.jpg');
        final id = await engine.enqueueUpload(
          [a],
          peerFingerprint: _fp,
          peerName: 'PC',
          rootId: 'cam',
          path: '',
          mode: TransferMode.move,
        );
        final job = await until(id, (j) => j.status == TransferStatus.failed);
        expect(job.files.single.error, TransferErrors.verificationFailed);
        expect(job.files.single.sourceOutcome, isNull);
        expect(server.completes, hasLength(2));
        expect(
          http.calls.where((c) => c.path == ApiRoutes.uploads),
          hasLength(2),
        );
        expect(await local.stat(a.id), isNotNull);
        expect(
          local.calls.where(
            (c) => c.startsWith('trash') || c.startsWith('delete'),
          ),
          isEmpty,
        );
      });

      test('a declined dialog keeps every original; "Delete originals" asks '
          'again', () async {
        final a = local.addFile('/storage/emulated/0/DCIM/a.jpg');
        local.declineDeletes = true;
        final id = await engine.enqueueUpload(
          [a],
          peerFingerprint: _fp,
          peerName: 'PC',
          rootId: 'cam',
          path: '',
          mode: TransferMode.move,
        );
        var job = await until(id, settled);
        expect(job.files.single.sourceOutcome, SourceOutcome.keptDeclined);
        expect(await local.stat(a.id), isNotNull);
        local.declineDeletes = false;
        await engine.deleteOriginals(id);
        job = await until(
          id,
          (j) => j.files.single.sourceOutcome == SourceOutcome.trashed,
        );
        expect(await local.stat(a.id), isNull);
      });

      test('a crash between verify and delete: after the restart nothing '
          'is deleted by itself; "Delete originals" does it', () async {
        final never = Completer<FinalizeResult>();
        await engine.dispose();
        engine = newEngine(verifiedMove: _NeverMove(never.future));
        await engine.start();
        engine.onConnection(_fp);
        final a = local.addFile('/storage/emulated/0/DCIM/a.jpg');
        final id = await engine.enqueueUpload(
          [a],
          peerFingerprint: _fp,
          peerName: 'PC',
          rootId: 'cam',
          path: '',
          mode: TransferMode.move,
        );
        await until(id, (j) => j.status == TransferStatus.done);
        await engine.dispose();
        engine = newEngine();
        await engine.start();
        engine.onConnection(_fp);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        var job = (await repo.dao.job(id))!;
        expect(job.files.single.originalPending, isTrue);
        expect(await local.stat(a.id), isNotNull);
        await engine.deleteOriginals(id);
        job = await until(id, settled);
        expect(job.files.single.sourceOutcome, SourceOutcome.trashed);
      });
    });
  });

  test('sender hash of a download comes from the other device', () async {
    final sha = sha256.convert(utf8.encode('x')).toString();
    http
      ..contents['ms:0'] = [1, 2]
      ..json = (c) =>
          c.path == ApiRoutes.fileSha256('ms:0') ? {'sha256': sha} : const {};
    final id = await engine.enqueueDownload(
      [_remote('ms:0', size: 2)],
      peerFingerprint: _fp,
      peerName: 'Phone',
      localFolder: _dl,
    );
    final job = await until(id, (j) => j.status == TransferStatus.done);
    expect(job.files.single.senderSha256, sha);
  });
}

class _Stripper implements TransferPreprocessor {
  new(this.onCleanup);

  final void Function() onCleanup;

  @override
  Future<PreparedSource> prepare(FileRef f, _) async => PreparedSource(
    sizeBytes: 2,
    read: (start, end) => Stream.value([7, 7].sublist(start, end)),
    cleanup: () async => onCleanup(),
  );
}

/// A [VerifiedMove] that never finishes (the app dies mid-delete).
class _NeverMove implements VerifiedMove {
  new(this.result);

  final Future<FinalizeResult> result;

  @override
  Future<FinalizeResult> deleteOriginals(
    List<VerifiedOriginal> originals, {
    required DeleteMode mode,
  }) => result;
}
