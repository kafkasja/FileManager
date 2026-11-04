import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/file_hasher.dart';
import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/device_identity_repository_impl.dart';
import 'package:kfm/features/connect/data/guarded_server_socket.dart';
import 'package:kfm/features/connect/data/known_devices_dao.dart';
import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/data/remote_trash_service.dart';
import 'package:kfm/features/connect/data/routes/file_routes.dart';
import 'package:kfm/features/connect/data/routes/session_routes.dart';
import 'package:kfm/features/connect/data/routes/upload_routes.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_scope_store.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/data/upload_store.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/domain/remote_file_id.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:kfm/features/connect/domain/upload_protocol.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/transfers/data/transfer_engine.dart';
import 'package:kfm/features/transfers/data/transfers_dao.dart';
import 'package:kfm/features/transfers/data/verified_move_impl.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:kfm/features/transfers/domain/transfer_preprocessor.dart';
import 'package:shelf/shelf.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/chaos_proxy.dart';
import 'path_guard_test.dart' show fakeGuard;

const _root = '/storage/emulated/0';
const _dcim = '$_root/DCIM';
const _dl = '$_root/Download/Phone';
final String _clientFp = 'cd' * 32;

final _loopback = [LocalAddress(InternetAddress.loopbackIPv4, 8, 'lo')];

List<int> _random(int n, int seed) {
  final r = Random(seed);
  return List<int>.generate(n, (_) => r.nextInt(256));
}

String _sha(List<int> b) => crypto.sha256.convert(b).toString();

/// The sharing device: a real `ShareServer` over TLS on loopback with the
/// N7 file routes and N9–N11 upload routes on a fake file source.
class _Peer {
  new _(this.db, this.staging);

  final AppDatabase db;
  final Directory staging;
  final ClientSessionStore sessions = ClientSessionStore();
  late final ShareScopeStore scopes = ShareScopeStore(sessions: sessions);
  final FakeFileSource files = _ChunkedSource()..addFolder(_dcim);
  late final UploadStore uploads = UploadStore(staging: () async => staging);
  late final ShareServer server;
  late int port;
  late String fp;

  /// Q8: awaited before the server hashes a finished upload's part (holds
  /// a `complete` while the link is cut).
  Future<void> Function()? beforePartHash;
  int completeHashes = 0;
  int completeRequests = 0;

  static Future<_Peer> start({
    Duration firstRequestTimeout = kFirstRequestTimeout,
  }) async {
    final peer = _Peer._(
      AppDatabase(NativeDatabase.memory()),
      await Directory.systemTemp.createTemp('kfm_chaos_server'),
    );
    await peer._start(firstRequestTimeout);
    return peer;
  }

  Future<void> _start(Duration firstRequestTimeout) async {
    final identity = DeviceIdentityRepositoryImpl(
      store: InMemorySecretStore(),
      displayName: () async => 'Phone A',
      platform: 'android',
      run: <R>(R Function() fn) async => fn(),
    );
    final dao = MediaIndexDao(db);
    final guard = AllowListGuard(
      scopeOf: scopes.scopeOf,
      source: () => files,
      paths: fakeGuard(existing: {_root, _dcim}),
    );
    final trash = RemoteTrashService(
      source: () => files,
      lock: SerialLock(),
      onNotice: (_) {},
      onOutcome: (_) {},
      removeFromIndex: dao.deleteIds,
      sessionAlive: (id) => sessions.sessions.any((s) => s.sessionId == id),
    );
    server = ShareServer(
      identity,
      (served) => _countCompletes(
        buildSharePipeline(
          served: served,
          authenticate: authenticate(sessions),
          sizeLimitExempt: isUploadChunkRequest,
          routes: [
            ...sessionRoutes(sessions, changeToken: (_) async => null),
            ...fileRoutes(
              FileRoutesEnv(
                guard: guard,
                scopeOf: scopes.scopeOf,
                sessions: sessions,
                source: () => files,
                dao: () => dao,
                addToIndex: (_) async {},
                canSeeAllFiles: () => true,
                thumbnails: () async => throw UnimplementedError(),
                trash: () => trash,
                diskLength: (_) async => null,
              ),
            ),
            ...uploadRoutes(
              UploadRoutesEnv(
                guard: guard,
                sessions: sessions,
                uploads: uploads,
                source: () => files,
                addToIndex: (_) async {},
                stagingFreeBytes: () async => null,
                hashPath: (path) async {
                  completeHashes++;
                  await beforePartHash?.call();
                  return await hashFileInIsolate(path);
                },
              ),
            ),
          ],
        ),
      ),
      addresses: () async => _loopback,
      bindAddress: InternetAddress.loopbackIPv4,
      firstRequestTimeout: firstRequestTimeout,
    );
    final state = await server.start();
    port = state.port!;
    fp = state.fingerprint!;
    scopes.set(
      _clientFp,
      const ShareScope([
        SharedRoot(id: 'cam', path: _dcim, label: 'DCIM', readOnly: false),
      ]),
    );
  }

