import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/accept_gate.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/device_identity_repository_impl.dart';
import 'package:kfm/features/connect/data/known_pair_limiter.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/pair_nonce_store.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/data/routes/pair_routes.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/protocol.dart';

final _loopback = [LocalAddress(InternetAddress.loopbackIPv4, 8, 'lo')];

DeviceIdentityRepositoryImpl _identity(String name) =>
    DeviceIdentityRepositoryImpl(
      store: InMemorySecretStore(),
      displayName: () async => name,
      platform: 'android',
      run: <R>(R Function() fn) async => fn(),
    );

/// N6 over real TLS on loopback: real `ShareServer`, `PinnedClient`,
/// gate and sessions.
void main() {
  late DeviceIdentityRepositoryImpl serverRepo;
  late DeviceIdentityRepositoryImpl clientRepo;
  late ShareServer server;
  late AcceptGate gate;
  late ClientSessionStore sessions;
  late Set<String> known;
  late int port;
  late String serverFp;

  Future<void> start() async {
    final state = await server.start();
    port = state.port!;
    serverFp = state.fingerprint!;
  }

  setUp(() async {
    serverRepo = _identity('Phone A');
    clientRepo = _identity('Phone B');
    final nonces = PairNonceStore();
    gate = AcceptGate();
    sessions = ClientSessionStore();
    known = {};
    server = ShareServer(
      serverRepo,
      (served) => buildSharePipeline(
        served: served,
        authenticate: authenticate(sessions),
        routes: [
          ...coreRoutes(
            info: () async {
              final id = await serverRepo.loadOrCreate();
              return ServerInfoDto(
                deviceId: id.deviceId,
                name: id.displayName,
                platform: id.platform,
                fingerprint: id.fingerprint,
                protocolVersion: kProtocolVersion,
              );
            },
            nonces: nonces,
          ),
          knownPairRoute(
            nonces: nonces,
            limiter: KnownPairLimiter(),
            serverFingerprint: () async =>
                (await serverRepo.loadOrCreate()).fingerprint,
            lookup: (fp) async => known.contains(fp)
                ? KnownDevice(
                    id: 'x',
                    peerDeviceId: 'b',
                    name: 'Phone B',
                    platform: 'android',
                    fingerprint: fp,
                    lastSeenAt: DateTime(2026),
                    lastAddresses: const [],
                    allowedRoots: const [],
                    canShareToUs: false,
                    isTemporary: false,
                    autoAccept: false,
                  )
                : null,
            handOff: promptHandOff(
              gate: gate,
              sessions: sessions,
              serverDeviceId: () async =>
                  (await serverRepo.loadOrCreate()).deviceId,
            ),
          ),
        ],
      ),
      addresses: () async => _loopback,
      bindAddress: InternetAddress.loopbackIPv4,
    );
    await start();
  });

  tearDown(() async {
    gate.cancelAll();
    sessions.clear();
    await server.stop();
  });

  test('a remembered device reconnects with no QR: prompt → accept → '
      'token', () async {
    known.add((await clientRepo.loadOrCreate()).fingerprint);
    final client = PairingClient(identity: clientRepo);
    final requested = gate.events.firstWhere((e) => e is AcceptRequested);
    final pairing = client.pairKnown(
      fingerprint: serverFp,
      name: 'Phone A',
      candidates: [(host: '127.0.0.1', port: port)],
    );
    final request = (await requested).request;
    expect(request.remembered, isTrue);
    gate.decide(request.requestId, ConnectionDecision.accepted);
    final result = await pairing;
    addTearDown(result.http.close);
    expect(result.http.bearerToken, isNotNull);
    expect(sessions.sessions.single.clientName, 'Phone B');
  });

  test('not remembered on the other side → notAllowed', () async {
    final client = PairingClient(identity: clientRepo);
    await expectLater(
      client.pairKnown(
        fingerprint: serverFp,
        name: 'Phone A',
        candidates: [(host: '127.0.0.1', port: port)],
      ),
      throwsA(
        isA<PairingException>().having(
          (e) => e.failure,
          'f',
          PairingFailure.notAllowed,
        ),
      ),
    );
  });

  test('after the other device resets its identity → keyChanged', () async {
    known.add((await clientRepo.loadOrCreate()).fingerprint);
    final oldFp = serverFp;
    await server.stop();
    await serverRepo.reset();
    await start();
    expect(serverFp, isNot(oldFp));
    final client = PairingClient(identity: clientRepo);
    await expectLater(
      client.pairKnown(
        fingerprint: oldFp,
        name: 'Phone A',
        candidates: [(host: '127.0.0.1', port: port)],
      ),
      throwsA(
        isA<PairingException>().having(
          (e) => e.failure,
          'f',
          PairingFailure.keyChanged,
        ),
      ),
    );
    expect(gate.pending, isNull);
  });

  test('nothing listening → offline', () async {
    await server.stop();
    final client = PairingClient(identity: clientRepo);
    await expectLater(
      client.pairKnown(
        fingerprint: serverFp,
        name: 'Phone A',
        candidates: [(host: '127.0.0.1', port: port)],
      ),
      throwsA(
        isA<PairingException>().having(
          (e) => e.failure,
          'f',
          PairingFailure.offline,
        ),
      ),
    );
  });
}
