import 'dart:typed_data';

import 'package:kfm/features/ai_labels/domain/label_map.dart';
import 'package:kfm/features/ai_labels/domain/label_pipeline.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// EfficientNet-Lite0 int8 + EfficientDet-Lite0 on the TFLite C API
/// (`tflite_flutter`, LiteRT 1.4). CPU only (XNNPACK), no GPU, no NNAPI.
/// Created inside the worker isolate; opening the native library throws on
/// devices that can't load it (API < 26), which the worker reports.
class TfliteImageModels implements ImageModels {
  factory fromBuffers(Uint8List classifier, Uint8List detector) {
    Interpreter open(Uint8List bytes) {
      final options = InterpreterOptions()..threads = 2;
      return Interpreter.fromBuffer(bytes, options: options)..allocateTensors();
    }

    final c = open(classifier);
    try {
      return TfliteImageModels._(c, open(detector));
    } on Object {
      c.close();
      rethrow;
    }
  }

  new _(this._classifier, this._detector) {
    _check(_classifier.getInputTensor(0), kClassifierInput);
    _check(_detector.getInputTensor(0), kDetectorInput);
  }

  final Interpreter _classifier;
  final Interpreter _detector;

  static void _check(Tensor input, int edge) {
    if (input.type != TensorType.uint8 ||
        input.shape.join('x') != '1x${edge}x${edge}x3') {
      throw StateError('unexpected model input ${input.type} ${input.shape}');
    }
  }

  @override
  List<double> classify(Uint8List rgb) {
    _classifier.getInputTensor(0).data = rgb;
    _classifier.invoke();
    final out = _classifier.getOutputTensor(0);
    final data = out.data;
    if (out.type == TensorType.float32) return _floats(data);
    // uint8 softmax: prob = scale * (q - zeroPoint) (scale 1/256 here).
    final params = out.params;
    final scale = params.scale == 0 ? 1 / 256 : params.scale;
    return [for (final q in data) scale * (q - params.zeroPoint)];
  }

  @override
  List<Detection> detect(Uint8List rgb) {
    _detector.getInputTensor(0).data = rgb;
    _detector.invoke();
    // TFLite_Detection_PostProcess: boxes, classes, scores, count.
    final classes = _floats(_detector.getOutputTensor(1).data);
    final scores = _floats(_detector.getOutputTensor(2).data);
    final count = _floats(_detector.getOutputTensor(3).data).first.round();
    final n = [
      count,
      classes.length,
      scores.length,
    ].reduce((a, b) => a < b ? a : b);
    return [
      for (var i = 0; i < n; i++) Detection(classes[i].round(), scores[i]),
    ];
  }

  static List<double> _floats(Uint8List bytes) {
    final view = ByteData.sublistView(bytes);
    return [
      for (var i = 0; i + 3 < bytes.length; i += 4)
        view.getFloat32(i, Endian.little),
    ];
  }

  @override
  void close() {
    _classifier.close();
    _detector.close();
  }
}

/// The worker's model factory on device (a top-level tear-off is sendable
/// to the isolate).
ImageModels createTfliteModels(Uint8List classifier, Uint8List detector) =>
    TfliteImageModels.fromBuffers(classifier, detector);
