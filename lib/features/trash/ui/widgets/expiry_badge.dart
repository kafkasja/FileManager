import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';

/// Calendar days until the expiry date (local time); 0 = expires today or
/// already expired. A 7-day item reads "7 days left" right after trashing
/// (V1: rounding down showed 6, and a fresh 1-day item "Expires today").
int daysLeft(DateTime expiresAt, DateTime now) {
  final e = expiresAt.toLocal();
  final n = now.toLocal();
  final days =
      (DateTime(
                e.year,
                e.month,
                e.day,
              ).difference(DateTime(n.year, n.month, n.day)).inHours /
              24)
          .round(); // DST days are 23 or 25 hours long
  return days < 0 ? 0 : days;
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
