import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/swipe/domain/action_label.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_layout_controller.dart';
import 'package:kfm/features/trash/data/trash_providers.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Settings → Swiping → Customize swipes (TASK-P1): one action per
/// direction. Directions are physical, never mirrored for RTL.
class CustomizeSwipesScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final layout = ref.watch(swipeLayoutControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.customizeSwipes)),
      body: switch (layout) {
        AsyncData(:final value) => _Body(layout: value),
        AsyncError(:final error) => Center(child: Text(error.toString())),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const new({required this.layout});

  final SwipeLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final colors = Theme.of(context).colorScheme;
    Widget tile(SwipeDirection d) => _DirectionTile(
      direction: d,
      action: layout.actionFor(d),
      onTap: () => _pick(context, ref, d),
    );

    return ListView(
      padding: EdgeInsetsDirectional.all(spacing * 2),
      children: [
        Text(l10n.customizeSwipesIntro),
        SizedBox(height: spacing * 2),
        Center(child: SizedBox(width: 180, child: tile(SwipeDirection.up))),
        SizedBox(height: spacing),
        Row(
          // Physical directions: left stays left in RTL languages too.
          textDirection: TextDirection.ltr,
          children: [
            Expanded(child: tile(SwipeDirection.left)),
            SizedBox(width: spacing),
            Container(
              width: 88,
              height: 120,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.photo_outlined, color: colors.outline),
            ),
            SizedBox(width: spacing),
            Expanded(child: tile(SwipeDirection.right)),
          ],
        ),
        SizedBox(height: spacing),
        Center(child: SizedBox(width: 180, child: tile(SwipeDirection.down))),
        SizedBox(height: spacing * 3),
        if (layout != SwipeLayout.basic)
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: Text(l10n.swipeLayoutReset),
              onPressed: () => _confirmReset(context, ref),
            ),
          ),
      ],
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    SwipeDirection direction,
  ) async {
    final current = layout.actionFor(direction);
    // The last mapped direction can't become "nothing": the deck would be
    // stuck with no way to swipe.
    final isLastAction = current != null && layout.directions.length == 1;
    final choice = await showModalBottomSheet<_Choice>(
      context: context,
      showDragHandle: true,
      builder: (context) => _ActionPicker(
        direction: direction,
        current: current,
        canPickNothing: !isLastAction,
      ),
    );
    if (choice == null || choice.action == current) return;
    await ref
        .read(swipeLayoutControllerProvider.notifier)
        .setDirection(direction, choice.action);
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.swipeLayoutResetTitle),
        content: Text(l10n.swipeLayoutResetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(swipeLayoutControllerProvider.notifier).resetToBasic();
    }
  }
}

/// The picked option; `action` null = nothing.
typedef _Choice = ({SwipeAction? action});

class _DirectionTile extends ConsumerWidget {
  const new({
    required this.direction,
    required this.action,
    required this.onTap,
  });

  final SwipeDirection direction;
  final SwipeAction? action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final name = swipeActionName(l10n, action, ref.watch(_deleteModeProvider));
    final directionName = swipeDirectionName(l10n, direction);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: true,
          label: '$directionName: $name',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Icon(_arrow(direction), color: colors.primary),
                const SizedBox(height: 4),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: action == null ? colors.onSurfaceVariant : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _arrow(SwipeDirection d) => switch (d) {
    SwipeDirection.left => Icons.arrow_back,
    SwipeDirection.right => Icons.arrow_forward,
    SwipeDirection.up => Icons.arrow_upward,
    SwipeDirection.down => Icons.arrow_downward,
  };
}

class _ActionPicker extends ConsumerWidget {
  const new({
    required this.direction,
    required this.current,
    required this.canPickNothing,
  });

  final SwipeDirection direction;
  final SwipeAction? current;
  final bool canPickNothing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(_deleteModeProvider);
    Widget option(SwipeAction? action, {bool enabled = true, String? help}) =>
        ListTile(
          enabled: enabled,
          selected: action == current,
          title: Text(swipeActionName(l10n, action, mode)),
          subtitle: help == null ? null : Text(help),
          trailing: action == current ? const Icon(Icons.check) : null,
          onTap: () => Navigator.of(context).pop<_Choice>((action: action)),
        );
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: Text(
              swipeDirectionName(l10n, direction),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final a in assignableSwipeActions) option(a),
          option(
            null,
            enabled: canPickNothing,
            help: canPickNothing ? null : l10n.swipeActionNeedOne,
          ),
        ],
      ),
    );
  }
}

/// The saved delete mode, so "trash" reads "Delete permanently" when that
/// is what it will do.
final Provider<DeleteMode> _deleteModeProvider =
    Provider.autoDispose<DeleteMode>(
      (ref) => ref.watch(deleteModeSettingProvider).value ?? DeleteMode.trash,
    );

String swipeDirectionName(AppLocalizations l, SwipeDirection d) => switch (d) {
  SwipeDirection.left => l.swipeDirectionLeft,
  SwipeDirection.right => l.swipeDirectionRight,
  SwipeDirection.up => l.swipeDirectionUp,
  SwipeDirection.down => l.swipeDirectionDown,
};

/// What a direction does, as a name ("Move to trash"), not a result label.
String swipeActionName(AppLocalizations l, SwipeAction? a, DeleteMode mode) =>
    switch (a?.type) {
      null => l.swipeActionNothing,
      SwipeActionType.trash =>
        mode == DeleteMode.permanent ? l.swipeActionDelete : l.swipeActionTrash,
      SwipeActionType.keep => l.swipeActionKeep,
      // P2 gives its types proper names; until then reuse the result label.
      _ => actionLabel(l, a!, deleteMode: mode),
    };
