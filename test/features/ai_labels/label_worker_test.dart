import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kfm/features/ai_labels/data/label_worker.dart';
import 'package:kfm/features/ai_labels/data/tflite_models.dart';
import 'package:kfm/features/ai_labels/domain/label_map.dart';
import 'package:kfm/features/ai_labels/domain/label_pipeline.dart';

/// Pretends to be both models: a tabby at 0.8 and [persons] people.
class FakeModels implements ImageModels {
  new({this.persons = 5, this.crashOnClassify = false});

  final int persons;
  final bool crashOnClassify;
  final List<int> classifyLengths = [];
  final List<int> detectLengths = [];

  @override
  List<double> classify(Uint8List rgb) {
    if (crashOnClassify) throw StateError('native crash');
    classifyLengths.add(rgb.length);
    return List.generate(1000, (i) => i == 281 ? 0.8 : 0.0002);
  }

  @override
  List<Detection> detect(Uint8List rgb) {
    detectLengths.add(rgb.length);
    return [
      for (var i = 0; i < persons; i++)
        const Detection(LabelMap.personClass, 0.9),
      const Detection(11, 0.99), // '???': never mapped
    ];
  }

  @override
  void close() {}
}

// Top-level factories: sent to the worker isolate.
ImageModels fakeModels(Uint8List c, Uint8List d) => FakeModels();
ImageModels crashingModels(Uint8List c, Uint8List d) =>
    FakeModels(crashOnClassify: true);
ImageModels failingModels(Uint8List c, Uint8List d) =>
    throw ArgumentError('Failed to load dynamic library');

Uint8List jpeg(int r, int g, int b, {int w = 320, int h = 240}) {
  final image = img.Image(width: w, height: h)..clear(img.ColorRgb8(r, g, b));
  return img.encodeJpg(image, quality: 90);
}

void main() {
  final mapJson = File(LabelMap.assetPath).readAsStringSync();
  final map = LabelMap.parse(mapJson);

  test('pipeline: resizes to 224 and 320 RGB, maps labels, adds colours', () {
    final models = FakeModels();
    final out = {
      for (final (l, c) in labelImage(jpeg(30, 90, 220), models, map)) l: c,
    };
    expect(models.classifyLengths, [224 * 224 * 3]);
    expect(models.detectLengths, [320 * 320 * 3]);
    expect(out.keys, containsAll(['cat', 'pet', 'animal', 'person', 'crowd']));
    expect(out['color:blue'], closeTo(1, 0.01));
    expect(out['cat'], closeTo(0.8, 1e-9));
  });

  test('pipeline: an undecodable thumbnail throws', () {
    expect(
      () => labelImage(Uint8List.fromList([1, 2, 3]), FakeModels(), map),
      throwsA(isA<UndecodableImageException>()),
    );
  });

  group('IsolateLabelWorker', () {
    Future<IsolateLabelWorker> spawn(ImageModelsFactory f) =>
        IsolateLabelWorker.spawn(
          classifier: Uint8List(4),
          detector: Uint8List(4),
          labelMapJson: mapJson,
          createModels: f,
        );

    test('labels in the isolate; a bad file fails only itself', () async {
      final w = await spawn(fakeModels);
      addTearDown(w.close);
      final labels = {for (final (l, _) in await w.label(jpeg(240, 20, 20))) l};
      expect(labels, containsAll(['cat', 'person', 'crowd', 'color:red']));
      await expectLater(
        w.label(Uint8List.fromList([0, 1])),
        throwsA(isA<LabelFailed>()),
      );
      // Still running.
      expect(await w.label(jpeg(20, 200, 40)), isNotEmpty);
    });

    test('a crash in the isolate is reported as LabelWorkerCrashed', () async {
      final w = await spawn(crashingModels);
      addTearDown(w.close);
      await expectLater(
        w.label(jpeg(1, 2, 3)),
        throwsA(isA<LabelWorkerCrashed>()),
      );
      await expectLater(
        w.label(jpeg(1, 2, 3)),
        throwsA(isA<LabelWorkerCrashed>()),
      );
    });

    test('a native load failure fails the start', () async {
      await expectLater(
        spawn(failingModels),
        throwsA(isA<LabelWorkerStartFailed>()),
      );
    });
  });

  // Real models: fetch them with `dart run tool/fetch_ai_models.dart`
  // (build/ai_models/). The TFLite C library must be loadable on the host,
  // which it isn't on Windows/macOS/Linux test machines today (only the
  // Android .so ships): then this is skipped with the reason, and the real
  // run is the device check in CHANGES.md.
  final c = File('build/ai_models/classifier.tflite');
  final d = File('build/ai_models/detector.tflite');
  String? skip;
  if (!c.existsSync() || !d.existsSync()) {
    skip = 'models not fetched (dart run tool/fetch_ai_models.dart)';
  } else {
    try {
      TfliteImageModels.fromBuffers(
        c.readAsBytesSync(),
        d.readAsBytesSync(),
      ).close();
    } on Object catch (e) {
      skip = 'TFLite C library not loadable on this host: $e';
    }
  }
  test('real models: a blue fixture gets color:blue and no crash', () {
    final models = TfliteImageModels.fromBuffers(
      c.readAsBytesSync(),
      d.readAsBytesSync(),
    );
    addTearDown(models.close);
    final labels = {
      for (final (l, _) in labelImage(jpeg(40, 110, 220), models, map)) l,
    };
    expect(labels, contains('color:blue'));
  }, skip: skip);
}
