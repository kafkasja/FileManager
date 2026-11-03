import 'package:meta/meta.dart';

/// What the cloud icon shows for one local file (TASK-X4).
enum CloudBadge { none, onCloud, changedSinceUpload }

/// One uploaded `cloud_items` row as X4 needs it (status already filtered
/// to handedToProvider/verified).
@immutable
class CloudUploadFact {
  const new({
    required this.destinationId,
    required this.sizeBytes,
    required this.sourceModifiedAtMs,
    required this.uploadedAtMs,
  });

  final int destinationId;
  final int sizeBytes;
  final int sourceModifiedAtMs;
  final int uploadedAtMs;

  /// The local file still has the size and modified time it was uploaded
  /// with. Inequality, not "newer": an older version also differs.
  bool matches({required int localSizeBytes, required int localModifiedAtMs}) =>
      sizeBytes == localSizeBytes && sourceModifiedAtMs == localModifiedAtMs;

  @override
  bool operator ==(Object other) =>
      other is CloudUploadFact &&
      other.destinationId == destinationId &&
      other.sizeBytes == sizeBytes &&
      other.sourceModifiedAtMs == sourceModifiedAtMs &&
      other.uploadedAtMs == uploadedAtMs;

  @override
  int get hashCode =>
      Object.hash(destinationId, sizeBytes, sourceModifiedAtMs, uploadedAtMs);
}

/// The one "on cloud" rule; `MediaIndexDao._applyQuery`'s `onCloud`
/// predicate is its SQL twin (the agreement test keeps them equal).
/// [localModifiedAtMs] = media_index.modifiedAtMs
/// (`FileRef.modifiedAt.millisecondsSinceEpoch` for index-built refs).
CloudBadge cloudBadgeFor({
  required List<CloudUploadFact> uploads,
  required int localSizeBytes,
  required int localModifiedAtMs,
}) {
  if (uploads.isEmpty) return CloudBadge.none;
  final unchanged = uploads.any(
    (u) => u.matches(
      localSizeBytes: localSizeBytes,
      localModifiedAtMs: localModifiedAtMs,
    ),
  );
  return unchanged ? CloudBadge.onCloud : CloudBadge.changedSinceUpload;
}
