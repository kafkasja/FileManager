import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/features/connect/ui/known_devices_providers.dart';

/// Settings → Connect a device (TASK-N1): the entry rows of Phase 5. N6
/// adds "Remembered devices" and "Reset this device's identity".
class ConnectSettingsSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.wifi_tethering),
          title: Text(l10n.connectShareThisDevice),
          subtitle: Text(l10n.connectShareThisDeviceHint),
          onTap: () => context.push(AppRoutes.connectShare),
        ),
        ListTile(
          leading: const Icon(Icons.devices_outlined),
          title: Text(l10n.connectToDevice),
          subtitle: Text(l10n.connectToDeviceHint),
          onTap: () => context.push(AppRoutes.connect),
        ),
        ListTile(
          key: const ValueKey('settings-remembered-devices'),
          leading: const Icon(Icons.devices_other_outlined),
          title: Text(l10n.rememberedDevicesTitle),
          subtitle: Text(l10n.rememberedDevicesHint),
          onTap: () => context.push(AppRoutes.connectDevices),
        ),
        ListTile(
          key: const ValueKey('settings-reset-identity'),
          leading: const Icon(Icons.key_off_outlined),
          title: Text(l10n.resetIdentityTitle),
          subtitle: Text(l10n.resetIdentityHint),
          onTap: () => resetIdentityWithConfirm(context, ref),
        ),
      ],
    );
  }
}

/// Confirms, then resets this device's identity (N6): stops sharing, new
/// key, every remembered device forgotten.
Future<void> resetIdentityWithConfirm(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.resetIdentityConfirmTitle),
      content: Text(l10n.resetIdentityConfirmBody),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('reset-identity-confirm'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.resetIdentityConfirm),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await ref.read(rememberedDevicesServiceProvider).resetIdentity();
    messenger.showSnackBar(SnackBar(content: Text(l10n.resetIdentityDone)));
  } on Object {
    messenger.showSnackBar(SnackBar(content: Text(l10n.resetIdentityFailed)));
  }
}
