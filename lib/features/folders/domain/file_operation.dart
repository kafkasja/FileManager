import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:meta/meta.dart';

/// One Browse file operation on one or more files (TASK-B4). Folder rename
/// is separate (`FolderOps.renameFolder`).
@immutable
sealed class FileOperation {
  const new(this.files);

  final List<FileRef> files;
}

final class MoveOp extends FileOperation {
  const new(super.files, this.targetFolder);

  final String targetFolder;
}

final class CopyOp extends FileOperation {
  const new(super.files, this.targetFolder);

  final String targetFolder;
}

/// A copy next to the original (`a (1).jpg`); never asks about collisions.
final class DuplicateOp extends FileOperation {
  const new(super.files);
}

final class RenameOp extends FileOperation {
  new(FileRef f, this.newName) : super([f]);

  final String newName;
}

/// Trash (restorable) or permanent, per the D1 setting.
final class DeleteOp extends FileOperation {
  const new(super.files, {required this.permanent});

  final bool permanent;
}

/// What to do when the target folder already has a file with that name.
enum CollisionChoice { replace, keepBoth, skip }

@immutable
class OperationProgress {
  const new({
    required this.done,
    required this.total,
    required this.bytesDone,
    required this.bytesTotal,
    this.current,
  });

  final int done;
  final int total;

  /// Sum of the sizes of finished files (F3's copy has no byte callback).
  final int bytesDone;
  final int bytesTotal;

  /// Name of the file being worked on.
  final String? current;
}

/// One file's result. `after` null = skipped or failed (`error` set when
/// failed). `replaced` / `trashed`: the existing file a Replace put in the
/// trash.
typedef OpResult = ({
  FileRef before,
  FileRef? after,
  FileRef? replaced,
  TrashedItem? trashed,
  FileOpException? error,
});

@immutable
class CompletedOperation {
  const new({
    required this.op,
    required this.results,
    required this.cancelled,
    this.stoppedEarly = false,
  });

  final FileOperation op;
  final List<OpResult> results;
  final bool cancelled;

  /// A `noSpace` / `userCancelled` failure stopped the batch before every
  /// file was reached (the last result has that error).
  final bool stoppedEarly;

  /// Files the batch never reached (cancelled or stopped early).
  int get notProcessed => op.files.length - results.length;

  int get failed => results.where((r) => r.error != null).length;

  /// Done files. A delete has no `after`: every result without an error
  /// counts.
  int get succeeded => results
      .where((r) => r.after != null || (op is DeleteOp && r.error == null))
      .length;

  /// Collision Skips (neither done nor failed).
  int get skipped => results.length - succeeded - failed;
}
