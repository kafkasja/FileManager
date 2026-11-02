import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/layout/handed.dart';

void main() {
  test('secondarySide: right-handed = start (left), left-handed = end', () {
    expect(secondarySide(Handedness.right), MainAxisAlignment.start);
    expect(secondarySide(Handedness.left), MainAxisAlignment.end);
  });

  test('mirroredFor keeps the order right-handed and reverses it left', () {
    const a = SizedBox(key: ValueKey('a'));
    const b = SizedBox(key: ValueKey('b'));
    const c = SizedBox(key: ValueKey('c'));
    expect(mirroredFor(Handedness.right, const [a, b, c]), [a, b, c]);
    expect(mirroredFor(Handedness.left, const [a, b, c]), [c, b, a]);
  });

  test('reverseHorizontalFor puts the first item at the physical side', () {
    expect(reverseHorizontalFor(Handedness.right, TextDirection.ltr), isFalse);
    expect(reverseHorizontalFor(Handedness.left, TextDirection.ltr), isTrue);
    expect(reverseHorizontalFor(Handedness.right, TextDirection.rtl), isTrue);
    expect(reverseHorizontalFor(Handedness.left, TextDirection.rtl), isFalse);
  });
}
