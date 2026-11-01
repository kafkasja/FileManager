import 'package:drift/drift.dart';
import 'package:kfm/core/db/tables/swipe_sources_table.dart';

/// Ordered file ids of a list/group source (TASK-SS1). Deleted when the
/// source closes. Re-keyed on F3 idChanges (P2's FileIdRekeyer).
@DataClassName('SwipeSourceItemRow')
@TableIndex(name: 'ssi_file', columns: {#fileId})
class SwipeSourceItems extends Table {
  IntColumn get sourceId =>
      integer().references(SwipeSources, #id, onDelete: KeyAction.cascade)();

  /// 0..n-1 in the caller's order.
  IntColumn get position => integer()();
  TextColumn get fileId => text()();

  /// 0-based group (kind = groups); null otherwise.
  IntColumn get groupIndex => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {sourceId, position};
}
