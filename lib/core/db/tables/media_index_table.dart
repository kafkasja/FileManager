import 'package:drift/drift.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/source_rule.dart';

/// Cached scan of the device's files (TASK-F5). One row per FileRef.
/// Times are epoch milliseconds (UTC) so sorting and keyset paging use plain
/// integer indexes.
@DataClassName('MediaIndexRow')
@TableIndex(name: 'mi_kind_date', columns: {#kind, #sortDateMs})
@TableIndex(name: 'mi_kind_size', columns: {#kind, #sizeBytes})
@TableIndex(name: 'mi_folder_date', columns: {#folderPath, #sortDateMs})
@TableIndex(name: 'mi_date', columns: {#sortDateMs})
@TableIndex(name: 'mi_name', columns: {#nameLower})
@TableIndex(name: 'mi_screenshot_date', columns: {#screenshot, #sortDateMs})
@TableIndex(name: 'mi_source_date', columns: {#source, #sortDateMs})
@TableIndex(name: 'mi_ext', columns: {#extension})
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

  /// P5: see `isScreenshot` (set by the DAO on every write).
  BoolColumn get screenshot => boolean().withDefault(const Constant(false))();

  /// B1: where the file comes from (`sourceFor`, set by the DAO on every
  /// write). intEnum stores the index: only ever APPEND values.
  IntColumn get source =>
      intEnum<SourceBucket>().withDefault(const Constant(0))();

  /// B1: dot-file, inside a dot-folder or inside a `.nomedia` folder.
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  /// B1: lower-case extension without the dot ('' = none), `extensionOf`.
  TextColumn get extension => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
