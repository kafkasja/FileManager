import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/desktop/browse/desktop_clipboard.dart';
import 'package:kfm/desktop/widgets/desktop_drag.dart';
import 'package:kfm/features/folders/ui/file_op_flow.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_feedback.dart';
import 'package:kfm/features/tags/ui/tag_actions.dart';
import 'package:kfm/features/transfers/ui/send_flow.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_drops.g.dart';

/// The app's one drag & drop controller (TASK-PL3 step 4).
@Riverpod(keepAlive: true)
DesktopDragController desktopDragController(Ref ref) {
  final c = DesktopDragController();
  ref.onDispose(c.dispose);
  return c;
}

/// Sort drags: [action] on [files] of the local deck, one undo row each
/// (like the toolbar buttons).
void applySortDrop(
  BuildContext context,
  WidgetRef ref,
  List<FileRef> files,
  SwipeAction action,
) {
  final result = ref
      .read(swipeDeckControllerProvider.notifier)
      .applyToFiles(files, action);
  if (result.problem case final p? when context.mounted) {
    SwipeFeedback.explain(context, p);
  }
}

String _leaf(String path) {
  final i = path.lastIndexOf('/');
  return i < 0 ? path : path.substring(i + 1);
}

String _parentOf(String path) {
  final i = path.lastIndexOf('/');
  return i <= 0 ? path.substring(0, i + 1) : path.substring(0, i);
}

/// A folder (sidebar place, Browse folder or the open folder): Explorer
/// files are copied in; Browse files move (Ctrl = copy) through B4 / U2;
/// Sort files get a one-off Move to / Copy to action.
DropOfferBuilder folderDropOffer(
  BuildContext context,
  WidgetRef ref,
  String folder, {
  String? name,
}) => (data, {required copy}) {
  final l10n = context.l10n;
  final label = name ?? _leaf(folder);
  switch (data.origin) {
    case DragOrigin.explorer:
      return DropOffer(
        label: l10n.desktopDropCopyTo(label),
        onDrop: () => importPaths(context, ref, data.paths, folder),
      );
    case DragOrigin.browse:
      // A folder never goes into itself (or one of its subfolders); a move
      // into the folder everything already is in does nothing.
      final lower = folder.toLowerCase();
      if (data.folders.any((d) {
        final l = d.toLowerCase();
        return lower == l || lower.startsWith('$l/');
      })) {
        return null;
      }
      if (!copy &&
          data.files.every((f) => f.folderPath == folder) &&
          data.folders.every((d) => _parentOf(d) == folder)) {
        return null;
      }
      return DropOffer(
        label: copy
            ? l10n.desktopDropCopyTo(label)
            : l10n.desktopDropMoveTo(label),
        ctrlCopies: true,
        onDrop: () async {
          if (!context.mounted) return;
          await pasteFiles(
            context,
            ref,
            DesktopClip(data.files, cut: !copy, folders: data.folders),
            folder,
          );
        },
      );
    case DragOrigin.sort:
      return DropOffer(
        label: copy
            ? l10n.desktopDropCopyTo(label)
            : l10n.desktopDropMoveTo(label),
        ctrlCopies: true,
        onDrop: () async => applySortDrop(
          context,
          ref,
          data.files,
          SwipeAction(
            copy ? SwipeActionType.copyTo : SwipeActionType.moveTo,
            targetFolder: folder,
          ),
        ),
      );
  }
};

/// A tag in the sidebar.
DropOfferBuilder tagDropOffer(
  BuildContext context,
  WidgetRef ref,
  int tagId,
  String name,
) => (data, {required copy}) {
  if (!data.fromKfm || !data.filesOnly) return null;
  return DropOffer(
    label: context.l10n.desktopDropTag(name),
    onDrop: () async {
      if (!context.mounted) return;
      if (data.origin == DragOrigin.sort) {
        applySortDrop(
          context,
          ref,
          data.files,
          SwipeAction(SwipeActionType.addTag, tagId: tagId),
        );
      } else {
        await addTagIdToFiles(context, tagId, [
          for (final f in data.files) f.id,
        ]);
      }
    },
  );
};

/// Favorites in the sidebar.
DropOfferBuilder favoriteDropOffer(BuildContext context, WidgetRef ref) =>
    (data, {required copy}) {
      if (!data.fromKfm || !data.filesOnly) return null;
      return DropOffer(
        label: context.l10n.desktopDropFavorite,
        onDrop: () async {
          if (!context.mounted) return;
          if (data.origin == DragOrigin.sort) {
            applySortDrop(
              context,
              ref,
              data.files,
              const SwipeAction(SwipeActionType.favorite),
            );
          } else {
            await setFavorites(context, [
              for (final f in data.files) f.id,
            ], favorite: true);
          }
        },
      );
    };

/// Trash in the sidebar: the user's delete mode (Sort: the Trash action).
DropOfferBuilder trashDropOffer(BuildContext context, WidgetRef ref) =>
    (data, {required copy}) {
      if (!data.fromKfm || !data.filesOnly) return null;
      return DropOffer(
        label: context.l10n.desktopDropTrash,
        onDrop: () async {
          if (!context.mounted) return;
          if (data.origin == DragOrigin.sort) {
            applySortDrop(context, ref, data.files, SwipeAction.trash);
          } else {
            await deleteFiles(context, ref, data.files);
          }
        },
      );
    };

/// Devices in the sidebar: N12 "Send to…".
DropOfferBuilder devicesDropOffer(BuildContext context, WidgetRef ref) =>
    (data, {required copy}) {
      if (!data.fromKfm || !data.filesOnly) return null;
      return DropOffer(
        label: context.l10n.desktopDropSend,
        onDrop: () async {
          if (!context.mounted) return;
          await startSend(context, ref, data.files);
        },
      );
    };

/// Whether `path` is a folder on disk (tests replace it: the fake file
/// source has no disk).
@visibleForTesting
Future<bool> Function(String path) isFolderOnDisk = (path) async =>
    isWindowsHost && await Directory(path).exists();

/// Files and folders from Explorer (a drop, or a Windows clipboard paste)
/// into [folder]: copied (or moved for an Explorer cut, [move]) with B4's
/// collision dialog, progress and Undo; folders with their whole tree.
Future<void> importPaths(
  BuildContext context,
  WidgetRef ref,
  List<String> paths,
  String folder, {
  bool move = false,
}) async {
  final source = ref.read(fileSourceProvider);
  final files = <FileRef>[];
  final folders = <String>[];
  for (final p in paths) {
    if (await isFolderOnDisk(p)) {
      folders.add(p);
      continue;
    }
    final f = await source.statPath(p);
    if (f != null) files.add(f);
  }
  if (!context.mounted) return;
  if (files.isEmpty && folders.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.desktopDropNothing)));
    return;
  }
  await pasteFiles(
    context,
    ref,
    DesktopClip(files, cut: move, folders: folders),
    folder,
  );
}
