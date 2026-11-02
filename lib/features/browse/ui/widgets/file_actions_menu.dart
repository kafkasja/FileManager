import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/archive/ui/archive_actions.dart';
import 'package:kfm/features/browse/ui/open_file.dart';
import 'package:kfm/features/details/ui/file_details_sheet.dart';
import 'package:kfm/features/folders/ui/file_op_flow.dart';
import 'package:kfm/features/privacy/ui/share_flow.dart';
import 'package:kfm/features/tags/ui/tag_actions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_actions_menu.g.dart';

/// One entry of a file's ⋮ menu (TASK-B4): Browse tiles and rows, search
/// results and the B7 preview. B4 registers Open with, Rename, Duplicate,
/// Copy to, Move to and Delete; B5 adds zip items, B9 tag/favorite, X2
/// Share, B10 Details (last).
@immutable
class FileMenuItem {
  const new({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.order = 0,
    this.isAvailable = _always,
    this.labelFor,
  });

  final String Function(BuildContext context) label;

  /// A label that depends on the file (B9: Add to / Remove from favorites).
  final String Function(BuildContext context, FileRef file)? labelFor;
  final IconData icon;

  /// Lower first.
  final int order;
  final bool Function(FileRef file) isAvailable;
  final Future<void> Function(BuildContext context, WidgetRef ref, FileRef f)
  onSelected;

  static bool _always(FileRef _) => true;
}

/// Sorted by [FileMenuItem.order].
@Riverpod(keepAlive: true)
List<FileMenuItem> fileMenuItems(Ref ref) => List.unmodifiable(
  <FileMenuItem>[
    FileMenuItem(
      order: 10,
      label: (c) => c.l10n.openWith,
      icon: Icons.open_in_new,
      onSelected: openWithOrExplain,
    ),
    FileMenuItem(
      order: 20,
      label: (c) => c.l10n.fileMenuRename,
      icon: Icons.drive_file_rename_outline,
      onSelected: renameFile,
    ),
    FileMenuItem(
      order: 30,
      label: (c) => c.l10n.fileMenuDuplicate,
      icon: Icons.control_point_duplicate,
      onSelected: (context, ref, f) => duplicateFiles(context, ref, [f]),
    ),
    FileMenuItem(
      order: 40,
      label: (c) => c.l10n.fileMenuCopyTo,
      icon: Icons.copy_outlined,
      onSelected: (context, ref, f) =>
          moveOrCopyFiles(context, ref, [f], copy: true),
    ),
    FileMenuItem(
      order: 50,
      label: (c) => c.l10n.fileMenuMoveTo,
      icon: Icons.drive_file_move_outlined,
      onSelected: (context, ref, f) =>
          moveOrCopyFiles(context, ref, [f], copy: false),
    ),
    FileMenuItem(
      order: 60,
      label: (c) => c.l10n.fileMenuDelete,
      icon: Icons.delete_outline,
      onSelected: (context, ref, f) => deleteFiles(context, ref, [f]),
    ),
    ...archiveFileMenuItems,
    shareFileMenuItem,
    ...tagFileMenuItems,
    FileMenuItem(
      order: 90,
      label: (c) => c.l10n.fileMenuDetails,
      icon: Icons.info_outline,
      onSelected: (context, ref, f) => showFileDetails(context, f),
    ),
  ]..sort((a, b) => a.order.compareTo(b.order)),
);

/// The ⋮ button for [file]. [overlay]: a small dark circle for use on a
/// thumbnail (grid tile, preview).
class FileActionsMenuButton extends ConsumerWidget {
  const new({required this.file, this.overlay = false, super.key});

  final FileRef file;
  final bool overlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      for (final item in ref.watch(fileMenuItemsProvider))
        if (item.isAvailable(file)) item,
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<FileMenuItem>(
      tooltip: context.l10n.fileMenuTooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 200),
      style: overlay
          ? IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              minimumSize: const Size.square(32),
              maximumSize: const Size.square(32),
              padding: EdgeInsets.zero,
            )
          : null,
      iconSize: overlay ? 18 : null,
      icon: const Icon(Icons.more_vert),
      onSelected: (item) => unawaited(item.onSelected(context, ref, file)),
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem(
            value: item,
            child: ListTile(
              leading: Icon(item.icon),
              title: Text(
                item.labelFor?.call(context, file) ?? item.label(context),
              ),
            ),
          ),
      ],
    );
  }
}
