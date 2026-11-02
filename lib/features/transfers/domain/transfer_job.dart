import 'package:kfm/core/db/tables/transfers_table.dart';
import 'package:meta/meta.dart';

export 'package:kfm/core/db/tables/transfers_table.dart'
    show TransferDirection, TransferFileStatus, TransferMode, TransferStatus;

/// Engine error codes stored in `transfer_files.error` next to
/// `ApiErrorCode` wire codes and `FileOpFailure` names (TASK-N9).
abstract final class TransferErrors {
  /// Not enough space on this device (receiver = us).
  static const noSpaceHere = 'no_space_here';

  /// The app was closed or crashed while the file was running.
  static const interrupted = 'interrupted';

  /// The other device went away mid-file.
  static const unavailable = 'unavailable';

  /// The local file is gone.
  static const sourceGone = 'source_gone';

  /// The received byte count didn't match.
  static const incomplete = 'incomplete';
}

/// One file of a [TransferJob] (immutable snapshot of its row).
@immutable
class TransferFile {
  const new({
    required this.id,
    required this.transferId,
    required this.seq,
    required this.sourceFileId,
    required this.name,
    required this.sizeBytes,
    required this.sourceModifiedAtMs,
    required this.bytesDone,
    required this.status,
    this.error,
    this.targetFileId,
    this.uploadId,
    this.attempts = 0,
  });

  final int id;
  final String transferId;
  final int seq;
  final String sourceFileId;
  final String name;
  final int sizeBytes;
  final int sourceModifiedAtMs;
  final int bytesDone;
  final TransferFileStatus status;
  final String? error;
  final String? targetFileId;
  final String? uploadId;
  final int attempts;

  bool get isFinished => switch (status) {
    TransferFileStatus.done ||
    TransferFileStatus.failed ||
    TransferFileStatus.cancelled ||
    TransferFileStatus.skipped => true,
    _ => false,
  };
}

/// A job: files to or from one device.
@immutable
class TransferJob {
  const new({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.deviceFingerprint,
    required this.direction,
    required this.mode,
    required this.targetPath,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.files,
    this.targetRootId,
    this.swipeSessionId,
  });

  final String id;
  final String deviceId;
  final String deviceName;
  final String deviceFingerprint;
  final TransferDirection direction;
  final TransferMode mode;
  final String? targetRootId;
  final String targetPath;
  final TransferStatus status;
  final int? swipeSessionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// In `seq` order.
  final List<TransferFile> files;

  int get totalBytes => files.fold(0, (s, f) => s + f.sizeBytes);
  int get doneCount =>
      files.where((f) => f.status == TransferFileStatus.done).length;
  int get failedCount =>
      files.where((f) => f.status == TransferFileStatus.failed).length;

  bool get isFinished => switch (status) {
    TransferStatus.done ||
    TransferStatus.failed ||
    TransferStatus.cancelled => true,
    _ => false,
  };

  bool get isActive =>
      status == TransferStatus.running || status == TransferStatus.queued;
}

/// The job status that follows from its files' statuses.
TransferStatus jobStatusOf(Iterable<TransferFileStatus> files) {
  final all = files.toList();
  if (all.any(
    (s) => s == TransferFileStatus.running || s == TransferFileStatus.verifying,
  )) {
    return TransferStatus.running;
  }
  if (all.contains(TransferFileStatus.queued)) return TransferStatus.queued;
  if (all.contains(TransferFileStatus.failed)) return TransferStatus.failed;
  if (all.isEmpty || all.contains(TransferFileStatus.cancelled)) {
    return TransferStatus.cancelled;
  }
  return TransferStatus.done;
}

/// Live bytes of running files and the speed of each running job,
/// published by the engine at most every 250 ms.
@immutable
class TransferLive {
  const new({this.bytes = const {}, this.bytesPerSecond = const {}});

  /// By transfer file id.
  final Map<int, int> bytes;

  /// By job id.
  final Map<String, double> bytesPerSecond;

  static const empty = TransferLive();

  /// [job]'s transferred bytes, live where known.
  int doneBytesOf(TransferJob job) => job.files.fold(
    0,
    (s, f) =>
        s +
        switch (f.status) {
          TransferFileStatus.done => f.sizeBytes,
          TransferFileStatus.running => bytes[f.id] ?? f.bytesDone,
          _ => 0,
        },
  );
}
