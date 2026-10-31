import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';

final Matcher _invalid = throwsA(
  isA<FileOpException>().having(
    (e) => e.failure,
    'failure',
    FileOpFailure.invalidName,
  ),
);

void main() {
  group('validateFileName (B4)', () {
    test('rejects each character shared storage refuses', () {
      for (final c in ['/', r'\', ':', '*', '?', '"', '<', '>', '|']) {
        expect(() => validateFileName('a${c}b.jpg'), _invalid, reason: c);
      }
    });

    test('rejects control characters', () {
      for (final code in [0, 1, 9, 10, 13, 0x1F]) {
        expect(
          () => validateFileName('a${String.fromCharCode(code)}b'),
          _invalid,
          reason: 'U+${code.toRadixString(16)}',
        );
      }
    });

    test('limits names to 255 UTF-8 bytes, not characters', () {
      validateFileName('a' * 255);
      expect(() => validateFileName('a' * 256), _invalid);
      // "é" is 2 bytes: 127 of them + "a" = 255 bytes, 128 characters.
      validateFileName('${'é' * 127}a');
      expect(() => validateFileName('é' * 128), _invalid);
      // A 4-byte emoji.
      validateFileName('${'😀' * 63}abc');
      expect(() => validateFileName('😀' * 64), _invalid);
    });

    test('still rejects empty and dot names, accepts ordinary ones', () {
      for (final bad in ['', '   ', '.', '..']) {
        expect(() => validateFileName(bad), _invalid, reason: bad);
      }
      [
        'ok name (1).jpg',
        '.hidden',
        'Ünïcödé — 写真.png',
        "it's #1 & more [x] {y} 100%.txt",
      ].forEach(validateFileName);
    });
  });

  group('checkPathSegment (FileSource renames, B4)', () {
    test('accepts names only the dialogs refuse', () {
      [
        'What?.pdf',
        'a:b',
        'a*b|c',
        '<x>',
        'tab\there',
      ].forEach(checkPathSegment);
    });

    test('rejects what is no single path segment', () {
      for (final bad in ['', ' ', '.', '..', 'a/b', 'a\u0000b', 'a' * 256]) {
        expect(() => checkPathSegment(bad), _invalid, reason: bad);
      }
    });
  });
}
