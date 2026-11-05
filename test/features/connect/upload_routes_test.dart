import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
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
  late Handler Function(UploadStore store) rebuild;

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
    rebuild = (store) => buildSharePipeline(
      served: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
      authenticate: authenticate(sessions),
      sizeLimitExempt: isUploadChunkRequest,
      routes: uploadRoutes(
        UploadRoutesEnv(
          // These check the read-back hash (E1: copies skip it).
          streamingHash: false,
          guard: guard,
          sessions: sessions,
          uploads: store,
          source: () => files,
          addToIndex: (f) async => indexed.add(f),
          stagingFreeBytes: () async => null,
          // Free space on every chunk (E1 checks every 256 MiB).
          spaceCheckBytes: 0,
        ),
      ),
    );
    handler = rebuild(uploads);
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
    final status = await call('GET', ApiRoutes.upload(_id), as: other);
    expect(status.statusCode, 404);
    // The same id can't be taken over either (and isn't revealed).
    final again = await call(
      'POST',
      ApiRoutes.uploads,
      json: create(),
      as: other,
    );
    expect(again.statusCode, 404);
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

  test('clear deletes every partial, leftovers too', () async {
    await call('POST', ApiRoutes.uploads, json: create());
    File('${staging.path}/up-${'cd' * 16}.part').writeAsBytesSync([1]);
    await uploads.clear();
    expect(staging.listSync(), isEmpty);
  });

  group('N10 resume', () {
    test('create is idempotent for its owner; other details are a '
        'conflict', () async {
      await call('POST', ApiRoutes.uploads, json: create());
      await call('PUT', '${ApiRoutes.uploadChunk(_id)}?offset=0', bytes: [1]);
      final again = await call('POST', ApiRoutes.uploads, json: create());
      expect(again.statusCode, 200);
      final st = UploadStatusDto.fromJson(await body(again));
      expect(st.received, 1);
      expect(st.size, 5);
      final other = await call(
        'POST',
        ApiRoutes.uploads,
        json: create(name: 'b.jpg'),
      );
      expect(other.statusCode, 409);
    });

    test('GET status tells where to resume; a restart reloads it from the '
        '.json and cuts an unconfirmed tail', () async {
      await call('POST', ApiRoutes.uploads, json: create());
      await call(
        'PUT',
        '${ApiRoutes.uploadChunk(_id)}?offset=0',
        bytes: [1, 2],
      );
      var r = await call('GET', ApiRoutes.upload(_id));
      expect(r.statusCode, 200);
      expect(UploadStatusDto.fromJson(await body(r)).received, 2);
      final meta = jsonDecode(
        File('${staging.path}/up-$_id.json').readAsStringSync(),
      ) as Map<String, Object?>;
      expect(meta['received'], 2);
      expect(meta['ownerFingerprint'], 'fp');
      // A crash after bytes were written but before the .json said so.
      part(_id).writeAsBytesSync([1, 2, 9, 9], flush: true);
      final reloaded = UploadStore(staging: () async => staging);
      handler = rebuild(reloaded);
      r = await call('GET', ApiRoutes.upload(_id));
      expect(UploadStatusDto.fromJson(await body(r)).received, 2);
      expect(part(_id).readAsBytesSync(), [1, 2]);
      r = await call(
        'PUT',
        '${ApiRoutes.uploadChunk(_id)}?offset=2',
        bytes: [3, 4, 5],
      );
      expect(UploadStatusDto.fromJson(await body(r)).received, 5);
      r = await call('POST', ApiRoutes.uploadComplete(_id), json: const {});
      expect(r.statusCode, 200);
      expect(
        files.bytesOf(UploadCompletedDto.fromJson(await body(r)).finalId),
        [1, 2, 3, 4, 5],
      );
    });

    test("the owner's new chunk ends a hanging one and takes over", () async {
      await call('POST', ApiRoutes.uploads, json: create(size: 4));
      final hanging = StreamController<List<int>>();
      final first = call(
        'PUT',
        '${ApiRoutes.uploadChunk(_id)}?offset=0',
        stream: hanging.stream,
        length: 4,
      );
      hanging.add([1, 2]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final second = await call(
        'PUT',
        '${ApiRoutes.uploadChunk(_id)}?offset=0',
        bytes: [1, 2, 3, 4],
      );
      expect(second.statusCode, 200);
      expect(UploadStatusDto.fromJson(await body(second)).received, 4);
      expect((await first).statusCode, 410);
      expect(part(_id).readAsBytesSync(), [1, 2, 3, 4]);
      await hanging.close();
    });

    test('stop sharing keeps partials; removing the owner or 7 days without '
        'a chunk deletes them', () async {
      await call('POST', ApiRoutes.uploads, json: create());
      uploads.stop();
      sessions.clear();
      expect(await part(_id).exists(), isTrue);
      await uploads.removeOwner('fp2');
      expect(await part(_id).exists(), isTrue);
      await uploads.removeOwner('fp');
      expect(staging.listSync(), isEmpty);

      final id2 = 'ef' * 16;
      final store = UploadStore(staging: () async => staging);
      await store.create(
        uploadId: id2,
        ownerFingerprint: 'fp',
        rootId: 'cam',
        path: '',
        name: 'a.jpg',
        size: 5,
      );
      final later = UploadStore(
        staging: () async => staging,
        clock: () => DateTime.now().add(const Duration(days: 8)),
      );
      await later.purgeStale();
      expect(staging.listSync(), isEmpty);
    });

    test('free space is checked again during the upload (507)', () async {
      await call('POST', ApiRoutes.uploads, json: create());
      files.freeBytesValue = 10;
      final r = await call(
        'PUT',
        '${ApiRoutes.uploadChunk(_id)}?offset=0',
        bytes: [1],
      );
      expect(r.statusCode, 507);
      expect(part(_id).lengthSync(), 0);
    });
  });

  group('N11 verify', () {
    final good = sha256.convert([1, 2, 3, 4, 5]).toString();

    Future<void> sendAll() async {
      await call('POST', ApiRoutes.uploads, json: create());
      await call(
        'PUT',
        '${ApiRoutes.uploadChunk(_id)}?offset=0',
        bytes: [1, 2, 3, 4, 5],
      );
    }

    test('complete {sha256} checks the part and the published file and '
        'answers the final hash; a repeat gets the same answer', () async {
      await sendAll();
      var r = await call(
        'POST',
        ApiRoutes.uploadComplete(_id),
        json: CompleteUploadDto(sha256: good).toJson(),
      );
      expect(r.statusCode, 200);
      final done = UploadCompletedDto.fromJson(await body(r));
      expect(done.sha256, good);
      expect(await files.stat(done.finalId), isNotNull);
      // The answer was lost: status says everything is there, a repeated
      // complete returns the same file (no second copy).
      r = await call('GET', ApiRoutes.upload(_id));
      expect(r.statusCode, 200);
      expect(UploadStatusDto.fromJson(await body(r)).received, 5);
      r = await call(
        'POST',
        ApiRoutes.uploadComplete(_id),
        json: CompleteUploadDto(sha256: good).toJson(),
      );
      expect(UploadCompletedDto.fromJson(await body(r)).finalId, done.finalId);
      expect(
        files.files.where((f) => f.folderPath.endsWith('DCIM')),
        hasLength(1),
      );
      // Not for another client.
      r = await call('GET', ApiRoutes.upload(_id), as: other);
      expect(r.statusCode, 404);
    });

    test('a wrong hash: 409 verification_failed, nothing published, the '
        'partial is gone', () async {
      await sendAll();
      final r = await call(
        'POST',
        ApiRoutes.uploadComplete(_id),
        json: CompleteUploadDto(sha256: 'f' * 64).toJson(),
      );
      expect(r.statusCode, 409);
      expect(await code(r), 'verification_failed');
      expect(await files.statPath('$_root/DCIM/a.jpg'), isNull);
      expect(await part(_id).exists(), isFalse);
    });

    test(
      'the published file reads back different: it is deleted, 409',
      () async {
        handler = buildSharePipeline(
          served: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
          authenticate: authenticate(sessions),
          sizeLimitExempt: isUploadChunkRequest,
          routes: uploadRoutes(
            UploadRoutesEnv(
              // These check the read-back hash (E1: copies skip it).
              streamingHash: false,
              spaceCheckBytes: 0,
              guard: AllowListGuard(
                scopeOf: scopes.scopeOf,
                source: () => files,
                paths: fakeGuard(
                  existing: {_root, '$_root/DCIM', '$_root/Download'},
                ),
              ),
              sessions: sessions,
              uploads: uploads,
              source: () => files,
              addToIndex: (f) async => indexed.add(f),
              stagingFreeBytes: () async => null,
              hashFile: (f, s) async => 'e' * 64,
            ),
          ),
        );
        await sendAll();
        final r = await call(
          'POST',
          ApiRoutes.uploadComplete(_id),
          json: CompleteUploadDto(sha256: good).toJson(),
        );
        expect(r.statusCode, 409);
        expect(await files.statPath('$_root/DCIM/a.jpg'), isNull);
        expect(
          files.calls.where((c) => c.startsWith('deletePermanentlyBatch')),
          hasLength(1),
        );
      },
    );
  });

  group('Q8 complete and space', () {
    final good = sha256.convert([1, 2, 3, 4, 5]).toString();
    late int partHashes;
    late int copyHashes;
    Completer<void>? gate;

    Handler build({
      UploadPublish publish = UploadPublish.copy,
      Future<int?> Function()? stagingFree,
    }) => buildSharePipeline(
      served: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
      authenticate: authenticate(sessions),
      sizeLimitExempt: isUploadChunkRequest,
      routes: uploadRoutes(
        UploadRoutesEnv(
          // These check the read-back hash (E1: copies skip it).
          streamingHash: false,
          spaceCheckBytes: 0,
          guard: AllowListGuard(
            scopeOf: scopes.scopeOf,
            source: () => files,
            paths: fakeGuard(
              existing: {_root, '$_root/DCIM', '$_root/Download'},
            ),
          ),
          sessions: sessions,
          uploads: uploads,
          source: () => files,
          addToIndex: (f) async => indexed.add(f),
          stagingFreeBytes: stagingFree ?? () async => null,
          hashPath: (path) async {
            partHashes++;
            await gate?.future;
            return sha256.convert(await File(path).readAsBytes()).toString();
          },
          hashFile: (f, s) async {
            copyHashes++;
            return sha256.convert(files.bytesOf(f.id)!).toString();
          },
          publishMode: (_) async => publish,
        ),
      ),
    );

    setUp(() {
      partHashes = 0;
      copyHashes = 0;
      gate = null;
    });

    Future<void> sendAll() async {
      await call('POST', ApiRoutes.uploads, json: create());
      await call(
        'PUT',
        '${ApiRoutes.uploadChunk(_id)}?offset=0',
        bytes: [1, 2, 3, 4, 5],
      );
    }

    Future<void> until(bool Function() done) async {
      for (var i = 0; i < 200 && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }

    test('a repeated complete while the first still runs (the link dropped '
        'during the hash) waits for it: one file, the same answer, and the '
        'completion is remembered afterwards', () async {
      handler = build();
      await sendAll();
      gate = Completer<void>();
      final first = call(
        'POST',
        ApiRoutes.uploadComplete(_id),
        json: CompleteUploadDto(sha256: good).toJson(),
      );
      await until(() => partHashes == 1);
      // The client's view: status says every byte is there, so it asks
      // to complete again.
      var r = await call('GET', ApiRoutes.upload(_id));
      expect(UploadStatusDto.fromJson(await body(r)).received, 5);
      final second = call(
        'POST',
        ApiRoutes.uploadComplete(_id),
        json: CompleteUploadDto(sha256: good).toJson(),
      );
      // Cancel (DELETE) can't pull the upload away mid-publish either.
      r = await call('DELETE', ApiRoutes.upload(_id));
      expect(await code(r), 'busy');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      gate!.complete();
      final a = await first;
      final b = await second;
      expect(a.statusCode, 200);
      expect(b.statusCode, 200);
      final da = UploadCompletedDto.fromJson(await body(a));
      final db = UploadCompletedDto.fromJson(await body(b));
      expect(db.finalId, da.finalId);
      expect(db.sha256, good);
      expect(partHashes, 1, reason: 'published once');
      expect(
        files.files
            .where((f) => f.folderPath.endsWith('DCIM'))
            .map((f) => f.name),
        ['a.jpg'],
      );
      // A third ask after both answers were lost: remembered, no 404.
      r = await call('GET', ApiRoutes.upload(_id));
      expect(r.statusCode, 200);
      r = await call(
        'POST',
        ApiRoutes.uploadComplete(_id),
        json: CompleteUploadDto(sha256: good).toJson(),
      );
      expect(UploadCompletedDto.fromJson(await body(r)).finalId, da.finalId);
    });

    test(
      'a part that fails to read keeps the upload (asked again later)',
      () async {
        handler = buildSharePipeline(
          served: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
          authenticate: authenticate(sessions),
          sizeLimitExempt: isUploadChunkRequest,
          routes: uploadRoutes(
            UploadRoutesEnv(
              // These check the read-back hash (E1: copies skip it).
              streamingHash: false,
              spaceCheckBytes: 0,
              guard: AllowListGuard(
                scopeOf: scopes.scopeOf,
                source: () => files,
                paths: fakeGuard(existing: {_root, '$_root/DCIM'}),
              ),
              sessions: sessions,
              uploads: uploads,
              source: () => files,
              addToIndex: (f) async {},
              stagingFreeBytes: () async => null,
              hashPath: (_) async => throw const FileSystemException('busy'),
            ),
          ),
        );
        await sendAll();
        final r = await call(
          'POST',
          ApiRoutes.uploadComplete(_id),
          json: CompleteUploadDto(sha256: good).toJson(),
        );
        expect(r.statusCode, 500);
        expect(part(_id).lengthSync(), 5);
        final st = await call('GET', ApiRoutes.upload(_id));
        expect(UploadStatusDto.fromJson(await body(st)).received, 5);
      },
    );

    test(
      'an atomic rename skips the read-back hash; a copy is hashed',
      () async {
        handler = build(publish: UploadPublish.rename);
        await sendAll();
        var r = await call(
          'POST',
          ApiRoutes.uploadComplete(_id),
          json: CompleteUploadDto(sha256: good).toJson(),
        );
        expect(UploadCompletedDto.fromJson(await body(r)).sha256, good);
        expect((partHashes, copyHashes), (1, 0));

        final id2 = 'cd' * 16;
        handler = build();
        await call(
          'POST',
          ApiRoutes.uploads,
          json: create(id: id2, name: 'b.jpg'),
        );
        await call(
          'PUT',
          '${ApiRoutes.uploadChunk(id2)}?offset=0',
          bytes: [1, 2, 3, 4, 5],
        );
        r = await call(
          'POST',
          ApiRoutes.uploadComplete(id2),
          json: CompleteUploadDto(sha256: good).toJson(),
        );
        expect(r.statusCode, 200);
        expect((partHashes, copyHashes), (2, 1));
      },
    );

    test('publishing by copy within the same free space needs the size twice '
        '(507 before any byte is sent); a rename or another volume needs it '
        'once', () async {
      const mb = 1024 * 1024;
      const size = 100 * mb;
      // 200 MB free on the phone's storage: the 100 MB partial + 64 MB
      // margin fits, the 100 MB publish copy on top does not.
      files.freeBytesValue = 200 * mb;
      Map<String, Object?> big(String id) =>
          create(id: id, name: 'f$id.bin', size: size);

      handler = build(stagingFree: () async => 200 * mb);
      var r = await call('POST', ApiRoutes.uploads, json: big('a1' * 16));
      expect(r.statusCode, 507);
      expect(part('a1' * 16).existsSync(), isFalse);

      handler = build(
        publish: UploadPublish.rename,
        stagingFree: () async => 200 * mb,
      );
      r = await call('POST', ApiRoutes.uploads, json: big('a2' * 16));
      expect(r.statusCode, 201);

      // Staging on another volume (e.g. an SD card target): each side once.
      handler = build(stagingFree: () async => 5000 * mb);
      r = await call('POST', ApiRoutes.uploads, json: big('a3' * 16));
      expect(r.statusCode, 201);

      // Checked per chunk too.
      handler = build(stagingFree: () async => 200 * mb);
      r = await call(
        'PUT',
        '${ApiRoutes.uploadChunk('a3' * 16)}?offset=0',
        bytes: [1],
      );
      expect(r.statusCode, 507);
    });

    test('uploadPublishFor: Android copies; Windows renames on the same '
        'drive', () {
      expect(
        uploadPublishFor(
          '/storage/emulated/0/Android/data/com.kaf.kfm/files/transfers',
          '/storage/emulated/0/Download',
          isAndroid: true,
          isWindows: false,
        ),
        UploadPublish.copy,
      );
      expect(
        uploadPublishFor(
          r'C:\Users\k\AppData\Roaming\Kaf\KFM\transfers',
          'c:/Users/k/Pictures',
          isAndroid: false,
          isWindows: true,
        ),
        UploadPublish.rename,
      );
      expect(
        uploadPublishFor(
          r'C:\Users\k\AppData\Roaming\Kaf\KFM\transfers',
          'E:/Photos',
          isAndroid: false,
          isWindows: true,
        ),
        UploadPublish.copyOtherVolume,
      );
      expect(
        uploadPublishFor(
          r'C:\x',
          '//server/share',
          isAndroid: false,
          isWindows: true,
        ),
        UploadPublish.copy,
      );
    });
  });
}
