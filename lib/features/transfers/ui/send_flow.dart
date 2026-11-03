import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/adaptive_sheet.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/browse/ui/widgets/file_actions_menu.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/discovery.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/connect_controller.dart';
import 'package:kfm/features/connect/ui/connect_screen.dart';
import 'package:kfm/features/connect/ui/known_devices_providers.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/privacy/domain/location_stripper.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';
import 'package:kfm/features/transfers/ui/transfer_flows.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_flow.g.dart';

/// How the Connect screen starts a send-mode pairing.
enum SendPairStart { nearby, scan, code }

/// Files waiting for a send-mode pairing on the Connect screen (N12):
/// once connected, the screen offers "Send N files to R".
typedef PendingSendFiles = ({
  List<FileRef> files,
  SendPairStart start,
  NearbyDevice? device,
});

@Riverpod(keepAlive: true)
class PendingSend extends _$PendingSend {
  @override
  PendingSendFiles? build() => null;

  // A method, not a setter: callers hand over a whole send.
  // ignore: use_setters_to_change_properties
  void set(PendingSendFiles? value) => state = value;
}

/// What the device sheet picked.
sealed class _SendTarget {
  const new();
}

final class _ToConnected extends _SendTarget {
  const new(this.fingerprint, this.name);

  final String fingerprint;
  final String name;
}

/// N12b: a client connected to this (sharing) device.
final class _ToClient extends _SendTarget {
  const new(this.fingerprint, this.name);

  final String fingerprint;
  final String name;
}

final class _ToRemembered extends _SendTarget {
  const new(this.device);

  final KnownDevice device;
}

final class _ToNearby extends _SendTarget {
  const new(this.device);

  final NearbyDevice device;
}

final class _ToPair extends _SendTarget {
  const new(this.start);

  final SendPairStart start;
}

void _snack(BuildContext context, String text, {bool showTransfers = false}) {
  final router = GoRouter.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        persist: false,
        content: Text(text),
        action: showTransfers
            ? SnackBarAction(
                label: context.l10n.transferShow,
                onPressed: () => router.push(AppRoutes.transfers),
              )
            : null,
      ),
    );
}

/// TASK-N12 "Send to…": pick a device (connected, remembered, nearby, QR
/// or code), connect send-only when needed, confirm, then one send job.
/// The other device decides; no folder is shared either way.
Future<void> startSend(
  BuildContext context,
  WidgetRef ref,
  List<FileRef> files,
) async {
  if (files.isEmpty) return;
  final target = await showAdaptiveSheet<_SendTarget>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SendDeviceSheet(count: files.length),
  );
  if (target == null || !context.mounted) return;
  final connection = ref.read(remoteConnectionControllerProvider);
  final connectedFp = switch (connection) {
    RemoteConnected(:final peerFingerprint) => peerFingerprint,
    _ => null,
  };
  switch (target) {
    case _ToConnected(:final fingerprint, :final name):
      await confirmAndSend(context, ref, files, fingerprint, name);
    case _ToClient(:final fingerprint, :final name):
      await _offerToClient(context, ref, files, fingerprint, name);
    case _ToRemembered(:final device):
      if (connectedFp == device.fingerprint) {
        await confirmAndSend(
          context,
          ref,
          files,
          device.fingerprint,
          device.name,
        );
        return;
      }
      if (!await _leaveOther(context, ref, connection, device.name)) return;
      if (!context.mounted) return;
      final ok = await _reconnectToSend(context, ref, device);
      if (!ok || !context.mounted) return;
      await confirmAndSend(
        context,
        ref,
        files,
        device.fingerprint,
        device.name,
      );
    case _ToNearby(:final device):
      if (!await _leaveOther(context, ref, connection, device.name)) return;
      if (!context.mounted) return;
      ref.read(pendingSendProvider.notifier).set((
        files: files,
        start: SendPairStart.nearby,
        device: device,
      ));
      await context.push(AppRoutes.connectSend);
    case _ToPair(:final start):
      if (!await _leaveOther(context, ref, connection, null)) return;
      if (!context.mounted) return;
      ref.read(pendingSendProvider.notifier).set((
        files: files,
        start: start,
        device: null,
      ));
      await context.push(AppRoutes.connectSend);
  }
}

