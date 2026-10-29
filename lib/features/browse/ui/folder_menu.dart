import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'folder_menu.g.dart';

/// One entry of a folder row's ⋮ menu in Browse's folder mode. B1 ships
/// none (the ⋮ is hidden while empty); B5 adds "Compress", B4 may add more.
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
List<FolderMenuItem> folderMenuItems(Ref ref) => const [];
