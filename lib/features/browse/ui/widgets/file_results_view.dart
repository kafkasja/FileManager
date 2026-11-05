import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/browse/ui/browse_preview.dart';
import 'package:kfm/features/browse/ui/browse_settings_section.dart';
import 'package:kfm/features/browse/ui/open_file.dart';
import 'package:kfm/features/browse/ui/widgets/file_actions_menu.dart';
import 'package:kfm/features/browse/ui/widgets/file_tile.dart';
import 'package:kfm/features/selection/domain/selection_state.dart';
import 'package:kfm/features/selection/ui/drag_select_detector.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';
import 'package:kfm/features/storage/ui/storage_providers.dart';

/// The results body (TASK-B1): grid (or list for non-visual kinds), paging,
/// empty / error / unavailable states. Browse, B8's search and B9's
/// collections render it with their own query. Tiles follow B6's
/// selection modes. [leading] slivers scroll
/// with it (banner, folder list); [showFiles] false shows only them.
/// B7: taps open the paged preview; closing it scrolls the last-viewed file
/// into view.
class FileResultsView extends ConsumerStatefulWidget {
  const new({
    required this.query,
    this.leading = const [],
    this.showFiles = true,
    this.highlight = const [],
    this.empty,
    this.asList,
    super.key,
  });

  final IndexQuery query;
  final List<Widget> leading;
  final bool showFiles;

  /// B8: name words highlighted on the tiles.
  final List<String> highlight;

  /// B8: shown instead of "No files here" when nothing matches.
  final WidgetBuilder? empty;

  /// List rows instead of the grid; null = list only for non-visual kinds.
  final bool? asList;

  @override
  ConsumerState<FileResultsView> createState() => _FileResultsViewState();
}

class _FileResultsViewState extends ConsumerState<FileResultsView> {
  /// Load the next page this many tiles before the end.
  static const _prefetch = 60;

  /// The grid / list sliver: where a file sits for [_reveal].
  final GlobalKey _sliver = GlobalKey();

