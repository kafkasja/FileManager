import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/updates/data/update_checker.dart';
import 'package:kfm/features/updates/domain/update_status.dart';
import 'package:kfm/features/updates/ui/open_release_page.dart';
import 'package:kfm/features/updates/ui/whats_new_sheet.dart';

/// X7: "KFM X is available · What's new · Download · ×". Only for a newer
/// release the user hasn't closed; never on the Swipe tab (AppScaffold).
class UpdateBanner extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(updateCheckerProvider);
    final dismissed = ref.watch(updateDismissedVersionProvider).value;
    if (status is! UpdateAvailable || dismissed == null) {
      return const SizedBox.shrink();
    }
    final release = status.release;
    final version = '${release.version}';
    if (dismissed == version) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.tokens.spacing;
    return Material(
      key: const ValueKey('update-banner'),
      color: scheme.secondaryContainer,
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: spacing * 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.updatesAvailable(version),
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
            TextButton(
              onPressed: () => unawaited(showWhatsNewSheet(context, release)),
              child: Text(l10n.updatesWhatsNew),
            ),
            TextButton(
              key: const ValueKey('update-download'),
              onPressed: () =>
                  unawaited(openReleasePage(context, ref, release)),
              child: Text(l10n.updatesDownload),
            ),
            IconButton(
              key: const ValueKey('update-dismiss'),
              tooltip: l10n.updatesDismiss,
              icon: const Icon(Icons.close),
              onPressed: () => ref
                  .read(settingsRepositoryProvider)
                  .write(AppSettings.updateDismissedVersion, version)
                  .fireAndForget(),
            ),
          ],
        ),
      ),
    );
  }
}
