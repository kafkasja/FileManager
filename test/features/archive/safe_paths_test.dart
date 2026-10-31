import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/archive/domain/archive_job.dart';
import 'package:kfm/features/archive/domain/safe_paths.dart';

Matcher get _unsafe => throwsA(isA<UnsafeEntryPath>());

void main() {
  group('safeJoin', () {
    const root = '/storage/emulated/0/Download/photos';

    test('keeps normal names inside the target', () {
      expect(safeJoin(root, 'a.jpg'), '$root/a.jpg');
      expect(safeJoin(root, 'sub/dir/b.txt'), '$root/sub/dir/b.txt');
      expect(safeJoin(root, 'folder/'), '$root/folder');
      expect(safeJoin('$root/', 'x'), '$root/x');
      expect(safeJoin(root, './a/./b'), '$root/a/b');
      expect(safeJoin(root, 'a/../b'), '$root/b');
      expect(safeJoin(root, r'win\style\c.txt'), '$root/win/style/c.txt');
      expect(safeJoin(root, 'ünï cødé/文件.txt'), '$root/ünï cødé/文件.txt');
    });

    test('rejects zip-slip, absolute and empty names', () {
      expect(() => safeJoin(root, '../evil.txt'), _unsafe);
      expect(() => safeJoin(root, 'a/../../b'), _unsafe);
      expect(() => safeJoin(root, r'..\evil.txt'), _unsafe);
      expect(() => safeJoin(root, '/abs/path'), _unsafe);
      expect(() => safeJoin(root, r'\abs\path'), _unsafe);
      expect(() => safeJoin(root, 'C:/Windows/x'), _unsafe);
      expect(() => safeJoin(root, 'nul\u0000.txt'), _unsafe);
      expect(() => safeJoin(root, './'), _unsafe);
      expect(() => safeJoin(root, ''), _unsafe);
    });

    test('the error names the entry', () {
      expect(
        () => safeJoin(root, '../evil.txt'),
        throwsA(
          isA<UnsafeEntryPath>().having((e) => e.entry, 'entry', '../evil.txt'),
        ),
      );
    });
  });

  test('isSymlinkEntry: Unix-made S_IFLNK only', () {
    expect(
      isSymlinkEntry(versionMadeBy: 0x0314, externalAttributes: 0xA1FF << 16),
      isTrue,
    );
    // A regular Unix file.
    expect(
      isSymlinkEntry(versionMadeBy: 0x0314, externalAttributes: 0x81A4 << 16),
      isFalse,
    );
    // DOS-made: the high bits mean nothing.
    expect(
      isSymlinkEntry(versionMadeBy: 0x0014, externalAttributes: 0xA1FF << 16),
      isFalse,
    );
  });

  group('entry names', () {
    test('CP437 high half decodes', () {
      // "Müller ä ß ½" in CP437.
      expect(
        decodeCp437([0x4D, 0x81, 0x6C, 0x6C, 0x65, 0x72, 0x20, 0x84, 0x20]),
        'Müller ä ',
      );
      expect(decodeCp437([0xE1, 0xAB, 0xFF]), 'ß½\u00A0');
      expect(decodeCp437([0xB0, 0xDB]), '░█');
    });

    test('UTF-8 when flagged or valid, else CP437', () {
      final utf = utf8.encode('Fotoğraf.jpg');
      expect(decodeEntryName(utf, utf8Flag: true), 'Fotoğraf.jpg');
      // macOS: UTF-8 without the flag.
      expect(decodeEntryName(utf, utf8Flag: false), 'Fotoğraf.jpg');
      // Windows' zip: CP437 bytes, no flag ("Ü.txt" = 0x9A).
      expect(
        decodeEntryName([0x9A, 0x2E, 0x74, 0x78, 0x74], utf8Flag: false),
        'Ü.txt',
      );
      expect(
        decodeEntryName(ascii.encode('plain.txt'), utf8Flag: false),
        'plain.txt',
      );
    });
  });
}
