import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/browse/ui/browse_settings_section.dart';
import 'package:kfm/features/browse/ui/open_file.dart';
import 'package:kfm/features/browse/ui/widgets/file_tile.dart';

/// The results body (TASK-B1): grid (or list for non-visual kinds), paging,
/// empty / error / unavailable states. Browse, B8's search and B9's
/// collections render it with their own query. [leading] slivers scroll
/// with it (banner, folder list); [showFiles] false shows only them.
class FileResultsView extends ConsumerWidget {
  const new({
    required this.query,
    this.leading = const [],
    this.showFiles = true,
    super.key,
  });

  final IndexQuery query;
  final List<Widget> leading;
  final bool showFiles;

  /// Load the next page this many tiles before the end.
  static const _prefetch = 60;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CustomScrollView(
    // One scroll position per view; kept while the tab is switched away.
    key: PageStorageKey<IndexQuery>(query),
    slivers: [...leading, if (showFiles) _results(context, ref)],
  );

  Widget _results(BuildContext context, WidgetRef ref) {
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
    void maybeLoadMore(int index) {
      if (data.hasMore &&
          !data.loadingMore &&
          data.loadMoreError == null &&
          index >= data.items.length - _prefetch) {
        // Not during build: it changes provider state.
        scheduleMicrotask(() => unawaited(notifier.loadMore()));
      }
    }

    void open(FileRef f) => unawaited(openFile(context, ref, f));
    final asList =
        query.kinds.isNotEmpty &&
        !query.kinds.any((k) => k == FileKind.image || k == FileKind.video);
    final body = asList
        ? SliverList.builder(
            itemCount: data.items.length,
            itemBuilder: (context, i) {
              maybeLoadMore(i);
              final f = data.items[i];
              return FileListRow(
                key: ValueKey(f.id),
                file: f,
                onTap: () => open(f),
                highlightBig: highlightBig,
              );
            },
          )
        : SliverPadding(
            padding: EdgeInsets.all(spacing / 4),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 128,
                mainAxisSpacing: spacing / 4,
                crossAxisSpacing: spacing / 4,
              ),
              itemCount: data.items.length,
              itemBuilder: (context, i) {
                maybeLoadMore(i);
                final f = data.items[i];
                return FileGridTile(
                  key: ValueKey(f.id),
                  file: f,
                  onTap: () => open(f),
                  showSize: showSizes || query.sort.field == FileSortField.size,
                  highlightBig: highlightBig,
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
