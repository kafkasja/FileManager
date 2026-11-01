import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/domain/fingerprint_words.dart';

void main() {
  const a = 'aa11223344556677889900aabbccddeeff00112233445566778899aabbccddee';
  const b = '0f1e2d3c4b5a69788796a5b4c3d2e1f00f1e2d3c4b5a69788796a5b4c3d2e1f0';

  test('the list has 256 distinct lowercase words', () {
    expect(kFingerprintWordList, hasLength(256));
    expect(kFingerprintWordList.toSet(), hasLength(256));
    for (final w in kFingerprintWordList) {
      expect(w, matches(RegExp(r'^[a-z]+$')));
    }
  });

  test('deterministic: 4 words, same inputs → same words', () {
    final w = fingerprintWords(a, b);
    expect(w, hasLength(4));
    expect(fingerprintWords(a, b), w);
  });

  test('order matters: swapping server and client gives other words', () {
    expect(fingerprintWords(a, b), isNot(fingerprintWords(b, a)));
  });

  test('a different client fingerprint gives other words', () {
    expect(fingerprintWords(a, b), isNot(fingerprintWords(a, '${b}0')));
  });

  test('fixed vector (protocol v1: the list must never change)', () {
    // sha256("ab") = fb8e20fc… → bytes 251, 142, 32, 252.
    expect(fingerprintWords('a', 'b'), ['wolf', 'monkey', 'candle', 'yogurt']);
    expect(kFingerprintWordList.first, 'acorn');
    expect(kFingerprintWordList.last, 'zinc');
  });
}