  Handler _countCompletes(Handler h) => (r) async {
    if (r.url.path.endsWith('/complete')) completeRequests++;
    return await h(r);
  };

  /// A new session for the client (pairing is tested elsewhere).
  String issue([String clientFp = '']) => sessions
      .issue(
        clientFingerprint: clientFp.isEmpty ? _clientFp : clientFp,
        clientDeviceId: 'd',
        clientName: 'PC',
      )
      .token;

  List<String> partials() => [
    for (final e in staging.listSync()) e.uri.pathSegments.last,
  ];

  Future<void> stop() async {
    sessions.clear();
    await server.stop();
    await files.dispose();
    await db.close();
    if (await staging.exists()) await staging.delete(recursive: true);
  }
}

/// TASK-Q1: network chaos between the real `PinnedClient` / `TransferEngine`
/// / `RemoteConnectionController` and a real `ShareServer`, through
/// [ChaosProxy].
void main() {
  late _Peer peer;
  late ChaosProxy proxy;

  setUp(() async {
    peer = await _Peer.start();
    proxy = await ChaosProxy.start(peer.port);
  });

  tearDown(() async {
    await proxy.close();
    await peer.stop();
  });

  PinnedClient client([String? token]) =>
      PinnedClient.pinned(proxy.uri(), peer.fp)
        ..bearerToken = token ?? peer.issue();

  group('PinnedClient over a broken link', () {
    test('a response or handshake cut at any byte is a clean '
        'RemoteUnavailableException, never wrong data', () async {
      final token = peer.issue();
      final ok = client(token);
      final want = await ok.getJson(
        ApiRoutes.session,
        decode: (j) => j['changeToken'],
      );
      expect(want, isNull);
      ok.close();
      final total = proxy.downstreamBytes;
      expect(total, greaterThan(500));
      final failures = <String>[];
      // The last ~40 bytes are the TLS close_notify after the answer.
      for (var cut = 1; cut < total - 40; cut += max(1, total ~/ 25)) {
        proxy.cutDownstreamAfter = cut;
        final c = client(token);
        try {
          await c.getJson(ApiRoutes.session, decode: (j) => j);
          failures.add('cut at $cut/$total: succeeded');
        } on RemoteUnavailableException {
          // Expected: network / badResponse.
        } on Object catch (e) {
          failures.add('cut at $cut/$total: ${e.runtimeType} $e');
        } finally {
          c.close();
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('a request cut while uploading a chunk leaves the server partial '
        'at the last whole chunk; the retry resumes there', () async {
      final token = peer.issue();
      final bytes = _random(600 * 1024, 1);
      final id = 'e0' * 16;
      var c = client(token);
      await c.postJson(
        ApiRoutes.uploads,
        CreateUploadDto(
          uploadId: id,
          rootId: 'cam',
          path: '',
          name: 'u.jpg',
          size: bytes.length,
        ).toJson(),
        decode: UploadStatusDto.fromJson,
      );
      // First chunk 300 KB ok; the second is cut halfway.
      await c.putStream(
        ApiRoutes.uploadChunk(id),
        Stream.value(bytes.sublist(0, 300 * 1024)),
        300 * 1024,
        query: const {'offset': '0'},
        decode: UploadStatusDto.fromJson,
      );
      // Per connection: the new client's handshake + headers + ~150 KB.
      proxy.cutUpstreamAfter = 150 * 1024;
      c.close();
      c = client(token);
      await expectLater(
        c.putStream(
          ApiRoutes.uploadChunk(id),
          Stream.value(bytes.sublist(300 * 1024)),
          300 * 1024,
          query: const {'offset': '${300 * 1024}'},
          decode: UploadStatusDto.fromJson,
        ),
        throwsA(isA<RemoteUnavailableException>()),
      );
      c.close();
      proxy.cutUpstreamAfter = null;
      c = client(token);
      // The server noticed the cut and truncated back (it may take a beat
      // to see the dead socket).
      UploadStatusDto status;
      final end = DateTime.now().add(const Duration(seconds: 10));
      do {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        status = await c.getJson(
          ApiRoutes.upload(id),
          decode: UploadStatusDto.fromJson,
        );
      } while (status.received != 300 * 1024 && DateTime.now().isBefore(end));
      expect(status.received, 300 * 1024);
      await c.putStream(
        ApiRoutes.uploadChunk(id),
        Stream.value(bytes.sublist(300 * 1024)),
        300 * 1024,
        query: const {'offset': '${300 * 1024}'},
        decode: UploadStatusDto.fromJson,
      );
      final done = await c.postJson(
        ApiRoutes.uploadComplete(id),
        CompleteUploadDto(sha256: _sha(bytes)).toJson(),
        decode: UploadCompletedDto.fromJson,
      );
      c.close();
      expect(done.sha256, _sha(bytes));
      expect(peer.files.bytesOf(done.finalId), bytes);
      expect(peer.partials(), isEmpty);
    });

    test('dead-but-open link (blackhole): a JSON call times out; closing the '
        'client aborts a hung chunk upload at once', () async {
      final token = peer.issue();
      final c = client(token);
      await c.getJson(ApiRoutes.session, decode: (j) => j);
      proxy.blackhole = true;
      final watch = Stopwatch()..start();
      await expectLater(
        c.getJson(
          ApiRoutes.session,
          decode: (j) => j,
          timeout: kHeartbeatTimeout,
        ),
        throwsA(
          isA<RemoteUnavailableException>().having(
            (e) => e.reason,
            'reason',
            RemoteUnavailableReason.timeout,
          ),
        ),
      );
      expect(watch.elapsed, lessThan(const Duration(seconds: 6)));

      final id = 'e1' * 16;
      proxy.blackhole = false;
      await c.postJson(
        ApiRoutes.uploads,
        CreateUploadDto(
          uploadId: id,
          rootId: 'cam',
          path: '',
          name: 'b.jpg',
          size: 10,
        ).toJson(),
        decode: UploadStatusDto.fromJson,
      );
      // Half the chunk went out on the open connection, then the link died.
      final body = StreamController<List<int>>()..add(List.filled(5, 7));
      final hung = c.putStream(
        ApiRoutes.uploadChunk(id),
        body.stream,
        10,
        query: const {'offset': '0'},
        decode: UploadStatusDto.fromJson,
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      proxy.blackhole = true;
      watch.reset();
      c.close(); // what the heartbeat's teardown does
      await expectLater(hung, throwsA(isA<RemoteUnavailableException>()));
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
      unawaited(body.close());

      // Reconnected on another path: the server is not stuck on the dead
      // socket's chunk.
      final direct = PinnedClient.pinned(
        Uri.parse('https://127.0.0.1:${peer.port}'),
        peer.fp,
      )..bearerToken = peer.issue();
      final s = await direct.putStream(
        ApiRoutes.uploadChunk(id),
        Stream.value(List<int>.filled(10, 7)),
        10,
        query: const {'offset': '0'},
        decode: UploadStatusDto.fromJson,
      );
      expect(s.received, 10);
      direct.close();
    });

    test('Q7: a chunk upload that stops moving on a dead-but-open link '
        'times out by itself (no heartbeat teardown needed)', () async {
      final c = client()..putStallTimeout = const Duration(seconds: 1);
      final id = 'e2' * 16;
      await c.postJson(
        ApiRoutes.uploads,
        CreateUploadDto(
          uploadId: id,
          rootId: 'cam',
          path: '',
          name: 'stall.jpg',
          size: 10,
        ).toJson(),
        decode: UploadStatusDto.fromJson,
      );
      final body = StreamController<List<int>>()..add(List.filled(5, 7));
      final hung = c.putStream(
        ApiRoutes.uploadChunk(id),
        body.stream,
        10,
        query: const {'offset': '0'},
        decode: UploadStatusDto.fromJson,
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      proxy.blackhole = true;
      final watch = Stopwatch()..start();
      await expectLater(
        hung,
        throwsA(
          isA<RemoteUnavailableException>().having(
            (e) => e.reason,
            'reason',
            RemoteUnavailableReason.timeout,
          ),
        ),
      );
      expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
      unawaited(body.close());
      c.close();
    });

    test('two clients at once and the same client twice: the replaced '
        'session ends with an error, never a short "complete" body', () async {
      final big = peer.files.addFile(
        '$_dcim/big.jpg',
        bytes: _random(3 * 1024 * 1024, 2),
      );
      final other = peer.files.addFile(
        '$_dcim/o.jpg',
        bytes: _random(512 * 1024, 3),
      );
      peer.scopes.set(
        'ef' * 32,
        const ShareScope([
          SharedRoot(id: 'cam', path: _dcim, label: 'DCIM', readOnly: false),
        ]),
      );
      proxy.bytesPerSecond = 2 * 1024 * 1024;
      final a = client();
      final b = client(peer.issue('ef' * 32));
      Future<List<int>> read(PinnedClient c, FileRef f) async {
        final res = await c.getStream(ApiRoutes.fileContent(f.id));
        final out = <int>[];
        await res.forEach(out.addAll);
        return out;
      }

      final aRead = read(a, big);
      final bRead = read(b, other);
      // The same client connects again (reconnect race / second tab).
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final a2 = client(peer.issue());
      expect(await bRead, peer.files.bytesOf(other.id));
      await expectLater(aRead, throwsA(isA<HttpException>()));
      await expectLater(
        a.getJson(ApiRoutes.session, decode: (j) => j),
        throwsA(
          isA<RemoteApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.unauthorized,
          ),
        ),
      );
      proxy.bytesPerSecond = null;
      expect(await read(a2, big), peer.files.bytesOf(big.id));
      for (final c in [a, a2, b]) {
        c.close();
      }
      await _settle(() => proxy.openConnections == 0);
      expect(proxy.openConnections, 0, reason: 'leaked sockets');
    });
  });

  group('TransferEngine through drops', () {
    late AppDatabase db;
    late DbWriteQueue queue;
    late TransfersRepository repo;
    late KnownDevicesRepository devices;
    late FakeFileSource local;
    late Directory staging;
    late TransferEngine engine;
    late PinnedClient http;
    late int reconnects;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      queue = DbWriteQueue();
      repo = TransfersRepository(TransfersDao(db), queue);
      devices = KnownDevicesRepository(KnownDevicesDao(db), queue);
      local = FakeFileSource()..addFolder(_dl);
      staging = await Directory.systemTemp.createTemp('kfm_chaos_client');
      http = client();
      reconnects = 0;
      engine = TransferEngine(
        repo: repo,
        devices: devices,
        local: local,
        http: (fp) => fp == peer.fp ? http : null,
        staging: () async => staging,
        preprocessor: const IdentityPreprocessor(),
        addToIndex: (_) async {},
        reconnect: (fp) async => reconnects++,
        verifiedMove: LocalVerifiedMove(
          source: local,
          lock: SerialLock(),
          removeFromIndex: (_) async {},
        ),
        chunkBytes: 128 * 1024,
        liveInterval: const Duration(milliseconds: 50),
        persistInterval: Duration.zero,
        retryBase: const Duration(milliseconds: 20),
        retryCap: const Duration(milliseconds: 200),
        reconnectBase: const Duration(milliseconds: 50),
        reconnectCap: const Duration(milliseconds: 400),
      );
      await engine.start();
      engine.onConnection(peer.fp);
    });

    tearDown(() async {
      await engine.dispose();
      http.close();
      await queue.close();
      await db.close();
      await local.dispose();
      if (await staging.exists()) await staging.delete(recursive: true);
    });

    Future<TransferJob> until(
      String id,
      bool Function(TransferJob j) test, {
      Duration timeout = const Duration(seconds: 60),
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
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    bool settled(TransferJob j) =>
        j.allFilesEnded &&
        j.files.every(
          (f) =>
              f.status != TransferFileStatus.done ||
              j.mode != TransferMode.move ||
              f.sourceOutcome != null,
        );

    FileRef remoteRef(FileRef f) => FileRef(
      id: remoteFileId(peer.fp, f.id),
      uri: 'remote://x',
      name: f.name,
      kind: FileKind.image,
      sizeBytes: f.sizeBytes,
      modifiedAt: f.modifiedAt,
      folderPath: 'cam',
      origin: FileOrigin.remote,
    );

    /// Waits until [bytes] more went through, then drops the link for
    /// [down].
    Future<void> dropAfter(
      int bytes,
      Duration down, {
      bool upstream = false,
    }) async {
      int now() => upstream ? proxy.upstreamBytes : proxy.downstreamBytes;
      final target = now() + bytes;
      await _settle(
        () => now() >= target,
        timeout: const Duration(seconds: 30),
      );
      await proxy.drop(down);
    }

    for (final mode in TransferMode.values) {
      test('download (${mode.name}) through drops of 0.3 s and 2 s: resumes '
          'from the partial; one whole file; original kept unless '
          'verified', () async {
        final bytes = _random(4 * 1024 * 1024, 4);
        final src = peer.files.addFile('$_dcim/big.jpg', bytes: bytes);
        proxy.bytesPerSecond = 3 * 1024 * 1024;
        final id = await engine.enqueueDownload(
          [remoteRef(src)],
          peerFingerprint: peer.fp,
          peerName: 'Phone A',
          localFolder: _dl,
          mode: mode,
        );
        await dropAfter(1024 * 1024, const Duration(milliseconds: 300));
        await dropAfter(1024 * 1024, const Duration(seconds: 2));
        final job = await until(id, settled);
        final f = job.files.single;
        expect(f.status, TransferFileStatus.done, reason: f.error);
        final copies = local.files.where((x) => x.folderPath == _dl).toList();
        expect(copies.map((x) => x.name), ['big.jpg'], reason: 'one copy');
        expect(local.bytesOf(copies.single.id), bytes);
        // Resumed, not restarted from 0 every time.
        expect(proxy.downstreamBytes, lessThan(bytes.length * 2));
        expect(staging.listSync(), isEmpty, reason: 'client partials');
        if (mode == TransferMode.move) {
          expect(f.sourceOutcome, SourceOutcome.trashed);
          expect(await peer.files.stat(src.id), isNull);
        } else {
          expect(peer.files.bytesOf(src.id), bytes);
        }
      });

      test('upload (${mode.name}) through drops of 0.3 s and 2 s: resumes '
          'at the server offset; one whole file; original kept unless '
          'verified', () async {
        final bytes = _random(3 * 1024 * 1024, 5);
        final src = local.addFile('$_root/DCIM/Camera/up.jpg', bytes: bytes);
        proxy.bytesPerSecond = 3 * 1024 * 1024;
        final id = await engine.enqueueUpload(
          [src],
          peerFingerprint: peer.fp,
          peerName: 'Phone A',
          rootId: 'cam',
          path: '',
          mode: mode,
        );
        await dropAfter(
          800 * 1024,
          const Duration(milliseconds: 300),
          upstream: true,
        );
        await dropAfter(800 * 1024, const Duration(seconds: 2), upstream: true);
        final job = await until(id, settled);
        final f = job.files.single;
        expect(f.status, TransferFileStatus.done, reason: f.error);
        final copies = peer.files.files
            .where((x) => x.folderPath == _dcim)
            .toList();
        expect(copies.map((x) => x.name), ['up.jpg'], reason: 'one copy');
        expect(peer.files.bytesOf(copies.single.id), bytes);
        expect(proxy.upstreamBytes, lessThan(bytes.length * 2));
        expect(peer.partials(), isEmpty, reason: 'server partials');
        if (mode == TransferMode.move) {
          expect(f.sourceOutcome, SourceOutcome.trashed);
          expect(await local.stat(src.id), isNull);
        } else {
          expect(local.bytesOf(src.id), bytes);
        }
      });
    }

    for (final mode in TransferMode.values) {
      test('upload (${mode.name}): the link drops while the other device '
          'checks the finished file; the retry joins the running complete: '
          'one file, bytes sent once, original trashed once', () async {
        final bytes = _random(1024 * 1024, 7);
        final src = local.addFile('$_root/DCIM/Camera/q8.jpg', bytes: bytes);
        final held = Completer<void>();
        final release = Completer<void>();
        peer.beforePartHash = () async {
          if (!held.isCompleted) held.complete();
          await release.future;
        };
        final id = await engine.enqueueUpload(
          [src],
          peerFingerprint: peer.fp,
          peerName: 'Phone A',
          rootId: 'cam',
          path: '',
          mode: mode,
        );
        await held.future.timeout(const Duration(seconds: 30));
        // The complete's answer can't arrive: the link drops for 1 s.
        await proxy.drop(const Duration(seconds: 1));
        // The client comes back and asks again (status, then complete)
        // while the first complete still runs on the other side.
        await _settle(
          () => peer.completeRequests >= 2,
          timeout: const Duration(seconds: 20),
        );
        expect(peer.completeRequests, 2, reason: 'asked again while held');
        await Future<void>.delayed(const Duration(milliseconds: 100));
        release.complete();
        final job = await until(id, settled);
        final f = job.files.single;
        expect(f.status, TransferFileStatus.done, reason: f.error);
        final copies = peer.files.files
            .where((x) => x.folderPath == _dcim)
            .toList();
        expect(copies.map((x) => x.name), ['q8.jpg'], reason: 'one copy');
        expect(peer.files.bytesOf(copies.single.id), bytes);
        expect(peer.completeHashes, 1, reason: 'published once');
        expect(proxy.upstreamBytes, lessThan(bytes.length * 1.5));
        expect(peer.partials(), isEmpty);
        if (mode == TransferMode.move) {
          expect(f.sourceOutcome, SourceOutcome.trashed);
          expect(await local.stat(src.id), isNull);
          expect(
            local.calls.where((c) => c.startsWith('trashBatch')),
            hasLength(1),
          );
        } else {
          expect(local.bytesOf(src.id), bytes);
        }
      });
    }

    test('flapping (10 drops) mid-download: finishes; bounded retries; no '
        'leaked sockets or timers', () async {
      final bytes = _random(3 * 1024 * 1024, 6);
      final src = peer.files.addFile('$_dcim/flap.jpg', bytes: bytes);
      proxy.bytesPerSecond = 2 * 1024 * 1024;
      final id = await engine.enqueueDownload(
        [remoteRef(src)],
        peerFingerprint: peer.fp,
        peerName: 'Phone A',
        localFolder: _dl,
      );
      await proxy.flap(
        times: 10,
        up: const Duration(milliseconds: 150),
        down: const Duration(milliseconds: 100),
      );
      final job = await until(id, settled);
      expect(job.files.single.status, TransferFileStatus.done);
      final copy = local.files.singleWhere((x) => x.folderPath == _dl);
      expect(local.bytesOf(copy.id), bytes);
      // Backoff holds: a handful of connections per drop, not a storm.
      expect(proxy.accepted, lessThan(150));
      expect(engine.runningCount, 0);
      final acceptedAtEnd = proxy.accepted;
      await Future<void>.delayed(const Duration(seconds: 1));
      expect(proxy.accepted, acceptedAtEnd, reason: 'no retries after done');
      http.close();
      await _settle(() => proxy.openConnections == 0);
      expect(proxy.openConnections, 0, reason: 'leaked sockets');
    });
  });

  test('heartbeat over a dead-but-open link ends the connection as '
      'networkLost and closes the client', () async {
    final container = ProviderContainer(
      overrides: [remoteFollowsAppLifecycleProvider.overrideWithValue(false)],
    );
    addTearDown(container.dispose);
    container.listen(remoteConnectionControllerProvider, (_, _) {});
    final c = client();
    container
        .read(remoteConnectionControllerProvider.notifier)
        .connect(
          PairingSuccess(
            http: c,
            accepted: const PairAcceptedDto(
              token: 't',
              serverDeviceId: 's',
              roots: [],
            ),
            peerName: 'Phone A',
            peerFingerprint: peer.fp,
          ),
        );
    await Future<void>.delayed(const Duration(seconds: 6));
    expect(
      container.read(remoteConnectionControllerProvider),
      isA<RemoteConnected>(),
    );
    proxy.blackhole = true;
    final watch = Stopwatch()..start();
    await _settle(
      () =>
          container.read(remoteConnectionControllerProvider)
              is RemoteDisconnected,
      timeout: const Duration(seconds: 40),
    );
    final s = container.read(remoteConnectionControllerProvider);
    expect(
      s,
      isA<RemoteDisconnected>().having(
        (d) => d.reason,
        'reason',
        DisconnectReason.networkLost,
      ),
    );
    // 3 failed ticks of 5 s, each giving up after 4 s (~15-19 s).
    expect(watch.elapsed, lessThan(const Duration(seconds: 22)));
    expect(c.bearerToken, isNull);
  }, timeout: const Timeout(Duration(seconds: 60)));

  group('server under abuse (raw sockets)', () {
    Future<SecureSocket> raw() => SecureSocket.connect(
      InternetAddress.loopbackIPv4,
      peer.port,
      onBadCertificate: (_) => true,
    );

    /// Writes [request] on a raw TLS socket; the answer until the server
    /// closes it (or 15 s).
    Future<String> exchange(String request) async {
      final answer = <int>[];
      final done = Completer<void>();
      void end([Object? _]) {
        if (!done.isCompleted) done.complete();
      }

      final s = (await raw())
        ..listen(answer.addAll, onError: end, onDone: end)
        ..write(request);
      unawaited(s.flush().then<void>((_) {}, onError: end));
      await done.future.timeout(const Duration(seconds: 15), onTimeout: () {});
      s.destroy();
      return latin1.decode(answer);
    }

    Future<int> sessionStatus() async {
      final c = PinnedClient.pinned(
        Uri.parse('https://127.0.0.1:${peer.port}'),
        peer.fp,
      )..bearerToken = peer.issue();
      try {
        await c.getJson(
          ApiRoutes.session,
          decode: (j) => j,
          timeout: const Duration(seconds: 5),
        );
        return 200;
      } on RemoteApiException catch (e) {
        return e.status;
      } finally {
        c.close();
      }
    }

    test('slow headers (slowloris) and half-open TLS handshakes do not block '
        'other clients', () async {
      final slow = <Socket>[];
      for (var i = 0; i < 30; i++) {
        final s = await raw();
        s.write('GET /v1/session HTTP/1.1\r\nHost: x\r\n');
        slow.add(s);
      }
      final plain = <Socket>[];
      for (var i = 0; i < 30; i++) {
        // TCP connected, TLS never started.
        plain.add(
          await Socket.connect(InternetAddress.loopbackIPv4, peer.port),
        );
      }
      for (final s in slow) {
        s.write('X-Slow: 1\r\n');
      }
      expect(await sessionStatus(), 200);
      for (final s in [...slow, ...plain]) {
        s.destroy();
      }
    });

    test('Q7: sockets that never finish their first request (slowloris, '
        'TCP without TLS) are closed after the watchdog; a slow download '
        'that runs longer is not cut', () async {
      final quick = await _Peer.start(
        firstRequestTimeout: const Duration(seconds: 1),
      );
      addTearDown(quick.stop);
      final ended = <Future<void>>[];
      Future<void> endOf(Socket s) {
        final done = Completer<void>();
        s.listen(
          (_) {},
          onError: (Object _) {
            if (!done.isCompleted) done.complete();
          },
          onDone: () {
            if (!done.isCompleted) done.complete();
          },
        );
        return done.future;
      }

      final slow = await SecureSocket.connect(
        InternetAddress.loopbackIPv4,
        quick.port,
        onBadCertificate: (_) => true,
      );
      slow.write('GET /v1/session HTTP/1.1\r\nHost: x\r\n');
      ended.add(endOf(slow));
      final plain = await Socket.connect(
        InternetAddress.loopbackIPv4,
        quick.port,
      );
      ended.add(endOf(plain));

      // A 2 MB download at 512 KB/s (~4 s) over a throttled link.
      final bytes = _random(2 * 1024 * 1024, 9);
      final src = quick.files.addFile('$_dcim/slow.jpg', bytes: bytes);
      quick.scopes.set(
        _clientFp,
        const ShareScope([
          SharedRoot(id: 'cam', path: _dcim, label: 'DCIM', readOnly: false),
        ]),
      );
      final link = await ChaosProxy.start(quick.port);
      addTearDown(link.close);
      link.bytesPerSecond = 512 * 1024;
      final c = PinnedClient.pinned(link.uri(), quick.fp)
        ..bearerToken = quick.issue();
      addTearDown(c.close);
      final watch = Stopwatch()..start();
      final res = await c.getStream(ApiRoutes.fileContent(src.id));
      final got = <int>[];
      await res.forEach(got.addAll);
      expect(watch.elapsed, greaterThan(const Duration(seconds: 2)));
      expect(got.length, bytes.length);
      expect(_sha(got), _sha(bytes));

      // Both idle sockets were closed by the server long before.
      await Future.wait(ended).timeout(const Duration(seconds: 1));
      slow.destroy();
      plain.destroy();
    });

    test('a huge header or request line is refused without taking the '
        'server down', () async {
      for (final request in [
        'GET /v1/session HTTP/1.1\r\nHost: x\r\nX-Big: ${'a' * (1 << 21)}\r\n\r\n',
        'GET /${'a' * (2 * 1024 * 1024)} HTTP/1.1\r\nHost: x\r\n\r\n',
        'GET /v1/session HTTP/1.1\r\n${'X-H: 1\r\n' * 50000}\r\n',
      ]) {
        final text = await exchange(request);
        expect(
          text.isEmpty || RegExp(r'^HTTP/1\.1 4\d\d').hasMatch(text),
          isTrue,
          reason: text.length > 200 ? text.substring(0, 200) : text,
        );
      }
      expect(await sessionStatus(), 200);
    });

    test(
      'odd request targets (absolute form, //, .., bad '
      'percent-encoding) and a garbage Host are answered, never a 5xx',
      () async {
        for (final line in [
          'GET https://evil.example/v1/roots HTTP/1.1',
          'GET //v1/roots HTTP/1.1',
          'GET /v1/../v1/roots HTTP/1.1',
          'GET /v1/files/%ff%fe/content HTTP/1.1',
          'GET /v1/files/%00/content HTTP/1.1',
          'POST /v1/uploads/${'ab' * 16}/complete HTTP/1.1',
        ]) {
          final text = await exchange(
            '$line\r\nHost: ÿ\r\nConnection: close\r\n'
            'Authorization: Bearer ${peer.issue()}\r\n'
            'Content-Length: 0\r\n\r\n',
          );
          final status = RegExp(r'^HTTP/1\.1 (\d{3})').firstMatch(text);
          expect(status, isNotNull, reason: '$line → $text');
          expect(
            int.parse(status!.group(1)!),
            inInclusiveRange(200, 499),
            reason: '$line → $text',
          );
        }
        expect(await sessionStatus(), 200);
      },
    );
  });
}

Future<void> _settle(
  bool Function() done, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);
  while (!done() && DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

/// Reads in 64 KB pieces like a real file (FakeFileSource hands out one
/// chunk, which a cancelled stream can't cut any more).
class _ChunkedSource extends FakeFileSource {
  @override
  Stream<List<int>> openRead(FileRef f, {int start = 0, int? end}) async* {
    final all = <int>[];
    await super.openRead(f, start: start, end: end).forEach(all.addAll);
    for (var i = 0; i < all.length; i += 64 * 1024) {
      yield all.sublist(i, min(all.length, i + 64 * 1024));
    }
  }
}
