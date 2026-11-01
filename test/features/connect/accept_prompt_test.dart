import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/accept_gate.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/device_identity_repository_impl.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/pair_nonce_store.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/data/pairing_secret_store.dart';
import 'package:kfm/features/connect/data/routes/pair_routes.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/device_identity.dart';
import 'package:kfm/features/connect/domain/fingerprint_words.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:shelf/shelf.dart';

import 'handler_remote_http.dart';

DeviceIdentityRepositoryImpl _identity(String name) =>
    DeviceIdentityRepositoryImpl(
      store: InMemorySecretStore(),
      displayName: () async => name,
      platform: 'android',
      run: <R>(R Function() fn) async => fn(),
    );

/// A sharing device with the real N3 pieces: gate, sessions, authenticate.
class _Device {
  new(this.id, {Duration timeout = const Duration(seconds: 60)})
    : gate = AcceptGate(timeout: timeout),
      sessions = ClientSessionStore(),
      secrets = PairingSecretStore(autoRefresh: false),
      nonces = PairNonceStore() {
    secrets.start(
      addresses: const [(host: '192.168.1.23', port: 4433)],
      serverFingerprint: id.fingerprint,
      deviceName: id.displayName,
    );
    handler = buildSharePipeline(
      served: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
      authenticate: authenticate(sessions),
      routes: [
        ...coreRoutes(
          info: () async => ServerInfoDto(
            deviceId: id.deviceId,
            name: id.displayName,
            platform: id.platform,
            fingerprint: id.fingerprint,
            protocolVersion: kProtocolVersion,
          ),
          nonces: nonces,
        ),
        ...pairRoutes(
          secrets: secrets,
          nonces: nonces,
          handOff: promptHandOff(
            gate: gate,
            sessions: sessions,
            serverDeviceId: () async => id.deviceId,
          ),
        ),
        pairCancelRoute(gate),
      ],
    );
    gate.events.listen(events.add);
  }

  final DeviceIdentity id;
  final AcceptGate gate;
  final ClientSessionStore sessions;
  final PairingSecretStore secrets;
  final PairNonceStore nonces;
  late final Handler handler;
  final List<AcceptGateEvent> events = [];

  SecretActive get active => secrets.state as SecretActive;

  /// Completes when the next prompt opens.
  Future<ConnectionRequest> nextRequest() async {
    final e = await gate.events.firstWhere((e) => e is AcceptRequested);
    return e.request;
  }

  void dispose() {
    gate.cancelAll();
    sessions.clear();
    secrets.clear();
  }
}

Future<Response> _get(
  Handler h,
  String path, {
  String? token,
  String ip = '192.168.1.40',
}) async => await h(
  Request(
    'GET',
    Uri.parse('https://192.168.1.23:4433$path'),
    headers: {if (token != null) 'authorization': 'Bearer $token'},
    context: {'shelf.io.connection_info': FakeConnectionInfo(ip)},
  ),
);

Matcher _fails(PairingFailure f) =>
    throwsA(isA<PairingException>().having((e) => e.failure, 'failure', f));

