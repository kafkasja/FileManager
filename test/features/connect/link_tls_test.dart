import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/crypto/identity_proof.dart';
import 'package:kfm/features/connect/data/device_identity_repository_impl.dart';
import 'package:kfm/features/connect/data/known_pair_limiter.dart';
import 'package:kfm/features/connect/data/link_invite_store.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/pair_nonce_store.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/data/routes/link_routes.dart';
import 'package:kfm/features/connect/data/routes/session_routes.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/link.dart';
import 'package:kfm/features/connect/domain/protocol.dart';

final _loopback = [LocalAddress(InternetAddress.loopbackIPv4, 8, 'lo')];

DeviceIdentityRepositoryImpl _identity(String name) =>
    DeviceIdentityRepositoryImpl(
      store: InMemorySecretStore(),
      displayName: () async => name,
      platform: 'android',
      run: <R>(R Function() fn) async => fn(),
    );

/// One device of the link test: its identity, server, sessions, invites.
class _Device {
  new(this.name) : repo = _identity(name);

  final String name;
  final DeviceIdentityRepositoryImpl repo;
  final sessions = ClientSessionStore();
  final nonces = PairNonceStore();
  final invites = LinkInviteStore();
  final limiter = KnownPairLimiter();
  late ShareServer server;
  late int port;
  late String fp;

  /// What `/v1/link` does here (B's side); set per test.
  late LinkRequestHandler onLink;
  final joined = <String>[];
  final closed = <String>[];

