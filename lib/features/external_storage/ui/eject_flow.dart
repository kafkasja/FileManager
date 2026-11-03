import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/routing_file_source.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/volumes/volumes_channel.dart';
import 'package:kfm/core/platform/volumes/volumes_providers.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/features/external_storage/data/eject_watch.dart';
import 'package:kfm/features/external_storage/data/tracked_file_source.dart';
import 'package:kfm/features/external_storage/data/volume_activity_tracker.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:kfm/features/external_storage/ui/place_labels.dart';
import 'package:kfm/features/folders/data/local_job_providers.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// U3: Eject on a removable place. Android apps can't unmount volumes, so
/// KFM finishes (or pauses) its own work on the place, closes its readers
/// and hands off to the system storage screen; the unmount is confirmed
/// by U1's place events (the `PlaceEjected` snackbar). Cameras are closed
/// right away.
Future<void> ejectPlace(
  BuildContext context,
  WidgetRef ref,
  StoragePlace place,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final tracker = ref.read(volumeActivityTrackerProvider.notifier);
  final id = place.id;
  if (ref.read(volumeActivityTrackerProvider).isEjecting(id)) return;

  // 1. Local jobs on this place: wait, or pause them and go on.
  final runner = ref.read(localJobRunnerProvider);
  final jobs = await runner?.activeJobsOn(id) ?? const <String>[];
  if (!context.mounted) return;
  if (jobs.isNotEmpty) {
    final pause = await _confirmPauseJobs(context, jobs.length);
    if (pause != true || !context.mounted) return;
    await runner!.pauseWhere(id);
    if (!context.mounted) return;
  }

  // 2. New work refused; readers closed.
  tracker.beginEject(id);
  await _closeReaders(ref, id);
  if (!context.mounted) {
    tracker.cancelEject(id);
    return;
  }

  // 3. Wait for what's still running (a batch commit, the current file).
  if (ref.read(volumeActivityTrackerProvider).activeCount(id) > 0) {
    final idle = await _waitForIdle(context, place);
    if (idle != true || !context.mounted) {
      tracker.cancelEject(id);
      return;
    }
  }

  // Cameras: no OS eject; closing the session is enough.
  if (place.kind == PlaceKind.camera) {
    try {
      await ref.read(mtpPlatformProvider)?.close(id.substring('mtp:'.length));
    } finally {
      // The next op re-opens the camera (Android keeps the permission).
      tracker.cancelEject(id);
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.ejectCameraSafe)));
    return;
  }

  // 4. Writes are already durable (dart:io flush + close, SAF close/fsync).
  //    Windows (PL1): the app ejects the drive itself.
  final volumes = ref.read(volumesPlatformProvider);
  if (volumes != null && volumes.ejectsDirectly) {
    await ejectDirectly(ref, place, volumes, messenger, l10n);
    return;
  }
  //    Android: hand off to the system's Eject.
  final go = await _showHint(context, place);
  if (go != true || !context.mounted) {
    tracker.cancelEject(id);
    return;
  }
  await openEjectSettings(ref, place, messenger, l10n.ejectFailed);
}

/// Opens the system storage screen and waits for the unmount
/// (`EjectWatch`). A failure cancels the eject.
Future<void> openEjectSettings(
  WidgetRef ref,
  StoragePlace place,
  ScaffoldMessengerState messenger,
  String failedMessage,
) async {
  final watch = ref.read(ejectWatchProvider)..start(place);
  try {
    final volumes = ref.read(volumesPlatformProvider);
    if (volumes == null) throw StateError('no volumes platform');
    await volumes.openStorageSettings();
  } on Object catch (e, st) {
    developer.log(
      'storage settings failed',
      name: 'kfm.eject',
      error: e,
      stackTrace: st,
    );
    watch.stop(place.id);
    ref.read(volumeActivityTrackerProvider.notifier).cancelEject(place.id);
    messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
  }
}

