import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/platform/volumes/volumes_providers.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:kfm/features/external_storage/data/volume_activity_tracker.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:kfm/features/external_storage/ui/eject_flow.dart';
import 'package:kfm/features/external_storage/ui/place_labels.dart';
import 'package:kfm/features/external_storage/ui/saf_grant_flow.dart';

/// U1: the Places section at the top of the Browse root. Hidden while
/// internal storage is the only place (simple by default).
class PlacesList extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final activity = ref.watch(volumeActivityTrackerProvider);
    return switch (ref.watch(placesProvider)) {
      AsyncValue(:final value?) => () {
        final shown = [
          for (final p in value)
            if (p.isMounted) p,
        ];
        if (!shown.any((p) => p.isRemovable)) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                spacing * 2,
                spacing,
                spacing * 2,
                0,
              ),
              child: Text(
                l10n.externalPlacesTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            for (final p in shown)
              ListTile(
                key: ValueKey('place-${p.id}'),
                leading: Icon(placeIcon(p.kind)),
                title: Text(placeLabel(l10n, p)),
                subtitle: switch (placeSubtitle(l10n, p)) {
                  final s? => Text(s, maxLines: 2),
                  null => null,
                },
                trailing: p.isRemovable && !p.needsPermission
                    ? IconButton(
                        key: ValueKey('eject-${p.id}'),
                        icon: const Icon(Icons.eject),
                        tooltip: l10n.ejectAction,
                        onPressed: activity.isEjecting(p.id)
                            ? null
                            : () => unawaited(ejectPlace(context, ref, p)),
                      )
                    : null,
                onTap: activity.isEjecting(p.id)
                    ? null
                    : () => unawaited(openPlace(context, ref, p)),
              ),
          ],
        );
      }(),
      AsyncError() => ListTile(
        title: Text(l10n.externalLoadError),
        trailing: TextButton(
          onPressed: () => ref.invalidate(deviceStorageProvider),
          child: Text(l10n.retry),
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// Opens [place]: cameras ask for the USB permission first, then open in
/// U2's place browser; SAF volumes get their one-time grant and open in
/// the place browser too; places reached by path open Browse's folder
/// layout at their root (indexed: B1 filters and B2 sorting work).
Future<void> openPlace(
  BuildContext context,
  WidgetRef ref,
  StoragePlace place,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  if (place.kind == PlaceKind.camera) {
    final mtp = ref.read(mtpPlatformProvider);
    final device = place.id.substring('mtp:'.length);
    if (place.needsPermission && mtp != null) {
      await mtp.requestPermission(device);
      return;
    }
    if (place.isUnsupported) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.externalCameraUnsupported)),
      );
      return;
    }
    await context.push(
      placeBrowserLocation(root: place.id, title: placeLabel(l10n, place)),
    );
    return;
  }
  final root = place.rootPath;
  if (root == null) return;
  if (!await ensureSafGrant(context, ref, place)) return;
  if (!context.mounted) return;
  if (place.access == AccessMethod.saf) {
    await context.push(
      placeBrowserLocation(root: root, title: placeLabel(l10n, place)),
    );
    return;
  }
  context.go(AppRoutes.browse);
  // The Browse tab may only now be built: set its folder after this frame.
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return;
  ref.read(browseViewControllerProvider.notifier)
    ..setLayout(BrowseLayout.folders)
    ..openFolder(root);
}
