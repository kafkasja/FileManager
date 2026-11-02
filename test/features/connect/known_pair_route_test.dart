import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/accept_gate.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/crypto/identity_proof.dart';
import 'package:kfm/features/connect/data/device_identity_repository_impl.dart';
import 'package:kfm/features/connect/data/known_pair_limiter.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/pair_nonce_store.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/data/pairing_secret_store.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/data/routes/pair_routes.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_scope_store.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/device_identity.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:shelf/shelf.dart';

import 'handler_remote_http.dart';

DeviceIdentityRepositoryImpl _identity(String name) =>
    DeviceIdentityRepositoryImpl(
      store: InMemorySecretStore(),
      displayName: () async => name,
      platform: 'android',
      run: <R>(R Function() fn) async => fn(),
    );

Uint8List _utf8(String s) => Uint8List.fromList(utf8.encode(s));

KnownDevice _known(String fp, {bool autoAccept = false}) => KnownDevice(
  id: 'id-$fp',
  peerDeviceId: 'dev',
  name: 'Phone B',
  platform: 'android',
  fingerprint: fp,
  lastSeenAt: DateTime(2026),
  lastAddresses: const [],
  allowedRoots: const [],
  canShareToUs: false,
  isTemporary: false,
  autoAccept: autoAccept,
);

