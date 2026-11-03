import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/tables/cloud_items_table.dart';
import 'package:kfm/core/db/tables/transfers_table.dart' show SourceOutcome;
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/cloud/data/cloud_destinations_repository.dart'
    show CloudItemErrors;
import 'package:kfm/features/cloud/domain/cloud_state.dart';

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

  static const List<SourceOutcome> _originalMayGo = [
    SourceOutcome.keptDeclined,
    SourceOutcome.keptFailed,
    SourceOutcome.keptCancelled,
  ];

  /// [DbWriteQueue.enqueue] with the write's result.
  Future<T> _write<T>(Future<T> Function() run) async {
    late T result;
    await _queue.enqueue(null, () async => result = await run());
    return result;
  }

  /// One `queued` row per (file, destination), replacing an earlier
  /// hand-off of the same file there. Left alone (still on its way; its
  /// own job decides): uploading rows and rows [busy] says a running job
  /// holds. Returns the row ids in [files]' order and the ids that were
  /// (re-)queued for this request.
  ///
  /// A failed or queued row keeps its `remote_uri` (a copy left by an
  /// earlier attempt): the runner deletes that document before it writes
  /// a new one, so a Retry never orphans it.
  Future<({List<int> ids, Set<int> queued})> enqueue(
    List<FileRef> files,
    int destinationId,
    CloudItemMode mode, {
    bool Function(int id)? busy,
  }) => _write(
    () => _db.transaction(() async {
      final ids = <int>[];
      final queued = <int>{};
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
          final id = await _db.into(_db.cloudItems).insert(row);
          ids.add(id);
          queued.add(id);
          continue;
        }
        ids.add(old.id);
        // Already on its way there: left as it is.
        if (old.status == CloudItemStatus.uploading ||
            (busy?.call(old.id) ?? false)) {
          continue;
        }
        final keepsDocument =
            old.status == CloudItemStatus.failed ||
            old.status == CloudItemStatus.queued;
        await (_db.update(
          _db.cloudItems,
        )..where((i) => i.id.equals(old.id))).write(
          row.copyWith(
            remoteUri: keepsDocument ? const Value.absent() : const Value(null),
            sha256: const Value(null),
            uploadedAtMs: const Value(null),
            error: const Value(null),
            sourceOutcome: const Value(null),
          ),
        );
        queued.add(old.id);
      }
      return (ids: ids, queued: queued);
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

  /// An earlier attempt's document of an uploading row was deleted.
  Future<bool> clearRemoteUri(int id) =>
      _setWhereUploading(id, const CloudItemsCompanion(remoteUri: Value(null)));

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

  /// queued/uploading → failed, `attempts + 1`. `remote_uri` is kept
  /// unless [documentRemoved] (only after its document was deleted).
  Future<bool> markFailed(
    int id,
    String error, {
    bool documentRemoved = false,
  }) => _write(() async {
    final n = await _db.customUpdate(
      'UPDATE cloud_items SET status = ?, error = ?, '
      'attempts = attempts + 1'
      '${documentRemoved ? ', remote_uri = NULL' : ''} '
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

  /// A failed row's document that couldn't be deleted: its URI is kept and
  /// its error says so (rule 8), so start-up retries the delete.
  Future<void> recordLeftover(int id, String remoteUri) => _write(
    () => _db.transaction(() async {
      final row = await byId(id);
      if (row == null || row.status != CloudItemStatus.failed) return;
      await (_db.update(_db.cloudItems)..where((i) => i.id.equals(id))).write(
        CloudItemsCompanion(
          remoteUri: Value(remoteUri),
          error: Value(CloudItemErrors.withLeftover(row.error)),
        ),
      );
    }),
  );

  /// Failed rows whose document still has to be deleted.
  Future<List<CloudItemRow>> leftovers() async {
    final rows =
        await (_db.select(_db.cloudItems)..where(
              (i) =>
                  i.status.equalsValue(CloudItemStatus.failed) &
                  i.remoteUri.isNotNull(),
            ))
            .get();
    return [
      for (final r in rows)
        if (CloudItemErrors.hasLeftover(r.error)) r,
    ];
  }

  /// [remoteUri] of a failed row was deleted: the URI goes and the error
  /// loses its leftover mark. No-op when the row changed meanwhile.
  Future<void> clearDocument(int id, String remoteUri) => _write(
    () => _db.transaction(() async {
      final row = await byId(id);
      if (row == null ||
          row.status != CloudItemStatus.failed ||
          row.remoteUri != remoteUri) {
        return;
      }
      await (_db.update(_db.cloudItems)..where((i) => i.id.equals(id))).write(
        CloudItemsCompanion(
          remoteUri: const Value(null),
          error: Value(CloudItemErrors.reasonOf(row.error)),
        ),
      );
    }),
  );

  /// The local file got a new id (F3 `idChanges`): its rows follow it
  /// ([rekeyStatements]). Idempotent, so X3's runner and P2's
  /// `FileIdRekeyer` may both call it for the same change.
  Future<void> rekey(
    String oldId,
    String newId, {
    int? newSizeBytes,
    int? newModifiedMs,
  }) {
    if (oldId == newId) return Future.value();
    return _write(
      () => _db.transaction(
        () => rekeyStatements(
          _db,
          oldId,
          newId,
          newSizeBytes: newSizeBytes,
          newModifiedMs: newModifiedMs,
        ),
      ),
    );
  }

  /// X4 re-keying, for callers already inside a write-queue transaction
  /// (P2's `FileIdRekeyer`). Where both ids have a row for the same
  /// destination the older upload goes (ties: the new id's row stays);
  /// the rest move to [newId]. A move isn't an edit: rows that matched the
  /// file's size adopt its new modified time (cross-volume moves change it),
  /// so the badge survives (accepted risk as P7: edited *and* moved with the
  /// same size shows "on cloud" again).
  static Future<void> rekeyStatements(
    AppDatabase db,
    String oldId,
    String newId, {
    int? newSizeBytes,
    int? newModifiedMs,
  }) async {
    if (oldId == newId) return;
    await db.customStatement(
      'DELETE FROM cloud_items WHERE id IN ( '
      'SELECT CASE WHEN COALESCE(o.uploaded_at_ms, 0) > '
      'COALESCE(n.uploaded_at_ms, 0) THEN n.id ELSE o.id END '
      'FROM cloud_items o JOIN cloud_items n '
      'ON n.destination_id = o.destination_id '
      'WHERE o.file_id = ? AND n.file_id = ?)',
      [oldId, newId],
    );
    await db.customStatement(
      'UPDATE cloud_items SET file_id = ? WHERE file_id = ?',
      [newId, oldId],
    );
    if (newSizeBytes != null && newModifiedMs != null) {
      await db.customStatement(
        'UPDATE cloud_items SET source_modified_at_ms = ? '
        'WHERE file_id = ? AND size_bytes = ?',
        [newModifiedMs, newId, newSizeBytes],
      );
    }
    // customStatement doesn't notify drift streams.
    db.notifyUpdates({const TableUpdate('cloud_items')});
  }

  static const List<CloudItemStatus> _uploaded = [
    CloudItemStatus.handedToProvider,
    CloudItemStatus.verified,
  ];

  static CloudUploadFact _fact(CloudItemRow r) => CloudUploadFact(
    destinationId: r.destinationId,
    sizeBytes: r.sizeBytes,
    sourceModifiedAtMs: r.sourceModifiedAtMs,
    uploadedAtMs: r.uploadedAtMs ?? 0,
  );

  /// X4: uploaded rows (handedToProvider/verified) per file id, one query
  /// per 500 ids (served by `ci_on_cloud_file`). Ids without uploads are
  /// absent.
  Future<Map<String, List<CloudUploadFact>>> uploadFactsFor(
    List<String> fileIds,
  ) async {
    final out = <String, List<CloudUploadFact>>{};
    for (var i = 0; i < fileIds.length; i += 500) {
      final chunk = fileIds.sublist(
        i,
        i + 500 > fileIds.length ? fileIds.length : i + 500,
      );
      final rows =
          await (_db.select(_db.cloudItems)..where(
                (c) => c.fileId.isIn(chunk) & c.status.isInValues(_uploaded),
              ))
              .get();
      for (final r in rows) {
        (out[r.fileId] ??= []).add(_fact(r));
      }
    }
    return out;
  }

  /// X4: one file's uploads, newest first (the viewer's info line).
  Stream<List<CloudUploadFact>> destinationsFor(String fileId) =>
      (_db.select(_db.cloudItems)
            ..where(
              (c) => c.fileId.equals(fileId) & c.status.isInValues(_uploaded),
            )
            ..orderBy([
              (c) => OrderingTerm.desc(c.uploadedAtMs),
              (c) => OrderingTerm.asc(c.id),
            ]))
          .watch()
          .map((rows) => [for (final r in rows) _fact(r)]);

  /// X4: at least one upload exists (badge, filter row and settings stay
  /// hidden otherwise). Removed destinations' rows count too.
  Stream<bool> watchHasAny() => _db
      .customSelect(
        'SELECT EXISTS (SELECT 1 FROM cloud_items '
        "WHERE status IN ('handedToProvider', 'verified')) AS e",
        readsFrom: {_db.cloudItems},
      )
      .watchSingle()
      .map((r) => r.read<bool>('e'))
      .distinct();

  /// X4: fires (debounced by the caller) whenever `cloud_items` changes.
  Stream<void> watchChangeTick() =>
      _db.tableUpdates(TableUpdateQuery.onTable(_db.cloudItems)).map((_) {});

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
  /// file restarts from 0). Their partial documents stay on the row: the
  /// runner deletes them before it writes again. Returns their URIs.
  Future<List<String>> resetInterrupted() => _write(
    () => _db.transaction(() async {
      final rows = await (_db.select(
        _db.cloudItems,
      )..where((i) => i.status.equalsValue(CloudItemStatus.uploading))).get();
      if (rows.isEmpty) return const <String>[];
      await (_db.update(
        _db.cloudItems,
      )..where((i) => i.status.equalsValue(CloudItemStatus.uploading))).write(
        const CloudItemsCompanion(status: Value(CloudItemStatus.queued)),
      );
      return [for (final r in rows) ?r.remoteUri];
    }),
  );

  /// Rows of the last [since] for the Transfers page, newest first, plus
  /// every unfinished row and every verified move whose original may still
  /// be deleted, however old.
  Stream<List<CloudItemRow>> watchJobs({required DateTime since}) =>
      (_db.select(_db.cloudItems)
            ..where(
              (i) =>
                  i.createdAt.isBiggerOrEqualValue(since) |
                  i.status.isInValues(_active) |
                  (i.mode.equalsValue(CloudItemMode.move) &
                      i.status.equalsValue(CloudItemStatus.verified) &
                      (i.sourceOutcome.isNull() |
                          i.sourceOutcome.isInValues(_originalMayGo))),
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

/// A verified move row whose original may still be deleted ("Delete
/// originals"). An original that wasn't found isn't offered again.
bool cloudOriginalMayGo(CloudItemRow row) =>
    row.mode == CloudItemMode.move &&
    row.status == CloudItemStatus.verified &&
    switch (row.sourceOutcome) {
      null || SourceOutcome.keptDeclined || SourceOutcome.keptCancelled => true,
      SourceOutcome.keptFailed => row.error != CloudItemErrors.sourceGone,
      _ => false,
    };
