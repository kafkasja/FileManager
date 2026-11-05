import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/adaptive_sheet.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/browse/ui/widgets/file_actions_menu.dart';
import 'package:kfm/features/selection/ui/selection_actions.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/tags/ui/file_tags_sheet.dart';
import 'package:kfm/features/tags/ui/tag_picker_sheet.dart';
import 'package:kfm/features/tags/ui/tag_remove_sheet.dart';
import 'package:kfm/features/tags/ui/tag_undo.dart';

/// Adds a picked (or new) tag to [ids], with Undo (TASK-B9).
Future<void> addTagToFiles(
  BuildContext context,
  WidgetRef ref,
  List<String> ids,
) async {
  if (ids.isEmpty) return;
  final tagId = await showTagPicker(context);
  if (tagId == null || !context.mounted) return;
  await addTagIdToFiles(context, tagId, ids);
}

/// Adds tag [tagId] to [ids] and shows the summary with Undo. Undo removes
/// it only from the files that didn't have it.
Future<void> addTagIdToFiles(
  BuildContext context,
  int tagId,
  List<String> ids, {
  bool quiet = false,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final repo = container.read(tagRepositoryProvider);
  final List<String> added;
  final String name;
  try {
    added = await queuedTagWrite(container, () => repo.addToFiles(tagId, ids));
    name = await _tagName(container, tagId);
  } on Object {
    return; // Published on dbWriteErrorsProvider.
  }
  if (quiet) return;
  showTagUndo(
    messenger,
    l10n.tagAddedSummary(added.length, name),
    undoLabel: l10n.undoAction,
    undo: added.isEmpty
        ? null
        : () => queuedTagWrite(container, () => repo.removeRows(tagId, added)),
  );
}

/// [tagId]'s name, also for a tag just created (not in [tagsByIdProvider]
/// yet).
Future<String> _tagName(ProviderContainer container, int tagId) async =>
    container.read(tagsByIdProvider).value?[tagId]?.name ??
    (await container.read(tagRepositoryProvider).byId(tagId))?.name ??
    '';

/// Removes tag [tagId] from [ids], with Undo (puts back the exact rows).
Future<void> removeTagIdFromFiles(
  BuildContext context,
  int tagId,
  List<String> ids, {
  bool quiet = false,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final repo = container.read(tagRepositoryProvider);
  final name = container.read(tagsByIdProvider).value?[tagId]?.name ?? '';
  final List<FileTagRow> rows;
  try {
    rows = await queuedTagWrite(
      container,
      () => repo.removeFromFiles(tagId, ids),
    );
  } on Object {
    return; // Published on dbWriteErrorsProvider.
  }
  if (quiet) return;
  showTagUndo(
    messenger,
    l10n.tagRemovedSummary(rows.length, name),
    undoLabel: l10n.undoAction,
    undo: rows.isEmpty
        ? null
        : () => queuedTagWrite(container, () => repo.reinsert(rows)),
  );
}

/// Picks one of the tags on [ids] and removes it from them.
Future<void> removeTagFromFiles(
  BuildContext context,
  WidgetRef ref,
  List<String> ids,
) async {
  if (ids.isEmpty) return;
  final tagId = await showTagRemoveSheet(context, ids);
  if (tagId == null || !context.mounted) return;
  await removeTagIdFromFiles(context, tagId, ids);
}

/// Adds or removes [ids] from Favorites, with Undo of exactly what changed.
Future<void> setFavorites(
  BuildContext context,
  List<String> ids, {
  required bool favorite,
}) async {
  if (ids.isEmpty) return;
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final repo = container.read(favoritesRepositoryProvider);
  try {
    if (favorite) {
      final added = await queuedTagWrite(container, () => repo.addFiles(ids));
      showTagUndo(
        messenger,
        l10n.favoriteAddedSummary(added.length),
        undoLabel: l10n.undoAction,
        undo: added.isEmpty
            ? null
            : () => queuedTagWrite(container, () => repo.removeIds(added)),
      );
    } else {
      final rows = await queuedTagWrite(container, () => repo.removeFiles(ids));
      showTagUndo(
        messenger,
        l10n.favoriteRemovedSummary(rows.length),
        undoLabel: l10n.undoAction,
        undo: rows.isEmpty
            ? null
            : () => queuedTagWrite(container, () => repo.reinsert(rows)),
      );
    }
  } on Object {
    return; // Published on dbWriteErrorsProvider.
  }
}

/// Whether [id] is a favorite, from the loaded [favoriteIdsProvider].
bool isFavoriteIn(BuildContext context, String id) =>
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(favoriteIdsProvider).value?.contains(id) ??
    false;

Future<void> _toggleFavorite(
  BuildContext context,
  WidgetRef ref,
  FileRef f,
) async {
  // The database, not the (possibly a tick old) loaded set.
  final bool isFavorite;
  try {
    isFavorite = await ref.read(favoritesRepositoryProvider).isFavorite(f.id);
  } on Object {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.tagWriteError)));
    }
    return;
  }
  if (!context.mounted) return;
  await setFavorites(context, [f.id], favorite: !isFavorite);
}

