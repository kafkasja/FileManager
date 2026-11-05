import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/file_hasher.dart';
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
final String _id = 'cd' * 16;

/// TASK-E1 throughput: fewer fsyncs (checkpoints), the hash made while the
/// bytes arrive, and moves that still read the part back (rule 10).
void main() {
  late ClientSessionStore sessions;
  late Directory staging;
  late Handler handler;
  late IssuedSession me;
  late int readBacks;
  late UploadStore uploads;
  late FakeFileSource files;
  var clock = DateTime(2026, 11, 5, 12);

  setUp(() async {
    staging = await Directory.systemTemp.createTemp('kfm_speed');
    sessions = ClientSessionStore();
    final scopes = ShareScopeStore(sessions: sessions);
    files = FakeFileSource()..addFolder('$_root/DCIM');
    uploads = UploadStore(staging: () async => staging, clock: () => clock);
    readBacks = 0;
    final guard = AllowListGuard(
      scopeOf: scopes.scopeOf,
      source: () => files,
      paths: fakeGuard(existing: {_root, '$_root/DCIM'}),
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
          addToIndex: (_) async {},
          stagingFreeBytes: () async => null,
          hashPath: (path) async {
            readBacks++;
            return await hashFileInIsolate(path);
          },
        ),
      ),
    );
    me = sessions.issue(
      clientFingerprint: 'fp',
      clientDeviceId: 'd',
      clientName: 'Pixel',
    );
    scopes.set(
      'fp',
      const ShareScope([
        SharedRoot(
          id: 'cam',
          path: '$_root/DCIM',
          label: 'DCIM',
          readOnly: false,
        ),
      ]),
    );
  });

  tearDown(() async {
    sessions.clear();
    await uploads.clear();
    await files.dispose();
    if (await staging.exists()) await staging.delete(recursive: true);
  });

  Future<Response> call(
    String method,
    String path, {
    Object? json,
    List<int>? bytes,
  }) => Future.value(
    handler(
      Request(
        method,
        Uri.parse('https://192.168.1.23:4433$path'),
        headers: {
          'authorization': 'Bearer ${me.token}',
          if (json != null) 'content-type': 'application/json',
          if (bytes != null) 'content-length': '${bytes.length}',
        },
        body: json != null ? jsonEncode(json) : bytes,
        context: {
          'shelf.io.connection_info': FakeConnectionInfo('192.168.1.40'),
        },
      ),
    ),
  );

  Future<Map<String, Object?>> body(Response r) async =>
      jsonDecode(await r.readAsString()) as Map<String, Object?>;

  int claimed() =>
      (jsonDecode(File('${staging.path}/up-$_id.json').readAsStringSync())
              as Map<String, Object?>)['received']!
          as int;

  Future<void> create(int size) async {
    final r = await call(
      'POST',
      ApiRoutes.uploads,
      json: CreateUploadDto(
        uploadId: _id,
        rootId: 'cam',
        path: '',
        name: 'cat.mp4',
        size: size,
      ).toJson(),
    );
    expect(r.statusCode, 201);
  }

  Future<void> chunk(int offset, List<int> bytes) async {
    final r = await call(
      'PUT',
      '${ApiRoutes.uploadChunk(_id)}?offset=$offset',
      bytes: bytes,
    );
    expect(r.statusCode, 200, reason: await r.readAsString());
  }

  test('the .json only claims checkpointed bytes; a restart resumes '
      'there', () async {
    await create(9);
    await chunk(0, [1, 2, 3]);
    // The first chunk is a checkpoint.
    expect(claimed(), 3);
    // Within 5 s and 64 MiB: no fsync, no .json rewrite.
    clock = clock.add(const Duration(seconds: 1));
    await chunk(3, [4, 5, 6]);
    expect(claimed(), 3);
    final r = await call('GET', ApiRoutes.upload(_id));
    expect(UploadStatusDto.fromJson(await body(r)).received, 6);
    // A crash now: a reload cuts the part back to what was claimed.
    final reloaded = UploadStore(staging: () async => staging);
    expect((await reloaded.any(_id))!.received, 3);
    expect(File('${staging.path}/up-$_id.part').lengthSync(), 3);
    // 5 s later the next chunk schedules one.
    clock = clock.add(const Duration(seconds: 5));
    await chunk(6, [7]);
    await uploads.ensureSynced((await uploads.any(_id))!);
    expect(claimed(), 7);
  });

  test('a copy is verified with the hash made while it arrived; a move '
      'reads the part back; a wrong hash still fails', () async {
    final bytes = List<int>.generate(5000, (i) => i % 251);
    final good = sha256.convert(bytes).toString();
    await create(bytes.length);
    await chunk(0, bytes.sublist(0, 3000));
    await chunk(3000, bytes.sublist(3000));
    var r = await call(
      'POST',
      ApiRoutes.uploadComplete(_id),
      json: CompleteUploadDto(sha256: good).toJson(),
    );
    expect(r.statusCode, 200);
    expect(readBacks, 0);

    final id2 = 'ef' * 16;
    for (final (id, sha, readBack) in [
      (id2, good, true),
      ('ab' * 16, 'f' * 64, false),
    ]) {
      final c = await call(
        'POST',
        ApiRoutes.uploads,
        json: CreateUploadDto(
          uploadId: id,
          rootId: 'cam',
          path: '',
          name: 'b.mp4',
          size: bytes.length,
        ).toJson(),
      );
      expect(c.statusCode, 201);
      final p = await call(
        'PUT',
        '${ApiRoutes.uploadChunk(id)}?offset=0',
        bytes: bytes,
      );
      expect(p.statusCode, 200);
      r = await call(
        'POST',
        ApiRoutes.uploadComplete(id),
        json: CompleteUploadDto(sha256: sha, readBack: readBack).toJson(),
      );
      if (readBack) {
        expect(r.statusCode, 200);
        expect(readBacks, 1);
      } else {
        expect(r.statusCode, 409);
        expect((await body(r))['code'], 'verification_failed');
      }
    }
  });

  test('the server takes 32 MiB chunks; a 4 MiB client still works', () {
    expect(kMaxTransferChunkBytes, 32 * 1024 * 1024);
    expect(kTransferChunkBytes, lessThanOrEqualTo(kMaxTransferChunkBytes));
    expect(
      CompleteUploadDto.fromJson(const {'sha256': 'a', 'readBack': true})
          .readBack,
      isTrue,
    );
    expect(CompleteUploadDto.fromJson(const {'sha256': 'a'}).readBack, isFalse);
  });
}
