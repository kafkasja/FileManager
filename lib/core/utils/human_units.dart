import 'package:kfm/l10n/generated/app_localizations.dart';

/// "45 s", "2 min", "1 min 30 s", "1 h", "1 h 30 min" (TASK-E2 §4). Seconds
/// are dropped from an hour or more.
String formatShortDuration(AppLocalizations l10n, int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  if (s < 60) return l10n.durationShortSeconds(s);
  if (s < 3600) {
    final m = s ~/ 60;
    final rest = s % 60;
    return rest == 0
        ? l10n.durationShortMinutes(m)
        : l10n.durationShortMinutesSeconds(m, rest);
  }
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  return m == 0
      ? l10n.durationShortHours(h)
      : l10n.durationShortHoursMinutes(h, m);
}

/// A unit a value can be typed in: [factor] base units (bytes, seconds)
/// per one of it.
enum InputUnit {
  seconds(1),
  minutes(60),
  hours(3600),
  megabytes(1024 * 1024),
  gigabytes(1024 * 1024 * 1024);

  new(this.factor);

  final int factor;

  static const List<InputUnit> durationUnits = [seconds, minutes, hours];
  static const List<InputUnit> sizeUnits = [megabytes, gigabytes];

  String label(AppLocalizations l10n) => switch (this) {
    seconds => l10n.unitSecondsShort,
    minutes => l10n.unitMinutesShort,
    hours => l10n.unitHoursShort,
    megabytes => l10n.unitMegabytesShort,
    gigabytes => l10n.unitGigabytesShort,
  };
}

/// The largest unit of [units] that shows [value] as a whole number (≥ 1),
/// else the smallest: 7200 s → 2 h, 90 s → 90 s, 250 MB → 250 MB.
InputUnit unitFor(int value, List<InputUnit> units) {
  for (final u in units.reversed) {
    if (value >= u.factor && value % u.factor == 0) return u;
  }
  return units.first;
}

/// Parses a typed amount ("90", "1.5", "1,5") in [unit] to base units, or
/// null when it isn't a positive number. Rounds to whole base units.
int? parseAmount(String text, InputUnit unit) {
  final t = text.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(t)) return null;
  final v = double.tryParse(t);
  if (v == null || v <= 0) return null;
  return (v * unit.factor).round();
}

/// How [value] reads in [unit] in the text field: "2", "1.5".
String amountText(int value, InputUnit unit) {
  final v = value / unit.factor;
  return v == v.roundToDouble()
      ? v.round().toString()
      : v.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}
