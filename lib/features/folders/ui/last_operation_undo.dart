import 'package:kfm/core/background/cancel_token.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/features/archive/data/archive_undo.dart';
import 'package:kfm/features/archive/domain/archive_job.dart';
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

/// B5: a zip was created. Undo trashes it.
final class CompressDone extends LastOperation {
  const new(this.zip);

  final FileRef zip;
}

/// B5: an extract of [zipPath] created [files] and the folders [dirs].
/// [stamps] (same order as [files]) are their size and modified time right
/// after the extract. Undo deletes the unchanged ones (they can be
/// extracted again) and trashes the rest, then removes the folders that
/// are empty again (see `ArchiveUndo.undoCreated`).
final class ExtractDone extends LastOperation {
  const new(this.files, this.dirs, {this.zipPath, this.stamps = const []});

  final List<FileRef> files;
  final List<String> dirs;
  final String? zipPath;
  final List<ExtractedStamp> stamps;
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
    switch (state) {
      case CompressDone(:final zip) when zip.id == change.oldId:
        state = CompressDone(change.newRef);
        return;
      case ExtractDone(:final files, :final dirs, :final zipPath, :final stamps)
          when files.any((f) => f.id == change.oldId):
        // Index-aligned with [stamps], which keep the extract-time values.
        state = ExtractDone(
          List.unmodifiable([
            for (final f in files)
              if (f.id == change.oldId) change.newRef else f,
          ]),
          dirs,
          zipPath: zipPath,
          stamps: stamps,
        );
        return;
      default:
        break;
    }
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

  /// B5: `ArchiveService` after a compress / extract.
  /// An extract that created nothing clears the stored one.
  void recordArchive(LastOperation op) => state = switch (op) {
    ExtractDone(:final files, :final dirs) when files.isEmpty && dirs.isEmpty =>
      null,
    CompressDone() || ExtractDone() => op,
    _ => throw ArgumentError.value(op, 'op', 'not a zip / unzip operation'),
  };

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
      case CompressDone(:final zip):
        return await _undoArchive(
          last,
          () => ref
              .read(archiveUndoProvider)
              .undoCreated([zip], cancel: cancel, onProgress: onProgress),
        );
      case ExtractDone(
        :final files,
        :final dirs,
        :final zipPath,
        :final stamps,
      ):
        return await _undoArchive(
          last,
          () => ref
              .read(archiveUndoProvider)
              .undoCreated(
                files,
                dirs: dirs,
                zipPath: zipPath,
                stamps: stamps,
                cancel: cancel,
                onProgress: onProgress,
              ),
        );
    }
  }

  Future<UndoOutcome> _undoArchive(
    LastOperation last,
    Future<UndoOutcome> Function() run,
  ) async {
    final out = await run();
    // Declined / cancelled before anything changed: still undoable.
    if ((out.declined || out.cancelled) &&
        out.undone == 0 &&
        out.failed.isEmpty &&
        state == null) {
      state = last;
    }
    return out;
  }
}
