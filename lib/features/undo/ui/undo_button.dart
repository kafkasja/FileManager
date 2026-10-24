import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/action_label.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/undo/domain/undo_service.dart';

/// Always visible on the swipe screen; disabled when there is nothing to
/// undo. Long-press shows the last 5 actions (S2).
class UndoButton extends ConsumerWidget {
  const new({required this.sessionId, super.key});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(undoableCountProvider(sessionId)).value ?? 0;
    final enabled = count > 0;
    return GestureDetector(
      onLongPress: enabled ? () => _showHistory(context, ref) : null,
      child: IconButton.filledTonal(
        tooltip: context.l10n.undo,
        iconSize: 28,
        onPressed: enabled ? () => _undo(context, ref) : null,
        icon: const Icon(Icons.undo),
      ),
    );
  }

  static Future<void> _undo(BuildContext context, WidgetRef ref) async {
    final outcome = await ref.read(swipeDeckControllerProvider.notifier).undo();
    if (context.mounted) showUndoOutcome(context, outcome);
  }

  Future<void> _showHistory(BuildContext context, WidgetRef ref) async {
    final actions = await ref
        .read(undoRepositoryProvider)
        .stack(sessionId, limit: 5);
    final names = {
      for (final f in await ref.read(mediaIndexDaoProvider).byIds([
        for (final a in actions) a.fileId,
      ]))
        f.id: f.name,
    };
    if (!context.mounted || actions.isEmpty) return;
    final steps = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final l10n = context.l10n;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(l10n.undoHistoryTitle)),
              for (final (i, a) in actions.indexed)
                ListTile(
                  leading: const Icon(Icons.undo),
                  title: Text(actionLabel(l10n, a.action)),
                  subtitle: Text(names[a.fileId] ?? a.fileId),
                  onTap: () => Navigator.pop(context, i + 1),
                ),
            ],
          ),
        );
      },
    );
    if (steps == null) return;
    final controller = ref.read(swipeDeckControllerProvider.notifier);
    for (var i = 0; i < steps; i++) {
      final outcome = await controller.undo();
      if (context.mounted) showUndoOutcome(context, outcome);
      if (outcome is! Undone) break;
    }
  }
}

/// Snackbar for undo results that need words (a normal undo just shows the
/// file again).
void showUndoOutcome(BuildContext context, UndoOutcome outcome) {
  final l10n = context.l10n;
  final text = switch (outcome) {
    Undone(restoredFromTrash: true) => l10n.undoRestored,
    PermanentlyDeleted() => l10n.undoPermanentlyDeleted,
    UndoFailed(error: UnimplementedError()) => l10n.undoNotPossibleYet,
    UndoFailed() => l10n.undoFailed,
    Undone() || NothingToUndo() => null,
  };
  if (text == null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
