import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/tables/known_devices_table.dart';
import 'package:kfm/core/db/tables/transfers_table.dart';
import 'package:kfm/core/utils/random_id.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';

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

  /// Queued files of [deviceFingerprint]'s jobs, oldest job first, then in
  /// `seq` order; [exclude] are already running.
  Future<List<QueuedTransferFile>> nextQueued(
    String deviceFingerprint, {
    required int limit,
    Set<int> exclude = const {},
  }) async {
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
                transferFiles.id.isNotIn(exclude),
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
  }) => transaction(() async {
    final id = randomHexId();
    await into(transfers).insert(
      TransfersCompanion.insert(
        id: id,
        deviceId: deviceId,
        direction: direction,
        mode: TransferMode.copy,
        targetRootId: Value(targetRootId),
        targetPath: targetPath,
        status: files.isEmpty ? TransferStatus.done : TransferStatus.queued,
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

  /// Recomputes the job's status from its files.
  Future<void> refreshJob(String jobId, DateTime now) async {
    final statuses = await (select(
      transferFiles,
    )..where((f) => f.transferId.equals(jobId))).map((f) => f.status).get();
    await (update(transfers)..where((t) => t.id.equals(jobId))).write(
      TransfersCompanion(
        status: Value(jobStatusOf(statuses)),
        updatedAt: Value(now),
      ),
    );
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

  /// Failed/cancelled files of [jobId] (or only [fileId]) → queued from 0.
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
            bytesDone: Value(0),
            error: Value(null),
            uploadId: Value(null),
          ),
        );
    await refreshJob(jobId, now);
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

  /// App start: files left `running` failed with [error].
  Future<int> failRunning(String error, DateTime now) => transaction(() async {
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
        TransferFilesCompanion(
          status: const Value(TransferFileStatus.failed),
          error: Value(error),
        ),
      );
    }
    for (final job in {for (final f in running) f.transferId}) {
      await refreshJob(job, now);
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

  /// Latest value wins.
  Future<void> setProgress(int id, int bytesDone) => _queue.enqueue(
    'transfer_file.$id',
    () =>
        dao.updateFile(id, TransferFilesCompanion(bytesDone: Value(bytesDone))),
  );

  Future<void> cancelQueued(String jobId, {int? fileId}) => _queue.enqueue(
    null,
    () => dao.cancelQueued(jobId, _clock(), fileId: fileId),
  );

  Future<void> requeue(String jobId, {int? fileId}) =>
      _queue.enqueue(null, () => dao.requeue(jobId, _clock(), fileId: fileId));

  Future<int> failRunning() async {
    // Nothing to do on most starts: no write, no transaction.
    if (!await dao.hasRunning()) return 0;
    var n = 0;
    await _queue.enqueue(null, () async {
      n = await dao.failRunning(TransferErrors.interrupted, _clock());
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
