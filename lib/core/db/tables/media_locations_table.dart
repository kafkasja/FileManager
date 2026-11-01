import 'package:drift/drift.dart';

/// EXIF facts per image, read once per file version (TASK-C5). A row exists
/// even when the photo has no GPS, so it is never read twice. No FK to
/// media_index: applyIdChange is delete + insert, a cascade would wipe rows.
@DataClassName('MediaLocationRow')
class MediaLocations extends Table {
  TextColumn get fileId => text()();

  /// media_index.modifiedAtMs when read (epoch ms).
  IntColumn get fileModifiedAtMs => integer()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  BoolColumn get frontCamera => boolean().withDefault(const Constant(false))();

  /// Location access was granted (or not needed, API < 29) when read. Rows
  /// read without it are read again once access is granted.
  BoolColumn get locationReadable => boolean()();
  IntColumn get readAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {fileId};

  @override
  List<String> get customConstraints => [
    'CHECK ((lat IS NULL) = (lng IS NULL))',
    'CHECK (lat IS NULL OR lat BETWEEN -90 AND 90)',
    'CHECK (lng IS NULL OR lng BETWEEN -180 AND 180)',
  ];
}
