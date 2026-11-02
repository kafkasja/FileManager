import 'package:kfm/core/db/tables/share_offers_table.dart';
import 'package:meta/meta.dart';

export 'package:kfm/core/db/tables/share_offers_table.dart'
    show OfferDirection, OfferFileStatus, OfferStatus;

/// One file of a [ShareOffer] (TASK-N12). Immutable.
@immutable
class ShareOfferFile {
  const new({
    required this.seq,
    required this.name,
    required this.sizeBytes,
    this.mimeType,
    this.localFileId,
    this.canonicalPath,
    this.sourceModifiedAtMs,
    this.uploadId,
    this.status = OfferFileStatus.waiting,
    this.error,
  });

  final int seq;
  final String name;
  final int sizeBytes;
  final String? mimeType;

  /// Outgoing (N12b): the offered file id; incoming: the imported file.
  final String? localFileId;

  /// Outgoing (N12b): the exact path the client may read.
  final String? canonicalPath;
  final int? sourceModifiedAtMs;

  /// Incoming: the N9 upload that claimed this file.
  final String? uploadId;
  final OfferFileStatus status;
  final String? error;

  bool get ended =>
      status == OfferFileStatus.done ||
      status == OfferFileStatus.failed ||
      status == OfferFileStatus.cancelled;

  ShareOfferFile copyWith({
    String? localFileId,
    Object? uploadId = _keep,
    OfferFileStatus? status,
    Object? error = _keep,
  }) => ShareOfferFile(
    seq: seq,
    name: name,
    sizeBytes: sizeBytes,
    mimeType: mimeType,
    localFileId: localFileId ?? this.localFileId,
    canonicalPath: canonicalPath,
    sourceModifiedAtMs: sourceModifiedAtMs,
    uploadId: identical(uploadId, _keep) ? this.uploadId : uploadId as String?,
    status: status ?? this.status,
    error: identical(error, _keep) ? this.error : error as String?,
  );
}

const Object _keep = Object();

/// A send-files offer held by this device's share server (TASK-N12).
@immutable
class ShareOffer {
  const new({
    required this.id,
    required this.direction,
    required this.peerFingerprint,
    required this.peerName,
    required this.status,
    required this.files,
    required this.createdAt,
    required this.expiresAt,
    this.declineReason,
    this.folder,
    this.autoAccepted = false,
    this.decidedAt,
  });

  final String id;
  final OfferDirection direction;
  final String peerFingerprint;
  final String peerName;
  final OfferStatus status;
  final List<ShareOfferFile> files;
  final DateTime createdAt;

  /// Pending: the decision deadline. Accepted: the grant end.
  final DateTime expiresAt;

  /// `OfferDeclineReason` wire name.
  final String? declineReason;

  /// Incoming + accepted: where files land.
  final String? folder;
  final bool autoAccepted;
  final DateTime? decidedAt;

  int get fileCount => files.length;
  int get totalBytes => files.fold(0, (a, f) => a + f.sizeBytes);
  bool get isOpen =>
      status == OfferStatus.pending || status == OfferStatus.accepted;
  bool get allFilesEnded => files.every((f) => f.ended);

  ShareOffer copyWith({
    OfferStatus? status,
    List<ShareOfferFile>? files,
    DateTime? expiresAt,
    Object? declineReason = _keep,
    String? folder,
    bool? autoAccepted,
    DateTime? decidedAt,
  }) => ShareOffer(
    id: id,
    direction: direction,
    peerFingerprint: peerFingerprint,
    peerName: peerName,
    status: status ?? this.status,
    files: files ?? this.files,
    createdAt: createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
    declineReason: identical(declineReason, _keep)
        ? this.declineReason
        : declineReason as String?,
    folder: folder ?? this.folder,
    autoAccepted: autoAccepted ?? this.autoAccepted,
    decidedAt: decidedAt ?? this.decidedAt,
  );

  ShareOffer withFile(ShareOfferFile f) => copyWith(
    files: [
      for (final x in files)
        if (x.seq == f.seq) f else x,
    ],
  );
}
