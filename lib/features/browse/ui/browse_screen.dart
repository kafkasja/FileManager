import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/haptics.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/layout/segment_label.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/app/widgets/hiding_header.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/ai_labels/ui/ai_labels_card.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/browse/ui/folder_menu.dart';
import 'package:kfm/features/browse/ui/same_time_view.dart';
import 'package:kfm/features/browse/ui/widgets/browse_parts.dart';
import 'package:kfm/features/browse/ui/widgets/file_results_view.dart';
import 'package:kfm/features/browse/ui/widgets/sort_sheet.dart';
import 'package:kfm/features/browse/ui/widgets/sources_carousel.dart';
import 'package:kfm/features/browse/ui/widgets/sources_row.dart';
import 'package:kfm/features/external_storage/ui/places_list.dart';
import 'package:kfm/features/folders/ui/file_drag.dart';
import 'package:kfm/features/folders/ui/file_op_flow.dart';
import 'package:kfm/features/folders/ui/last_operation_undo.dart';
import 'package:kfm/features/selection/domain/selection_state.dart';
import 'package:kfm/features/selection/ui/selection_bar.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_these.dart';

/// "Swipe these" needs SS1's swipe sources (Phase 4); SS1 turns it on.
const swipeSourceAvailable = true;

/// The Browse tab (TASK-B1): every indexed file, type chips, a flat list
/// (with the sources carousel on top) or folders, and opening any file.
class BrowseScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(browseViewControllerProvider);
    final controller = ref.read(browseViewControllerProvider.notifier);
    final canSeeAll =
        ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ??
        false;
    final spacing = context.tokens.spacing;
    final compact = compactSegments(context);
    final canGoUp = view.folder != null;
    final selection = ref.watch(selectionControllerProvider).value;
    final mode = selection?.mode ?? SelectionMode.normal;
    final selecting = mode != SelectionMode.normal;
    final canRestore =
        (selection?.canRestoreCleared ?? false) &&
        (selection?.isEmpty ?? false);
    final selector = ref.read(selectionControllerProvider.notifier);
    final canUndo = ref.watch(lastOperationUndoProvider) != null;
    // Folder mode's storage list has no files to select; Same time selects
    // per group.
    final canSelectAll = switch (view.layout) {
      BrowseLayout.all => true,
      BrowseLayout.folders => view.folder != null,
      BrowseLayout.sameTime => false,
    };
    final newestFirst =
        view.sort.field != FileSortField.date || view.sort.descending;

    return PopScope(
      // Back leaves Edit / Select mode, then goes up a folder.
      canPop: !canGoUp && !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        switch (mode) {
          case SelectionMode.edit:
            selector.exitEdit();
          case SelectionMode.select:
            selector.exitSelect();
          case SelectionMode.normal:
            if (canGoUp) _goUp(controller, view);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: selecting
              ? IconButton(
                  tooltip: l10n.selectionExit,
                  icon: const Icon(Icons.close),
                  onPressed: mode == SelectionMode.edit
                      ? selector.exitEdit
                      : selector.exitSelect,
                )
              : null,
          title: Text(switch (mode) {
            SelectionMode.normal => l10n.tabBrowse,
            SelectionMode.select => l10n.selectionEnter,
            SelectionMode.edit => l10n.selectionEditTitle,
          }),
          actions: [
            if (mode == SelectionMode.select && canSelectAll)
              IconButton(
                tooltip: l10n.selectionSelectAll,
                icon: const Icon(Icons.select_all),
                onPressed: () => unawaited(_selectAll(context, ref, view)),
              ),
            if (!selecting)
              IconButton(
                tooltip: l10n.searchOpen,
                icon: const Icon(Icons.search),
                onPressed: () => unawaited(
                  context.push<void>(
                    AppRoutes.search,
                    extra: view.folderMode ? view.folder : null,
                  ),
                ),
              ),
            // E1: Connect is one tap away (phone or PC).
            if (!selecting)
              IconButton(
                key: const ValueKey('browse-devices'),
                tooltip: l10n.connectADevice,
                icon: const Icon(Icons.devices_outlined),
                onPressed: () =>
                    unawaited(context.push<void>(AppRoutes.connect)),
              ),
            if (!selecting)
              IconButton(
                tooltip: l10n.collectionsOpen,
                icon: const Icon(Icons.label_outline),
                onPressed: () =>
                    unawaited(context.push<void>(AppRoutes.collections)),
              ),
            if (!selecting)
              IconButton(
                tooltip: l10n.selectionEnter,
                icon: const Icon(Icons.checklist),
                onPressed: selector.enterSelect,
              ),
            IconButton(
              tooltip: l10n.browseSortTitle,
              icon: const Icon(Icons.sort),
              onPressed: () => unawaited(showSortSheet(context)),
            ),
            PopupMenuButton<_MenuAction>(
              onSelected: (action) => switch (action) {
                _MenuAction.newFolder => unawaited(
                  createFolderIn(
                    context,
                    ref,
                    view.folder ?? ref.read(defaultNewFolderParentProvider),
                  ),
                ),
                _MenuAction.undoLast => unawaited(
                  undoLastFileOperation(context),
                ),
                _MenuAction.showHidden => controller.setShowHidden(
                  show: !view.showHidden,
                ),
                _MenuAction.restoreSelection => unawaited(
                  selector.restoreCleared(),
                ),
                _MenuAction.similar => unawaited(
                  context.push<void>(AppRoutes.similar),
                ),
                _MenuAction.storage => unawaited(
                  context.push<void>(AppRoutes.storage),
                ),
                _MenuAction.groups => unawaited(
                  context.push<void>(AppRoutes.groups),
                ),
                _MenuAction.swipeThese => unawaited(
                  swipeQueryFiles(
                    context,
                    ref,
                    query: view.query,
                    title: switch (view.folder) {
                      final folder? when view.folderMode => nameOfFolder(
                        l10n,
                        folder,
                      ),
                      _ => l10n.tabBrowse,
                    },
                    returnRoute: AppRoutes.browse,
                  ),
                ),
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _MenuAction.newFolder,
                  child: Text(l10n.browseNewFolder),
                ),
                PopupMenuItem(
                  value: _MenuAction.storage,
                  child: Text(l10n.storageOverviewTitle),
                ),
                PopupMenuItem(
                  value: _MenuAction.similar,
                  child: Text(l10n.similarTitle),
                ),
                PopupMenuItem(
                  value: _MenuAction.groups,
                  child: Text(l10n.groupsTitle),
                ),
                if (canUndo)
                  PopupMenuItem(
                    value: _MenuAction.undoLast,
                    child: Text(l10n.opUndoLast),
                  ),
                if (canRestore)
                  PopupMenuItem(
                    value: _MenuAction.restoreSelection,
                    child: Text(l10n.selectionRestore),
                  ),
                if (canSeeAll)
                  CheckedPopupMenuItem(
                    value: _MenuAction.showHidden,
                    checked: view.showHidden,
                    child: Text(l10n.browseShowHidden),
                  ),
                if (swipeSourceAvailable)
                  PopupMenuItem(
                    value: _MenuAction.swipeThese,
                    child: Text(l10n.browseSwipeThese),
                  ),
              ],
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Body(
                view: view,
                canSeeAll: canSeeAll,
                // E4: the bar rule (hides on scroll down, back on any small
                // scroll up, always at the top), on every phone height.
                header: HidingHeaderSliver(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.symmetric(
                          horizontal: spacing * 2,
                          vertical: spacing / 2,
                        ),
                        child: SegmentedButton<BrowseLayout>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: BrowseLayout.all,
                              label: SegmentLabel(l10n.browseModeAll),
                              icon: compact
                                  ? null
                                  : const Icon(Icons.grid_view),
                            ),
                            ButtonSegment(
                              value: BrowseLayout.folders,
                              label: SegmentLabel(l10n.browseModeFolders),
                              icon: compact
                                  ? null
                                  : const Icon(Icons.folder_outlined),
                            ),
                            ButtonSegment(
                              value: BrowseLayout.sameTime,
                              label: SegmentLabel(l10n.browseModeSameTime),
                              icon: compact
                                  ? null
                                  : const Icon(Icons.burst_mode_outlined),
                            ),
                          ],
                          selected: {view.layout},
                          onSelectionChanged: (s) =>
                              controller.setLayout(s.first),
                        ),
                      ),
                      // The folder path lives in the header so it comes
                      // back with it: after "Open folder" jumps down to a
                      // file, the user still sees which folder this is.
                      if (view.folderMode)
                        _Breadcrumb(folder: view.folder),
                      KindChipsRow(
                        scope: view.query.copyWith(kinds: const {}),
                        selected: view.kinds,
                        onSelect: controller.setKind,
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.symmetric(
                          horizontal: spacing * 2,
                        ),
                        child: Text(
                          // Same time always goes by date (B3).
                          view.layout == BrowseLayout.sameTime
                              ? sortLabel(
                                  l10n,
                                  FileSort(
                                    FileSortField.date,
                                    descending: newestFirst,
                                  ),
                                )
                              : sortLabel(l10n, view.sort),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      const SelectionHint(),
                    ],
                  ),
                ),
              ),
            ),
            const SelectionBar(),
          ],
        ),
      ),
    );
  }

  static Future<void> _selectAll(
    BuildContext context,
    WidgetRef ref,
    BrowseView view,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final added = await ref
        .read(selectionControllerProvider.notifier)
        .selectAll(view.query);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.selectionAdded(added))));
  }

  static void _goUp(BrowseViewController controller, BrowseView view) {
    final folder = view.folder;
    if (folder == null) return;
    final root = volumeRootOf(folder);
    controller.openFolder(
      folder == root ? null : folder.substring(0, folder.lastIndexOf('/')),
    );
  }
}

