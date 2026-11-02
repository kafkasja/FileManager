import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/updates/domain/release_info.dart';
import 'package:kfm/features/updates/ui/open_release_page.dart';

/// X7 "What's new": the release title, date and notes as plain selectable
/// text (no Markdown rendering).
Future<void> showWhatsNewSheet(BuildContext context, ReleaseInfo release) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => WhatsNewSheet(release: release),
    );

class WhatsNewSheet extends ConsumerWidget {
  const new({required this.release, super.key});

  final ReleaseInfo release;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final title = release.title.isEmpty
        ? l10n.updatesAvailable('${release.version}')
        : release.title;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: EdgeInsetsDirectional.fromSTEB(
          spacing * 2,
          0,
          spacing * 2,
          spacing * 2,
        ),
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          Text(
            DateFormat.yMMMd(locale).format(release.publishedAt.toLocal()),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: spacing * 2),
          SelectableText(
            release.notes.isEmpty ? l10n.updatesNoNotes : release.notes,
            key: const ValueKey('whats-new-notes'),
          ),
          SizedBox(height: spacing * 2),
          FilledButton.icon(
            onPressed: () => unawaited(openReleasePage(context, ref, release)),
            icon: const Icon(Icons.open_in_browser),
            label: Text(l10n.updatesDownload),
          ),
        ],
      ),
    );
  }
}
