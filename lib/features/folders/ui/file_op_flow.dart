import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/file_op_messages.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/background/cancel_token.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/permissions/ensure_all_files_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/cloud/ui/cloud_send_flow.dart';
import 'package:kfm/features/folders/data/file_operation_runner.dart';
import 'package:kfm/features/folders/data/folder_ops.dart';
import 'package:kfm/features/folders/data/folder_tree_transfer.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';
import 'package:kfm/features/folders/domain/move_target.dart';
import 'package:kfm/features/folders/ui/collision_dialog.dart';
import 'package:kfm/features/folders/ui/folder_picker_sheet.dart';
import 'package:kfm/features/folders/ui/last_operation_undo.dart';
import 'package:kfm/features/folders/ui/local_job_flow.dart';
import 'package:kfm/features/folders/ui/operation_progress_sheet.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// How long the end snackbar (with Undo) stays (TASK-B4 Decision 1).
const opSnackBarDuration = Duration(seconds: 8);

/// Runs [op] end to end (TASK-B4 §5–§8): All files access for non-media
/// files, the permanent-delete confirm, collisions, the progress sheet for
/// more than [progressSheetThreshold] files, the summary snackbar with
/// Undo and H2's "Delete permanently instead?" fallback. Records the result
/// in `LastOperationUndo`. [skippedNeedAccess]: selected files left out
/// because All files access is missing (added to the summary).
///
/// Returns null when nothing ran (declined, refused for space).
Future<CompletedOperation?> runFileOperation(
  BuildContext context,
  WidgetRef ref,
  FileOperation op, {
  int skippedNeedAccess = 0,
}) async {
  if (op.files.isEmpty) return null;
  if (op.files.any((f) => !f.isMedia) &&
      !await ensureAllFilesAccess(context, ref)) {
    return null;
  }
  if (!context.mounted) return null;
  return await _Host(context).run(op, skippedNeedAccess: skippedNeedAccess);
}

/// Move to… / Copy to…: the folder picker, then [runFileOperation].
Future<void> moveOrCopyFiles(
  BuildContext context,
  WidgetRef ref,
  List<FileRef> files, {
  required bool copy,
  int skippedNeedAccess = 0,
  bool fromSelection = false,
}) async {
  if (files.isEmpty) return;
  final folders = {for (final f in files) f.folderPath};
  final picked = await showMoveTargetPicker(
    context,
    mode: copy ? FolderPickerMode.copy : FolderPickerMode.move,
    // Same-folder move is a no-op.
    disabledFolder: !copy && folders.length == 1 ? folders.single : null,
  );
  if (picked == null || !context.mounted) return;
  final String target;
  switch (picked) {
    case CloudTarget(:final destinationId):
      // X3: into a cloud app's folder (copy, or copy → verify → delete).
      await startCloudJobFlow(
        context,
        ref,
        files,
        destinationId,
        move: !copy,
        fromSelection: fromSelection,
      );
      return;
    case FolderTarget(:final path):
      target = path;
  }
  if (!context.mounted) return;
  // U2: another place (SD card, USB drive) → a verified local job.
  if (needsLocalJob(ref, files, target)) {
    await startLocalJobFlow(
      context,
      ref,
      files,
      target,
      move: !copy,
      fromSelection: fromSelection,
    );
    return;
  }
  await runFileOperation(
    context,
    ref,
    copy ? CopyOp(files, target) : MoveOp(files, target),
    skippedNeedAccess: skippedNeedAccess,
  );
}

/// Delete in the user's delete mode (D1): trash, or permanent after a
/// confirm.
Future<void> deleteFiles(
  BuildContext context,
  WidgetRef ref,
  List<FileRef> files, {
  int skippedNeedAccess = 0,
}) async {
  if (files.isEmpty) return;
  final op = await ref.read(fileOperationRunnerProvider).deleteOp(files);
  if (!context.mounted) return;
  await runFileOperation(
    context,
    ref,
    op,
    skippedNeedAccess: skippedNeedAccess,
  );
}

/// Duplicate next to the originals (`a (1).jpg`).
Future<void> duplicateFiles(
  BuildContext context,
  WidgetRef ref,
  List<FileRef> files, {
  int skippedNeedAccess = 0,
}) => runFileOperation(
  context,
  ref,
  DuplicateOp(files),
  skippedNeedAccess: skippedNeedAccess,
);

/// Rename one file: a name dialog, then a [RenameOp].
Future<void> renameFile(BuildContext context, WidgetRef ref, FileRef f) async {
  final l10n = context.l10n;
  final name = await showNameDialog(
    context,
    title: l10n.fileMenuRename,
    action: l10n.renameAction,
    initial: f.name,
    selectBaseName: true,
  );
  if (name == null || name == f.name || !context.mounted) return;
  await runFileOperation(context, ref, RenameOp(f, name));
}