enum _MenuAction {
  newFolder,
  storage,
  similar,
  groups,
  undoLast,
  showHidden,
  restoreSelection,
  swipeThese,
}

class _Body extends ConsumerWidget {
  const new({
    required this.view,
    required this.canSeeAll,
    required this.header,
  });

  final BrowseView view;
  final bool canSeeAll;

  /// The mode/kind/sort header: the first sliver of every layout.
  final Widget header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsAccess =
        !canSeeAll &&
        (view.query.visible(canSeeAllFiles: false) == null ||
            view.kinds.any((k) => !mediaKinds.contains(k)));
    final banner = [
      header,
      if (needsAccess) const SliverToBoxAdapter(child: AccessBanner()),
      // C3: offer content labels at the top of the image view.
      if (view.kinds.contains(FileKind.image))
        const SliverToBoxAdapter(child: AiLabelsCard()),
    ];
    if (view.layout == BrowseLayout.sameTime) {
      return SameTimeView(
        query: view.query,
        newestFirst:
            view.sort.field != FileSortField.date || view.sort.descending,
        leading: banner,
        scrollToTopTab: AppTab.browse,
      );
    }
    if (view.folderMode) {
      return FileResultsView(
        query: view.query,
        showFiles: view.folder != null,
        scrollToTopTab: AppTab.browse,
        onRefresh: () => _refresh(context, ref),
        leading: [
          ...banner,
          _FolderList(scope: view.query, parent: view.folder),
        ],
      );
    }
    // Sources (WhatsApp, Camera…) only on the All files page (user
    // request 2026-10-29); they scroll away with the grid.
    return FileResultsView(
      query: view.query,
      scrollToTopTab: AppTab.browse,
      onRefresh: () => _refresh(context, ref),
      leading: [
        ...banner,
        // U1: SD cards, USB drives and cameras (hidden without them).
        const SliverToBoxAdapter(child: PlacesList()),
        const SliverToBoxAdapter(child: SourcesCarousel()),
      ],
    );
  }

  /// E4 (A5): pull to refresh. A folder rescans just that folder, All
  /// runs an incremental scan; the results reload; a failure says so
  /// (rule 8).
  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.browseRefreshFailed;
    lightHaptic(ref);
    try {
      final indexer = ref.read(mediaIndexerProvider);
      if (view.folder case final folder? when view.folderMode) {
        await indexer.refreshFolder(folder, recursive: false);
      } else {
        await indexer.incremental();
      }
      ref
        ..invalidate(filePagesProvider(view.query))
        ..invalidate(browseCountProvider(view.query));
    } on Object {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failed)));
    }
  }
}

