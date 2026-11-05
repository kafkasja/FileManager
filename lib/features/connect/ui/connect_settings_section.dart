import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/features/connect/ui/known_devices_providers.dart';
import 'package:kfm/features/connect/ui/windows_close_host.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';
import 'package:kfm/features/settings/ui/widgets/settings_tiles.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';

// Settings → Connect & sharing (TASK-N1/N6/N9, E2).

/// One row for both directions (E2 + E1: "Share this device" and "Connect
/// to a device" became "Connect a device"). E1 adjusts the target screen.
final connectEntry = SettingsEntry(
  id: 'connect.connect',
  titleBuilder: (c) => c.l10n.connectADevice,
  subtitleBuilder: (c) => c.l10n.connectADeviceHelp,
  keywordsBuilder: (c) => c.l10n.settingsKeywordsConnect,
  builder: (c) => SettingsTile(
    icon: Icons.devices_outlined,
    title: c.l10n.connectADevice,
    subtitle: c.l10n.connectADeviceHelp,
    chevron: true,
    onTap: () => c.push(AppRoutes.connect),
  ),
);

// TODO(E1): `connect.receiveFolder` ("Received files go to") goes here, right
// after [connectEntry]: E1 declares the key + row widget, the entry joins
// `settingsSectionsProvider` → Connect & sharing.

final rememberedDevicesEntry = SettingsEntry(
  id: 'connect.devices',
  titleBuilder: (c) => c.l10n.rememberedDevicesTitle,
  subtitleBuilder: (c) => c.l10n.rememberedDevicesHint,
  builder: (c) => ListTile(
    key: const ValueKey('settings-remembered-devices'),
    leading: const Icon(Icons.devices_other_outlined),
    title: Text(c.l10n.rememberedDevicesTitle),
    subtitle: Text(c.l10n.rememberedDevicesHint),
    onTap: () => c.push(AppRoutes.connectDevices),
  ),
);

/// N9: every Wi-Fi transfer in one place.
final transfersEntry = SettingsEntry(
  id: 'connect.transfers',
  titleBuilder: (c) => c.l10n.transfersTitle,
  subtitleBuilder: (c) => c.l10n.transfersSettingHelp,
  builder: (_) => Consumer(
    builder: (c, ref, _) => ListTile(
      key: const ValueKey('settings-transfers'),
      leading: const Icon(Icons.swap_vert),
      title: Text(c.l10n.transfersTitle),
      subtitle: Text(
        c.l10n.transfersRunning(ref.watch(activeTransferCountProvider)),
      ),
      onTap: () => c.push(AppRoutes.transfers),
    ),
  ),
);

/// PL1: what closing the window does while sharing (Windows only).
final stopSharingOnCloseEntry = SettingsEntry(
  id: 'connect.stopSharingOnClose',
  titleBuilder: (c) => c.l10n.settingsStopSharingOnClose,
  subtitleBuilder: (c) => c.l10n.settingsStopSharingOnCloseHint,
  formFactors: const {FormFactor.desktop},
  visible: (_) => isWindowsHost,
  builder: (_) => Consumer(
    builder: (c, ref, _) => SwitchListTile(
      key: const ValueKey('settings-stop-sharing-on-close'),
      secondary: const Icon(Icons.close_fullscreen),
      title: Text(c.l10n.settingsStopSharingOnClose),
      subtitle: Text(c.l10n.settingsStopSharingOnCloseHint),
      value: ref.watch(windowsStopSharingOnCloseProvider).value ?? false,
      onChanged: (v) => ref
          .read(settingsRepositoryProvider)
          .write(AppSettings.windowsStopSharingOnClose, v)
          .fireAndForget(),
    ),
  ),
);

final resetIdentityEntry = SettingsEntry(
  id: 'connect.resetIdentity',
  titleBuilder: (c) => c.l10n.resetIdentityTitle,
  subtitleBuilder: (c) => c.l10n.resetIdentityHint,
  builder: (_) => Consumer(
    builder: (c, ref, _) => ListTile(
      key: const ValueKey('settings-reset-identity'),
      leading: const Icon(Icons.key_off_outlined),
      title: Text(c.l10n.resetIdentityTitle),
      subtitle: Text(c.l10n.resetIdentityHint),
      onTap: () => resetIdentityWithConfirm(c, ref),
    ),
  ),
);

/// Privacy & access: who can see this device's files (the user asked for
/// sharing privacy there). Same screen as Remembered devices.
final privacyDevicesEntry = SettingsEntry(
  id: 'privacy.devices',
  titleBuilder: (c) => c.l10n.privacyDevicesTitle,
  subtitleBuilder: (c) => c.l10n.privacyDevicesHelp,
  builder: (c) => SettingsTile(
    icon: Icons.phonelink_lock_outlined,
    title: c.l10n.privacyDevicesTitle,
    subtitle: c.l10n.privacyDevicesHelp,
    chevron: true,
    onTap: () => c.push(AppRoutes.connectDevices),
  ),
);

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
