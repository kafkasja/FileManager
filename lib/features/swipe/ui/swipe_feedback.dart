import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/swipe/domain/action_label.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/domain/swipe_deck_state.dart';
import 'package:kfm/features/swipe/ui/swipe_action_bar.dart'
    show swipeActionIcon;
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_settings_section.dart'
    show hapticsEnabledProvider;
import 'package:kfm/features/swipe/ui/swipe_toast.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';

/// S4 feedback for a swipe, wherever it happens: the deck (S1) or the
/// fullscreen viewer (S3). One place, so both always feel the same (H3).
abstract final class SwipeFeedback {
  /// Colour, icon and label while the card is past the threshold.
  static SwipeHint? hintFor(
    BuildContext context,
    WidgetRef ref,
    SwipeDeckState deck,
    SwipeDirection d,
  ) {
    final action = deck.session.layout.actionFor(d);
    if (action == null) return null;
    final tokens = context.tokens;
    return (
      color: switch (action.type) {
        SwipeActionType.trash => tokens.swipeTrash,
        SwipeActionType.keep => tokens.swipeKeep,
        _ => tokens.swipeOther,
      },
      icon: swipeActionIcon(action.type),
      label: _label(context, ref, deck, action),
    );
  }

  /// Can [d] run right now (mapped and no P2 problem)?
  static bool canSwipe(WidgetRef ref, SwipeDeckState deck, SwipeDirection d) =>
      deck.session.layout.actionFor(d) != null &&
      ref.read(swipeDeckControllerProvider.notifier).problemFor(d) == null;

  /// Threshold crossed: a light tick (if vibration is on).
  static void tick(WidgetRef ref) {
    if (ref.read(hapticsEnabledProvider).value ?? true) {
      HapticFeedback.selectionClick().ignore();
    }
  }

  /// A swipe or an action bar tap (P4): apply it on the shared deck, then
  /// vibrate, show the label and announce it. False when nothing happened.
  static bool apply(
    BuildContext context,
    WidgetRef ref,
    SwipeDeckState deck,
    SwipeToastController toast,
    SwipeAction action,
  ) {
    final done = ref.read(swipeDeckControllerProvider.notifier).apply(action);
    if (!done) return false;
    if (ref.read(hapticsEnabledProvider).value ?? true) {
      HapticFeedback.lightImpact().ignore();
    }
    final label = _label(context, ref, deck, action);
    toast.show(label);
    SemanticsService.sendAnnouncement(
      View.of(context),
      label,
      Directionality.of(context),
    ).ignore();
    return true;
  }

  /// P2: released on a direction whose action can't run right now.
  static void blocked(BuildContext context, WidgetRef ref, SwipeDirection d) {
    final problem = ref
        .read(swipeDeckControllerProvider.notifier)
        .problemFor(d);
    if (problem != null) explain(context, problem); // unmapped: nothing to say
  }

  static void explain(BuildContext context, SwipeActionProblem problem) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (problem) {
          SwipeActionProblem.tagMissing => l10n.swipeProblemTagMissing,
          SwipeActionProblem.unsupported => l10n.swipeProblemUnsupported,
        }),
      ),
    );
  }

  static String _label(
    BuildContext context,
    WidgetRef ref,
    SwipeDeckState deck,
    SwipeAction action,
  ) => actionLabel(
    context.l10n,
    action,
    deleteMode: deck.session.deleteMode,
    tagName: ref.read(tagsByIdProvider).value?[action.tagId]?.name,
  );
}
