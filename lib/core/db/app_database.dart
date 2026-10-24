import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:kfm/core/db/tables/media_index_table.dart';
import 'package:kfm/core/db/tables/pending_deletes_table.dart';
import 'package:kfm/core/db/tables/pending_folder_items_table.dart';
import 'package:kfm/core/db/tables/session_actions_table.dart';
import 'package:kfm/core/db/tables/sessions_table.dart';
import 'package:kfm/core/db/tables/settings_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart' show CommonDatabase;

part 'app_database.g.dart';

/// The one on-device database. Tables are owned by the tasks listed in
/// `tasks/_CONVENTIONS.md` → Database tables; see CLAUDE.md → Adding a table.
@DriftDatabase(
  tables: [
    Settings,
    MediaIndex,
    Sessions,
    SessionActions,
    PendingDeletes,
    PendingFolderItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Pass an [executor] in tests (e.g. `NativeDatabase.memory()`).
  new([QueryExecutor? executor]) : super(executor ?? _open());

  /// Bump by exactly 1 per task that changes the schema, and add a step below.
  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // One block per schema-changing task. Never edit a shipped block.
      if (from < 2) {
        // TASK-F5
        await m.createTable(mediaIndex);
        for (final index in [
          miKindDate,
          miKindSize,
          miFolderDate,
          miDate,
          miName,
        ]) {
          await m.createIndex(index);
        }
      }
      if (from < 3) {
        // TASK-SE1
        await m.createTable(sessions);
        await m.createIndex(oneActiveSession);
      }
      if (from < 4) {
        // TASK-S2
        await m.createTable(sessionActions);
        await m.createIndex(saSessionStatusSeq);
      }
      if (from < 5) {
        // TASK-D2
        await m.createTable(pendingDeletes);
        await m.createIndex(pdSessionStatus);
      }
      if (from < 6) {
        // TASK-D4
        await m.createTable(pendingFolderItems);
        await m.createIndex(pfiExpires);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA synchronous = NORMAL');
    },
  );

  /// Current SQLite journal mode (`wal` on device, `memory` for in-memory DBs).
  Future<String> journalMode() async {
    final row = await customSelect('PRAGMA journal_mode').getSingle();
    return row.read<String>('journal_mode');
  }

  static QueryExecutor _open() => driftDatabase(
    name: 'kfm',
    native: const DriftNativeOptions(
      // F5's indexer isolate uses the same database.
      shareAcrossIsolates: true,
      databaseDirectory: getApplicationSupportDirectory,
      setup: setupConnection,
    ),
  );

  /// Runs on the raw connection before drift uses it. journal_mode can't be
  /// changed inside a transaction, so it is set here rather than in beforeOpen.
  @visibleForTesting
  static void setupConnection(CommonDatabase db) {
    db.execute('PRAGMA journal_mode = WAL');
  }
}
