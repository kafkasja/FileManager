import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kfm/app/a11y/file_semantics.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/scroll_to_top.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/app/widgets/empty_state.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/features/browse/domain/time_clusters.dart';
import 'package:kfm/features/browse/ui/browse_preview.dart';
import 'package:kfm/features/browse/ui/same_time_controller.dart';
import 'package:kfm/features/browse/ui/widgets/file_results_view.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';
import 'package:kfm/features/swipe/ui/swipe_these.dart';

/// B3: photos/videos taken within the window of each other, as cards under
/// day headers. [leading] slivers scroll with it (access banner).
class SameTimeView extends ConsumerStatefulWidget {
  const new({
    required this.query,
    required this.newestFirst,
    this.leading = const [],
    this.scrollToTopTab,
    super.key,
  });

  /// The Browse query (kinds, folder, hidden); its sort is ignored.
  final IndexQuery query;
  final bool newestFirst;
  final List<Widget> leading;

  /// E4: tapping this tab again scrolls to the top.
  final AppTab? scrollToTopTab;

  @override
  ConsumerState<SameTimeView> createState() => _SameTimeViewState();
}

class _SameTimeViewState extends ConsumerState<SameTimeView> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.query;
    final newestFirst = widget.newestFirst;
    final leading = widget.leading;
    if (widget.scrollToTopTab case final tab?) {
      ref.listen(scrollToTopProvider, (_, next) {
        if (next?.$1 == tab) scrollResultsToTop(_scroll);
      });
    }
    final l10n = context.l10n;
    final window = ref.watch(sameTimeWindowProvider).value;
    // The sort doesn't change the groups: one key per filter.
    final key = query.copyWith(sort: FileSort.newestFirst);
    final clusters = window == null
        ? null
        : ref.watch(sameTimeClustersProvider(key, window));
    final Widget body;
    // A new window / filter keeps showing the previous groups until ready.
    final value = clusters?.value;
    if (value == null) {
      body = clusters != null && clusters.hasError
          ? SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.browseLoadError),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(sameTimeClustersProvider(key, window!)),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            )
          : const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            );
    } else if (value.isEmpty) {
      // E4 (A11): the window may be too short; Settings sets it.
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.burst_mode_outlined,
          text: l10n.sameTimeEmpty,
          action: TextButton(
            onPressed: () => context.go(AppRoutes.settings),
            child: Text(l10n.sameTimeChangeWindow),
          ),
        ),
      );
    } else {
      final days = groupByDay(value, newestFirst: newestFirst);
      body = SliverMainAxisGroup(
        slivers: [
          for (final d in days)
            SliverMainAxisGroup(
              slivers: [
                PinnedHeaderSliver(child: _DayHeader(day: d)),
                SliverList.builder(
                  itemCount: d.clusters.length,
                  itemBuilder: (context, i) => _GroupCard(
                    key: ValueKey(d.clusters[i].fileIds.first),
                    cluster: d.clusters[i],
                  ),
                ),
              ],
            ),
        ],
      );
    }
    return Scrollbar(
      controller: _scroll,
      interactive: true,
      child: CustomScrollView(
        key: PageStorageKey<String>('sameTime:$key'),
        controller: _scroll,
        slivers: [...leading, body],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const new({required this.day});

  final SameTimeDay day;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final spacing = context.tokens.spacing;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          spacing * 2,
          spacing,
          spacing * 2,
          spacing,
        ),
        child: Text(
          context.l10n.sameTimeDayHeader(
            DateFormat.yMMMEd(locale).format(day.day),
            day.clusters.length,
          ),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );
  }
}

/// One group: "3 photos · 14:02:11–14:02:15", a strip of thumbnails (only
/// the visible ones built), tap = B7 preview, long-press / ⋮ = select all.
class _GroupCard extends ConsumerStatefulWidget {
  const new({required this.cluster, super.key});

  final TimeCluster cluster;

  @override
  ConsumerState<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends ConsumerState<_GroupCard> {
  /// Files read for a card; bigger groups show "+N more".
  static const shown = 200;
  static const _tile = 96.0;

  List<FileRef>? _files;
  Object? _error;

  List<String> get _shownIds => widget.cluster.fileIds.length > shown
      ? widget.cluster.fileIds.sublist(0, shown)
      : widget.cluster.fileIds;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final files = await ref.read(mediaIndexDaoProvider).byIds(_shownIds);
      if (mounted) setState(() => _files = files);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _open(int index) => unawaited(
    openSelectionPreview(
      context,
      ref,
      ids: widget.cluster.fileIds,
      loaded: _files ?? const [],
      loadedIds: _files == null ? 0 : _shownIds.length,
      startAt: index,
    ),
  );

  /// B6: add-only; reads every file of the group (also past [shown]).
  Future<void> _selectGroup() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      final files = await ref
          .read(mediaIndexDaoProvider)
          .byIds(widget.cluster.fileIds);
      final added = ref
          .read(selectionControllerProvider.notifier)
          .addAll(files);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.selectionAdded(added))));
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.browseLoadError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final c = widget.cluster;
    final time = DateFormat.Hms(locale);
    DateTime local(int ms) =>
        DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    final files = _files;
    final more = c.size - _shownIds.length;
    return Card(
      margin: EdgeInsetsDirectional.symmetric(
        horizontal: spacing,
        vertical: spacing / 2,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onLongPress: () => unawaited(_selectGroup()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(width: spacing * 2),
                Expanded(
                  child: Text(
                    l10n.sameTimeGroupTitle(
                      c.size,
                      time.format(local(c.startMs)),
                      time.format(local(c.endMs)),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<VoidCallback>(
                  tooltip: l10n.selectionMore,
                  onSelected: (action) => action(),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: () => unawaited(_selectGroup()),
                      child: Text(l10n.sameTimeSelectGroup),
                    ),
                    // SS1: swipe this group (photos and videos).
                    PopupMenuItem(
                      value: () => unawaited(
                        swipeFileIds(
                          context,
                          ref,
                          ids: widget.cluster.fileIds,
                          title: l10n.sameTimeGroupTitle(
                            c.size,
                            time.format(local(c.startMs)),
                            time.format(local(c.endMs)),
                          ),
                          origin: SwipeSourceOrigin.sameTime,
                          returnRoute: AppRoutes.browse,
                        ),
                      ),
                      child: Text(l10n.sameTimeSwipeGroup),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: _tile,
              child: switch ((files, _error)) {
                (_, final Object _) => Center(
                  child: Text(l10n.browseLoadError),
                ),
                (null, _) => const Center(child: CircularProgressIndicator()),
                (final List<FileRef> files, _) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsetsDirectional.symmetric(horizontal: spacing),
                  itemCount: files.length + (more > 0 ? 1 : 0),
                  separatorBuilder: (_, _) => SizedBox(width: spacing / 2),
                  itemBuilder: (context, i) => i == files.length
                      ? SizedBox(
                          width: _tile,
                          child: Center(child: Text(l10n.sameTimeMore(more))),
                        )
                      : SizedBox.square(
                          dimension: _tile,
                          child: Semantics(
                            button: true,
                            label: fileSemanticsLabel(context.l10n, files[i]),
                            excludeSemantics: true,
                            child: InkWell(
                              onTap: () => _open(i),
                              child: Thumbnail(file: files[i]),
                            ),
                          ),
                        ),
                ),
              },
            ),
            SizedBox(height: spacing),
          ],
        ),
      ),
    );
  }
}
