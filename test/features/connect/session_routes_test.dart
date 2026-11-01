import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/routes/session_routes.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:shelf/shelf.dart';

import 'handler_remote_http.dart';

void main() {
  late DateTime now;
  late ClientSessionStore store;
  late Handler handler;

  setUp(() {
    now = DateTime(2026, 11);
    store = ClientSessionStore(clock: () => now);
    handler = buildSharePipeline(
      served: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
      authenticate: authenticate(store),
      routes: sessionRoutes(store),
    );
  });
  tearDown(() => store.clear());

  Future<Response> call(String method, String path, {String? token}) async =>
      await handler(
        Request(
          method,
          Uri.parse('https://192.168.1.23:4433$path'),
          headers: {if (token != null) 'authorization': 'Bearer $token'},
          context: {
            'shelf.io.connection_info': FakeConnectionInfo('192.168.1.40'),
          },
        ),
      );

  IssuedSession issue(String fp) =>
      store.issue(clientFingerprint: fp, clientDeviceId: fp, clientName: fp);

  test('GET /v1/session: 204 with a token, 401 without', () async {
    final s = issue('a');
    expect(
      (await call('GET', ApiRoutes.session, token: s.token)).statusCode,
      204,
    );
    expect((await call('GET', ApiRoutes.session)).statusCode, 401);
    expect(
      (await call('GET', ApiRoutes.session, token: 'nope')).statusCode,
      401,
    );
  });

  test('POST /v1/session/close ends only the caller session', () async {
    final a = issue('a');
    final b = issue('b');
    expect(
      (await call('POST', ApiRoutes.sessionClose, token: a.token)).statusCode,
      204,
    );
    expect(
      (await call('GET', ApiRoutes.session, token: a.token)).statusCode,
      401,
    );
    expect(
      (await call('GET', ApiRoutes.session, token: b.token)).statusCode,
      204,
    );
    expect(store.sessions.map((s) => s.clientFingerprint), ['b']);
  });

  test('heartbeats keep a session alive past the 10-minute idle timeout; '
      'without them it expires', () async {
    final live = issue('live');
    final idle = issue('idle');
    for (var i = 0; i < 30; i++) {
      now = now.add(const Duration(minutes: 1));
      expect(
        (await call('GET', ApiRoutes.session, token: live.token)).statusCode,
        204,
      );
    }
    expect(
      (await call('GET', ApiRoutes.session, token: idle.token)).statusCode,
      401,
    );
  });

  test('session routes are file-free (route-coverage exemption)', () {
    for (final r in sessionRoutes(store)) {
      expect(kNoFileAccessRoutes, contains(r.key));
    }
  });
}
