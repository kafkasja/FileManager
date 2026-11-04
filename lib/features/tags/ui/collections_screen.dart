import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/tags/domain/tag.dart';
import 'package:kfm/features/tags/ui/tag_edit_dialog.dart';
import 'package:kfm/features/tags/ui/tag_undo.dart';

/// Browse → Tags & favorites (TASK-B9): the Favorites card, then every tag
/// with its visible file count. Tap opens the files; long-press or ⋮ edits
/// or deletes a tag.
class CollectionsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final tags = (ref.watch(tagsByIdProvider).value?.values.toList() ?? <Tag>[])
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final counts = ref.watch(tagCountsProvider).value ?? const <int, int>{};
    return Scaffold(
      appBar: AppBar(title: Text(l10n.collectionsTitle)),
      body: ListView(
        padding: EdgeInsetsDirectional.only(bottom: spacing * 2),
        children: [
          const _FavoritesCard(),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              spacing * 2,
              spacing * 2,
              spacing * 2,
              spacing,
            ),
            child: Text(
              l10n.collectionsTags,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (tags.isEmpty)
            Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
              child: Text(l10n.collectionsEmpty),
            ),
          for (final t in tags)
            ListTile(
              leading: Icon(Icons.label, color: Color(t.color)),
              title: Text(t.name),
              subtitle: Text(l10n.collectionsFileCount(counts[t.id] ?? 0)),
              onTap: () => unawaited(
                context.push<void>(AppRoutes.collectionTagFor(t.id)),
              ),
              onLongPress: () => unawaited(showTagEditDialog(context, t)),
              trailing: PopupMenuButton<_TagMenu>(
                tooltip: l10n.collectionsTagMenu,
                onSelected: (action) => unawaited(switch (action) {
                  _TagMenu.edit => showTagEditDialog(context, t),
                  _TagMenu.delete => confirmDeleteTag(context, t),
                }),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _TagMenu.edit,
                    child: Text(l10n.tagMenuEdit),
                  ),
                  PopupMenuItem(
                    value: _TagMenu.delete,
                    child: Text(l10n.tagMenuDelete),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

enum _TagMenu { edit, delete }

class _FavoritesCard extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final radius = BorderRadius.circular(context.tokens.radius);
    final count =
        ref
            .watch(browseCountProvider(const FavoritesCollection().query))
            .value ??
        0;
    final thumbs = ref.watch(favoriteThumbsProvider).value ?? const [];
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        spacing * 2,
        spacing,
        spacing * 2,
        0,
      ),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              unawaited(context.push<void>(AppRoutes.collectionFavorites)),
          child: Padding(
            padding: EdgeInsets.all(spacing * 1.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, color: scheme.error),
                    SizedBox(width: spacing),
                    Expanded(
                      child: Text(
                        l10n.collectionsFavorites,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    // Wraps instead of pushing the row wider (big text).
                    Flexible(
                      child: Text(
                        l10n.collectionsFileCount(count),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                if (thumbs.isNotEmpty) ...[
                  SizedBox(height: spacing),
                  Row(
                    children: [
                      for (var i = 0; i < 4; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                              end: i < 3 ? spacing / 2 : 0,
                            ),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: i < thumbs.length
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        context.tokens.radius / 2,
                                      ),
                                      child: Thumbnail(file: thumbs[i]),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Swipe setups that use [tagId] in an "Add tag" direction or button:
/// preset names, plus the current setup.
Future<List<String>> tagUsages(
  ProviderContainer container,
  int tagId,
  String currentSetupLabel,
) async {
  bool uses(SwipeLayout layout) => [
    ...layout.directions.values,
    ...layout.actionBar,
  ].any((a) => a.type == SwipeActionType.addTag && a.tagId == tagId);

  // The kept-alive list: a fresh stream's `.first` can stall (B9 tests).
  final presets = await container.read(presetsProvider.future);
  final current = SwipeLayout.decode(
    await container
        .read(settingsRepositoryProvider)
        .read(AppSettings.swipeLayoutCurrent),
  );
  return [
    for (final p in presets)
      if (p is Preset && uses(p.layout)) p.name,
    if (uses(current)) currentSetupLabel,
  ];
}

/// Confirms (with the swipe-setup warning) and deletes [tag]; Undo brings it
/// back with the same id and files.
Future<void> confirmDeleteTag(BuildContext context, Tag tag) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final count = container.read(tagCountsProvider).value?[tag.id] ?? 0;
  final List<String> usedIn;
  try {
    usedIn = await tagUsages(container, tag.id, l10n.tagUsedCurrentSetup);
  } on Object {
    messenger.showSnackBar(SnackBar(content: Text(l10n.tagWriteError)));
    return;
  }
  if (!context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      // Scrolls on short screens (a phone in landscape, big text).
      scrollable: true,
      title: Text(l10n.tagDeleteTitle(tag.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.tagDeleteBody(count)),
          if (usedIn.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.tagDeleteUsedIn(usedIn.join(', '))),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.tagDeleteConfirm),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final repo = container.read(tagRepositoryProvider);
  try {
    final snapshot = await queuedTagWrite(
      container,
      () => repo.deleteWithSnapshot(tag.id),
    );
    showTagUndo(
      messenger,
      l10n.tagDeleted(tag.name),
      undoLabel: l10n.undoAction,
      undo: () =>
          queuedTagWrite(container, () => repo.restoreSnapshot(snapshot)),
    );
  } on Object {
    return; // Published on dbWriteErrorsProvider.
  }
}
