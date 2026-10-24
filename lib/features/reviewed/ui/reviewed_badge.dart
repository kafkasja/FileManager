import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';

/// P7: small "Reviewed" pill on a swipe card. Never takes a gesture.
class ReviewedBadge extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          color: colors.surface.withValues(alpha: 0.7),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 8,
            vertical: 3,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 14, color: colors.primary),
              const SizedBox(width: 4),
              Text(
                context.l10n.reviewedBadge,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
