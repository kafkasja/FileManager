import 'package:drift/drift.dart';

/// Stored by name: APPEND ONLY.
enum SignalStatus { ok, failed, unsupported }

/// Per-image signals (TASK-C2). No FK to media_index: applyIdChange
/// deletes + re-inserts rows, a cascade would wipe signals. Orphans are
/// removed by the job; ids are re-keyed by FileIdRekeyer.
@DataClassName('ImageSignalRow')
@TableIndex(name: 'is_blur', columns: {#blurScore})
class ImageSignals extends Table {
  TextColumn get fileId => text()();
  TextColumn get status => textEnum<SignalStatus>()();
  IntColumn get dHash => integer().nullable()();
  RealColumn get blurScore => real().nullable()();

  /// = media_index.modified_at_ms when computed (ms, not drift DateTime,
  /// which stores seconds and would make every row look stale).
  IntColumn get fileModifiedAtMs => integer()();
  IntColumn get algoVersion => integer()();

  @override
  Set<Column<Object>> get primaryKey => {fileId};

  @override
  List<String> get customConstraints => [
    "CHECK ((status = 'ok') = (d_hash IS NOT NULL AND blur_score IS NOT NULL))",
  ];
}
