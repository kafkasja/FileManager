import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/smart_groups/data/smart_groups_providers.dart';

/// Settings → Groups (TASK-C5): online place names (off by default) and
/// the location-access row while it isn't granted.
class SmartGroupsSettingsSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final online =
        ref.watch(smartGroupsOnlinePlaceNamesProvider).value ?? false;
    final location = ref.watch(mediaLocationAccessProvider).value;
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.travel_explore_outlined),
          title: Text(l10n.groupsOnlineNames),
          subtitle: Text(l10n.groupsOnlineNamesHelp),
          value: online,
          onChanged: (v) => ref
              .read(settingsRepositoryProvider)
              .write(AppSettings.smartGroupsOnlinePlaceNames, v)
              .fireAndForget(),
        ),
        if (location == false)
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(l10n.groupsLocationRow),
            onTap: () => unawaited(
              ref.read(mediaLocationAccessProvider.notifier).request(),
            ),
          ),
      ],
    );
  }
}
