import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/connect/data/known_devices_dao.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_file_id.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/session/domain/session_source.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/transfers/data/swipe_sends.dart';
import 'package:kfm/features/transfers/data/transfer_engine.dart';
import 'package:kfm/features/transfers/data/transfers_dao.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:kfm/features/transfers/domain/transfer_preprocessor.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

import '../../core/files/fake_file_source.dart';

final String _fp = 'ab' * 32;
const _dl = '/storage/emulated/0/Download/Phone';

/// A content response the test feeds by hand (hold = an in-flight file).
class _Held extends Stream<List<int>> implements HttpClientResponse {
  new(this.contentLength);

  final StreamController<List<int>> c = StreamController<List<int>>();
  bool cancelled = false;

  @override
  final int contentLength;

  @override
  int get statusCode => 200;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    c.onCancel = () => cancelled = true;
    return c.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

typedef _Call = ({
  String method,
  String path,
  Map<String, String> query,
  Object? body,
});

/// The other device: per-prefix JSON answers, held content streams.
class _Http implements RemoteHttp {
  final List<_Call> calls = [];
  final Map<String, _Held> held = {};
  final Map<String, List<int>> contents = {};
  final Map<String, ApiErrorCode> failContent = {};
  Map<String, Object?> Function(_Call call)? json;

  int running = 0;
  int maxRunning = 0;

  @override
  Uri get base => Uri.parse('https://192.168.1.20:4433');

  @override
  String? bearerToken;

  Future<T> _json<T>(
    String method,
    String path,
    Object? body,
    T Function(Map<String, Object?>) decode, [
    Map<String, String> query = const {},
  ]) async {
    final call = (method: method, path: path, query: query, body: body);
    calls.add(call);
    return decode(json?.call(call) ?? const {});
  }

  @override
  Future<T> getJson<T>(
    String path, {
    required T Function(Map<String, Object?> json) decode,
    Map<String, String> query = const {},
  }) => _json('GET', path, null, decode, query);

  @override
  Future<T> postJson<T>(
    String path,
    Object? body, {
    required T Function(Map<String, Object?> json) decode,
    Duration? timeout,
  }) => _json('POST', path, body, decode);

  @override
  Future<T> deleteJson<T>(
    String path, {
    required T Function(Map<String, Object?> json) decode,
  }) => _json('DELETE', path, null, decode);

  @override
  Future<T> putStream<T>(
    String path,
    Stream<List<int>> body,
    int length, {
    required T Function(Map<String, Object?> json) decode,
    Map<String, String> query = const {},
  }) async {
    final bytes = <int>[];
    await body.forEach(bytes.addAll);
    return await _json('PUT', path, bytes, decode, query);
  }

  @override
  Future<HttpClientResponse> getStream(
    String path, {
    Map<String, String> query = const {},
    Map<String, String> headers = const {},
  }) async {
    calls.add((method: 'GET', path: path, query: query, body: null));
    final serverId = Uri.decodeComponent(path.split('/')[3]);
    if (failContent[serverId] case final code?) {
      throw RemoteApiException(code.status, ApiErrorDto(code.wire, ''));
    }
    running++;
    if (running > maxRunning) maxRunning = running;
    final h = held[serverId];
    if (h != null) {
      unawaited(h.c.done.whenComplete(() => running--));
      return h;
    }
    final bytes = contents[serverId] ?? const [];
    final r = _Held(bytes.length);
    unawaited(() async {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      r.c.add(bytes);
      running--;
      await r.c.close();
    }());
    return r;
  }

