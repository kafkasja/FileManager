import 'package:drift/drift.dart';
import 'package:kfm/core/files/file_ref.dart';

/// Cached scan of the device's files (TASK-F5). One row per FileRef.
/// Times are epoch milliseconds (UTC) so sorting and keyset paging use plain
/// integer indexes.
@DataClassName('MediaIndexRow')
@TableIndex(name: 'mi_kind_date', columns: {#kind, #sortDateMs})
@TableIndex(name: 'mi_kind_size', columns: {#kind, #sizeBytes})
@TableIndex(name: 'mi_folder_date', columns: {#folderPath, #sortDateMs})
@TableIndex(name: 'mi_date', columns: {#sortDateMs})
@TableIndex(name: 'mi_name', columns: {#nameLower})
class MediaIndex extends Table {
  /// FileRef.id.
  TextColumn get id => text()();
  TextColumn get uri => text()();
  TextColumn get name => text()();

  /// For case-insensitive search and name sort (B8).
  TextColumn get nameLower => text()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get kind => intEnum<FileKind>()();
  IntColumn get sizeBytes => integer()();
  IntColumn get modifiedAtMs => integer()();

  /// Null when unknown, never 0.
  IntColumn get takenAtMs => integer().nullable()();

  /// takenAt ?? modifiedAt, denormalized for indexed sorting.
  IntColumn get sortDateMs => integer()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get folderPath => text()();
  IntColumn get origin => intEnum<FileOrigin>()();
  IntColumn get indexedAtMs => integer()();

  /// Scan generation that last saw this row. After a full scan, rows of the
  /// scanned kinds with an older generation are gone from the device.
  IntColumn get scanGeneration => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