  IndexQuery get query => widget.query;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    // One scroll position per view; kept while the tab is switched away.
    key: PageStorageKey<IndexQuery>(query),
    slivers: [...widget.leading, if (widget.showFiles) _results(context)],
  );

  Future<void> _preview(int index) async {
    final last = await openResultsPreview(context, query: query, index: index);
    if (last == null || !mounted) return;
    // After the route is gone, so the grid has laid out any new pages.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reveal(last);
    });
  }

  /// Jumps (no animation) so [f] is visible, unless it already is. Its
  /// index comes from the loaded list (no DAO lookup); not loaded = stay.
  void _reveal(FileRef f) {
    final items = ref.read(filePagesProvider(query)).value?.items;
    final index = items?.indexWhere((e) => e.id == f.id) ?? -1;
    final sliverContext = _sliver.currentContext;
    if (index < 0 || sliverContext == null) return;
    final render = sliverContext.findRenderObject();
    if (render is! RenderSliver || render.geometry == null) return;
    final constraints = render.constraints;
    final double start;
    final double extent;
    switch (render) {
      case RenderSliverGrid(:final gridDelegate):
        final geometry = gridDelegate
            .getLayout(constraints)
            .getGeometryForChildIndex(index);
        start = geometry.scrollOffset;
        extent = geometry.mainAxisExtent;
      case RenderSliverMultiBoxAdaptor(:final firstChild?):
        // List rows all have the same height.
        extent = firstChild.size.height;
        start = index * extent;
      default:
        return;
    }
    final position = Scrollable.of(sliverContext).position;
    final top = constraints.precedingScrollExtent + start;
    final viewport = position.viewportDimension;
    if (top >= position.pixels && top + extent <= position.pixels + viewport) {
      return;
    }
    position.jumpTo(
      (top - (viewport - extent) / 2).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }

  Widget _results(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final pages = ref.watch(filePagesProvider(query));
    final data = pages.value;
    if (data == null) {
      if (pages.hasError) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _ErrorBox(
            onRetry: () => ref.invalidate(filePagesProvider(query)),
          ),
        );
      }
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (data.unavailable || data.items.isEmpty) {
      if (widget.empty case final empty?) {
        return SliverFillRemaining(hasScrollBody: false, child: empty(context));
      }
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(spacing * 3),
            child: Text(l10n.browseEmpty, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    final notifier = ref.read(filePagesProvider(query).notifier);
    final showSizes = ref.watch(browseShowSizesProvider).value ?? true;
    final highlightBig = ref.watch(browseHighlightBigProvider).value ?? false;
    final bigFileBytes =
        ref.watch(storageBigFileThresholdProvider).value ??
        FileGridTile.defaultBigFileBytes;
    // B4: the ⋮ only in Normal mode (tiles select in the other modes).
    final normal =
        ref.watch(
          selectionControllerProvider.select(
            (s) => s.value?.mode ?? SelectionMode.normal,
          ),
        ) ==
        SelectionMode.normal;
    void maybeLoadMore(int index) {
      if (data.hasMore &&
          !data.loadingMore &&
          data.loadMoreError == null &&
          index >= data.items.length - _prefetch) {
        // Not during build: it changes provider state.
        scheduleMicrotask(() => unawaited(notifier.loadMore()));
      }
    }

    void open(int i) {
      final f = data.items[i];
      if (opensInPreview(f)) {
        unawaited(_preview(i));
      } else {
        // openFile, not "Open with": X5 APKs and text files have their own
        // screens.
        unawaited(openFile(context, ref, f));
      }
    }

    final asList =
        widget.asList ??
        (query.kinds.isNotEmpty &&
            !query.kinds.any(
              (k) => k == FileKind.image || k == FileKind.video,
            ));
    final body = asList
        ? SliverList.builder(
            key: _sliver,
            itemCount: data.items.length,
            itemBuilder: (context, i) {
              maybeLoadMore(i);
              final f = data.items[i];
              return SelectableFile(
                listRow: true,
                key: ValueKey(f.id),
                index: i,
                items: data.items,
                onOpen: () => open(i),
                onPreview: () => unawaited(_preview(i)),
                builder: (context, onTap) => FileListRow(
                  file: f,
                  onTap: onTap,
                  highlightBig: highlightBig,
                  bigFileBytes: bigFileBytes,
                  highlight: widget.highlight,
                  menu: normal ? FileActionsMenuButton(file: f) : null,
                ),
              );
            },
          )
        : SliverPadding(
            padding: EdgeInsets.all(spacing / 4),
            sliver: SliverGrid.builder(
              key: _sliver,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 128,
                mainAxisSpacing: spacing / 4,
                crossAxisSpacing: spacing / 4,
              ),
              itemCount: data.items.length,
              itemBuilder: (context, i) {
                maybeLoadMore(i);
                final f = data.items[i];
                return SelectableFile(
                  key: ValueKey(f.id),
                  index: i,
                  items: data.items,
                  onOpen: () => open(i),
                  onPreview: () => unawaited(_preview(i)),
                  builder: (context, onTap) => FileGridTile(
                    file: f,
                    onTap: onTap,
                    showSize:
                        showSizes || query.sort.field == FileSortField.size,
                    highlightBig: highlightBig,
                    bigFileBytes: bigFileBytes,
                    highlight: widget.highlight,
                    menu: normal
                        ? FileActionsMenuButton(file: f, overlay: true)
                        : null,
                  ),
                );
              },
            ),
          );
    return SliverMainAxisGroup(
      slivers: [
        body,
        if (data.loadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(spacing * 2),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        if (data.loadMoreError != null)
          SliverToBoxAdapter(
            child: _ErrorBox(onRetry: () => unawaited(notifier.loadMore())),
          ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const new({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    return Padding(
      padding: EdgeInsets.all(spacing * 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.browseLoadError, textAlign: TextAlign.center),
          SizedBox(height: spacing),
          OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}
