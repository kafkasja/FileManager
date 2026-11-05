import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/scroll_to_top.dart';
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
import 'package:kfm/features/cloud/ui/cloud_badge_cache.dart';
import 'package:kfm/features/selection/domain/selection_state.dart';
import 'package:kfm/features/selection/ui/drag_select_detector.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';

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
    this.scrollToTopTab,
    this.onRefresh,
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

  /// E4: tapping this tab again scrolls to the top (Browse's own view).
  final AppTab? scrollToTopTab;

  /// E4 (A5): pull to refresh (phone Browse); null = none.
  final Future<void> Function()? onRefresh;

  @override
  ConsumerState<FileResultsView> createState() => _FileResultsViewState();
}

class _FileResultsViewState extends ConsumerState<FileResultsView> {
  /// Load the next page this many tiles before the loaded end (a backstop
  /// for [_onScroll]: placeholders being built always load).
  static const _prefetch = 60;

  /// The grid / list sliver: where a file sits for [_reveal].
  final GlobalKey _sliver = GlobalKey();

  IndexQuery get query => widget.query;

  /// The item count of the last build (E4: count changes relayout).
  int? _lastTotal;

  /// Drives the scrollbar and the scroll to the top.
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// E4: the file flashed once after "Open folder" scrolled to it.
  String? _flashId;

  @override
  Widget build(BuildContext context) {
    if (widget.scrollToTopTab case final tab?) {
      ref.listen(scrollToTopProvider, (_, next) {
        if (next?.$1 == tab) scrollResultsToTop(_scroll);
      });
      if (tab == AppTab.browse && widget.showFiles) {
        final highlight = ref.watch(browseHighlightProvider);
        if (highlight != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => unawaited(_highlight(highlight)),
          );
        }
      }
    }
    Widget view = CustomScrollView(
      // One scroll position per view; kept while the tab is switched away.
      key: PageStorageKey<IndexQuery>(query),
      controller: _scroll,
      slivers: [...widget.leading, if (widget.showFiles) _results(context)],
    );
    // E4 (H7): the extent is stable, so the thumb can be dragged through
    // thousands of files (placeholders fill in as pages load).
    if (widget.showFiles) {
      view = Scrollbar(controller: _scroll, interactive: true, child: view);
    }
    if (widget.onRefresh case final refresh?) {
      view = RefreshIndicator(onRefresh: refresh, child: view);
    }
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: _onScroll,
      child: view,
    );
  }

  /// E4 (H1): loads the next page by pixels, not by built tiles: once the
  /// loaded rows end less than [prefetchViewports] screens ahead, so a
  /// fast fling never reaches them.
  bool _onScroll(ScrollUpdateNotification n) {
    if (n.depth != 0 || !widget.showFiles) return false;
    final data = ref.read(filePagesProvider(query)).value;
    if (data == null || !data.hasMore || data.loadingMore) return false;
    if (data.loadMoreError != null) return false;
    final end = _loadedEnd(data.items.length);
    final m = n.metrics;
    if (end == null ||
        m.pixels + m.viewportDimension * (1 + prefetchViewports) >= end) {
      unawaited(ref.read(filePagesProvider(query).notifier).loadMore());
    }
    return false;
  }

  /// Load ahead this many screens past the visible one.
  static const prefetchViewports = 3;

  /// Scroll offset where the loaded rows end (placeholders follow), or null
  /// before the results sliver has laid out.
  double? _loadedEnd(int loaded) {
    final render = _sliver.currentContext?.findRenderObject();
    if (render is! RenderSliver || render.geometry == null || loaded == 0) {
      return null;
    }
    final constraints = render.constraints;
    switch (render) {
      case RenderSliverGrid(:final gridDelegate):
        final g = gridDelegate
            .getLayout(constraints)
            .getGeometryForChildIndex(loaded - 1);
        return constraints.precedingScrollExtent +
            g.scrollOffset +
            g.mainAxisExtent;
      case RenderSliverMultiBoxAdaptor(:final firstChild?):
        return constraints.precedingScrollExtent +
            loaded * firstChild.size.height;
      default:
        return null;
    }
  }

  /// Loads pages until [id] is there (at most a few), scrolls to it and
  /// flashes it once.
  Future<void> _highlight(String id) async {
    final notifier = ref.read(browseHighlightProvider.notifier);
    if (ref.read(browseHighlightProvider) != id) return;
    final pages = ref.read(filePagesProvider(query).notifier);
    FileRef? file;
    for (var i = 0; i < 6 && mounted; i++) {
      final data = await ref.read(filePagesProvider(query).future);
      if (!mounted) return;
      final index = data.indexOfId(id);
      if (index != null) {
        file = data.items[index];
        break;
      }
      if (!data.hasMore) break;
      await pages.loadMore();
    }
    if (!mounted) return;
    notifier.show(null);
    if (file == null) return;
    final found = file;
    setState(() => _flashId = found.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reveal(found);
    });
  }

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
    // E4 (H5): once for all tiles (no cloud badge Consumer per tile when
    // nothing was ever uploaded or badges are off).
    final showCloud =
        (ref.watch(cloudHasUploadsProvider).value ?? false) &&
        (ref.watch(cloudShowBadgeProvider).value ?? false);
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

    // E4 (H1): a stable scroll extent. While more pages exist the list is
    // as long as the whole result (its count), with neutral placeholders
    // for rows not loaded yet, so a fling never stops dead at a page end
    // and the scrollbar doesn't jump. Without more pages (or after a
    // failed load) it is exactly the loaded rows.
    final loaded = data.items.length;
    final total = data.hasMore && data.loadMoreError == null
        ? math.max(
            loaded,
            ref.watch(browseCountProvider(query)).value ?? loaded,
          )
        : loaded;
    if (total != _lastTotal) {
      _lastTotal = total;
      // A new count with the same tiles on screen doesn't relayout the
      // sliver by itself: the scroll extent would stay the old one until
      // the next scroll.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _sliver.currentContext?.findRenderObject()?.markNeedsLayout();
      });
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
    // E4 (H3): a tile keyed by its file id keeps its element (and its
    // shown thumbnail) when a reload moves it to another index.
    int? indexOfKey(Key key) => switch (key) {
      ValueKey<String>(:final value) => data.indexOfId(value),
      _ => null,
    };
    final body = asList
        ? SliverList.builder(
            key: _sliver,
            itemCount: total,
            findChildIndexCallback: indexOfKey,
            itemBuilder: (context, i) {
              maybeLoadMore(i);
              if (i >= loaded) return const ResultsPlaceholder(listRow: true);
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
                  highlight: widget.highlight,
                  showCloud: showCloud,
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
              itemCount: total,
              findChildIndexCallback: indexOfKey,
              itemBuilder: (context, i) {
                maybeLoadMore(i);
                if (i >= loaded) return const ResultsPlaceholder();
                final f = data.items[i];
                final tile = SelectableFile(
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
                    highlight: widget.highlight,
                    showCloud: showCloud,
                    menu: normal
                        ? FileActionsMenuButton(file: f, overlay: true)
                        : null,
                  ),
                );
                return f.id == _flashId
                    ? _Flash(key: ValueKey('flash:${f.id}'), child: tile)
                    : tile;
              },
            ),
          );
    // No spinner sliver at the end: placeholders stand in for what loads.
    return SliverMainAxisGroup(
      slivers: [
        body,
        if (data.loadMoreError != null)
          SliverToBoxAdapter(
            child: _ErrorBox(onRetry: () => unawaited(notifier.loadMore())),
          ),
      ],
    );
  }
}

