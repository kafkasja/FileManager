import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:kfm/features/archive/ui/archive_flow.dart';
import 'package:kfm/features/archive/ui/archive_view_screen.dart';
import 'package:kfm/features/browse/ui/folder_menu.dart';
import 'package:kfm/features/browse/ui/widgets/file_actions_menu.dart';
import 'package:kfm/features/folders/ui/file_op_flow.dart';
import 'package:kfm/features/selection/ui/selection_actions.dart';

/// B5's single-file ⋮ items, only for `.zip` files (right after Open with;
/// a Normal-mode tap still opens Android "Open with", B1).
final List<FileMenuItem> archiveFileMenuItems = List.unmodifiable([
  FileMenuItem(
    order: 12,
    label: (c) => c.l10n.archiveViewContents,
    icon: Icons.folder_zip_outlined,
    isAvailable: isZipFile,
    onSelected: viewZipContents,
  ),
  FileMenuItem(
    order: 14,
    label: (c) => c.l10n.archiveExtractHere,
    icon: Icons.unarchive_outlined,
    isAvailable: isZipFile,
    onSelected: (context, ref, f) =>
        extractZip(context, ref, f, destination: ExtractDestination.here),
  ),
  FileMenuItem(
    order: 16,
    label: (c) => c.l10n.archiveExtractTo,
    icon: Icons.drive_folder_upload_outlined,
    isAvailable: isZipFile,
    onSelected: (context, ref, f) => extractZip(
      context,
      ref,
      f,
      destination: ExtractDestination.chooseFolder,
    ),
  ),
]);

/// B5's selection bar action, under "More".
final SelectionAction compressSelectionAction = SelectionAction(
  id: 'b5.compress',
  order: 50,
  label: (c) => c.l10n.archiveCompress,
  icon: Icons.folder_zip_outlined,
  run: (context, ref, ids) async {
    final loaded = await loadSelectionForAction(context, ref, ids);
    if (loaded == null || !context.mounted) return;
    await compressFiles(context, ref, loaded.files);
  },
);

/// B5's folder ⋮ item (not on a volume root).
final FolderMenuItem compressFolderMenuItem = FolderMenuItem(
  label: (c) => c.l10n.archiveCompress,
  icon: Icons.folder_zip_outlined,
  onSelected: compressFolder,
  isAvailable: (f) => f.path != volumeRootOf(f.path),
);
