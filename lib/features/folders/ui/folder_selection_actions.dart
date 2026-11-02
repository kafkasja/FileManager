import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/folders/ui/file_op_flow.dart';
import 'package:kfm/features/selection/ui/selection_actions.dart';

/// B4's selection bar actions: Move to / Delete as buttons, Copy to /
/// Duplicate under More. The selection is never cleared afterwards (B6),
/// except that a move to another place (a U2 job) drops the moved files.
final List<SelectionAction> folderSelectionActions = List.unmodifiable([
  SelectionAction(
    id: 'b4.move',
    order: 10,
    primary: true,
    label: (c) => c.l10n.selectionActionMove,
    icon: Icons.drive_file_move_outlined,
    run: _withFiles(
      (context, ref, files, skipped) => moveOrCopyFiles(
        context,
        ref,
        files,
        copy: false,
        skippedNeedAccess: skipped,
        fromSelection: true,
      ),
    ),
  ),
  SelectionAction(
    id: 'b4.delete',
    order: 20,
    primary: true,
    label: (c) => c.l10n.selectionActionDelete,
    icon: Icons.delete_outline,
    run: _withFiles(
      (context, ref, files, skipped) =>
          deleteFiles(context, ref, files, skippedNeedAccess: skipped),
    ),
  ),
  SelectionAction(
    id: 'b4.copy',
    order: 30,
    label: (c) => c.l10n.selectionActionCopy,
    icon: Icons.copy_outlined,
    run: _withFiles(
      (context, ref, files, skipped) => moveOrCopyFiles(
        context,
        ref,
        files,
        copy: true,
        skippedNeedAccess: skipped,
      ),
    ),
  ),
  SelectionAction(
    id: 'b4.duplicate',
    order: 40,
    label: (c) => c.l10n.selectionActionDuplicate,
    icon: Icons.control_point_duplicate,
    run: _withFiles(
      (context, ref, files, skipped) =>
          duplicateFiles(context, ref, files, skippedNeedAccess: skipped),
    ),
  ),
]);

typedef _FilesAction = Future<void> Function(
  BuildContext context,
  WidgetRef ref,
  List<FileRef> files,
  int skippedNeedAccess,
);

/// Resolves the selection ids first (`loadSelectionForAction`).
Future<void> Function(BuildContext, WidgetRef, List<String>) _withFiles(
  _FilesAction action,
) => (context, ref, ids) async {
  final loaded = await loadSelectionForAction(context, ref, ids);
  if (loaded == null || !context.mounted) return;
  await action(context, ref, loaded.files, loaded.needAllFiles);
};
