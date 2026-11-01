import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/ai_labels/data/ai_model_manifest.dart';
import 'package:kfm/features/ai_labels/data/ai_model_store.dart';
import 'package:path/path.dart' as p;

/// A loopback server for the two model files with switchable behaviour.
class ModelServer {
  late HttpServer _server;
  final Map<String, Uint8List> files = {};

  /// Every request: (path, Range header).
  final List<(String, String?)> requests = [];

  /// Close the connection after this many body bytes (once).
  int? cutAfter;

  /// Ignore Range (always 200 with the full body).
  bool ignoreRange = false;

  /// Paths answered with 404.
  final Set<String> missing = {};

  /// Delay between 4 KB chunks (for cancel).
  Duration chunkDelay = Duration.zero;

  /// Completes when the first body chunk was sent.
  Completer<void> firstChunk = Completer();

  String url(String path) =>
      'http://${_server.address.host}:${_server.port}$path';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
  }

  Future<void> _handle(HttpRequest req) async {
    final path = req.uri.path;
    final range = req.headers.value(HttpHeaders.rangeHeader);
    requests.add((path, range));
    final body = files[path];
    final res = req.response;
    if (body == null || missing.contains(path)) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    var start = 0;
    if (range != null && !ignoreRange) {
      start = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
      res
        ..statusCode = HttpStatus.partialContent
        ..headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $start-${body.length - 1}/${body.length}',
        );
    }
    res.contentLength = body.length - start;
    final cut = cutAfter;
    cutAfter = null;
    var sent = 0;
    try {
      for (var i = start; i < body.length; i += 4096) {
        final end = i + 4096 > body.length ? body.length : i + 4096;
        if (cut != null && sent + (end - i) > cut) {
          res.add(body.sublist(i, i + (cut - sent)));
          await res.flush();
          // Fewer bytes than Content-Length: the connection is dropped and
          // the client sees an error mid-body.
          await res.close().catchError((_) {});
          return;
        }
        res.add(body.sublist(i, end));
        sent += end - i;
        await res.flush();
        if (!firstChunk.isCompleted) firstChunk.complete();
        if (chunkDelay > Duration.zero) await Future<void>.delayed(chunkDelay);
      }
      await res.close();
    } on Object {
      // Client went away (cancel).
    }
  }

  Future<void> stop() => _server.close(force: true);
}

Uint8List bytesOf(int n, int seed) =>
    Uint8List.fromList([for (var i = 0; i < n; i++) (i * 31 + seed) % 251]);

String sha(List<int> b) => sha256.convert(b).toString();