  Future<void> start() async {
    server = ShareServer(
      repo,
      (served) => buildSharePipeline(
        served: served,
        authenticate: authenticate(sessions),
        routes: [
          ...coreRoutes(
            info: () async {
              final id = await repo.loadOrCreate();
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
          ...sessionRoutes(sessions),
          ...linkRoutes(
            invites: invites,
            nonces: nonces,
            limiter: limiter,
            serverFingerprint: () async =>
                (await repo.loadOrCreate()).fingerprint,
            onLink: (s, dto, ip) => onLink(s, dto, ip),
            onJoin: (hello, invite, ip) async {
              joined.add(invite.peerFingerprint);
              final issued = sessions.issue(
                clientFingerprint: invite.peerFingerprint,
                clientDeviceId: hello.clientDeviceId,
                clientName: hello.clientName,
              );
              return PairAcceptedDto(
                token: issued.token,
                serverDeviceId: 'id-$name',
                roots: const [],
              );
            },
            onClose: (s) async => closed.add(s.clientFingerprint),
          ),
        ],
      ),
      addresses: () async => _loopback,
      bindAddress: InternetAddress.loopbackIPv4,
    );
    final state = await server.start();
    port = state.port!;
    fp = state.fingerprint!;
  }

  Future<void> stop() async {
    sessions.clear();
    await server.stop();
  }
}

/// TASK-E1d1 over real TLS on loopback: A (scanned) asks B to connect
/// back; B joins A's server with the single-use invite and an identity
/// proof, pinned to A's key from the pairing.
void main() {
  late _Device a;
  late _Device b;

  setUp(() async {
    a = _Device('PC A');
    b = _Device('Phone B');
    await a.start();
    await b.start();
  });

  tearDown(() async {
    await a.stop();
    await b.stop();
  });

  /// A's pinned, authenticated client to B (as after a pairing).
  Future<RemoteHttp> aToB() async {
    final issued = b.sessions.issue(
      clientFingerprint: a.fp,
      clientDeviceId: 'a',
      clientName: a.name,
    );
    final http = PinnedClient.pinned(
      Uri(scheme: 'https', host: '127.0.0.1', port: b.port),
      b.fp,
    )..bearerToken = issued.token;
    addTearDown(http.close);
    return http;
  }

  test('one device key: the server cert and the client identity have the '
      'same fingerprint (B pins what A proved in the pairing)', () async {
    expect(a.fp, (await a.repo.loadOrCreate()).fingerprint);
    expect(b.fp, (await b.repo.loadOrCreate()).fingerprint);
  });

  test('back-link: B joins A with the invite; both have a session', () async {
    final joins = <PairingSuccess>[];
    b.onLink = (session, dto, ip) async {
      expect(session.clientFingerprint, a.fp);
      final result = await PairingClient(identity: b.repo).joinLink(
        host: ip,
        port: dto.port,
        fingerprint: session.clientFingerprint,
        name: session.clientName,
        invite: fromB64url(dto.invite)!,
      );
      joins.add(result);
      return const LinkResponseDto(reverse: true, perms: LinkPerms());
    };
    final invite = a.invites.issue(
      peerFingerprint: b.fp,
      remoteIp: '127.0.0.1',
    );
    final http = await aToB();
    final res = await http.postJson(
      ApiRoutes.link,
      LinkRequestDto(
        port: a.port,
        invite: b64url(invite),
        perms: const LinkPerms(see: false),
      ).toJson(),
      decode: LinkResponseDto.fromJson,
    );
    expect(res.reverse, isTrue);
    expect(a.joined, [b.fp]);
    expect(a.sessions.sessions.single.clientFingerprint, b.fp);
    final back = joins.single;
    addTearDown(back.http.close);
    expect(back.peerFingerprint, a.fp);
    // B's client works on A's server.
    await back.http.getJson<Object?>(ApiRoutes.session, decode: (j) => j);
    // The invite was single use.
    expect(a.invites.openCount, 0);
  });

  Future<int> joinWith({
    required DeviceIdentityRepositoryImpl who,
    required Uint8List invite,
  }) async {
    try {
      await PairingClient(identity: who).joinLink(
        host: '127.0.0.1',
        port: a.port,
        fingerprint: a.fp,
        name: a.name,
        invite: invite,
      );
      return 200;
    } on PairingException catch (e) {
      final cause = e.cause;
      return cause is RemoteApiException ? cause.status : -1;
    }
  }

  test('wrong, reused, other key, other IP and expired invites → 401; then '
      'the limiter locks the IP (429)', () async {
    // Wrong invite.
    a.invites.issue(peerFingerprint: b.fp, remoteIp: '127.0.0.1');
    expect(
      await joinWith(who: b.repo, invite: Uint8List(kLinkInviteBytes)),
      401,
    );
    // Another device's key with B's invite.
    final c = _identity('Laptop C');
    final forB = a.invites.issue(peerFingerprint: b.fp, remoteIp: '127.0.0.1');
    expect(await joinWith(who: c, invite: forB), 401);
    // …and that invite is gone now (single use), even for B.
    expect(await joinWith(who: b.repo, invite: forB), 401);
    // Issued for another IP.
    final elsewhere = a.invites.issue(
      peerFingerprint: b.fp,
      remoteIp: '10.0.0.9',
    );
    expect(await joinWith(who: b.repo, invite: elsewhere), 401);
    expect(
      await joinWith(who: b.repo, invite: Uint8List(kLinkInviteBytes)),
      401,
    );
    // Five failures within the window: locked.
    final ok = a.invites.issue(peerFingerprint: b.fp, remoteIp: '127.0.0.1');
    expect(await joinWith(who: b.repo, invite: ok), 429);
    expect(a.sessions.sessions, isEmpty);
  });

  test('an expired invite is refused', () {
    var now = DateTime(2026, 11, 5);
    final store = LinkInviteStore(clock: () => now);
    final invite = store.issue(peerFingerprint: 'b', remoteIp: '1.2.3.4');
    now = now.add(kLinkInviteLifetime);
    expect(
      store.consume(invite, provenFingerprint: 'b', remoteIp: '1.2.3.4'),
      isNull,
    );
    final fresh = store.issue(peerFingerprint: 'b', remoteIp: '1.2.3.4');
    expect(
      store.consume(fresh, provenFingerprint: 'b', remoteIp: '1.2.3.4'),
      isNotNull,
    );
    expect(
      store.consume(fresh, provenFingerprint: 'b', remoteIp: '1.2.3.4'),
      isNull,
    );
  });

  test('/v1/link needs a session; a send-only session gets 403; '
      '/v1/link/close reaches the handler', () async {
    final noToken = PinnedClient.pinned(
      Uri(scheme: 'https', host: '127.0.0.1', port: b.port),
      b.fp,
    );
    addTearDown(noToken.close);
    await expectLater(
      noToken.postJson<void>(ApiRoutes.link, const {
        'port': 1,
        'invite': 'x',
      }, decode: (_) {}),
      throwsA(
        isA<RemoteApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCode.unauthorized,
        ),
      ),
    );
    final send = b.sessions.issue(
      clientFingerprint: 'cc' * 32,
      clientDeviceId: 'c',
      clientName: 'C',
      purpose: SessionPurpose.send,
    );
    final sendOnly = PinnedClient.pinned(
      Uri(scheme: 'https', host: '127.0.0.1', port: b.port),
      b.fp,
    )..bearerToken = send.token;
    addTearDown(sendOnly.close);
    await expectLater(
      sendOnly.postJson<void>(ApiRoutes.link, {
        'port': 1,
        'invite': b64url(Uint8List(32)),
      }, decode: (_) {}),
      throwsA(
        isA<RemoteApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCode.forbidden,
        ),
      ),
    );
    final http = await aToB();
    await http.postJson<void>(
      ApiRoutes.linkClose,
      const <String, Object?>{},
      decode: (_) {},
    );
    expect(b.closed, [a.fp]);
  });
}
