import 'package:drift/drift.dart';

/// User tags (TASK-P2). Names are unique; the repository also rejects
/// case-insensitive duplicates.
@DataClassName('TagRow')
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();

  /// ARGB, one of `kTagColors`.
  IntColumn get color => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {name},
  ];
}

/// Which file has which tag (TASK-P2). Keyed by FileRef.id; re-keyed on
/// `FileSource.idChanges`.
@DataClassName('FileTagRow')
@TableIndex(name: 'ft_tag', columns: {#tagId})
class FileTags extends Table {
  TextColumn get fileId => text()();
  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {fileId, tagId};
}

/// Favorite files (TASK-P2), keyed by FileRef.id.
@DataClassName('FavoriteRow')
class Favorites extends Table {
  TextColumn get fileId => text()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {fileId};
}
