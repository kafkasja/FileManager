import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/routes/upload_routes.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
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
final String _id = 'ab' * 16;

SharedRoot _r(String id, String rel, {bool readOnly = false}) =>
    SharedRoot(id: id, path: '$_root/$rel', label: rel, readOnly: readOnly);

void main() {
  late ClientSessionStore sessions;
  late ShareScopeStore scopes;
  late FakeFileSource files;
  late UploadStore uploads;
  late Directory staging;
  late Handler handler;
  late IssuedSession me;
  late IssuedSession other;
  late List<List<FileRef>> indexed;

  setUp(() async {
    staging = await Directory.systemTemp.createTemp('kfm_uploads');
    sessions = ClientSessionStore();
    scopes = ShareScopeStore(sessions: sessions);
    files = FakeFileSource()
      ..addFolder('$_root/DCIM')
      ..addFolder('$_root/Download');
    uploads = UploadStore(staging: () async => staging);
    indexed = [];
    final guard = AllowListGuard(
      scopeOf: scopes.scopeOf,
      source: () => files,
      paths: fakeGuard(existing: {_root, '$_root/DCIM', '$_root/Download'}),
    );
    handler = buildSharePipeline(
      served: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
      authenticate: authenticate(sessions),
      sizeLimitExempt: isUploadChunkRequest,
      routes: uploadRoutes(
        UploadRoutesEnv(
          guard: guard,
          sessions: sessions,
          uploads: uploads,
          source: () => files,
          addToIndex: (f) async => indexed.add(f),
          stagingFreeBytes: () async => null,
        ),
      ),
    );
    me = sessions.issue(
      clientFingerprint: 'fp',
      clientDeviceId: 'd',
      clientName: 'Pixel',
    );
    other = sessions.issue(
      clientFingerprint: 'fp2',
      clientDeviceId: 'd2',
      clientName: 'PC',
    );
    final scope = ShareScope([
      _r('cam', 'DCIM'),
      _r('dl', 'Download', readOnly: true),
    ]);
    scopes
      ..set('fp', scope)
      ..set('fp2', scope);
  });

  tearDown(() async {
    sessions.clear();
    await files.dispose();
    if (await staging.exists()) await staging.delete(recursive: true);
  });

  Future<Response> call(
    String method,
    String path, {
    Object? json,
    List<int>? bytes,
    Stream<List<int>>? stream,
    int? length,
    IssuedSession? as,
  }) async {
    final token = (as ?? me).token;
    return await handler(
      Request(
        method,
        Uri.parse('https://192.168.1.23:4433$path'),
        headers: {
          'authorization': 'Bearer $token',
          if (json != null) 'content-type': 'application/json',
          if (bytes != null) 'content-length': '${length ?? bytes.length}',
          if (stream != null) 'content-length': '$length',
        },
        body: json != null ? jsonEncode(json) : (bytes ?? stream),
        context: {
          'shelf.io.connection_info': FakeConnectionInfo('192.168.1.40'),
        },
      ),
    );
  }

  Future<Map<String, Object?>> body(Response r) async {
    final text = await r.readAsString();
    return text.isEmpty ? const {} : jsonDecode(text) as Map<String, Object?>;
  }

  Future<String?> code(Response r) async => (await body(r))['code'] as String?;

  Map<String, Object?> create({
    String? id,
    String rootId = 'cam',
    String path = '',
    String name = 'a.jpg',
    int size = 5,
  }) => CreateUploadDto(
    uploadId: id ?? _id,
    rootId: rootId,
    path: path,
    name: name,
    size: size,
  ).toJson();

  File part(String id) => File('${staging.path}/up-$id.part');

  test('create → chunks → complete publishes the file; partial gone', () async {
    var r = await call('POST', ApiRoutes.uploads, json: create());
    expect(r.statusCode, 201);
    expect(UploadStatusDto.fromJson(await body(r)).received, 0);
    expect(await part(_id).exists(), isTrue);

    r = await call(
      'PUT',
      '${ApiRoutes.uploadChunk(_id)}?offset=0',
      bytes: [1, 2, 3],
    );
    expect(r.statusCode, 200);
    expect(UploadStatusDto.fromJson(await body(r)).received, 3);
    r = await call(
      'PUT',
      '${ApiRoutes.uploadChunk(_id)}?offset=3',
      bytes: [4, 5],
    );
    expect(UploadStatusDto.fromJson(await body(r)).received, 5);

    r = await call('POST', ApiRoutes.uploadComplete(_id), json: const {});
    expect(r.statusCode, 200);
    final done = UploadCompletedDto.fromJson(await body(r));
    expect(done.finalId, 'path:$_root/DCIM/a.jpg');
    final out = await files.stat(done.finalId);
    expect(out?.sizeBytes, 5);
    expect(await part(_id).exists(), isFalse);
    expect(File('${staging.path}/up-$_id.json').existsSync(), isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(indexed.single.single.id, done.finalId);
  });

  test('a read-only or unknown root is refused (403)', () async {
    final r1 = await call(
      'POST',
      ApiRoutes.uploads,
      json: create(rootId: 'dl'),
    );
    expect(r1.statusCode, 403);
    expect(await code(r1), 'forbidden_path');
    final r2 = await call(
      'POST',
      ApiRoutes.uploads,
      json: create(rootId: 'nope'),
    );
    expect(r2.statusCode, 403);
    expect(staging.listSync(), isEmpty);
  });

  test('peer names are checked: invalid_name, nothing written', () async {
    for (final bad in ['a/b.jpg', '..', '.nomedia', 'x' * 300, '']) {
      final r = await call('POST', ApiRoutes.uploads, json: create(name: bad));
      expect(r.statusCode, 400, reason: bad);
      expect(await code(r), 'invalid_name');
    }
    // An upload id that isn't 32 hex (it names the partial) is refused.
    final r = await call(
      'POST',
      ApiRoutes.uploads,
      json: create(id: '../../evil'),
    );
    expect(r.statusCode, 403);
    expect(staging.listSync(), isEmpty);
  });

  test('not enough space: 507, nothing partial left', () async {
    files.freeBytesValue = 10;
    final r = await call('POST', ApiRoutes.uploads, json: create());
    expect(r.statusCode, 507);
    expect(await code(r), 'insufficient_storage');
    expect(staging.listSync(), isEmpty);
  });

  test("another client can't append, complete or delete (404)", () async {
    await call('POST', ApiRoutes.uploads, json: create());
    final chunk = await call(
      'PUT',
      '${ApiRoutes.uploadChunk(_id)}?offset=0',
      bytes: [1],
      as: other,
    );
    expect(chunk.statusCode, 404);
    final complete = await call(
      'POST',
      ApiRoutes.uploadComplete(_id),
      json: const {},
      as: other,
    );
    expect(complete.statusCode, 404);
    final delete = await call('DELETE', ApiRoutes.upload(_id), as: other);
    expect(delete.statusCode, 404);
    expect(await part(_id).exists(), isTrue);
    // The same id can't be taken over either.
    final again = await call(
      'POST',
      ApiRoutes.uploads,
      json: create(),
      as: other,
    );
    expect(again.statusCode, 409);
  });

  test('offset must match; complete needs every byte; chunk cap', () async {
    await call('POST', ApiRoutes.uploads, json: create());
    final wrong = await call(
      'PUT',
      '${ApiRoutes.uploadChunk(_id)}?offset=2',
      bytes: [1],
    );
    expect(wrong.statusCode, 409);
    final early = await call(
      'POST',
      ApiRoutes.uploadComplete(_id),
      json: const {},
    );
    expect(early.statusCode, 409);
    final huge = await call(
      'PUT',
      '${ApiRoutes.uploadChunk(_id)}?offset=0',
      stream: Stream.value([1]),
      length: kTransferChunkBytes + 1,
    );
    expect(huge.statusCode, 413);
    final tooMuch = await call(
      'PUT',
      '${ApiRoutes.uploadChunk(_id)}?offset=0',
      bytes: [1, 2, 3, 4, 5, 6],
    );
    expect(tooMuch.statusCode, 413);
  });

  test('delete (cancel) removes the partial', () async {
    await call('POST', ApiRoutes.uploads, json: create());
    await call('PUT', '${ApiRoutes.uploadChunk(_id)}?offset=0', bytes: [1]);
    final r = await call('DELETE', ApiRoutes.upload(_id));
    expect(r.statusCode, 204);
    expect(staging.listSync(), isEmpty);
    final after = await call(
      'PUT',
      '${ApiRoutes.uploadChunk(_id)}?offset=1',
      bytes: [2],
    );
    expect(after.statusCode, 404);
  });

  test('Disconnect mid-chunk cancels it; the partial is cut back', () async {
    await call('POST', ApiRoutes.uploads, json: create(size: 10));
    final body = StreamController<List<int>>();
    final pending = call(
      'PUT',
      '${ApiRoutes.uploadChunk(_id)}?offset=0',
      stream: body.stream,
      length: 10,
    );
    body.add([1, 2, 3]);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(sessions.streamsOf(me.session.sessionId), hasLength(1));
    sessions.revoke(me.session.sessionId);
    final r = await pending;
    expect(r.statusCode, 410);
    expect(await part(_id).length(), 0);
    await body.close();
  });

  test('stop sharing deletes every partial, leftovers too', () async {
    await call('POST', ApiRoutes.uploads, json: create());
    File('${staging.path}/up-${'cd' * 16}.part').writeAsBytesSync([1]);
    await uploads.clear();
    expect(staging.listSync(), isEmpty);
  });
}
