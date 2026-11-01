import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/utils/text_ranges.dart';

void main() {
  test('one range per match, case-insensitive', () {
    expect(highlightRanges('Q3_Report_2024.pdf', ['report', '2024']), [
      (3, 9),
      (10, 14),
    ]);
  });

  test('every occurrence; overlapping and touching ranges merge', () {
    expect(highlightRanges('abab', ['ab']), [(0, 4)]);
    expect(highlightRanges('invoice', ['voi', 'inv']), [(0, 5)]);
    expect(highlightRanges('aXa', ['a']), [(0, 1), (2, 3)]);
  });

  test('no match or empty words give nothing', () {
    expect(highlightRanges('photo.jpg', ['zz']), isEmpty);
    expect(highlightRanges('photo.jpg', ['']), isEmpty);
  });

  test('ö in the query matches Ö in the name', () {
    expect(highlightRanges('Ölüdeniz.jpg', ['ölü']), [(0, 3)]);
  });
}
