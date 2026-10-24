import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/stats/data/stats_repository.dart';

/// P8: what the session just did, after Done.
Future<void> showSessionSummary(BuildContext context, SessionStats s) {
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).toLanguageTag();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final spacing = context.tokens.spacing;
      Widget line(IconData icon, String text) =>
          ListTile(leading: Icon(icon), title: Text(text));
      return SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            spacing * 2,
            0,
            spacing * 2,
            spacing * 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.summaryTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              line(
                Icons.check_circle_outline,
                l10n.summaryReviewed(s.reviewed),
              ),
              if (s.toTrashBytes > 0)
                line(
                  Icons.delete_outline,
                  l10n.summaryToTrash(
                    formatBytes(s.toTrashBytes, locale: locale),
                  ),
                ),
              if (s.freedBytes > 0)
                line(
                  Icons.cleaning_services_outlined,
                  l10n.summaryFreed(formatBytes(s.freedBytes, locale: locale)),
                ),
              SizedBox(height: spacing),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.ok),
              ),
            ],
          ),
        ),
      );
    },
  );
}