/// PL1: ejects [place] through [volumes] (Windows shows its own "Safe to
/// remove"). Success is confirmed by U1's place events (`PlaceEjected`); a
/// refusal cancels the eject and says why. KFM's own directory watchers
/// under the drive are stopped first (an open watcher handle makes Windows
/// refuse the eject as "in use") and started again when it fails.
@visibleForTesting
Future<void> ejectDirectly(
  WidgetRef ref,
  StoragePlace place,
  VolumesPlatform volumes,
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
) async {
  final watch = ref.read(ejectWatchProvider)..start(place);
  final pauses = ref.read(watchPausesProvider);
  final root = place.rootPath;
  VolumeEjectError? error;
  try {
    if (root == null) throw StateError('no root for ${place.id}');
    await pauses.pause(root);
    error = await volumes.eject(root);
  } on Object catch (e, st) {
    developer.log('eject failed', name: 'kfm.eject', error: e, stackTrace: st);
    error = VolumeEjectError.failed;
  }
  // The drive is gone after a successful eject (the watchers find nothing
  // to restart); after a refusal they watch it again.
  if (root != null) await pauses.resume(root);
  if (error == null) return;
  watch.stop(place.id);
  ref.read(volumeActivityTrackerProvider.notifier).cancelEject(place.id);
  final label = placeLabel(l10n, place);
  messenger.showSnackBar(
    SnackBar(
      content: Text(switch (error) {
        VolumeEjectError.inUse => l10n.ejectWindowsInUse(label),
        VolumeEjectError.notEjectable ||
        VolumeEjectError.failed => l10n.ejectWindowsFailed(label),
      }),
    ),
  );
}

Future<void> _closeReaders(WidgetRef ref, String placeId) async {
  final fs = ref.read(fileSourceProvider);
  final placeOf = switch (fs) {
    final TrackedFileSource t => t.placeOfFile,
    _ => routingOf(fs)?.placeOfFile ?? placeIdOf,
  };
  bool onPlace(FileRef f) => placeOf(f) == placeId;
  if (ref.exists(videoControllerPoolProvider)) {
    await ref.read(videoControllerPoolProvider).disposeWhere(onPlace);
  }
  if (ref.exists(thumbnailCacheProvider)) {
    ref.read(thumbnailCacheProvider).value?.cancelWhere(onPlace);
  }
}

Future<bool?> _confirmPauseJobs(BuildContext context, int count) {
  final l10n = context.l10n;
  final spacing = context.tokens.spacing;
  return showModalBottomSheet<bool>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.all(spacing * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.ejectRunningJobs(count),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: spacing),
            Text(l10n.ejectRunningJobsBody),
            SizedBox(height: spacing * 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const ValueKey('eject-wait'),
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.ejectWait),
                ),
                SizedBox(width: spacing),
                FilledButton(
                  key: const ValueKey('eject-pause'),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.ejectPauseAndEject),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// A spinner until nothing runs on [place]; true when idle, false when
/// cancelled.
Future<bool?> _waitForIdle(BuildContext context, StoragePlace place) =>
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WaitDialog(place: place),
    );

class _WaitDialog extends ConsumerStatefulWidget {
  const new({required this.place});

  final StoragePlace place;

  @override
  ConsumerState<_WaitDialog> createState() => _WaitDialogState();
}

class _WaitDialogState extends ConsumerState<_WaitDialog> {
  @override
  void initState() {
    super.initState();
    unawaited(
      ref
          .read(volumeActivityTrackerProvider.notifier)
          .whenIdle(widget.place.id)
          .then((_) {
            if (mounted) Navigator.pop(context, true);
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    return AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          SizedBox(width: spacing * 2),
          Expanded(
            child: Text(l10n.ejectWaiting(placeLabel(l10n, widget.place))),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('eject-cancel-wait'),
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

Future<bool?> _showHint(BuildContext context, StoragePlace place) {
  final l10n = context.l10n;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.ejectHintTitle(placeLabel(l10n, place))),
      content: Text(l10n.ejectHint),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('eject-open-settings'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.ejectOpenSettings),
        ),
      ],
    ),
  );
}
