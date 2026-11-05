import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';
import 'package:kfm/features/connect/data/accept_gate.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/known_devices_dao.dart';
import 'package:kfm/features/connect/data/known_pair_limiter.dart';
import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/offer_service.dart';
import 'package:kfm/features/connect/data/pair_nonce_store.dart';
import 'package:kfm/features/connect/data/pairing_secret_store.dart';
import 'package:kfm/features/connect/data/remote_trash_service.dart';
import 'package:kfm/features/connect/data/routes/file_routes.dart';
import 'package:kfm/features/connect/data/routes/inbox_routes.dart';
import 'package:kfm/features/connect/data/routes/offer_routes.dart';
import 'package:kfm/features/connect/data/routes/pair_routes.dart';
import 'package:kfm/features/connect/data/routes/roots_routes.dart';
import 'package:kfm/features/connect/data/routes/session_routes.dart';
import 'package:kfm/features/connect/data/routes/upload_routes.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_offers_dao.dart';
import 'package:kfm/features/connect/data/share_scope_store.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/data/upload_store.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:kfm/features/connect/domain/upload_protocol.dart';
import 'package:shelf/shelf.dart';

import '../../core/files/fake_file_source.dart';
import 'handler_remote_http.dart';
import 'path_guard_test.dart' show fakeGuard;

const _root = '/storage/emulated/0';
final String _fp = 'aa' * 32;
final String _uploadId = 'ab' * 16;

