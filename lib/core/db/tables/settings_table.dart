import 'package:drift/drift.dart';

/// All user settings as typed key/value rows. Owned by TASK-F2.
/// Values are JSON-encoded; see `SettingKey`.
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
