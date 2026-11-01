import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:shelf/shelf.dart';

import 'handler_remote_http.dart';

/// Every route of the N1 route table (protocol v1), with a placeholder id.
const List<(String, String)> _allRoutes = [
  ('GET', '/v1/info'),
  ('POST', '/v1/pair/nonce'),
  ('POST', '/v1/pair/code/start'),
  ('POST', '/v1/pair'),
  ('POST', '/v1/pair/known'),
  ('POST', '/v1/pair/cancel'),
  ('GET', '/v1/session'),
  ('POST', '/v1/session/close'),
  ('GET', '/v1/roots'),
  ('GET', '/v1/files'),
  ('GET', '/v1/files/x1'),
  ('GET', '/v1/files/x1/thumb'),
  ('GET', '/v1/files/x1/preview'),
  ('GET', '/v1/files/x1/content'),
  ('POST', '/v1/files/x1/move'),
  ('POST', '/v1/files/x1/copy'),
  ('POST', '/v1/files/x1/rename'),
  ('POST', '/v1/files/trash'),
  ('POST', '/v1/files/write-access'),
  ('GET', '/v1/files/x1/sha256'),
  ('POST', '/v1/uploads'),
  ('GET', '/v1/uploads/u1'),
  ('PUT', '/v1/uploads/u1/chunk'),
  ('POST', '/v1/uploads/u1/complete'),
  ('DELETE', '/v1/uploads/u1'),
];

void main() {
  late DateTime now;
  late ClientSessionStore store;
  late Handler handler;
  ClientSession? seen;

  setUp(() {
    now = DateTime(2026, 11);
    store = ClientSessionStore(clock: () => now);
    seen = null;
    // Every route answers 200 and records the attached session.
    handler = buildSharePipeline(
      served: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
      authenticate: authenticate(store),
      routes: [
        for (final (m, p) in _allRoutes)
          ServerRoute(m, p, (request) {
            seen = sessionOf(request);
            return Response.ok('ok');
          }),
      ],
    );
  });

  tearDown(() => store.clear());

  Future<Response> call(String method, String path, {String? auth}) async =>
      await handler(
        Request(
          method,
          Uri.parse('https://192.168.1.23:4433$path'),
          headers: {'authorization': ?auth},
          context: {
            'shelf.io.connection_info': FakeConnectionInfo('192.168.1.40'),
          },
        ),
      );

  test('every route outside the allow-set is 401 without a valid token; '
      'allow-set routes pass', () async {
    for (final (m, p) in _allRoutes) {
      final open = kUnauthenticatedRoutes.contains(routeKey(m, p));
      for (final auth in [null, 'Bearer nope', 'Basic abc', 'Bearer', '']) {
        final r = await call(m, p, auth: auth);
        expect(r.statusCode, open ? 200 : 401, reason: '$m $p auth=$auth');
      }
    }
  });

  test('a valid token passes and attaches the session', () async {
    final s = store.issue(
      clientFingerprint: 'fp',
      clientDeviceId: 'd',
      clientName: 'B',
    );
    final r = await call('GET', '/v1/files', auth: 'Bearer ${s.token}');
    expect(r.statusCode, 200);
    expect(seen?.sessionId, s.session.sessionId);
  });

  test('revoked, idle-expired and previous-run tokens → 401', () async {
    final s = store.issue(
      clientFingerprint: 'fp',
      clientDeviceId: 'd',
      clientName: 'B',
    );
    now = now.add(const Duration(minutes: 10));
    expect(
      (await call('GET', '/v1/roots', auth: 'Bearer ${s.token}')).statusCode,
      401,
    );
    final t = store.issue(
      clientFingerprint: 'fp',
      clientDeviceId: 'd',
      clientName: 'B',
    );
    store.revoke(t.session.sessionId);
    expect(
      (await call('GET', '/v1/roots', auth: 'Bearer ${t.token}')).statusCode,
      401,
    );
    final u = store.issue(
      clientFingerprint: 'fp',
      clientDeviceId: 'd',
      clientName: 'B',
    );
    store.clear(); // stop sharing
    expect(
      (await call('GET', '/v1/roots', auth: 'Bearer ${u.token}')).statusCode,
      401,
    );
  });
}
