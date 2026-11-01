import 'dart:typed_data';

import 'package:kfm/features/ai_labels/domain/label_map.dart';

/// A colour covering at least this share of the pixels becomes a label.
const double kColorMinShare = 0.20;

/// `color:<name>` labels for the colours covering ≥ [minShare] of the
/// pixels, confidence = the pixel share (TASK-C3 §3). [rgb] is packed
/// 8-bit RGB (3 bytes per pixel). Pure Dart; runs in the worker isolate.
List<LabelScore> dominantColors(
  Uint8List rgb, {
  double minShare = kColorMinShare,
}) {
  final pixels = rgb.length ~/ 3;
  if (pixels == 0) return const [];
  final counts = List<int>.filled(kColorNames.length, 0);
  for (var i = 0; i + 2 < rgb.length; i += 3) {
    counts[colorIndexOf(rgb[i], rgb[i + 1], rgb[i + 2])]++;
  }
  return [
    for (var c = 0; c < counts.length; c++)
      if (counts[c] / pixels >= minShare)
        ('color:${kColorNames[c]}', counts[c] / pixels),
  ];
}

/// Index into [kColorNames] for one pixel (HSV buckets).
int colorIndexOf(int r, int g, int b) {
  final max = r > g ? (r > b ? r : b) : (g > b ? g : b);
  final min = r < g ? (r < b ? r : b) : (g < b ? g : b);
  final v = max / 255;
  final delta = max - min;
  final s = max == 0 ? 0.0 : delta / max;
  if (v < 0.18) return _black;
  if (s < 0.15) {
    if (v > 0.85) return _white;
    return v < 0.3 ? _black : _gray;
  }
  double h;
  if (max == r) {
    h = 60 * (((g - b) / delta) % 6);
  } else if (max == g) {
    h = 60 * ((b - r) / delta + 2);
  } else {
    h = 60 * ((r - g) / delta + 4);
  }
  if (h < 0) h += 360;
  if (h < 15 || h >= 345) {
    return s < 0.45 && v > 0.7 ? _pink : _red;
  }
  if (h < 45) return v < 0.6 ? _brown : _orange;
  if (h < 70) return v < 0.45 ? _brown : _yellow;
  if (h < 170) return _green;
  if (h < 260) return _blue;
  if (h < 290) return _purple;
  return _pink;
}

const int _red = 0;
const int _orange = 1;
const int _yellow = 2;
const int _green = 3;
const int _blue = 4;
const int _purple = 5;
const int _pink = 6;
const int _brown = 7;
const int _black = 8;
const int _white = 9;
const int _gray = 10;
