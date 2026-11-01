import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/accept_gate.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/device_identity_repository_impl.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/pair_nonce_store.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/data/pairing_secret_store.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/data/routes/pair_routes.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
import 'package:kfm/features/connect/domain/protocol.dart';

final _loopback = [LocalAddress(InternetAddress.loopbackIPv4, 8, 'lo')];

DeviceIdentityRepositoryImpl _identity(String name) =>
    DeviceIdentityRepositoryImpl(
      store: InMemorySecretStore(),
      displayName: () async => name,
      platform: 'android',
      run: <R>(R Function() fn) async => fn(),
    );

/// N3 over real TLS on loopback: real `ShareServer`, real `PairingClient`
/// with `PinnedClient`, real gate, sessions and `authenticate`.
void main() {
  late DeviceIdentityRepositoryImpl serverRepo;
  late ShareServer server;
  late AcceptGate gate;
  late ClientSessionStore sessions;
  late PairingSecretStore secrets;
  late Uri base;
  late String fingerprint;

  setUp(() async {
    serverRepo = _identity('Phone A');
    final id = await serverRepo.loadOrCreate();
    final nonces = PairNonceStore();
    gate = AcceptGate();
    sessions = ClientSessionStore();
    secrets = PairingSecretStore(autoRefresh: false);
    server = ShareServer(
      serverRepo,
      (served) => buildSharePipeline(
        served: served,
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
      ),
      addresses: () async => _loopback,
      bindAddress: InternetAddress.loopbackIPv4,
    );
    final state = await server.start();
    base = Uri.parse('https://127.0.0.1:${state.port}');
    fingerprint = state.fingerprint!;
    secrets.start(
      addresses: [(host: '127.0.0.1', port: state.port!)],
      serverFingerprint: fingerprint,
      deviceName: 'Phone A',
    );
  });

  tearDown(() async {
    gate.cancelAll();
    sessions.clear();
    secrets.clear();
    await server.stop();
  });

  Future<int> sessionStatus(String? token) async {
    final c = PinnedClient.pinned(base, fingerprint)..bearerToken = token;
    try {
      await c.getJson(ApiRoutes.session, decode: (j) => j);
      return 200;
    } on RemoteApiException catch (e) {
      return e.status;
    } finally {
      c.close();
    }
  }

  test('accept: same words on both sides, token within 2 s, then '
      'authenticated; Disconnect → 401', () async {
    final client = PairingClient(identity: _identity('Phone B'));
    final words = <List<String>>[];
    final requested = gate.events.firstWhere((e) => e is AcceptRequested);
    final pairing = client.pairWithQr(
      (secrets.state as SecretActive).offer,
      onWaiting: (_, w) => words.add(w),
    );
    final request = (await requested).request;
    expect(words.single, request.words);
    final sw = Stopwatch()..start();
    gate.decide(request.requestId, ConnectionDecision.accepted);
    final result = await pairing;
    expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
    addTearDown(result.http.close);
    final token = result.http.bearerToken!;
    // Authenticated: /v1/session isn't built yet (N5) → 404, not 401.
    expect(await sessionStatus(token), 404);
    expect(await sessionStatus(null), 401);
    expect(await sessionStatus('${token}x'), 401);
    sessions.revoke(sessions.sessions.single.sessionId);
    expect(await sessionStatus(token), 401);
  });

  test('client Cancel over TLS closes the prompt as cancelled', () async {
    final client = PairingClient(identity: _identity('Phone B'));
    final cancel = PairingCancel();
    final requested = gate.events.firstWhere((e) => e is AcceptRequested);
    final closed = gate.events.firstWhere((e) => e is AcceptClosed);
    final pairing = client.pairWithCode(
      base: base,
      code: (secrets.state as SecretActive).code,
      cancel: cancel,
    );
    await requested;
    cancel.cancel();
    await expectLater(
      pairing,
      throwsA(
        isA<PairingException>().having(
          (e) => e.failure,
          'failure',
          PairingFailure.cancelled,
        ),
      ),
    );
    final e = await closed.timeout(const Duration(seconds: 5));
    expect((e as AcceptClosed).decision, ConnectionDecision.cancelled);
    expect(gate.pending, isNull);
  });

  test('decline over TLS → declined, no session', () async {
    final client = PairingClient(identity: _identity('Phone B'));
    final requested = gate.events.firstWhere((e) => e is AcceptRequested);
    final pairing = client.pairWithQr((secrets.state as SecretActive).offer);
    gate.decide(
      (await requested).request.requestId,
      ConnectionDecision.declined,
    );
    await expectLater(
      pairing,
      throwsA(
        isA<PairingException>().having(
          (e) => e.failure,
          'failure',
          PairingFailure.declined,
        ),
      ),
    );
    expect(sessions.sessions, isEmpty);
  });
}
