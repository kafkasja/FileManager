import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/routing_file_source.dart';
import 'package:kfm/core/files/staging_dir.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:kfm/features/external_storage/ui/place_labels.dart';
import 'package:kfm/features/folders/data/fat_names.dart';
import 'package:kfm/features/folders/data/local_job_providers.dart';
import 'package:kfm/features/folders/data/local_job_runner.dart';
import 'package:kfm/features/folders/data/local_jobs_dao.dart';
import 'package:kfm/features/folders/ui/folder_picker_sheet.dart';
import 'package:kfm/features/transfers/ui/permanent_move_confirm.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

/// Staging room kept on top of the largest file.
const int _stagingMargin = 64 * 1024 * 1024;

/// True when moving/copying [files] into [target] crosses places (U2): a
/// local job runs instead of B4's in-place runner.
bool needsLocalJob(WidgetRef ref, List<FileRef> files, String target) {
  final fs = routingOf(ref.read(fileSourceProvider));
  return fs != null &&
      ref.read(localJobRunnerProvider) != null &&
      files.any((f) => fs.isCrossPlace(f, target));
}

/// The place browser's Copy to / Move to: the B4 picker (with Places),
/// then a local job (or nothing when dismissed).
Future<void> pickTargetAndStartLocalJob(
  BuildContext context,
  WidgetRef ref,
  List<FileRef> files, {
  required bool move,
}) async {
  final folders = {for (final f in files) f.folderPath};
  final target = await showFolderPicker(
    context,
    mode: move ? FolderPickerMode.move : FolderPickerMode.copy,
    disabledFolder: move && folders.length == 1 ? folders.single : null,
  );
  if (target == null || !context.mounted) return;
  await startLocalJobFlow(context, ref, files, target, move: move);
}

/// Pre-checks and questions, then starts the job (TASK-U2): a permanent
/// delete setting asks N11's confirmation (move), space on the target and
/// in the staging folder, one collision question for the whole job.
Future<void> startLocalJobFlow(
  BuildContext context,
  WidgetRef ref,
  List<FileRef> files,
  String target, {
  required bool move,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final runner = ref.read(localJobRunnerProvider);
  final fs = ref.read(fileSourceProvider);
  if (runner == null || files.isEmpty) return;
  void say(String text) =>
      messenger.showSnackBar(SnackBar(content: Text(text)));

  DeleteMode? deleteMode;
  if (move) {
    // `deleteModeSettingProvider` hangs in Riverpod 3 (B4).
    deleteMode = DeleteMode.parse(
      await ref.read(settingsRepositoryProvider).read(AppSettings.deleteMode),
    );
    if (deleteMode == DeleteMode.permanent) {
      if (!context.mounted) return;
      deleteMode = await confirmPermanentMove(context, count: files.length);
      if (deleteMode == null) return;
    }
  }

  // Space on the target (null = unknown: the place's volume stats, else
  // ENOSPC per file).
  final places = ref.read(placesProvider).value ?? const [];
  final placeId =
      routingOf(fs)?.placeOfFolder(target) ?? placeIdOfFolder(target);
  final place = places.where((p) => p.id == placeId).firstOrNull;
  final total = files.fold(0, (s, f) => s + f.sizeBytes);
  final free = await fs.freeBytes(target) ?? place?.freeBytes;
  if (free != null && total * 1.01 > free) {
    say(
      l10n.externalNotEnoughSpace(
        place == null ? target : placeLabel(l10n, place),
      ),
    );
    return;
  }
  final largest = files.fold(0, (m, f) => f.sizeBytes > m ? f.sizeBytes : m);
  final stagingFree = await fs.freeBytes((await transferStagingDir()).path);
  if (stagingFree != null && stagingFree < largest + _stagingMargin) {
    say(l10n.externalStagingNoSpace);
    return;
  }

  // One collision question per job.
  final removable = placeId != 'primary';
  final existing = await _existingNames(ref, target);
  final clashes = files
      .where(
        (f) => existing.contains(
          (removable ? fatSafeName(f.name) : f.name).toLowerCase(),
        ),
      )
      .length;
  var policy = CollisionPolicy.keepBoth;
  if (clashes > 0) {
    if (!context.mounted) return;
    final chosen = await _askCollision(context, clashes);
    if (chosen == null) return;
    policy = chosen;
  }

  await runner.start(
    LocalJobRequest(
      mode: move ? LocalJobMode.move : LocalJobMode.copy,
      files: files,
      targetFolder: target,
      collision: policy,
      deleteMode: deleteMode,
    ),
  );
  if (!context.mounted) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        move
            ? l10n.externalJobStartedMove(files.length)
            : l10n.externalJobStartedCopy(files.length),
      ),
      persist: false,
      action: SnackBarAction(
        label: l10n.externalJobView,
        onPressed: () => unawaited(context.push(AppRoutes.transfers)),
      ),
    ),
  );
}

/// Lower-case names already in [target].
Future<Set<String>> _existingNames(WidgetRef ref, String target) async {
  final fs = ref.read(fileSourceProvider);
  try {
    final routing = routingOf(fs);
    if (routing != null && routing.saf.locator.owns(target)) {
      final l = await routing.saf.listChildren(target, includeHidden: true);
      return {for (final f in l.files) f.name.toLowerCase()};
    }
    final l = await fs
        .scan(
          query: FileQuery(
            rootPath: target,
            recursive: false,
            includeHidden: true,
          ),
        )
        .expand((p) => p)
        .toList();
    return {for (final f in l) f.name.toLowerCase()};
  } on Object {
    return const {}; // the job still never overwrites (keep both)
  }
}

Future<CollisionPolicy?> _askCollision(BuildContext context, int count) {
  final l10n = context.l10n;
  return showDialog<CollisionPolicy>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.externalCollisionTitle(count)),
      content: Text(l10n.externalApplyToAll),
      actions: [
        TextButton(
          key: const ValueKey('collision-skip'),
          onPressed: () => Navigator.pop(context, CollisionPolicy.skip),
          child: Text(l10n.externalCollisionSkip),
        ),
        TextButton(
          key: const ValueKey('collision-replace'),
          onPressed: () => Navigator.pop(context, CollisionPolicy.replace),
          child: Text(l10n.externalCollisionReplace),
        ),
        FilledButton(
          key: const ValueKey('collision-keep-both'),
          onPressed: () => Navigator.pop(context, CollisionPolicy.keepBoth),
          child: Text(l10n.externalCollisionKeepBoth),
        ),
      ],
    ),
  );
}
