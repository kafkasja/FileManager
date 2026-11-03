import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/browse/ui/widgets/browse_parts.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// What was being done to the file; picks the fallback message.
enum FileOpVerb { move, copy, rename, other }

/// Why a file operation failed, for a snackbar (TASK-B4 §12; P2's swipe
/// `fileOpFailureText` delegates here). [error] is usually a
/// [FileOpException]; anything else gets the [verb]'s generic message.
///
/// [swipeTarget]: the target is a folder from a swipe action (P2), so a
/// `notFound` means that folder is gone and a permission problem means it
/// needs All files access. Elsewhere `notFound` means the file is gone.
String fileOpFailureMessage(
  AppLocalizations l,
  Object? error,
  FileRef file, {
  FileOpVerb verb = FileOpVerb.other,
  bool swipeTarget = false,
}) {
  final failure = error is FileOpException ? error.failure : null;
  final fallback = switch (verb) {
    FileOpVerb.move => l.fileOpMoveFailed(file.name),
    FileOpVerb.copy => l.fileOpCopyFailed(file.name),
    FileOpVerb.rename => l.fileOpRenameFailed(file.name),
    FileOpVerb.other => l.fileOpFailedGeneric(file.name),
  };
  if (swipeTarget) {
    return switch (failure) {
      FileOpFailure.notFound => l.fileOpFolderMissing,
      FileOpFailure.userCancelled => l.fileOpDeclined,
      FileOpFailure.noSpace => l.fileOpNoSpace,
      FileOpFailure.volumeEjecting => l.ejectRefused,
      FileOpFailure.inUse => l.fileOpInUse(file.name),
      FileOpFailure.unsupported ||
      FileOpFailure.permissionDenied => l.fileOpNeedsAllFiles,
      _ => fallback,
    };
  }
  return switch (failure) {
    FileOpFailure.notFound => l.fileOpNotFound(file.name),
    FileOpFailure.userCancelled => l.fileOpDeclined,
    FileOpFailure.noSpace => l.fileOpNoSpace,
    FileOpFailure.permissionDenied => l.fileOpPermission(file.name),
    FileOpFailure.unsupported => l.fileOpNeedsAllFiles,
    FileOpFailure.invalidName => l.nameInvalid,
    FileOpFailure.targetExists => l.nameExists,
    FileOpFailure.pendingFolderUnavailable => l.pendingFallbackTitle,
    FileOpFailure.unavailable => l.remoteNotConnected,
    FileOpFailure.volumeEjecting => l.ejectRefused,
    FileOpFailure.inUse => l.fileOpInUse(file.name),
    FileOpFailure.noTrash => l.fileOpNoTrash,
    FileOpFailure.ioError || null => fallback,
  };
}

/// Why a folder could not be created or renamed ([name] = the folder).
String folderOpFailureMessage(
  AppLocalizations l,
  FileOpException e,
  String name,
) => switch (e.failure) {
  FileOpFailure.targetExists => l.nameExists,
  FileOpFailure.invalidName => l.nameInvalid,
  FileOpFailure.permissionDenied ||
  FileOpFailure.unsupported => l.fileOpNeedsAllFiles,
  FileOpFailure.notFound => l.fileOpNotFound(name),
  FileOpFailure.volumeEjecting => l.ejectRefused,
  FileOpFailure.inUse => l.fileOpInUse(name),
  _ => l.fileOpFailedGeneric(name),
};

/// "Not enough space (needs 3 GB, 1 GB free)".
String spaceRefusedMessage(
  AppLocalizations l, {
  required int needed,
  required int free,
}) => l.opSpaceRefused(
  formatBytes(needed, locale: l.localeName),
  formatBytes(free, locale: l.localeName),
);

/// The end snackbar of a Browse operation: "Moved 12 files to Holiday ·
/// 1 failed · 2 skipped", "Stopped: 40 of 500 done · …" (cancelled, or
/// stopped early by no space / a declined dialog, which adds the reason).
/// A single failed file gets its failure message instead.
///
/// Deletes count every result without an error as done (a deleted file
/// has no `after`); other operations count results with an `after`.
String operationSummary(AppLocalizations l, CompletedOperation done) {
  final op = done.op;
  final results = done.results;
  final failed = done.failed;
  final ok = op is DeleteOp
      ? results.where((r) => r.error == null).length
      : done.succeeded;
  final skipped = op is DeleteOp
      ? 0
      : results.where((r) => r.after == null && r.error == null).length;

  if (op.files.length == 1 && failed == 1 && !done.cancelled) {
    final r = results.firstWhere((r) => r.error != null);
    return fileOpFailureMessage(l, r.error, r.before, verb: _verbOf(op));
  }

  // Stopped early (no space, a declined dialog): the files never reached
  // aren't in `results`; say why it stopped.
  final stop = done.stoppedEarly
      ? results.where((r) => r.error != null).lastOrNull
      : null;
  final main = done.cancelled || done.stoppedEarly
      ? l.opCancelledSummary(ok, op.files.length)
      : switch (op) {
          MoveOp(:final targetFolder) => l.opMovedSummary(
            ok,
            nameOfFolder(l, targetFolder),
          ),
          CopyOp(:final targetFolder) => l.opCopiedSummary(
            ok,
            nameOfFolder(l, targetFolder),
          ),
          DuplicateOp() => l.opDuplicatedSummary(ok),
          RenameOp(:final newName) => l.opRenamedSummary(
            results.firstOrNull?.after?.name ?? newName,
          ),
          DeleteOp(:final permanent) =>
            permanent ? l.opDeletedSummary(ok) : l.opTrashedSummary(ok),
        };
  return [
    main,
    if (failed > 0) l.opFailedSummary(failed),
    if (skipped > 0) l.opSkippedSummary(skipped),
    if (stop != null)
      fileOpFailureMessage(l, stop.error, stop.before, verb: _verbOf(op)),
  ].join(' · ');
}

FileOpVerb _verbOf(FileOperation op) => switch (op) {
  MoveOp() => FileOpVerb.move,
  CopyOp() || DuplicateOp() => FileOpVerb.copy,
  RenameOp() => FileOpVerb.rename,
  DeleteOp() => FileOpVerb.other,
};
