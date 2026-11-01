import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/background/in_app_jobs.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/tables/smart_groups_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/features/smart_groups/data/smart_groups_job.dart';
import 'package:kfm/features/smart_groups/data/smart_groups_providers.dart';
import 'package:kfm/features/smart_groups/data/smart_groups_repository.dart';
import 'package:kfm/features/smart_groups/ui/smart_group_titles.dart';

/// Smart groups (TASK-C5): Screenshots, Selfies, Documents (live queries),
/// Trips and Places (computed by `SmartGroupsJob`). Opening it the first
/// time turns the job on and asks for location access (never at start).
class GroupsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        activateSmartGroups(
          ref.read(settingsRepositoryProvider),
          ref.read(mediaLocationAccessProvider.notifier),
          ref.read(inAppJobRunnerProvider),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final progress =
        ref.watch(smartGroupsProgressProvider).value ??
        SmartGroupsProgress.idle;
    final location = ref.watch(mediaLocationAccessProvider).value;
    final trips =
        ref.watch(smartGroupListProvider(SmartGroupKind.trip)).value ??
        const <SmartGroupView>[];
    final places = location ?? false
        ? ref.watch(smartGroupListProvider(SmartGroupKind.place)).value ??
              const <SmartGroupView>[]
        : const <SmartGroupView>[];
    final live = [
      for (final g in LiveGroup.values)
        if (ref.watch(liveGroupSummaryProvider(g)).value case final s?
            when s.count > 0)
          (g, s),
    ];
    final running = progress.phase != SmartGroupsPhase.idle;
    final nothing = live.isEmpty && trips.isEmpty && places.isEmpty;

    Widget header(String text) => Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        spacing * 2,
        spacing * 2,
        spacing * 2,
        spacing / 2,
      ),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupsTitle)),
      body: ListView(
        padding: EdgeInsetsDirectional.only(bottom: spacing * 2),
        children: [
          if (progress.error != null)
            ListTile(
              leading: Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(l10n.groupsJobError),
            ),
          if (progress.phase == SmartGroupsPhase.reading)
            ListTile(
              leading: const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text(l10n.groupsProgress(progress.done, progress.total)),
            )
          else if (progress.phase == SmartGroupsPhase.grouping)
            ListTile(
              leading: const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text(l10n.groupsGrouping),
            ),
          if (progress.failedFiles > 0)
            ListTile(
              dense: true,
              title: Text(l10n.groupsFailedFiles(progress.failedFiles)),
            ),
          for (final (g, s) in live)
            _GroupCard(
              title: liveGroupTitle(l10n, g),
              count: s.count,
              cover: s.cover,
              onTap: () => _open(LiveGroupKey(g)),
            ),
          if (trips.isNotEmpty) header(l10n.groupsTrips),
          for (final t in trips)
            _GroupCard(
              title: smartGroupTitle(l10n, t.row),
              count: t.row.itemCount,
              cover: t.cover,
              onTap: () => _open(StoredGroupKey(t.row.id)),
            ),
          if (places.isNotEmpty) header(l10n.groupsPlaces),
          for (final p in places)
            _GroupCard(
              title: smartGroupTitle(l10n, p.row),
              count: p.row.itemCount,
              cover: p.cover,
              onTap: () => _open(StoredGroupKey(p.row.id)),
            ),
          if (location == false)
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(l10n.groupsLocationRow),
              onTap: () => unawaited(
                ref.read(mediaLocationAccessProvider.notifier).request(),
              ),
            ),
          if (nothing && !running)
            Padding(
              padding: EdgeInsetsDirectional.all(spacing * 3),
              child: Text(
                l10n.groupsEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }

  void _open(GroupKey key) =>
      unawaited(context.push<void>(AppRoutes.groupFor(key.value)));
}

class _GroupCard extends StatelessWidget {
  const new({
    required this.title,
    required this.count,
    required this.cover,
    required this.onTap,
  });

  final String title;
  final int count;
  final FileRef? cover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tokens.spacing;
    final radius = context.tokens.radius;
    final file = cover;
    return Card(
      margin: EdgeInsetsDirectional.symmetric(
        horizontal: spacing * 2,
        vertical: spacing / 2,
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: EdgeInsetsDirectional.symmetric(horizontal: spacing),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(radius / 2),
          child: SizedBox.square(
            dimension: 56,
            child: file == null
                ? ColoredBox(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child: const Icon(Icons.photo_library_outlined),
                  )
                : Thumbnail(file: file),
          ),
        ),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(context.l10n.groupsCount(count)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
