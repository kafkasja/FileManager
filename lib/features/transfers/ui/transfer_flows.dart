import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/remote_file_source.dart';
import 'package:kfm/features/connect/data/remote_source_provider.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/remote_browse_screen.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/folders/ui/folder_picker_sheet.dart';
import 'package:kfm/features/privacy/domain/location_stripper.dart';
import 'package:kfm/features/privacy/ui/move_warning_dialog.dart';
import 'package:kfm/features/selection/ui/selection_actions.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/transfers/data/transfer_engine.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:kfm/features/transfers/ui/permanent_move_confirm.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

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

/// N9: remote browse selection → "Download": confirms the folder
/// (`Download/<device>` by default, "Change folder" picks another), then
/// queues one job. N11: Copy (default) or Move; a move trashes each
/// original on the other device once its copy is verified.
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
  var mode = TransferMode.copy;
  final choice = await showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.transferDownloadTitle(files.length)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.transferDownloadTo(folder)),
            SizedBox(height: context.tokens.spacing),
            _ModeChoice(mode: mode, onChanged: (m) => setState(() => mode = m)),
            if (mode == TransferMode.move) ...[
              SizedBox(height: context.tokens.spacing),
              Text(
                l10n.transferMoveDownloadNote(peerName),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
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
            child: Text(
              mode == TransferMode.move
                  ? l10n.transferModeMove
                  : l10n.transferDownloadAction,
            ),
          ),
        ],
      ),
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
        mode: mode,
      );
  if (!context.mounted) return;
  _snack(
    context,
    mode == TransferMode.move
        ? l10n.transferMoveDownloadQueued(files.length, peerName)
        : l10n.transferDownloadQueued(files.length, peerName),
    showTransfers: true,
  );
}

/// N11: Copy · Move.
class _ModeChoice extends StatelessWidget {
  const new({required this.mode, required this.onChanged});

  final TransferMode mode;
  final ValueChanged<TransferMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<TransferMode>(
      key: const ValueKey('transfer-mode'),
      segments: [
        ButtonSegment(
          value: TransferMode.copy,
          label: Text(l10n.transferModeCopy),
          icon: const Icon(Icons.copy_outlined),
        ),
        ButtonSegment(
          value: TransferMode.move,
          label: Text(l10n.transferModeMove),
          icon: const Icon(Icons.drive_file_move_outlined),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// N9: local selection → "Send to device": the connected device, a folder
/// in one of its writable roots, then one upload job. N11 [mode] move
/// ("Move to device"): once each copy is verified the originals here
/// follow the delete setting, snapshotted for the job (permanent asks
/// first).
Future<void> startUpload(
  BuildContext context,
  WidgetRef ref,
  List<FileRef> files, {
  TransferMode mode = TransferMode.copy,
}) async {
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
  // X2: with "Remove location" on, photos and videos go without it;
  // otherwise only when KFM can read locations (ACCESS_MEDIA_LOCATION):
  // without it Android redacts GPS from the bytes KFM reads.
  final hasMedia = files.any(LocationStripper.appliesTo);
  final strip =
      hasMedia &&
      await ref
          .read(settingsRepositoryProvider)
          .read(AppSettings.privacyStripLocation);
  final readable =
      !Platform.isAndroid ||
      await ref.read(permissionServiceProvider).hasMediaLocation();
  if (!context.mounted) return;
  var jobMode = mode;
  if (strip && jobMode == TransferMode.move) {
    // The originals are the only files with location: ask first.
    final choice = await showLocationMoveWarning(context);
    if (choice == null || !context.mounted) return;
    if (choice == LocationMoveChoice.copyInstead) jobMode = TransferMode.copy;
  }
  final folder = await showRemoteFolderPicker(
    context,
    source: ref.read(remoteSourceProvider(fp)),
    device: name,
    roots: writable,
    note: strip
        ? l10n.privacyTransferNote
        : (readable || !hasMedia ? null : l10n.transferNoLocation),
  );
  if (folder == null || !context.mounted) return;
  DeleteMode? deleteMode;
  if (jobMode == TransferMode.move) {
    // Read straight from the settings: awaiting the unwatched
    // `deleteModeSettingProvider` hangs in Riverpod 3 (B4).
    deleteMode = DeleteMode.parse(
      await ref.read(settingsRepositoryProvider).read(AppSettings.deleteMode),
    );
    if (!context.mounted) return;
    if (deleteMode == DeleteMode.permanent) {
      deleteMode = await confirmPermanentMove(context, count: files.length);
      if (deleteMode == null || !context.mounted) return;
    }
  }
  final target = splitRemoteFolder(folder);
  await ref
      .read(transferEngineProvider)
      .enqueueUpload(
        files,
        peerFingerprint: fp,
        peerName: name,
        rootId: target.rootId,
        path: target.path,
        mode: jobMode,
        deleteMode: deleteMode,
      );
  if (!context.mounted) return;
  _snack(
    context,
    jobMode == TransferMode.move
        ? l10n.transferMoveQueued(files.length, name)
        : l10n.transferUploadQueued(files.length, name),
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

/// B6 selection bar: "Move to device" (N11): like "Send to device", then
/// the originals here follow the delete setting once verified.
final SelectionAction moveToDeviceSelectionAction = SelectionAction(
  id: 'n11.move',
  order: 7,
  label: (c) => c.l10n.transferMoveToDevice,
  icon: Icons.drive_file_move_outlined,
  run: (context, ref, ids) async {
    final files = await ref.read(mediaIndexDaoProvider).byIds(ids);
    if (!context.mounted) return;
    await startUpload(context, ref, files, mode: TransferMode.move);
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
