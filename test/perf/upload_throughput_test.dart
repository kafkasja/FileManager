import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/file_hasher.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/device_identity_repository_impl.dart';
import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/routes/upload_routes.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_scope_store.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/data/transfer_stats_log.dart';
import 'package:kfm/features/connect/data/upload_store.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:kfm/features/transfers/data/chunked_uploader.dart';
import 'package:kfm/features/transfers/data/transfer_run.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:kfm/features/transfers/domain/transfer_preprocessor.dart';

import '../core/files/fake_file_source.dart';
import '../features/connect/path_guard_test.dart' show fakeGuard;

/// TASK-E1 issue 3 ("a 312 MB upload was super slow"): a real TLS
/// `ShareServer` on loopback receives a file from the real
/// `ChunkedUploader`, both on disk. Off by default (it writes ~1 GB):
/// `KFM_PERF=1 flutter test test/perf/upload_throughput_test.dart`
/// (`KFM_PERF_MB` sets the size, default 312). Results go to
/// `archive/notes/E1-impl-notes.md`.
const _root = '/storage/emulated/0';
const _dcim = '$_root/DCIM';
final String _clientFp = 'cd' * 32;

void main() {
  final enabled = Platform.environment['KFM_PERF'] == '1';
  final mb = int.tryParse(Platform.environment['KFM_PERF_MB'] ?? '') ?? 312;
  // Compare: hash after sending (the N10/N11 way) instead of while.
  final streaming = Platform.environment['KFM_PERF_HASH_AFTER'] != '1';

  test(
    'upload throughput over loopback ($mb MB)',
    () async {
      final work = await Directory.systemTemp.createTemp('kfm_perf');
      addTearDown(() => work.delete(recursive: true));
      final published = Directory('${work.path}/published')..createSync();
      final source = File('${work.path}/source.bin');
      final size = mb * 1000 * 1000;
      final expected = await _writeSource(source, size);

      // The receiving device in its own isolate (two devices: their TLS and
      // disk work run in parallel, as on a phone and a PC).
      final fromServer = ReceivePort();
      final isolate = await Isolate.spawn(_serve, [
        fromServer.sendPort,
        work.path,
        streaming,
      ]);
      final events = StreamIterator(fromServer);
      await events.moveNext();
      final hello = events.current as List<Object?>;
      final toServer = hello[0]! as SendPort;
      final port = hello[1]! as int;
      final fingerprint = hello[2]! as String;
      final token = hello[3]! as String;
      addTearDown(() {
        toServer.send('stop');
        fromServer.close();
        isolate.kill();
      });
      final http = PinnedClient.pinned(
        Uri.parse('https://127.0.0.1:$port'),
        fingerprint,
      )..bearerToken = token;
      addTearDown(http.close);

      final ref = FileRef(
        id: 'path:${source.path}',
        uri: source.path,
        name: 'cat.mp4',
        kind: FileKind.video,
        sizeBytes: size,
        modifiedAt: source.lastModifiedSync(),
        folderPath: work.path,
        origin: FileOrigin.local,
      );
      final local = _StatSource(ref);
      final uploader = ChunkedUploader(
        local: local,
        preprocessor: _DiskPreprocessor(source),
        save: (_, _) async {},
        streamingHash: streaming,
      );
      final now = DateTime.now();
      final run = TransferRun(
        TransferFile(
          id: 1,
          transferId: 't',
          seq: 0,
          sourceFileId: ref.id,
          name: ref.name,
          sizeBytes: size,
          sourceModifiedAtMs: ref.modifiedAt.millisecondsSinceEpoch,
          bytesDone: 0,
          status: TransferFileStatus.running,
        ),
        TransferJob(
          id: 't',
          deviceId: 'd',
          deviceName: 'PC',
          deviceFingerprint: fingerprint,
          direction: TransferDirection.upload,
          mode: TransferMode.copy,
          targetPath: '',
          targetRootId: 'cam',
          status: TransferStatus.running,
          createdAt: now,
          updatedAt: now,
          files: const [],
        ),
      );
      debugOnTransferStats = print;
      addTearDown(() => debugOnTransferStats = null);
      final hashClock = Stopwatch()..start();
      await hashFileInIsolate(source.path);
      // The result is the point of this opt-in test.
      // ignore: avoid_print
      print(
        'E1 perf: one full SHA-256 read ${hashClock.elapsedMilliseconds}ms',
      );
      final clock = Stopwatch()..start();
      await uploader.run(run, http);
      clock.stop();
      final out = published.listSync().whereType<File>().single;
      expect(out.lengthSync(), size);
      expect(await hashFileInIsolate(out.path), expected);
      final secs = clock.elapsedMilliseconds / 1000;
      // The result is the point of this opt-in test.
      // ignore: avoid_print
      print(
        'E1 perf: $mb MB in ${secs.toStringAsFixed(2)} s = '
        '${(size / 1e6 / secs).toStringAsFixed(1)} MB/s',
      );
    },
    skip: enabled ? false : 'set KFM_PERF=1 to run the throughput test',
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

/// The receiving side: a real TLS `ShareServer` with the upload routes.
/// Sends `[its SendPort, port, fingerprint, token]`; 'stop' ends it.
Future<void> _serve(List<Object> args) async {
  final out = args[0] as SendPort;
  final work = args[1] as String;
  final streaming = args[2] as bool;
  debugOnTransferStats = print;
  final staging = Directory('$work/staging')..createSync();
  final published = Directory('$work/published');
  final sessions = ClientSessionStore();
  final scopes = ShareScopeStore(sessions: sessions);
  final files = _DiskImportSource(published)..addFolder(_dcim);
  final uploads = UploadStore(staging: () async => staging);
  final guard = AllowListGuard(
    scopeOf: scopes.scopeOf,
    source: () => files,
    paths: fakeGuard(existing: {_root, _dcim}),
  );
  final server = ShareServer(
    DeviceIdentityRepositoryImpl(
      store: InMemorySecretStore(),
      displayName: () async => 'PC',
      platform: 'windows',
      run: <R>(R Function() fn) async => fn(),
    ),
    (served) => buildSharePipeline(
      served: served,
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
          // The PC receiving (the reported case): the partial is renamed
          // into place on the same volume.
          publishMode: (_) async => UploadPublish.rename,
          streamingHash: streaming,
        ),
      ),
    ),
    addresses: () async => [
      LocalAddress(InternetAddress.loopbackIPv4, 8, 'lo'),
    ],
    bindAddress: InternetAddress.loopbackIPv4,
  );
  final state = await server.start();
  scopes.set(
    _clientFp,
    const ShareScope([
      SharedRoot(id: 'cam', path: _dcim, label: 'DCIM', readOnly: false),
    ]),
  );
  final token = sessions
      .issue(clientFingerprint: _clientFp, clientDeviceId: 'd', clientName: 'P')
      .token;
  final inbox = ReceivePort();
  out.send([inbox.sendPort, state.port, state.fingerprint, token]);
  await inbox.first;
  await server.stop();
  inbox.close();
}