/// One connection at a time: "Disconnect from X to send to R?" (its
/// jobs pause and wait, N10). True when not connected or the user agreed.
Future<bool> _leaveOther(
  BuildContext context,
  WidgetRef ref,
  RemoteConnectionState connection,
  String? to,
) async {
  if (connection is! RemoteConnected) return true;
  final l10n = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(
        l10n.sendSwitchDevice(
          connection.peerName,
          to ?? l10n.connectOtherDevice,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('send-switch-confirm'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.sendSwitchAction),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  await ref.read(remoteConnectionControllerProvider.notifier).disconnect();
  return true;
}

/// `/v1/pair/known` with a send-only session (no connection prompt on the
/// other device). Errors show as a snackbar (rule 8).
Future<bool> _reconnectToSend(
  BuildContext context,
  WidgetRef ref,
  KnownDevice device,
) async {
  final l10n = context.l10n;
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              SizedBox(width: context.tokens.spacing * 2),
              Expanded(child: Text(l10n.sendConnecting(device.name))),
            ],
          ),
        ),
      ),
    ),
  );
  try {
    await ref
        .read(knownDeviceConnectorProvider)
        .reconnect(device.fingerprint, purpose: SessionPurpose.send);
    navigator.pop();
    return true;
  } on PairingException catch (e) {
    navigator.pop();
    if (context.mounted) {
      _snack(
        context,
        e.failure == PairingFailure.offline ||
                e.failure == PairingFailure.network
            ? l10n.sendAskReceive(device.name)
            : pairingFailureMessage(l10n, e.failure, device.name),
      );
    }
    return false;
  }
}

