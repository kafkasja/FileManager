import 'dart:convert';
import 'dart:developer' as developer;

import 'package:kfm/core/files/file_ref.dart';
import 'package:meta/meta.dart';

enum TagFilterMode { any, tagged, untagged, hasTags }

enum ReviewedFilterMode { any, reviewed, notReviewed }

/// Which dates a filter keeps (local calendar days).
@immutable
sealed class DateFilter {
  const new();
}

final class DateAny extends DateFilter {
  const new();

  @override
  bool operator ==(Object other) => other is DateAny;

  @override
  int get hashCode => 0;
}

/// Evaluated when the query is built, never stored as fixed dates.
final class DateThisMonth extends DateFilter {
  const new();

  @override
  bool operator ==(Object other) => other is DateThisMonth;

  @override
  int get hashCode => 1;
}

/// Today and the [days] − 1 days before it (1..3650).
final class DateLastDays extends DateFilter {
  const new(this.days);

  final int days;

  @override
  bool operator ==(Object other) => other is DateLastDays && other.days == days;

  @override
  int get hashCode => Object.hash(2, days);
}

/// [from]..[to], inclusive local days.
final class DateRange extends DateFilter {
  const new(this.from, this.to);

  final DateTime from;
  final DateTime to;

  @override
  bool operator ==(Object other) =>
      other is DateRange &&
      _sameDay(other.from, from) &&
      _sameDay(other.to, to);

  @override
  int get hashCode => Object.hash(
    3,
    from.year,
    from.month,
    from.day,
    to.year,
    to.month,
    to.day,
  );
}

/// What the swipe queue (and later presets, storage overview, browse) is
/// narrowed to (TASK-P5). Pure Dart; stored as JSON in `sessions.filter`.
@immutable
class FileFilter {
  const new({
    this.kinds = const {},
    this.screenshotsOnly = false,
    this.date = const DateAny(),
    this.minSizeBytes,
    this.maxSizeBytes,
    this.folderPaths = const {},
    this.tagMode = TagFilterMode.any,
    this.tagIds = const {},
    this.favoritesOnly = false,
    this.reviewed = ReviewedFilterMode.any,
  });

  /// Throws [FormatException] on bad types or a newer version. Unknown keys
  /// are ignored.
  factory fromJson(Map<String, Object?> j) {
    final v = j['v'];
    if (v is! int || v > 1) throw FormatException('Bad filter version: $v');
    T? opt<T>(String key) => switch (j[key]) {
      null => null,
      final T value => value,
      final other => throw FormatException('Bad $key: $other'),
    };
    final kinds = opt<List<Object?>>('kinds') ?? const [];
    final folders = opt<List<Object?>>('folders') ?? const [];
    final tags = opt<List<Object?>>('tagIds') ?? const [];
    return FileFilter(
      kinds: {
        for (final k in kinds)
          FileKind.values.asNameMap()[k] ??
              (throw FormatException('Bad kind: $k')),
      },
      screenshotsOnly: opt<bool>('screenshots') ?? false,
      date: _dateFromJson(opt<Map<String, Object?>>('date')),
      minSizeBytes: opt<int>('minSize'),
      maxSizeBytes: opt<int>('maxSize'),
      folderPaths: {for (final f in folders) _of<String>(f, 'folder')},
      tagMode: _enum(TagFilterMode.values, opt<String>('tagMode')),
      tagIds: {for (final t in tags) _of<int>(t, 'tag id')},
      favoritesOnly: opt<bool>('favorites') ?? false,
      reviewed: _enum(ReviewedFilterMode.values, opt<String>('reviewed')),
    );
  }

  /// Empty = every kind the caller allows.
  final Set<FileKind> kinds;
  final bool screenshotsOnly;
  final DateFilter date;
  final int? minSizeBytes;
  final int? maxSizeBytes;

  /// Empty = all folders; exact folders (no subfolders).
  final Set<String> folderPaths;
  final TagFilterMode tagMode;

  /// Only for [TagFilterMode.hasTags]: any of these.
  final Set<int> tagIds;
  final bool favoritesOnly;

  /// P7 adds the query part; hidden in the sheet until then.
  final ReviewedFilterMode reviewed;

  static const none = FileFilter();

  bool get isEmpty => this == none;

  /// Why it can't be applied, or null.
  FilterProblem? get problem {
    final min = minSizeBytes;
    final max = maxSizeBytes;
    if (min != null && max != null && min > max) {
      return FilterProblem.sizeRange;
    }
    if ((min ?? 0) < 0 || (max ?? 0) < 0) return FilterProblem.sizeRange;
    if (tagMode == TagFilterMode.hasTags && tagIds.isEmpty) {
      return FilterProblem.noTagsChosen;
    }
    return switch (date) {
      DateRange(:final from, :final to) when _day(from).isAfter(_day(to)) =>
        FilterProblem.dateRange,
      DateLastDays(:final days) when days < 1 || days > 3650 =>
        FilterProblem.dateRange,
      _ => null,
    };
  }

  bool get isValid => problem == null;

