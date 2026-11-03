import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/tables/cloud_items_table.dart';
import 'package:kfm/core/db/tables/transfers_table.dart' show SourceOutcome;
import 'package:kfm/core/files/file_ref.dart';

export 'package:kfm/core/db/app_database.dart' show CloudItemRow;
export 'package:kfm/core/db/tables/cloud_items_table.dart';

/// `cloud_items` (TASK-X3 owns the writes; X4 adds read queries here). All
/// writes go through the [DbWriteQueue] (no coalescing: every status
/// change matters).
class CloudItemsRepository {
  new(this._db, this._queue, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DbWriteQueue _queue;
  final DateTime Function() _now;

  static const List<CloudItemStatus> _active = [
    CloudItemStatus.queued,
    CloudItemStatus.uploading,
  ];

  /// [DbWriteQueue.enqueue] with the write's result.
  Future<T> _write<T>(Future<T> Function() run) async {
    late T result;
    await _queue.enqueue(null, () async => result = await run());
    return result;
  }

  /// One `queued` row per (file, destination), replacing an earlier
  /// hand-off of the same file there (a row still queued or uploading is
  /// left alone). Returns the row ids in [files]' order.
  Future<List<int>> enqueue(
    List<FileRef> files,
    int destinationId,
    CloudItemMode mode,
  ) => _write(
    () => _db.transaction(() async {
      final ids = <int>[];
      final at = _now();
      for (final f in files) {
        final row = CloudItemsCompanion.insert(
          fileId: f.id,
          name: f.name,
          destinationId: destinationId,
          mode: mode,
          status: CloudItemStatus.queued,
          sizeBytes: f.sizeBytes,
          sourceModifiedAtMs: f.modifiedAt.millisecondsSinceEpoch,
          createdAt: at,
          attempts: const Value(0),
        );
        final old =
            await (_db.select(_db.cloudItems)..where(
                  (i) =>
                      i.fileId.equals(f.id) &
                      i.destinationId.equals(destinationId),
                ))
                .getSingleOrNull();
        if (old == null) {
          ids.add(await _db.into(_db.cloudItems).insert(row));
          continue;
        }
        ids.add(old.id);
        // Already on its way there: left as it is.
        if (_active.contains(old.status)) continue;
        await (_db.update(
          _db.cloudItems,
        )..where((i) => i.id.equals(old.id))).write(
          row.copyWith(
            remoteUri: const Value(null),
            sha256: const Value(null),
            uploadedAtMs: const Value(null),
            error: const Value(null),
            sourceOutcome: const Value(null),
          ),
        );
      }
      return ids;
    }),
  );

  Future<CloudItemRow?> byId(int id) => (_db.select(
    _db.cloudItems,
  )..where((i) => i.id.equals(id))).getSingleOrNull();

  Future<List<CloudItemRow>> byIds(Iterable<int> ids) =>
      (_db.select(_db.cloudItems)..where((i) => i.id.isIn(ids))).get();

  /// The oldest queued row of an active destination, skipping [skip].
  Future<CloudItemRow?> nextQueued({Set<int> skip = const {}}) {
    final q =
        _db.select(_db.cloudItems).join([
            innerJoin(
              _db.cloudDestinations,
              _db.cloudDestinations.id.equalsExp(_db.cloudItems.destinationId),
            ),
          ])
          ..where(
            _db.cloudItems.status.equalsValue(CloudItemStatus.queued) &
                _db.cloudDestinations.removedAt.isNull() &
                _db.cloudItems.id.isNotIn(skip),
          )
          ..orderBy([
            OrderingTerm.asc(_db.cloudItems.createdAt),
            OrderingTerm.asc(_db.cloudItems.id),
          ])
          ..limit(1);
    return q.map((r) => r.readTable(_db.cloudItems)).getSingleOrNull();
  }

  /// queued/uploading rows exist (start-up check, Hard rule 1).
  Future<bool> hasPending() async {
    final r = await _db
        .customSelect(
          'SELECT EXISTS (SELECT 1 FROM cloud_items '
          "WHERE status IN ('queued', 'uploading')) AS e",
          readsFrom: {_db.cloudItems},
        )
        .getSingle();
    return r.read<bool>('e');
  }

  /// queued → uploading with the source's size and modified time as they
  /// are now. False when the row isn't queued any more (cancelled,
  /// destination removed).
  Future<bool> startUploading(
    int id, {
    required int sizeBytes,
    required int sourceModifiedAtMs,
  }) => _write(() async {
    final n =
        await (_db.update(_db.cloudItems)..where(
              (i) =>
                  i.id.equals(id) &
                  i.status.equalsValue(CloudItemStatus.queued),
            ))
            .write(
              CloudItemsCompanion(
                status: const Value(CloudItemStatus.uploading),
                sizeBytes: Value(sizeBytes),
                sourceModifiedAtMs: Value(sourceModifiedAtMs),
              ),
            );
    return n == 1;
  });

  /// Right after createDocument, before any byte is written.
  Future<bool> markUploading(int id, String remoteUri) =>
      _setWhereUploading(id, CloudItemsCompanion(remoteUri: Value(remoteUri)));

  Future<bool> markHandedToProvider(int id, String sha256, int uploadedAtMs) =>
      _setWhereUploading(
        id,
        CloudItemsCompanion(
          status: const Value(CloudItemStatus.handedToProvider),
          sha256: Value(sha256),
          uploadedAtMs: Value(uploadedAtMs),
          error: const Value(null),
        ),
      );

  Future<bool> markVerified(int id, String sha256, int uploadedAtMs) =>
      _setWhereUploading(
        id,
        CloudItemsCompanion(
          status: const Value(CloudItemStatus.verified),
          sha256: Value(sha256),
          uploadedAtMs: Value(uploadedAtMs),
          error: const Value(null),
        ),
      );

  /// queued/uploading → failed, `attempts + 1`. [keepRemoteUri] false
  /// clears it (the document was deleted).
  Future<bool> markFailed(int id, String error, {bool keepRemoteUri = false}) =>
      _write(() async {
        final n = await _db.customUpdate(
          'UPDATE cloud_items SET status = ?, error = ?, '
          'attempts = attempts + 1'
          '${keepRemoteUri ? '' : ', remote_uri = NULL'} '
          "WHERE id = ? AND status IN ('queued', 'uploading')",
          variables: [
            Variable.withString(CloudItemStatus.failed.name),
            Variable.withString(error),
            Variable.withInt(id),
          ],
          updates: {_db.cloudItems},
          updateKind: UpdateKind.update,
        );
        return n == 1;
      });

  /// Moves: what happened to each original (N11 outcome + error text).
  Future<void> setOutcomes(
    Map<int, ({SourceOutcome outcome, String? error})> outcomes,
  ) => _write(
    () => _db.batch((b) {
      for (final MapEntry(key: id, value: o) in outcomes.entries) {
        b.update(
          _db.cloudItems,
          CloudItemsCompanion(
            sourceOutcome: Value(o.outcome),
            error: Value(o.error),
          ),
          where: (i) => i.id.equals(id),
        );
      }
    }),
  );

  /// Start-up: `uploading` rows go back to `queued` (SAF can't append, a
  /// file restarts from 0). Returns their partial documents' URIs.
  Future<List<String>> resetInterrupted() => _write(
    () => _db.transaction(() async {
      final rows = await (_db.select(
        _db.cloudItems,
      )..where((i) => i.status.equalsValue(CloudItemStatus.uploading))).get();
      if (rows.isEmpty) return const <String>[];
      await (_db.update(
        _db.cloudItems,
      )..where((i) => i.status.equalsValue(CloudItemStatus.uploading))).write(
        const CloudItemsCompanion(
          status: Value(CloudItemStatus.queued),
          remoteUri: Value(null),
        ),
      );
      return [for (final r in rows) ?r.remoteUri];
    }),
  );

  /// Rows of the last [since] for the Transfers page, newest first.
  Stream<List<CloudItemRow>> watchJobs({required DateTime since}) =>
      (_db.select(_db.cloudItems)
            ..where(
              (i) =>
                  i.createdAt.isBiggerOrEqualValue(since) |
                  i.status.isInValues(_active),
            )
            ..orderBy([
              (i) => OrderingTerm.desc(i.createdAt),
              (i) => OrderingTerm.desc(i.id),
            ]))
          .watch();

  Future<bool> _setWhereUploading(int id, CloudItemsCompanion values) =>
      _write(() async {
        final n =
            await (_db.update(_db.cloudItems)..where(
                  (i) =>
                      i.id.equals(id) &
                      i.status.equalsValue(CloudItemStatus.uploading),
                ))
                .write(values);
        return n == 1;
      });
}
