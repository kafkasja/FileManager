import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/cloud/data/cloud_items_repository.dart';
import 'package:kfm/features/cloud/data/cloud_providers.dart';
import 'package:kfm/features/cloud/data/cloud_upload_runner.dart';
import 'package:kfm/features/privacy/ui/move_warning_dialog.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';
import 'package:kfm/features/transfers/ui/permanent_move_confirm.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

/// Copy or safe-move [files] to the cloud destination [destinationId]
/// (TASK-X3): the permanent-delete confirm (N11), the location questions
/// (X2 option / `ACCESS_MEDIA_LOCATION`), then the runner. A move's
/// originals follow the delete setting only after each copy's read-back
/// matched, once per job.
Future<void> startCloudJobFlow(
  BuildContext context,
  WidgetRef ref,
  List<FileRef> files,
  int destinationId, {
  required bool move,
  bool fromSelection = false,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final runner = ref.read(cloudUploadRunnerProvider);
  if (runner == null || files.isEmpty) return;
  final readable = files.where(cloudCanRead).toList();
  if (readable.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.cloudNothingToSend)));
    return;
  }
  final dest = await ref
      .read(cloudDestinationsRepositoryProvider)
      .byId(destinationId);
  if (dest == null || !dest.isActive || !context.mounted) return;

  var copyOnly = !move;
  final settings = ref.read(settingsRepositoryProvider);
  final media = readable.any((f) => f.isMedia);
  // X2's decision is taken once, here: the job keeps it even if the
  // setting changes while it runs (the warning below was about it).
  final strip = await settings.read(AppSettings.privacyStripLocation);
  if (media) {
    if (strip) {
      // X2: the copies lose their location; a move would delete the only
      // files that have it.
      if (!copyOnly) {
        if (!context.mounted) return;
        final choice = await showLocationMoveWarning(context);
        if (choice == null) return;
        if (choice == LocationMoveChoice.copyInstead) copyOnly = true;
      }
    } else if (!await _mediaLocation(ref) && !copyOnly) {
      if (!context.mounted) return;
      final go = await _askGpsMove(context, ref);
      if (go != true) return;
    }
  }

  var deleteMode = DeleteMode.trash;
  if (!copyOnly) {
    // `deleteModeSettingProvider` hangs in Riverpod 3 (B4).
    deleteMode = DeleteMode.parse(await settings.read(AppSettings.deleteMode));
    if (deleteMode == DeleteMode.permanent) {
      if (!context.mounted) return;
      final chosen = await confirmPermanentMove(
        context,
        count: readable.length,
      );
      if (chosen == null) return;
      deleteMode = chosen;
    }
  }

  final CloudJobHandle handle;
  try {
    handle = await runner.start(
      CloudJobRequest(
        files: readable,
        destinationId: destinationId,
        mode: copyOnly ? CloudItemMode.copy : CloudItemMode.move,
        deleteMode: deleteMode,
        stripLocation: strip,
      ),
    );
  } on Object catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    return;
  }
  if (!copyOnly && fromSelection) {
    ref
        .read(selectionControllerProvider.notifier)
        .dropAll(readable.map((f) => f.id));
  }
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        copyOnly
            ? l10n.cloudStartedCopy(readable.length, dest.label)
            : l10n.cloudStartedMove(readable.length, dest.label),
      ),
      persist: false,
      action: context.mounted
          ? SnackBarAction(
              label: l10n.externalJobView,
              onPressed: () => unawaited(context.push(AppRoutes.transfers)),
            )
          : null,
    ),
  );
  unawaited(
    handle.done.then(
      (summary) {
        if (summary == null) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              summary.kept > 0
                  ? l10n.cloudOriginalsKept(summary.kept)
                  : l10n.cloudOriginalsDeleted(summary.deleted),
            ),
          ),
        );
      },
      onError: (Object e) {
        messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      },
    ),
  );
}

/// Whether original photo bytes (with GPS) can be read; asks once when
/// Android can still ask (it often grants without a dialog).
Future<bool> _mediaLocation(WidgetRef ref) async {
  final perms = ref.read(permissionServiceProvider);
  if (await perms.hasMediaLocation()) return true;
  if (await perms.mediaLocationPermanentlyDenied()) return false;
  return await perms.requestMediaLocation();
}

/// "Location data may be removed from the cloud copy, and the original
/// will be deleted." True = go ahead (allowed now, or Move anyway).
Future<bool?> _askGpsMove(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final choice = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.location_off_outlined),
      title: Text(l10n.cloudGpsMoveTitle),
      content: Text(l10n.cloudGpsMoveWarning),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const ValueKey('cloud-gps-move-anyway'),
          onPressed: () => Navigator.pop(context, 'anyway'),
          child: Text(l10n.cloudGpsMoveAnyway),
        ),
        FilledButton(
          key: const ValueKey('cloud-gps-allow'),
          autofocus: true,
          onPressed: () => Navigator.pop(context, 'allow'),
          child: Text(l10n.cloudGpsAllow),
        ),
      ],
    ),
  );
  switch (choice) {
    case 'anyway':
      return true;
    case 'allow':
      final perms = ref.read(permissionServiceProvider);
      if (await perms.requestMediaLocation()) return true;
      // "Don't ask again": only the app settings page helps; the move
      // waits for the user to start it again.
      await perms.openAppSettings();
      return false;
    default:
      return null;
  }
}
