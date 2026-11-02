import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/known_devices_dao.dart';
import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/offer_service.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/data/routes/offer_routes.dart';
import 'package:kfm/features/connect/data/routes/upload_routes.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_offers_dao.dart';
import 'package:kfm/features/connect/data/share_scope_store.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/data/upload_store.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/share_offer.dart';
import 'package:kfm/features/transfers/data/transfer_engine.dart';
import 'package:kfm/features/transfers/data/transfers_dao.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:kfm/features/transfers/domain/transfer_preprocessor.dart';
import 'package:shelf/shelf.dart';

import '../../core/files/fake_file_source.dart';
import '../connect/handler_remote_http.dart' show FakeConnectionInfo;
import '../connect/path_guard_test.dart' show fakeGuard;

const _root = '/storage/emulated/0';
const _downloads = '$_root/Download';
final String _fpS = 'aa' * 32; // the sender (client)
final String _fpR = 'cc' * 32; // the receiver (server)

/// The sender's pinned client, calling the receiver's pipeline in-process.
class _ShelfHttp implements RemoteHttp {
  new(this.handler);

  final Handler handler;

  /// When set, chunk uploads wait for it (a send "mid-transfer").
  Completer<void>? holdPut;
  int putsWaiting = 0;
  final List<String> sent = [];

  @override
  Uri get base => Uri.parse('https://192.168.1.23:4433');

  @override
  String? bearerToken;

  Future<T> _send<T>(
    String method,
    String path,
    T Function(Map<String, Object?>) decode, {
    Object? json,
    List<int>? bytes,
    Map<String, String> query = const {},
  }) async {
    sent.add('$method $path');
    final uri = Uri.parse('https://192.168.1.23:4433$path')
        .replace(queryParameters: query.isEmpty ? null : query);
    final res = await handler(
      Request(
        method,
        uri,
        headers: {
          'authorization': 'Bearer $bearerToken',
          if (json != null) 'content-type': 'application/json',
          if (bytes != null) 'content-length': '${bytes.length}',
        },
        body: bytes ?? (json == null ? null : jsonEncode(json)),
        context: {
          'shelf.io.connection_info': FakeConnectionInfo('192.168.1.40'),
        },
      ),
    );
    final text = await res.readAsString();
    final map = text.isEmpty
        ? const <String, Object?>{}
        : jsonDecode(text) as Map<String, Object?>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw RemoteApiException(res.statusCode, ApiErrorDto.fromJson(map));
    }
    return decode(map);
  }

  @override
  Future<T> getJson<T>(
    String path, {
    required T Function(Map<String, Object?> json) decode,
    Map<String, String> query = const {},
    Duration? timeout,
  }) => _send('GET', path, decode, query: query);

  @override
  Future<T> postJson<T>(
    String path,
    Object? body, {
    required T Function(Map<String, Object?> json) decode,
    Duration? timeout,
  }) => _send('POST', path, decode, json: body ?? const {});

  @override
  Future<T> deleteJson<T>(
    String path, {
    required T Function(Map<String, Object?> json) decode,
  }) => _send('DELETE', path, decode);

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
    if (holdPut case final h?) {
      putsWaiting++;
      await h.future;
    }
    return await _send('PUT', path, decode, bytes: bytes, query: query);
  }

  @override
  Future<HttpClientResponse> getStream(
    String path, {
    Map<String, String> query = const {},
    Map<String, String> headers = const {},
  }) => throw UnimplementedError();

  @override
  void close() {}
}

