import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/desktop/shell/desktop_location.dart';
import 'package:kfm/desktop/shell/desktop_sidebar.dart';
import 'package:kfm/desktop/tabs/desktop_tabs_controller.dart';
import 'package:kfm/desktop/widgets/desktop_drag.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/domain/link.dart';
import 'package:kfm/features/connect/ui/connect_screen.dart';
import 'package:kfm/features/connect/ui/known_devices_providers.dart';
import 'package:kfm/features/connect/ui/link_chip.dart';
import 'package:kfm/features/connect/ui/link_providers.dart';
import 'package:kfm/features/transfers/ui/link_send.dart';
import 'package:kfm/features/transfers/ui/send_flow.dart';

/// TASK-E1: opens the linked device in the current tab (its files when
/// this PC can browse them, else Devices).
void openDeviceBrowse(WidgetRef ref, DeviceLink link) {
  ref
      .read(desktopTabsControllerProvider.notifier)
      .navigate(
        link.iSeeTheirs
            ? RouteLocation(AppRoutes.connectBrowseFor(link.peerFingerprint))
            : const DevicesLocation(),
      );
}

/// A drop on a device row (TASK-E1, generalises `devicesDropOffer`): KFM
/// files or files from Explorer. Linked → "Send to `name`" at once;
/// otherwise the N12 device picker.
DropOfferBuilder deviceDropOffer(
  BuildContext context,
  WidgetRef ref,
  DeviceRow row,
) => (data, {required copy}) {
  if (!data.filesOnly) return null;
  if (data.fromKfm && data.files.isEmpty) return null;
  if (!data.fromKfm && data.paths.isEmpty) return null;
  return DropOffer(
    label: context.l10n.linkSendTo(row.name),
    onDrop: () async {
      final files = data.fromKfm ? data.files : await _statAll(ref, data.paths);
      if (!context.mounted || files.isEmpty) return;
      final link = ref.read(currentLinkProvider);
      if (link != null && link.peerFingerprint == row.fingerprint) {
        await sendToLink(context, ref, link, files);
      } else {
        await startSend(context, ref, files);
      }
    },
  );
};

Future<List<FileRef>> _statAll(WidgetRef ref, List<String> paths) async {
  final source = ref.read(fileSourceProvider);
  return [for (final p in paths) ?await source.statPath(p)];
}

/// The nav pane's Devices group rows (filled into E3's
/// `desktopNavDeviceRowsProvider`): the linked device (green dot, click =
/// its files in this tab) and the remembered ones (click = reconnect).
class DesktopDeviceRows extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(deviceRowsProvider);
    if (rows.isEmpty) return const SizedBox.shrink();
    final loc = ref.watch(desktopTabsControllerProvider).current.location;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          DesktopDropTarget(
            offer: deviceDropOffer(context, ref, row),
            child: SidebarItem(
              key: ValueKey('desktop-device-${row.fingerprint}'),
              icon: row.platform == 'windows'
                  ? Icons.computer
                  : Icons.smartphone,
              iconColor: row.status == DeviceRowStatus.linked
                  ? colors.primary
                  : null,
              label: row.name,
              tooltip: row.status == DeviceRowStatus.linked
                  ? context.l10n.linkConnectedTo(row.name)
                  : context.l10n.linkReconnectTo(row.name),
              selected:
                  loc ==
                  RouteLocation(AppRoutes.connectBrowseFor(row.fingerprint)),
              trailing: row.status == DeviceRowStatus.linked
                  ? Icon(Icons.circle, size: 8, color: colors.primary)
                  : null,
              onTap: () => unawaited(_open(context, ref, row)),
            ),
          ),
      ],
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, DeviceRow row) async {
    final link = ref.read(currentLinkProvider);
    if (link != null && link.peerFingerprint == row.fingerprint) {
      openDeviceBrowse(ref, link);
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = context.l10n;
    messenger?.showSnackBar(
      SnackBar(persist: false, content: Text(l10n.linkReconnecting(row.name))),
    );
    try {
      await ref.read(knownDeviceConnectorProvider).reconnect(row.fingerprint);
    } on PairingException catch (e) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            persist: false,
            content: Text(pairingFailureMessage(l10n, e.failure, row.name)),
          ),
        );
      return;
    }
    messenger?.hideCurrentSnackBar();
    if (ref.read(currentLinkProvider) case final now?
        when now.peerFingerprint == row.fingerprint) {
      openDeviceBrowse(ref, now);
    }
  }
}

/// The status bar's link slot (E3's `desktopStatusConnectionProvider`).
class DesktopLinkStatus extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      LinkStatusChip(onOpen: (link) => openDeviceBrowse(ref, link));
}
