import 'package:drift/drift.dart';

/// One row per recorded swipe action (TASK-P7). Undoing the action deletes
/// its row, so an earlier label for the same file applies again by itself.
@DataClassName('ReviewedLabelRow')
@TableIndex(name: 'rl_file_preset', columns: {#fileId, #presetKey})
@TableIndex(name: 'rl_preset', columns: {#presetKey})
class ReviewedLabels extends Table {
  /// session_actions.id of the action that wrote it. No FK: labels outlive
  /// any future pruning of the undo log.
  IntColumn get actionId => integer()();

  /// FileRef.id after the action (re-keyed on idChanges).
  TextColumn get fileId => text()();

  /// Preset id, 0 = Basic.
  IntColumn get presetKey => integer()();

  /// SwipeActionType.name.
  TextColumn get actionType => text()();

  /// Folder name (move/copy) or tag name (addTag); else null.
  TextColumn get actionDetail => text().nullable()();
  DateTimeColumn get reviewedAt => dateTime()();

  /// FileRef.modifiedAt (epoch ms) when swiped. A different modified time
  /// (whole seconds) = edited = not reviewed any more.
  IntColumn get fileModifiedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {actionId};
}
