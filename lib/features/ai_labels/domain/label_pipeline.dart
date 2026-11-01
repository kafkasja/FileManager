import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:kfm/features/ai_labels/domain/dominant_colors.dart';
import 'package:kfm/features/ai_labels/domain/label_map.dart';

/// Classifier input edge (EfficientNet-Lite0: 224×224 RGB uint8).
const int kClassifierInput = 224;

/// Detector input edge (EfficientDet-Lite0: 320×320 RGB uint8).
const int kDetectorInput = 320;

/// Colours are counted on a small copy (fast, same shares).
const int kColorSampleEdge = 64;

/// The two models, behind an interface so the pipeline and the worker can
/// be tested without native code (the real one is `TfliteImageModels`).
abstract interface class ImageModels {
  /// ImageNet probabilities (1000) for packed RGB [kClassifierInput]².
  List<double> classify(Uint8List rgb);

  /// COCO boxes (no threshold applied) for packed RGB [kDetectorInput]².
  List<Detection> detect(Uint8List rgb);

  void close();
}

/// Thrown for thumbnails `package:image` can't decode.
class UndecodableImageException implements Exception {
  const new();

  @override
  String toString() => 'UndecodableImageException: thumbnail not decodable';
}

/// Decodes [encoded] (a JPEG thumbnail), runs both models and the colour
/// count, and maps everything to KFM labels. Runs in the worker isolate.
List<LabelScore> labelImage(
  Uint8List encoded,
  ImageModels models,
  LabelMap map,
) {
  final decoded = img.decodeImage(encoded);
  if (decoded == null) throw const UndecodableImageException();
  final image = decoded.numChannels == 3 && decoded.bitsPerChannel == 8
      ? decoded
      : decoded.convert(numChannels: 3, format: img.Format.uint8);
  // Models see the centre square (thumbnails keep the photo's aspect);
  // colours count the whole picture.
  final probs = models.classify(rgbOf(image, kClassifierInput, crop: true));
  final boxes = models.detect(rgbOf(image, kDetectorInput, crop: true));
  return [
    ...map.labelsFrom(probs, boxes),
    ...dominantColors(rgbOf(image, kColorSampleEdge)),
  ];
}

/// Packed RGB bytes of [image] at [edge]×[edge]: the centre square when
/// [crop], otherwise stretched.
Uint8List rgbOf(img.Image image, int edge, {bool crop = false}) {
  final img.Image resized;
  if (image.width == edge && image.height == edge) {
    resized = image;
  } else if (crop) {
    resized = img.copyResizeCropSquare(
      image,
      size: edge,
      interpolation: img.Interpolation.linear,
    );
  } else {
    resized = img.copyResize(
      image,
      width: edge,
      height: edge,
      interpolation: img.Interpolation.linear,
    );
  }
  return resized.getBytes(order: img.ChannelOrder.rgb);
}
