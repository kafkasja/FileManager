import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/swipe/domain/swipe_deck_state.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_source_launcher.dart';

/// The slim bar under the app bar while a swipe source is open (TASK-SS1):
/// origin icon, title, group position, close ×.
class SwipeSourceBar extends ConsumerWidget {
  const new({required this.deck, super.key});

  final SwipeDeckState deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = deck.source;
    if (source == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final scheme = Theme.of(context).colorScheme;
    final group = deck.groupPosition;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: spacing * 2),
        child: Row(
          children: [
            Icon(
              swipeSourceOriginIcon(source.origin),
              size: 20,
              color: scheme.onSecondaryContainer,
            ),
            SizedBox(width: spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    source.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: scheme.onSecondaryContainer),
                  ),
                  if (group != null)
                    Text(
                      l10n.swipeSourceGroupPosition(
                        group.group,
                        group.groupCount,
                        group.index,
                        group.groupSize,
                      ),
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: scheme.onSecondaryContainer),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.swipeSourceClose,
              icon: const Icon(Icons.close),
              color: scheme.onSecondaryContainer,
              onPressed: () => unawaited(
                ref
                    .read(SwipeDeckScope.providerOf(context).notifier)
                    .closeSource(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "All done in {title}" with Back to swiping / Back to {origin}.
class SwipeSourceFinished extends ConsumerWidget {
  const new({required this.deck, super.key});

  final SwipeDeckState deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = deck.source!;
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final route = source.returnRoute;
    final controller = ref.read(SwipeDeckScope.providerOf(context).notifier);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.all(spacing * 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: spacing * 2),
            Text(
              l10n.swipeSourceDone(source.title),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing * 2),
            FilledButton(
              onPressed: () => unawaited(controller.closeSource()),
              child: Text(l10n.swipeSourceBackToMain),
            ),
            if (route != null) ...[
              SizedBox(height: spacing),
              OutlinedButton(
                onPressed: () async {
                  final router = GoRouter.of(context);
                  await controller.closeSource();
                  router.go(route);
                },
                child: Text(
                  l10n.swipeSourceBackToOrigin(
                    swipeSourceOriginLabel(l10n, source.origin),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
