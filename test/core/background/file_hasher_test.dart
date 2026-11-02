import 'dart:io';

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

  test('a failing stream fails the hash', () {
    expect(
      hashStreamInIsolate(Stream.error(const FileSystemException('gone'))),
      throwsA(isA<FileSystemException>()),
    );
  });
}
