import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/rename/data/rename_providers.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/session/domain/clear_session.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

/// SE3 "Clear…": nothing pre-checked; options with nothing to clear are
/// hidden; the new-session row says how many deletes it will do.
Future<void> showClearSheet(BuildContext context, WidgetRef ref) async {
  final deck = await ref.read(swipeDeckControllerProvider.future);
  final summary = await ref.read(
    pendingDeleteSummaryProvider(deck.session.id).future,
  );
  final renameCount = await ref.read(
    renameBatchCountProvider(deck.session.id).future,
  );
  if (!context.mounted) return;
  final request = await showModalBottomSheet<ClearRequest>(
    context: context,
    showDragHandle: true,
    builder: (_) => _ClearSheet(
      canResetLayout: deck.session.layout != SwipeLayout.basic,
      waitingDeletes: summary.queued + summary.failed,
      renameCount: renameCount,
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
  });

  final bool canResetLayout;
  final int waitingDeletes;

  /// P3: files in the rename batch that a new session drops.
  final int renameCount;

  @override
  State<_ClearSheet> createState() => _ClearSheetState();
}

class _ClearSheetState extends State<_ClearSheet> {
  bool _resetLayout = false;
  bool _newSession = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final request = ClearRequest(
      resetLayout: _resetLayout,
      newSession: _newSession,
    );
    return SafeArea(
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
          Padding(
            padding: EdgeInsetsDirectional.all(spacing * 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                SizedBox(width: spacing),
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
    );
  }
}
