import 'package:drift/drift.dart';

/// Generated near-duplicate groups (TASK-C2); replaced on every regroup.
/// Never holds user decisions (those are in similar_dismissed).
@DataClassName('SimilarGroupRow')
class SimilarGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get suggestedFileId => text()();
  IntColumn get memberCount => integer()();

  /// Newest member's sort_date_ms (list order: newest groups first).
  IntColumn get sortDateMs => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('SimilarGroupItemRow')
@TableIndex(name: 'sgi_file', columns: {#fileId})
class SimilarGroupItems extends Table {
  IntColumn get groupId =>
      integer().references(SimilarGroups, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileId => text()();

  /// 0 = suggested best, then by compareBest order.
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {groupId, fileId};
}

/// Files whose group the user finished (Keep best, Clean duplicates, fully
/// swiped). Keyed by file, so regrouping keeps the decision: a group is
/// hidden when every shown member is here; a new member shows it again.
@DataClassName('SimilarDismissedRow')
class SimilarDismissed extends Table {
  TextColumn get fileId => text()();
  DateTimeColumn get dismissedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {fileId};
}
