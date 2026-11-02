import 'package:flutter/foundation.dart' show listEquals, setEquals;
import 'package:kfm/core/files/file_ref.dart';
import 'package:meta/meta.dart';

/// Files another app shared into KFM (TASK-X1), resolved to real `ms:`
/// files or app-owned `path:` copies.
@immutable
class SharedBatch {
  const new({
    required this.id,
    required this.receivedAt,
    required this.files,
    required this.copiedIds,
    this.failedCount = 0,
    this.skippedNotFiles = false,
  });

  final String id;
  final DateTime receivedAt;
  final List<FileRef> files;

  /// [FileRef.id]s that are KFM's own copies (in `shared_in/`).
  final Set<String> copiedIds;

  /// Items KFM couldn't read or copy (access revoked, no space).
  final int failedCount;

  /// Text or a link only: nothing to show.
  final bool skippedNotFiles;

  bool isCopy(FileRef f) => copiedIds.contains(f.id);

  SharedBatch copyWith({List<FileRef>? files, Set<String>? copiedIds}) =>
      SharedBatch(
        id: id,
        receivedAt: receivedAt,
        files: files ?? this.files,
        copiedIds: copiedIds ?? this.copiedIds,
        failedCount: failedCount,
        skippedNotFiles: skippedNotFiles,
      );

  @override
  bool operator ==(Object other) =>
      other is SharedBatch &&
      other.id == id &&
      other.receivedAt == receivedAt &&
      listEquals(other.files, files) &&
      setEquals(other.copiedIds, copiedIds) &&
      other.failedCount == failedCount &&
      other.skippedNotFiles == skippedNotFiles;

  @override
  int get hashCode => Object.hash(
    id,
    receivedAt,
    Object.hashAll(files),
    Object.hashAllUnordered(copiedIds),
    failedCount,
    skippedNotFiles,
  );
}

/// Copy progress of one big item (files > 50 MB).
@immutable
class ShareInProgress {
  const new({
    required this.batchId,
    required this.index,
    required this.bytes,
    required this.total,
  });

  final String batchId;
  final int index;
  final int bytes;
  final int total;

  @override
  bool operator ==(Object other) =>
      other is ShareInProgress &&
      other.batchId == batchId &&
      other.index == index &&
      other.bytes == bytes &&
      other.total == total;

  @override
  int get hashCode => Object.hash(batchId, index, bytes, total);
}
