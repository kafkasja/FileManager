import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/routes/roots_routes.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_scope_store.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:shelf/shelf.dart';

import '../../core/files/fake_file_source.dart';
import 'handler_remote_http.dart';
import 'path_guard_test.dart' show fakeGuard;

const _root = '/storage/emulated/0';

SharedRoot _r(String id, String rel, {bool readOnly = true}) =>
    SharedRoot(id: id, path: '$_root/$rel', label: rel, readOnly: readOnly);

void main() {
  late ClientSessionStore sessions;
  late ShareScopeStore scopes;
  late FakeFileSource files;
  late Handler handler;
  late String token;
  List<ResolvedTarget>? seen;
  String? seenBody;

  setUp(() {
    sessions = ClientSessionStore();
    scopes = ShareScopeStore(sessions: sessions);
    files = FakeFileSource()
      ..addFile('$_root/DCIM/a.jpg')
      ..addFile('$_root/Download/x.pdf')
      ..addFile('$_root/DCIM/.KFMTrash/t.jpg')
      ..addFile('$_root/Android/data/app.db');
    final existing = {
      _root,
      '$_root/DCIM',
      '$_root/Download',
      for (final f in files.files) ...[f.folderPath, f.path],
    };
    final guard = AllowListGuard(
      scopeOf: scopes.scopeOf,
      source: () => files,
      paths: fakeGuard(existing: existing),
    );
    seen = null;
    seenBody = null;
    Future<Response> ok(Request r) async {
      seen = guardedTargetsOf(r);
      seenBody = await r.readAsString();
      return Response.ok('ok');
    }

    handler = buildSharePipeline(
      served: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
      authenticate: authenticate(sessions),
      routes: [
        rootsRoute(scopes),
        ServerRoute(
          'GET',
          ApiRoutes.files,
          guard.guarded(
            ok,
            write: false,
            extract: (i) async => [
              RootPathTarget(
                i.request.url.queryParameters['rootId'] ?? '',
                i.request.url.queryParameters['path'] ?? '',
              ),
            ],
          ),
        ),
        ServerRoute(
          'GET',
          '/v1/files/<id>/content',
          guard.guarded(
            ok,
            write: false,
            extract: (i) async => [FileIdTarget(routeParam(i.request, 'id'))],
          ),
        ),
        ServerRoute(
          'GET',
          '/v1/files/<id>/empty',
          guard.guarded(ok, write: false, extract: (_) async => const []),
        ),
        ServerRoute(
          'POST',
          '/v1/files/<id>/move',
          guard.guarded(
            ok,
            write: true,
            extract: (i) async {
              final body = await i.json();
              return [
                FileIdTarget(routeParam(i.request, 'id')),
                RootPathTarget(
                  body['targetRootId']! as String,
                  body['targetPath']! as String,
                ),
              ];
            },
          ),
        ),
      ],
    );
    token = sessions
        .issue(clientFingerprint: 'fp', clientDeviceId: 'd', clientName: 'B')
        .token;
  });

  tearDown(() async {
    sessions.clear();
    await files.dispose();
  });

  Future<Response> call(
    String method,
    String pathAndQuery, {
    Object? body,
    bool auth = true,
  }) async => await handler(
    Request(
      method,
      Uri.parse('https://192.168.1.23:4433$pathAndQuery'),
      headers: {if (auth) 'authorization': 'Bearer $token'},
      body: body == null ? null : jsonEncode(body),
      context: {'shelf.io.connection_info': FakeConnectionInfo('192.168.1.40')},
    ),
  );

  Future<String> errorCode(Response r) async =>
      (jsonDecode(await r.readAsString()) as Map<String, Object?>)['code']!
          as String;

  String enc(String id) => Uri.encodeComponent(id);

  test('GET /v1/roots lists only what was shared, without paths', () async {
    var r = await call('GET', ApiRoutes.roots);
    expect(jsonDecode(await r.readAsString()), {'roots': <Object?>[]});
    scopes.set('fp', ShareScope([_r('cam', 'DCIM')]));
    r = await call('GET', ApiRoutes.roots);
    final text = await r.readAsString();
    expect(jsonDecode(text), {
      'roots': [
        {'id': 'cam', 'label': 'DCIM', 'readOnly': true},
      ],
    });
    expect(text, isNot(contains('/storage')));
    // Adding a root applies to the next request.
    scopes.set('fp', ShareScope([_r('cam', 'DCIM'), _r('dl', 'Download')]));
    r = await call('GET', ApiRoutes.roots);
    expect(
      (jsonDecode(await r.readAsString()) as Map<String, Object?>)['roots'],
      hasLength(2),
    );
  });

  test('auth runs before the guard: no token → 401, not 403', () async {
    final r = await call(
      'GET',
      '/v1/files/${enc('path:$_root/x')}/content',
      auth: false,
    );
    expect(r.statusCode, 401);
  });

  test('root + relative path: inside passes, ../ escape is 403', () async {
    scopes.set('fp', ShareScope([_r('cam', 'DCIM')]));
    var r = await call('GET', '/v1/files?rootId=cam&path=');
    expect(r.statusCode, 200);
    expect(seen!.single.canonicalPath, '$_root/DCIM');
    r = await call('GET', '/v1/files?rootId=cam&path=../../Download');
    expect(r.statusCode, 403);
    expect(await errorCode(r), 'forbidden_path');
    r = await call('GET', '/v1/files?rootId=cam&path=..%2FDownload');
    expect(r.statusCode, 403);
    r = await call('GET', '/v1/files?rootId=nope&path=');
    expect(r.statusCode, 403);
  });

  test(
    'file ids: encoded ../ is 403; outside scope 403; unknown 404',
    () async {
      scopes.set('fp', ShareScope([_r('cam', 'DCIM')]));
      var r = await call(
        'GET',
        '/v1/files/${enc('path:$_root/DCIM/a.jpg')}/content',
      );
      expect(r.statusCode, 200);
      expect(seen!.single.file?.ref.name, 'a.jpg');
      r = await call(
        'GET',
        '/v1/files/path:%2Fstorage%2Femulated%2F0%2FDCIM%2F..%2FDownload%2Fx.pdf/content',
      );
      expect(r.statusCode, 403);
      r = await call(
        'GET',
        '/v1/files/${enc('path:$_root/Download/x.pdf')}/content',
      );
      expect(r.statusCode, 403);
      r = await call(
        'GET',
        '/v1/files/${enc('path:$_root/DCIM/zz.jpg')}/content',
      );
      expect(r.statusCode, 404);
      // Double-encoded: decoded once it is no id at all; bad % encoding.
      r = await call('GET', '/v1/files/path%253A%252Fstorage/content');
      expect(r.statusCode, 403);
      r = await call('GET', '/v1/files/path%zz/content');
      expect(r.statusCode, 403);
    },
  );

  test(
    '.KFMTrash and Android/data are 403 even with all storage shared',
    () async {
      scopes.set(
        'fp',
        ShareScope([_r('all', '', readOnly: false).withPath(_root)]),
      );
      for (final p in [
        '$_root/DCIM/.KFMTrash/t.jpg',
        '$_root/Android/data/app.db',
      ]) {
        final r = await call('GET', '/v1/files/${enc('path:$p')}/content');
        expect(r.statusCode, 403, reason: p);
      }
      final r = await call(
        'GET',
        '/v1/files/${enc('path:$_root/Download/x.pdf')}/content',
      );
      expect(r.statusCode, 200);
    },
  );

  test('move: source and target both checked; read-only root refuses '
      'writes; body reaches the route', () async {
    scopes.set(
      'fp',
      ShareScope([_r('cam', 'DCIM', readOnly: false), _r('dl', 'Download')]),
    );
    final id = enc('path:$_root/DCIM/a.jpg');
    // Target outside every root.
    var r = await call(
      'POST',
      '/v1/files/$id/move',
      body: {'targetRootId': 'cam', 'targetPath': '../Music'},
    );
    expect(r.statusCode, 403);
    // Target under a read-only root.
    r = await call(
      'POST',
      '/v1/files/$id/move',
      body: {'targetRootId': 'dl', 'targetPath': ''},
    );
    expect(r.statusCode, 403);
    // Source under a read-only root.
    r = await call(
      'POST',
      '/v1/files/${enc('path:$_root/Download/x.pdf')}/move',
      body: {'targetRootId': 'cam', 'targetPath': ''},
    );
    expect(r.statusCode, 403);
    // Writable → writable passes, body forwarded intact.
    r = await call(
      'POST',
      '/v1/files/$id/move',
      body: {'targetRootId': 'cam', 'targetPath': 'sub'},
    );
    expect(r.statusCode, 200);
    expect(seen!.map((t) => t.canonicalPath), [
      '$_root/DCIM/a.jpg',
      '$_root/DCIM/sub',
    ]);
    expect(jsonDecode(seenBody!), {'targetRootId': 'cam', 'targetPath': 'sub'});
    // A malformed body is refused, not a 500.
    r = await call('POST', '/v1/files/$id/move', body: [1]);
    expect(r.statusCode, 403);
    expect(files.stat('path:$_root/DCIM/a.jpg'), completion(isNotNull));
  });

  test(
    'a scope edit cancels the client streams outside the new scope',
    () async {
      final session = sessions.sessions.single;
      final inCam = StreamController<int>();
      final inDl = StreamController<int>();
      final cancelled = <String>[];
      sessions
        ..registerStream(
          session.sessionId,
          inCam.stream.listen(null),
          canonicalPath: '$_root/DCIM/a.jpg',
        )
        ..registerStream(
          session.sessionId,
          inDl.stream.listen(null),
          canonicalPath: '$_root/Download/x.pdf',
        );
      inCam.onCancel = () => cancelled.add('cam');
      inDl.onCancel = () => cancelled.add('dl');
      scopes.set('fp', ShareScope([_r('cam', 'DCIM')]));
      await pumpEventQueue();
      expect(cancelled, ['dl']);
      expect(sessions.streamsOf(session.sessionId), hasLength(1));
    },
  );

  test('review: out-of-scope paths are 403 whether or not they exist '
      '(no existence oracle); in-scope unknown is 404', () async {
    scopes.set('fp', ShareScope([_r('cam', 'DCIM')]));
    for (final p in [
      '$_root/Download/x.pdf', // exists
      '$_root/Download/secret.pdf', // missing
      '$_root/Android/data/app.db', // exists, excluded
      '$_root/Android/data/com.other', // missing, excluded
    ]) {
      final r = await call('GET', '/v1/files/${enc('path:$p')}/content');
      expect(r.statusCode, 403, reason: p);
    }
    final r = await call(
      'GET',
      '/v1/files/${enc('path:$_root/DCIM/missing.jpg')}/content',
    );
    expect(r.statusCode, 404);
  });

  test(
    'review: case-insensitive storage cannot bypass a read-only root',
    () async {
      const whole = SharedRoot(
        id: 'all',
        path: _root,
        label: 'All',
        readOnly: false,
      );
      scopes.set('fp', ShareScope([whole, _r('cam', 'DCIM')]));
      final id = enc('path:$_root/Download/x.pdf');
      var r = await call(
        'POST',
        '/v1/files/$id/move',
        body: {'targetRootId': 'all', 'targetPath': 'dcim/Camera'},
      );
      expect(r.statusCode, 403);
      r = await call(
        'POST',
        '/v1/files/$id/move',
        body: {'targetRootId': 'all', 'targetPath': 'Music'},
      );
      expect(r.statusCode, 200);
      // Reading through a different case still works (same folder).
      scopes.set('fp', ShareScope([_r('cam', 'DCIM')]));
      expect(
        ShareScope([_r('cam', 'DCIM')]).rootFor('$_root/dcim/a.jpg')?.id,
        'cam',
      );
    },
  );

  test('review: an empty target list and bad field types are 403, not '
      '200 or 500', () async {
    scopes.set('fp', ShareScope([_r('cam', 'DCIM', readOnly: false)]));
    var r = await call('GET', '/v1/files/x/empty');
    expect(r.statusCode, 403);
    r = await call(
      'POST',
      '/v1/files/${enc('path:$_root/DCIM/a.jpg')}/move',
      body: {'targetRootId': 7, 'targetPath': ''},
    );
    expect(r.statusCode, 403);
  });

  test('review: a root turning read-only ends the client uploads, not '
      'its downloads', () async {
    scopes.set('fp', ShareScope([_r('cam', 'DCIM', readOnly: false)]));
    final session = sessions.sessions.single;
    final up = StreamController<int>();
    final down = StreamController<int>();
    final cancelled = <String>[];
    up.onCancel = () => cancelled.add('up');
    down.onCancel = () => cancelled.add('down');
    sessions
      ..registerStream(
        session.sessionId,
        up.stream.listen(null),
        canonicalPath: '$_root/DCIM/new.jpg',
        write: true,
      )
      ..registerStream(
        session.sessionId,
        down.stream.listen(null),
        canonicalPath: '$_root/DCIM/a.jpg',
      );
    scopes.set('fp', ShareScope([_r('cam', 'DCIM')]));
    await pumpEventQueue();
    expect(cancelled, ['up']);
  });
}

extension on SharedRoot {
  SharedRoot withPath(String path) =>
      SharedRoot(id: id, path: path, label: label, readOnly: readOnly);
}
