import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:kfm/features/similar/domain/luma.dart';

/// Longest side the blur score is measured on: the default threshold (100)
/// is calibrated for 256 px thumbnails.
const kBlurMaxSide = 256;

/// Variance of the Laplacian of the grayscale image, downscaled so its
/// longest side is at most [kBlurMaxSide] (TASK-C2). Lower = blurrier.
double blurScoreOf(img.Image image) {
  var src = image;
  if (math.max(src.width, src.height) > kBlurMaxSide) {
    src = src.width >= src.height
        ? img.copyResize(
            src,
            width: kBlurMaxSide,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            src,
            height: kBlurMaxSide,
            interpolation: img.Interpolation.average,
          );
  }
  final w = src.width;
  final h = src.height;
  if (w < 3 || h < 3) return 0;
  final luma = lumaOf(src);
  var sum = 0.0;
  var sumSq = 0.0;
  var n = 0;
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final i = y * w + x;
      final lap =
          luma[i - w] + luma[i + w] + luma[i - 1] + luma[i + 1] - 4 * luma[i];
      sum += lap;
      sumSq += lap * lap;
      n++;
    }
  }
  final mean = sum / n;
  return sumSq / n - mean * mean;
}
