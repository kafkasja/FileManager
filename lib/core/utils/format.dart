import 'package:intl/intl.dart';

const _units = ['B', 'KB', 'MB', 'GB', 'TB'];

/// "0 B", "999 B", "1.5 KB", "12.3 MB", "120 GB" (1024-based), digits in
/// the given [locale] (null = current intl default).
String formatBytes(int bytes, {String? locale}) {
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < _units.length - 1) {
    value /= 1024;
    unit++;
  }
  final pattern = unit == 0 || value >= 100 ? '#,##0' : '#,##0.#';
  return '${NumberFormat(pattern, locale).format(value)} ${_units[unit]}';
}

/// Medium date in local time, e.g. "Oct 23, 2026".
String formatDate(DateTime date, {String? locale}) =>
    DateFormat.yMMMd(locale).format(date.toLocal());