/// B6 selection ids → files the app may act on now. Files hidden by
/// missing All files access trigger the F4 prompt first; still missing →
/// counted. Null (with a snackbar) when nothing is left.
Future<ActionFiles?> loadSelectionForAction(
  BuildContext context,
  WidgetRef ref,
  List<String> ids,
) async {
  final runner = ref.read(fileOperationRunnerProvider);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  var loaded = await runner.loadForAction(ids);
  if (loaded.needAllFiles > 0 &&
      context.mounted &&
      await ensureAllFilesAccess(context, ref)) {
    loaded = await runner.loadForAction(ids);
  }
  if (loaded.files.isEmpty) {
    if (loaded.needAllFiles > 0) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.opSkippedNeedAccess(loaded.needAllFiles)),
          ),
        );
    }
    return null;
  }
  return loaded;
}

/// B4 drag & drop: moves (or copies, per `AppSettings.foldersDropAction`)
/// the whole selection into [folder].
Future<void> dropSelectionOnFolder(
  BuildContext context,
  WidgetRef ref,
  String folder,
) async {
  final action = await ref
      .read(settingsRepositoryProvider)
      .read(AppSettings.foldersDropAction);
  final ids = await ref.read(selectionControllerProvider.notifier).orderedIds();
  if (!context.mounted) return;
  final loaded = await loadSelectionForAction(context, ref, ids);
  if (loaded == null || !context.mounted) return;
  final files = action == DropAction.move
      ? [
          for (final f in loaded.files)
            if (f.folderPath != folder) f,
        ]
      : loaded.files;
  if (!context.mounted) return;
  if (needsLocalJob(ref, files, folder)) {
    await startLocalJobFlow(
      context,
      ref,
      files,
      folder,
      move: action != DropAction.copy,
      fromSelection: true,
    );
    return;
  }
  await runFileOperation(
    context,
    ref,
    action == DropAction.copy ? CopyOp(files, folder) : MoveOp(files, folder),
    skippedNeedAccess: loaded.needAllFiles,
  );
}

/// PL3: copies (or moves) whole [folders], with loose [files], into
/// [target] (`FolderTreeTransfer`): progress, collisions, the summary
/// snackbar and one Undo for all of it. Needs All files access.
Future<void> transferFolders(
  BuildContext context,
  WidgetRef ref, {
  required List<String> folders,
  required List<FileRef> files,
  required String target,
  required bool move,
}) async {
  if (folders.isEmpty && files.isEmpty) return;
  if (!await ensureAllFilesAccess(context, ref) || !context.mounted) return;
  await _Host(context)
      .runTree(folders: folders, files: files, target: target, move: move);
}

/// Undoes the last Browse file operation (snackbar Undo, Browse overflow).
Future<void> undoLastFileOperation(BuildContext context) =>
    _Host(context).undoLast();

