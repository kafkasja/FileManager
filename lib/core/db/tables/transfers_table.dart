import 'package:drift/drift.dart';
import 'package:kfm/core/db/tables/known_devices_table.dart';
import 'package:kfm/core/db/tables/sessions_table.dart';

/// Wi-Fi transfers with another device (TASK-N9). Local copy/move jobs live
/// in U2's own tables.
enum TransferDirection { upload, download }

/// `move` is N11.
enum TransferMode { copy, move }

/// `paused` is N10.
enum TransferStatus { queued, running, paused, done, failed, cancelled }

/// N10.
enum TransferPauseReason { user, waitingForDevice, noSpace }

/// `verifying` is N11.
enum TransferFileStatus {
  queued,
  running,
  verifying,
  done,
  failed,
  cancelled,
  skipped,
}

/// N11: what happened to the original after a move.
enum SourceOutcome {
  trashed,
  deletedPermanently,
  keptDeclined,
  keptCancelled,
  keptChanged,
  keptFailed,
  alreadyGone,
}

/// One job: files to or from one device (TASK-N9; N10/N11 only read and
/// write their columns).
@DataClassName('TransferRow')
@TableIndex(name: 'transfers_status', columns: {#status})
class Transfers extends Table {
  /// `randomHexId()`.
  TextColumn get id => text()();

  /// The peer (N6 local id). Removing the device removes its jobs.
  TextColumn get deviceId =>
      text().references(KnownDevices, #id, onDelete: KeyAction.cascade)();
  TextColumn get direction => textEnum<TransferDirection>()();
  TextColumn get mode => textEnum<TransferMode>()();

  /// Upload: N4 root id on the peer. Download: null.
  TextColumn get targetRootId => text().nullable()();

  /// Upload: path relative to [targetRootId] ('' = the root). Download:
  /// absolute local folder.
  TextColumn get targetPath => text()();
  TextColumn get status => textEnum<TransferStatus>()();

  /// N10.
  TextColumn get pauseReason => textEnum<TransferPauseReason>().nullable()();

  /// N11: 'trash' | 'permanent' for upload-moves; null otherwise.
  TextColumn get deleteMode => text().nullable()();

  /// The swipe session this job collects sends for (one open job per
  /// device and session).
  IntColumn get swipeSessionId => integer().nullable().references(
    Sessions,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One file of a [Transfers] job.
@DataClassName('TransferFileRow')
@TableIndex(name: 'transfer_files_job_status', columns: {#transferId, #status})
class TransferFiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transferId =>
      text().references(Transfers, #id, onDelete: KeyAction.cascade)();

  /// Order inside the job.
  IntColumn get seq => integer()();

  /// `FileRef.id` on the sending side (the remote id for downloads).
  TextColumn get sourceFileId => text()();

  /// The target name (checked with `validateFileName` before writing).
  TextColumn get name => text()();
  IntColumn get sizeBytes => integer()();

  /// N10 "source changed" check.
  IntColumn get sourceModifiedAtMs => integer()();
  IntColumn get bytesDone => integer().withDefault(const Constant(0))();
  TextColumn get status => textEnum<TransferFileStatus>()();

  /// An `ApiErrorCode` wire code, a `FileOpFailure` name or an engine code.
  TextColumn get error => text().nullable()();

  /// The final file (local `FileRef.id` or the server's `finalId`).
  TextColumn get targetFileId => text().nullable()();

  /// Server upload handle.
  TextColumn get uploadId => text().nullable()();

  /// N10 download validator.
  TextColumn get etag => text().nullable()();

  /// N10.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// N10.
  DateTimeColumn get nextRetryAt => dateTime().nullable()();

  /// N10/N11.
  TextColumn get senderSha256 => text().nullable()();

  /// N11.
  TextColumn get receiverSha256 => text().nullable()();

  /// N11.
  TextColumn get sourceOutcome => textEnum<SourceOutcome>().nullable()();

  /// N11.
  TextColumn get sourceError => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {transferId, seq},
  ];
}
