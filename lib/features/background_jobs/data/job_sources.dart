import 'package:kfm/features/background_jobs/domain/job_progress.dart';
import 'package:kfm/features/folders/data/local_jobs_dao.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';

/// Key prefixes: one namespace for the three job sources.
const transferKeyPrefix = 't:';
const localKeyPrefix = 'l:';
const incomingKeyPrefix = 'i:';

/// A Wi-Fi transfer (N9–N12) as a [JobProgress].
JobProgress transferProgressOf(TransferJob job, TransferLive live) {
  final upload = job.direction == TransferDirection.upload;
  final kind = switch ((upload, job.isMove)) {
    (true, false) => JobKind.send,
    (true, true) => JobKind.moveTo,
    (false, false) => JobKind.download,
    (false, true) => JobKind.moveFrom,
  };
  final phase = switch (job.status) {
    TransferStatus.queued || TransferStatus.running => JobPhase.running,
    // N12: waiting for the accept keeps polling: it counts as running.
    TransferStatus.paused when job.awaitingAccept => JobPhase.running,
    TransferStatus.paused => JobPhase.paused,
    TransferStatus.done => JobPhase.done,
    TransferStatus.failed => JobPhase.failed,
    TransferStatus.cancelled => JobPhase.cancelled,
  };
  return JobProgress(
    key: '$transferKeyPrefix${job.id}',
    kind: kind,
    target: DeviceTarget(job.deviceName),
    phase: phase,
    files: job.files.length,
    filesDone: job.doneCount,
    filesFailed: job.failedCount,
    bytesTotal: job.totalBytes,
    bytesDone: live.doneBytesOf(job),
  );
}

/// A U2 local job as a [JobProgress]; [live] = the copying file's bytes.
JobProgress localProgressOf(
  LocalJobView view,
  ({int position, int bytes})? live,
) {
  final job = view.job;
  final phase = switch (job.status) {
    LocalJobStatus.queued || LocalJobStatus.running => JobPhase.running,
    LocalJobStatus.paused => JobPhase.paused,
    LocalJobStatus.done => JobPhase.done,
    LocalJobStatus.failed => JobPhase.failed,
    LocalJobStatus.cancelled => JobPhase.cancelled,
  };
  var done = 0;
  for (final f in view.files) {
    done += switch (f.status) {
      LocalFileStatus.done ||
      LocalFileStatus.verified ||
      LocalFileStatus.verifying ||
      LocalFileStatus.skipped ||
      LocalFileStatus.failed => f.sizeBytes,
      LocalFileStatus.copying when live?.position == f.position =>
        live!.bytes.clamp(0, f.sizeBytes),
      _ => 0,
    };
  }
  return JobProgress(
    key: '$localKeyPrefix${job.id}',
    kind: job.mode == LocalJobMode.move ? JobKind.localMove : JobKind.localCopy,
    target: PlaceTarget(job.targetPlaceId, job.targetFolder),
    phase: phase,
    files: view.total,
    filesDone: view.files
        .where(
          (f) =>
              f.status == LocalFileStatus.done ||
              f.status == LocalFileStatus.verified,
        )
        .length,
    filesFailed: view.failed,
    bytesTotal: view.bytesTotal,
    bytesDone: done,
  );
}
