import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/cloud/data/cloud_providers.dart';
import 'package:kfm/features/cloud/ui/cloud_badge_cache.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';
import 'package:kfm/features/swipe/ui/swipe_source_launcher.dart';

/// Settings → Cloud (TASK-X3): one row to the destinations screen. Reads
/// the DB only, never the cloud channel. X4: once KFM uploaded something,
/// the "Show cloud icon" switch with its help text and "Swipe files already
/// on cloud".
class CloudSettingsSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final count = ref.watch(activeCloudDestinationsProvider).value?.length ?? 0;
    final hasUploads = ref.watch(cloudHasUploadsProvider).value ?? false;
    final destinations = ListTile(
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
    if (!hasUploads) return destinations;
    final show = ref.watch(cloudShowBadgeProvider).value ?? true;
    return Column(
      children: [
        destinations,
        SwitchListTile(
          key: const ValueKey('settings-cloud-show-badge'),
          secondary: const Icon(Icons.cloud_done_outlined),
          title: Text(l10n.cloudShowBadge),
          subtitle: Text(l10n.cloudBadgeHelp),
          isThreeLine: true,
          value: show,
          onChanged: (v) => ref
              .read(settingsRepositoryProvider)
              .write(AppSettings.cloudShowBadge, v)
              .fireAndForget(),
        ),
        ListTile(
          key: const ValueKey('settings-cloud-swipe'),
          leading: const Icon(Icons.swipe_outlined),
          title: Text(l10n.cloudSwipeOnCloud),
          onTap: () => unawaited(_swipeOnCloud(context, ref)),
        ),
      ],
    );
  }

  Future<void> _swipeOnCloud(BuildContext context, WidgetRef ref) async {
    final SwipeSourceOpenResult r;
    try {
      r = await ref
          .read(swipeSourceLauncherProvider.notifier)
          .open(
            FilterSourceRequest(
              origin: SwipeSourceOrigin.cloud,
              title: context.l10n.cloudSwipeOnCloudTitle,
              filter: const FileFilter(cloud: CloudFilterMode.onCloud),
              returnRoute: AppRoutes.settings,
            ),
          );
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.swipeErrorGeneric)));
      }
      return;
    }
    if (!context.mounted) return;
    if (r is SwipeSourceOpened) context.go(AppRoutes.swipe);
    showSwipeSourceResult(context, r);
  }
}
