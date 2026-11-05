import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/archive/ui/archive_actions.dart';
import 'package:kfm/features/browse/ui/open_file.dart';
import 'package:kfm/features/connect/ui/link_providers.dart';
import 'package:kfm/features/details/ui/file_details_sheet.dart';
import 'package:kfm/features/folders/ui/file_op_flow.dart';
import 'package:kfm/features/privacy/ui/share_flow.dart';
import 'package:kfm/features/tags/ui/tag_actions.dart';
import 'package:kfm/features/transfers/ui/link_send.dart';
import 'package:kfm/features/transfers/ui/send_flow.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_actions_menu.g.dart';

/// One entry of a file's ⋮ menu (TASK-B4): Browse tiles and rows, search
/// results and the B7 preview. B4 registers Open with, Rename, Duplicate,
/// Copy to, Move to and Delete; B5 adds zip items, B9 tag/favorite, X2
/// Share, B10 Details (last). The enlarged viewers build their action bar
/// from the same list ([FileMenuIds], `viewer_action_bar.dart`).
@immutable
class FileMenuItem {
  const new({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.order = 0,
    this.isAvailable = _always,
    this.labelFor,
    this.id,
    this.leaves = false,
  });

  /// Stable name for the viewer bar's picks ([FileMenuIds]).
  final String? id;

  /// [onSelected] completes with `true` once the file left its list
  /// (deleted, moved away): a viewer then shows the next file.
  final bool leaves;

  final String Function(BuildContext context) label;

  /// A label that depends on the file (B9: Add to / Remove from favorites).
  final String Function(BuildContext context, FileRef file)? labelFor;
  final IconData icon;

  /// Lower first.
  final int order;
  final bool Function(FileRef file) isAvailable;

  /// Completes with `true` when a [leaves] item removed the file; other
  /// items' results are ignored.
  final Future<Object?> Function(BuildContext context, WidgetRef ref, FileRef f)
  onSelected;

  static bool _always(FileRef _) => true;
}

/// [FileMenuItem.id]s the viewers pick by name.
abstract final class FileMenuIds {
  static const sendLinked = 'e1.sendLinked';
  static const openWith = 'b4.openWith';
  static const rename = 'b4.rename';
  static const duplicate = 'b4.duplicate';
  static const copyTo = 'b4.copyTo';
  static const moveTo = 'b4.moveTo';
  static const delete = 'b4.delete';
  static const share = 'x2.share';
  static const details = 'b10.details';
}

/// Sorted by [FileMenuItem.order]. E1: while linked, "Send to `name`"
/// comes first.
@Riverpod(keepAlive: true)
List<FileMenuItem> fileMenuItems(Ref ref) => List.unmodifiable(
  <FileMenuItem>[
    if (ref.watch(currentLinkProvider) case final link?)
      sendToLinkFileMenuItem(link),
    FileMenuItem(
      id: FileMenuIds.openWith,
      order: 10,
      label: (c) => c.l10n.openWith,
      icon: Icons.open_in_new,
      onSelected: openWithOrExplain,
    ),
    FileMenuItem(
      id: FileMenuIds.rename,
      order: 20,
      label: (c) => c.l10n.fileMenuRename,
      icon: Icons.drive_file_rename_outline,
      onSelected: renameFile,
    ),
    FileMenuItem(
      id: FileMenuIds.duplicate,
      order: 30,
      label: (c) => c.l10n.fileMenuDuplicate,
      icon: Icons.control_point_duplicate,
      onSelected: (context, ref, f) => duplicateFiles(context, ref, [f]),
    ),
    FileMenuItem(
      id: FileMenuIds.copyTo,
      order: 40,
      label: (c) => c.l10n.fileMenuCopyTo,
      icon: Icons.copy_outlined,
      onSelected: (context, ref, f) =>
          moveOrCopyFiles(context, ref, [f], copy: true),
    ),
    FileMenuItem(
      id: FileMenuIds.moveTo,
      order: 50,
      leaves: true,
      label: (c) => c.l10n.fileMenuMoveTo,
      icon: Icons.drive_file_move_outlined,
      onSelected: (context, ref, f) =>
          moveOrCopyFiles(context, ref, [f], copy: false),
    ),
    FileMenuItem(
      id: FileMenuIds.delete,
      order: 60,
      leaves: true,
      label: (c) => c.l10n.fileMenuDelete,
      icon: Icons.delete_outline,
      onSelected: (context, ref, f) => deleteFiles(context, ref, [f]),
    ),
    ...archiveFileMenuItems,
    shareFileMenuItem,
    sendFileMenuItem,
    ...tagFileMenuItems,
    FileMenuItem(
      id: FileMenuIds.details,
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
    // E4 (H5): a plain IconButton that opens the menu on tap, so a tile
    // keeps no PopupMenuButton state while scrolling.
    return IconButton(
      tooltip: context.l10n.fileMenuTooltip,
      padding: EdgeInsets.zero,
      // On a thumbnail: no dark disc (it crowded the tile), just a white
      // icon with a shadow; the tap area stays 48 dp.
      style: overlay
          ? IconButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size.square(48),
              padding: EdgeInsets.zero,
            )
          : null,
      iconSize: overlay ? 22 : null,
      icon: Icon(
        Icons.more_vert,
        shadows: overlay
            ? const [Shadow(blurRadius: 6), Shadow(blurRadius: 2)]
            : null,
      ),
      onPressed: () => unawaited(_open(context, ref, items)),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    List<FileMenuItem> items,
  ) async {
    final button = context.findRenderObject()! as RenderBox;
    final overlayBox =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlayBox),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlayBox,
        ),
      ),
      Offset.zero & overlayBox.size,
    );
    final item = await showMenu<FileMenuItem>(
      context: context,
      position: position,
      constraints: const BoxConstraints(minWidth: 200),
      items: [
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
    if (item == null || !context.mounted) return;
    await item.onSelected(context, ref, file);
  }
}
