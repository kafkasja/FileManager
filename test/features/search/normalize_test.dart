import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/search/domain/normalize.dart';

void main() {
  test('trims and lowercases', () {
    expect(normalizeSearchWord('  Video '), 'video');
    expect(normalizeSearchWord('PDF'), 'pdf');
  });

  test('collapses inner whitespace', () {
    expect(normalizeSearchWord('Screen \t  Recording'), 'screen recording');
  });

  test('Turkish dotted and dotless i', () {
    expect(normalizeSearchWord('İstanbul'), 'istanbul');
    expect(normalizeSearchWord('ISTANBUL'), 'istanbul');
    expect(normalizeSearchWord('ılık'), 'ilik');
    expect(normalizeSearchWord('KIŞ'), 'kis');
  });

  test('strips diacritics', () {
    expect(normalizeSearchWord('köpek'), 'kopek');
    expect(normalizeSearchWord('KÖPEK'), 'kopek');
    expect(normalizeSearchWord('café'), 'cafe');
    expect(normalizeSearchWord('çağrı şüpheli'), 'cagri supheli');
    expect(normalizeSearchWord('Ölüdeniz'), 'oludeniz');
    expect(normalizeSearchWord('Straße'), 'strasse');
    expect(normalizeSearchWord('ñandú'), 'nandu');
  });

  test('combining marks are dropped', () {
    expect(normalizeSearchWord('café'), 'cafe');
    expect(normalizeSearchWord('ö'), 'o');
  });

  test('other scripts and digits pass through', () {
    expect(normalizeSearchWord('写真 2024'), '写真 2024');
    expect(normalizeSearchWord('.JPG'), '.jpg');
  });
}
