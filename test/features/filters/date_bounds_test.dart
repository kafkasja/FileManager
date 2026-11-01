import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/filters/data/filter_query.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';

void main() {
  final now = DateTime(2026, 6, 15, 18, 30);

  test('any: no bounds', () {
    final b = dateBounds(const DateAny(), now);
    expect(b.from, isNull);
    expect(b.to, isNull);
  });

  test('this month: local 1st .. next 1st, UTC', () {
    final b = dateBounds(const DateThisMonth(), now);
    expect(b.from, DateTime(2026, 6).toUtc());
    expect(b.to, DateTime(2026, 7).toUtc());
    expect(b.from!.isUtc, isTrue);
  });

  test('this month in December rolls into the next year', () {
    final b = dateBounds(const DateThisMonth(), DateTime(2026, 12, 31, 23));
    expect(b.to, DateTime(2027).toUtc());
  });

  test('last days: today and days-1 before, open end', () {
    expect(
      dateBounds(const DateLastDays(1), now).from,
      DateTime(2026, 6, 15).toUtc(),
    );
    final week = dateBounds(const DateLastDays(7), now);
    expect(week.from, DateTime(2026, 6, 9).toUtc());
    expect(week.to, isNull);
    // Across a month boundary.
    expect(
      dateBounds(const DateLastDays(20), now).from,
      DateTime(2026, 5, 27).toUtc(),
    );
  });

  test('range: inclusive local days, end exclusive the day after', () {
    final b = dateBounds(
      DateRange(DateTime(2026, 2, 3, 14), DateTime(2026, 2, 28, 1)),
      now,
    );
    expect(b.from, DateTime(2026, 2, 3).toUtc());
    expect(b.to, DateTime(2026, 3).toUtc());
  });
}
