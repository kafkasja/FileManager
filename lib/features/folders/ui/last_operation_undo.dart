import 'package:kfm/core/background/cancel_token.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/features/folders/data/file_operation_runner.dart';
import 'package:kfm/features/folders/data/folder_ops.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'last_operation_undo.g.dart';

/// The one Browse operation that can still be undone.
@immutable
sealed class LastOperation {
  const new();
}

final class FileOpDone extends LastOperation {
  const new(this.done);

  final CompletedOperation done;
}

final class FolderRenameDone extends LastOperation {
  const new(this.oldPath, this.newPath);

  final String oldPath;
  final String newPath;
}

/// Undo of the last Browse file operation (TASK-B4 §8; not S2's swipe
/// `UndoService`). Memory only: lost on restart (Decision 1). A new
/// operation replaces the stored one; undoing clears it (but an undo that
/// was declined or cancelled before it changed anything keeps it).
///
/// Follows F3's `idChanges`: a stored `after` whose id changes (a MediaStore
/// re-key) is updated, so undo still finds it.
@Riverpod(keepAlive: true)
class LastOperationUndo extends _$LastOperationUndo {
  @override
  LastOperation? build() {
    final sub = ref.watch(fileSourceProvider).idChanges.listen(_onIdChange);
    ref.onDispose(sub.cancel);
    return null;
  }

  void _onIdChange(FileIdChange change) {
    if (state case FileOpDone(:final done)) {
      if (!done.results.any((r) => r.after?.id == change.oldId)) return;
      OpResult rekey(OpResult r) => r.after?.id != change.oldId
          ? r
          : (
              before: r.before,
              after: change.newRef,
              replaced: r.replaced,
              trashed: r.trashed,
              error: r.error,
            );
      state = FileOpDone(
        CompletedOperation(
          op: done.op,
          results: List.unmodifiable(done.results.map(rekey)),
          cancelled: done.cancelled,
          stoppedEarly: done.stoppedEarly,
        ),
      );
    }
  }

  /// Call after every [FileOperationRunner.run]. Ops with nothing to undo
  /// (permanent delete, all skipped/failed) clear the stored one.
  void record(CompletedOperation done) =>
      state = done.isUndoable ? FileOpDone(done) : null;

  void recordFolderRename(FolderRenamed renamed) =>
      state = FolderRenameDone(renamed.oldPath, renamed.newPath);

  void clear() => state = null;

  /// Undoes the stored operation (null when there is none). Missing files
  /// are counted in [UndoOutcome.missing]; the rest is undone.
  Future<UndoOutcome?> undo({
    CancelToken? cancel,
    void Function(OperationProgress)? onProgress,
  }) async {
    final last = state;
    if (last == null) return null;
    state = null;
    switch (last) {
      case FileOpDone(:final done):
        final out = await ref
            .read(fileOperationRunnerProvider)
            .undo(done, cancel: cancel, onProgress: onProgress);
        // Declined / cancelled before anything changed: still undoable.
        // A partial undo is cleared (what's left isn't tracked).
        if ((out.declined || out.cancelled) &&
            out.undone == 0 &&
            out.failed.isEmpty &&
            state == null) {
          state = last;
        }
        return out;
      case FolderRenameDone(:final oldPath, :final newPath):
        try {
          await ref
              .read(folderOpsProvider)
              .renameFolder(newPath, nameOf(oldPath));
          return const UndoOutcome(undone: 1);
        } on FileOpException catch (e) {
          return e.failure == FileOpFailure.notFound
              ? const UndoOutcome(missing: 1)
              : UndoOutcome(failed: [e]);
        }
    }
  }
}
