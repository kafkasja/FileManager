import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/utils/debouncer.dart';
import 'package:kfm/features/filters/data/filter_query.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// P5: narrow the swipe queue. Opens with the session's current filter and
/// applies it to the deck. Edit mode (P6 preset editor): pass [initial] and
/// [onSave]; the deck is left alone and the count ignores session history.
Future<void> showFilterSheet(
  BuildContext context, {
  FileFilter? initial,
  void Function(FileFilter filter)? onSave,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _FilterSheet(initial: initial, onSave: onSave),
);

const int _mb = 1 << 20;

final FutureProvider<List<({String path, int count})>> _folders =
    FutureProvider.autoDispose<List<({String path, int count})>>(
      (ref) => ref.watch(mediaIndexDaoProvider).folderSummaries(),
    );

class _FilterSheet extends ConsumerStatefulWidget {
  const new({this.initial, this.onSave});

  final FileFilter? initial;
  final void Function(FileFilter filter)? onSave;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late FileFilter _filter =
      widget.initial ?? ref.read(swipeDeckControllerProvider.notifier).filter;
  final _debouncer = Debouncer(const Duration(milliseconds: 250));
  int? _count;
  int _requests = 0;

  /// P7 include switch (deck mode only); null while loading the default.
  bool? _include;

  bool get _deckMode => widget.onSave == null;

  @override
  void initState() {
    super.initState();
    _recount();
    if (_deckMode) {
      final override = _filter.includeReviewed;
      if (override != null) {
        _include = override;
      } else {
        ref
            .read(swipeDeckControllerProvider.notifier)
            .includeReviewedDefault()
            .then((v) {
              if (mounted) setState(() => _include = v);
            })
            .ignore();
      }
    }
  }

  @override
  void dispose() {
    _debouncer.cancel();
    super.dispose();
  }

  void _set(FileFilter f) {
    setState(() => _filter = f);
    _debouncer.run(_recount);
  }

  void _recount() {
    final request = ++_requests;
    final include = _include;
    final filter = include == null || !_deckMode
        ? _filter
        : _filter.copyWith(includeReviewed: include);
    if (!filter.isValid) return;
    unawaited(
      _countFor(filter).then((n) {
        if (mounted && request == _requests) setState(() => _count = n);
      }),
    );
  }

  Future<int> _countFor(FileFilter filter) async {
    if (widget.onSave == null) {
      return await ref
          .read(swipeDeckControllerProvider.notifier)
          .matchCount(filter);
    }
    final query = toIndexQuery(filter, now: DateTime.now());
    return query == null
        ? 0
        : await ref.read(mediaIndexDaoProvider).count(query);
  }

  Future<void> _apply() async {
    final navigator = Navigator.of(context);
    if (widget.onSave case final onSave?) {
      onSave(_filter);
    } else {
      final deck = ref.read(swipeDeckControllerProvider.notifier);
      var filter = _filter;
      final include = _include;
      if (include != null) {
        if (deck.presetKey == 0) {
          // Basic isn't a preset: the switch is Basic's own setting.
          await ref
              .read(settingsRepositoryProvider)
              .write(AppSettings.basicIncludeReviewed, include);
          filter = filter.copyWith(clearIncludeReviewed: true);
        } else {
          // In a preset it lasts for this session only.
          filter = filter.copyWith(includeReviewed: include);
        }
      }
      await deck.applyFilter(filter);
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final f = _filter;
    final tags = ref.watch(tagsByIdProvider).value ?? const {};
    final folders = ref.watch(_folders).value ?? const [];
    final problem = f.problem;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scroll,
              padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
              children: [
                Text(
                  l10n.filterTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                _Header(l10n.filterKinds),
                Wrap(
                  spacing: spacing,
                  children: [
                    for (final (kind, label) in [
                      (FileKind.image, l10n.filterPhotos),
                      (FileKind.video, l10n.filterVideos),
                    ])
                      FilterChip(
                        label: Text(label),
                        selected: f.kinds.contains(kind),
                        onSelected: (on) => _set(
                          _filter.copyWith(
                            kinds: _toggle(_filter.kinds, kind, on: on),
                          ),
                        ),
                      ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.filterScreenshotsOnly),
                  value: f.screenshotsOnly,
                  onChanged: (v) => _set(_filter.copyWith(screenshotsOnly: v)),
                ),
                _Header(l10n.filterDate),
                Wrap(
                  spacing: spacing,
                  children: [
                    _choice(
                      l10n.filterAny,
                      f.date is DateAny,
                      () => _set(_filter.copyWith(date: const DateAny())),
                    ),
                    _choice(
                      l10n.filterThisMonth,
                      f.date is DateThisMonth,
                      () => _set(_filter.copyWith(date: const DateThisMonth())),
                    ),
                    _choice(
                      l10n.filterLast30Days,
                      f.date == const DateLastDays(30),
                      () =>
                          _set(_filter.copyWith(date: const DateLastDays(30))),
                    ),
                    _choice(
                      switch (f.date) {
                        DateRange(:final from, :final to) => l10n.filterRange(
                          _day(context, from),
                          _day(context, to),
                        ),
                        _ => l10n.filterCustomRange,
                      },
                      f.date is DateRange,
                      _pickRange,
                    ),
                  ],
                ),
                _Header(l10n.filterSize),
                Wrap(
                  spacing: spacing,
                  children: [
                    _choice(
                      l10n.filterAny,
                      f.minSizeBytes == null && f.maxSizeBytes == null,
                      () => _set(
                        _filter.copyWith(
                          clearMinSize: true,
                          clearMaxSize: true,
                        ),
                      ),
                    ),
                    for (final mb in const [10, 50, 100])
                      _choice(
                        l10n.filterOverMb(mb),
                        f.minSizeBytes == mb * _mb && f.maxSizeBytes == null,
                        () => _set(
                          _filter.copyWith(
                            minSizeBytes: mb * _mb,
                            clearMaxSize: true,
                          ),
                        ),
                      ),
                  ],
                ),
                if (folders.isNotEmpty) ...[
                  _Header(l10n.filterFolders),
                  Wrap(
                    spacing: spacing,
                    children: [
                      for (final folder in {
                        for (final x in folders) x.path,
                        ...f.folderPaths,
                      })
                        FilterChip(
                          label: Text(_folderLabel(l10n, folder, folders)),
                          selected: f.folderPaths.contains(folder),
                          onSelected: (on) => _set(
                            _filter.copyWith(
                              folderPaths: _toggle(
                                f.folderPaths,
                                folder,
                                on: on,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  _Header(l10n.filterTags),
                  Wrap(
                    spacing: spacing,
                    children: [
                      for (final (mode, label) in [
                        (TagFilterMode.any, l10n.filterAny),
                        (TagFilterMode.tagged, l10n.filterTagged),
                        (TagFilterMode.untagged, l10n.filterUntagged),
                        (TagFilterMode.hasTags, l10n.filterSpecificTags),
                      ])
                        _choice(
                          label,
                          f.tagMode == mode,
                          () => _set(_filter.copyWith(tagMode: mode)),
                        ),
                    ],
                  ),
                  if (f.tagMode == TagFilterMode.hasTags)
                    Wrap(
                      spacing: spacing,
                      children: [
                        for (final t in tags.values)
                          FilterChip(
                            avatar: Icon(Icons.label, color: Color(t.color)),
                            label: Text(t.name),
                            selected: f.tagIds.contains(t.id),
                            onSelected: (on) => _set(
                              _filter.copyWith(
                                tagIds: _toggle(_filter.tagIds, t.id, on: on),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
                _Header(l10n.filterReviewed),
                Wrap(
                  spacing: spacing,
                  children: [
                    for (final (mode, label) in [
                      (ReviewedFilterMode.any, l10n.filterAny),
                      (ReviewedFilterMode.reviewed, l10n.filterReviewedOnly),
                      (ReviewedFilterMode.notReviewed, l10n.filterNotReviewed),
                    ])
                      _choice(
                        label,
                        f.reviewed == mode,
                        () => _set(_filter.copyWith(reviewed: mode)),
                      ),
                  ],
                ),
                if (_deckMode && _include != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.reviewedIncludeToggle),
                    value: _include!,
                    onChanged: (v) {
                      setState(() => _include = v);
                      _debouncer.run(_recount);
                    },
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.filterFavoritesOnly),
                  value: f.favoritesOnly,
                  onChanged: (v) => _set(_filter.copyWith(favoritesOnly: v)),
                ),
                SizedBox(height: spacing * 2),
              ],
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: EdgeInsetsDirectional.all(spacing * 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      problem != null
                          ? _problemText(l10n, problem)
                          : _count == null
                          ? ''
                          : l10n.filterMatches(_count!),
                      style: TextStyle(
                        color: problem != null
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: f.isEmpty ? null : () => _set(FileFilter.none),
                    child: Text(l10n.reset),
                  ),
                  SizedBox(width: spacing),
                  FilledButton(
                    onPressed: problem == null ? _apply : null,
                    child: Text(l10n.filterApply),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _choice(String label, bool selected, VoidCallback onTap) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
  );

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 1),
      initialDateRange: switch (_filter.date) {
        DateRange(:final from, :final to) => DateTimeRange(
          start: from,
          end: to,
        ),
        _ => null,
      },
    );
    if (range == null) return;
    _set(_filter.copyWith(date: DateRange(range.start, range.end)));
  }

  static String _day(BuildContext context, DateTime d) =>
      MaterialLocalizations.of(context).formatShortDate(d);

  static String _folderLabel(
    AppLocalizations l,
    String path,
    List<({String path, int count})> folders,
  ) {
    final leaf = path.split('/').where((p) => p.isNotEmpty).lastOrNull ?? path;
    final known = folders.where((f) => f.path == path).firstOrNull;
    return known == null
        ? l.filterFolderMissing(leaf)
        : l.filterFolderCount(leaf, known.count);
  }

  static String _problemText(AppLocalizations l, FilterProblem p) =>
      switch (p) {
        FilterProblem.sizeRange => l.filterProblemSize,
        FilterProblem.noTagsChosen => l.filterProblemTags,
        FilterProblem.dateRange => l.filterProblemDate,
      };
}

class _Header extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: 16, bottom: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}

/// A copy of [set] with [item] added or removed.
Set<T> _toggle<T>(Set<T> set, T item, {required bool on}) =>
    on ? {...set, item} : ({...set}..remove(item));