void main() {
  late ModelServer server;
  late Directory base;
  late Uint8List classifier;
  late Uint8List detector;
  late bool wifiOnly;
  late bool onWifi;
  late StreamController<bool> wifi;
  final stores = <AiModelStore>[];

  AiModelManifest manifest({
    String? classifierUrl,
    String? fallback,
    int setVersion = 1,
  }) => AiModelManifest(
    modelSetVersion: setVersion,
    models: [
      AiModelEntry(
        id: 'classifier',
        file: 'classifier.tflite',
        sizeBytes: classifier.length,
        sha256: sha(classifier),
        url: classifierUrl ?? server.url('/c'),
        fallbackUrl: fallback,
        name: 'C',
        licence: 'Apache-2.0',
        publisher: 'Google',
        sourceUrl: 'https://example.org',
      ),
      AiModelEntry(
        id: 'detector',
        file: 'detector.tflite',
        sizeBytes: detector.length,
        sha256: sha(detector),
        url: server.url('/d'),
        name: 'D',
        licence: 'Apache-2.0',
        publisher: 'Google',
        sourceUrl: 'https://example.org',
      ),
    ],
  );

  AiModelStore store({AiModelManifest? m, bool insecure = true}) {
    final s = AiModelStore(
      manifest: m ?? manifest(),
      baseDir: () async => base,
      wifiOnly: () async => wifiOnly,
      isOnWifi: () async => onWifi,
      wifiChanges: wifi.stream,
      allowInsecureForTests: insecure,
    );
    stores.add(s);
    return s;
  }

  File inDir(String name) =>
      File(p.join(base.path, AiModelStore.dirName, name));

  setUp(() async {
    server = ModelServer();
    await server.start();
    classifier = bytesOf(50000, 1);
    detector = bytesOf(30000, 2);
    server.files['/c'] = classifier;
    server.files['/d'] = detector;
    base = Directory.systemTemp.createTempSync('kfm_models');
    wifiOnly = true;
    onWifi = true;
    wifi = StreamController.broadcast();
  });
  tearDown(() async {
    for (final s in stores) {
      s.dispose();
    }
    stores.clear();
    await wifi.close();
    await server.stop();
    base.deleteSync(recursive: true);
  });

  test('no request before Download; full download installs both', () async {
    final s = store();
    expect(await s.verifyInstalled(), const AiModelsNotInstalled());
    expect(server.requests, isEmpty);

    final seen = <AiModelState>[];
    final sub = s.states.listen(seen.add);
    expect(await s.download(), isTrue);
    await sub.cancel();
    expect(s.state, AiModelsInstalled(classifier.length + detector.length));
    expect(seen.whereType<AiModelsDownloading>(), isNotEmpty);
    expect(seen.whereType<AiModelsVerifying>(), isNotEmpty);
    expect(inDir('classifier.tflite').readAsBytesSync(), classifier);
    expect(inDir('detector.tflite').readAsBytesSync(), detector);
    expect(inDir('classifier.tflite.part').existsSync(), isFalse);
    final info = jsonDecode(
      inDir(AiModelStore.installedFile).readAsStringSync(),
    ) as Map<String, Object?>;
    expect(info['modelSetVersion'], 1);
    expect(server.requests.map((r) => r.$1), ['/c', '/d']);

    // A new start sees the set; loading re-hashes and returns the bytes.
    final again = store();
    expect(await again.verifyInstalled(), isA<AiModelsInstalled>());
    final loaded = await again.loadVerified();
    expect(loaded!.classifier, classifier);
    expect(loaded.detector, detector);
  });

  test('resumes after a cut with a Range request (206)', () async {
    server.cutAfter = 20000;
    final s = store();
    expect(await s.download(), isFalse);
    expect(s.state, isA<AiModelsFailed>());
    final failed = s.state as AiModelsFailed;
    expect(failed.reason, AiModelFailure.network);
    expect(failed.partialBytes, greaterThan(0));
    final part = inDir('classifier.tflite.part').lengthSync();
    expect(part, greaterThan(0));

    expect(await s.download(), isTrue);
    expect(server.requests[1], ('/c', 'bytes=$part-'));
    expect(inDir('classifier.tflite').readAsBytesSync(), classifier);
  });

  test('a 200 answer to a Range request restarts from 0', () async {
    server.cutAfter = 20000;
    final s = store();
    await s.download();
    server.ignoreRange = true;
    expect(await s.download(), isTrue);
    expect(inDir('classifier.tflite').readAsBytesSync(), classifier);
    expect(inDir('detector.tflite').readAsBytesSync(), detector);
  });

  test('cancel stops it and keeps the .part for resume', () async {
    server.chunkDelay = const Duration(milliseconds: 20);
    final s = store();
    final run = s.download();
    await s.states.firstWhere(
      (st) => st is AiModelsDownloading && st.doneBytes > 0,
    );
    await s.cancel();
    expect(await run, isFalse);
    expect(s.state, isA<AiModelsNotInstalled>());
    expect((s.state as AiModelsNotInstalled).partialBytes, greaterThan(0));
    expect(inDir('classifier.tflite.part').existsSync(), isTrue);
    expect(inDir('classifier.tflite').existsSync(), isFalse);

    server.chunkDelay = Duration.zero;
    expect(await s.download(), isTrue);
    expect(server.requests.last.$1, '/d');
    expect(server.requests[1].$2, startsWith('bytes='));
  });

  test('a wrong hash is rejected and never installed', () async {
    server.files['/c'] = bytesOf(classifier.length, 9);
    final s = store();
    expect(await s.download(), isFalse);
    expect(
      s.state,
      const AiModelsFailed(
        AiModelFailure.checksum,
        detail: 'classifier.tflite',
      ),
    );
    expect(inDir('classifier.tflite').existsSync(), isFalse);
    expect(inDir('classifier.tflite.part').existsSync(), isFalse);
    expect(inDir(AiModelStore.installedFile).existsSync(), isFalse);
    expect(await s.loadVerified(), isNull);
  });

  test('fallback is tried only when the primary fails, and only with the '
      'pinned hash', () async {
    server.files['/fb'] = classifier;
    server.files['/fbBad'] = bytesOf(classifier.length, 7);
    server.missing.add('/c');
    final ok = store(m: manifest(fallback: server.url('/fb')));
    expect(await ok.download(), isTrue);
    expect(server.requests.map((r) => r.$1), ['/c', '/fb', '/d']);

    base
      ..deleteSync(recursive: true)
      ..createSync();
    final bad = store(m: manifest(fallback: server.url('/fbBad')));
    expect(await bad.download(), isFalse);
    expect((bad.state as AiModelsFailed).reason, AiModelFailure.checksum);
    expect(inDir('classifier.tflite').existsSync(), isFalse);
  });

  test('an HTTP error shows as failed(http)', () async {
    server.missing.add('/c');
    final s = store();
    expect(await s.download(), isFalse);
    expect(s.state, const AiModelsFailed(AiModelFailure.http, detail: '404'));
  });

  test('Wi-Fi only: waits on mobile data, then downloads on Wi-Fi', () async {
    onWifi = false;
    final s = store();
    final run = s.download();
    await pumpEventQueue();
    expect(s.state, isA<AiModelsWaitingForWifi>());
    expect(server.requests, isEmpty);
    onWifi = true;
    wifi.add(true);
    expect(await run, isTrue);
    expect(s.isInstalled, isTrue);
  });

  test(
    '"Use mobile data this time" and Wi-Fi only off download at once',
    () async {
      onWifi = false;
      final s = store();
      expect(await s.download(useMobileData: true), isTrue);
      await s.remove();
      wifiOnly = false;
      expect(await s.download(), isTrue);
    },
  );

  test('cancel while waiting for Wi-Fi', () async {
    onWifi = false;
    final s = store();
    final run = s.download();
    await pumpEventQueue();
    await s.cancel();
    expect(await run, isFalse);
    expect(s.state, const AiModelsNotInstalled());
  });

  test('remove deletes ai_models/ (files, parts, installed.json)', () async {
    final s = store();
    await s.download();
    await s.remove();
    expect(
      Directory(p.join(base.path, AiModelStore.dirName)).existsSync(),
      isFalse,
    );
    expect(s.state, const AiModelsNotInstalled());
    expect(await s.loadVerified(), isNull);
  });

  test('a changed byte is never loaded: "download again"', () async {
    final s = store();
    await s.download();
    final f = inDir('detector.tflite');
    final bytes = f.readAsBytesSync();
    bytes[100] ^= 0xFF;
    f.writeAsBytesSync(bytes);
    // Same size: the cheap start check passes, the full hash doesn't.
    final again = store();
    expect(await again.verifyInstalled(), isA<AiModelsInstalled>());
    expect(await again.loadVerified(), isNull);
    expect(again.state, const AiModelsNotInstalled(needsUpdate: true));
  });

  test('a missing file or a newer model set needs a new download', () async {
    final s = store();
    await s.download();
    final newer = store(m: manifest(setVersion: 2));
    expect(
      await newer.verifyInstalled(),
      const AiModelsNotInstalled(needsUpdate: true),
    );
    inDir('classifier.tflite').deleteSync();
    expect(
      await store().verifyInstalled(),
      const AiModelsNotInstalled(needsUpdate: true),
    );
  });

  test('HTTPS only', () async {
    final s = store(insecure: false);
    expect(await s.download(), isFalse);
    expect(server.requests, isEmpty);
  });

  test('the bundled manifest pins the researched files', () {
    final m = AiModelManifest.parse(
      File(AiModelManifest.assetPath).readAsStringSync(),
    );
    expect(m.totalBytes, 9998012);
    expect(m.models.map((e) => e.id), ['classifier', 'detector']);
    for (final e in m.models) {
      expect(e.url, startsWith('https://storage.googleapis.com/'));
      expect(e.sha256, hasLength(64));
      expect(e.fallbackUrl, isNull);
    }
    expect(
      m.byId('classifier').sha256,
      'aa03e4017f54fd5c743bd397b0a3e136fab0942f9c7cd715064a31ca3e4fc996',
    );
    expect(
      m.byId('detector').sha256,
      '2e04c53bfeac0ac2a30c057c7e2a777594ce39baaac35a92f74fb1e8c4fc4e0b',
    );
  });
}
