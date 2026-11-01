import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/ai_labels/domain/label_map.dart';

void main() {
  final classifierNames = File('assets/ai/classifier_labels.txt')
      .readAsLinesSync();
  final detectorNames = File('assets/ai/detector_labels.txt').readAsLinesSync();
  final map = LabelMap.parse(File(LabelMap.assetPath).readAsStringSync());

  group("indices match the models' own label lists", () {
    test('the committed lists have the pinned lengths', () {
      expect(classifierNames, hasLength(1000));
      expect(detectorNames, hasLength(90));
    });

    test('every classifier entry names its ImageNet class', () {
      for (final MapEntry(:key, :value) in map.classifier.entries) {
        expect(key, inInclusiveRange(0, 999));
        expect(classifierNames[key], value.rawName, reason: 'index $key');
      }
    });

    test("every detector entry names its COCO class; never a '???'", () {
      for (final MapEntry(:key, :value) in map.detector.entries) {
        expect(key, inInclusiveRange(0, 89));
        expect(detectorNames[key], value.rawName, reason: 'index $key');
        expect(value.rawName, isNot('???'));
      }
    });

    test('spot checks of the intended classes', () {
      String c(int i) => map.classifier[i]!.rawName;
      String d(int i) => map.detector[i]!.rawName;
      expect(c(281), 'tabby');
      expect(c(978), 'seashore');
      expect(c(963), 'pizza');
      expect(c(922), 'menu');
      expect(c(916), 'web site');
      expect(c(549), 'envelope');
      expect(d(LabelMap.personClass), 'person');
      expect(d(16), 'cat');
      expect(d(17), 'dog');
    });

    test('no label is stored under a raw model name', () {
      for (final l in map.vocabulary) {
        expect(l, l.toLowerCase());
        expect(l.length, inInclusiveRange(1, 64));
      }
    });
  });

  test('vocabulary: plan labels + crowd + the 11 colours', () {
    expect(
      map.vocabulary,
      containsAll([
        'animal',
        'cat',
        'dog',
        'pet',
        'bird',
        'insect',
        'food',
        'fruit',
        'vegetable',
        'dessert',
        'beach',
        'sea',
        'lake',
        'mountain',
        'person',
        'crowd',
        'vehicle',
        'car',
        'bus',
        'bicycle',
        'motorcycle',
        'truck',
        'document',
        'color:blue',
        'color:gray',
      ]),
    );
    expect(map.vocabulary.where((l) => l.startsWith('color:')), hasLength(11));
    // Not available from these models (C4 must not expand to them).
    expect(map.vocabulary, isNot(contains('selfie')));
    expect(map.vocabulary, isNot(contains('smile')));
  });

  List<double> probs(Map<int, double> p) => [
    for (var i = 0; i < 1000; i++) p[i] ?? 0,
  ];
  Map<String, double> asMap(List<LabelScore> l) => {
    for (final (k, v) in l) k: v,
  };

  group('labelsFrom', () {
    test('a tabby at 0.8 gives cat, pet and animal', () {
      final out = asMap(map.labelsFrom(probs({281: 0.8}), const []));
      expect(out, {'cat': 0.8, 'pet': 0.8, 'animal': 0.8});
    });

    test('classifier threshold is 0.30 and only the top 5 count', () {
      expect(map.labelsFrom(probs({978: 0.29}), const []), isEmpty);
      expect(asMap(map.labelsFrom(probs({978: 0.30}), const [])), {
        'beach': 0.30,
        'sea': 0.30,
      });
      // Six classes above 0.30 can't happen with softmax, but the cut is
      // by rank: the 6th best never counts.
      final many = probs({
        281: 0.9,
        963: 0.8,
        978: 0.7,
        975: 0.6,
        970: 0.5,
        922: 0.4,
      });
      expect(
        asMap(map.labelsFrom(many, const [])).keys,
        isNot(contains('document')),
      );
    });

    test('detector: score >= 0.5; person boxes count towards crowd', () {
      const person = LabelMap.personClass;
      expect(
        map.labelsFrom(probs({}), const [Detection(person, 0.49)]),
        isEmpty,
      );
      final three = asMap(
        map.labelsFrom(probs({}), [
          for (var i = 0; i < 3; i++) const Detection(person, 0.7),
          const Detection(person, 0.3),
        ]),
      );
      expect(three, {'person': 0.7});
      final five = asMap(
        map.labelsFrom(probs({}), [
          for (var i = 0; i < 4; i++) const Detection(person, 0.6),
          const Detection(person, 0.9),
        ]),
      );
      expect(five, {'person': 0.9, 'crowd': 0.9});
    });

    test('unmapped and placeholder classes give nothing', () {
      // 11 is '???' in the 90-id layout.
      expect(
        map.labelsFrom(probs({398: 0.9}), const [Detection(11, 0.99)]),
        isEmpty,
      );
    });

    test('a label keeps its highest source score, clamped to 0..1', () {
      final out = asMap(
        map.labelsFrom(probs({281: 0.6}), const [Detection(16, 1.2)]),
      );
      expect(out['cat'], 1.0);
      expect(out['animal'], 1.0);
      expect(out['pet'], 1.0);
    });
  });
}
