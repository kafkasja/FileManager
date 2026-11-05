import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/features/browse/data/recent_searches.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/browse/ui/widgets/sources_row.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';

/// "Where files come from" (browse.txt point 2), only on the All files
/// page: a horizontal row of big cards with the newest photo as cover.
/// A connected device (N7) comes first, then recent searches (last 5,
/// B8/C4 add them); sources without files are hidden.
class SourcesCarousel extends ConsumerWidget {
  const new({super.key});

  static const cardWidth = 148.0;
  static const cardHeight = 188.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSeeAll =
        ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ??
        false;
    final recents = ref.watch(recentSearchesProvider).value ?? const [];
    final spacing = context.tokens.spacing;
    final remote = ref.watch(remoteConnectionControllerProvider);
    final cards = <Widget>[
      if (remote case RemoteConnected(:final peerName, :final peerFingerprint))
        _RemoteDeviceCard(name: peerName, peerFingerprint: peerFingerprint)
      else
        // E1: Connect is easy to find (opens the Connect screen).
        const _NearbyDevicesCard(),
      for (final r in recents)
        _CollectionCard(collection: RecentCollection(r), recent: true),
      for (final source in BrowseSourceChip.values)
        if (_shown(ref, source, canSeeAll: canSeeAll))
          _CollectionCard(collection: SourceCollection(source)),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: cardHeight + spacing * 2,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.all(spacing),
        itemCount: cards.length,
        separatorBuilder: (_, _) => SizedBox(width: spacing),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }

  static bool _shown(
    WidgetRef ref,
    BrowseSourceChip source, {
    required bool canSeeAll,
  }) {
    // Without access these stay, so opening them explains why.
    if (!canSeeAll && source.needsAllFiles) return true;
    final count = ref.watch(browseCountProvider(source.apply(IndexQuery.all)));
    return (count.value ?? 0) > 0;
  }
}

class _CollectionCard extends ConsumerWidget {
  const new({required this.collection, this.recent = false});

  final BrowseCollection collection;
  final bool recent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final radius = BorderRadius.circular(context.tokens.radius);
    final query = collection.query;
    final cover = ref.watch(collectionCoverProvider(query)).value;
    final count = ref.watch(browseCountProvider(query)).value;
    final title = collection.title(l10n);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: SourcesCarousel.cardWidth,
      child: Semantics(
        button: true,
        label: title,
        child: Material(
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          color: scheme.surfaceContainerHighest,
          child: InkWell(
            onTap: () => unawaited(
              context.push(AppRoutes.browseCollection, extra: collection),
            ),
            onLongPress: switch (collection) {
              RecentCollection(:final search) =>
                () => ref
                    .read(recentSearchesRepositoryProvider)
                    .remove(search)
                    .fireAndForget(),
              SourceCollection() ||
              TagCollection() ||
              FavoritesCollection() => null,
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (cover != null)
                  Thumbnail(file: cover)
                else
                  Icon(
                    recent ? Icons.history : Icons.folder_outlined,
                    size: 48,
                    color: scheme.outline,
                  ),
                // Keeps the name readable on any cover.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                      stops: [0.45, 1],
                    ),
                  ),
                ),
                if (recent)
                  PositionedDirectional(
                    top: spacing,
                    start: spacing,
                    child: Tooltip(
                      message: l10n.browseRecent,
                      child: const Icon(
                        Icons.history,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 4)],
                      ),
                    ),
                  ),
                PositionedDirectional(
                  start: spacing,
                  end: spacing,
                  bottom: spacing,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium?.copyWith(color: Colors.white),
                      ),
                      if (count != null)
                        Text(
                          l10n.browseFileCount(count),
                          style: text.labelMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// N7: the connected device; opens its remote browse screen.
class _RemoteDeviceCard extends StatelessWidget {
  const new({required this.name, required this.peerFingerprint});

  final String name;
  final String peerFingerprint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: SourcesCarousel.cardWidth,
      child: Semantics(
        button: true,
        label: l10n.remoteBrowseAction(name),
        excludeSemantics: true,
        child: Material(
          borderRadius: BorderRadius.circular(context.tokens.radius),
          clipBehavior: Clip.antiAlias,
          color: scheme.primaryContainer,
          child: InkWell(
            onTap: () => unawaited(
              context.push(AppRoutes.connectBrowseFor(peerFingerprint)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Icon(
                  Icons.devices_outlined,
                  size: 48,
                  color: scheme.onPrimaryContainer,
                ),
                PositionedDirectional(
                  start: spacing,
                  end: spacing,
                  bottom: spacing,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        l10n.remoteConnectedDevice,
                        style: text.labelMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// E1: "Nearby devices · Connect a phone or PC" while nothing is linked.
class _NearbyDevicesCard extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: SourcesCarousel.cardWidth,
      child: Semantics(
        button: true,
        label: l10n.linkNearbyDevices,
        excludeSemantics: true,
        child: Material(
          key: const ValueKey('browse-nearby-devices'),
          borderRadius: BorderRadius.circular(context.tokens.radius),
          clipBehavior: Clip.antiAlias,
          color: scheme.secondaryContainer,
          child: InkWell(
            onTap: () => unawaited(context.push(AppRoutes.connect)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Icon(
                  Icons.devices_outlined,
                  size: 48,
                  color: scheme.onSecondaryContainer,
                ),
                PositionedDirectional(
                  start: spacing,
                  end: spacing,
                  bottom: spacing,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.linkNearbyDevices,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                      Text(
                        l10n.linkNearbyDevicesHint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
