import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/ai_labels/domain/dominant_colors.dart';
import 'package:kfm/features/ai_labels/domain/label_map.dart';

Uint8List solid(int r, int g, int b, [int pixels = 100]) => Uint8List.fromList([
  for (var i = 0; i < pixels; i++) ...[r, g, b],
]);

void main() {
  test('solid fixtures map to their colour name', () {
    const cases = {
      'red': (220, 20, 30),
      'orange': (245, 140, 20),
      'yellow': (240, 220, 40),
      'green': (40, 170, 60),
      'blue': (40, 110, 220),
      'purple': (120, 50, 200),
      'pink': (240, 110, 190),
      'brown': (120, 70, 30),
      'black': (10, 10, 10),
      'white': (250, 250, 250),
      'gray': (128, 128, 128),
    };
    expect(cases.keys.toSet(), kColorNames.toSet());
    for (final MapEntry(key: name, value: (r, g, b)) in cases.entries) {
      expect(dominantColors(solid(r, g, b)), [('color:$name', 1.0)]);
    }
  });

  test('a mostly blue sky gets color:blue with its pixel share', () {
    final sky = Uint8List.fromList([
      ...solid(90, 150, 230, 70),
      ...solid(250, 250, 250, 15),
      ...solid(40, 170, 60, 15),
    ]);
    final out = {for (final (l, c) in dominantColors(sky)) l: c};
    expect(out, {'color:blue': closeTo(0.70, 1e-9)});
  });

  test('colours below 20% are left out; two big ones both count', () {
    final img = Uint8List.fromList([
      ...solid(220, 20, 30, 50),
      ...solid(40, 110, 220, 30),
      ...solid(40, 170, 60, 20),
    ]);
    final out = {for (final (l, c) in dominantColors(img)) l: c};
    expect(
      out.keys,
      unorderedEquals(['color:red', 'color:blue', 'color:green']),
    );
    final small = Uint8List.fromList([
      ...solid(220, 20, 30, 81),
      ...solid(40, 110, 220, 19),
    ]);
    expect(dominantColors(small).map((e) => e.$1), ['color:red']);
  });

  test('empty input gives nothing', () {
    expect(dominantColors(Uint8List(0)), isEmpty);
  });
}
