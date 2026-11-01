import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/features/archive/ui/archive_actions.dart';
import 'package:kfm/features/folders/ui/folder_selection_actions.dart';
import 'package:kfm/features/selection/domain/selection_state.dart';
import 'package:kfm/features/tags/ui/tag_actions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selection_actions.g.dart';

/// One thing the selection bar can do with the selection (TASK-B6). B4
/// (move/copy/delete/rename/duplicate), B5 (compress) and B9 (tag/favorite)
/// each register one in [selectionActions]; nobody edits the bar.
@immutable
class SelectionAction {
  const new({
    required this.id,
    required this.label,
    required this.icon,
    required this.run,
    this.primary = false,
    this.order = 0,
    this.isAvailable = _always,
  });

  final String id;
  final String Function(BuildContext context) label;
  final IconData icon;

  /// A bar button; otherwise under "More".
  final bool primary;

  /// Lower first.
  final int order;
  final bool Function(SelectionState state) isAvailable;

  /// `ids` in selection order. Never clears the selection.
  final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    List<String> ids,
  )
  run;

  static bool _always(SelectionState _) => true;
}

/// Sorted by [SelectionAction.order] (the bar sorts too). B4: move,
/// delete, copy, duplicate; B5: compress; B9: favorites and tags.
@Riverpod(keepAlive: true)
List<SelectionAction> selectionActions(Ref ref) => List.unmodifiable(
  <SelectionAction>[
    ...folderSelectionActions,
    compressSelectionAction,
    ...tagSelectionActions,
  ]..sort((a, b) => a.order.compareTo(b.order)),
);