/// A tile (or list row) for a result not loaded yet: the thumbnail
/// placeholder colour, same size, not tappable (E4).
class ResultsPlaceholder extends StatelessWidget {
  const new({this.listRow = false})
    : super(key: const ValueKey('results-placeholder'));

  final bool listRow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final box = ColoredBox(color: scheme.surfaceContainerHighest);
    if (!listRow) return ExcludeSemantics(child: box);
    final text = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    // The text line's height (font size × line height), a thinner bar in it.
    Widget bar(TextStyle? style, double width) {
      final size = scaler.scale(style?.fontSize ?? 14);
      return SizedBox(
        height: size * (style?.height ?? 1.2),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(width: width, height: size * 0.7, child: box),
        ),
      );
    }

    // A ListTile with the row's leading, title and subtitle sizes, so the
    // row keeps its height when the file arrives.
    return ExcludeSemantics(
      child: ListTile(
        enabled: false,
        leading: SizedBox.square(dimension: 48, child: box),
        title: bar(text.bodyLarge, 160),
        subtitle: bar(text.bodyMedium, 96),
      ),
    );
  }
}

/// Animates [controller]'s view to the top (a jump first when far away,
/// so it never animates through thousands of rows).
void scrollResultsToTop(ScrollController controller) {
  if (!controller.hasClients) return;
  final position = controller.position;
  if (position.pixels > position.viewportDimension * 3) {
    position.jumpTo(position.viewportDimension * 3);
  }
  position
      .animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      )
      .ignore();
}

/// One fading outline over a tile (E4: the file "Open folder" came for).
class _Flash extends StatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  State<_Flash> createState() => _FlashState();
}

class _FlashState extends State<_Flash> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: FadeTransition(
              opacity: ReverseAnimation(_fade),
              child: DecoratedBox(
                key: const ValueKey('results-flash'),
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 4),
                ),
              ),
            ),
          ),
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
