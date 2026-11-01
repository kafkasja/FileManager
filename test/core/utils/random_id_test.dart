import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/utils/random_id.dart';

void main() {
  test('32 lowercase hex chars, from the given Random', () {
    final id = randomHexId(Random(1));
    expect(id, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(randomHexId(Random(1)), id);
    expect(randomHexId(), isNot(randomHexId()));
  });
}