  /// Null/'' = [none]; corrupt data is logged and gives [none].
  static FileFilter decode(String? raw) {
    if (raw == null || raw.isEmpty) return none;
    try {
      return switch (jsonDecode(raw)) {
        final Map<String, Object?> j => FileFilter.fromJson(j),
        final other => throw FormatException('Not a filter: $other'),
      };
    } on FormatException catch (e, st) {
      developer.log(
        'corrupt filter, using none',
        name: 'kfm.filters',
        error: e,
        stackTrace: st,
      );
      return none;
    }
  }

  /// Only non-default fields.
  Map<String, Object?> toJson() => {
    'v': 1,
    if (kinds.isNotEmpty) 'kinds': [for (final k in kinds) k.name]..sort(),
    if (screenshotsOnly) 'screenshots': true,
    if (date is! DateAny) 'date': _dateToJson(date),
    'minSize': ?minSizeBytes,
    'maxSize': ?maxSizeBytes,
    if (folderPaths.isNotEmpty) 'folders': folderPaths.toList()..sort(),
    if (tagMode != TagFilterMode.any) 'tagMode': tagMode.name,
    if (tagIds.isNotEmpty) 'tagIds': tagIds.toList()..sort(),
    if (favoritesOnly) 'favorites': true,
    if (reviewed != ReviewedFilterMode.any) 'reviewed': reviewed.name,
  };

  /// Sizes are set with [clearMinSize]/[clearMaxSize] to go back to "any".
  FileFilter copyWith({
    Set<FileKind>? kinds,
    bool? screenshotsOnly,
    DateFilter? date,
    int? minSizeBytes,
    int? maxSizeBytes,
    bool clearMinSize = false,
    bool clearMaxSize = false,
    Set<String>? folderPaths,
    TagFilterMode? tagMode,
    Set<int>? tagIds,
    bool? favoritesOnly,
    ReviewedFilterMode? reviewed,
  }) => FileFilter(
    kinds: kinds ?? this.kinds,
    screenshotsOnly: screenshotsOnly ?? this.screenshotsOnly,
    date: date ?? this.date,
    minSizeBytes: clearMinSize ? null : minSizeBytes ?? this.minSizeBytes,
    maxSizeBytes: clearMaxSize ? null : maxSizeBytes ?? this.maxSizeBytes,
    folderPaths: folderPaths ?? this.folderPaths,
    tagMode: tagMode ?? this.tagMode,
    tagIds: tagIds ?? this.tagIds,
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    reviewed: reviewed ?? this.reviewed,
  );

  @override
  bool operator ==(Object other) =>
      other is FileFilter &&
      _setEquals(other.kinds, kinds) &&
      other.screenshotsOnly == screenshotsOnly &&
      other.date == date &&
      other.minSizeBytes == minSizeBytes &&
      other.maxSizeBytes == maxSizeBytes &&
      _setEquals(other.folderPaths, folderPaths) &&
      other.tagMode == tagMode &&
      _setEquals(other.tagIds, tagIds) &&
      other.favoritesOnly == favoritesOnly &&
      other.reviewed == reviewed;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(kinds),
    screenshotsOnly,
    date,
    minSizeBytes,
    maxSizeBytes,
    Object.hashAllUnordered(folderPaths),
    tagMode,
    Object.hashAllUnordered(tagIds),
    favoritesOnly,
    reviewed,
  );

  static T _of<T>(Object? value, String what) =>
      value is T ? value : throw FormatException('Bad $what: $value');

  static T _enum<T extends Enum>(List<T> values, String? name) {
    if (name == null) return values.first;
    return values.asNameMap()[name] ??
        (throw FormatException('Bad value: $name'));
  }

  static Map<String, Object?> _dateToJson(DateFilter d) => switch (d) {
    DateAny() => {'t': 'any'},
    DateThisMonth() => {'t': 'month'},
    DateLastDays(:final days) => {'t': 'days', 'days': days},
    DateRange(:final from, :final to) => {
      't': 'range',
      'from': _ymd(from),
      'to': _ymd(to),
    },
  };

  static DateFilter _dateFromJson(Map<String, Object?>? j) =>
      switch ((j?['t'], j?['days'], j?['from'], j?['to'])) {
        (null || 'any', _, _, _) => const DateAny(),
        ('month', _, _, _) => const DateThisMonth(),
        ('days', final int days, _, _) => DateLastDays(days),
        ('range', _, final String from, final String to) => DateRange(
          _parseYmd(from),
          _parseYmd(to),
        ),
        _ => throw FormatException('Bad date filter: $j'),
      };

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime _parseYmd(String s) {
    final parts = s.split('-');
    final nums = parts.map(int.tryParse).toList();
    if (parts.length != 3 || nums.contains(null)) {
      throw FormatException('Bad date: $s');
    }
    return DateTime(nums[0]!, nums[1]!, nums[2]!);
  }
}

/// Why a filter can't be applied (shown next to the disabled Apply).
enum FilterProblem { sizeRange, noTagsChosen, dateRange }

bool _setEquals<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
