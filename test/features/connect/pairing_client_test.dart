import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/crypto/identity_proof.dart';
import 'package:kfm/features/connect/data/device_identity_repository_impl.dart';
import 'package:kfm/features/connect/data/pair_nonce_store.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/data/pairing_secret_store.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/data/routes/pair_routes.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/device_identity.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:shelf/shelf.dart';

import 'fake_remote_http.dart';
import 'handler_remote_http.dart';

DeviceIdentityRepositoryImpl _identity(String name) =>
    DeviceIdentityRepositoryImpl(
      store: InMemorySecretStore(),
      displayName: () async => name,
      platform: 'android',
      run: <R>(R Function() fn) async => fn(),
    );

/// One sharing device: its routes with an N3 stub ([decide]).
class _Device {
  new(this.repo, this.id, {List<LocalAddress>? served})
    : secrets = PairingSecretStore(autoRefresh: false),
      nonces = PairNonceStore() {
    secrets.start(
      addresses: const [(host: '192.168.1.23', port: 4433)],
      serverFingerprint: id.fingerprint,
      deviceName: id.displayName,
    );
    handler = buildSharePipeline(
      served:
          served ??
          [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
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
          handOff: (c) {
            handed.add(c);
            return decide(c);
          },
        ),
      ],
    );
  }

  final DeviceIdentityRepositoryImpl repo;
  final DeviceIdentity id;
  final PairingSecretStore secrets;
  final PairNonceStore nonces;
  late final Handler handler;
  final List<PairCandidate> handed = [];
  Future<Response> Function(PairCandidate c) decide = (_) async => jsonOk(
    const PairAcceptedDto(
      token: 'tok',
      serverDeviceId: 'srv',
      roots: [],
    ).toJson(),
  );

  SecretActive get active => secrets.state as SecretActive;
}

