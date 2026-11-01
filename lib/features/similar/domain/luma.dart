import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Grayscale (Rec. 601 luma, 0–255) of [image], row-major.
Float64List lumaOf(img.Image image) {
  final w = image.width;
  final out = Float64List(w * image.height);
  for (final p in image) {
    final max = p.maxChannelValue;
    final scale = max == 0 ? 0 : 255 / max;
    out[p.y * w + p.x] = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b) * scale;
  }
  return out;
}
