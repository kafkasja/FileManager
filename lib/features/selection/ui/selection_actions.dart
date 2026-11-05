import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/features/archive/ui/archive_actions.dart';
import 'package:kfm/features/connect/ui/link_providers.dart';
import 'package:kfm/features/details/ui/selection_summary_sheet.dart';
import 'package:kfm/features/folders/ui/folder_selection_actions.dart';
import 'package:kfm/features/privacy/ui/share_flow.dart';
import 'package:kfm/features/selection/domain/selection_state.dart';
import 'package:kfm/features/swipe/ui/swipe_these.dart';
import 'package:kfm/features/tags/ui/tag_actions.dart';
import 'package:kfm/features/transfers/ui/link_send.dart';
import 'package:kfm/features/transfers/ui/transfer_flows.dart';
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
/// delete, copy, duplicate; B5: compress; B9: favorites and tags; X2:
/// share; B10: details.
@Riverpod(keepAlive: true)
List<SelectionAction> selectionActions(Ref ref) => List.unmodifiable(
  <SelectionAction>[
    // E1: one tap to the linked device, first.
    if (ref.watch(currentLinkProvider) case final link?)
      sendToLinkSelectionAction(link),
    ...folderSelectionActions,
    compressSelectionAction,
    ...tagSelectionActions,
    swipeSelectionAction,
    // N9: upload to the connected device.
    sendToDeviceSelectionAction,
    // N11: move to the connected device (verified, then deleted here).
    moveToDeviceSelectionAction,
    // X2: Android share sheet (optionally without location).
    shareSelectionAction,
    detailsSelectionAction,
  ]..sort((a, b) => a.order.compareTo(b.order)),
);
