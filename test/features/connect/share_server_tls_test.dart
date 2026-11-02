import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/device_identity_repository_impl.dart';
import 'package:kfm/features/connect/data/pair_nonce_store.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:shelf/shelf.dart';

final _loopback = [LocalAddress(InternetAddress.loopbackIPv4, 8, 'lo')];

DeviceIdentityRepositoryImpl _identity() => DeviceIdentityRepositoryImpl(
  store: InMemorySecretStore(),
  displayName: () async => 'Test phone',
  platform: 'android',
  run: <R>(R Function() fn) async => fn(),
);

void main() {
  late DeviceIdentityRepositoryImpl identity;
  late ShareServer server;
  late Uri base;
  late String fingerprint;
  var handled = 0;

  setUp(() async {
    handled = 0;
    identity = _identity();
    final nonces = PairNonceStore();
    server = ShareServer(
      identity,
      (served) {
        final inner = buildSharePipeline(
          served: served,
          routes: coreRoutes(
            info: () async {
              final id = await identity.loadOrCreate();
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
        );
        return (Request r) {
          handled++;
          return inner(r);
        };
      },
      addresses: () async => _loopback,
      bindAddress: InternetAddress.loopbackIPv4,
    );
    final state = await server.start();
    expect(state.status, ShareServerStatus.running);
    base = Uri.parse('https://127.0.0.1:${state.port}');
    fingerprint = state.fingerprint!;
  });

  tearDown(() => server.stop());

  test('pinned to the right fingerprint: GET /v1/info over TLS', () async {
    final client = PinnedClient.pinned(base, fingerprint);
    addTearDown(client.close);
    final info = await client.getJson(
      ApiRoutes.info,
      decode: ServerInfoDto.fromJson,
    );
    expect(info.fingerprint, fingerprint);
    expect(info.name, 'Test phone');
    expect(info.protocolVersion, 1);
    expect(client.seenFingerprint, fingerprint);
  });

  test('POST /v1/pair/nonce and 401 for a protected route', () async {
    final client = PinnedClient.pinned(base, fingerprint);
    addTearDown(client.close);
    final nonce = await client.postJson(
      ApiRoutes.pairNonce,
      null,
      decode: PairNonceDto.fromJson,
    );
    expect(nonce.expiresInSeconds, 60);
    await expectLater(
      client.getJson(ApiRoutes.files, decode: (j) => j),
      throwsA(
        isA<RemoteApiException>()
            .having((e) => e.status, 'status', 401)
            .having((e) => e.code, 'code', ApiErrorCode.unauthorized),
      ),
    );
  });

  test('pinned to another fingerprint: handshake fails, nothing reaches '
      'the handler', () async {
    final client = PinnedClient.pinned(base, 'a' * 64);
    addTearDown(client.close);
    await expectLater(
      client.getJson(ApiRoutes.info, decode: ServerInfoDto.fromJson),
      throwsA(
        isA<RemoteUnavailableException>().having(
          (e) => e.reason,
          'reason',
          RemoteUnavailableReason.pinMismatch,
        ),
      ),
    );
    expect(handled, 0);
  });

  test('first contact: only allowed routes, before any byte', () async {
    final client = PinnedClient.firstContact(base);
    addTearDown(client.close);
    await expectLater(
      client.postJson(ApiRoutes.pairNonce, null, decode: (j) => j),
      throwsStateError,
    );
    await expectLater(
      client.getJson(ApiRoutes.files, decode: (j) => j),
      throwsStateError,
    );
    expect(handled, 0);
    final info = await client.getJson(
      ApiRoutes.info,
      decode: ServerInfoDto.fromJson,
    );
    expect(client.seenFingerprint, info.fingerprint);
  });

  test(
    'first contact: a later connection with another cert is rejected',
    () async {
      final client = PinnedClient.firstContact(base);
      addTearDown(client.close);
      await client.getJson(ApiRoutes.info, decode: ServerInfoDto.fromJson);
      final port = base.port;
      await server.stop();

      // Another device takes over the same address and port.
      final other = generateIdentityMaterial();
      final ctx = SecurityContext()
        ..useCertificateChainBytes(utf8.encode(other.certPem))
        ..usePrivateKeyBytes(utf8.encode(other.privateKeyPem));
      final impostor = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        port,
        ctx,
      );
      addTearDown(() => impostor.close(force: true));
      var reached = 0;
      impostor.listen((r) async {
        reached++;
        await r.response.close();
      });
      // The first call may hit the dead keep-alive connection (network error).
      try {
        await client.getJson(ApiRoutes.info, decode: ServerInfoDto.fromJson);
      } on RemoteUnavailableException {
        // expected either way
      }

      await expectLater(
        client.getJson(ApiRoutes.info, decode: ServerInfoDto.fromJson),
        throwsA(
          isA<RemoteUnavailableException>().having(
            (e) => e.reason,
            'reason',
            RemoteUnavailableReason.pinMismatch,
          ),
        ),
      );
      expect(reached, 0);
      expect(client.seenFingerprint, fingerprint);
    },
  );

  test('promote keeps the base and pins the seen fingerprint', () async {
    final first = PinnedClient.firstContact(base);
    expect(first.promote, throwsStateError);
    await first.getJson(ApiRoutes.info, decode: ServerInfoDto.fromJson);
    final pinned = first.promote();
    addTearDown(pinned.close);
    expect(pinned.base, base);
    expect(pinned.isFirstContact, isFalse);
    // Promoted: any route may now be called (this one answers 401).
    await expectLater(
      pinned.getJson(ApiRoutes.files, decode: (j) => j),
      throwsA(isA<RemoteApiException>()),
    );
    // The old client is closed.
    await expectLater(
      first.getJson(ApiRoutes.info, decode: (j) => j),
      throwsStateError,
    );
  });

  test('stop closes the port at once', () async {
    final port = base.port;
    await server.stop();
    final client = PinnedClient.pinned(base, fingerprint);
    addTearDown(client.close);
    final watch = Stopwatch()..start();
    await expectLater(
      client.getJson(ApiRoutes.info, decode: (j) => j),
      throwsA(isA<RemoteUnavailableException>()),
    );
    // Android refuses at once; Windows retries a refused loopback SYN for
    // about 2 s, hence the margin.
    expect(watch.elapsed, lessThan(const Duration(seconds: 4)));
    expect(port, greaterThan(0));
  });

  test('a plain-HTTP request fails (TLS only)', () async {
    final plain = HttpClient();
    addTearDown(() => plain.close(force: true));
    final uri = base.replace(scheme: 'http');
    await expectLater(
      () async => await (await plain.getUrl(uri)).close(),
      throwsA(anything),
    );
    expect(handled, 0);
  });

  test('restart keeps the fingerprint; no addresses → error state', () async {
    await server.stop();
    final again = await server.start();
    expect(again.fingerprint, fingerprint);
    await server.stop();

    final offline = ShareServer(
      identity,
      (_) =>
          (_) => Response.ok(''),
      addresses: () async => const [],
      bindAddress: InternetAddress.loopbackIPv4,
    );
    final state = await offline.start();
    expect(state.status, ShareServerStatus.error);
    expect(state.error, isA<NoLocalNetworkException>());
    expect(offline.isRunning, isFalse);
  });

  test('N6 follow-up: a restart reuses the saved port; a taken port falls '
      'back to a new one, which is saved', () async {
    await server.stop();
    int? saved;
    ShareServer withPort() => ShareServer(
      identity,
      (_) =>
          (_) => Response.ok(''),
      addresses: () async => _loopback,
      bindAddress: InternetAddress.loopbackIPv4,
      preferredPort: () async => saved,
      savePort: (p) async => saved = p,
    );
    final first = withPort();
    final a = await first.start();
    expect(saved, a.port);
    await first.stop();

    final second = withPort();
    final b = await second.start();
    expect(b.port, a.port);

    // The port is busy now (second still runs): a third server moves on.
    final third = withPort();
    final c = await third.start();
    expect(c.port, isNot(a.port));
    expect(saved, c.port);
    await third.stop();
    await second.stop();
  });
}
