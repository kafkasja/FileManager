import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/file_hasher.dart';

/// TASK-E1: the hash made while a transfer streams equals a full read.
void main() {
  final data = Uint8List.fromList(List<int>.generate(3 << 20, (i) => i * 31));
  final expected = sha256.convert(data).toString();

  test('chunks fed as they arrive give the file hash', () async {
    final h = await HashSession.start();
    addTearDown(h.dispose);
    for (var i = 0; i < data.length; i += 65536) {
      await h.add(Uint8List.sublistView(data, i, i + 65536));
    }
    expect(h.length, data.length);
    expect(await h.close(), expected);
  });

  test('a resume feeds the part on disk first, then the rest', () async {
    final dir = await Directory.systemTemp.createTemp('kfm_hash');
    addTearDown(() => dir.delete(recursive: true));
    final part = File('${dir.path}/p')..writeAsBytesSync(data);
    const cut = 1234567;
    final h = await HashSession.start();
    addTearDown(h.dispose);
    await h.addFile(part.path, 0, cut);
    await h.add(Uint8List.sublistView(data, cut));
    expect(await h.close(), expected);
  });

  test('a session given up never hangs', () async {
    final h = await HashSession.start();
    await h.add([1, 2, 3]);
    h.dispose();
    expect(h.close, throwsStateError);
  });
}
