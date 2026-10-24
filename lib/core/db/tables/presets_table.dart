import 'package:drift/drift.dart';

/// Saved swipe setups (TASK-P6). Ids start at 1; 0 means "Basic" in P7/P8.
@DataClassName('PresetRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX presets_name_nocase ON presets (name COLLATE NOCASE)',
)
class Presets extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Trimmed, 1–40 chars, unique ignoring case.
  TextColumn get name => text().withLength(min: 1, max: 40)();

  /// SwipeLayout JSON.
  TextColumn get layoutJson => text()();

  /// FileFilter JSON; null = no filter.
  TextColumn get filterJson => text().nullable()();

  /// P7: false = skip files already reviewed in this preset (default).
  BoolColumn get includeReviewed =>
      boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get createdAt => dateTime()();
}
