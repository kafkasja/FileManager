import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/selection/domain/selection_state.dart';
import 'package:kfm/features/selection/ui/selection_actions.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';

/// The bottom selection bar (TASK-B6): "240 selected · 3.1 GB", the
/// registered actions and the overflow. Visible whenever something is
/// selected or a select mode is on, so the user always sees a selection
/// exists.
class SelectionBar extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(selectionControllerProvider).value;
    if (s == null || (s.isEmpty && s.mode == SelectionMode.normal)) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final controller = ref.read(selectionControllerProvider.notifier);
    final actions = [
      for (final a in ref.watch(selectionActionsProvider))
        if (!s.isEmpty && a.isAvailable(s)) a,
    ]..sort((a, b) => a.order.compareTo(b.order));
    final primary = [
      for (final a in actions)
        if (a.primary) a,
    ];
    final more = [
      for (final a in actions)
        if (!a.primary) a,
    ];

    Future<void> run(SelectionAction a) async {
      final ids = await controller.orderedIds();
      if (!context.mounted) return;
      await a.run(context, ref, ids);
    }

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: spacing * 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.selectionCount(
                    s.count,
                    formatBytes(
                      s.totalBytes,
                      locale: Localizations.localeOf(context).toLanguageTag(),
                    ),
                  ),
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              for (final a in primary)
                IconButton(
                  tooltip: a.label(context),
                  icon: Icon(a.icon),
                  onPressed: () => unawaited(run(a)),
                ),
              if (s.mode == SelectionMode.edit)
                TextButton(
                  onPressed: controller.exitEdit,
                  child: Text(l10n.selectionDone),
                ),
              PopupMenuButton<VoidCallback>(
                tooltip: l10n.selectionMore,
                onSelected: (action) => action(),
                itemBuilder: (context) => [
                  for (final a in more)
                    PopupMenuItem(
                      value: () => unawaited(run(a)),
                      child: ListTile(
                        leading: Icon(a.icon),
                        title: Text(a.label(context)),
                      ),
                    ),
                  if (!s.isEmpty && s.mode != SelectionMode.edit)
                    PopupMenuItem(
                      value: controller.enterEdit,
                      child: Text(l10n.selectionEditTitle),
                    ),
                  if (!s.isEmpty)
                    PopupMenuItem(
                      value: () => unawaited(clearSelection(context, ref)),
                      child: Text(l10n.selectionClearAll),
                    ),
                  if (!s.isEmpty)
                    PopupMenuItem(
                      value: () =>
                          unawaited(context.push(AppRoutes.browseSelected)),
                      child: Text(l10n.selectionView),
                    ),
                  if (s.canRestoreCleared)
                    PopupMenuItem(
                      value: () => unawaited(controller.restoreCleared()),
                      child: Text(l10n.selectionRestore),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clear all + the 10 s Undo snackbar (no confirmation: Undo makes it
/// safe).
Future<void> clearSelection(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(selectionControllerProvider.notifier);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final cleared = await controller.clearAll();
  if (cleared == 0) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n.selectionCleared(cleared)),
        duration: const Duration(seconds: 10),
        persist: false,
        action: SnackBarAction(
          label: l10n.undoAction,
          onPressed: () => unawaited(controller.restoreCleared()),
        ),
      ),
    );
}

/// Select / Edit selection header hint.
class SelectionHint extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(
      selectionControllerProvider.select((s) => s.value?.mode),
    );
    final l10n = context.l10n;
    final text = switch (mode) {
      SelectionMode.select => l10n.selectionHint,
      SelectionMode.edit => l10n.selectionEditHint,
      _ => null,
    };
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: context.tokens.spacing * 2,
        vertical: context.tokens.spacing / 2,
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
