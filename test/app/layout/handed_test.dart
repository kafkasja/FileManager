import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/layout/handed.dart';

void main() {
  test('thumbSide: right-handed = right (end), left-handed = left', () {
    expect(thumbSide(Handedness.right), MainAxisAlignment.end);
    expect(thumbSide(Handedness.left), MainAxisAlignment.start);
  });

  test('thumbFirst puts the first item at the thumb', () {
    const a = SizedBox(key: ValueKey('a'));
    const b = SizedBox(key: ValueKey('b'));
    expect(thumbFirst(Handedness.right, const [a, b]), [b, a]);
    expect(thumbFirst(Handedness.left, const [a, b]), [a, b]);
  });

  test('thumbFabLocation: physical thumb side in either direction', () {
    expect(
      thumbFabLocation(Handedness.right, TextDirection.ltr),
      FloatingActionButtonLocation.endFloat,
    );
    expect(
      thumbFabLocation(Handedness.left, TextDirection.ltr),
      FloatingActionButtonLocation.startFloat,
    );
    expect(
      thumbFabLocation(Handedness.right, TextDirection.rtl),
      FloatingActionButtonLocation.startFloat,
    );
  });

  test('every FAB sits on the thumb side (rule)', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      if (src.contains('floatingActionButton:') &&
          !src.contains('thumbFabLocation(')) {
        offenders.add(f.path);
      }
    }
    expect(offenders, isEmpty, reason: 'use thumbFabLocation');
  });

  test('mirroredFor keeps the order right-handed and reverses it left', () {
    const a = SizedBox(key: ValueKey('a'));
    const b = SizedBox(key: ValueKey('b'));
    const c = SizedBox(key: ValueKey('c'));
    expect(mirroredFor(Handedness.right, const [a, b, c]), [a, b, c]);
    expect(mirroredFor(Handedness.left, const [a, b, c]), [c, b, a]);
  });

  test('reverseHorizontalFor puts the first item at the thumb side', () {
    expect(reverseHorizontalFor(Handedness.right, TextDirection.ltr), isTrue);
    expect(reverseHorizontalFor(Handedness.left, TextDirection.ltr), isFalse);
    expect(reverseHorizontalFor(Handedness.right, TextDirection.rtl), isFalse);
    expect(reverseHorizontalFor(Handedness.left, TextDirection.rtl), isTrue);
  });
}