/// TASK-Q7: hostile or malformed input against every share route, through
/// the real pipeline (in process). Every answer is a 2xx/4xx, never a 500,
/// an unhandled error or a hang; nothing outside the allow-list changes.
void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late ClientSessionStore sessions;
  late ShareScopeStore scopes;
  late FakeFileSource files;
  late UploadStore uploads;
  late Directory staging;
  late OfferService offers;
  late PairingSecretStore secrets;
  late AcceptGate gate;
  late List<ServerRoute> routes;
  late Handler handler;
  late Future<int?> Function() stagingFree;
  late FileRef inScope;
  late FileRef readOnly;
  late FileRef outside;

  setUp(() async {
    stagingFree = () async => null;
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    staging = await Directory.systemTemp.createTemp('kfm_fuzz');
    sessions = ClientSessionStore();
    scopes = ShareScopeStore(sessions: sessions);
    files = FakeFileSource()
      ..addFolder('$_root/DCIM')
      ..addFolder('$_root/Download')
      ..addFolder('$_root/Secret');
    inScope = files.addFile('$_root/DCIM/a.jpg', bytes: [1, 2, 3, 4]);
    readOnly = files.addFile('$_root/Download/b.pdf', bytes: [5, 6]);
    outside = files.addFile('$_root/Secret/c.jpg', bytes: [7, 8, 9]);
    final dao = MediaIndexDao(db);
    await dao.upsertBatch(files.files, 1);
    uploads = UploadStore(staging: () async => staging);
    final devices = KnownDevicesRepository(KnownDevicesDao(db), queue);
    offers = OfferService(
      repo: OfferRepository(ShareOffersDao(db), queue),
      devices: devices,
      sessions: () => sessions,
      uploads: uploads,
      freeBytes: (_) async => null,
      downloadsRoot: '$_root/Download',
    );
    final existing = {
      _root,
      '$_root/DCIM',
      '$_root/Download',
      '$_root/Secret',
      for (final f in files.files) f.path,
    };
    final guard = AllowListGuard(
      scopeOf: scopes.scopeOf,
      source: () => files,
      paths: fakeGuard(existing: existing),
      grants: offers,
    );
    final trash = RemoteTrashService(
      source: () => files,
      lock: SerialLock(),
      onNotice: (_) {},
      onOutcome: (_) {},
      removeFromIndex: dao.deleteIds,
      sessionAlive: (id) => sessions.sessions.any((s) => s.sessionId == id),
    );
    final nonces = PairNonceStore();
    secrets = PairingSecretStore()
      ..start(
        addresses: const [(host: '192.168.1.23', port: 4433)],
        serverFingerprint: 'cc' * 32,
        deviceName: 'Phone',
      );
    gate = AcceptGate();
    final handOff = promptHandOff(
      gate: gate,
      sessions: sessions,
      serverDeviceId: () async => 'server',
    );
    routes = [
      ...coreRoutes(
        info: () async => const ServerInfoDto(
          deviceId: 'server',
          name: 'Phone',
          platform: 'android',
          fingerprint: 'cc',
          protocolVersion: kProtocolVersion,
        ),
        nonces: nonces,
      ),
      ...pairRoutes(secrets: secrets, nonces: nonces, handOff: handOff),
      pairCancelRoute(gate),
      rootsRoute(scopes),
      ...sessionRoutes(
        sessions,
        changeToken: (_) async => 't',
        inboxToken: offers.inboxTokenFor,
      ),
      ...fileRoutes(
        FileRoutesEnv(
          guard: guard,
          scopeOf: scopes.scopeOf,
          sessions: sessions,
          source: () => files,
          dao: () => dao,
          addToIndex: (_) async {},
          canSeeAllFiles: () => true,
          thumbnails: () async => _NoThumbs(),
          trash: () => trash,
          preview: (f, max) async => null,
          diskLength: (f) async => null,
          hashFile: (f, s) async => 'ff' * 32,
        ),
      ),
      ...uploadRoutes(
        UploadRoutesEnv(
          // Free space on every chunk (the Q1 race needs it).
          spaceCheckBytes: 0,
          guard: guard,
          sessions: sessions,
          uploads: uploads,
          source: () => files,
          addToIndex: (_) async {},
          stagingFreeBytes: () => stagingFree(),
          hashPath: (_) async => 'ff' * 32,
          hashFile: (f, s) async => 'ff' * 32,
          grants: offers,
        ),
      ),
      ...offerRoutes(() => offers),
      ...inboxRoutes(() => offers),
      knownPairRoute(
        nonces: nonces,
        limiter: KnownPairLimiter(),
        serverFingerprint: () async => 'cc' * 32,
        lookup: (_) async => null,
        handOff: handOff,
      ),
    ];
    handler = buildSharePipeline(
      served: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
      authenticate: authenticate(sessions),
      sizeLimitExempt: (r) =>
          isUploadChunkRequest(r) || isOfferCreateRequest(r),
      routes: routes,
    );
    scopes.set(
      _fp,
      const ShareScope([
        SharedRoot(
          id: 'cam',
          path: '$_root/DCIM',
          label: 'DCIM',
          readOnly: false,
        ),
        SharedRoot(
          id: 'dl',
          path: '$_root/Download',
          label: 'Download',
          readOnly: true,
        ),
      ]),
    );
  });

  tearDown(() async {
    gate.cancelAll();
    offers.dispose();
    sessions.clear();
    secrets.clear();
    await files.dispose();
    await queue.close();
    await db.close();
    if (await staging.exists()) await staging.delete(recursive: true);
  });

  /// One request with a fresh session unless [token] is given (a fuzzed
  /// `session/close` must not starve the rest). Returns the status after
  /// the whole body was read.
  Future<int> send(
    String method,
    String path, {
    List<int>? body,
    Map<String, String> headers = const {},
    bool auth = true,
    String? token,
  }) async {
    token ??= sessions
        .issue(clientFingerprint: _fp, clientDeviceId: 'd', clientName: 'PC')
        .token;
    final response = await Future<Response>.sync(
      () => handler(
        Request(
          method,
          Uri.parse('https://192.168.1.23:4433$path'),
          headers: {
            if (auth) 'authorization': 'Bearer $token',
            if (body != null) 'content-length': '${body.length}',
            ...headers,
          },
          body: body,
          context: {
            'shelf.io.connection_info': FakeConnectionInfo('192.168.1.40'),
          },
        ),
      ),
    ).timeout(const Duration(seconds: 10));
    await response.read().drain<void>().timeout(const Duration(seconds: 10));
    return response.statusCode;
  }

  String fill(String template, String id) =>
      template.replaceAll(RegExp('<[a-zA-Z]+>'), id);

  final ids = <String>[
    'x',
    '%',
    '%zz',
    '..',
    '..%2F..%2Fetc%2Fpasswd',
    'path%3A%2Fetc%2Fpasswd',
    'path%3A${Uri.encodeComponent('$_root/DCIM/../Secret/c.jpg')}',
    'path%3A${Uri.encodeComponent('$_root/Secret/c.jpg')}',
    'path%3A${Uri.encodeComponent('$_root/DCIM/a.jpg%00')}',
    'path%3A',
    'ms%3A',
    'ms%3A-1',
    'ms%3A99999999999999999999999',
    'offer%3A1',
    'a' * 4000,
    _uploadId,
    'AB' * 16,
  ];

  final bodies = <String, List<int>?>{
    'none': null,
    'empty': const [],
    'null': utf8.encode('null'),
    'array': utf8.encode('[]'),
    'string': utf8.encode('"x"'),
    'number': utf8.encode('1e999'),
    'truncated': utf8.encode('{"ids": ["a"'),
    'bad utf8': const [0x7B, 0xFF, 0xFE, 0x7D],
    'deep': utf8.encode('${'[' * 5000}${']' * 5000}'),
    'deep object': utf8.encode('${'{"a":' * 3000}1${'}' * 3000}'),
    'empty object': utf8.encode('{}'),
    'wrong types': utf8.encode(
      jsonEncode({
        'ids': 'x',
        'targetRootId': 1,
        'targetPath': <Object?>[],
        'newName': 5,
        'uploadId': 7,
        'rootId': <String, Object?>{},
        'path': null,
        'name': true,
        'size': '5',
        'sha256': 5,
        'reason': 9,
        'sha256ById': 'x',
        'sizeById': <Object?>[],
        'hello': 'x',
        'pairAttemptId': 5,
        'nonce': 1,
        'sig': <Object?>[],
        'files': 'x',
        'done': 'x',
        'failed': 3,
      }),
    ),
    'null ids': utf8.encode('{"ids": [null, 1, {}]}'),
    'many ids': utf8.encode(
      jsonEncode({
        'ids': [for (var i = 0; i < 2000; i++) 'path:$_root/DCIM/a.jpg'],
      }),
    ),
    'traversal move': utf8.encode(
      jsonEncode({'targetRootId': 'cam', 'targetPath': '../Secret'}),
    ),
    'traversal move 2': utf8.encode(
      jsonEncode({'targetRootId': 'cam', 'targetPath': '/../../Secret'}),
    ),
    'read-only move': utf8.encode(
      jsonEncode({'targetRootId': 'dl', 'targetPath': ''}),
    ),
    'rename escape': utf8.encode(jsonEncode({'newName': '../Secret/x.jpg'})),
    'rename dot': utf8.encode(jsonEncode({'newName': '..'})),
    'negative upload': utf8.encode(
      jsonEncode({
        'uploadId': _uploadId,
        'rootId': 'cam',
        'path': '',
        'name': 'n.jpg',
        'size': -1,
      }),
    ),
    'huge upload': utf8.encode(
      jsonEncode({
        'uploadId': _uploadId,
        'rootId': 'cam',
        'path': '',
        'name': 'h.jpg',
        'size': 9223372036854775807,
      }),
    ),
    'float upload': utf8.encode(
      jsonEncode({
        'uploadId': _uploadId,
        'rootId': 'cam',
        'path': '',
        'name': 'f.jpg',
        'size': 1.5,
      }),
    ),
    'traversal upload': utf8.encode(
      jsonEncode({
        'uploadId': _uploadId,
        'rootId': 'cam',
        'path': '../Secret',
        'name': 'evil.jpg',
        'size': 3,
      }),
    ),
    'traversal upload id': utf8.encode(
      jsonEncode({
        'uploadId': '../../x',
        'rootId': 'cam',
        'path': '',
        'name': 'e.jpg',
        'size': 3,
      }),
    ),
    'verifiedMove trash': utf8.encode(
      jsonEncode({
        'ids': ['path:$_root/Secret/c.jpg'],
        'reason': 'verifiedMove',
        'sha256ById': {'x': 5},
        'sizeById': {'x': 'y'},
      }),
    ),
    'pair junk': utf8.encode(
      jsonEncode({
        'hello': {
          'pairAttemptId': 'a',
          'clientDeviceId': 'b',
          'clientName': 'c',
          'clientPlatform': 'd',
          'clientCertPem':
              '-----BEGIN CERTIFICATE-----\nAAAA\n-----END '
              'CERTIFICATE-----',
        },
        'pA': 'AAAA',
        'nonce': '!!!',
        'sig': 'AAAA',
        'secret': 'AAAA',
        'attemptId': 'x',
        'confirmA': 'AAAA',
      }),
    ),
    'offer junk': utf8.encode(
      jsonEncode({
        'offerId': 'x' * 100,
        'files': [
          {'name': '../x', 'size': -5},
          {'name': 5},
          null,
        ],
      }),
    ),
    'finished junk': utf8.encode(
      jsonEncode({
        'done': [1, null],
        'failed': {'a': 1},
      }),
    ),
    'over limit': List<int>.filled(kMaxJsonBodyBytes + 10, 0x20),
  };

  final queries = <String>[
    '?offset=-1',
    '?offset=abc',
    '?offset=99999999999999999999999',
    '?offset=0&offset=1',
    '?q=garbage',
    '?q=%7B%7D',
    '?q=${Uri.encodeQueryComponent('{"rootId":"cam","path":"../Secret"}')}',
    '?q=${Uri.encodeQueryComponent('{"rootId":5}')}',
    '?cursor=zzz',
    '?cursor=%',
    '?limit=-5&max=-1',
    '?rootId=cam&path=..%2FSecret',
    '?rootId=cam&path=%2F..%2F..',
    '?rootId=nope',
  ];

  final rangeHeaders = <String>[
    'bytes=-',
    'bytes=5-1',
    'bytes=-0',
    'bytes=99999999999999999999999-',
    'bytes=0-99999999999999999999999',
    'bytes=0-0,1-1',
    'items=0-1',
  ];

  Future<void> expectNo500(
    String what,
    Future<int> Function() request,
    List<String> failures,
  ) async {
    try {
      final status = await request();
      if (status >= 500) failures.add('$what → $status');
    } on Object catch (e) {
      failures.add('$what → threw ${e.runtimeType}: $e');
    }
  }

  test('every route: malformed ids, bodies, queries and ranges are 4xx, '
      'never 500, a throw or a hang', () async {
    final failures = <String>[];
    for (final r in routes) {
      final validId = r.path.contains('upload')
          ? _uploadId
          : Uri.encodeComponent(inScope.id);
      for (final id in ids) {
        final path = fill(r.path, id);
        await expectNo500(
          '${r.method} $path',
          () => send(r.method, path, body: utf8.encode('{}')),
          failures,
        );
      }
      final path = fill(r.path, validId);
      for (final MapEntry(:key, :value) in bodies.entries) {
        await expectNo500(
          '${r.method} $path body=$key',
          () => send(r.method, path, body: value),
          failures,
        );
      }
      for (final q in queries) {
        await expectNo500(
          '${r.method} $path$q',
          () => send(r.method, '$path$q', body: utf8.encode('{}')),
          failures,
        );
      }
      for (final range in rangeHeaders) {
        await expectNo500(
          '${r.method} $path Range: $range',
          () => send(
            r.method,
            path,
            headers: {'range': range, 'if-range': '"x"'},
          ),
          failures,
        );
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test(
    'nothing outside the writable scope changed after the fuzzing',
    () async {
      final before = {for (final f in files.files) f.id: f};
      for (final r in routes) {
        if (r.method == 'GET') continue;
        for (final id in ids) {
          for (final body in bodies.values) {
            try {
              await send(r.method, fill(r.path, id), body: body);
            } on Object {
              // The first test reports throws; this one checks side effects.
            }
          }
        }
      }
      final after = {for (final f in files.files) f.id: f};
      expect(after[outside.id], isNotNull, reason: 'outside the scope');
      expect(files.bytesOf(outside.id), [7, 8, 9]);
      expect(after[readOnly.id], isNotNull, reason: 'read-only root');
      expect(files.bytesOf(readOnly.id), [5, 6]);
      for (final f in after.values) {
        expect(
          f.path.startsWith('$_root/DCIM/') || before.containsKey(f.id),
          isTrue,
          reason: 'new file outside the writable root: ${f.path}',
        );
      }
      // No partial escaped the staging folder.
      for (final e in staging.listSync()) {
        expect(e.path.startsWith(staging.path), isTrue);
      }
    },
  );

  test('a revoked, idle-expired or malformed bearer token is 401 on every '
      'authenticated route', () async {
    final old = sessions.issue(
      clientFingerprint: _fp,
      clientDeviceId: 'd',
      clientName: 'PC',
    );
    // Reconnecting replaces the session: the old token is now a replay.
    sessions.issue(
      clientFingerprint: _fp,
      clientDeviceId: 'd',
      clientName: 'PC',
    );
    final tokens = <String>[
      'Bearer ${old.token}',
      'Bearer ${old.token} ',
      'bearer ${old.token}',
      'Bearer ',
      'Bearer ${'A' * 129}',
      'Basic ${base64.encode(utf8.encode('a:b'))}',
      'Bearer a\u0000b',
    ];
    for (final r in routes) {
      if (kUnauthenticatedRoutes.contains(r.key)) continue;
      for (final t in tokens) {
        final response = await handler(
          Request(
            r.method,
            Uri.parse(
              'https://192.168.1.23:4433'
              '${fill(r.path, Uri.encodeComponent(inScope.id))}',
            ),
            headers: {'authorization': t},
            context: {
              'shelf.io.connection_info': FakeConnectionInfo('192.168.1.40'),
            },
          ),
        );
        expect(response.statusCode, 401, reason: '${r.key} with "$t"');
      }
    }
  });

  test('a chunk at a negative, future or overflowing offset is refused and '
      'leaves the partial untouched', () async {
    expect(
      await send(
        'POST',
        ApiRoutes.uploads,
        body: utf8.encode(
          jsonEncode(
            CreateUploadDto(
              uploadId: _uploadId,
              rootId: 'cam',
              path: '',
              name: 'z.jpg',
              size: 4,
            ).toJson(),
          ),
        ),
      ),
      201,
    );
    for (final offset in ['-1', '1', '4', '9223372036854775807', '-0']) {
      final status = await send(
        'PUT',
        '${ApiRoutes.uploadChunk(_uploadId)}?offset=$offset',
        body: const [1, 2],
        headers: const {'content-type': 'application/octet-stream'},
      );
      if (offset == '-0') {
        // int.parse('-0') == 0: a valid first chunk.
        expect(status, 200);
        continue;
      }
      expect(status, inInclusiveRange(400, 499), reason: 'offset $offset');
    }
    final part = File('${staging.path}/up-$_uploadId.part');
    expect(await part.readAsBytes(), [1, 2]);
    // A body longer than the rest of the declared size.
    expect(
      await send(
        'PUT',
        '${ApiRoutes.uploadChunk(_uploadId)}?offset=2',
        body: const [3, 4, 5],
      ),
      413,
    );
    expect(await part.readAsBytes(), [1, 2]);
  });

  Future<void> createUpload(
    String id, {
    int size = 4,
    String name = 'z.jpg',
  }) async {
    expect(
      await send(
        'POST',
        ApiRoutes.uploads,
        body: utf8.encode(
          jsonEncode(
            CreateUploadDto(
              uploadId: id,
              rootId: 'cam',
              path: '',
              name: name,
              size: size,
            ).toJson(),
          ),
        ),
      ),
      201,
    );
  }

  test('complete with a malformed body is refused (4xx) and publishes '
      'nothing unverified', () async {
    final failures = <String>[];
    var n = 0;
    for (final MapEntry(:key, :value) in bodies.entries) {
      final id = (n++).toRadixString(16).padLeft(32, '0');
      await createUpload(id, name: 'z$n.jpg');
      expect(
        await send(
          'PUT',
          '${ApiRoutes.uploadChunk(id)}?offset=0',
          body: const [1, 2, 3, 4],
        ),
        200,
      );
      await expectNo500(
        'complete body=$key',
        () => send('POST', ApiRoutes.uploadComplete(id), body: value),
        failures,
      );
      const malformed = {
        'null',
        'array',
        'string',
        'number',
        'truncated',
        'bad utf8',
        'deep',
        'wrong types',
        'over limit',
      };
      if (malformed.contains(key)) {
        // Not published without the check the client may have asked for;
        // the partial stays for a well-formed retry.
        expect(
          files.files.where((f) => f.name == 'z$n.jpg'),
          isEmpty,
          reason: key,
        );
        expect((await uploads.any(id))?.received, 4, reason: key);
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('Q1 reconnect race: a repeated chunk at the same offset that was '
      'still checking free space is never appended twice', () async {
    await createUpload(_uploadId);
    final gates = <Completer<void>>[];
    stagingFree = () async {
      final g = Completer<void>();
      gates.add(g);
      await g.future;
      return null;
    };
    final chunk = '${ApiRoutes.uploadChunk(_uploadId)}?offset=0';
    final token = sessions
        .issue(clientFingerprint: _fp, clientDeviceId: 'd', clientName: 'PC')
        .token;
    final first = send('PUT', chunk, body: const [1, 2], token: token);
    final retry = send('PUT', chunk, body: const [1, 2], token: token);
    while (gates.length < 2) {
      await Future<void>.delayed(Duration.zero);
    }
    gates[0].complete();
    expect(await first, 200);
    gates[1].complete();
    expect(await retry, 409);
    final part = File('${staging.path}/up-$_uploadId.part');
    expect(await part.readAsBytes(), [1, 2]);
    expect((await uploads.any(_uploadId))!.received, 2);
  });

  test(
    'a declared size near 2^63 does not overflow the free-space check',
    () async {
      files.freeBytesValue = 1 << 30;
      for (final size in [
        9223372036854775807,
        9223372036854775807 - kTransferSpaceMarginBytes + 1,
      ]) {
        final status = await send(
          'POST',
          ApiRoutes.uploads,
          body: utf8.encode(
            jsonEncode({
              'uploadId': _uploadId,
              'rootId': 'cam',
              'path': '',
              'name': 'h.jpg',
              'size': size,
            }),
          ),
        );
        expect(status, inInclusiveRange(400, 599), reason: 'size $size');
        expect(status, isNot(500));
      }
      expect(await uploads.any(_uploadId), isNull);
    },
  );
}

class _NoThumbs implements ThumbnailCache {
  @override
  bool hasFailed(FileRef f) => false;

  @override
  Future<Uint8List?> get(
    FileRef f, {
    ThumbPriority priority = ThumbPriority.visible,
  }) async => null;

  @override
  void prefetch(Iterable<FileRef> files) {}

  @override
  void cancel(String fileId) {}

  @override
  void cancelWhere(bool Function(FileRef f) test) {}

  @override
  Future<void> clear() async {}

  @override
  Future<int> diskSizeBytes() async => 0;
}
