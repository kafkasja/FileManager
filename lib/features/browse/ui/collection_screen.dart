import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/browse/ui/widgets/browse_parts.dart';
import 'package:kfm/features/browse/ui/widgets/file_results_view.dart';
import 'package:kfm/features/browse/ui/widgets/sort_sheet.dart';
import 'package:kfm/features/browse/ui/widgets/sources_row.dart';
import 'package:kfm/features/selection/domain/selection_state.dart';
import 'package:kfm/features/selection/ui/selection_bar.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_these.dart';

/// One carousel card's files (a source like WhatsApp, or a recent search):
/// its own type chips, the global Browse sort. "Other apps" lists its
/// folder groups first.
class CollectionScreen extends ConsumerStatefulWidget {
  const new({required this.collection, super.key});

  final BrowseCollection collection;

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  Set<FileKind> _kinds = const {};

  /// "Other apps": the folder group shown (null = the group list).
  String? _group;

  bool get _isOther =>
      widget.collection == const SourceCollection(BrowseSourceChip.other);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final collection = widget.collection;
    final sort = ref.watch(browseViewControllerProvider.select((v) => v.sort));
    final canSeeAll =
        ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ??
        false;
    final spacing = context.tokens.spacing;
    // A recent search keeps its own sort; sources, tags and Favorites
    // follow the Browse sort.
    final scope = switch (collection) {
      SourceCollection() ||
      TagCollection() ||
      FavoritesCollection() => collection.query.copyWith(sort: sort),
      RecentCollection() => collection.query,
    };
    final base = _kinds.isEmpty ? scope : scope.copyWith(kinds: _kinds);
    final group = _group;
    final query = group == null ? base : base.copyWith(folderPath: () => group);
    final needsAccess =
        !canSeeAll &&
        (query.visible(canSeeAllFiles: false) == null ||
            _kinds.any((k) => !mediaKinds.contains(k)) ||
            switch (collection) {
              SourceCollection(:final source) => source.needsAllFiles,
              RecentCollection() ||
              TagCollection() ||
              FavoritesCollection() => false,
            });
    final banner = [
      if (needsAccess) const SliverToBoxAdapter(child: AccessBanner()),
    ];

    final mode =
        ref.watch(selectionControllerProvider.select((s) => s.value?.mode)) ??
        SelectionMode.normal;
    final selector = ref.read(selectionControllerProvider.notifier);
    return PopScope(
      // Back leaves Edit / Select mode, then a folder group.
      canPop: group == null && mode == SelectionMode.normal,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        switch (mode) {
          case SelectionMode.edit:
            selector.exitEdit();
          case SelectionMode.select:
            selector.exitSelect();
          case SelectionMode.normal:
            setState(() => _group = null);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            group == null ? collection.title(l10n) : nameOfFolder(l10n, group),
          ),
          actions: [
            IconButton(
              tooltip: l10n.browseSortTitle,
              icon: const Icon(Icons.sort),
              onPressed: () => unawaited(showSortSheet(context)),
            ),
            // SS1: swipe the photos and videos shown here.
            IconButton(
              tooltip: l10n.browseSwipeThese,
              icon: const Icon(Icons.swipe_outlined),
              onPressed: () => unawaited(
                swipeQueryFiles(
                  context,
                  ref,
                  query: query,
                  title: group == null
                      ? collection.title(l10n)
                      : nameOfFolder(l10n, group),
                  returnRoute: AppRoutes.browse,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KindChipsRow(
              scope: group == null
                  ? scope
                  : scope.copyWith(folderPath: () => group),
              selected: _kinds,
              onSelect: (kind, {add = false}) =>
                  setState(() => _kinds = toggleKind(_kinds, kind, add: add)),
            ),
            const SelectionHint(),
            if (collection is! RecentCollection)
              Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: spacing * 2,
                ),
                child: Text(
                  sortLabel(l10n, sort),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            Expanded(
              child: _isOther && group == null
                  ? OtherGroups(
                      scope: base,
                      leading: banner,
                      onOpen: (path) => setState(() => _group = path),
                    )
                  : FileResultsView(query: query, leading: banner),
            ),
            const SelectionBar(),
          ],
        ),
      ),
    );
  }
}
