import 'package:kfm/core/db/tables/transfers_table.dart';
import 'package:kfm/features/connect/domain/offer_protocol.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:meta/meta.dart';

export 'package:kfm/core/db/tables/transfers_table.dart'
    show
        SourceOutcome,
        TransferDirection,
        TransferFileStatus,
        TransferMode,
        TransferPauseReason,
        TransferStatus;

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

  /// N10: the local file was edited mid-upload (it starts over).
  static const sourceChanged = 'source_changed';

  /// N11: the copy didn't match its source (wire code too). Set on the
  /// first mismatch (the file starts over once); a second one fails it.
  static const verificationFailed = 'verification_failed';

  /// N11: a move whose source is already gone (moved before).
  static const alreadyMoved = 'already_moved';

  /// X2: "Remove location" is on and location couldn't be removed from
  /// the file, so it isn't sent.
  static const locationNotRemoved = 'location_not_removed';

  /// N12: the receiver declined the offer.
  static const offerDeclined = 'offer_declined';

  /// N12: the receiver has no room for the offer (declined at once).
  static const offerNoSpace = 'offer_no_space';

  /// N12: nobody answered within 2 minutes.
  static const offerExpired = 'offer_expired';

  /// N12: the receiver stopped it (or its grant ended).
  static const offerCancelled = 'offer_cancelled';
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
    this.etag,
    this.nextRetryAt,
    this.senderSha256,
    this.receiverSha256,
    this.sourceOutcome,
    this.sourceError,
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

  /// Failed tries of the current backoff series (N10).
  final int attempts;

  /// N10 download validator (`If-Range`).
  final String? etag;

  /// N10: a queued file waits for its next try until then.
  final DateTime? nextRetryAt;

  /// N10/N11: the sending side's SHA-256.
  final String? senderSha256;

  /// N11: the receiving side's SHA-256 of the final file. Set only for a
  /// verified copy of a move job: its original may be deleted.
  final String? receiverSha256;

  /// N11: what happened to the original (null = not deleted yet).
  final SourceOutcome? sourceOutcome;

  /// N11: why the original was kept (`keptFailed`).
  final String? sourceError;

  /// N11: a verified copy whose original is still to be deleted (pending,
  /// or kept for a reason "Delete originals" may retry).
  bool get originalDeletable =>
      status == TransferFileStatus.done &&
      receiverSha256 != null &&
      switch (sourceOutcome) {
        null ||
        SourceOutcome.keptDeclined ||
        SourceOutcome.keptFailed ||
        SourceOutcome.keptCancelled => true,
        _ => false,
      };

  /// N11: deletable and nothing tried yet.
  bool get originalPending => originalDeletable && sourceOutcome == null;

  /// Queued again after a failure, waiting for its next try (N10).
  bool get isRetrying =>
      status == TransferFileStatus.queued && nextRetryAt != null;

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
    this.pauseReason,
    this.deleteMode,
    this.deviceTemporary = false,
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

  /// Set while [status] is `paused` (N10).
  final TransferPauseReason? pauseReason;

  /// N11: upload-moves snapshot the delete mode at creation; null for
  /// copies and download-moves (the other device's trash).
  final DeleteMode? deleteMode;

  bool get isMove => mode == TransferMode.move;

  /// N12: a send (push) into an offer: the offer id, else null.
  String? get offerId => offerIdOfRoot(targetRootId);
  bool get isOffer => offerId != null;

  /// N12b: a download of an offer the other device made: its id.
  String? get inboxOfferId => offerIdOfInboxRoot(targetRootId);

  /// N12: waiting for the other device to accept.
  bool get awaitingAccept =>
      isPaused && pauseReason == TransferPauseReason.awaitingAccept;

  /// N11: no file is waiting or running any more.
  bool get allFilesEnded => files.every((f) => f.isFinished);

  /// The device was connected without "Remember" (no reconnect without a
  /// code).
  final bool deviceTemporary;
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

  bool get isPaused => status == TransferStatus.paused;
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
  const new({
    this.bytes = const {},
    this.bytesPerSecond = const {},
    this.finalizing = const {},
  });

  /// By transfer file id.
  final Map<int, int> bytes;

  /// By job id.
  final Map<String, double> bytesPerSecond;

  /// N11: move jobs whose originals are being deleted.
  final Set<String> finalizing;

  static const empty = TransferLive();

  /// [job]'s transferred bytes, live where known.
  int doneBytesOf(TransferJob job) => job.files.fold(
    0,
    (s, f) =>
        s +
        switch (f.status) {
          // N11: every byte is there; only the check is left.
          TransferFileStatus.done ||
          TransferFileStatus.verifying => f.sizeBytes,
          TransferFileStatus.running => bytes[f.id] ?? f.bytesDone,
          // A paused or retrying file keeps what it already has (N10).
          TransferFileStatus.queued => f.bytesDone,
          _ => 0,
        },
  );
}
