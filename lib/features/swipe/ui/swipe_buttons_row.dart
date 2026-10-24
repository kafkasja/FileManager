import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/swipe/domain/action_label.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/tags/domain/tag.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

/// Button order (physical, never mirrored for RTL).
const List<SwipeDirection> swipeButtonOrder = [
  SwipeDirection.left,
  SwipeDirection.down,
  SwipeDirection.up,
  SwipeDirection.right,
];

IconData swipeDirectionIcon(SwipeDirection d) => switch (d) {
  SwipeDirection.left => Icons.arrow_back,
  SwipeDirection.right => Icons.arrow_forward,
  SwipeDirection.up => Icons.arrow_upward,
  SwipeDirection.down => Icons.arrow_downward,
};

/// P9: one button per mapped direction; a tap flies the card out exactly
/// like a swipe (same undo row, label, vibration).
class SwipeButtonsRow extends StatelessWidget {
  const new({
    required this.layout,
    required this.deleteMode,
    required this.controller,
    this.tags = const {},
    super.key,
  });

  final SwipeLayout layout;
  final DeleteMode deleteMode;
  final SwipeCardController controller;
  final Map<int, Tag> tags;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gap = context.tokens.spacing;
    final entries = [
      for (final d in swipeButtonOrder)
        if (layout.actionFor(d) case final a?) (d, a),
    ];
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: gap * 1.5),
      // Equal-height buttons even when one label wraps.
      child: IntrinsicHeight(
        child: Row(
          // Physical directions: left stays left in RTL too.
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (dir, action) in entries)
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.all(gap / 2),
                  child: _DirectionButton(
                    icon: swipeDirectionIcon(dir),
                    label: swipeActionName(
                      l10n,
                      action,
                      deleteMode,
                      tags: tags,
                    ),
                    semantics: l10n.swipeButtonSemantics(
                      swipeActionName(l10n, action, deleteMode, tags: tags),
                      swipeDirectionName(l10n, dir),
                    ),
                    onPressed: () => controller.flyOff(dir),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.semantics,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String semantics;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semantics,
    excludeSemantics: true,
    child: FilledButton.tonal(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}
