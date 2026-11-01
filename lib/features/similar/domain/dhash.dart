import 'package:image/image.dart' as img;
import 'package:kfm/features/similar/domain/luma.dart';

/// 64-bit difference hash (TASK-C2): grayscale, resize to 9×8, one bit per
/// "left pixel brighter than its right neighbour". Stored as a signed
/// 64-bit int (bit 63 is the sign bit).
int dHashOf(img.Image image) {
  final small = img.copyResize(
    image,
    width: 9,
    height: 8,
    interpolation: img.Interpolation.average,
  );
  final luma = lumaOf(small);
  var hash = 0;
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      hash <<= 1;
      if (luma[y * 9 + x] > luma[y * 9 + x + 1]) hash |= 1;
    }
  }
  return hash;
}

/// Number of differing bits of two hashes (0–64).
int hammingDistance(int a, int b) {
  var x = a ^ b;
  var count = 0;
  while (x != 0) {
    x &= x - 1; // clears the lowest set bit (also for negative values)
    count++;
  }
  return count;
}
