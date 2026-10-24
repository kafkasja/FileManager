import 'package:drift/drift.dart';
import 'package:kfm/core/db/tables/sessions_table.dart';

enum RenameBatchStatus { collecting, applying, applied, reverting, discarded }

/// A rename batch (TASK-P3): files swiped into it, renamed together with a
/// name pattern. One collecting batch per session.
@DataClassName('RenameBatchRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX one_collecting_batch ON rename_batches (session_id) '
  "WHERE status = 'collecting'",
)
class RenameBatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get status => textEnum<RenameBatchStatus>()();

  /// The NamePattern JSON used by apply (null while collecting).
  TextColumn get patternJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get appliedAt => dateTime().nullable()();
}

/// One file in a rename batch (TASK-P3). `current*` columns are updated
/// after every rename, so an interrupted apply/revert can be finished.
@DataClassName('RenameBatchItemRow')
class RenameBatchItems extends Table {
  IntColumn get batchId =>
      integer().references(RenameBatches, #id, onDelete: KeyAction.cascade)();

  /// FileRef.id when the file was added (stable key).
  TextColumn get fileId => text()();

  /// Swipe order, 1..n.
  IntColumn get position => integer()();
  TextColumn get folderPath => text()();
  TextColumn get originalName => text()();
  TextColumn get currentFileId => text()();
  TextColumn get currentName => text()();

  /// Final name, set when apply starts.
  TextColumn get newName => text().nullable()();

  /// Intermediate name for the two-phase rename (name swaps).
  TextColumn get tempName => text().nullable()();
  BoolColumn get skipped => boolean().withDefault(const Constant(false))();

  /// 'missing' | 'changed' | FileOpFailure.name.
  TextColumn get skipReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {batchId, fileId};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {batchId, position},
  ];
}
