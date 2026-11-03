import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/features/cloud/data/cloud_providers.dart';

/// Settings → Cloud (TASK-X3; X4 adds its badge toggle here): one row to
/// the destinations screen. Reads the DB only, never the cloud channel.
class CloudSettingsSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final count = ref.watch(activeCloudDestinationsProvider).value?.length ?? 0;
    return ListTile(
      key: const ValueKey('settings-cloud-destinations'),
      leading: const Icon(Icons.cloud_outlined),
      title: Text(l10n.cloudDestinations),
      subtitle: Text(
        count == 0
            ? l10n.cloudDestinationsNone
            : l10n.cloudDestinationsCount(count),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => unawaited(context.push(AppRoutes.cloudSettings)),
    );
  }
}
