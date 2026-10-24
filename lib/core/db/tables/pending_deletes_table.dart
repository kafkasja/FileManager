import 'package:drift/drift.dart';
import 'package:kfm/core/db/tables/session_actions_table.dart';
import 'package:kfm/core/db/tables/sessions_table.dart';

enum PendingDeleteStatus { queued, committing, committed, failed }

/// P8: how a trashed file left the trash.
enum TrashExit { restored, purged }

/// Deferred deletes (TASK-D2): a trash swipe only queues a row here; files
/// are deleted in batches outside the undo safe zone.
@DataClassName('PendingDeleteRow')
@TableIndex(name: 'pd_session_status', columns: {#sessionId, #status})
class PendingDeletes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get actionId => integer().unique().references(
    SessionActions,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileId => text()();

  /// 'trash' | 'permanent' (the session's DeleteMode).
  TextColumn get mode => text()();
  TextColumn get status => textEnum<PendingDeleteStatus>()();
  TextColumn get failureReason => text().nullable()();

  /// FileRef.sizeBytes at queue time (P8 stats).
  IntColumn get sizeBytes => integer()();

  /// FileRef.modifiedAt (epoch ms) at queue time: a changed file is never
  /// deleted by mistake.
  IntColumn get fileModifiedAtMs => integer()();

  /// The mode actually used when committed (P8).
  TextColumn get committedMode => text().nullable()();
  DateTimeColumn get queuedAt => dateTime()();
  DateTimeColumn get committedAt => dateTime().nullable()();

  /// P8. TrashedItem.trashId when committed to the trash; null otherwise.
  TextColumn get trashId => text().nullable()();

  /// P8. When the trashed file left the trash (restored or purged).
  DateTimeColumn get leftTrashAt => dateTime().nullable()();
  TextColumn get leftTrashReason => textEnum<TrashExit>().nullable()();
}
