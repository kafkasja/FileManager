import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kfm/core/utils/format.dart';

void main() {
  setUpAll(() => initializeDateFormatting('nl'));

  test('formatBytes', () {
    expect(formatBytes(0, locale: 'en'), '0 B');
    expect(formatBytes(1023, locale: 'en'), '1,023 B');
    expect(formatBytes(1536, locale: 'en'), '1.5 KB');
    expect(formatBytes(12 * 1024 * 1024, locale: 'en'), '12 MB');
    expect(formatBytes(150 * 1024 * 1024, locale: 'en'), '150 MB');
    expect(formatBytes(1536 * 1024 * 1024, locale: 'en'), '1.5 GB');
    expect(formatBytes(1536, locale: 'nl'), '1,5 KB');
  });

  test('formatDate', () {
    final d = DateTime(2026, 10, 23, 12);
    expect(formatDate(d, locale: 'en'), 'Oct 23, 2026');
    expect(formatDate(d, locale: 'nl'), '23 okt 2026');
  });
}
