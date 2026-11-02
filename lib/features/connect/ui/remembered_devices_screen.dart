import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/discovery.dart';
import 'package:kfm/features/connect/data/remote_source_provider.dart';
import 'package:kfm/features/connect/domain/fingerprint_words.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/ui/connect_controller.dart';
import 'package:kfm/features/connect/ui/known_devices_providers.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';

/// "Remembered devices" (TASK-N6): reconnect without scanning, "Share from
/// this device", "Always allow", Remove and Remove all.
class RememberedDevicesScreen extends ConsumerWidget {
  const new({this.fromConnect = false, super.key});

  /// Opened from the Connect screen: Reconnect goes back to it.
  final bool fromConnect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final devices = ref.watch(knownDevicesProvider);
    // Keeps the Connect screen's controller alive while a reconnect starts
    // here and the Connect screen takes over.
    ref.listen(connectControllerProvider, (_, _) {});
    final list = devices.value ?? const <KnownDevice>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rememberedDevicesTitle),
        actions: [
          if (list.isNotEmpty)
            PopupMenuButton<void>(
              key: const ValueKey('remembered-menu'),
              itemBuilder: (_) => [
                PopupMenuItem<void>(
                  key: const ValueKey('remembered-remove-all'),
                  onTap: () => unawaited(_removeAll(context, ref)),
                  child: Text(l10n.rememberedRemoveAll),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: switch (devices) {
          AsyncError() => _Empty(text: l10n.rememberedLoadFailed),
          AsyncData(value: final v) when v.isEmpty => _Empty(
            text: l10n.rememberedEmpty,
          ),
          AsyncData(value: final v) => _DeviceList(
            devices: v,
            fromConnect: fromConnect,
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Future<void> _removeAll(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rememberedRemoveAllTitle),
        content: Text(l10n.rememberedRemoveAllBody),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('remembered-remove-all-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.rememberedRemoveAll),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(rememberedDevicesServiceProvider).removeAll();
    } on Object {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.rememberedRemoveFailed)),
      );
    }
  }
}

class _Empty extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tokens.spacing;
    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(spacing * 3),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _DeviceList extends ConsumerWidget {
  const new({required this.devices, required this.fromConnect});

  final List<KnownDevice> devices;
  final bool fromConnect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.tokens.spacing;
    // Online = seen by mDNS now (its TXT fp matches; only a hint).
    final nearby = ref.watch(nearbyDevicesProvider).value ?? const [];
    final online = {for (final NearbyDevice n in nearby) ?n.fingerprintHint};
    final names = <String, int>{};
    for (final d in devices) {
      names[d.name] = (names[d.name] ?? 0) + 1;
    }
    return ListView(
      padding: EdgeInsetsDirectional.all(spacing * 2),
      children: [
        for (final d in devices)
          _DeviceCard(
            device: d,
            online: online.contains(d.fingerprint),
            // Same name twice (e.g. a reinstall): tell them apart.
            showWords: (names[d.name] ?? 0) > 1,
            fromConnect: fromConnect,
          ),
      ],
    );
  }
}

class _DeviceCard extends ConsumerWidget {
  const new({
    required this.device,
    required this.online,
    required this.showWords,
    required this.fromConnect,
  });

  final KnownDevice device;
  final bool online;
  final bool showWords;
  final bool fromConnect;

  static IconData _icon(String platform) => switch (platform) {
    'windows' || 'macos' || 'linux' => Icons.computer_outlined,
    'android' || 'ios' => Icons.smartphone_outlined,
    _ => Icons.devices_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    final d = device;
    // A live connection beats the mDNS hint (mDNS is blocked on some
    // networks, and the emulator never sees it).
    final connected = ref.watch(remotePeerConnectedProvider(d.fingerprint));
    final status = connected
        ? l10n.rememberedConnected
        : d.canShareToUs
        ? (online ? l10n.rememberedOnline : l10n.rememberedOffline)
        : l10n.rememberedConnectsToUs;
    return Card(
      key: ValueKey('remembered-${d.fingerprint}'),
      child: Padding(
        padding: EdgeInsetsDirectional.only(bottom: spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: Icon(_icon(d.platform)),
              title: Text(d.name),
              subtitle: Text(
                showWords
                    ? l10n.rememberedStatusWords(
                        status,
                        // Fixed English words (ARB-exempt): only to tell
                        // rows apart, not the pairing phrase.
                        fingerprintWords(
                          d.fingerprint,
                          d.fingerprint,
                        ).join(' '),
                      )
                    : status,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (connected || (d.canShareToUs && online))
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: theme.colorScheme.primary,
                      // The subtitle already says "Connected".
                      semanticLabel: connected ? null : l10n.rememberedOnline,
                    ),
                  IconButton(
                    key: ValueKey('remembered-remove-${d.fingerprint}'),
                    tooltip: l10n.rememberedRemove,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => unawaited(_remove(context, ref)),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              key: ValueKey('remembered-always-${d.fingerprint}'),
              value: d.autoAccept,
              title: Text(l10n.rememberedAlwaysAllow),
              subtitle: Text(l10n.rememberedAlwaysAllowHint),
              onChanged: (v) => ref
                  .read(knownDevicesRepositoryProvider)
                  .setAutoAccept(d.fingerprint, autoAccept: v)
                  .fireAndForget(),
            ),
            Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: connected
                    ? FilledButton.tonal(
                        key: ValueKey('remembered-browse-${d.fingerprint}'),
                        onPressed: () => unawaited(
                          context.push(
                            AppRoutes.connectBrowseFor(d.fingerprint),
                          ),
                        ),
                        child: Text(l10n.remoteBrowseAction(d.name)),
                      )
                    : d.canShareToUs
                    ? FilledButton(
                        key: ValueKey('remembered-reconnect-${d.fingerprint}'),
                        onPressed: () => _reconnect(context, ref),
                        child: Text(l10n.rememberedReconnect),
                      )
                    : OutlinedButton(
                        key: ValueKey('remembered-share-${d.fingerprint}'),
                        onPressed: () =>
                            unawaited(context.push(AppRoutes.connectShare)),
                        child: Text(l10n.rememberedShareFromHere),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reconnect(BuildContext context, WidgetRef ref) {
    ref
        .read(connectControllerProvider.notifier)
        .reconnect(device.fingerprint, name: device.name);
    if (fromConnect && context.canPop()) {
      context.pop();
    } else {
      unawaited(context.push(AppRoutes.connect));
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    // N9: its transfers go with it (FK cascade).
    final transfers = await ref
        .read(transfersRepositoryProvider)
        .dao
        .countForDevice(device.id);
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rememberedRemoveTitle(device.name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.rememberedRemoveBody),
            if (transfers > 0) ...[
              const SizedBox(height: 12),
              Text(l10n.rememberedRemoveTransfers(transfers)),
            ],
          ],
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('remembered-remove-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.rememberedRemove),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(rememberedDevicesServiceProvider).remove(device);
    } on Object {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.rememberedRemoveFailed)),
      );
    }
  }
}