/// [size] bytes of a repeated random 1 MiB block; returns its SHA-256.
Future<String> _writeSource(File f, int size) async {
  final r = Random(1);
  final block = Uint8List.fromList(
    List<int>.generate(1 << 20, (_) => r.nextInt(256)),
  );
  final sink = f.openWrite();
  var left = size;
  while (left > 0) {
    final n = min(left, block.length);
    sink.add(n == block.length ? block : Uint8List.sublistView(block, 0, n));
    left -= n;
  }
  await sink.close();
  final digest = await crypto.sha256.bind(f.openRead()).first;
  return digest.toString();
}

/// The sender's file on disk.
class _DiskPreprocessor implements TransferPreprocessor {
  const new(this.file);

  final File file;

  @override
  Future<PreparedSource> prepare(FileRef f, FileSource source) async =>
      PreparedSource(
        sizeBytes: file.lengthSync(),
        read: file.openRead,
        path: file.path,
      );
}

/// The sender's source: only `stat` is used.
class _StatSource extends FakeFileSource {
  new(this.ref);

  final FileRef ref;

  @override
  Future<FileRef?> stat(String id) async => id == ref.id ? ref : null;
}

/// The receiver: published files are moved into [dir] (no copy in
/// memory).
class _DiskImportSource extends FakeFileSource {
  new(this.dir);

  final Directory dir;

  @override
  Future<int?> freeBytes(String folderPath) async => null;

  @override
  Future<FileRef> importFile(
    File staged, {
    required String targetFolder,
    required String name,
    String? mimeType,
  }) async {
    final out = await staged.rename('${dir.path}/$name');
    return FileRef(
      id: 'path:$_dcim/$name',
      uri: out.path,
      name: name,
      kind: FileKind.video,
      sizeBytes: await out.length(),
      modifiedAt: DateTime.now(),
      folderPath: dir.path.replaceAll(r'\', '/'),
      origin: FileOrigin.local,
    );
  }
}
