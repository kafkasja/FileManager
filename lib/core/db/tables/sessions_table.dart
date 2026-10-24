import 'package:drift/drift.dart';

/// One row per swipe session (TASK-SE1). At most one is active.
@DataClassName('SessionRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX one_active_session ON sessions (is_active) '
  'WHERE is_active = 1',
)
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// FK to presets is added by P6's migration.
  IntColumn get presetId => integer().nullable()();

  /// SwipeLayout JSON.
  TextColumn get layout => text()();

  /// Filter JSON (P5); null = all media.
  TextColumn get filter => text().nullable()();

  /// 'trash' | 'permanent', copied from the setting when the session starts
  /// (D1), so changing the setting never affects queued deletes.
  TextColumn get deleteMode => text().withDefault(const Constant('trash'))();

  /// Number of files swiped so far (progress).
  IntColumn get cursor => integer().withDefault(const Constant(0))();

  /// Last swiped file; the deck resumes after it even if new photos shifted
  /// positions (SE2).
  TextColumn get cursorFileId => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isActive => boolean()();
}
