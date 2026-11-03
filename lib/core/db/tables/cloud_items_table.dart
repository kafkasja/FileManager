import 'package:drift/drift.dart';
import 'package:kfm/core/db/tables/cloud_destinations_table.dart';
import 'package:kfm/core/db/tables/transfers_table.dart' show SourceOutcome;

/// queued → uploading → handedToProvider (copy) | verified (safe move)
///                    → failed
/// "On cloud" (X4) = handedToProvider or verified.
enum CloudItemStatus { queued, uploading, handedToProvider, verified, failed }

enum CloudItemMode { copy, move }

/// One row per (file, destination): the latest hand-off of that file to
/// that destination (TASK-X3). It is the job state and the badge history.
@DataClassName('CloudItemRow')
@TableIndex(name: 'ci_status', columns: {#status})
@TableIndex.sql(
  'CREATE INDEX ci_on_cloud_file ON cloud_items (file_id) '
  "WHERE status IN ('handedToProvider', 'verified')",
)
class CloudItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// FileRef.id at hand-off time (re-keyed by X4 on idChanges).
  TextColumn get fileId => text()();

  /// Display name of the file at hand-off time (the Transfers list).
  TextColumn get name => text()();

  /// No cascade: destinations are soft-deleted (Hard rule 4).
  IntColumn get destinationId => integer().references(CloudDestinations, #id)();
  TextColumn get mode => textEnum<CloudItemMode>()();
  TextColumn get status => textEnum<CloudItemStatus>()();

  /// Document URI / synced-folder path; set right after createDocument so
  /// a restart can delete a partial document. Null while queued.
  TextColumn get remoteUri => text().nullable()();

  /// Local file's size and modified time (epoch **ms**, same unit as
  /// media_index.modifiedAtMs) at hand-off time. X4 compares both.
  IntColumn get sizeBytes => integer()();
  IntColumn get sourceModifiedAtMs => integer()();

  /// SHA-256 of the bytes written (source side); verified moves also match
  /// the read-back hash.
  TextColumn get sha256 => text().nullable()();

  /// Epoch ms when the status became handedToProvider/verified.
  IntColumn get uploadedAtMs => integer().nullable()();
  TextColumn get error => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Moves: what happened to the original (N11 outcome); null = not yet.
  TextColumn get sourceOutcome => textEnum<SourceOutcome>().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {fileId, destinationId},
  ];
}
