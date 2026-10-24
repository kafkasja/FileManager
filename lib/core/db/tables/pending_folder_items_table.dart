import 'package:drift/drift.dart';

/// Files in a volume's hidden `.KFMTrash` folder (TASK-D4): non-media files,
/// and media on Android 10 and older. Emptied after the retention days.
@DataClassName('PendingFolderItemRow')
@TableIndex(name: 'pfi_expires', columns: {#expiresAt})
class PendingFolderItems extends Table {
  /// Random id (also part of the stored file name).
  TextColumn get id => text()();

  /// Absolute path the file came from (restore target).
  TextColumn get originalPath => text()();
  TextColumn get storedPath => text().unique()();

  /// Root path of the storage volume holding the folder.
  TextColumn get volumeId => text()();
  TextColumn get name => text()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get sizeBytes => integer()();

  /// FileRef.id before the move (`ms:` for media on API ≤29).
  TextColumn get originalFileId => text()();
  DateTimeColumn get originalModifiedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
