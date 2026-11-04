import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/file_hasher.dart';

void main() {
  final bytes = List<int>.generate(300000, (i) => i % 251);
  final expected = sha256.convert(bytes).toString();

  test('a file and a range of it are hashed in an isolate', () async {
    final dir = await Directory.systemTemp.createTemp('kfm_hash');
    addTearDown(() => dir.delete(recursive: true));
    final f = File('${dir.path}/a.bin')..writeAsBytesSync(bytes);
    expect(await hashFileInIsolate(f.path), expected);
    expect(
      await hashFileInIsolate(f.path, start: 10, end: 20),
      sha256.convert(bytes.sublist(10, 20)).toString(),
    );
  });

  test('a stream is hashed in a worker isolate, chunk by chunk', () async {
    Stream<List<int>> chunks() async* {
      for (var i = 0; i < bytes.length; i += 65536) {
        yield bytes.sublist(i, (i + 65536).clamp(0, bytes.length));
      }
    }

    expect(await hashStreamInIsolate(chunks()), expected);
    expect(
      await hashStreamInIsolate(const Stream.empty()),
      sha256.convert(const []).toString(),
    );
  });

  test('Q8: a fast stream is never read far ahead of the worker', () async {
    // 512 chunks; before the fix all of them were queued for the worker
    // at once (a 1 GB file took ~850 MB of extra memory).
    final chunk = Uint8List.fromList(List<int>.generate(16384, (i) => i % 7));
    final all = BytesBuilder(copy: false);
    Stream<List<int>> fast() async* {
      for (var i = 0; i < 512; i++) {
        all.add(chunk);
        yield chunk;
      }
    }

    var most = 0;
    debugOnHashChunkSent = (n) => most = n > most ? n : most;
    addTearDown(() => debugOnHashChunkSent = null);
    final hex = await hashStreamInIsolate(fast());
    expect(hex, sha256.convert(all.takeBytes()).toString());
    expect(most, lessThanOrEqualTo(kHashChunksInFlight));
    expect(most, greaterThan(0));
  });

  test('a failing stream fails the hash', () {
    expect(
      hashStreamInIsolate(Stream.error(const FileSystemException('gone'))),
      throwsA(isA<FileSystemException>()),
    );
  });
}
