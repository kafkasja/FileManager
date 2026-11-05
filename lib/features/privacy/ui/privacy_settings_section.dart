import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/privacy/data/privacy_providers.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';
import 'package:kfm/features/smart_groups/data/smart_groups_providers.dart';

/// Settings → Privacy & access (TASK-X2, E2): location removal plus, while
/// KFM can't read photo locations, the access row (also used by Groups).
final stripLocationEntry = SettingsEntry(
  id: 'privacy.location',
  titleBuilder: (c) => c.l10n.privacyStripLocation,
  subtitleBuilder: (c) => c.l10n.privacyStripLocationHelp,
  keywordsBuilder: (c) => c.l10n.settingsKeywordsLocation,
  builder: (_) => const PrivacySettingsSection(),
);

/// Settings → Privacy (TASK-X2): "Remove location when sharing" (off by
/// default), and while KFM can't read photo locations a note plus the row
/// that asks for access (C5's `ACCESS_MEDIA_LOCATION` state).
class PrivacySettingsSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final strip = ref.watch(privacyStripLocationProvider).value ?? false;
    final readable = ref.watch(mediaLocationAccessProvider).value;
    return Column(
      children: [
        SwitchListTile(
          key: const ValueKey('privacy-strip-location'),
          secondary: const Icon(Icons.location_off_outlined),
          title: Text(l10n.privacyStripLocation),
          subtitle: Text(l10n.privacyStripLocationHelp),
          value: strip,
          onChanged: (v) => ref
              .read(settingsRepositoryProvider)
              .write(AppSettings.privacyStripLocation, v)
              .fireAndForget(),
        ),
        if (readable == false)
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(l10n.privacyAllowAccess),
            subtitle: Text(
              strip ? l10n.privacyNoOriginalNote : l10n.privacyAllowAccessHelp,
            ),
            onTap: () => unawaited(
              ref.read(mediaLocationAccessProvider.notifier).request(),
            ),
          ),
      ],
    );
  }
}
