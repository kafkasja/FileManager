import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/setting_key.dart';

/// Typed access to the `settings` table. Writes go through [DbWriteQueue].
class SettingsRepository {
  new(this._db, this._queue);

  final AppDatabase _db;
  final DbWriteQueue _queue;

  Future<T> read<T extends Object>(SettingKey<T> key) async {
    final row = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(key.name))).getSingleOrNull();
    return row == null ? key.defaultValue : key.decodeFromDb(row.value);
  }

  Stream<T> watch<T extends Object>(SettingKey<T> key) =>
      (_db.select(_db.settings)..where((s) => s.key.equals(key.name)))
          .watchSingleOrNull()
          .map(
            (row) =>
                row == null ? key.defaultValue : key.decodeFromDb(row.value),
          )
          .distinct();

  /// Completes when committed. UI callers usually don't await and use
  /// `.fireAndForget()`: failures are published on [DbWriteQueue.errors].
  Future<void> write<T extends Object>(SettingKey<T> key, T value) =>
      _queue.enqueue(
        'setting:${key.name}',
        () => _db
            .into(_db.settings)
            .insertOnConflictUpdate(
              SettingRow(key: key.name, value: key.encodeToDb(value)),
            ),
      );

  /// Removes the stored value so [read] returns the default again.
  Future<void> reset<T extends Object>(SettingKey<T> key) => _queue.enqueue(
    'setting:${key.name}',
    () => (_db.delete(_db.settings)..where((s) => s.key.equals(key.name))).go(),
  );
}
