import 'package:kfm/core/db/tables/rename_batches_table.dart';
import 'package:kfm/features/rename/domain/name_pattern.dart';
import 'package:meta/meta.dart';

export 'package:kfm/core/db/tables/rename_batches_table.dart'
    show RenameBatchStatus;

/// A rename batch (TASK-P3).
@immutable
class RenameBatch {
  const new({
    required this.id,
    required this.sessionId,
    required this.status,
    this.pattern,
  });

  final int id;
  final int sessionId;
  final RenameBatchStatus status;

  /// The pattern apply used (null while collecting).
  final NamePattern? pattern;
}

/// One file in a batch.
@immutable
class RenameBatchItem {
  const new({
    required this.batchId,
    required this.fileId,
    required this.position,
    required this.folderPath,
    required this.originalName,
    required this.currentFileId,
    required this.currentName,
    this.newName,
    this.tempName,
    this.skipped = false,
    this.skipReason,
  });

  final int batchId;

  /// FileRef.id when added.
  final String fileId;
  final int position;
  final String folderPath;
  final String originalName;
  final String currentFileId;
  final String currentName;
  final String? newName;
  final String? tempName;
  final bool skipped;
  final String? skipReason;
}
