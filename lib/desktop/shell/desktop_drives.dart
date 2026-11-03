import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/desktop/shell/desktop_drops.dart';
import 'package:kfm/desktop/shell/desktop_navigation.dart';
import 'package:kfm/desktop/shell/desktop_sidebar.dart';
import 'package:kfm/desktop/widgets/desktop_drag.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:kfm/features/external_storage/data/volume_activity_tracker.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:kfm/features/external_storage/ui/eject_flow.dart';
import 'package:kfm/features/external_storage/ui/place_labels.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// PL1: the drives in the sidebar's Places (U1 places on Windows: system
/// drive, other disks, USB sticks / SD cards). Cameras aren't drives.
List<StoragePlace> desktopDrivesOf(List<StoragePlace> places) => [
  for (final p in places)
    if (p.isMounted && p.kind != PlaceKind.camera && p.rootPath != null) p,
];

/// "Local disk (C:)" for the system drive, else the U1 place name.
String desktopDriveLabel(AppLocalizations l10n, StoragePlace place) =>
    place.id == kInternalPlaceId && place.rootPath != null
    ? l10n.desktopSystemDrive(place.rootPath!)
    : placeLabel(l10n, place);

IconData desktopDriveIcon(StoragePlace place) => switch (place.kind) {
  PlaceKind.internal => Icons.storage_outlined,
  PlaceKind.sdCard => Icons.sd_card_outlined,
  PlaceKind.usbDrive => Icons.usb,
  PlaceKind.camera => Icons.photo_camera_outlined,
  PlaceKind.unknown => Icons.sd_storage_outlined,
};

/// The drive rows: open in desktop Browse, take drops, and an Eject button
/// on removable ones (U3's eject flow).
class DesktopDriveItems extends ConsumerWidget {
  const new({required this.collapsed, super.key});

  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final drives = desktopDrivesOf(ref.watch(placesProvider).value ?? const []);
    final activity = ref.watch(volumeActivityTrackerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final d in drives)
          if (d.rootPath case final root?)
            Builder(
              builder: (context) {
                final ejecting = activity.isEjecting(d.id);
                final item = SidebarItem(
                  key: ValueKey('desktop-drive-${d.id}'),
                  icon: desktopDriveIcon(d),
                  label: desktopDriveLabel(l10n, d),
                  tooltip: placeSubtitle(l10n, d),
                  collapsed: collapsed,
                  enabled: !ejecting,
                  onTap: () => openDesktopFolder(context, ref, root),
                  trailing: d.isRemovable
                      ? IconButton(
                          key: ValueKey('desktop-eject-${d.id}'),
                          icon: const Icon(Icons.eject, size: 18),
                          tooltip: l10n.ejectAction,
                          visualDensity: VisualDensity.compact,
                          onPressed: ejecting
                              ? null
                              : () => unawaited(ejectPlace(context, ref, d)),
                        )
                      : null,
                );
                return ejecting
                    ? item
                    : DesktopDropTarget(
                        offer: folderDropOffer(context, ref, root),
                        child: item,
                      );
              },
            ),
      ],
    );
  }
}
