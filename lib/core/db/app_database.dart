import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:kfm/core/db/tables/media_index_table.dart';
import 'package:kfm/core/db/tables/pending_deletes_table.dart';
import 'package:kfm/core/db/tables/pending_folder_items_table.dart';
import 'package:kfm/core/db/tables/presets_table.dart';
import 'package:kfm/core/db/tables/rename_batches_table.dart';
import 'package:kfm/core/db/tables/reviewed_labels_table.dart';
import 'package:kfm/core/db/tables/session_actions_table.dart';
import 'package:kfm/core/db/tables/sessions_table.dart';
import 'package:kfm/core/db/tables/settings_table.dart';
import 'package:kfm/core/db/tables/tags_table.dart';
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
    Tags,
    FileTags,
    Favorites,
    RenameBatches,
    RenameBatchItems,
    Presets,
    ReviewedLabels,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Pass an [executor] in tests (e.g. `NativeDatabase.memory()`).
  new([QueryExecutor? executor]) : super(executor ?? _open());

  /// The H2 background worker: same file, its own connection (never the
  /// app's shared isolate, which may not exist or may outlive the worker).
  factory forWorker() => AppDatabase(
    driftDatabase(
      name: 'kfm',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
        setup: setupConnection,
      ),
    ),
  );

  /// Bump by exactly 1 per task that changes the schema, and add a step below.
  @override
  int get schemaVersion => 12;

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
      if (from < 7) {
        // TASK-P2
        await m.createTable(tags);
        await m.createTable(fileTags);
        await m.createTable(favorites);
        await m.createIndex(ftTag);
      }
      if (from < 8) {
        // TASK-P3
        await m.createTable(renameBatches);
        await m.createIndex(oneCollectingBatch);
        await m.createTable(renameBatchItems);
      }
      if (from < 9) {
        // TASK-P5
        if (from >= 2) {
          // media_index exists in its v2 shape. (From v1 the `from < 2`
          // block created it from the current class, column included.)
          await m.addColumn(mediaIndex, mediaIndex.screenshot);
          await customStatement(screenshotBackfillSql);
        }
        await m.createIndex(miScreenshotDate);
      }
      if (from < 10) {
        // TASK-P6
        await m.createTable(presets);
        await m.createIndex(presetsNameNocase);
        // From < 3 the v3 block created `sessions` with ended_at already.
        if (from >= 3) await m.addColumn(sessions, sessions.endedAt);
        // Before P6 every inactive session was ended (no pausing yet).
        await customStatement(
          'UPDATE sessions SET ended_at = updated_at WHERE is_active = 0',
        );
        await m.createIndex(oneOpenSessionPerPreset);
      }
      if (from < 11) {
        // TASK-P7
        await m.createTable(reviewedLabels);
        await m.createIndex(rlFilePreset);
        await m.createIndex(rlPreset);
      }
      if (from < 12) {
        // TASK-P8
        // From < 5 the v5 block created pending_deletes with these already.
        if (from >= 5) {
          await m.addColumn(pendingDeletes, pendingDeletes.trashId);
          await m.addColumn(pendingDeletes, pendingDeletes.leftTrashAt);
          await m.addColumn(pendingDeletes, pendingDeletes.leftTrashReason);
        }
        // Rows committed before P8: the trashId from the action's item.
        await customStatement(
          'UPDATE pending_deletes SET trash_id = (SELECT '
          r"json_extract(sa.previous_state, '$.trashedItem.trashId') "
          'FROM session_actions sa WHERE sa.id = pending_deletes.action_id) '
          "WHERE status = 'committed' AND committed_mode = 'trash'",
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA synchronous = NORMAL');
    },
  );

  /// P5 backfill; mirrors `isScreenshot` (kind 0 = FileKind.image).
  @visibleForTesting
  static const screenshotBackfillSql =
      'UPDATE media_index SET screenshot = 1 WHERE kind = 0 AND ( '
      "name_lower LIKE 'screenshot%' OR "
      "'/' || lower(folder_path) || '/' LIKE '%/screenshots/%' OR "
      "'/' || lower(folder_path) || '/' LIKE '%/screenshot/%' OR "
      "'/' || lower(folder_path) || '/' LIKE '%/screen captures/%')";

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
    db
      ..execute('PRAGMA journal_mode = WAL')
      // App and background worker may write at the same moment (H2).
      ..execute('PRAGMA busy_timeout = 5000');
  }
}
