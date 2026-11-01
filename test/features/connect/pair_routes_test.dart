import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/crypto/constant_time.dart';
import 'package:kfm/features/connect/data/crypto/identity_proof.dart';
import 'package:kfm/features/connect/data/crypto/spake2.dart';
import 'package:kfm/features/connect/data/device_identity_repository_impl.dart';
import 'package:kfm/features/connect/data/pair_nonce_store.dart';
import 'package:kfm/features/connect/data/pairing_secret_store.dart';
import 'package:kfm/features/connect/data/routes/pair_routes.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/device_identity.dart';
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

final _served = [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')];

Uint8List _utf8(String s) => Uint8List.fromList(utf8.encode(s));
Uint8List _sha(List<int> b) =>
    Uint8List.fromList(crypto.sha256.convert(b).bytes);

Future<String> _code(Response r) async =>
    (jsonDecode(await r.readAsString()) as Map<String, Object?>)['code']!
        as String;

void main() {
  late DeviceIdentityRepositoryImpl serverRepo;
  late DeviceIdentityRepositoryImpl clientRepo;
  late DeviceIdentityRepositoryImpl otherRepo;
  late DeviceIdentity serverId;
  late DeviceIdentity clientId;
  late DeviceIdentity otherId;

  setUpAll(() async {
    serverRepo = _identity('Server');
    clientRepo = _identity('Client');
    otherRepo = _identity('Other');
    serverId = await serverRepo.loadOrCreate();
    clientId = await clientRepo.loadOrCreate();
    otherId = await otherRepo.loadOrCreate();
  });

  late DateTime now;
  late PairingSecretStore secrets;
  late PairNonceStore nonces;
  late List<PairCandidate> handed;
  late Handler handler;

  void build({int codeLength = kShortCodeLength}) {
    secrets =
        PairingSecretStore(
          clock: () => now,
          autoRefresh: false,
          codeLength: codeLength,
        )..start(
          addresses: const [(host: '192.168.1.23', port: 4433)],
          serverFingerprint: serverId.fingerprint,
          deviceName: 'Server',
        );
    nonces = PairNonceStore(clock: () => now);
    handed = [];
    handler = buildSharePipeline(
      served: _served,
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
        ...pairRoutes(
          secrets: secrets,
          nonces: nonces,
          // N3 stub: accept at once.
          handOff: (c) async {
            handed.add(c);
            return jsonOk(
              const PairAcceptedDto(
                token: 'token',
                serverDeviceId: 'srv',
                roots: [],
              ).toJson(),
            );
          },
        ),
      ],
    );
  }

  setUp(() {
    now = DateTime(2026, 11);
    build();
  });

  SecretActive active() => secrets.state as SecretActive;

  ClientHelloDto hello(DeviceIdentity id) => ClientHelloDto(
    pairAttemptId: 'a' * 32,
    clientDeviceId: id.deviceId,
    clientName: id.displayName,
    clientPlatform: id.platform,
    clientCertPem: id.certPem,
  );

  Future<Uint8List> nonce([String ip = '192.168.1.40']) async {
    final r = await handler(fakeRequest('POST', ApiRoutes.pairNonce, ip: ip));
    final json = jsonDecode(await r.readAsString()) as Map<String, Object?>;
    return fromB64url(PairNonceDto.fromJson(json).nonce)!;
  }

  Future<Response> qrPair({
    required Uint8List secret,
    DeviceIdentityRepositoryImpl? signer,
    DeviceIdentity? as,
    String ip = '192.168.1.40',
    Uint8List? withNonce,
  }) async {
    final n = withNonce ?? await nonce(ip);
    final sig = await (signer ?? clientRepo).sign(
      signedMessage(ProofLabels.pairQr, [
        _utf8(serverId.fingerprint),
        n,
        _sha(secret),
      ]),
    );
    return await handler(
      fakeRequest(
        'POST',
        ApiRoutes.pair,
        ip: ip,
        body: PairRequestDto(
          hello: hello(as ?? clientId),
          credential: QrCredential(
            secret: b64url(secret),
            nonce: b64url(n),
            sig: b64url(sig),
          ),
        ).toJson(),
      ),
    );
  }

  /// Client half of SPAKE2 with [code]; returns the client and the response.
  Future<(Spake2Client, Response)> codeStart(
    String code, {
    DeviceIdentity? as,
    String ip = '192.168.1.40',
    BigInt? x,
  }) async {
    final me = as ?? clientId;
    final spake = Spake2Client(
      w: spake2PasswordScalar(code),
      idA: _utf8(me.fingerprint),
      idB: _utf8(serverId.fingerprint),
      aad: _utf8(kSpake2Aad),
      x: x,
    );
    final r = await handler(
      fakeRequest(
        'POST',
        ApiRoutes.pairCodeStart,
        ip: ip,
        body: CodeStartRequestDto(
          hello: hello(me),
          pA: b64url(spake.pA),
        ).toJson(),
      ),
    );
    return (spake, r);
  }

  Future<CodeStartResponseDto> startOk(Response r) async {
    expect(r.statusCode, 200);
    return CodeStartResponseDto.fromJson(
      jsonDecode(await r.readAsString()) as Map<String, Object?>,
    );
  }

  Future<Response> codePair(
    Spake2Keys keys,
    String attemptId, {
    DeviceIdentityRepositoryImpl? signer,
    DeviceIdentity? as,
    String ip = '192.168.1.40',
  }) async {
    final sig = await (signer ?? clientRepo).sign(
      signedMessage(ProofLabels.pairCode, [
        _utf8(serverId.fingerprint),
        _sha(keys.tt),
      ]),
    );
    return await handler(
      fakeRequest(
        'POST',
        ApiRoutes.pair,
        ip: ip,
        body: PairRequestDto(
          hello: hello(as ?? clientId),
          credential: CodeCredential(
            attemptId: attemptId,
            confirmA: b64url(keys.confirmA),
            sig: b64url(sig),
          ),
        ).toJson(),
      ),
    );
  }

  group('QR path', () {
    test('right secret + nonce + signature → hand-off with the derived '
        'client fingerprint; both rotate', () async {
      final before = active();
      final r = await qrPair(secret: before.offer.secret);
      expect(r.statusCode, 200);
      expect(handed.single.clientFingerprint, clientId.fingerprint);
      expect(handed.single.method, PairMethod.qr);
      expect(handed.single.remoteIp, '192.168.1.40');
      expect(active().offer.secret, isNot(before.offer.secret));
      expect(active().code, isNot(before.code));
    });

    test('wrong secret → pairing_failed, counted', () async {
      final r = await qrPair(secret: Uint8List(32));
      expect(r.statusCode, 401);
      expect(await _code(r), 'pairing_failed');
      expect(secrets.qrFailures, 1);
      expect(handed, isEmpty);
    });

    test(
      'a second device with the same QR gets secret_used; one hand-off',
      () async {
        final secret = active().offer.secret;
        expect((await qrPair(secret: secret)).statusCode, 200);
        final r = await qrPair(secret: secret, as: otherId, signer: otherRepo);
        expect(await _code(r), 'secret_used');
        expect(handed, hasLength(1));
      },
    );

    test('an expired secret → expired', () async {
      final secret = active().offer.secret;
      now = now.add(kPairSecretLifetime);
      final r = await qrPair(secret: secret);
      expect(await _code(r), 'expired');
    });

    test(
      'nonce reused, expired or issued to another IP → pairing_failed',
      () async {
        final secret = active().offer.secret;
        final n = await nonce();
        // Used once with a wrong secret, then again with the right one.
        await qrPair(secret: Uint8List(32), withNonce: n);
        expect(
          await _code(await qrPair(secret: secret, withNonce: n)),
          'pairing_failed',
        );
        final late = await nonce();
        now = now.add(kPairNonceLifetime);
        expect(
          await _code(await qrPair(secret: secret, withNonce: late)),
          'pairing_failed',
        );
        final foreign = await nonce('192.168.1.99');
        expect(
          await _code(await qrPair(secret: secret, withNonce: foreign)),
          'pairing_failed',
        );
        expect(handed, isEmpty);
      },
    );

    test(
      'a signature by another key than the sent cert → pairing_failed',
      () async {
        final r = await qrPair(
          secret: active().offer.secret,
          signer: otherRepo,
        );
        expect(await _code(r), 'pairing_failed');
        expect(handed, isEmpty);
      },
    );

    test('5 failures → 429 and the QR rotates', () async {
      final old = active().offer.secret;
      for (var i = 0; i < 4; i++) {
        expect(
          await _code(await qrPair(secret: Uint8List(32))),
          'pairing_failed',
        );
      }
      final r = await qrPair(secret: Uint8List(32));
      expect(r.statusCode, 429);
      expect(active().offer.secret, isNot(old));
    });

    test('a malformed body → pairing_failed, not counted', () async {
      final r = await handler(
        fakeRequest('POST', ApiRoutes.pair, body: {'nope': 1}),
      );
      expect(await _code(r), 'pairing_failed');
      expect(secrets.qrFailures, 0);
    });

    test('not sharing (store wiped) → pairing_failed', () async {
      final secret = active().offer.secret;
      secrets.clear();
      expect(await _code(await qrPair(secret: secret)), 'pairing_failed');
    });
  });

  group('short-code path', () {
    test(
      'right code → confirmB verifies, pair hands off; both rotate',
      () async {
        final before = active();
        final (spake, r) = await codeStart(before.code.value);
        final start = await startOk(r);
        final keys = spake.finish(fromB64url(start.pB)!)!;
        expect(
          constantTimeEquals(keys.confirmB, fromB64url(start.confirmB)!),
          isTrue,
        );
        final p = await codePair(keys, start.attemptId);
        expect(p.statusCode, 200);
        expect(handed.single.method, PairMethod.code);
        expect(handed.single.clientFingerprint, clientId.fingerprint);
        expect(active().offer.secret, isNot(before.offer.secret));
        expect(active().code, isNot(before.code));
      },
    );

    test('wrong code → confirmB mismatch on the client', () async {
      final (spake, r) = await codeStart('00000000');
      final start = await startOk(r);
      final keys = spake.finish(fromB64url(start.pB)!)!;
      expect(
        constantTimeEquals(keys.confirmB, fromB64url(start.confirmB)!),
        isFalse,
      );
      // Even if a client sent confirmA anyway, the server refuses.
      expect(
        await _code(await codePair(keys, start.attemptId)),
        'pairing_failed',
      );
      expect(handed, isEmpty);
      expect(secrets.codeAttempts, 1);
    });

    test('one /code/start can complete at most once; a second /pair needs a '
        'new start', () async {
      final (spake, r) = await codeStart(active().code.value);
      final start = await startOk(r);
      final keys = spake.finish(fromB64url(start.pB)!)!;
      expect((await codePair(keys, start.attemptId)).statusCode, 200);
      expect(
        await _code(await codePair(keys, start.attemptId)),
        'pairing_failed',
      );
    });

    test('a failed /pair deletes the attempt (no second try)', () async {
      final (spake, r) = await codeStart(active().code.value);
      final start = await startOk(r);
      final keys = spake.finish(fromB64url(start.pB)!)!;
      // Bad signature first...
      expect(
        await _code(await codePair(keys, start.attemptId, signer: otherRepo)),
        'pairing_failed',
      );
      // ...then a correct one with the same attempt fails too.
      expect(
        await _code(await codePair(keys, start.attemptId)),
        'pairing_failed',
      );
      expect(handed, isEmpty);
    });

    test('cert swapped between start and pair → pairing_failed', () async {
      final (spake, r) = await codeStart(active().code.value);
      final start = await startOk(r);
      final keys = spake.finish(fromB64url(start.pB)!)!;
      final p = await codePair(
        keys,
        start.attemptId,
        as: otherId,
        signer: otherRepo,
      );
      expect(await _code(p), 'pairing_failed');
      expect(handed, isEmpty);
    });

    test(
      'the attempt only completes from the same IP and within 30 s',
      () async {
        final (spake, r) = await codeStart(active().code.value);
        final start = await startOk(r);
        final keys = spake.finish(fromB64url(start.pB)!)!;
        expect(
          await _code(
            await codePair(keys, start.attemptId, ip: '192.168.1.41'),
          ),
          'pairing_failed',
        );

        final (spake2, r2) = await codeStart(active().code.value);
        final start2 = await startOk(r2);
        final keys2 = spake2.finish(fromB64url(start2.pB)!)!;
        now = now.add(kSpakeAttemptLifetime);
        expect(
          await _code(await codePair(keys2, start2.attemptId)),
          'pairing_failed',
        );
      },
    );

    test('an invalid pA → pairing_failed, still counted', () async {
      final r = await handler(
        fakeRequest(
          'POST',
          ApiRoutes.pairCodeStart,
          body: CodeStartRequestDto(
            hello: hello(clientId),
            pA: b64url(Uint8List(65)),
          ).toJson(),
        ),
      );
      expect(await _code(r), 'pairing_failed');
      expect(secrets.codeAttempts, 1);
    });

    test('5 wrong codes lock it: the old code stops working, a 6th start '
        'within 30 s gets 429, after the cooldown the counter is 0', () async {
      final oldCode = active().code.value;
      for (var i = 0; i < 5; i++) {
        await startOk((await codeStart('00000000')).$2);
      }
      expect(active().code.value, isNot(oldCode));
      final sixth = (await codeStart(oldCode)).$2;
      expect(sixth.statusCode, 429);
      expect(await _code(sixth), 'too_many_attempts');
      now = now.add(kCodeLockCooldown);
      // The old code no longer pairs (its SPAKE2 confirmation fails).
      final (spake, r) = await codeStart(oldCode);
      final start = await startOk(r);
      final keys = spake.finish(fromB64url(start.pB)!)!;
      expect(
        constantTimeEquals(keys.confirmB, fromB64url(start.confirmB)!),
        isFalse,
      );
      expect(secrets.codeAttempts, 1);
    });

    test('after 3 locks typed codes are refused, the QR still pairs', () async {
      for (var lock = 0; lock < 3; lock++) {
        for (var i = 0; i < 5; i++) {
          await startOk((await codeStart('00000000')).$2);
        }
        now = now.add(kCodeLockCooldown);
      }
      final r = (await codeStart(active().code.value)).$2;
      expect(r.statusCode, 429);
      expect(active().typedCodesEnabled, isFalse);
      expect((await qrPair(secret: active().offer.secret)).statusCode, 200);
    });

    test('QR failures never touch the code counter and vice versa', () async {
      await qrPair(secret: Uint8List(32));
      await startOk((await codeStart('00000000')).$2);
      expect(secrets.qrFailures, 1);
      expect(secrets.codeAttempts, 1);
    });
  });

  group('offline guessing is impossible', () {
    // Test-only 2-character code space: 32² = 1024 codes.
    final all = [
      for (final a in kCrockfordAlphabet.split(''))
        for (final b in kCrockfordAlphabet.split('')) '$a$b',
    ];

    /// Every code whose confirmB the attacker can reproduce from its own x
    /// and the recorded {pB, confirmB}.
    Future<List<String>> attack(String guess) async {
      final x = spake2RandomScalar(Random(7));
      final (spake, r) = await codeStart(guess, as: otherId, x: x);
      final start = await startOk(r);
      final pB = fromB64url(start.pB)!;
      final confirmB = fromB64url(start.confirmB)!;
      final matches = <String>[];
      for (final c in all) {
        final w = spake2PasswordScalar(c);
        final k = spake2ClientSecret(x: x, w: w, pB: pB);
        if (k == null) continue;
        final keys = spake2DeriveKeys(
          idA: _utf8(otherId.fingerprint),
          idB: _utf8(serverId.fingerprint),
          pA: spake.pA,
          pB: pB,
          k: k,
          w: w,
          aad: _utf8(kSpake2Aad),
        );
        if (constantTimeEquals(keys.confirmB, confirmB)) matches.add(c);
      }
      return matches;
    }

    test(
      'control: with the right guess the computation finds the code',
      () async {
        build(codeLength: 2);
        final code = active().code.value;
        expect(await attack(code), [code]);
      },
    );

    test('with a wrong guess no candidate of all 1024 matches, and a second '
        'guess needs a new counted /code/start', () async {
      build(codeLength: 2);
      final code = active().code.value;
      final wrong = all.firstWhere((c) => c != code);
      expect(await attack(wrong), isEmpty);
      expect(secrets.codeAttempts, 1);
      await attack(all.lastWhere((c) => c != code && c != wrong));
      expect(secrets.codeAttempts, 2);
    });
  });
}
