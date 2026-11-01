import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kfm/core/index/blur_rule.dart';
import 'package:kfm/features/similar/domain/best_pick.dart';
import 'package:kfm/features/similar/domain/blur.dart';
import 'package:kfm/features/similar/domain/dhash.dart';
import 'package:kfm/features/similar/domain/grouping.dart';
import 'package:kfm/features/similar/domain/signals.dart';

import 'similar_test_utils.dart';

img.Image decode(String name) => img.decodeImage(fixture(name))!;

void main() {
  group('dHash', () {
    final baseHash = dHashOf(decode('base'));

    test('identical bytes give the same hash', () {
      expect(dHashOf(decode('base')), baseHash);
    });

    test('resized and recompressed copies are within strict distance', () {
      expect(
        hammingDistance(baseHash, dHashOf(decode('resized'))),
        lessThanOrEqualTo(maxDistanceFor('strict')),
      );
      expect(
        hammingDistance(baseHash, dHashOf(decode('recompressed'))),
        lessThanOrEqualTo(maxDistanceFor('strict')),
      );
    });

    test('an unrelated photo is beyond loose distance', () {
      expect(
        hammingDistance(baseHash, dHashOf(decode('unrelated'))),
        greaterThan(maxDistanceFor('loose')),
      );
    });

    test('hamming distance counts bits, also the sign bit', () {
      expect(hammingDistance(0, 0), 0);
      expect(hammingDistance(0, -1), 64);
      expect(hammingDistance(0x0F, 0x01), 3);
      expect(hammingDistance(1 << 63, 0), 1);
    });
  });

  group('blur score (default threshold 100 on 256 px)', () {
    test('sharp fixtures score >= 100, the blurred one < 100', () {
      for (final name in ['base', 'resized', 'recompressed', 'unrelated']) {
        final score = blurScoreOf(decode(name));
        expect(score, greaterThanOrEqualTo(100), reason: name);
        expect(isBlurry(score, 100), isFalse, reason: name);
      }
      final blurred = blurScoreOf(decode('blurred'));
      expect(blurred, lessThan(100));
      expect(isBlurry(blurred, 100), isTrue);
    });

    test('large images are measured at <= 256 px', () {
      final big = img.copyResize(
        decode('base'),
        width: 1024,
      ); // nearest (the default): exact 4x pixel copies
      // 4x pixel copies, averaged back down to 256 px = the original.
      final original = blurScoreOf(decode('base'));
      expect(blurScoreOf(big), closeTo(original, original * 0.05));
    });

    test('a flat image scores 0', () {
      final flat = img.Image(width: 50, height: 50)
        ..clear(img.ColorRgb8(80, 80, 80));
      expect(blurScoreOf(flat), closeTo(0, 1e-9));
    });
  });

  test('computeSignals: ok rows and failed rows for corrupt bytes', () {
    final result = computeSignals([
      ('a', fixture('base')),
      ('b', Uint8List.fromList([1, 2, 3, 4])),
      ('c', Uint8List.sublistView(fixture('base'), 0, 200)),
    ]);
    expect(result.map((r) => r.fileId), ['a', 'b', 'c']);
    expect(result[0].ok, isTrue);
    expect(result[0].dHash, dHashOf(decode('base')));
    expect(result[1].ok, isFalse);
    expect(result[1].dHash, isNull);
    expect(result[2].ok, isFalse);
  });

  group('compareBest', () {
    ScoredImage s(String id, double blur, {int w = 10, int size = 1}) =>
        ScoredImage(
          file: photo(id, size: size, width: w, height: w),
          dHash: 0,
          blurScore: blur,
        );

    test('sharpest first; resolution then size break ties', () {
      final list = [
        s('blurry', 50, w: 4000),
        s('sharp', 300),
        s('sharp-big', 200, w: 20),
        s('sharp-big-heavy', 200, w: 20, size: 9),
      ]..sort(compareBest);
      expect(list.map((e) => e.file.id), [
        'sharp',
        'sharp-big-heavy',
        'sharp-big',
        'blurry',
      ]);
    });
  });

  group('groupSimilar', () {
    SignalPoint p(String id, int minute, int hash, {double blur = 200}) =>
        SignalPoint(
          fileId: id,
          sortDateMs: base
              .add(Duration(minutes: minute))
              .millisecondsSinceEpoch,
          dHash: hash,
          blurScore: blur,
          sizeBytes: 1,
        );

    test('near hashes within 10 minutes form one group, best first', () {
      final groups = groupSimilar([
        p('a', 0, 0x00, blur: 150),
        p('b', 1, 0x01, blur: 300),
        p('c', 2, 0x03, blur: 100),
        p('far', 3, -1),
      ], maxDistance: 6);
      expect(groups, [
        ['b', 'a', 'c'],
      ]);
    });

    test('the same hash hours apart is never grouped', () {
      expect(
        groupSimilar([p('a', 0, 7), p('b', 180, 7)], maxDistance: 10),
        isEmpty,
      );
    });

    test('chains join through the window; groups newest first', () {
      final groups = groupSimilar([
        p('x1', 0, 0),
        p('x2', 9, 0),
        p('x3', 18, 0), // 18 min after x1 but 9 after x2
        p('y1', 100, 0xFF00),
        p('y2', 101, 0xFF00),
      ], maxDistance: 10);
      expect(groups.length, 2);
      expect(groups.first.toSet(), {'y1', 'y2'});
      expect(groups.last.toSet(), {'x1', 'x2', 'x3'});
    });

    test('strictness maps to distances', () {
      expect(maxDistanceFor('loose'), 14);
      expect(maxDistanceFor('normal'), 10);
      expect(maxDistanceFor('strict'), 6);
      expect(maxDistanceFor('bogus'), 10);
    });
  });
}
