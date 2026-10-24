import 'package:drift/drift.dart';

/// One row per swipe session (TASK-SE1). At most one is active; at most one
/// open (not ended) per preset (P6).
@DataClassName('SessionRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX one_active_session ON sessions (is_active) '
  'WHERE is_active = 1',
)
@TableIndex.sql(
  'CREATE UNIQUE INDEX one_open_session_per_preset ON sessions '
  '(COALESCE(preset_id, 0)) WHERE ended_at IS NULL',
)
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Preset id (P6); null = Basic. No FK: a deleted preset's ended sessions
  /// keep their id for P8 stats.
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

  /// Set when the session ends (Done / SE3 / preset deleted). Null with
  /// isActive false = paused by a preset switch (P6).
  DateTimeColumn get endedAt => dateTime().nullable()();
}
