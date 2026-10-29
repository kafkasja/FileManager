import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/browse/domain/text_preview.dart';

TextPreviewText _text(List<int> bytes, {bool truncated = false}) =>
    decodeTextPreview(Uint8List.fromList(bytes), truncated: truncated)
        as TextPreviewText;

FileRef _file(String name, {String? mime}) => FileRef(
  id: 'path:/x/$name',
  uri: '/x/$name',
  name: name,
  mimeType: mime,
  kind: kindFor(mime, name),
  sizeBytes: 1,
  modifiedAt: DateTime.utc(2025),
  folderPath: '/x',
  origin: FileOrigin.local,
);

void main() {
  test('UTF-8, with and without BOM', () {
    expect(_text(utf8.encode('héllo')).text, 'héllo');
    expect(_text([0xEF, 0xBB, 0xBF, ...utf8.encode('ç')]).text, 'ç');
  });

  test('UTF-16 LE and BE with BOM', () {
    expect(_text([0xFF, 0xFE, 0x68, 0x00, 0x69, 0x00]).text, 'hi');
    expect(_text([0xFE, 0xFF, 0x00, 0x68, 0x00, 0x69]).text, 'hi');
  });

  test('not UTF-8 → Latin-1 with the flag', () {
    final t = _text([0x63, 0x61, 0x66, 0xE9]); // "café" in Latin-1
    expect(t.text, 'café');
    expect(t.latin1, isTrue);
  });

  test('a multi-byte sequence cut at the 1 MiB edge is dropped', () {
    final bytes = [...utf8.encode('ab'), 0xE2, 0x82]; // start of "€"
    final t = _text(bytes, truncated: true);
    expect(t.text, 'ab');
    expect(t.latin1, isFalse);
    expect(t.truncated, isTrue);
  });

  test('binary data renamed .txt is not shown as text', () {
    final bytes = Uint8List.fromList(List.generate(1000, (i) => i % 32));
    expect(
      decodeTextPreview(bytes, truncated: false),
      isA<TextPreviewBinary>(),
    );
  });

  test('isTextFile: mime and extensions; HTML is not', () {
    expect(isTextFile(_file('a.log')), isTrue);
    expect(isTextFile(_file('a.json')), isTrue);
    expect(isTextFile(_file('a', mime: 'text/plain')), isTrue);
    expect(isTextFile(_file('a.html', mime: 'text/html')), isFalse);
    expect(isTextFile(_file('a.pdf')), isFalse);
  });
}
