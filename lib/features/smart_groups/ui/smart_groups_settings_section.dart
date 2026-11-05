import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';
import 'package:kfm/features/smart_groups/data/smart_groups_providers.dart';

/// Settings → Smart features (TASK-C5, E2): online place names (off by
/// default). Phones only: Windows has no geocoder. The location-access
/// row lives in Privacy & access.
final placeNamesEntry = SettingsEntry(
  id: 'smart.placeNames',
  titleBuilder: (c) => c.l10n.groupsOnlineNames,
  subtitleBuilder: (c) => c.l10n.groupsOnlineNamesHelp,
  formFactors: const {FormFactor.mobile},
  builder: (_) => const SmartGroupsSettingsSection(),
);

class SmartGroupsSettingsSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final online =
        ref.watch(smartGroupsOnlinePlaceNamesProvider).value ?? false;
    return SwitchListTile(
      secondary: const Icon(Icons.travel_explore_outlined),
      title: Text(l10n.groupsOnlineNames),
      subtitle: Text(l10n.groupsOnlineNamesHelp),
      value: online,
      onChanged: (v) => ref
          .read(settingsRepositoryProvider)
          .write(AppSettings.smartGroupsOnlinePlaceNames, v)
          .fireAndForget(),
    );
  }
}
