import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/utils/read_future.dart';
import 'package:kfm/features/rename/data/rename_providers.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/session/domain/clear_session.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

/// SE3 "Clear…": nothing pre-checked; options with nothing to clear are
/// hidden; the new-session row says how many deletes it will do.
Future<void> showClearSheet(BuildContext context, WidgetRef ref) async {
  final deck = await ref.readFuture(swipeDeckControllerProvider.future);
  final summary = await ref.readFuture(
    pendingDeleteSummaryProvider(deck.session.id).future,
  );
  final renameCount = await ref.readFuture(
    renameBatchCountProvider(deck.session.id).future,
  );
  final selected = (await ref.readFuture(selectionControllerProvider.future))
      .count;
  if (!context.mounted) return;
  final request = await showModalBottomSheet<ClearRequest>(
    context: context,
    showDragHandle: true,
    builder: (_) => _ClearSheet(
      canResetLayout: deck.session.layout != SwipeLayout.basic,
      waitingDeletes: summary.queued + summary.failed,
      renameCount: renameCount,
      selectedCount: selected,
    ),
  );
  if (request == null || request.isEmpty) return;
  final controller = ref.read(swipeDeckControllerProvider.notifier);
  final result = await controller.clear(request);
  if (!context.mounted) return;
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  if (request.newSession && !result.sessionEnded) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.newSessionFailed)));
    return;
  }
  if (result.selectionCleared > 0) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.selectionCleared(result.selectionCleared)),
        duration: const Duration(seconds: 10),
        persist: false,
        action: SnackBarAction(
          label: l10n.undoAction,
          onPressed: () => ref
              .read(selectionControllerProvider.notifier)
              .restoreCleared()
              .ignore(),
        ),
      ),
    );
  }
  final before = result.layoutBefore;
  if (before != null) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.layoutResetDone),
        duration: const Duration(seconds: 8),
        // Actions make a SnackBar persistent by default; these time out.
        persist: false,
        action: SnackBarAction(
          label: l10n.undoAction,
          onPressed: () => controller.undoLayoutReset(before).ignore(),
        ),
      ),
    );
  }
}

class _ClearSheet extends StatefulWidget {
  const new({
    required this.canResetLayout,
    required this.waitingDeletes,
    this.renameCount = 0,
    this.selectedCount = 0,
  });

  final bool canResetLayout;
  final int waitingDeletes;

  /// P3: files in the rename batch that a new session drops.
  final int renameCount;

  /// B6: files in the selection (row hidden when 0).
  final int selectedCount;

  @override
  State<_ClearSheet> createState() => _ClearSheetState();
}

class _ClearSheetState extends State<_ClearSheet> {
  bool _resetLayout = false;
  bool _newSession = false;
  bool _clearSelection = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final request = ClearRequest(
      resetLayout: _resetLayout,
      newSession: _newSession,
      clearSelection: _clearSelection,
    );
    // Scrolls on short screens (small phones in landscape, big text).
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text(
                l10n.clearMenu,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (widget.canResetLayout)
              CheckboxListTile(
                value: _resetLayout,
                onChanged: (v) => setState(() => _resetLayout = v ?? false),
                title: Text(l10n.clearResetLayout),
                subtitle: Text(l10n.clearResetLayoutHelp),
              ),
            CheckboxListTile(
              value: _newSession,
              onChanged: (v) => setState(() => _newSession = v ?? false),
              title: Text(l10n.clearNewSession),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.clearNewSessionHelp),
                  Text(l10n.clearNewSessionDeletes(widget.waitingDeletes)),
                  if (widget.renameCount > 0)
                    Text(l10n.clearRenameDropped(widget.renameCount)),
                ],
              ),
              isThreeLine: true,
            ),
            if (widget.selectedCount > 0)
              CheckboxListTile(
                value: _clearSelection,
                onChanged: (v) => setState(() => _clearSelection = v ?? false),
                title: Text(l10n.clearSelectionRow(widget.selectedCount)),
              ),
            Padding(
              padding: EdgeInsetsDirectional.all(spacing * 2),
              // Wraps the buttons when they don't fit side by side.
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: spacing,
                overflowAlignment: OverflowBarAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: request.isEmpty
                        ? null
                        : () => Navigator.pop(context, request),
                    child: Text(l10n.clearConfirm),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