class _Breadcrumb extends ConsumerWidget {
  const new({required this.folder});

  final String? folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(browseViewControllerProvider.notifier);
    final crumbs = <(String, String?)>[(l10n.browseStorageRoot, null)];
    final current = folder;
    if (current != null) {
      final root = volumeRootOf(current);
      crumbs.add((nameOfFolder(l10n, root), root));
      if (current != root) {
        final segments = current.substring(root.length + 1).split('/');
        for (var i = 0; i < segments.length; i++) {
          crumbs.add((
            segments[i],
            '$root/${segments.sublist(0, i + 1).join('/')}',
          ));
        }
      }
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: context.tokens.spacing,
      ),
      child: Row(
        children: [
          for (final (i, (label, path)) in crumbs.indexed) ...[
            if (i > 0) const Icon(Icons.chevron_right, size: 18),
            TextButton(
              onPressed: i == crumbs.length - 1
                  ? null
                  : () => controller.openFolder(path),
              child: Text(label),
            ),
          ],
        ],
      ),
    );
  }
}

class _FolderList extends ConsumerWidget {
  const new({required this.scope, required this.parent});

  final IndexQuery scope;
  final String? parent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final folders = ref.watch(browseFoldersProvider(scope, parent: parent));
    final menu = ref.watch(folderMenuItemsProvider);
    final controller = ref.read(browseViewControllerProvider.notifier);
    return switch (folders) {
      AsyncData(:final value) => SliverList.builder(
        itemCount: value.length,
        itemBuilder: (context, i) {
          final entry = value[i];
          final items = [
            for (final item in menu)
              if (item.isAvailable(entry)) item,
          ];
          final tile = ListTile(
            leading: Icon(
              parent == null ? Icons.sd_storage_outlined : Icons.folder,
            ),
            title: Text(
              parent == null ? nameOfFolder(l10n, entry.path) : entry.name,
            ),
            subtitle: Text(l10n.browseFileCount(entry.fileCount)),
            trailing: items.isEmpty
                ? null
                : PopupMenuButton<FolderMenuItem>(
                    tooltip: l10n.browseFolderMenu,
                    onSelected: (item) =>
                        unawaited(item.onSelected(context, ref, entry)),
                    itemBuilder: (context) => [
                      for (final item in items)
                        PopupMenuItem(
                          value: item,
                          child: ListTile(
                            leading: Icon(item.icon),
                            title: Text(item.label(context)),
                          ),
                        ),
                    ],
                  ),
            onTap: () => controller.openFolder(entry.path),
          );
          // B4: selected files can be dropped here (not on volumes).
          return parent == null
              ? KeyedSubtree(key: ValueKey(entry.path), child: tile)
              : FolderDropTarget(
                  key: ValueKey(entry.path),
                  folder: entry.path,
                  child: tile,
                );
        },
      ),
      AsyncError() => SliverToBoxAdapter(
        child: ListTile(
          title: Text(l10n.browseLoadError),
          trailing: TextButton(
            onPressed: () =>
                ref.invalidate(browseFoldersProvider(scope, parent: parent)),
            child: Text(l10n.retry),
          ),
        ),
      ),
      _ => const SliverToBoxAdapter(child: LinearProgressIndicator()),
    };
  }
}
