import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/crypto/identity_proof.dart';
import 'package:kfm/features/connect/data/pair_nonce_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:shelf/shelf.dart';

class _Conn implements HttpConnectionInfo {
  new(String ip) : remoteAddress = InternetAddress(ip);

  @override
  final InternetAddress remoteAddress;

  @override
  int get localPort => 4433;

  @override
  int get remotePort => 50000;
}

final _served = [
  LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0'),
  LocalAddress(InternetAddress('192.168.43.1'), 24, 'ap0'),
];

Request _req(
  String method,
  String path, {
  String ip = '192.168.1.40',
  Object? body,
}) => Request(
  method,
  Uri.parse('https://192.168.1.23:4433$path'),
  body: body,
  context: {'shelf.io.connection_info': _Conn(ip)},
);

Future<Map<String, Object?>> _json(Response r) async =>
    jsonDecode(await r.readAsString()) as Map<String, Object?>;

Middleware _passThrough() => (inner) => inner;

void main() {
  late PairNonceStore nonces;
  late Handler handler;
  var infoCalls = 0;

  const info = ServerInfoDto(
    deviceId: '0123456789abcdef0123456789abcdef',
    name: 'Phone',
    platform: 'android',
    fingerprint: 'ab',
    protocolVersion: kProtocolVersion,
  );

  Handler build({
    Middleware? authenticate,
    List<ServerRoute> extra = const [],
  }) => buildSharePipeline(
    served: _served,
    authenticate: authenticate,
    routes: [
      ...coreRoutes(
        info: () async {
          infoCalls++;
          return info;
        },
        nonces: nonces,
      ),
      ...extra,
    ],
  );

  setUp(() {
    infoCalls = 0;
    nonces = PairNonceStore();
    handler = build();
  });

  test('GET /v1/info returns exactly the five fields', () async {
    final r = await handler(_req('GET', '/v1/info'));
    expect(r.statusCode, 200);
    expect(r.headers['content-type'], startsWith('application/json'));
    final json = await _json(r);
    expect(json.keys.toSet(), {
      'deviceId',
      'name',
      'platform',
      'fingerprint',
      'protocolVersion',
    });
    expect(json['protocolVersion'], 1);
  });

  test('POST /v1/pair/nonce issues a 32-byte single-use nonce', () async {
    final r = await handler(_req('POST', '/v1/pair/nonce'));
    expect(r.statusCode, 200);
    final dto = PairNonceDto.fromJson(await _json(r));
    expect(dto.expiresInSeconds, 60);
    final bytes = fromB64url(dto.nonce)!;
    expect(bytes, hasLength(32));
    expect(nonces.consume('192.168.1.40', bytes), isTrue);
    expect(nonces.consume('192.168.1.40', bytes), isFalse);
  });

  group('privateNetworkOnly', () {
    test('same /24 as a served address passes', () {
      expect(sameSubnet(InternetAddress('192.168.1.200'), _served), isTrue);
      expect(sameSubnet(InternetAddress('192.168.43.7'), _served), isTrue);
    });

    test('other subnets, loopback, mobile data and IPv6 get 403', () async {
      for (final ip in [
        '192.168.2.40',
        '10.20.30.40',
        '127.0.0.1',
        '8.8.8.8',
        '::1',
      ]) {
        final r = await handler(_req('GET', '/v1/info', ip: ip));
        expect(r.statusCode, 403, reason: ip);
        expect((await _json(r))['code'], 'forbidden');
      }
      expect(infoCalls, 0);
    });

    test('a request without connection info gets 403', () async {
      final r = await handler(
        Request('GET', Uri.parse('https://192.168.1.23:4433/v1/info')),
      );
      expect(r.statusCode, 403);
    });

    test('prefix compare honours the prefix length', () {
      final wide = [LocalAddress(InternetAddress('10.1.2.3'), 8, 'wlan0')];
      expect(sameSubnet(InternetAddress('10.200.0.1'), wide), isTrue);
      final narrow = [LocalAddress(InternetAddress('10.1.2.3'), 30, 'wlan0')];
      expect(sameSubnet(InternetAddress('10.1.2.1'), narrow), isTrue);
      expect(sameSubnet(InternetAddress('10.1.2.4'), narrow), isFalse);
    });
  });

  group('authenticate stub', () {
    test('every route outside the allow-set gets 401', () async {
      for (final (m, p) in [
        ('GET', '/v1/files'),
        ('GET', '/v1/roots'),
        ('GET', '/v1/session'),
        ('POST', '/v1/files/trash'),
        ('GET', '/v1/info/'),
        ('POST', '/v1/info'),
        ('GET', '/'),
      ]) {
        final r = await handler(_req(m, p));
        expect(r.statusCode, 401, reason: '$m $p');
        expect((await _json(r))['code'], 'unauthorized');
      }
    });

    test('allow-set routes not built yet are 404 (deny by default)', () async {
      final r = await handler(_req('POST', '/v1/pair'));
      expect(r.statusCode, 404);
      expect((await _json(r))['code'], 'not_found');
    });
  });

  test('router is deny-by-default: unknown routes are 404', () async {
    final open = build(authenticate: _passThrough());
    final r = await open(_req('GET', '/v1/nope'));
    expect(r.statusCode, 404);
  });

  group('requestSizeLimit', () {
    late List<int> seen;
    setUp(() {
      seen = [];
      handler = build(
        authenticate: _passThrough(),
        extra: [
          ServerRoute('POST', '/v1/echo', (request) async {
            seen.addAll(await request.read().expand((c) => c).toList());
            return jsonOk({'n': seen.length});
          }),
        ],
      );
    });

    test('64 KiB passes, one byte more is 413', () async {
      final ok = await handler(
        _req('POST', '/v1/echo', body: List.filled(kMaxJsonBodyBytes, 32)),
      );
      expect(ok.statusCode, 200);
      final big = await handler(
        _req('POST', '/v1/echo', body: List.filled(kMaxJsonBodyBytes + 1, 32)),
      );
      expect(big.statusCode, 413);
      expect((await _json(big))['code'], 'too_large');
    });

    test('a body without Content-Length is capped too', () async {
      Stream<List<int>> chunks(int n) =>
          Stream.fromIterable(List.generate(n, (_) => List.filled(1024, 32)));
      final big = await handler(_req('POST', '/v1/echo', body: chunks(65)));
      expect(big.statusCode, 413);
      seen.clear();
      final ok = await handler(_req('POST', '/v1/echo', body: chunks(64)));
      expect(ok.statusCode, 200);
      expect(seen, hasLength(kMaxJsonBodyBytes));
    });
  });

  test('a throwing handler becomes 500 internal without details', () async {
    final h = build(
      authenticate: _passThrough(),
      extra: [
        ServerRoute('GET', '/v1/boom', (_) => throw StateError('secret')),
      ],
    );
    final r = await h(_req('GET', '/v1/boom'));
    expect(r.statusCode, 500);
    final body = await r.readAsString();
    expect(body, isNot(contains('secret')));
    expect(jsonDecode(body), {'code': 'internal', 'message': ''});
  });

  test('duplicate routes are rejected', () {
    expect(
      () => build(
        extra: [ServerRoute('GET', ApiRoutes.info, (_) => Response.ok(''))],
      ),
      throwsArgumentError,
    );
  });
}
