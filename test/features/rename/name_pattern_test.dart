import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/rename/domain/name_pattern.dart';

NameSource _f(String name, [DateTime? date]) =>
    (originalName: name, date: date ?? DateTime(2026, 7, 4, 12));

void main() {
  final three = [_f('IMG_1.jpg'), _f('VID_2.mp4'), _f('IMG_3.JPG')];

  test('counter with start and padding; each file keeps its extension', () {
    expect(buildNames(const NamePattern(template: 'holiday_{n}'), three), [
      'holiday_001.jpg',
      'holiday_002.mp4',
      'holiday_003.JPG',
    ]);
    expect(
      buildNames(
        const NamePattern(template: 'trip {n}', start: 9, padding: 2),
        three,
      ),
      ['trip 09.jpg', 'trip 10.mp4', 'trip 11.JPG'],
    );
  });

  test('{date} and {orig}', () {
    expect(
      buildNames(const NamePattern(template: '{date}_{orig}_{n}', padding: 1), [
        _f('beach.png', DateTime(2025, 12, 31, 23)),
      ]),
      ['2025-12-31_beach_1.png'],
    );
  });

  test('a file without extension stays without one', () {
    expect(buildNames(const NamePattern(template: 'doc_{n}'), [_f('README')]), [
      'doc_001',
    ]);
  });

  test('validation', () {
    PatternError? v(String t, [List<NameSource>? files]) =>
        validatePattern(NamePattern(template: t), files ?? three);
    expect(v('holiday_{n}'), isNull);
    expect(v('   '), PatternError.empty);
    expect(v('a/b_{n}'), PatternError.invalidChars);
    expect(v('a:b_{n}'), PatternError.invalidChars);
    expect(v('a?{n}'), PatternError.invalidChars);
    expect(v('holiday'), PatternError.needsCounter);
    expect(v('holiday', [_f('x.jpg')]), isNull);
    expect(v('${'x' * 200}{n}'), PatternError.tooLong);
  });

  test('JSON round trip; bad data throws', () {
    const p = NamePattern(template: 'a_{n}', start: 0, padding: 4);
    expect(NamePattern.fromJson(p.toJson()), p);
    expect(
      () => NamePattern.fromJson(const {
        'template': 'a',
        'start': 1,
        'padding': 9,
      }),
      throwsFormatException,
    );
    expect(() => NamePattern.fromJson(const {}), throwsFormatException);
  });
}
