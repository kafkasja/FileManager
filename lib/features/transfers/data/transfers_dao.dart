import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/tables/known_devices_table.dart';
import 'package:kfm/core/db/tables/transfers_table.dart';
import 'package:kfm/core/utils/random_id.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

part 'transfers_dao.g.dart';

/// A queued file plus what the engine needs to run it.
typedef QueuedTransferFile = ({TransferFile file, TransferJob job});

/// What a new job's files are made of.
typedef NewTransferFile = ({
  String sourceFileId,
  String name,
  int sizeBytes,
  int sourceModifiedAtMs,
});

/// Raw access to `transfers` + `transfer_files` (TASK-N9). Use
/// [TransfersRepository] from the UI isolate (writes go through the write
/// queue); the in-transaction helpers are for callers already inside a
/// queued transaction (the swipe dispatcher).
@DriftAccessor(tables: [Transfers, TransferFiles, KnownDevices])
class TransfersDao extends DatabaseAccessor<AppDatabase>
    with _$TransfersDaoMixin {
  new(super.attachedDatabase);

  /// Every job, newest first, with its device and files.
  Future<List<TransferJob>> jobs({String? jobId}) async {
    final query = select(transfers).join([
      innerJoin(knownDevices, knownDevices.id.equalsExp(transfers.deviceId)),
    ]);
    if (jobId != null) query.where(transfers.id.equals(jobId));
    query.orderBy([
      OrderingTerm.desc(transfers.createdAt),
      OrderingTerm.desc(transfers.id),
    ]);
    final rows = await query.get();
    if (rows.isEmpty) return const [];
    final fileQuery = select(transferFiles)
      ..orderBy([(f) => OrderingTerm.asc(f.seq)]);
    if (jobId != null) fileQuery.where((f) => f.transferId.equals(jobId));
    final byJob = <String, List<TransferFile>>{};
    for (final f in await fileQuery.get()) {
      (byJob[f.transferId] ??= []).add(transferFileFromRow(f));
    }
    return [
      for (final r in rows)
        _job(
          r.readTable(transfers),
          r.readTable(knownDevices),
          byJob[r.readTable(transfers).id] ?? const [],
        ),
    ];
  }

  Future<TransferJob?> job(String id) async =>
      (await jobs(jobId: id)).firstOrNull;

  /// [jobs] again after every change of the two tables.
  Stream<List<TransferJob>> watchJobs() async* {
    yield await jobs();
    await for (final _ in attachedDatabase.tableUpdates(
      TableUpdateQuery.onAllTables([transfers, transferFiles, knownDevices]),
    )) {
      yield await jobs();
    }
  }

  /// Fires once per insert into `transfer_files` (engine wake-up).
  Stream<void> fileInserts() => attachedDatabase
      .tableUpdates(
        TableUpdateQuery.onTable(
          transferFiles,
          limitUpdateKind: UpdateKind.insert,
        ),
      )
      .map((_) {});

  static TransferJob _job(
    TransferRow t,
    KnownDeviceRow d,
    List<TransferFile> files,
  ) => TransferJob(
    id: t.id,
    deviceId: t.deviceId,
    deviceName: d.name,
    deviceFingerprint: d.publicKeyFingerprint,
    direction: t.direction,
    mode: t.mode,
    targetRootId: t.targetRootId,
    targetPath: t.targetPath,
    status: t.status,
    swipeSessionId: t.swipeSessionId,
    pauseReason: t.pauseReason,
    deleteMode: t.deleteMode == null ? null : DeleteMode.parse(t.deleteMode),
    deviceTemporary: d.isTemporary,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
    files: List.unmodifiable(files),
  );

  /// The name of the known device [id], or null.
  Future<String?> deviceName(String id) async {
    final row = await (select(
      knownDevices,
    )..where((d) => d.id.equals(id))).getSingleOrNull();
    return row?.name;
  }

  Future<TransferFile?> file(int id) async {
    final row = await (select(
      transferFiles,
    )..where((f) => f.id.equals(id))).getSingleOrNull();
    return row == null ? null : transferFileFromRow(row);
  }

  /// Queued files of [deviceFingerprint]'s jobs that aren't paused, oldest
  /// job first, then in `seq` order; [exclude] are already running, files
  /// waiting for a retry after [now] are skipped (N10). A wait longer
  /// than [maxRetryWait] (the backoff cap) can only mean the clock went
  /// back since it was scheduled: such a file is due now (Q5), instead of
  /// waiting until the wall clock catches up (a day for a -1 day jump).
  Future<List<QueuedTransferFile>> nextQueued(
    String deviceFingerprint, {
    required int limit,
    Set<int> exclude = const {},
    DateTime? now,
    Duration? maxRetryWait,
  }) async {
    final at = now ?? DateTime.now();
    final query =
        select(transferFiles).join([
            innerJoin(
              transfers,
              transfers.id.equalsExp(transferFiles.transferId),
            ),
            innerJoin(
              knownDevices,
              knownDevices.id.equalsExp(transfers.deviceId),
            ),
          ])
          ..where(
            transferFiles.status.equalsValue(TransferFileStatus.queued) &
                knownDevices.publicKeyFingerprint.equals(deviceFingerprint) &
                transferFiles.id.isNotIn(exclude) &
                transfers.pauseReason.isNull() &
                (transferFiles.nextRetryAt.isNull() |
                    transferFiles.nextRetryAt.isSmallerOrEqualValue(at) |
                    (maxRetryWait == null
                        ? const Constant(false)
                        : transferFiles.nextRetryAt.isBiggerThanValue(
                            at.add(maxRetryWait),
                          ))),
          )
          ..orderBy([
            OrderingTerm.asc(transfers.createdAt),
            OrderingTerm.asc(transfers.id),
            OrderingTerm.asc(transferFiles.seq),
          ])
          ..limit(limit);
    return [
      for (final r in await query.get())
        (
          file: transferFileFromRow(r.readTable(transferFiles)),
          job: _job(
            r.readTable(transfers),
            r.readTable(knownDevices),
            const [],
          ),
        ),
    ];
  }

  /// Inserts a job with [files] (seq 0…); returns the job id.
  Future<String> insertJob({
    required String deviceId,
    required TransferDirection direction,
    required String targetPath,
    required List<NewTransferFile> files,
    required DateTime now,
    String? targetRootId,
    int? swipeSessionId,
    TransferMode mode = TransferMode.copy,
    DeleteMode? deleteMode,
    TransferPauseReason? pauseReason,
  }) => transaction(() async {
    final id = randomHexId();
    await into(transfers).insert(
      TransfersCompanion.insert(
        id: id,
        deviceId: deviceId,
        direction: direction,
        mode: mode,
        deleteMode: Value(deleteMode?.name),
        targetRootId: Value(targetRootId),
        targetPath: targetPath,
        status: files.isEmpty
            ? TransferStatus.done
            : pauseReason != null
            ? TransferStatus.paused
            : TransferStatus.queued,
        pauseReason: Value(files.isEmpty ? null : pauseReason),
        swipeSessionId: Value(swipeSessionId),
        createdAt: now,
        updatedAt: now,
      ),
    );
    for (final (i, f) in files.indexed) {
      await into(transferFiles).insert(_fileRow(id, i, f));
    }
    return id;
  });

  static TransferFilesCompanion _fileRow(
    String jobId,
    int seq,
    NewTransferFile f,
  ) => TransferFilesCompanion.insert(
    transferId: jobId,
    seq: seq,
    sourceFileId: f.sourceFileId,
    name: f.name,
    sizeBytes: f.sizeBytes,
    sourceModifiedAtMs: f.sourceModifiedAtMs,
    status: TransferFileStatus.queued,
  );

  /// Swipe sends: appends [f] to the open job of ([deviceId], [direction],
  /// [swipeSessionId], target) or starts one. Call inside a transaction.
  /// Returns the new transfer file id.
  Future<int> appendToSessionJob({
    required String deviceId,
    required TransferDirection direction,
    required String targetPath,
    required int swipeSessionId,
    required NewTransferFile f,
    required DateTime now,
    String? targetRootId,
  }) async {
    final open =
        await (select(transfers)
              ..where(
                (t) =>
                    t.deviceId.equals(deviceId) &
                    t.direction.equalsValue(direction) &
                    t.swipeSessionId.equals(swipeSessionId) &
                    t.targetPath.equals(targetPath) &
                    (targetRootId == null
                        ? t.targetRootId.isNull()
                        : t.targetRootId.equals(targetRootId)) &
                    t.status.isInValues([
                      TransferStatus.queued,
                      TransferStatus.running,
                      TransferStatus.paused,
                    ]),
              )
              ..limit(1))
            .getSingleOrNull();
    final String jobId;
    var seq = 0;
    if (open == null) {
      jobId = randomHexId();
      await into(transfers).insert(
        TransfersCompanion.insert(
          id: jobId,
          deviceId: deviceId,
          direction: direction,
          mode: TransferMode.copy,
          targetRootId: Value(targetRootId),
          targetPath: targetPath,
          status: TransferStatus.queued,
          swipeSessionId: Value(swipeSessionId),
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      jobId = open.id;
      final max = transferFiles.seq.max();
      final row =
          await (selectOnly(transferFiles)
                ..addColumns([max])
                ..where(transferFiles.transferId.equals(jobId)))
              .getSingle();
      seq = (row.read(max) ?? -1) + 1;
    }
    final fileId = await into(transferFiles).insert(_fileRow(jobId, seq, f));
    await refreshJob(jobId, now);
    return fileId;
  }

  Future<void> updateFile(int id, TransferFilesCompanion row) =>
      (update(transferFiles)..where((f) => f.id.equals(id))).write(row);

  /// Recomputes the job's status from its files. A job with a pause reason
  /// stays `paused` while anything is unfinished; once everything ended
  /// the reason goes (N10).
  Future<void> refreshJob(String jobId, DateTime now) async {
    final job = await (select(
      transfers,
    )..where((t) => t.id.equals(jobId))).getSingleOrNull();
    if (job == null) return;
    final statuses = await (select(
      transferFiles,
    )..where((f) => f.transferId.equals(jobId))).map((f) => f.status).get();
    final computed = jobStatusOf(statuses);
    final unfinished =
        computed == TransferStatus.queued || computed == TransferStatus.running;
    final paused = job.pauseReason != null && unfinished;
    await (update(transfers)..where((t) => t.id.equals(jobId))).write(
      TransfersCompanion(
        status: Value(paused ? TransferStatus.paused : computed),
        pauseReason: Value(paused ? job.pauseReason : null),
        updatedAt: Value(now),
      ),
    );
  }

  /// Pauses [jobId] with [reason] (N10) when it has unfinished files.
  Future<void> pauseJob(
    String jobId,
    TransferPauseReason reason,
    DateTime now,
  ) async {
    await (update(transfers)..where((t) => t.id.equals(jobId))).write(
      TransfersCompanion(pauseReason: Value(reason)),
    );
    await refreshJob(jobId, now);
  }

  /// Every queued or running job of [deviceFingerprint] → paused with
  /// [reason] (the device went away). Returns their ids.
  Future<List<String>> pauseActiveOfDevice(
    String deviceFingerprint,
    TransferPauseReason reason,
    DateTime now,
  ) async {
    final rows =
        await (select(transfers).join([
              innerJoin(
                knownDevices,
                knownDevices.id.equalsExp(transfers.deviceId),
              ),
            ])..where(
              knownDevices.publicKeyFingerprint.equals(deviceFingerprint) &
                  transfers.status.isInValues([
                    TransferStatus.queued,
                    TransferStatus.running,
                  ]),
            ))
            .get();
    final ids = [for (final r in rows) r.readTable(transfers).id];
    for (final id in ids) {
      await pauseJob(id, reason, now);
    }
    return ids;
  }

  /// Clears [jobId]'s pause (N10): its queued files may start at once and
  /// their backoff series begins again.
  Future<void> resumeJob(String jobId, DateTime now) async {
    await (update(transfers)..where((t) => t.id.equals(jobId))).write(
      const TransfersCompanion(pauseReason: Value(null)),
    );
    await (update(transferFiles)..where(
          (f) =>
              f.transferId.equals(jobId) &
              f.status.equalsValue(TransferFileStatus.queued),
        ))
        .write(
          const TransferFilesCompanion(
            attempts: Value(0),
            nextRetryAt: Value(null),
          ),
        );
    await refreshJob(jobId, now);
  }

  /// Jobs of [deviceFingerprint] paused with [reason].
  Future<List<String>> pausedJobsOf(
    String deviceFingerprint,
    TransferPauseReason reason,
  ) async {
    final rows =
        await (select(transfers).join([
              innerJoin(
                knownDevices,
                knownDevices.id.equalsExp(transfers.deviceId),
              ),
            ])..where(
              knownDevices.publicKeyFingerprint.equals(deviceFingerprint) &
                  transfers.status.equalsValue(TransferStatus.paused) &
                  transfers.pauseReason.equalsValue(reason),
            ))
            .get();
    return [for (final r in rows) r.readTable(transfers).id];
  }

  /// Devices with jobs waiting for them (N10 recovery), oldest job first:
  /// `(fingerprint, temporary)`.
  Future<List<({String fingerprint, bool temporary})>> waitingDevices() async {
    final rows =
        await (select(transfers).join([
                innerJoin(
                  knownDevices,
                  knownDevices.id.equalsExp(transfers.deviceId),
                ),
              ])
              ..where(
                transfers.status.equalsValue(TransferStatus.paused) &
                    // N12: a send waiting for its answer needs the
                    // connection too (its offer is polled over it).
                    transfers.pauseReason.isInValues([
                      TransferPauseReason.waitingForDevice,
                      TransferPauseReason.awaitingAccept,
                    ]),
              )
              ..orderBy([OrderingTerm.asc(transfers.createdAt)]))
            .get();
    final out = <({String fingerprint, bool temporary})>[];
    for (final r in rows) {
      final d = r.readTable(knownDevices);
      if (out.any((o) => o.fingerprint == d.publicKeyFingerprint)) continue;
      out.add((fingerprint: d.publicKeyFingerprint, temporary: d.isTemporary));
    }
    return out;
  }

  /// Ids of files that may still resume (their partials are kept).
  Future<Set<int>> unfinishedFileIds() async {
    final rows =
        await (select(transferFiles)..where(
              (f) => f.status.isInValues([
                TransferFileStatus.queued,
                TransferFileStatus.running,
                TransferFileStatus.verifying,
                TransferFileStatus.failed,
              ]),
            ))
            .get();
    return {for (final r in rows) r.id};
  }

  Future<String?> jobIdOfFile(int fileId) async {
    final row = await (select(
      transferFiles,
    )..where((f) => f.id.equals(fileId))).getSingleOrNull();
    return row?.transferId;
  }

  /// Undo of a swipe send: deletes the file while it is still queued
  /// (and its job when that was its last file). False = already started.
  Future<bool> deleteQueuedFile(int fileId, DateTime now) async {
    final row = await (select(
      transferFiles,
    )..where((f) => f.id.equals(fileId))).getSingleOrNull();
    if (row == null) return true;
    if (row.status != TransferFileStatus.queued) return false;
    await (delete(transferFiles)..where((f) => f.id.equals(fileId))).go();
    final left = await (select(
      transferFiles,
    )..where((f) => f.transferId.equals(row.transferId))).get();
    if (left.isEmpty) {
      await (delete(transfers)..where((t) => t.id.equals(row.transferId))).go();
    } else {
      await refreshJob(row.transferId, now);
    }
    return true;
  }

  /// Queued files of [jobId] (or only [fileId]) → cancelled.
  Future<void> cancelQueued(String jobId, DateTime now, {int? fileId}) async {
    await (update(transferFiles)..where(
          (f) =>
              f.transferId.equals(jobId) &
              f.status.equalsValue(TransferFileStatus.queued) &
              (fileId == null ? const Constant(true) : f.id.equals(fileId)),
        ))
        .write(
          const TransferFilesCompanion(
            status: Value(TransferFileStatus.cancelled),
          ),
        );
    await refreshJob(jobId, now);
  }

  /// N12: the offer of [jobId] ended without (more) bytes: its queued
  /// files are cancelled with [error] and the pause goes.
  Future<void> endOffer(String jobId, String error, DateTime now) async {
    await (update(transferFiles)..where(
          (f) =>
              f.transferId.equals(jobId) &
              f.status.equalsValue(TransferFileStatus.queued),
        ))
        .write(
          TransferFilesCompanion(
            status: const Value(TransferFileStatus.cancelled),
            error: Value(error),
            bytesDone: const Value(0),
          ),
        );
    await (update(transfers)..where((t) => t.id.equals(jobId))).write(
      const TransfersCompanion(pauseReason: Value(null)),
    );
    await refreshJob(jobId, now);
  }

  /// Failed/cancelled files of [jobId] (or only [fileId]) → queued. N10:
  /// a failed file resumes from what is left of its partial (the engine
  /// re-checks it); a cancelled one has none.
  Future<void> requeue(String jobId, DateTime now, {int? fileId}) async {
    await (update(transferFiles)..where(
          (f) =>
              f.transferId.equals(jobId) &
              f.status.isInValues([
                TransferFileStatus.failed,
                TransferFileStatus.cancelled,
              ]) &
              (fileId == null ? const Constant(true) : f.id.equals(fileId)),
        ))
        .write(
          const TransferFilesCompanion(
            status: Value(TransferFileStatus.queued),
            error: Value(null),
            attempts: Value(0),
            nextRetryAt: Value(null),
          ),
        );
    await (update(transfers)..where((t) => t.id.equals(jobId))).write(
      const TransfersCompanion(pauseReason: Value(null)),
    );
    await refreshJob(jobId, now);
  }

  /// N11: writes what happened to each original ([outcomes] by transfer
  /// file id) in one go.
  Future<void> setOutcomes(
    Map<int, ({SourceOutcome outcome, String? error})> outcomes,
  ) async {
    for (final MapEntry(:key, :value) in outcomes.entries) {
      await updateFile(
        key,
        TransferFilesCompanion(
          sourceOutcome: Value(value.outcome),
          sourceError: Value(value.error),
        ),
      );
    }
  }

  /// N11: verified files of [jobId] whose original wasn't deleted yet →
  /// `keptCancelled` (the move job was cancelled).
  Future<void> keepPendingOriginals(String jobId) =>
      (update(transferFiles)..where(
            (f) =>
                f.transferId.equals(jobId) &
                f.status.equalsValue(TransferFileStatus.done) &
                f.receiverSha256.isNotNull() &
                f.sourceOutcome.isNull(),
          ))
          .write(
            const TransferFilesCompanion(
              sourceOutcome: Value(SourceOutcome.keptCancelled),
            ),
          );

  /// Files waiting for a backoff retry (N10).
  Future<bool> hasRetryWaits() async {
    final row =
        await (select(transferFiles)
              ..where((f) => f.nextRetryAt.isNotNull())
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<bool> hasRunning() async {
    final row =
        await (select(transferFiles)
              ..where(
                (f) => f.status.isInValues([
                  TransferFileStatus.running,
                  TransferFileStatus.verifying,
                ]),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// App start (N10): files left `running` are queued again (their
  /// partials resume) and their jobs wait for the device; every backoff
  /// wait starts over. Returns the files recovered.
  Future<int> recoverRunning(DateTime now) => transaction(() async {
    final running =
        await (select(transferFiles)..where(
              (f) => f.status.isInValues([
                TransferFileStatus.running,
                TransferFileStatus.verifying,
              ]),
            ))
            .get();
    for (final f in running) {
      await updateFile(
        f.id,
        const TransferFilesCompanion(status: Value(TransferFileStatus.queued)),
      );
    }
    await (update(transferFiles)..where((f) => f.nextRetryAt.isNotNull()))
        .write(const TransferFilesCompanion(nextRetryAt: Value(null)));
    for (final job in {for (final f in running) f.transferId}) {
      await pauseJob(job, TransferPauseReason.waitingForDevice, now);
    }
    return running.length;
  });

  /// "Clear finished": removes done, failed and cancelled jobs, then the
  /// temporary devices no job references any more (N6). Returns the jobs
  /// removed.
  Future<int> clearFinished() => transaction(() async {
    final n =
        await (delete(transfers)..where(
              (t) => t.status.isInValues([
                TransferStatus.done,
                TransferStatus.failed,
                TransferStatus.cancelled,
              ]),
            ))
            .go();
    await removeOrphanTemporaryDevices();
    return n;
  });

  /// Temporary `known_devices` rows without a job.
  Future<int> removeOrphanTemporaryDevices() =>
      (delete(knownDevices)..where(
            (d) =>
                d.isTemporary.equals(true) &
                notExistsQuery(
                  select(transfers)..where((t) => t.deviceId.equalsExp(d.id)),
                ),
          ))
          .go();

  /// Jobs of [deviceId] (N6's remove dialog).
  Future<int> countForDevice(String deviceId) {
    final count = transfers.id.count();
    return (selectOnly(transfers)
          ..addColumns([count])
          ..where(transfers.deviceId.equals(deviceId)))
        .map((row) => row.read(count) ?? 0)
        .getSingle();
  }
}

TransferFile transferFileFromRow(TransferFileRow r) => TransferFile(
  id: r.id,
  transferId: r.transferId,
  seq: r.seq,
  sourceFileId: r.sourceFileId,
  name: r.name,
  sizeBytes: r.sizeBytes,
  sourceModifiedAtMs: r.sourceModifiedAtMs,
  bytesDone: r.bytesDone,
  status: r.status,
  error: r.error,
  targetFileId: r.targetFileId,
  uploadId: r.uploadId,
  attempts: r.attempts,
  etag: r.etag,
  nextRetryAt: r.nextRetryAt,
  senderSha256: r.senderSha256,
  receiverSha256: r.receiverSha256,
  sourceOutcome: r.sourceOutcome,
  sourceError: r.sourceError,
);

/// Transfers for the UI isolate (TASK-N9): reads go to the DAO, every
/// write through [DbWriteQueue] (ordered; failures on its error stream and
/// on the returned future). Progress writes coalesce per file.
class TransfersRepository {
  new(this.dao, this._queue, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final TransfersDao dao;
  final DbWriteQueue _queue;
  final DateTime Function() _clock;

  DateTime now() => _clock();

  Stream<List<TransferJob>> watchJobs() => dao.watchJobs();

  Future<String> createJob({
    required String deviceId,
    required TransferDirection direction,
    required String targetPath,
    required List<NewTransferFile> files,
    String? targetRootId,
    TransferMode mode = TransferMode.copy,
    DeleteMode? deleteMode,
    TransferPauseReason? pauseReason,
  }) async {
    late String id;
    await _queue.enqueue(null, () async {
      id = await dao.insertJob(
        deviceId: deviceId,
        direction: direction,
        targetPath: targetPath,
        targetRootId: targetRootId,
        files: files,
        now: _clock(),
        mode: mode,
        deleteMode: deleteMode,
        pauseReason: pauseReason,
      );
    });
    return id;
  }

  /// Status changes: never coalesced.
  Future<void> setFile(int id, String jobId, TransferFilesCompanion row) =>
      _queue.enqueue(null, () async {
        await dao.transaction(() async {
          await dao.updateFile(id, row);
          await dao.refreshJob(jobId, _clock());
        });
      });

  /// Fields that don't change the job's status (uploadId, etag, hashes,
  /// a restarted source's size).
  Future<void> saveFile(int id, TransferFilesCompanion row) =>
      _queue.enqueue(null, () => dao.updateFile(id, row));

  /// N11: see [TransfersDao.setOutcomes]; one transaction.
  Future<void> setOutcomes(
    Map<int, ({SourceOutcome outcome, String? error})> outcomes,
  ) => _queue.enqueue(
    null,
    () => dao.transaction(() => dao.setOutcomes(outcomes)),
  );

  /// N11: see [TransfersDao.keepPendingOriginals].
  Future<void> keepPendingOriginals(String jobId) =>
      _queue.enqueue(null, () => dao.keepPendingOriginals(jobId));

  Future<void> pauseJob(String jobId, TransferPauseReason reason) =>
      _queue.enqueue(null, () => dao.pauseJob(jobId, reason, _clock()));

  Future<List<String>> pauseActiveOfDevice(
    String fingerprint,
    TransferPauseReason reason,
  ) async {
    var ids = const <String>[];
    await _queue.enqueue(null, () async {
      ids = await dao.transaction(
        () => dao.pauseActiveOfDevice(fingerprint, reason, _clock()),
      );
    });
    return ids;
  }

  Future<void> resumeJob(String jobId) =>
      _queue.enqueue(null, () => dao.resumeJob(jobId, _clock()));

  /// Latest value wins.
  Future<void> setProgress(int id, int bytesDone) => _queue.enqueue(
    'transfer_file.$id',
    () =>
        dao.updateFile(id, TransferFilesCompanion(bytesDone: Value(bytesDone))),
  );

  /// N12: see [TransfersDao.endOffer].
  Future<void> endOffer(String jobId, String error) =>
      _queue.enqueue(null, () => dao.endOffer(jobId, error, _clock()));

  Future<void> cancelQueued(String jobId, {int? fileId}) => _queue.enqueue(
    null,
    () => dao.cancelQueued(jobId, _clock(), fileId: fileId),
  );

  Future<void> requeue(String jobId, {int? fileId}) =>
      _queue.enqueue(null, () => dao.requeue(jobId, _clock(), fileId: fileId));

  /// App start: see [TransfersDao.recoverRunning].
  Future<int> recoverRunning() async {
    // Nothing to do on most starts: no write, no transaction.
    if (!await dao.hasRunning() && !await dao.hasRetryWaits()) return 0;
    var n = 0;
    await _queue.enqueue(null, () async {
      n = await dao.recoverRunning(_clock());
    });
    return n;
  }

  Future<int> clearFinished() async {
    var n = 0;
    await _queue.enqueue(null, () async => n = await dao.clearFinished());
    return n;
  }

  /// Undo of a swipe send (see [TransfersDao.deleteQueuedFile]).
  Future<bool> deleteQueuedFile(int fileId) async {
    var removed = false;
    await _queue.enqueue(null, () async {
      removed = await dao.transaction(
        () => dao.deleteQueuedFile(fileId, _clock()),
      );
    });
    return removed;
  }
}
