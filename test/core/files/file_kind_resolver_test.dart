import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';

void main() {
  group('kindFor', () {
    const cases = <(String?, String, FileKind)>[
      ('image/jpeg', 'a.bin', FileKind.image),
      ('video/mp4', 'a', FileKind.video),
      ('audio/mpeg', 'a', FileKind.audio),
      ('application/zip', 'a', FileKind.archive),
      ('application/pdf', 'a', FileKind.document),
      ('text/plain', 'a', FileKind.document),
      (null, 'IMG_1.JPG', FileKind.image),
      (null, 'clip.MOV', FileKind.video),
      (null, 'song.flac', FileKind.audio),
      (null, 'backup.tar.gz', FileKind.archive),
      (null, 'x.7z', FileKind.archive),
      (null, 'cv.docx', FileKind.document),
      (null, 'sheet.xlsx', FileKind.document),
      (null, 'book.epub', FileKind.document),
      (null, 'app.apk', FileKind.other),
      (null, 'README', FileKind.other),
      (null, '.nomedia', FileKind.other),
      ('application/octet-stream', 'x.pdf', FileKind.document),
    ];
    for (final (mime, name, kind) in cases) {
      test('$mime / $name -> $kind', () => expect(kindFor(mime, name), kind));
    }
  });

  group('file names', () {
    test('splitExtension', () {
      expect(splitExtension('a.jpg'), ('a', '.jpg'));
      expect(splitExtension('a.tar.gz'), ('a.tar', '.gz'));
      expect(splitExtension('.nomedia'), ('.nomedia', ''));
      expect(splitExtension('README'), ('README', ''));
    });

    test('uniqueName appends (1), (2)…', () async {
      final taken = {'a.jpg', 'a (1).jpg'};
      expect(
        await uniqueName('b.jpg', (c) async => taken.contains(c)),
        'b.jpg',
      );
      expect(
        await uniqueName('a.jpg', (c) async => taken.contains(c)),
        'a (2).jpg',
      );
      expect(
        await uniqueName('README', (c) async => c == 'README'),
        'README (1)',
      );
    });

    test('validateFileName', () {
      for (final bad in ['', ' ', '.', '..', 'a/b', r'a\b']) {
        expect(
          () => validateFileName(bad),
          throwsA(isA<FileOpException>()),
          reason: bad,
        );
      }
      validateFileName('ok name (1).jpg');
    });

    test('parentOf / nameOf / isInHiddenFolder', () {
      expect(parentOf('/a/b/c.jpg'), '/a/b');
      expect(nameOf('/a/b/c.jpg'), 'c.jpg');
      expect(isInHiddenFolder('/r/.x/c.jpg', root: '/r'), isTrue);
      expect(isInHiddenFolder('/r/x/.c.jpg', root: '/r'), isFalse);
      expect(isInHiddenFolder('/.r/x/c.jpg', root: '/.r'), isFalse);
    });
  });
}
