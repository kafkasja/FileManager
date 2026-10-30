import 'package:drift/drift.dart';

/// TASK-B6. The one global selection. No FK to media_index: rows are pruned
/// when files leave the index.
@DataClassName('SelectionItemRow')
class SelectionItems extends Table {
  /// FileRef.id (re-keyed on idChanges).
  TextColumn get fileId => text()();

  /// Insertion order ("View selected", Swipe these, actions).
  IntColumn get seq => integer()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {fileId};
}

/// TASK-B6. The selection before the last Clear all (one snapshot only), so
/// Undo survives a crash between clear and undo.
@DataClassName('SelectionSnapshotRow')
class SelectionSnapshots extends Table {
  TextColumn get fileId => text()();
  IntColumn get seq => integer()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {fileId};
}