  @override
  void close() {}
}

FileRef _remote(String serverId, {int size = 3, String? name}) => FileRef(
  id: remoteFileId(_fp, serverId),
  uri: 'remote://x',
  name: name ?? '${serverId.replaceAll(':', '')}.jpg',
  kind: FileKind.image,
  sizeBytes: size,
  modifiedAt: DateTime.utc(2026),
  folderPath: 'cam',
  origin: FileOrigin.remote,
);

void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late TransfersRepository repo;
  late KnownDevicesRepository devices;
  late FakeFileSource local;
  late _Http http;
  late Directory staging;
  late TransferEngine engine;
  late List<List<FileRef>> indexed;
  RemoteHttp? connected;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    repo = TransfersRepository(TransfersDao(db), queue);
    devices = KnownDevicesRepository(KnownDevicesDao(db), queue);
    local = FakeFileSource()..addFolder(_dl);
    http = _Http();
    connected = http;
    indexed = [];
    staging = await Directory.systemTemp.createTemp('kfm_engine');
    engine = TransferEngine(
      repo: repo,
      devices: devices,
      local: local,
      http: (fp) => fp == _fp ? connected : null,
      staging: () async => staging,
      preprocessor: const IdentityPreprocessor(),
      addToIndex: (f) async => indexed.add(f),
      liveInterval: const Duration(milliseconds: 20),
    );
    await engine.start();
    engine.onConnection(_fp);
  });

  tearDown(() async {
    await engine.dispose();
    await queue.close();
    await db.close();
    await local.dispose();
    if (await staging.exists()) await staging.delete(recursive: true);
  });

  Future<TransferJob> until(
    String id,
    bool Function(TransferJob j) test, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final end = DateTime.now().add(timeout);
    while (true) {
      await queue.flush();
      final job = await repo.dao.job(id);
      if (job != null && test(job)) return job;
      if (DateTime.now().isAfter(end)) {
        fail(
          'timed out: ${job?.status} ${job?.files.map((f) => '${f.status.name}:${f.error}')}',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  List<String> parts() => [
    for (final e in staging.listSync()) e.uri.pathSegments.last,
  ];

  group('downloads', () {
    test('2 at a time, seq order; all land in the folder; no partials '
        'left', () async {
      for (var i = 0; i < 4; i++) {
        http.contents['ms:$i'] = [i, i, i];
      }
      final id = await engine.enqueueDownload(
        [for (var i = 0; i < 4; i++) _remote('ms:$i')],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      final job = await until(id, (j) => j.status == TransferStatus.done);
      expect(http.maxRunning, 2);
      final order = [
        for (final c in http.calls)
          if (c.method == 'GET') Uri.decodeComponent(c.path.split('/')[3]),
      ];
      expect(order, ['ms:0', 'ms:1', 'ms:2', 'ms:3']);
      for (var i = 0; i < 4; i++) {
        expect((await local.stat('path:$_dl/ms$i.jpg'))?.sizeBytes, 3);
      }
      expect(job.files.map((f) => f.targetFileId), everyElement(isNotNull));
      expect(parts(), isEmpty);
      expect(indexed, hasLength(4));
      // Not remembered before: a temporary row now exists for the job.
      final row = await devices.byFingerprint(_fp);
      expect(row?.isTemporary, isTrue);
    });

    test('cancel: running and queued files end, finished stay, no '
        'partials', () async {
      http
        ..contents['ms:0'] = [1, 2, 3]
        ..held['ms:1'] = _Held(10)
        ..held['ms:2'] = _Held(10);
      final id = await engine.enqueueDownload(
        [
          _remote('ms:0'),
          _remote('ms:1', size: 10),
          _remote('ms:2', size: 10),
          _remote('ms:3'),
        ],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      await until(id, (j) => j.files[0].status == TransferFileStatus.done);
      http.held['ms:1']!.c.add([1, 2, 3, 4]);
      await until(
        id,
        (j) =>
            j.files[1].status == TransferFileStatus.running &&
            j.files[2].status == TransferFileStatus.running,
      );
      expect(parts(), isNotEmpty);
      await engine.cancelJob(id);
      final job = await until(id, (j) => j.status == TransferStatus.cancelled);
      expect(job.files.map((f) => f.status), [
        TransferFileStatus.done,
        TransferFileStatus.cancelled,
        TransferFileStatus.cancelled,
        TransferFileStatus.cancelled,
      ]);
      expect(http.held['ms:1']!.cancelled, isTrue);
      expect(await local.stat('path:$_dl/ms0.jpg'), isNotNull);
      expect(await local.stat('path:$_dl/ms1.jpg'), isNull);
      // Let the cancelled runs clean up.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(parts(), isEmpty);
    });

    test('a failure keeps going; Retry restarts from 0', () async {
      http
        ..failContent['ms:0'] = ApiErrorCode.notFound
        ..contents['ms:0'] = [9, 9]
        ..contents['ms:1'] = [1];
      final id = await engine.enqueueDownload(
        [_remote('ms:0', size: 2), _remote('ms:1', size: 1)],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      var job = await until(id, (j) => j.isFinished);
      expect(job.status, TransferStatus.failed);
      expect(job.files[0].error, 'not_found');
      expect(job.files[1].status, TransferFileStatus.done);
      http.failContent.clear();
      await engine.retry(id);
      job = await until(id, (j) => j.status == TransferStatus.done);
      expect(job.files[0].attempts, 2);
      expect((await local.stat('path:$_dl/ms0.jpg'))?.sizeBytes, 2);
    });

    test('a peer file name that escapes the folder fails invalid_name; '
        'nothing is written', () async {
      http.contents['ms:0'] = [1];
      final id = await engine.enqueueDownload(
        [_remote('ms:0', name: 'a/b.jpg'), _remote('ms:1', name: '..')],
        peerFingerprint: _fp,
        peerName: '../evil',
        localFolder: defaultDownloadFolder(
          '/storage/emulated/0/Download',
          '../evil',
        ),
      );
      final job = await until(id, (j) => j.isFinished);
      expect(job.files.map((f) => f.error), ['invalid_name', 'invalid_name']);
      expect(job.targetPath, '/storage/emulated/0/Download/_evil');
      expect(local.calls.where((c) => c.startsWith('importFile')), isEmpty);
      expect(parts(), isEmpty);
    });

    test('not enough space here: failed before anything is fetched', () async {
      local.freeBytesValue = 1000;
      final id = await engine.enqueueDownload(
        [_remote('ms:0')],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      final job = await until(id, (j) => j.isFinished);
      expect(job.files.single.error, TransferErrors.noSpaceHere);
      expect(http.calls.where((c) => c.method == 'GET'), isEmpty);
    });

    test('the device leaves mid-file: failed, no crash', () async {
      http.held['ms:0'] = _Held(10);
      final id = await engine.enqueueDownload(
        [_remote('ms:0', size: 10)],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      await until(
        id,
        (j) => j.files.single.status == TransferFileStatus.running,
      );
      http.held['ms:0']!.c.addError(
        const RemoteUnavailableException(RemoteUnavailableReason.network),
      );
      final job = await until(id, (j) => j.isFinished);
      expect(job.files.single.error, TransferErrors.unavailable);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(parts(), isEmpty);
    });

    test('queued while not connected; starts on the next connection', () async {
      connected = null;
      engine.onConnection(null);
      http.contents['ms:0'] = [1];
      final id = await engine.enqueueDownload(
        [_remote('ms:0', size: 1)],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect((await repo.dao.job(id))!.status, TransferStatus.queued);
      connected = http;
      engine.onConnection(_fp);
      await until(id, (j) => j.status == TransferStatus.done);
    });
  });

  group('uploads', () {
    test('create → chunk → complete; the final id is stored', () async {
      final f = local.addFile(
        '/storage/emulated/0/DCIM/a.jpg',
        bytes: [1, 2, 3, 4],
      );
      http.json = (c) => switch (c.method) {
        'PUT' => {'received': 4},
        'POST' when c.path.endsWith('/complete') => {'finalId': 'ms:77'},
        _ => {'received': 0},
      };
      final id = await engine.enqueueUpload(
        [f],
        peerFingerprint: _fp,
        peerName: 'PC',
        rootId: 'cam',
        path: 'sub',
      );
      final job = await until(id, (j) => j.status == TransferStatus.done);
      expect(job.files.single.targetFileId, 'ms:77');
      final create = http.calls.firstWhere((c) => c.path == ApiRoutes.uploads);
      expect(create.body, containsPair('rootId', 'cam'));
      expect(create.body, containsPair('path', 'sub'));
      expect(create.body, containsPair('name', 'a.jpg'));
      expect(create.body, containsPair('size', 4));
      final put = http.calls.firstWhere((c) => c.method == 'PUT');
      expect(put.body, [1, 2, 3, 4]);
      expect(put.query, {'offset': '0'});
      expect(http.calls.where((c) => c.method == 'DELETE'), isEmpty);
    });

    test('a refused upload (403) fails "forbidden_path" and the partial '
        'is deleted on the other device', () async {
      final f = local.addFile('/storage/emulated/0/DCIM/a.jpg');
      http.json = (c) {
        if (c.method == 'PUT') {
          throw RemoteApiException(
            403,
            ApiErrorDto(ApiErrorCode.forbiddenPath.wire, ''),
          );
        }
        return {'received': 0};
      };
      final id = await engine.enqueueUpload(
        [f],
        peerFingerprint: _fp,
        peerName: 'PC',
        rootId: 'cam',
        path: '',
      );
      final job = await until(id, (j) => j.isFinished);
      expect(job.files.single.error, 'forbidden_path');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        http.calls.where((c) => c.method == 'DELETE').single.path,
        startsWith('/v1/uploads/'),
      );
    });

    test(
      'the preprocessor decides what is sent; its temp file is cleaned',
      () async {
        final f = local.addFile('/storage/emulated/0/DCIM/a.jpg');
        var cleaned = false;
        final stripped = TransferEngine(
          repo: repo,
          devices: devices,
          local: local,
          http: (fp) => http,
          staging: () async => staging,
          preprocessor: _Stripper(() => cleaned = true),
          addToIndex: (_) async {},
        )..onConnection(_fp);
        addTearDown(stripped.dispose);
        await engine.dispose();
        http.json = (c) => switch (c.method) {
          'PUT' => {'received': 2},
          'POST' when c.path.endsWith('/complete') => {'finalId': 'x'},
          _ => {'received': 0},
        };
        final id = await stripped.enqueueUpload(
          [f],
          peerFingerprint: _fp,
          peerName: 'PC',
          rootId: 'cam',
          path: '',
        );
        await until(id, (j) => j.status == TransferStatus.done);
        final create = http.calls.firstWhere(
          (c) => c.path == ApiRoutes.uploads,
        );
        expect(create.body, containsPair('size', 2));
        expect(http.calls.firstWhere((c) => c.method == 'PUT').body, [7, 7]);
        expect(cleaned, isTrue);
      },
    );
  });

  group('jobs and devices', () {
    test('clear finished removes the job and its temporary device', () async {
      http.contents['ms:0'] = [1];
      final id = await engine.enqueueDownload(
        [_remote('ms:0', size: 1)],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      await until(id, (j) => j.status == TransferStatus.done);
      expect(await engine.clearFinished(), 1);
      expect(await repo.dao.jobs(), isEmpty);
      expect(await devices.byFingerprint(_fp), isNull);
    });

    test('a remembered device stays; removing it removes its jobs', () async {
      final d = await devices.saveAfterPairing(
        PairedPeer(
          fingerprint: _fp,
          peerDeviceId: 'p',
          name: 'Phone',
          platform: 'android',
        ),
        temporary: false,
      );
      connected = null;
      engine.onConnection(null);
      await engine.enqueueDownload(
        [_remote('ms:0')],
        peerFingerprint: _fp,
        peerName: 'Phone',
        localFolder: _dl,
      );
      expect(await repo.dao.countForDevice(d.id), 1);
      await devices.remove(d.id);
      expect(await repo.dao.jobs(), isEmpty);
      expect(await db.select(db.transferFiles).get(), isEmpty);
    });

    test('restart: files left running are failed "interrupted"', () async {
      connected = null;
      engine.onConnection(null);
      final d = await engine.deviceIdFor(_fp, 'Phone');
      final id = await repo.createJob(
        deviceId: d,
        direction: TransferDirection.download,
        targetPath: _dl,
        files: [
          (sourceFileId: 'x', name: 'x', sizeBytes: 1, sourceModifiedAtMs: 0),
        ],
      );
      final job = (await repo.dao.job(id))!;
      await repo.setFile(
        job.files.single.id,
        id,
        const TransferFilesCompanion(status: Value(TransferFileStatus.running)),
      );
      expect(await repo.failRunning(), 1);
      final after = (await repo.dao.job(id))!;
      expect(after.status, TransferStatus.failed);
      expect(after.files.single.error, TransferErrors.interrupted);
    });
  });

  group('swipe sends (sendToDevice)', () {
    late String deviceId;
    late Session session;

    setUp(() async {
      deviceId = (await devices.saveAfterPairing(
        PairedPeer(
          fingerprint: _fp,
          peerDeviceId: 'p',
          name: 'PC',
          platform: 'windows',
        ),
        temporary: false,
      )).id;
      connected = null;
      engine.onConnection(null);
      final now = DateTime.utc(2026);
      final sid = await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              layout: '{}',
              startedAt: now,
              updatedAt: now,
              isActive: true,
            ),
          );
      session = Session(
        id: sid,
        layout: SwipeLayout.basic,
        deleteMode: DeleteMode.trash,
        cursor: 0,
        startedAt: now,
        updatedAt: now,
      );
    });

    Future<int> send(Session s, FileRef f, SwipeAction a) => db.transaction(
      () => swipeSendQueue(
        repo.dao,
        downloadsRoot: '/storage/emulated/0/Download',
      )(s, f, a),
    );

    test('a local session collects uploads in one job; undo removes a '
        'queued file', () async {
      final action = SwipeAction(
        SwipeActionType.sendToDevice,
        deviceId: deviceId,
        targetFolder: 'cam/Phone',
      );
      final a = local.addFile('/storage/emulated/0/DCIM/a.jpg');
      final b = local.addFile('/storage/emulated/0/DCIM/b.jpg');
      final first = await send(session, a, action);
      final second = await send(session, b, action);
      final jobs = await repo.dao.jobs();
      expect(jobs, hasLength(1));
      final job = jobs.single;
      expect(job.direction, TransferDirection.upload);
      expect(job.targetRootId, 'cam');
      expect(job.targetPath, 'Phone');
      expect(job.swipeSessionId, session.id);
      expect(job.files.map((f) => f.seq), [0, 1]);
      expect(await repo.deleteQueuedFile(second), isTrue);
      expect((await repo.dao.job(job.id))!.files, hasLength(1));
      expect(await repo.deleteQueuedFile(first), isTrue);
      expect(await repo.dao.jobs(), isEmpty);
    });

    test('a started file is not removed ("Already sent")', () async {
      final f = local.addFile('/storage/emulated/0/DCIM/a.jpg');
      final id = await send(
        session,
        f,
        SwipeAction(
          SwipeActionType.sendToDevice,
          deviceId: deviceId,
          targetFolder: 'cam',
        ),
      );
      final job = (await repo.dao.jobs()).single;
      await repo.setFile(
        id,
        job.id,
        const TransferFilesCompanion(status: Value(TransferFileStatus.running)),
      );
      expect(await repo.deleteQueuedFile(id), isFalse);
    });

    test(
      "that device's own session downloads into Download/<device>",
      () async {
        final remoteSession = Session(
          id: session.id,
          layout: SwipeLayout.basic,
          deleteMode: DeleteMode.trash,
          cursor: 0,
          startedAt: session.startedAt,
          updatedAt: session.updatedAt,
          sourceId: remoteSourceId(_fp),
        );
        await send(
          remoteSession,
          _remote('ms:5'),
          SwipeAction(SwipeActionType.sendToDevice, deviceId: deviceId),
        );
        final job = (await repo.dao.jobs()).single;
        expect(job.direction, TransferDirection.download);
        expect(job.targetPath, '/storage/emulated/0/Download/PC');
        expect(job.files.single.sourceFileId, remoteFileId(_fp, 'ms:5'));
      },
    );
  });
}

class _Stripper implements TransferPreprocessor {
  new(this.onCleanup);

  final void Function() onCleanup;

  @override
  Future<PreparedSource> prepare(FileRef f, _) async => PreparedSource(
    sizeBytes: 2,
    read: (start, end) => Stream.value([7, 7].sublist(start, end)),
    cleanup: () async => onCleanup(),
  );
}
