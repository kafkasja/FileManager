import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/remote_file_source.dart';
import 'package:kfm/features/connect/data/remote_source_provider.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/remote_browse_screen.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/folders/ui/folder_picker_sheet.dart';
import 'package:kfm/features/selection/ui/selection_actions.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/transfers/data/transfer_engine.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';

void _snack(BuildContext context, String text, {bool showTransfers = false}) {
  final router = GoRouter.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
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

/// N9: remote browse selection → "Download": confirms the folder
/// (`Download/<device>` by default, "Change folder" picks another), then
/// queues one job.
Future<void> startDownload(
  BuildContext context,
  WidgetRef ref, {
  required String peerFingerprint,
  required String peerName,
  required List<FileRef> files,
}) async {
  if (files.isEmpty) return;
  final l10n = context.l10n;
  final folder = defaultDownloadFolder(
    ref.read(downloadsRootProvider),
    peerName,
  );
  final choice = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.transferDownloadTitle(files.length)),
      content: Text(l10n.transferDownloadTo(folder)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: Text(l10n.transferChangeFolder),
        ),
        FilledButton(
          key: const ValueKey('transfer-download-confirm'),
          onPressed: () => Navigator.pop(context, folder),
          child: Text(l10n.transferDownloadAction),
        ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return;
  final target = choice.isEmpty ? await showFolderPicker(context) : choice;
  if (target == null || !context.mounted) return;
  await ref
      .read(transferEngineProvider)
      .enqueueDownload(
        files,
        peerFingerprint: peerFingerprint,
        peerName: peerName,
        localFolder: target,
      );
  if (!context.mounted) return;
  _snack(
    context,
    l10n.transferDownloadQueued(files.length, peerName),
    showTransfers: true,
  );
}

/// N9: local selection → "Send to device": the connected device, a folder
/// in one of its writable roots, then one upload job.
Future<void> startUpload(
  BuildContext context,
  WidgetRef ref,
  List<FileRef> files,
) async {
  if (files.isEmpty) return;
  final l10n = context.l10n;
  final connection = ref.read(remoteConnectionControllerProvider);
  if (connection is! RemoteConnected) {
    _snack(context, l10n.transferConnectFirst);
    return;
  }
  final fp = connection.peerFingerprint;
  final name = connection.peerName;
  final writable = [
    for (final r in connection.roots)
      if (!r.readOnly) r,
  ];
  if (writable.isEmpty) {
    _snack(context, l10n.transferNoWritableFolder(name));
    return;
  }
  final folder = await showRemoteFolderPicker(
    context,
    source: ref.read(remoteSourceProvider(fp)),
    device: name,
    roots: writable,
    // KFM never asks for ACCESS_MEDIA_LOCATION: Android redacts GPS from
    // the bytes it reads.
    note: Platform.isAndroid ? l10n.transferNoLocation : null,
  );
  if (folder == null || !context.mounted) return;
  final target = splitRemoteFolder(folder);
  await ref
      .read(transferEngineProvider)
      .enqueueUpload(
        files,
        peerFingerprint: fp,
        peerName: name,
        rootId: target.rootId,
        path: target.path,
      );
  if (!context.mounted) return;
  _snack(
    context,
    l10n.transferUploadQueued(files.length, name),
    showTransfers: true,
  );
}

/// B6 selection bar: "Send to device" (N9).
final SelectionAction sendToDeviceSelectionAction = SelectionAction(
  id: 'n9.send',
  order: 6,
  label: (c) => c.l10n.transferSendToDevice,
  icon: Icons.send_to_mobile_outlined,
  run: (context, ref, ids) async {
    final files = await ref.read(mediaIndexDaoProvider).byIds(ids);
    if (!context.mounted) return;
    await startUpload(context, ref, files);
  },
);

/// P2 action editor for `sendToDevice` (N9): a remembered device, then a
/// folder in one of its writable roots, which needs the connection to it.
/// Null = dismissed or not possible right now (a snackbar says why).
Future<SwipeAction?> pickSendToDeviceAction(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final l10n = context.l10n;
  final devices = [
    for (final d in await container.read(knownDevicesRepositoryProvider).all())
      if (!d.isTemporary) d,
  ];
  if (!context.mounted) return null;
  if (devices.isEmpty) {
    _snack(context, l10n.transferNoRememberedDevices);
    return null;
  }
  final device = await showModalBottomSheet<KnownDevice>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(title: Text(l10n.transferPickDeviceTitle)),
          for (final d in devices)
            ListTile(
              leading: const Icon(Icons.devices_outlined),
              title: Text(d.name),
              onTap: () => Navigator.pop(context, d),
            ),
        ],
      ),
    ),
  );
  if (device == null || !context.mounted) return null;
  final connection = container.read(remoteConnectionControllerProvider);
  if (connection is! RemoteConnected ||
      connection.peerFingerprint != device.fingerprint) {
    _snack(context, l10n.transferConnectToPick(device.name));
    return null;
  }
  final writable = [
    for (final r in connection.roots)
      if (!r.readOnly) r,
  ];
  if (writable.isEmpty) {
    _snack(context, l10n.transferNoWritableFolder(device.name));
    return null;
  }
  final folder = await showRemoteFolderPicker(
    context,
    source: container.read(remoteSourceProvider(device.fingerprint)),
    device: device.name,
    roots: writable,
  );
  if (folder == null) return null;
  return SwipeAction(
    SwipeActionType.sendToDevice,
    deviceId: device.id,
    targetFolder: folder,
  );
}
