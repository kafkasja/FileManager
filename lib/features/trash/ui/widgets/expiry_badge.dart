import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';

/// Whole days left, rounded down; 0 = expires today.
int daysLeft(DateTime expiresAt, DateTime now) {
  final left = expiresAt.difference(now);
  return left.isNegative ? 0 : left.inDays;
}

/// "N days left" / "Expires today".
class ExpiryBadge extends StatelessWidget {
  const new({required this.expiresAt, this.now, super.key});

  final DateTime expiresAt;

  /// For tests; defaults to the current time.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final days = daysLeft(expiresAt, now ?? DateTime.now());
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        days == 0 ? l10n.trashExpiresToday : l10n.trashDaysLeft(days),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
