// Writes the TASK-C2 fixture JPEGs to test/fixtures/similar/.
// Run from the repo root: dart run tool/gen_similar_fixtures.dart
// Deterministic (seeded), so re-running gives the same images.
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

img.Image scene(int seed, {int size = 256}) {
  final rnd = Random(seed);
  final image = img.Image(width: size, height: size);
  final c1 = [rnd.nextInt(256), rnd.nextInt(256), rnd.nextInt(256)];
  final c2 = [rnd.nextInt(256), rnd.nextInt(256), rnd.nextInt(256)];
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final t = (x + y) / (2 * size);
      image.setPixelRgb(
        x,
        y,
        (c1[0] * (1 - t) + c2[0] * t).round(),
        (c1[1] * (1 - t) + c2[1] * t).round(),
        (c1[2] * (1 - t) + c2[2] * t).round(),
      );
    }
  }
  for (var i = 0; i < 30; i++) {
    final color = img.ColorRgb8(
      rnd.nextInt(256),
      rnd.nextInt(256),
      rnd.nextInt(256),
    );
    final x = rnd.nextInt(size);
    final y = rnd.nextInt(size);
    final r = size ~/ 40 + rnd.nextInt(size ~/ 6);
    if (rnd.nextBool()) {
      img.fillCircle(image, x: x, y: y, radius: r, color: color);
    } else {
      img.fillRect(
        image,
        x1: x,
        y1: y,
        x2: x + r,
        y2: y + r ~/ 2,
        color: color,
      );
    }
  }
  return image;
}

void main() {
  final dir = Directory('test/fixtures/similar')..createSync(recursive: true);
  void write(String name, img.Image image, {int quality = 90}) =>
      File('${dir.path}/$name')
          .writeAsBytesSync(img.encodeJpg(image, quality: quality));

  final base = scene(1);
  write('base.jpg', base);
  write(
    'resized.jpg',
    img.copyResize(base, width: 160, interpolation: img.Interpolation.average),
  );
  write('recompressed.jpg', base, quality: 25);
  write('unrelated.jpg', scene(2));
  write('blurred.jpg', img.gaussianBlur(base.clone(), radius: 4));
}
