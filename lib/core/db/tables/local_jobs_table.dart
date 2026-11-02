import 'package:drift/drift.dart';
import 'package:kfm/core/db/tables/transfers_table.dart';

/// Copy/move jobs between places on this device (TASK-U2): internal
/// storage, SD cards, USB drives, cameras. N9's `transfers` stays
/// device-to-device.
enum LocalJobMode { copy, move }

enum LocalJobStatus { queued, running, paused, done, failed, cancelled }

/// `verified` = copied and checked; a move's original is deleted at the
/// job's end (then `done`).
enum LocalFileStatus {
  queued,
  copying,
  verifying,
  verified,
  done,
  skipped,
  failed,
}

/// A name clash in the target folder, decided once per job.
enum CollisionPolicy { keepBoth, skip, replace }

@DataClassName('LocalJobRow')
class LocalJobs extends Table {
  /// `randomHexId()`.
  TextColumn get id => text()();
  TextColumn get mode => textEnum<LocalJobMode>()();

  /// U1 place id of the target (`primary`, a volume uuid).
  TextColumn get targetPlaceId => text()();

  /// Absolute folder path (SAF places too: their volume path).
  TextColumn get targetFolder => text()();
  TextColumn get status => textEnum<LocalJobStatus>()();
  TextColumn get collisionPolicy => textEnum<CollisionPolicy>().nullable()();

  /// Move jobs: the D1 delete mode for this job ('trash' | 'permanent').
  TextColumn get deleteMode => text().nullable()();

  /// Why the job stopped (paused / failed), an engine code.
  TextColumn get failureReason => text().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('LocalJobFileRow')
@TableIndex(name: 'ljf_status', columns: {#jobId, #status})
class LocalJobFiles extends Table {
  TextColumn get jobId =>
      text().references(LocalJobs, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get sourceId => text()();
  TextColumn get sourcePlaceId => text()();
  TextColumn get originalName => text()();

  /// After FAT name sanitising (the job log shows renamed files).
  TextColumn get targetName => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get status => textEnum<LocalFileStatus>()();

  /// The verified copy's `FileRef.id`.
  TextColumn get targetId => text().nullable()();
  TextColumn get sha256 => text().nullable()();

  /// N11: what happened to the original of a move.
  TextColumn get sourceOutcome => textEnum<SourceOutcome>().nullable()();

  /// The source's modified time when the copy started.
  IntColumn get sourceModifiedAtMs => integer()();

  /// An engine code or a `FileOpFailure` name.
  TextColumn get failureReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {jobId, position};
}