/// TASK-N12 push end to end: the sender's engine against the receiver's
/// real routes (send-only session, offer, accept, guarded uploads).
void main() {
  // Receiver.
  late AppDatabase dbR;
  late DbWriteQueue queueR;
  late ClientSessionStore sessions;
  late FakeFileSource filesR;
  late Directory stagingR;
  late OfferService service;
  late DateTime nowR;
  // Sender.
  late AppDatabase dbS;
  late DbWriteQueue queueS;
  late TransfersRepository repo;
  late FakeFileSource local;
  late Directory stagingS;
  late _ShelfHttp http;
  late TransferEngine engine;
  late List<String> idle;
  late List<String> reconnects;
  late List<String> sendReconnects;
  late List<FileRef> picked;

  setUp(() async {
    nowR = DateTime.now();
    dbR = AppDatabase(NativeDatabase.memory());
    queueR = DbWriteQueue();
    sessions = ClientSessionStore();
    filesR = FakeFileSource()..addFolder(_downloads);
    stagingR = await Directory.systemTemp.createTemp('kfm_recv');
    final uploads = UploadStore(staging: () async => stagingR);
    service = OfferService(
      repo: OfferRepository(ShareOffersDao(dbR), queueR),
      devices: KnownDevicesRepository(KnownDevicesDao(dbR), queueR),
      sessions: () => sessions,
      uploads: uploads,
      freeBytes: (_) async => null,
      downloadsRoot: _downloads,
      clock: () => nowR,
    );
    final scopes = ShareScopeStore(sessions: sessions);
    final guard = AllowListGuard(
      scopeOf: scopes.scopeOf,
      source: () => filesR,
      paths: fakeGuard(existing: {_root, _downloads}),
      grants: service,
    );
    final handler = buildSharePipeline(
      served: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
      authenticate: authenticate(sessions),
      sizeLimitExempt: (r) =>
          isUploadChunkRequest(r) || isOfferCreateRequest(r),
      routes: [
        ...offerRoutes(() => service),
        ...uploadRoutes(
          UploadRoutesEnv(
            guard: guard,
            sessions: sessions,
            uploads: uploads,
            source: () => filesR,
            addToIndex: (_) async {},
            stagingFreeBytes: () async => null,
            grants: service,
          ),
        ),
      ],
    );
    http = _ShelfHttp(handler)
      ..bearerToken = sessions
          .issue(
            clientFingerprint: _fpS,
            clientDeviceId: 'd',
            clientName: 'Pixel',
            purpose: SessionPurpose.send,
          )
          .token;

    dbS = AppDatabase(NativeDatabase.memory());
    queueS = DbWriteQueue();
    repo = TransfersRepository(TransfersDao(dbS), queueS);
    local = FakeFileSource();
    stagingS = await Directory.systemTemp.createTemp('kfm_send');
    picked = [
      local.addFile('$_root/DCIM/a.jpg', bytes: [1, 2, 3, 4, 5]),
      local.addFile('$_root/DCIM/b.jpg', bytes: [6, 7]),
    ];
    idle = [];
    reconnects = [];
    sendReconnects = [];
    engine = TransferEngine(
      repo: repo,
      devices: KnownDevicesRepository(KnownDevicesDao(dbS), queueS),
      local: local,
      http: (fp) => fp == _fpR ? http : null,
      staging: () async => stagingS,
      preprocessor: const IdentityPreprocessor(),
      addToIndex: (_) async {},
      reconnect: (fp) async => reconnects.add(fp),
      reconnectToSend: (fp) async => sendReconnects.add(fp),
      onOffersIdle: idle.add,
      probe: (_) async => true,
      chunkBytes: 4,
      offerPollInterval: const Duration(hours: 1),
      liveInterval: const Duration(milliseconds: 20),
      persistInterval: Duration.zero,
    );
    await engine.start();
    engine.onConnection(_fpR);
  });

  tearDown(() async {
    await engine.dispose();
    service.dispose();
    sessions.clear();
    await queueS.close();
    await queueR.close();
    await dbS.close();
    await dbR.close();
    await local.dispose();
    await filesR.dispose();
    for (final d in [stagingR, stagingS]) {
      if (await d.exists()) await d.delete(recursive: true);
    }
  });

  Future<TransferJob> until(
    String id,
    bool Function(TransferJob j) test, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final end = DateTime.now().add(timeout);
    while (true) {
      await queueS.flush();
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

  Future<String> sendAndWaitForPrompt() async {
    final id = await engine.enqueueSend(
      picked,
      peerFingerprint: _fpR,
      peerName: 'Tablet',
    );
    final job = await until(id, (j) => j.awaitingAccept);
    expect(job.isOffer, isTrue);
    for (var i = 0; i < 200 && service.prompts.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(service.prompts.single.offer.id, job.offerId);
    return id;
  }

  test('offer → accept → both files arrive; job done; idle reported', () async {
    final id = await sendAndWaitForPrompt();
    // Waiting: no byte went anywhere, Resume does nothing.
    expect(http.sent.where((s) => s.startsWith('POST /v1/uploads')), isEmpty);
    await engine.resumeJob(id);
    expect((await repo.dao.job(id))!.awaitingAccept, isTrue);
    final offerId = (await repo.dao.job(id))!.offerId!;
    expect(await service.decide(offerId, accept: true), isTrue);
    await engine.checkOffers();
    final job = await until(id, (j) => j.status == TransferStatus.done);
    expect(job.doneCount, 2);
    final a = await filesR.stat('path:$_downloads/Pixel/a.jpg');
    final b = await filesR.stat('path:$_downloads/Pixel/b.jpg');
    expect(a?.sizeBytes, 5);
    expect(b?.sizeBytes, 2);
    expect(filesR.bytesOf('path:$_downloads/Pixel/a.jpg'), [1, 2, 3, 4, 5]);
    for (var i = 0; i < 100 && idle.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(idle, [_fpR]);
    final row = (await service.status(_fpS, offerId))!;
    expect(row.status.name, 'done');
  });

  test('decline → the job ends "declined"; nothing arrives', () async {
    final id = await sendAndWaitForPrompt();
    await service.decide((await repo.dao.job(id))!.offerId!, accept: false);
    await engine.checkOffers();
    final job = await until(id, (j) => j.isFinished);
    expect(job.status, TransferStatus.cancelled);
    expect(job.files.map((f) => f.error).toSet(), {
      TransferErrors.offerDeclined,
    });
    expect(filesR.calls.where((c) => c.startsWith('importFile')), isEmpty);
  });

  test('no answer → "no answer"', () async {
    final id = await sendAndWaitForPrompt();
    nowR = nowR.add(const Duration(minutes: 3));
    await engine.checkOffers();
    final job = await until(id, (j) => j.isFinished);
    expect(job.files.map((f) => f.error).toSet(), {
      TransferErrors.offerExpired,
    });
  });

  test('the receiver stops mid-transfer → "stopped by"; partials go', () async {
    final id = await sendAndWaitForPrompt();
    final offerId = (await repo.dao.job(id))!.offerId!;
    await service.decide(offerId, accept: true);
    http.holdPut = Completer<void>();
    await engine.checkOffers();
    for (var i = 0; i < 300; i++) {
      if (http.putsWaiting > 0) break;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await service.stopByReceiver(offerId);
    http.holdPut!.complete();
    final job = await until(id, (j) => j.isFinished);
    expect(job.files.map((f) => f.error).toSet(), {
      TransferErrors.offerCancelled,
    });
    expect(stagingR.listSync().where((e) => e.path.endsWith('.part')), isEmpty);
  });

  test('cancel on the sender ends the offer on the receiver', () async {
    final id = await sendAndWaitForPrompt();
    final offerId = (await repo.dao.job(id))!.offerId!;
    await engine.cancelJob(id);
    for (var i = 0; i < 100 && service.prompts.isNotEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(service.prompts, isEmpty);
    expect((await service.status(_fpS, offerId))!.status.name, 'cancelled');
  });

  test('a waiting send reconnects with a send-only session', () async {
    await sendAndWaitForPrompt();
    engine.onConnection(null, autoReconnect: true);
    await engine.reconnect(_fpR);
    expect(sendReconnects, [_fpR]);
    expect(reconnects, isEmpty);
  });

  test('offer rows: a restart re-posts idempotently', () async {
    final id = await sendAndWaitForPrompt();
    final offerId = (await repo.dao.job(id))!.offerId!;
    await engine.dispose();
    engine = TransferEngine(
      repo: repo,
      devices: KnownDevicesRepository(KnownDevicesDao(dbS), queueS),
      local: local,
      http: (fp) => fp == _fpR ? http : null,
      staging: () async => stagingS,
      preprocessor: const IdentityPreprocessor(),
      addToIndex: (_) async {},
      probe: (_) async => true,
      offerPollInterval: const Duration(hours: 1),
    );
    await engine.start();
    engine.onConnection(_fpR);
    await engine.checkOffers();
    expect(service.prompts.single.offer.id, offerId);
    expect((await dbR.select(dbR.shareOffers).get()).map((o) => o.status), [
      OfferStatus.pending,
    ]);
  });
}