void main() {
  late DeviceIdentityRepositoryImpl clientRepo;
  late DeviceIdentity clientId;
  late DeviceIdentity serverId;
  late DeviceIdentityRepositoryImpl otherRepo;

  setUpAll(() async {
    clientRepo = _identity('Phone B');
    otherRepo = _identity('Phone C');
    clientId = await clientRepo.loadOrCreate();
    await otherRepo.loadOrCreate();
    serverId = await _identity('Phone A').loadOrCreate();
  });

  late _Device a;
  late List<HandlerRemoteHttp> made;

  setUp(() {
    a = _Device(serverId);
    made = [];
  });

  tearDown(() => a.dispose());

  PairingClient client(
    _Device d, {
    DeviceIdentityRepositoryImpl? as,
    String ip = '192.168.1.40',
  }) => PairingClient(
    identity: as ?? clientRepo,
    pinned: (base, fp) {
      final h = HandlerRemoteHttp(
        d.handler,
        serverFingerprint: d.id.fingerprint,
        base: base,
        ip: ip,
      );
      made.add(h);
      return h;
    },
    firstContact: (base) {
      final h = HandlerRemoteHttp(
        d.handler,
        serverFingerprint: d.id.fingerprint,
        base: base,
        ip: ip,
      );
      made.add(h);
      return h;
    },
  );

  test('accept: prompt shows name + words, client gets a working token, '
      'both sides show the same 4 words', () async {
    final waitingWords = <List<String>>[];
    final requested = a.nextRequest();
    final pairing = client(a)
        .pairWithQr(a.active.offer, onWaiting: (_, w) => waitingWords.add(w));
    final request = await requested;
    expect(request.clientName, 'Phone B');
    expect(request.clientPlatform, 'android');
    expect(request.clientFingerprint, clientId.fingerprint);
    expect(request.remembered, isFalse);
    expect(
      request.words,
      fingerprintWords(serverId.fingerprint, clientId.fingerprint),
    );
    expect(waitingWords.single, request.words);
    expect(
      a.gate.decide(request.requestId, ConnectionDecision.accepted),
      isTrue,
    );
    final result = await pairing;
    expect(result.accepted.serverDeviceId, serverId.deviceId);
    expect(result.accepted.roots, isEmpty);
    final token = result.http.bearerToken!;
    final session = a.sessions.verify(token);
    expect(session?.clientFingerprint, clientId.fingerprint);
    expect(session?.clientName, 'Phone B');
    // Authenticated: an unbuilt route is 404 (not 401) with the token.
    expect(
      (await _get(a.handler, ApiRoutes.roots, token: token)).statusCode,
      404,
    );
    expect((await _get(a.handler, ApiRoutes.roots)).statusCode, 401);
  });

  test('short-code path goes through the same prompt', () async {
    final requested = a.nextRequest();
    final pairing = client(a).pairWithCode(
      base: Uri.parse('https://192.168.1.23:4433'),
      code: a.active.code,
    );
    final r = await requested;
    a.gate.decide(r.requestId, ConnectionDecision.accepted);
    expect((await pairing).accepted.token, isNotEmpty);
  });

  test('decline → declined, no session, nothing reachable', () async {
    final requested = a.nextRequest();
    final pairing = client(a).pairWithQr(a.active.offer);
    a.gate.decide((await requested).requestId, ConnectionDecision.declined);
    await expectLater(pairing, _fails(PairingFailure.declined));
    expect(a.sessions.sessions, isEmpty);
  });

  test(
    'no decision within the window → timed_out, dialog event closes',
    () async {
      a.dispose();
      a = _Device(serverId, timeout: const Duration(milliseconds: 50));
      await expectLater(
        client(a).pairWithQr(a.active.offer),
        _fails(PairingFailure.timedOut),
      );
      expect(
        a.events.last,
        isA<AcceptClosed>().having(
          (e) => e.decision,
          'decision',
          ConnectionDecision.timedOut,
        ),
      );
      expect(a.sessions.sessions, isEmpty);
    },
  );

  test('a second device while the prompt is open → busy, QR rotated, '
      'no second prompt', () async {
    final requested = a.nextRequest();
    final first = client(a).pairWithQr(a.active.offer);
    final r = await requested;
    final rotated = a.active.offer;
    await expectLater(
      client(a, as: otherRepo, ip: '192.168.1.41').pairWithQr(rotated),
      _fails(PairingFailure.busy),
    );
    // The busy request's secret stays consumed: the QR rotated again.
    expect(a.active.offer.toUri(), isNot(rotated.toUri()));
    expect(a.events.whereType<AcceptRequested>(), hasLength(1));
    expect(a.gate.pending?.requestId, r.requestId);
    a.gate.decide(r.requestId, ConnectionDecision.accepted);
    await first;
  });

  test(
    'client Cancel → /v1/pair/cancel closes the prompt; 410 cancelled',
    () async {
      final cancel = PairingCancel();
      final requested = a.nextRequest();
      final pairing = client(a).pairWithQr(a.active.offer, cancel: cancel);
      await requested;
      cancel.cancel();
      await expectLater(pairing, _fails(PairingFailure.cancelled));
      await pumpEventQueue();
      expect(a.gate.pending, isNull);
      expect(
        a.events.last,
        isA<AcceptClosed>().having(
          (e) => e.decision,
          'decision',
          ConnectionDecision.cancelled,
        ),
      );
      expect(made.last.sent, ['POST /v1/pair/cancel']);
    },
  );

  test('cancel from another IP or with an unknown id is ignored', () async {
    final requested = a.nextRequest();
    final pairing = client(a).pairWithQr(a.active.offer);
    final r = await requested;
    Future<int> cancel(String id, String ip) async => (await a.handler(
      fakeRequest(
        'POST',
        ApiRoutes.pairCancel,
        ip: ip,
        body: {'pairAttemptId': id},
      ),
    )).statusCode;
    expect(await cancel(r.pairAttemptId, '192.168.1.99'), 204);
    expect(await cancel('f' * 32, '192.168.1.40'), 204);
    expect(a.gate.pending?.requestId, r.requestId);
    expect(await cancel(r.pairAttemptId, '192.168.1.40'), 204);
    expect(a.gate.pending, isNull);
    await expectLater(pairing, _fails(PairingFailure.cancelled));
  });

  test('malformed cancel body → pairing_failed', () async {
    final res = await a.handler(
      fakeRequest('POST', ApiRoutes.pairCancel, body: {'x': 1}),
    );
    expect(res.statusCode, 401);
  });

  test('stop sharing while pending → cancelled; old tokens get 401', () async {
    final requested = a.nextRequest();
    final pairing = client(a).pairWithQr(a.active.offer);
    a.gate.decide((await requested).requestId, ConnectionDecision.accepted);
    final token = (await pairing).http.bearerToken!;

    final requested2 = a.nextRequest();
    final pairing2 = client(a, as: otherRepo).pairWithQr(a.active.offer);
    await requested2;
    // ShareServerController.stopSharing does exactly this.
    a.gate.cancelAll();
    a.sessions.clear();
    await expectLater(pairing2, _fails(PairingFailure.cancelled));
    expect(
      (await _get(a.handler, ApiRoutes.session, token: token)).statusCode,
      401,
    );
  });

  test('Disconnect (revoke) → the client’s next request gets 401', () async {
    final requested = a.nextRequest();
    final pairing = client(a).pairWithQr(a.active.offer);
    a.gate.decide((await requested).requestId, ConnectionDecision.accepted);
    final token = (await pairing).http.bearerToken!;
    expect(
      (await _get(a.handler, ApiRoutes.session, token: token)).statusCode,
      404,
    );
    a.sessions.revoke(a.sessions.sessions.single.sessionId);
    final res = await _get(a.handler, ApiRoutes.session, token: token);
    expect(res.statusCode, 401);
    expect(
      (jsonDecode(await res.readAsString()) as Map<String, Object?>)['code'],
      'unauthorized',
    );
  });

  test('remembered (N6 path) is labelled', () async {
    final requested = a.nextRequest();
    final handOff = promptHandOff(
      gate: a.gate,
      sessions: a.sessions,
      serverDeviceId: () async => 'srv',
    );
    final res = handOff(
      PairCandidate(
        hello: ClientHelloDto(
          pairAttemptId: 'a' * 32,
          clientDeviceId: clientId.deviceId,
          clientName: 'Phone B',
          clientPlatform: 'android',
          clientCertPem: clientId.certPem,
        ),
        clientFingerprint: clientId.fingerprint,
        remoteIp: '192.168.1.40',
        method: PairMethod.known,
        serverFingerprint: serverId.fingerprint,
      ),
    );
    final r = await requested;
    expect(r.remembered, isTrue);
    a.gate.decide(r.requestId, ConnectionDecision.declined);
    expect((await res).statusCode, 403);
    expect(a.sessions.sessions, isEmpty);
  });
}
