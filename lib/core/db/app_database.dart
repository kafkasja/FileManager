import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:kfm/core/db/tables/ai_labels_table.dart';
import 'package:kfm/core/db/tables/cloud_destinations_table.dart';
import 'package:kfm/core/db/tables/cloud_items_table.dart';
import 'package:kfm/core/db/tables/image_signals_table.dart';
import 'package:kfm/core/db/tables/known_devices_table.dart';
import 'package:kfm/core/db/tables/local_jobs_table.dart';
import 'package:kfm/core/db/tables/media_index_table.dart';
import 'package:kfm/core/db/tables/media_locations_table.dart';
import 'package:kfm/core/db/tables/pending_deletes_table.dart';
import 'package:kfm/core/db/tables/pending_folder_items_table.dart';
import 'package:kfm/core/db/tables/presets_table.dart';
import 'package:kfm/core/db/tables/rename_batches_table.dart';
import 'package:kfm/core/db/tables/reviewed_labels_table.dart';
import 'package:kfm/core/db/tables/selection_items_table.dart';
import 'package:kfm/core/db/tables/session_actions_table.dart';
import 'package:kfm/core/db/tables/sessions_table.dart';
import 'package:kfm/core/db/tables/settings_table.dart';
import 'package:kfm/core/db/tables/share_offers_table.dart';
import 'package:kfm/core/db/tables/similar_groups_table.dart';
import 'package:kfm/core/db/tables/smart_groups_table.dart';
import 'package:kfm/core/db/tables/swipe_source_items_table.dart';
import 'package:kfm/core/db/tables/swipe_sources_table.dart';
import 'package:kfm/core/db/tables/tags_table.dart';
import 'package:kfm/core/db/tables/transfers_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/source_backfill.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart' show CommonDatabase;

part 'app_database.g.dart';

/// The one on-device database. A new table gets its own file under
/// `tables/`, a `schemaVersion` bump and an `onUpgrade` step.
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
    SelectionItems,
    SelectionSnapshots,
    SwipeSources,
    SwipeSourceItems,
    ImageSignals,
    SimilarGroups,
    SimilarGroupItems,
    SimilarDismissed,
    MediaLocations,
    SmartGroups,
    SmartGroupItems,
    AiLabels,
    AiLabelStatus,
    KnownDevices,
    Transfers,
    TransferFiles,
    LocalJobs,
    LocalJobFiles,
    ShareOffers,
    ShareOfferFiles,
    CloudDestinations,
    CloudItems,
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
  int get schemaVersion => 24;

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
      if (from < 13) {
        // TASK-B1
        // From < 2 the v2 block created media_index with these already.
        if (from >= 2) {
          await m.addColumn(mediaIndex, mediaIndex.source);
          await m.addColumn(mediaIndex, mediaIndex.hidden);
          await m.addColumn(mediaIndex, mediaIndex.extension);
        }
        await m.createIndex(miSourceDate);
        await m.createIndex(miExt);
        // Hidden files were never indexed before: `hidden` needs no backfill.
        await backfillSourceAndExtension(this);
      }
      if (from < 14) {
        // TASK-B6
        await m.createTable(selectionItems);
        await m.createTable(selectionSnapshots);
      }
      if (from < 15) {
        // TASK-SS1
        await m.createTable(swipeSources);
        await m.createTable(swipeSourceItems);
        await m.createIndex(oneOpenSourcePerSession);
        await m.createIndex(ssSessionClosedSeq);
        await m.createIndex(ssiFile);
      }
      if (from < 16) {
        // TASK-C2
        await m.createTable(imageSignals);
        await m.createTable(similarGroups);
        await m.createTable(similarGroupItems);
        await m.createTable(similarDismissed);
        await m.createIndex(isBlur);
        await m.createIndex(sgiFile);
      }
      if (from < 17) {
        // TASK-C5
        await m.createTable(mediaLocations);
        await m.createTable(smartGroups);
        await m.createTable(smartGroupItems);
        await m.createIndex(sgKindRank);
        await m.createIndex(smgiFile);
      }
      if (from < 18) {
        // TASK-C3
        await m.createTable(aiLabels);
        await m.createTable(aiLabelStatus);
        await m.createIndex(aiLabelsLabel);
      }
      if (from < 19) {
        // TASK-N6
        await m.createTable(knownDevices);
      }
      if (from < 20) {
        // TASK-N8
        // From < 3 the v3 block created `sessions` with source_id already.
        if (from >= 3) await m.addColumn(sessions, sessions.sourceId);
        await customStatement('DROP INDEX IF EXISTS one_active_session');
        await customStatement(
          'DROP INDEX IF EXISTS one_open_session_per_preset',
        );
        await m.createIndex(oneActiveSessionPerSource);
        await m.createIndex(oneOpenSessionPerSourcePreset);
      }
      if (from < 21) {
        // TASK-N9
        await m.createTable(transfers);
        await m.createTable(transferFiles);
        await m.createIndex(transfersStatus);
        await m.createIndex(transferFilesJobStatus);
      }
      if (from < 22) {
        // TASK-U2
        await m.createTable(localJobs);
        await m.createTable(localJobFiles);
        await m.createIndex(ljfStatus);
      }
      if (from < 23) {
        // TASK-N12
        await m.createTable(shareOffers);
        await m.createTable(shareOfferFiles);
        await m.createIndex(shareOffersStatus);
        await m.createIndex(shareOfferFilesUpload);
        // From < 19 the v19 block created known_devices with it already.
        if (from >= 19) {
          await m.addColumn(knownDevices, knownDevices.autoAcceptFiles);
        }
      }
      if (from < 24) {
        // TASK-X3
        await m.createTable(cloudDestinations);
        await m.createTable(cloudItems);
        await m.createIndex(ciStatus);
        await m.createIndex(ciOnCloudFile);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // FULL: every commit (each swipe's undo row) is on disk before the
      // next one; NORMAL lost the last seconds of swipes on a sudden power
      // loss (V1 bug 4). Writes run off the UI thread, so the fsync is free
      // for the user.
      await customStatement('PRAGMA synchronous = FULL');
    },
  );

  /// The v3–v19 one-active-session index (SE1); replaced in v20 (N8). Kept
  /// for the shipped v3 block.
  late final Index oneActiveSession = Index(
    'one_active_session',
    'CREATE UNIQUE INDEX one_active_session ON sessions (is_active) '
        'WHERE is_active = 1',
  );

  /// The v10–v19 one-open-session-per-preset index (P6); replaced in v20
  /// (N8). Kept for the shipped v10 block.
  late final Index oneOpenSessionPerPreset = Index(
    'one_open_session_per_preset',
    'CREATE UNIQUE INDEX one_open_session_per_preset ON sessions '
        '(COALESCE(preset_id, 0)) WHERE ended_at IS NULL',
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
