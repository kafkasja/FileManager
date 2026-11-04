import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kfm/core/files/io/exif_meta.dart';
import 'package:kfm/core/files/io/fs_walker.dart';

List<int> _jpegWithExif({int orientation = 1}) {
  final im = img.Image(width: 40, height: 30);
  im.exif.imageIfd[0x0112] = img.IfdValueShort(orientation);
  im.exif.exifIfd[0x9003] = img.IfdValueAscii('2024:05:01 13:22:10');
  im.exif.exifIfd[0xA002] = img.IfdValueShort(40);
  im.exif.exifIfd[0xA003] = img.IfdValueShort(30);
  return img.encodeJpg(im);
}

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('kfm_exif_'));
  tearDown(() => dir.delete(recursive: true));

  test('parseExifDate', () {
    expect(
      parseExifDate('2024:05:01 13:22:10'),
      DateTime(2024, 5, 1, 13, 22, 10),
    );
    expect(parseExifDate('0000:00:00 00:00:00'), isNull);
    expect(parseExifDate('    '), isNull);
    expect(parseExifDate(null), isNull);
  });

  test('readExifMeta: date + size; rotated photos swap the size', () async {
    final a = File('${dir.path}/a.jpg')..writeAsBytesSync(_jpegWithExif());
    final b = File('${dir.path}/b.jpg')
      ..writeAsBytesSync(_jpegWithExif(orientation: 6));
    final ma = await readExifMeta(a.path);
    expect(ma?.takenAt, DateTime(2024, 5, 1, 13, 22, 10));
    expect((ma?.width, ma?.height), (40, 30));
    final mb = await readExifMeta(b.path);
    expect((mb?.width, mb?.height), (30, 40));
  });

  test('no EXIF or not an image: null, no error', () async {
    final plain = File('${dir.path}/p.jpg')
      ..writeAsBytesSync(img.encodeJpg(img.Image(width: 4, height: 4)));
    final junk = File('${dir.path}/j.jpg')..writeAsBytesSync([1, 2, 3]);
    expect(await readExifMeta(plain.path), isNull);
    expect(await readExifMeta(junk.path), isNull);
    expect(await readExifMeta('${dir.path}/missing.jpg'), isNull);
  });

  test('Q4: zero-byte, truncated and bit-flipped photos never throw or '
      'hang', () async {
    final good = _jpegWithExif();
    final f = File('${dir.path}/x.jpg');
    final rnd = Random(3);
    final inputs = <List<int>>[
      const [],
      [0xFF, 0xD8],
      [0xFF, 0xD8, 0xFF, 0xE1, 0xFF, 0xFF], // APP1 claiming 64 KiB
      for (var cut = 0; cut < good.length; cut += 7) good.sublist(0, cut),
      for (var i = 0; i < 400; i++)
        [...good]..[rnd.nextInt(200)] = rnd.nextInt(256),
    ];
    final sw = Stopwatch()..start();
    for (final bytes in inputs) {
      f.writeAsBytesSync(bytes);
      await readExifMeta(f.path).timeout(const Duration(seconds: 5));
    }
    expect(sw.elapsed, lessThan(const Duration(seconds: 60)));
  });

  test('the walker fills takenAt/width/height only with readExif', () async {
    File('${dir.path}/a.jpg').writeAsBytesSync(_jpegWithExif());
    final root = dir.path.replaceAll(r'\', '/');
    final withExif = await walkFiles(WalkOptions(root: root, readExif: true))
        .expand((p) => p)
        .toList();
    expect(withExif.single.takenAt, DateTime(2024, 5, 1, 13, 22, 10));
    expect(withExif.single.width, 40);
    final without = await walkFiles(WalkOptions(root: root))
        .expand((p) => p)
        .toList();
    expect(without.single.takenAt, isNull);
    expect(without.single.width, isNull);
  });
}
