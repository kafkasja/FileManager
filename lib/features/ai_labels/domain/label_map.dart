import 'dart:convert';

import 'package:meta/meta.dart';

/// Classifier: top-5 classes with at least this probability (TASK-C3 §2).
const int kClassifierTopK = 5;
const double kClassifierMinProbability = 0.30;

/// Detector: boxes with at least this score.
const double kDetectorMinScore = 0.50;

/// The 11 colour names of `dominantColors` (`color:<name>` labels).
const List<String> kColorNames = [
  'red',
  'orange',
  'yellow',
  'green',
  'blue',
  'purple',
  'pink',
  'brown',
  'black',
  'white',
  'gray',
];

/// One detector box (class index into `detector_labels.txt`, score 0–1).
@immutable
class Detection {
  const new(this.classIndex, this.score);

  final int classIndex;
  final double score;

  @override
  bool operator ==(Object other) =>
      other is Detection &&
      other.classIndex == classIndex &&
      other.score == score;

  @override
  int get hashCode => Object.hash(classIndex, score);

  @override
  String toString() => 'Detection($classIndex, $score)';
}

/// A KFM label with its confidence (0–1).
typedef LabelScore = (String label, double confidence);

/// One mapped model output: the raw name it must have (checked against the
/// committed label lists by `label_map_test`) and the KFM labels it gives.
@immutable
class LabelMapEntry {
  const new({required this.rawName, required this.labels});

  final String rawName;
  final List<String> labels;
}

/// `assets/ai/label_map.json`: model output index → KFM labels. Raw
/// ImageNet/COCO names are never stored, only KFM labels.
@immutable
class LabelMap {
  const new({
    required this.mapVersion,
    required this.crowdMinPersons,
    required this.classifier,
    required this.detector,
  });

  factory parse(String json) {
    final root = jsonDecode(json) as Map<String, Object?>;
    Map<int, LabelMapEntry> section(String key) => {
      for (final MapEntry(:key, :value)
          in (root[key]! as Map<String, Object?>).entries)
        int.parse(key): _entry(value! as Map<String, Object?>),
    };
    return LabelMap(
      mapVersion: root['mapVersion']! as int,
      crowdMinPersons: root['crowdMinPersons']! as int,
      classifier: section('classifier'),
      detector: section('detector'),
    );
  }

  static LabelMapEntry _entry(Map<String, Object?> e) => LabelMapEntry(
    rawName: e['name']! as String,
    labels: [for (final l in e['labels']! as List<Object?>) l! as String],
  );

  static const String assetPath = 'assets/ai/label_map.json';

  /// The detector's `person` class (COCO id 0).
  static const int personClass = 0;

  /// The label for ≥ [crowdMinPersons] people.
  static const String crowdLabel = 'crowd';

  final int mapVersion;
  final int crowdMinPersons;
  final Map<int, LabelMapEntry> classifier;
  final Map<int, LabelMapEntry> detector;

  /// Every label KFM can store (C4's keyword family reads it).
  Set<String> get vocabulary => {
    for (final e in classifier.values) ...e.labels,
    for (final e in detector.values) ...e.labels,
    crowdLabel,
    for (final c in kColorNames) 'color:$c',
  };

  /// KFM labels from the raw model outputs: classifier top-5 ≥ 0.30,
  /// detector boxes ≥ 0.50, `crowd` from the person count. A label's
  /// confidence is the highest source score that produced it, clamped 0–1.
  List<LabelScore> labelsFrom(
    List<double> classifierProbs,
    List<Detection> detections,
  ) {
    final best = <String, double>{};
    void put(String label, double score) {
      final s = score.clamp(0.0, 1.0);
      final old = best[label];
      if (old == null || s > old) best[label] = s;
    }

    final ranked = [for (var i = 0; i < classifierProbs.length; i++) i]
      ..sort((a, b) => classifierProbs[b].compareTo(classifierProbs[a]));
    for (final i in ranked.take(kClassifierTopK)) {
      final p = classifierProbs[i];
      if (p < kClassifierMinProbability) break;
      for (final l in classifier[i]?.labels ?? const <String>[]) {
        put(l, p);
      }
    }
    var persons = 0;
    var personBest = 0.0;
    for (final d in detections) {
      if (d.score < kDetectorMinScore) continue;
      if (d.classIndex == personClass) {
        persons++;
        if (d.score > personBest) personBest = d.score;
      }
      for (final l in detector[d.classIndex]?.labels ?? const <String>[]) {
        put(l, d.score);
      }
    }
    if (persons >= crowdMinPersons) put(crowdLabel, personBest);
    return [for (final MapEntry(:key, :value) in best.entries) (key, value)];
  }
}