/// Browse's "New folder" inside [parent].
Future<void> createFolderIn(
  BuildContext context,
  WidgetRef ref,
  String parent,
) async {
  final canSeeAll =
      ref.read(storageAccessControllerProvider).value?.canSeeAllFiles ?? false;
  if (!canSeeAll &&
      !isMediaFolderPath(parent) &&
      !await ensureAllFilesAccess(context, ref)) {
    return;
  }
  if (!context.mounted) return;
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final name = await showNameDialog(
    context,
    title: l10n.browseNewFolder,
    action: l10n.create,
    message: l10n.folderPickerNewIn(parent),
  );
  if (name == null) return;
  String text;
  try {
    await ref.read(folderOpsProvider).createFolder(parent, name);
    text = l10n.browseFolderCreated(name);
  } on FileOpException catch (e) {
    text = folderOpFailureMessage(l10n, e, name);
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Folder ⋮ → Rename (TASK-B4 §10): needs All files access; Undo renames
/// it back.
Future<void> renameFolderFlow(
  BuildContext context,
  WidgetRef ref,
  FolderEntry folder,
) async {
  if (!await ensureAllFilesAccess(context, ref) || !context.mounted) return;
  final l10n = context.l10n;
  final name = await showNameDialog(
    context,
    title: l10n.renameFolderTitle,
    action: l10n.renameAction,
    initial: folder.name,
  );
  if (name == null || name == folder.name || !context.mounted) return;
  final host = _Host(context);
  final ops = ref.read(folderOpsProvider);
  try {
    final hostContext = host.context;
    final renamed =
        folder.fileCount > progressSheetThreshold && hostContext != null
        ? await showOperationProgress(
            hostContext,
            label: ProgressLabel.working,
            cancel: CancelToken(),
            task: (_) => ops.renameFolder(folder.path, name),
          )
        : await ops.renameFolder(folder.path, name);
    host.container
        .read(lastOperationUndoProvider.notifier)
        .recordFolderRename(renamed);
    host.show(l10n.opFolderRenamed(nameOf(renamed.newPath)), undo: true);
  } on FileOpException catch (e) {
    host.show(folderOpFailureMessage(l10n, e, name));
  }
}

/// A one-field name dialog (file rename, folder rename, new folder).
/// Returns the trimmed, valid name, or null when cancelled.
Future<String?> showNameDialog(
  BuildContext context, {
  required String title,
  required String action,
  String initial = '',
  String? message,
  bool selectBaseName = false,
}) => showDialog<String>(
  context: context,
  builder: (_) => NameDialog(
    title: title,
    action: action,
    initial: initial,
    message: message,
    selectBaseName: selectBaseName,
  ),
);

class NameDialog extends StatefulWidget {
  const new({
    required this.title,
    required this.action,
    this.initial = '',
    this.message,
    this.selectBaseName = false,
    super.key,
  });

  final String title;
  final String action;
  final String initial;
  final String? message;

  /// Pre-select the name without its extension.
  final bool selectBaseName;

  @override
  State<NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<NameDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial,
  )..selection = _initialSelection();
  bool _invalid = false;

  TextSelection _initialSelection() {
    final text = widget.initial;
    final dot = text.lastIndexOf('.');
    return TextSelection(
      baseOffset: 0,
      extentOffset: widget.selectBaseName && dot > 0 ? dot : text.length,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    try {
      validateFileName(name);
    } on FileOpException {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message case final message?) Text(message),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.nameLabel,
              errorText: _invalid ? l10n.nameInvalid : null,
              errorMaxLines: 3,
            ),
            onChanged: (_) {
              if (_invalid) setState(() => _invalid = false);
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.action)),
      ],
    );
  }
}

/// Handles that outlive the tile or row that started an operation (a moved
/// file leaves its folder's list before the snackbar's Undo is tapped).
class _Host {
  new(BuildContext context)
    : _navigator = Navigator.of(context),
      container = ProviderScope.containerOf(context, listen: false),
      messenger = ScaffoldMessenger.of(context),
      l10n = context.l10n;

  final NavigatorState _navigator;
  final ProviderContainer container;
  final ScaffoldMessengerState messenger;
  final AppLocalizations l10n;

  /// For dialogs and the progress sheet; null once the screen is gone.
  BuildContext? get context => _navigator.mounted ? _navigator.context : null;