/// The confirm step: "Send N files (size) to R?", the X2 location note,
/// and (connected to R with writable shared folders) the old N9 "Put
/// them in a shared folder on R…". Send queues the job.
Future<void> confirmAndSend(
  BuildContext context,
  WidgetRef ref,
  List<FileRef> files,
  String fingerprint,
  String name,
) async {
  final l10n = context.l10n;
  final hasMedia = files.any(LocationStripper.appliesTo);
  final strip =
      hasMedia &&
      await ref
          .read(settingsRepositoryProvider)
          .read(AppSettings.privacyStripLocation);
  if (!context.mounted) return;
  final connection = ref.read(remoteConnectionControllerProvider);
  final sharedFolders =
      connection is RemoteConnected &&
      connection.peerFingerprint == fingerprint &&
      connection.roots.any((r) => !r.readOnly);
  final size = formatBytes(files.fold(0, (a, f) => a + f.sizeBytes));
  final choice = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.sendConfirmTitle(files.length, size, name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.sendConfirmHint(name)),
          if (strip) ...[
            SizedBox(height: context.tokens.spacing),
            Text(l10n.privacyTransferNote),
          ],
          if (sharedFolders)
            TextButton(
              key: const ValueKey('send-shared-folder'),
              onPressed: () => Navigator.pop(context, 'folder'),
              child: Text(l10n.sendSharedFolderInstead(name)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('send-confirm'),
          onPressed: () => Navigator.pop(context, 'send'),
          child: Text(l10n.sendAction),
        ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return;
  if (choice == 'folder') {
    await startUpload(context, ref, files);
    return;
  }
  await ref
      .read(transferEngineProvider)
      .enqueueSend(files, peerFingerprint: fingerprint, peerName: name);
  if (!context.mounted) return;
  _snack(context, l10n.sendWaiting(name), showTransfers: true);
}

/// N12b: offers [files] to the client [fingerprint] connected to this
/// sharing device; it prompts within a heartbeat and downloads them.
Future<void> _offerToClient(
  BuildContext context,
  WidgetRef ref,
  List<FileRef> files,
  String fingerprint,
  String name,
) async {
  final l10n = context.l10n;
  final size = formatBytes(files.fold(0, (a, f) => a + f.sizeBytes));
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.sendConfirmTitle(files.length, size, name)),
      content: Text(l10n.sendConfirmHint(name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('send-confirm'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.sendAction),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await ref
        .read(offerServiceProvider)
        .offerToClient(fingerprint, name, files);
    if (context.mounted) _snack(context, l10n.sendWaiting(name));
  } on Object {
    // X2 couldn't remove location from a file: nothing was offered.
    if (context.mounted) _snack(context, l10n.privacyTransferNotRemoved);
  }
}

/// "Send to…": Connected / Remembered (online dot from mDNS) / Nearby,
/// then Scan QR code / Enter code.
class _SendDeviceSheet extends ConsumerWidget {
  const new({required this.count});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final connection = ref.watch(remoteConnectionControllerProvider);
    final connected = connection is RemoteConnected ? connection : null;
    final remembered = [
      for (final d
          in ref.watch(knownDevicesProvider).value ?? const <KnownDevice>[])
        if (d.fingerprint != connected?.peerFingerprint) d,
    ];
    final nearby =
        ref.watch(nearbyDevicesProvider).value ?? const <NearbyDevice>[];
    // N12b: clients connected to this device while it shares.
    final clients = [
      for (final s
          in ref.watch(connectedClientsProvider).value ??
              const <ClientSession>[])
        if (!s.sendOnly) s,
    ];
    final online = {for (final n in nearby) ?n.fingerprintHint};
    final strangers = [
      for (final n in nearby)
        if (n.fingerprintHint != connected?.peerFingerprint &&
            !remembered.any((d) => d.fingerprint == n.fingerprintHint))
          n,
    ];
    Widget header(String text) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
      child: Text(text, style: theme.textTheme.titleSmall),
    );
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(
                l10n.sendSheetTitle(count),
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (connected != null) ...[
              header(l10n.sendSheetConnected),
              ListTile(
                key: const ValueKey('send-connected'),
                leading: const Icon(Icons.link),
                title: Text(connected.peerName),
                onTap: () => Navigator.pop(
                  context,
                  _ToConnected(connected.peerFingerprint, connected.peerName),
                ),
              ),
            ],
            if (clients.isNotEmpty) ...[
              header(l10n.sendSheetConnectedToYou),
              for (final s in clients)
                ListTile(
                  key: ValueKey('send-client-${s.clientFingerprint}'),
                  leading: const Icon(Icons.phonelink),
                  title: Text(s.clientName),
                  onTap: () => Navigator.pop(
                    context,
                    _ToClient(s.clientFingerprint, s.clientName),
                  ),
                ),
            ],
            if (remembered.isNotEmpty) ...[
              header(l10n.sendSheetRemembered),
              for (final d in remembered)
                ListTile(
                  key: ValueKey('send-remembered-${d.fingerprint}'),
                  leading: Icon(
                    online.contains(d.fingerprint)
                        ? Icons.devices
                        : Icons.devices_other_outlined,
                  ),
                  title: Text(d.name),
                  subtitle: Text(
                    online.contains(d.fingerprint)
                        ? l10n.sendSheetOnline
                        : l10n.sendAskReceive(d.name),
                  ),
                  onTap: () => Navigator.pop(context, _ToRemembered(d)),
                ),
            ],
            if (strangers.isNotEmpty) ...[
              header(l10n.sendSheetNearby),
              for (final n in strangers)
                ListTile(
                  leading: const Icon(Icons.wifi_tethering),
                  title: Text(n.name),
                  onTap: () => Navigator.pop(context, _ToNearby(n)),
                ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: Text(l10n.connectScanQr),
              onTap: () =>
                  Navigator.pop(context, const _ToPair(SendPairStart.scan)),
            ),
            ListTile(
              key: const ValueKey('send-enter-code'),
              leading: const Icon(Icons.pin_outlined),
              title: Text(l10n.connectTypeCode),
              onTap: () =>
                  Navigator.pop(context, const _ToPair(SendPairStart.code)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The file ⋮ menu: "Send to…" (N12, local files).
final FileMenuItem sendFileMenuItem = FileMenuItem(
  order: 19,
  label: (c) => c.l10n.sendTo,
  icon: Icons.send_to_mobile_outlined,
  isAvailable: (f) => f.origin != FileOrigin.remote,
  onSelected: (context, ref, f) => startSend(context, ref, [f]),
);

/// `/connect?send=1` (N12): the Connect screen pairing send-only for the
/// [pendingSendProvider] files; once connected it asks to send them and
/// goes back.
class ConnectSendScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConnectSendScreen> createState() => _ConnectSendScreenState();
}

class _ConnectSendScreenState extends ConsumerState<ConnectSendScreen> {
  late final PendingSend _pending;
  ProviderSubscription<RemoteConnectionState>? _sub;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _pending = ref.read(pendingSendProvider.notifier);
    _sub = ref.listenManual(remoteConnectionControllerProvider, (_, next) {
      if (_handled || next is! RemoteConnected) return;
      _handled = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_send(next)),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  void _start() {
    if (!mounted) return;
    final pending = ref.read(pendingSendProvider);
    if (pending == null) {
      context.pop();
      return;
    }
    final controller = ref.read(connectControllerProvider.notifier)
      ..setPurpose(SessionPurpose.send);
    switch (pending.start) {
      case SendPairStart.nearby:
        if (pending.device case final d?) controller.pickDevice(d);
      case SendPairStart.scan:
        controller.scan().ignore();
      case SendPairStart.code:
        controller.typeCode();
    }
  }

  Future<void> _send(RemoteConnected c) async {
    final pending = ref.read(pendingSendProvider);
    if (pending == null || !mounted) return;
    await confirmAndSend(
      context,
      ref,
      pending.files,
      c.peerFingerprint,
      c.peerName,
    );
    _pending.set(null);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) => const ConnectScreen();
}
