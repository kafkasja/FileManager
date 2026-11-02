import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/tables/local_jobs_table.dart';
import 'package:kfm/core/db/tables/transfers_table.dart';
import 'package:meta/meta.dart';

export 'package:kfm/core/db/tables/local_jobs_table.dart';

/// A local job with its files (the "On this phone" card, TASK-U2).
@immutable
class LocalJobView {
  const new(this.job, this.files);

  final LocalJobRow job;
  final List<LocalJobFileRow> files;

  int get total => files.length;
  int get finished => files
      .where(
        (f) =>
            f.status == LocalFileStatus.done ||
            f.status == LocalFileStatus.verified ||
            f.status == LocalFileStatus.skipped ||
            f.status == LocalFileStatus.failed,
      )
      .length;
  int get failed =>
      files.where((f) => f.status == LocalFileStatus.failed).length;
  int get skipped =>
      files.where((f) => f.status == LocalFileStatus.skipped).length;
  int get bytesTotal => files.fold(0, (s, f) => s + f.sizeBytes);
  int get bytesDone => files
      .where(
        (f) =>
            f.status == LocalFileStatus.done ||
            f.status == LocalFileStatus.verified,
      )
      .fold(0, (s, f) => s + f.sizeBytes);

  /// Files saved under another name (FAT characters).
  List<LocalJobFileRow> get renamed =>
      files.where((f) => f.targetName != f.originalName).toList();

  /// Move originals the user can still try to delete ("Delete originals").
  List<LocalJobFileRow> get originalsLeft => [
    for (final f in files)
      if (job.mode == LocalJobMode.move &&
          f.targetId != null &&
          f.sha256 != null &&
          (f.status == LocalFileStatus.verified ||
              f.status == LocalFileStatus.done) &&
          retryableOutcome(f.sourceOutcome))
        f,
  ];

  static bool retryableOutcome(SourceOutcome? o) =>
      o == null ||
      o == SourceOutcome.keptDeclined ||
      o == SourceOutcome.keptFailed ||
      o == SourceOutcome.keptCancelled;
}

/// `local_jobs` + `local_job_files` (TASK-U2). Writes go through the
/// [DbWriteQueue] (no coalescing: every status row matters).
class LocalJobsDao {
  new(this._db, this._queue);

  final AppDatabase _db;
  final DbWriteQueue _queue;

  Future<void> create(
    LocalJobsCompanion job,
    List<LocalJobFilesCompanion> files,
  ) => _queue.enqueue(
    null,
    () => _db.transaction(() async {
      await _db.into(_db.localJobs).insert(job);
      await _db.batch((b) => b.insertAll(_db.localJobFiles, files));
    }),
  );

  Future<LocalJobRow?> job(String id) => (_db.select(
    _db.localJobs,
  )..where((j) => j.id.equals(id))).getSingleOrNull();

  Future<List<LocalJobFileRow>> files(String jobId) =>
      (_db.select(_db.localJobFiles)
            ..where((f) => f.jobId.equals(jobId))
            ..orderBy([(f) => OrderingTerm.asc(f.position)]))
          .get();

  /// Oldest first.
  Future<List<LocalJobRow>> jobsWith(Set<LocalJobStatus> statuses) =>
      (_db.select(_db.localJobs)
            ..where((j) => j.status.isInValues(statuses.toList()))
            ..orderBy([(j) => OrderingTerm.asc(j.createdAtMs)]))
          .get();

  Future<void> setJob(
    String id,
    LocalJobStatus status, {
    String? failureReason,
    int? nowMs,
  }) => _queue.enqueue(
    null,
    () => (_db.update(_db.localJobs)..where((j) => j.id.equals(id))).write(
      LocalJobsCompanion(
        status: Value(status),
        failureReason: Value(failureReason),
        updatedAtMs: Value(nowMs ?? DateTime.now().millisecondsSinceEpoch),
      ),
    ),
  );

  Future<void> setFile(
    String jobId,
    int position,
    LocalJobFilesCompanion change,
  ) => _queue.enqueue(
    null,
    () =>
        (_db.update(_db.localJobFiles)..where(
              (f) => f.jobId.equals(jobId) & f.position.equals(position),
            ))
            .write(change),
  );

  /// N11 outcomes of one `deleteOriginals` call, in one transaction; files
  /// whose original is settled become `done`.
  Future<void> setOutcomes(
    String jobId,
    Map<int, ({SourceOutcome outcome, String? error})> byPosition,
  ) => _queue.enqueue(
    null,
    () => _db.transaction(() async {
      for (final MapEntry(key: position, value: o) in byPosition.entries) {
        await (_db.update(_db.localJobFiles)..where(
              (f) => f.jobId.equals(jobId) & f.position.equals(position),
            ))
            .write(
              LocalJobFilesCompanion(
                sourceOutcome: Value(o.outcome),
                status: const Value(LocalFileStatus.done),
                failureReason: Value(o.error),
              ),
            );
      }
    }),
  );

  /// App start: nothing runs yet. Running jobs pause; files caught
  /// mid-copy start over (their parts are deleted by the runner).
  Future<void> recoverAtStart() => _queue.enqueue(
    null,
    () => _db.transaction(() async {
      await (_db.update(
        _db.localJobs,
      )..where((j) => j.status.equalsValue(LocalJobStatus.running))).write(
        const LocalJobsCompanion(
          status: Value(LocalJobStatus.paused),
          failureReason: Value('interrupted'),
        ),
      );
      await (_db.update(_db.localJobFiles)..where(
            (f) => f.status.isInValues([
              LocalFileStatus.copying,
              LocalFileStatus.verifying,
            ]),
          ))
          .write(
            const LocalJobFilesCompanion(status: Value(LocalFileStatus.queued)),
          );
    }),
  );

  /// Jobs created since [since], newest first.
  Stream<List<LocalJobView>> watchRecent({required DateTime since}) {
    final cutoff = since.millisecondsSinceEpoch;
    final query =
        _db.select(_db.localJobs).join([
            leftOuterJoin(
              _db.localJobFiles,
              _db.localJobFiles.jobId.equalsExp(_db.localJobs.id),
            ),
          ])
          ..where(_db.localJobs.createdAtMs.isBiggerOrEqualValue(cutoff))
          ..orderBy([
            OrderingTerm.desc(_db.localJobs.createdAtMs),
            OrderingTerm.asc(_db.localJobFiles.position),
          ]);
    return query.watch().map((rows) {
      final jobs = <String, LocalJobRow>{};
      final files = <String, List<LocalJobFileRow>>{};
      for (final r in rows) {
        final job = r.readTable(_db.localJobs);
        jobs[job.id] = job;
        final f = r.readTableOrNull(_db.localJobFiles);
        (files[job.id] ??= []).addAll([?f]);
      }
      return [
        for (final j in jobs.values) LocalJobView(j, files[j.id] ?? const []),
      ];
    });
  }

  /// "Clear finished": done, failed and cancelled jobs (files cascade).
  Future<void> clearFinished() => _queue.enqueue(
    null,
    () =>
        (_db.delete(_db.localJobs)..where(
              (j) => j.status.isInValues([
                LocalJobStatus.done,
                LocalJobStatus.failed,
                LocalJobStatus.cancelled,
              ]),
            ))
            .go(),
  );
}