/// TASK-N6 `POST /v1/pair/known` with the real gate, sessions, nonces and
/// N3 prompt hand-off.
void main() {
  late DeviceIdentityRepositoryImpl serverRepo;
  late DeviceIdentityRepositoryImpl clientRepo;
  late DeviceIdentityRepositoryImpl otherRepo;
  late DeviceIdentity serverId;
  late DeviceIdentity clientId;
  late DeviceIdentity otherId;

  setUpAll(() async {
    serverRepo = _identity('Phone A');
    clientRepo = _identity('Phone B');
    otherRepo = _identity('Other');
    serverId = await serverRepo.loadOrCreate();
    clientId = await clientRepo.loadOrCreate();
    otherId = await otherRepo.loadOrCreate();
  });

  late DateTime now;
  late Map<String, KnownDevice> known;
  late AcceptGate gate;
  late ClientSessionStore sessions;
  late ShareScopeStore scopes;
  late PairNonceStore nonces;
  late PairingSecretStore secrets;
  late KnownPairLimiter limiter;
  late Handler handler;
  late List<AcceptGateEvent> events;
  late Map<String, StoredScope> stored;

  setUp(() {
    now = DateTime(2026, 11, 2);
    known = {};
    stored = {};
    gate = AcceptGate();
    sessions = ClientSessionStore();
    scopes = ShareScopeStore(sessions: sessions);
    nonces = PairNonceStore(clock: () => now);
    limiter = KnownPairLimiter(clock: () => now);
    secrets = PairingSecretStore(autoRefresh: false, clock: () => now)
      ..start(
        addresses: const [(host: '192.168.1.23', port: 4433)],
        serverFingerprint: serverId.fingerprint,
        deviceName: 'Phone A',
      );
    events = [];
    gate.events.listen(events.add);
    final handOff = promptHandOff(
      gate: gate,
      sessions: sessions,
      serverDeviceId: () async => serverId.deviceId,
      roots: (fp) => scopes.scopeOf(fp).toDtos(),
      beforeIssue: (c) => seedStoredScope(
        load: (fp) async => stored[fp] ?? StoredScope.empty,
        scopes: scopes,
        clientFingerprint: c.clientFingerprint,
      ),
    );
    handler = buildSharePipeline(
      served: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
      authenticate: authenticate(sessions),
      routes: [
        ...coreRoutes(
          info: () async => ServerInfoDto(
            deviceId: serverId.deviceId,
            name: serverId.displayName,
            platform: serverId.platform,
            fingerprint: serverId.fingerprint,
            protocolVersion: kProtocolVersion,
          ),
          nonces: nonces,
        ),
        ...pairRoutes(secrets: secrets, nonces: nonces, handOff: handOff),
        knownPairRoute(
          nonces: nonces,
          limiter: limiter,
          serverFingerprint: () async => serverId.fingerprint,
          lookup: (fp) async => known[fp],
          handOff: handOff,
        ),
      ],
    );
  });

  tearDown(() {
    gate.cancelAll();
    sessions.clear();
    secrets.clear();
  });

  Future<Uint8List> nonce([String ip = '192.168.1.40']) async {
    final r = await handler(fakeRequest('POST', ApiRoutes.pairNonce, ip: ip));
    final json = jsonDecode(await r.readAsString()) as Map<String, Object?>;
    return fromB64url(PairNonceDto.fromJson(json).nonce)!;
  }

  /// `/v1/pair/known` as [as] (cert), signed by [signer].
  Future<Response> knownPair({
    DeviceIdentity? as,
    DeviceIdentityRepositoryImpl? signer,
    String ip = '192.168.1.40',
    Uint8List? withNonce,
    String? serverFp,
  }) async {
    final me = as ?? clientId;
    final n = withNonce ?? await nonce(ip);
    final sig = await (signer ?? clientRepo).sign(
      signedMessage(ProofLabels.pairKnown, [
        _utf8(serverFp ?? serverId.fingerprint),
        n,
      ]),
    );
    return await handler(
      fakeRequest(
        'POST',
        ApiRoutes.pairKnown,
        ip: ip,
        body: KnownPairRequestDto(
          hello: ClientHelloDto(
            pairAttemptId: 'a' * 32,
            clientDeviceId: me.deviceId,
            clientName: me.displayName,
            clientPlatform: me.platform,
            clientCertPem: me.certPem,
          ),
          nonce: b64url(n),
          sig: b64url(sig),
        ).toJson(),
      ),
    );
  }

  Future<String> code(Response r) async =>
      (jsonDecode(await r.readAsString()) as Map<String, Object?>)['code']!
          as String;

  test('a remembered device gets the prompt ("remembered"); accept → token '
      'and its stored folders in the answer', () async {
    known[clientId.fingerprint] = _known(clientId.fingerprint);
    const root = SharedRoot(
      id: 'r1',
      path: '/storage/emulated/0/DCIM',
      label: 'Camera',
      readOnly: true,
    );
    stored[clientId.fingerprint] = const StoredScope(
      roots: [root],
      dropped: false,
    );
    final pending = knownPair();
    await pumpEventQueue();
    final request = gate.pending!;
    expect(request.remembered, isTrue);
    expect(request.clientFingerprint, clientId.fingerprint);
    gate.decide(request.requestId, ConnectionDecision.accepted);
    final r = await pending;
    expect(r.statusCode, 200);
    final dto = PairAcceptedDto.fromJson(
      jsonDecode(await r.readAsString()) as Map<String, Object?>,
    );
    expect(sessions.verify(dto.token)?.clientFingerprint, clientId.fingerprint);
    expect(dto.roots.single.id, 'r1');
    expect(scopes.scopeOf(clientId.fingerprint).roots.single, root);
  });

  test('declining a remembered device → declined, no session', () async {
    known[clientId.fingerprint] = _known(clientId.fingerprint);
    final pending = knownPair();
    await pumpEventQueue();
    gate.decide(gate.pending!.requestId, ConnectionDecision.declined);
    expect((await pending).statusCode, 403);
    expect(sessions.sessions, isEmpty);
  });

  test(
    '"Always allow": no prompt, token at once, AutoAccepted event',
    () async {
      known[clientId.fingerprint] = _known(
        clientId.fingerprint,
        autoAccept: true,
      );
      final r = await knownPair();
      expect(r.statusCode, 200);
      expect(gate.pending, isNull);
      expect(events.whereType<AcceptRequested>(), isEmpty);
      await pumpEventQueue();
      expect(
        events.whereType<AutoAccepted>().single.request.clientName,
        'Phone B',
      );
      expect(sessions.sessions.single.clientFingerprint, clientId.fingerprint);
    },
  );

  test('"Always allow" off still prompts', () async {
    known[clientId.fingerprint] = _known(clientId.fingerprint);
    final pending = knownPair();
    await pumpEventQueue();
    expect(events.whereType<AcceptRequested>(), hasLength(1));
    expect(sessions.sessions, isEmpty);
    gate.decide(gate.pending!.requestId, ConnectionDecision.accepted);
    expect((await pending).statusCode, 200);
  });

  test('"Always allow" still respects the busy gate', () async {
    known[clientId.fingerprint] = _known(
      clientId.fingerprint,
      autoAccept: true,
    );
    final blocker = gate.open(
      ConnectionRequest(
        requestId: 'x',
        pairAttemptId: 'y',
        remoteIp: '192.168.1.50',
        clientDeviceId: 'z',
        clientName: 'Someone',
        clientPlatform: 'android',
        clientFingerprint: 'ee' * 32,
        remembered: false,
        receivedAt: now,
        words: const [],
      ),
    )!;
    final r = await knownPair();
    expect(r.statusCode, 409);
    expect(await code(r), 'busy');
    expect(sessions.sessions, isEmpty);
    gate.decide('x', ConnectionDecision.declined);
    await blocker;
  });

  test('unknown key → 401 pairing_failed, no prompt', () async {
    final r = await knownPair(as: otherId, signer: otherRepo);
    expect(r.statusCode, 401);
    expect(await code(r), 'pairing_failed');
    expect(gate.pending, isNull);
  });

  test('a removed device → 401 even though it had "Always allow"', () async {
    known[clientId.fingerprint] = _known(
      clientId.fingerprint,
      autoAccept: true,
    );
    expect((await knownPair()).statusCode, 200);
    known.remove(clientId.fingerprint);
    final r = await knownPair();
    expect(r.statusCode, 401);
    expect(await code(r), 'pairing_failed');
    expect(sessions.sessions, hasLength(1)); // only the first
  });

  test('a known cert signed with a foreign key → 401, even with "Always '
      'allow"', () async {
    known[clientId.fingerprint] = _known(
      clientId.fingerprint,
      autoAccept: true,
    );
    final r = await knownPair(signer: otherRepo);
    expect(r.statusCode, 401);
    expect(sessions.sessions, isEmpty);
    expect(events, isEmpty);
  });

  test('a proof for another server fingerprint → 401', () async {
    known[clientId.fingerprint] = _known(
      clientId.fingerprint,
      autoAccept: true,
    );
    final r = await knownPair(serverFp: otherId.fingerprint);
    expect(r.statusCode, 401);
  });

  test('a reused nonce or a nonce from another IP → 401', () async {
    known[clientId.fingerprint] = _known(
      clientId.fingerprint,
      autoAccept: true,
    );
    final n = await nonce();
    expect((await knownPair(withNonce: n)).statusCode, 200);
    expect((await knownPair(withNonce: n)).statusCode, 401);
    final other = await nonce('192.168.1.41');
    expect((await knownPair(withNonce: other)).statusCode, 401);
  });

  test('malformed body → 401 (counted)', () async {
    final r = await handler(
      fakeRequest('POST', ApiRoutes.pairKnown, body: {'hello': 1}),
    );
    expect(r.statusCode, 401);
    expect(limiter.isLocked('192.168.1.40'), isFalse);
  });

  test('the 6th failure within a minute → 429; the QR secret and code are '
      'untouched; another IP is not affected; the window passes', () async {
    final offer = (secrets.state as SecretActive).offer;
    final codeBefore = (secrets.state as SecretActive).code;
    for (var i = 0; i < 5; i++) {
      expect((await knownPair(as: otherId, signer: otherRepo)).statusCode, 401);
    }
    final locked = await knownPair(as: otherId, signer: otherRepo);
    expect(locked.statusCode, 429);
    expect(await code(locked), 'too_many_attempts');
    // Even a valid known device from that IP waits.
    known[clientId.fingerprint] = _known(
      clientId.fingerprint,
      autoAccept: true,
    );
    expect((await knownPair()).statusCode, 429);
    final after = secrets.state as SecretActive;
    expect(after.offer.secret, offer.secret);
    expect(after.code, codeBefore);
    expect(
      (await knownPair(ip: '192.168.1.41')).statusCode,
      200,
      reason: 'another IP has its own counter',
    );
    now = now.add(const Duration(seconds: 61));
    expect((await knownPair()).statusCode, 200);
  });

  group('PairingClient.pairKnown failure mapping', () {
    PairingClient client({String? pinFingerprint, bool dead = false}) =>
        PairingClient(
          identity: clientRepo,
          pinned: (base, fp) {
            if (dead) {
              return _DeadHttp(base, RemoteUnavailableReason.timeout);
            }
            if (fp != (pinFingerprint ?? serverId.fingerprint)) {
              return _DeadHttp(base, RemoteUnavailableReason.pinMismatch);
            }
            return HandlerRemoteHttp(
              handler,
              serverFingerprint: serverId.fingerprint,
              base: base,
            );
          },
        );

    Future<void> expectFailure(
      Future<PairingSuccess> f,
      PairingFailure failure,
    ) => expectLater(
      f,
      throwsA(
        isA<PairingException>().having((e) => e.failure, 'failure', failure),
      ),
    );

    test('known + accepted → token, peer pinned', () async {
      known[clientId.fingerprint] = _known(
        clientId.fingerprint,
        autoAccept: true,
      );
      final waiting = <String>[];
      final r = await client().pairKnown(
        fingerprint: serverId.fingerprint,
        name: 'Phone A',
        candidates: const [(host: '192.168.1.23', port: 4433)],
        onWaiting: (n, _) => waiting.add(n),
      );
      expect(r.http.bearerToken, isNotNull);
      expect(r.peerFingerprint, serverId.fingerprint);
      expect(waiting, ['Phone A']);
    });

    test('removed on the other side → notAllowed', () async {
      await expectFailure(
        client().pairKnown(
          fingerprint: serverId.fingerprint,
          name: 'Phone A',
          candidates: const [(host: '192.168.1.23', port: 4433)],
        ),
        PairingFailure.notAllowed,
      );
    });

    test('another key at every address → keyChanged', () async {
      await expectFailure(
        client(pinFingerprint: 'ff' * 32).pairKnown(
          fingerprint: serverId.fingerprint,
          name: 'Phone A',
          candidates: const [
            (host: '192.168.1.23', port: 4433),
            (host: '10.0.0.2', port: 1),
          ],
        ),
        PairingFailure.keyChanged,
      );
    });

    test('nothing answers (or no address at all) → offline', () async {
      await expectFailure(
        client(dead: true).pairKnown(
          fingerprint: serverId.fingerprint,
          name: 'Phone A',
          candidates: const [(host: '192.168.1.23', port: 4433)],
        ),
        PairingFailure.offline,
      );
      await expectFailure(
        client().pairKnown(
          fingerprint: serverId.fingerprint,
          name: 'Phone A',
          candidates: const [],
        ),
        PairingFailure.offline,
      );
    });
  });
}

/// A pinned client that never reaches the server.
class _DeadHttp extends HandlerRemoteHttp {
  new(Uri base, this.reason)
    : super((_) => Response.ok(''), serverFingerprint: '', base: base);

  final RemoteUnavailableReason reason;

  @override
  Future<T> postJson<T>(
    String path,
    Object? body, {
    required T Function(Map<String, Object?> json) decode,
    Duration? timeout,
  }) async => throw RemoteUnavailableException(reason);
}