  void show(String text, {bool undo = false}) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        duration: opSnackBarDuration,
        persist: false,
        action: undo
            ? SnackBarAction(
                label: l10n.undoAction,
                onPressed: () => unawaited(undoLast()),
              )
            : null,
      ),
    );

  Future<CompletedOperation?> run(
    FileOperation op, {
    int skippedNeedAccess = 0,
  }) async {
    if (op case DeleteOp(permanent: true)) {
      if (!await _confirmPermanent(op.files)) return null;
    }
    final CompletedOperation done;
    try {
      done = await _execute(op);
    } on NotEnoughSpaceException catch (e) {
      show(spaceRefusedMessage(l10n, needed: e.neededBytes, free: e.freeBytes));
      return null;
    }
    container.read(lastOperationUndoProvider.notifier).record(done);
    final extra = <String>[];
    final fallback = done.pendingFolderUnavailable;
    if (fallback.isNotEmpty && await _confirmFallback(fallback.length)) {
      // Not recorded: it would replace the trash part's undo.
      final permanent = await _execute(DeleteOp(fallback, permanent: true));
      extra.add(operationSummary(l10n, permanent));
    }
    if (skippedNeedAccess > 0) {
      extra.add(l10n.opSkippedNeedAccess(skippedNeedAccess));
    }
    show(
      [operationSummary(l10n, done), ...extra].join(' · '),
      undo: done.isUndoable,
    );
    return done;
  }

  Future<void> runTree({
    required List<String> folders,
    required List<FileRef> files,
    required String target,
    required bool move,
  }) async {
    final cancel = CancelToken();
    final transfer = container.read(folderTreeTransferProvider);
    Future<CollisionAnswer> resolve(FileRef incoming, FileRef existing) async {
      final c = context;
      if (c == null) return (CollisionChoice.skip, false);
      return await showCollisionDialog(
        c,
        incoming: incoming,
        existing: existing,
      );
    }

    Future<TreeTransferDone> task(void Function(OperationProgress)? p) =>
        transfer.transfer(
          folders: folders,
          files: files,
          target: target,
          move: move,
          cancel: cancel,
          resolveCollision: resolve,
          onProgress: p,
        );

    final TreeTransferDone done;
    try {
      final c = context;
      done = c != null
          ? await showOperationProgress(
              c,
              label: move ? ProgressLabel.moving : ProgressLabel.copying,
              cancel: cancel,
              task: task,
            )
          : await task(null);
    } on FolderIntoItselfException {
      show(l10n.opFolderIntoItself);
      return;
    } on NotEnoughSpaceException catch (e) {
      show(spaceRefusedMessage(l10n, needed: e.neededBytes, free: e.freeBytes));
      return;
    } on FileOpException catch (e) {
      show(folderOpFailureMessage(l10n, e, nameOf(target)));
      return;
    }
    container.read(lastOperationUndoProvider.notifier).recordTree(done);
    final failed = [
      for (final r in done.results)
        if (r.error != null) r,
    ].length;
    final moved = [
      for (final r in done.results)
        if (r.after != null) r,
    ].length;
    show(
      [
        if (move)
          l10n.opTreeMoved(done.folderCount, moved)
        else
          l10n.opTreeCopied(done.folderCount, moved),
        if (failed > 0) l10n.opFailedSummary(failed),
      ].join(' · '),
      undo: done.isUndoable,
    );
  }

  Future<CompletedOperation> _execute(FileOperation op) async {
    final cancel = CancelToken();
    final runner = container.read(fileOperationRunnerProvider);
    Future<CollisionAnswer> resolve(FileRef incoming, FileRef existing) async {
      final c = context;
      if (c == null) return (CollisionChoice.skip, false);
      return await showCollisionDialog(
        c,
        incoming: incoming,
        existing: existing,
        showApplyToAll: op.files.length > 1,
      );
    }

    Future<CompletedOperation> task(void Function(OperationProgress)? p) =>
        runner.run(
          op,
          cancel: cancel,
          resolveCollision: resolve,
          onProgress: p,
        );

    final c = context;
    if (op.files.length > progressSheetThreshold && c != null) {
      return await showOperationProgress(
        c,
        label: switch (op) {
          MoveOp() => ProgressLabel.moving,
          CopyOp() || DuplicateOp() => ProgressLabel.copying,
          DeleteOp() => ProgressLabel.deleting,
          RenameOp() => ProgressLabel.working,
        },
        cancel: cancel,
        task: task,
      );
    }
    return await task(null);
  }

  Future<bool> _confirmPermanent(List<FileRef> files) async {
    final c = context;
    if (c == null) return false;
    final bytes = files.fold<int>(0, (s, f) => s + f.sizeBytes);
    final ok = await showDialog<bool>(
      context: c,
      builder: (context) => AlertDialog(
        title: Text(l10n.opPermanentConfirmTitle),
        content: Text(
          l10n.opPermanentConfirmBody(
            files.length,
            formatBytes(bytes, locale: l10n.localeName),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.permanentConfirmAction),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<bool> _confirmFallback(int count) async {
    final c = context;
    if (c == null) return false;
    final ok = await showDialog<bool>(
      context: c,
      builder: (context) => AlertDialog(
        title: Text(l10n.pendingFallbackTitle),
        content: Text(l10n.pendingFallbackBody(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.pendingFallbackAction),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> undoLast() async {
    final last = container.read(lastOperationUndoProvider);
    if (last == null) return;
    final undo = container.read(lastOperationUndoProvider.notifier);
    final count = switch (last) {
      FileOpDone(:final done) => done.results.length,
      ExtractDone(:final files) => files.length,
      CompressDone() => 1,
      FolderRenameDone() => 0,
      FolderTreeDone(:final done) => done.fileCount,
    };
    final cancel = CancelToken();
    final UndoOutcome? outcome;
    try {
      final c = context;
      outcome = count > progressSheetThreshold && c != null
          ? await showOperationProgress(
              c,
              label: ProgressLabel.undoing,
              cancel: cancel,
              task: (p) => undo.undo(cancel: cancel, onProgress: p),
            )
          : await undo.undo(cancel: cancel);
    } on FileOpException catch (e) {
      show(
        e.failure == FileOpFailure.userCancelled
            ? l10n.fileOpDeclined
            : l10n.undoFailed,
      );
      return;
    }
    if (outcome == null) return;
    show(_undoMessage(outcome, count));
  }

  String _undoMessage(UndoOutcome o, int total) {
    if (o.declined && o.undone == 0) return l10n.fileOpDeclined;
    return [
      if (o.cancelled)
        l10n.opUndoStopped(o.undone, total)
      else if (o.undone > 0 || (o.missing == 0 && o.failed.isEmpty))
        l10n.opUndone,
      if (o.missing > 0) l10n.opUndoMissing(o.missing),
      if (o.failed.isNotEmpty) l10n.opFailedSummary(o.failed.length),
    ].join(' · ');
  }
}
