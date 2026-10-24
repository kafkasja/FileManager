/// Local calendar boundaries for the stats screen (TASK-P8).
DateTime startOfDay(DateTime now) => DateTime(now.year, now.month, now.day);

/// [firstWeekday]: DateTime.monday (1) … DateTime.sunday (7).
DateTime startOfWeek(DateTime now, {int firstWeekday = DateTime.monday}) {
  final day = startOfDay(now);
  final back = (day.weekday - firstWeekday) % 7;
  return DateTime(day.year, day.month, day.day - back);
}

DateTime startOfMonth(DateTime now) => DateTime(now.year, now.month);

/// The later of [a] and [b] (null = no bound).
DateTime? laterOf(DateTime? a, DateTime? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a.isAfter(b) ? a : b;
}
