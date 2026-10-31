import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:kfm/features/archive/ui/archive_actions.dart';
import 'package:kfm/features/folders/ui/file_op_flow.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'folder_menu.g.dart';

/// One entry of a folder row's ⋮ menu in Browse's folder mode (the ⋮ is
/// hidden while none is available). B4: Rename; B5 adds "Compress".
@immutable
class FolderMenuItem {
  const new({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.isAvailable = _always,
  });

  final String Function(BuildContext context) label;
  final IconData icon;
  final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    FolderEntry folder,
  )
  onSelected;
  final bool Function(FolderEntry folder) isAvailable;

  static bool _always(FolderEntry _) => true;
}

@riverpod
List<FolderMenuItem> folderMenuItems(Ref ref) => [
  FolderMenuItem(
    label: (c) => c.l10n.renameAction,
    icon: Icons.drive_file_rename_outline,
    onSelected: renameFolderFlow,
    // Not a volume (storage list).
    isAvailable: (f) => f.path != volumeRootOf(f.path),
  ),
  compressFolderMenuItem,
];