/// B9's ⋮ file menu items: favorite toggle and the Tags sheet.
final List<FileMenuItem> tagFileMenuItems = [
  FileMenuItem(
    order: 70,
    label: (c) => c.l10n.fileMenuFavoriteAdd,
    labelFor: (c, f) => isFavoriteIn(c, f.id)
        ? c.l10n.fileMenuFavoriteRemove
        : c.l10n.fileMenuFavoriteAdd,
    icon: Icons.favorite_border,
    onSelected: _toggleFavorite,
  ),
  FileMenuItem(
    order: 71,
    label: (c) => c.l10n.fileMenuTags,
    icon: Icons.label_outline,
    onSelected: (context, ref, f) => showFileTagsSheet(context, f.id),
  ),
];

/// B9's selection bar "More…" entry: one item opening a sheet with
/// Add to / Remove from favorites, Add tag…, Remove tag… (keeps the menu
/// short).
final List<SelectionAction> tagSelectionActions = [
  SelectionAction(
    id: 'b9.tags',
    order: 70,
    label: (c) => c.l10n.selectionTagsMenu,
    icon: Icons.label_outline,
    run: (context, ref, ids) async {
      final l10n = context.l10n;
      final choice = await showAdaptiveSheet<_SelectionTagChoice>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (choice, icon, label) in [
                (
                  _SelectionTagChoice.favorite,
                  Icons.favorite_border,
                  l10n.fileMenuFavoriteAdd,
                ),
                (
                  _SelectionTagChoice.unfavorite,
                  Icons.heart_broken_outlined,
                  l10n.fileMenuFavoriteRemove,
                ),
                (
                  _SelectionTagChoice.addTag,
                  Icons.new_label_outlined,
                  l10n.selectionTagAdd,
                ),
                (
                  _SelectionTagChoice.removeTag,
                  Icons.label_off_outlined,
                  l10n.selectionTagRemove,
                ),
              ])
                ListTile(
                  leading: Icon(icon),
                  title: Text(label),
                  onTap: () => Navigator.of(context).pop(choice),
                ),
            ],
          ),
        ),
      );
      if (choice == null || !context.mounted) return;
      await switch (choice) {
        _SelectionTagChoice.favorite => setFavorites(
          context,
          ids,
          favorite: true,
        ),
        _SelectionTagChoice.unfavorite => setFavorites(
          context,
          ids,
          favorite: false,
        ),
        _SelectionTagChoice.addTag => addTagToFiles(context, ref, ids),
        _SelectionTagChoice.removeTag => removeTagFromFiles(context, ref, ids),
      };
    },
  ),
];

enum _SelectionTagChoice { favorite, unfavorite, addTag, removeTag }
