import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';

FileRef photo(String id, {int minute = 0, FileKind kind = FileKind.image}) =>
    FileRef(
      id: id,
      uri: id,
      name: '$id.jpg',
      kind: kind,
      sizeBytes: 1,
      modifiedAt: DateTime.utc(2025, 1, 1, 0, minute),
      folderPath: '/s',
      origin: FileOrigin.local,
    );

void main() {
  late Directory dir;
  late List<String> generated;
  late Map<String, Completer<void>> gates;

  Future<Uint8List?> generator(FileRef f, int size) async {
    generated.add(f.id);
    await gates[f.id]?.future;
    if (f.id.startsWith('bad')) throw const FormatException('undecodable');
    return Uint8List.fromList(List.filled(1000, f.id.length));
  }

  DiskThumbnailCache cache({int maxDisk = 1 << 30, int maxConcurrent = 4}) =>
      DiskThumbnailCache(
        dir: dir,
        generator: generator,
        maxDiskBytes: () async => maxDisk,
        maxConcurrent: maxConcurrent,
      );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kfm_thumbs');
    generated = [];
    gates = {};
  });
  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('memory hit, then disk hit in a new instance', () async {
    final c = cache();
    expect(await c.get(photo('a')), hasLength(1000));
    expect(await c.get(photo('a')), hasLength(1000));
    expect(generated, ['a']);

    final fresh = cache();
    expect(await fresh.get(photo('a')), hasLength(1000));
    expect(generated, ['a'], reason: 'served from disk');
    expect(await fresh.diskSizeBytes(), 1000);
  });

  test('an edited file (new modifiedAt) gets a new thumbnail', () async {
    final c = cache();
    await c.get(photo('a'));
    await c.get(photo('a', minute: 5));
    expect(generated, ['a', 'a']);
  });

  test('no thumbnail for non-media kinds', () async {
    expect(await cache().get(photo('d', kind: FileKind.document)), isNull);
    expect(generated, isEmpty);
  });

  test('a failure is remembered for the session (no retry loop)', () async {
    final c = cache();
    expect(await c.get(photo('bad1')), isNull);
    expect(await c.get(photo('bad1')), isNull);
    expect(generated, ['bad1']);
  });

  test('LIFO: the most recent visible request is served first', () async {
    gates['a'] = Completer<void>();
    final c = cache(maxConcurrent: 1);
    final a = c.get(photo('a')); // starts immediately, blocks
    final b = c.get(photo('b'));
    final p = c.get(photo('p'), priority: ThumbPriority.prefetch);
    final d = c.get(photo('d'));
    gates['a']!.complete();
    await Future.wait([a, b, p, d]);
    expect(generated, ['a', 'd', 'b', 'p']);
  });

  test('cancel drops a waiting request', () async {
    gates['a'] = Completer<void>();
    final c = cache(maxConcurrent: 1);
    final a = c.get(photo('a'));
    final b = c.get(photo('b'));
    c.cancel('b');
    gates['a']!.complete();
    expect(await b, isNull);
    await a;
    expect(generated, ['a']);
  });

  test('disk cap trims least recently used files to 80%', () async {
    final c = cache(maxDisk: 50 * 1000);
    for (var i = 0; i < DiskThumbnailCache.trimEvery; i++) {
      await c.get(photo('f$i'));
    }
    final size = await c.diskSizeBytes();
    expect(size, lessThanOrEqualTo(40 * 1000));
    expect(size, greaterThan(0));
  });

  test('clear empties memory and disk', () async {
    final c = cache();
    await c.get(photo('a'));
    await c.clear();
    expect(await c.diskSizeBytes(), 0);
    await c.get(photo('a'));
    expect(generated, ['a', 'a']);
  });

  group('androidThumbnailGenerator (H7)', () {
    late List<String> msCalls;
    late List<String> fileCalls;
    Uint8List? msResult;
    Exception? msError;
    Exception? fileError;

    FileRef ref(String id, String uri, FileKind kind, {String name = 'x'}) =>
        FileRef(
          id: id,
          uri: uri,
          name: name,
          kind: kind,
          sizeBytes: 1,
          modifiedAt: DateTime.utc(2025),
          folderPath: '/storage/emulated/0/.hidden',
          origin: FileOrigin.local,
        );

    ThumbGenerator gen() => androidThumbnailGenerator(
      mediaStore: (f, size) async {
        msCalls.add(f.id);
        if (msError case final e?) throw e;
        return msResult;
      },
      fromFile: (path, size) async {
        fileCalls.add(path);
        if (fileError case final e?) throw e;
        return Uint8List.fromList([size % 256]);
      },
    );

    setUp(() {
      msCalls = [];
      fileCalls = [];
      msResult = Uint8List.fromList([9]);
      msError = null;
      fileError = null;
    });

    test('ms: success uses MediaStore only', () async {
      final b = await gen()(
        ref('ms:5', 'content://media/5', FileKind.image, name: 'a.jpg'),
        256,
      );
      expect(b, [9]);
      expect(msCalls, ['ms:5']);
      expect(fileCalls, isEmpty);
    });

    test('ms: null or a throw falls back to the file path', () async {
      final f = ref('ms:5', 'content://media/5', FileKind.image, name: 'a.jpg');
      msResult = null;
      expect(await gen()(f, 256), isNotNull);
      msError = Exception('boom');
      expect(await gen()(f, 256), isNotNull);
      expect(fileCalls, [
        '/storage/emulated/0/.hidden/a.jpg',
        '/storage/emulated/0/.hidden/a.jpg',
      ]);
    });

    test(
      'path: image, video and audio go to the file; no MediaStore',
      () async {
        for (final kind in [FileKind.image, FileKind.video, FileKind.audio]) {
          const path = '/storage/emulated/0/.hidden/p';
          expect(await gen()(ref('path:$path', path, kind), 256), isNotNull);
        }
        expect(msCalls, isEmpty);
        expect(fileCalls, hasLength(3));
      },
    );

    test('path: document → null, no channel call', () async {
      const path = '/storage/emulated/0/.hidden/a.pdf';
      expect(
        await gen()(ref('path:$path', path, FileKind.document), 256),
        isNull,
      );
      expect(fileCalls, isEmpty);
    });

    test('a thrown file error → null, remembered as failed', () async {
      fileError = const FormatException('undecodable');
      final c = DiskThumbnailCache(
        dir: dir,
        generator: gen(),
        maxDiskBytes: () async => 1 << 30,
      );
      const path = '/storage/emulated/0/.hidden/bad.jpg';
      final f = ref('path:$path', path, FileKind.image);
      expect(await c.get(f), isNull);
      expect(await c.get(f), isNull);
      expect(fileCalls, [path], reason: 'not retried in the session');
    });
  });
}
