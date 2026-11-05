import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/link_perms_store.dart';
import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/routes/take_routes.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_scope_store.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/data/take_gate.dart';
import 'package:kfm/features/connect/domain/link.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:shelf/shelf.dart';

import '../../core/files/fake_file_source.dart';
import 'handler_remote_http.dart';
import 'path_guard_test.dart' show fakeGuard;

const _root = '/storage/emulated/0';
const _fp = 'fp';

/// TASK-E1d3: while "take without asking" is off, content and sha256 need a
/// grant from the take prompt; a verified-move trash needs a move grant;
/// viewing (stat, thumbs, previews) never asks.
void main() {
  late ClientSessionStore sessions;
  late ShareScopeStore scopes;
  late LinkPermsStore perms;
  late TakeGate gate;
  late FakeFileSource files;
  late Handler handler;
  late String token;

  setUp(() {
    sessions = ClientSessionStore();
    scopes = ShareScopeStore(sessions: sessions);
    perms = LinkPermsStore();
    gate = TakeGate(perms: perms.of);
    files = FakeFileSource()
      ..addFile('$_root/DCIM/a.jpg')
      ..addFile('$_root/DCIM/b.mp4', bytes: const [4, 5]);
    final existing = {
      _root,
      '$_root/DCIM',
      for (final f in files.files) ...[f.folderPath, f.path],
    };
    final guard = AllowListGuard(
      scopeOf: scopes.scopeOf,
      source: () => files,
      paths: fakeGuard(existing: existing),
      takes: gate,
    );
    Future<Response> ok(Request r) async => Response.ok('ok');
    handler = buildSharePipeline(
      served: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
      authenticate: authenticate(sessions),
      routes: [
        ServerRoute(
          'GET',
          '/v1/files/<id>/content',
          guard.guarded(
            ok,
            write: false,
            take: true,
            extract: (i) async => [FileIdTarget(routeParam(i.request, 'id'))],
          ),
        ),
        ServerRoute(
          'GET',
          '/v1/files/<id>/thumb',
          guard.guarded(
            ok,
            write: false,
            extract: (i) async => [FileIdTarget(routeParam(i.request, 'id'))],
          ),
        ),
        takeRoute(guard: guard, gate: gate),
      ],
    );
    scopes.set(
      _fp,
      const ShareScope([
        SharedRoot(id: 'all', path: _root, label: 'All', readOnly: false),
      ]),
    );
    token = sessions
        .issue(clientFingerprint: _fp, clientDeviceId: 'd', clientName: 'Phone')
        .token;
  });

  tearDown(() async {
    sessions.clear();
    gate.clear();
    await files.dispose();
  });

  Future<Response> call(String method, String path, {Object? body}) async =>
      await handler(
        Request(
          method,
          Uri.parse('https://192.168.1.23:4433$path'),
          headers: {'authorization': 'Bearer $token'},
          body: body == null ? null : jsonEncode(body),
          context: {
            'shelf.io.connection_info': FakeConnectionInfo('192.168.1.40'),
          },
        ),
      );

  Future<String> code(Response r) async =>
      (jsonDecode(await r.readAsString()) as Map<String, Object?>)['code']!
          as String;

  String id(String name) => 'path:$_root/DCIM/$name';
  String content(String name) =>
      '/v1/files/${Uri.encodeComponent(id(name))}/content';

  test('a take-free (or non-link) peer reads without asking', () async {
    expect((await call('GET', content('a.jpg'))).statusCode, 200);
    perms.set(_fp, const LinkPerms());
    expect((await call('GET', content('a.jpg'))).statusCode, 200);
    final r = await call(
      'POST',
      ApiRoutes.take,
      body: {
        'ids': [id('a.jpg')],
      },
    );
    expect(r.statusCode, 200);
    expect(gate.queued, 0);
  });

  test('take-asking on: content → 403 take_needs_approval; thumbs still '
      'work; Allow grants exactly the asked ids', () async {
    perms.set(_fp, const LinkPerms(takeFreely: false));
    var r = await call('GET', content('a.jpg'));
    expect(r.statusCode, 403);
    expect(await code(r), 'take_needs_approval');
    expect(
      (await call(
        'GET',
        '/v1/files/${Uri.encodeComponent(id('a.jpg'))}/thumb',
      )).statusCode,
      200,
    );
    final prompted = gate.events.firstWhere((e) => e is TakeRequested);
    final pending = call(
      'POST',
      ApiRoutes.take,
      body: {
        'ids': [id('a.jpg')],
      },
    );
    final request = (await prompted).request;
    expect(request.peerName, 'Phone');
    expect(request.files.single.name, 'a.jpg');
    expect(request.files.single.sizeBytes, 3);
    gate.decide(request.id, allow: true);
    expect((await pending).statusCode, 200);
    expect((await call('GET', content('a.jpg'))).statusCode, 200);
    // Not asked for: still refused.
    expect((await call('GET', content('b.mp4'))).statusCode, 403);
    // A second take of granted ids doesn't ask again.
    r = await call(
      'POST',
      ApiRoutes.take,
      body: {
        'ids': [id('a.jpg')],
      },
    );
    expect(r.statusCode, 200);
    expect(gate.allows(_fp, id('a.jpg'), move: true), isFalse);
  });

  test('Decline → 403 declined; ids outside the scope → refused before '
      'anyone is asked', () async {
    perms.set(_fp, const LinkPerms(takeFreely: false));
    final prompted = gate.events.firstWhere((e) => e is TakeRequested);
    final pending = call(
      'POST',
      ApiRoutes.take,
      body: {
        'ids': [id('b.mp4')],
      },
    );
    gate.decide((await prompted).request.id, allow: false);
    final r = await pending;
    expect(r.statusCode, 403);
    expect(await code(r), 'declined');
    final outside = await call(
      'POST',
      ApiRoutes.take,
      body: {
        'ids': ['path:/storage/emulated/0/Android/data/x.db'],
      },
    );
    expect(outside.statusCode, anyOf(403, 404));
    expect(gate.queued, 0);
  });

  test('no answer → timed out; prompts queue one at a time; closing the '
      'link drops the grants', () async {
    final perms = LinkPermsStore()
      ..set(_fp, const LinkPerms(takeFreely: false));
    final gate = TakeGate(
      perms: perms.of,
      timeout: const Duration(milliseconds: 50),
    );
    final first = gate.request(
      peerFingerprint: _fp,
      peerName: 'P',
      ids: const ['x'],
      files: const [],
      move: false,
    );
    final second = gate.request(
      peerFingerprint: _fp,
      peerName: 'P',
      ids: const ['y'],
      files: const [],
      move: true,
    );
    expect(gate.queued, 2);
    expect(await first, TakeDecision.timedOut);
    final head = gate.current!;
    expect(head.move, isTrue);
    gate.decide(head.id, allow: true);
    expect(await second, TakeDecision.allowed);
    expect(gate.allows(_fp, 'y', move: true), isTrue);
    expect(gate.allows(_fp, 'x'), isFalse);
    gate.clearPeer(_fp);
    expect(gate.allows(_fp, 'y'), isFalse);
  });

  test('a peer claiming wider perms changes nothing here', () {
    perms.set(_fp, const LinkPerms(takeFreely: false));
    // What the peer sent in /v1/link is display only: the gate reads this
    // device's store, never a DTO.
    final claimed = LinkRequestDto.fromJson(const {
      'port': 1,
      'invite': 'x',
      'perms': {'see': true, 'takeFreely': true},
    });
    expect(claimed.perms.takeFreely, isTrue);
    expect(gate.needsApproval(_fp), isTrue);
  });
}