void main() {
  late DeviceIdentityRepositoryImpl clientRepo;
  late DeviceIdentityRepositoryImpl serverRepo;
  late DeviceIdentityRepositoryImpl rogueRepo;
  late DeviceIdentity serverId;
  late DeviceIdentity rogueId;

  setUpAll(() async {
    clientRepo = _identity('Client');
    serverRepo = _identity('Phone A');
    rogueRepo = _identity('Phone A');
    await clientRepo.loadOrCreate();
    serverId = await serverRepo.loadOrCreate();
    rogueId = await rogueRepo.loadOrCreate();
  });

  group('in-process (real routes, no TLS)', () {
    late _Device a;
    late List<HandlerRemoteHttp> made;

    setUp(() {
      a = _Device(serverRepo, serverId);
      made = [];
    });

    PairingClient client(_Device d) => PairingClient(
      identity: clientRepo,
      pinned: (base, fp) {
        final h = HandlerRemoteHttp(
          d.handler,
          serverFingerprint: d.id.fingerprint,
          base: base,
        );
        made.add(h);
        return h;
      },
      firstContact: (base) {
        final h = HandlerRemoteHttp(
          d.handler,
          serverFingerprint: d.id.fingerprint,
          base: base,
        );
        made.add(h);
        return h;
      },
    );

    test('QR: pairs, sets the token, reports the waiting state', () async {
      final waiting = <String>[];
      final result = await client(a)
          .pairWithQr(a.active.offer, onWaiting: (n, w) => waiting.add(n));
      expect(waiting, ['Phone A']);
      expect(result.accepted.token, 'tok');
      expect(result.http.bearerToken, 'tok');
      expect(result.peerFingerprint, serverId.fingerprint);
      expect(a.handed.single.method, PairMethod.qr);
    });

    test('QR used twice: the second device gets secretUsed', () async {
      final offer = a.active.offer;
      await client(a).pairWithQr(offer);
      await expectLater(
        client(a).pairWithQr(offer),
        throwsA(
          isA<PairingException>().having(
            (e) => e.failure,
            'failure',
            PairingFailure.secretUsed,
          ),
        ),
      );
      expect(a.handed, hasLength(1));
    });

    test('code: SPAKE2 run reaches the waiting state and pairs', () async {
      final waiting = <String>[];
      final result = await client(a).pairWithCode(
        base: Uri.parse('https://192.168.1.23:4433'),
        code: a.active.code,
        expectedFingerprint: serverId.fingerprint,
        onWaiting: (n, w) => waiting.add(n),
      );
      expect(waiting, ['Phone A']);
      expect(result.peerFingerprint, serverId.fingerprint);
      expect(made.single.promoted, isTrue);
      expect(made.single.sent, [
        'GET /v1/info',
        'POST /v1/pair/code/start',
        'POST /v1/pair',
      ]);
      expect(a.handed.single.method, PairMethod.code);
    });

    test(
      'wrong code: aborts after confirmB, sends no confirmA/signature',
      () async {
        await expectLater(
          client(a).pairWithCode(
            base: Uri.parse('https://192.168.1.23:4433'),
            code: const ShortCode('00000000'),
          ),
          throwsA(
            isA<PairingException>().having(
              (e) => e.failure,
              'failure',
              PairingFailure.wrongCode,
            ),
          ),
        );
        expect(made.single.sent, ['GET /v1/info', 'POST /v1/pair/code/start']);
        expect(made.single.promoted, isFalse);
        expect(made.single.closed, isTrue);
      },
    );

    test("a rogue server advertising A's name can't produce confirmB: B "
        'aborts with nothing sent after /code/start', () async {
      final rogue = _Device(rogueRepo, rogueId);
      // The user types A's code; the rogue doesn't know it.
      await expectLater(
        client(rogue).pairWithCode(
          base: Uri.parse('https://192.168.1.23:4433'),
          code: a.active.code,
        ),
        throwsA(
          isA<PairingException>().having(
            (e) => e.failure,
            'failure',
            PairingFailure.wrongCode,
          ),
        ),
      );
      expect(made.single.sent, ['GET /v1/info', 'POST /v1/pair/code/start']);
      expect(rogue.handed, isEmpty);
    });

    test(
      'mDNS fp hint differs from the cert → wrongDevice before /code/start',
      () async {
        final rogue = _Device(rogueRepo, rogueId);
        await expectLater(
          client(rogue).pairWithCode(
            base: Uri.parse('https://192.168.1.23:4433'),
            code: a.active.code,
            expectedFingerprint: serverId.fingerprint,
          ),
          throwsA(
            isA<PairingException>().having(
              (e) => e.failure,
              'failure',
              PairingFailure.wrongDevice,
            ),
          ),
        );
        expect(made.single.sent, ['GET /v1/info']);
      },
    );

    test('decline / time-out / busy map to their failures', () async {
      for (final (code, failure) in [
        (ApiErrorCode.declined, PairingFailure.declined),
        (ApiErrorCode.timedOut, PairingFailure.timedOut),
        (ApiErrorCode.busy, PairingFailure.busy),
      ]) {
        a.decide = (_) async => apiError(code);
        await expectLater(
          client(a).pairWithQr(a.active.offer),
          throwsA(
            isA<PairingException>().having((e) => e.failure, 'f', failure),
          ),
        );
      }
    });

    test('too many typed codes → tooManyAttempts', () async {
      for (var i = 0; i < 5; i++) {
        a.secrets.beginCodeAttempt('192.168.1.40');
      }
      await expectLater(
        client(a).pairWithCode(
          base: Uri.parse('https://192.168.1.23:4433'),
          code: a.active.code,
        ),
        throwsA(
          isA<PairingException>().having(
            (e) => e.failure,
            'f',
            PairingFailure.tooManyAttempts,
          ),
        ),
      );
    });
  });

  group('address probing (FakeRemoteHttp)', () {
    final offer = PairingOffer(
      addresses: const [
        (host: '10.0.0.1', port: 1),
        (host: '10.0.0.2', port: 2),
        (host: '10.0.0.3', port: 3),
      ],
      serverFingerprint: 'ab' * 32,
      secret: fromB64url('A' * 43)!,
      deviceName: 'Phone A',
    );

    PairingClient probing(Map<String, FakeRemoteHttp> byHost) => PairingClient(
      identity: clientRepo,
      pinned: (base, fp) => byHost[base.host]!,
    );

    FakeRemoteHttp answering() => FakeRemoteHttp()
      ..on(
        'POST',
        ApiRoutes.pairNonce,
        (_) => {'nonce': b64url(List.filled(32, 1)), 'expiresInSeconds': 60},
      )
      ..on(
        'POST',
        ApiRoutes.pair,
        (_) => const PairAcceptedDto(
          token: 't',
          serverDeviceId: 's',
          roots: [],
        ).toJson(),
      );

    test('tries addresses in order, uses the first that answers, closes '
        'the others', () async {
      final dead = FakeRemoteHttp()
        ..failAll = const RemoteUnavailableException(
          RemoteUnavailableReason.timeout,
        );
      final good = answering();
      final unused = answering();
      final r = await probing({
        '10.0.0.1': dead,
        '10.0.0.2': good,
        '10.0.0.3': unused,
      }).pairWithQr(offer);
      expect(r.http, same(good));
      expect(dead.closed, isTrue);
      expect(unused.calls, isEmpty);
      expect(good.calls.map((c) => c.path), [
        ApiRoutes.pairNonce,
        ApiRoutes.pair,
      ]);
    });

    test('no address answers → unreachable (AP isolation message)', () async {
      FakeRemoteHttp dead() => FakeRemoteHttp()
        ..failAll = const RemoteUnavailableException(
          RemoteUnavailableReason.timeout,
        );
      await expectLater(
        probing({'10.0.0.1': dead(), '10.0.0.2': dead(), '10.0.0.3': dead()})
            .pairWithQr(offer),
        throwsA(
          isA<PairingException>().having(
            (e) => e.failure,
            'f',
            PairingFailure.unreachable,
          ),
        ),
      );
    });

    test('a pin mismatch and no other answer → wrongDevice', () async {
      FakeRemoteHttp pin() => FakeRemoteHttp()
        ..failAll = const RemoteUnavailableException(
          RemoteUnavailableReason.pinMismatch,
        );
      await expectLater(
        probing({'10.0.0.1': pin(), '10.0.0.2': pin(), '10.0.0.3': pin()})
            .pairWithQr(offer),
        throwsA(
          isA<PairingException>().having(
            (e) => e.failure,
            'f',
            PairingFailure.wrongDevice,
          ),
        ),
      );
    });

    test('cancel while waiting → cancelled, client closed', () async {
      final good = answering();
      final cancel = PairingCancel();
      good.on('POST', ApiRoutes.pair, (_) async {
        cancel.cancel();
        throw const RemoteUnavailableException(RemoteUnavailableReason.network);
      });
      await expectLater(
        probing({'10.0.0.1': good}).pairWithQr(offer, cancel: cancel),
        throwsA(
          isA<PairingException>().having(
            (e) => e.failure,
            'f',
            PairingFailure.cancelled,
          ),
        ),
      );
      expect(good.closed, isTrue);
    });
  });

  group('over TLS on loopback (PinnedClient)', () {
    late _Device a;
    late ShareServer server;
    late int port;
    var requests = 0;

    setUp(() async {
      requests = 0;
      a = _Device(
        serverRepo,
        serverId,
        served: [LocalAddress(InternetAddress.loopbackIPv4, 8, 'lo')],
      );
      server = ShareServer(
        serverRepo,
        (_) => (r) {
          requests++;
          return a.handler(r);
        },
        addresses: () async => [
          LocalAddress(InternetAddress.loopbackIPv4, 8, 'lo'),
        ],
        bindAddress: InternetAddress.loopbackIPv4,
      );
      port = (await server.start()).port!;
    });

    tearDown(() => server.stop());

    PairingOffer offer({String? fp}) => PairingOffer(
      addresses: [(host: '127.0.0.1', port: port)],
      serverFingerprint: fp ?? serverId.fingerprint,
      secret: a.active.offer.secret,
      deviceName: 'Phone A',
    );

    test('QR pairing pins the QR fingerprint and pairs', () async {
      final r = await PairingClient(identity: clientRepo).pairWithQr(offer());
      addTearDown(r.http.close);
      expect(r.accepted.token, 'tok');
      expect(a.handed.single.clientFingerprint, isNot(serverId.fingerprint));
    });

    test('a QR edited to another f is refused at the TLS pin; the server '
        'handles no request', () async {
      await expectLater(
        PairingClient(identity: clientRepo).pairWithQr(offer(fp: 'cd' * 32)),
        throwsA(
          isA<PairingException>().having(
            (e) => e.failure,
            'f',
            PairingFailure.wrongDevice,
          ),
        ),
      );
      expect(requests, 0);
      expect(a.handed, isEmpty);
    });

    test('typed code: first contact, SPAKE2, promote, pair', () async {
      final r = await PairingClient(identity: clientRepo).pairWithCode(
        base: Uri.parse('https://127.0.0.1:$port'),
        code: a.active.code,
      );
      addTearDown(r.http.close);
      expect(r.peerFingerprint, serverId.fingerprint);
      expect(r.http, isA<PinnedClient>());
      expect((r.http as PinnedClient).isFirstContact, isFalse);
      expect(requests, 3);
    });
  });
}
