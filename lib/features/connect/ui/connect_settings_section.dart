import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';

/// Settings → Connect a device (TASK-N1): the entry rows of Phase 5.
class ConnectSettingsSection extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.wifi_tethering),
          title: Text(l10n.connectShareThisDevice),
          subtitle: Text(l10n.connectShareThisDeviceHint),
          onTap: () => context.push(AppRoutes.connectShare),
        ),
        // N2 enables it (QR scan / typed code).
        ListTile(
          enabled: false,
          leading: const Icon(Icons.devices_outlined),
          title: Text(l10n.connectToDevice),
          subtitle: Text(l10n.connectToDeviceSoon),
        ),
      ],
    );
  }
}
