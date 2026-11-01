import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/browse/data/recent_searches.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/browse/ui/browse_screen.dart'
    show swipeSourceAvailable;
import 'package:kfm/features/browse/ui/widgets/browse_parts.dart';
import 'package:kfm/features/browse/ui/widgets/file_results_view.dart';
import 'package:kfm/features/browse/ui/widgets/sort_sheet.dart';
import 'package:kfm/features/browse/ui/widgets/sources_row.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/folders/ui/file_op_flow.dart';
import 'package:kfm/features/folders/ui/last_operation_undo.dart';
import 'package:kfm/features/search/data/search_vocabulary.dart';
import 'package:kfm/features/search/domain/search_keyword.dart';
import 'package:kfm/features/search/ui/search_controller.dart';
import 'package:kfm/features/selection/domain/selection_state.dart';
import 'package:kfm/features/selection/ui/selection_bar.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';
import 'package:kfm/features/swipe/ui/swipe_these.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Search (TASK-B8 §6): an autofocused field, token + filter chips, and
/// Browse-style results (B6 select, B4 actions, B7 preview). [folder] is
/// the folder it was opened from (offers an "Only in" chip).
class SearchScreen extends ConsumerStatefulWidget {
  const new({this.folder, super.key});

  final String? folder;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _field = TextEditingController();

  SearchScreenControllerProvider get _provider =>
      searchScreenControllerProvider(widget.folder);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _syncField(String text) {
    if (_field.text == text) return;
    _field.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(_provider);
    final controller = ref.read(_provider.notifier)..attach(l10n);
    ref.listen(_provider.select((s) => s.text), (_, text) => _syncField(text));
    final canSeeAll =
        ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ??
        false;
    final mode =
        ref.watch(selectionControllerProvider.select((s) => s.value?.mode)) ??
        SelectionMode.normal;
    final selecting = mode != SelectionMode.normal;
    final selector = ref.read(selectionControllerProvider.notifier);
    final canUndo = ref.watch(lastOperationUndoProvider) != null;
    final loadErrors =
        ref.watch(searchVocabularyProvider).value?.loadErrors ?? const [];
    final query = state.query;
    final showsFiles = !state.isEmpty && !state.matchesNothing;

    return PopScope(
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (mode == SelectionMode.edit) {
          selector.exitEdit();
        } else {
          selector.exitSelect();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _field,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              border: InputBorder.none,
            ),
            onChanged: controller.edit,
            onSubmitted: (_) => controller.submit(),
          ),
          actions: [
            if (state.text.isNotEmpty)
              IconButton(
                tooltip: l10n.searchClearText,
                icon: const Icon(Icons.clear),
                onPressed: () => controller.edit(''),
              ),
            if (mode == SelectionMode.select && showsFiles)
              IconButton(
                tooltip: l10n.selectionSelectAll,
                icon: const Icon(Icons.select_all),
                onPressed: () => unawaited(_selectAll(query)),
              ),
            IconButton(
              tooltip: l10n.browseSortTitle,
              icon: const Icon(Icons.sort),
              onPressed: () => unawaited(showSortSheet(context)),
            ),
            if (canUndo || swipeSourceAvailable)
              PopupMenuButton<_MenuAction>(
                onSelected: (action) => switch (action) {
                  _MenuAction.undoLast => unawaited(
                    undoLastFileOperation(context),
                  ),
                  _MenuAction.swipeThese => unawaited(
                    swipeQueryFiles(
                      context,
                      ref,
                      query: query,
                      title: state.text,
                      origin: SwipeSourceOrigin.search,
                      returnRoute: AppRoutes.search,
                    ),
                  ),
                },
                itemBuilder: (context) => [
                  if (canUndo)
                    PopupMenuItem(
                      value: _MenuAction.undoLast,
                      child: Text(l10n.opUndoLast),
                    ),
                  if (swipeSourceAvailable && showsFiles)
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
            _ChipsRow(state: state, provider: _provider, canSeeAll: canSeeAll),
            if (loadErrors.isNotEmpty)
              Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: context.tokens.spacing * 2,
                ),
                child: Text(
                  l10n.searchWordsLoadError(loadErrors.join(', ')),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (!state.isEmpty)
              _CountLine(query: state.matchesNothing ? null : query),
            const SelectionHint(),
            Expanded(
              child: state.isEmpty
                  ? _EmptySearch(provider: _provider)
                  : state.matchesNothing
                  ? _NoMatch(onClear: controller.clearAll)
                  : _results(context, state, canSeeAll: canSeeAll),
            ),
            const SelectionBar(),
          ],
        ),
      ),
    );
  }

  Widget _results(
    BuildContext context,
    SearchState state, {
    required bool canSeeAll,
  }) {
    final query = state.query;
    final needsAccess = !canSeeAll && queryNeedsAllFiles(query);
    final nonVisualExtensions =
        query.extensions.isNotEmpty &&
        query.extensions.every((e) {
          final kind = kindFor(null, 'x.$e');
          return kind != FileKind.image && kind != FileKind.video;
        });
    return FileResultsView(
      query: query,
      highlight: state.nameWords,
      // Names matter in a name search: rows show them.
      asList: (query.nameContains != null || nonVisualExtensions) ? true : null,
      leading: [
        if (needsAccess) const SliverToBoxAdapter(child: AccessBanner()),
      ],
      empty: (context) => needsAccess
          ? const SizedBox.shrink()
          : _NoMatch(onClear: ref.read(_provider.notifier).clearAll),
    );
  }

  Future<void> _selectAll(IndexQuery query) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final added = await ref
        .read(selectionControllerProvider.notifier)
        .selectAll(query);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.selectionAdded(added))));
  }
}

enum _MenuAction { undoLast, swipeThese }

class _CountLine extends ConsumerWidget {
  const new({required this.query});

  /// Null = nothing can match (0 files).
  final IndexQuery? query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = query;
    final count = q == null ? 0 : ref.watch(browseCountProvider(q)).value;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: context.tokens.spacing * 2,
      ),
      child: Text(
        count == null ? '' : context.l10n.browseFileCount(count),
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class _NoMatch extends StatelessWidget {
  const new({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing * 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.searchNoMatch, textAlign: TextAlign.center),
            SizedBox(height: spacing),
            OutlinedButton(
              onPressed: onClear,
              child: Text(l10n.searchClearFilters),
            ),
          ],
        ),
      ),
    );
  }
}

/// Token chips (✕ = name search instead) and the filter chips.
class _ChipsRow extends ConsumerWidget {
  const new({
    required this.state,
    required this.provider,
    required this.canSeeAll,
  });

  final SearchState state;
  final SearchScreenControllerProvider provider;
  final bool canSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final controller = ref.read(provider.notifier);
    // The "Only in" chip: a reopened search's folder, else the one the
    // screen was opened from.
    final onlyFolder = state.onlyIn ?? state.folder;

    Widget chip({
      required String label,
      required bool active,
      required VoidCallback onPressed,
      VoidCallback? onClear,
      Key? key,
    }) => Padding(
      padding: EdgeInsetsDirectional.only(end: spacing),
      child: InputChip(
        key: key,
        label: Text(label),
        selected: active,
        showCheckmark: false,
        onPressed: onPressed,
        onDeleted: active ? onClear : null,
        deleteButtonTooltipMessage: l10n.searchClearFilters,
        avatar: active ? null : const Icon(Icons.arrow_drop_down),
      ),
    );

    final type = typeLabel(state, l10n);
    final date = dateLabel(state, l10n, locale);
    final size = sizeLabel(state, l10n, locale);
    final source = state.source;
    final children = <Widget>[
      for (final token in state.chipTokens)
        Padding(
          padding: EdgeInsetsDirectional.only(end: spacing),
          child: InputChip(
            label: Text(tokenLabel(token, l10n)),
            selected: true,
            showCheckmark: false,
            onPressed: () {},
            onDeleted: () => controller.demote(token),
            deleteButtonTooltipMessage: l10n.searchTokenAsName(token.raw),
          ),
        ),
      chip(
        label: type ?? l10n.searchChipType,
        active: type != null,
        onPressed: () => unawaited(_typeSheet(context, provider)),
        onClear: () => controller.setKinds(const {}),
      ),
      chip(
        label: source?.label(l10n) ?? l10n.searchChipSource,
        active: source != null,
        onPressed: () => unawaited(_sourceSheet(context, provider)),
        onClear: () => controller.setSource(null),
      ),
      chip(
        label: date ?? l10n.searchChipDate,
        active: date != null,
        onPressed: () => unawaited(_dateSheet(context, controller)),
        onClear: () => controller.setDate(const DateAny()),
      ),
      chip(
        label: size ?? l10n.searchChipSize,
        active: size != null,
        onPressed: () => unawaited(_sizeSheet(context, controller)),
        onClear: controller.setSize,
      ),
      if (canSeeAll || state.hidden != HiddenFilter.exclude)
        chip(
          label: switch (state.hidden) {
            HiddenFilter.exclude => l10n.searchChipHidden,
            HiddenFilter.include => l10n.searchHiddenInclude,
            HiddenFilter.only => l10n.searchHiddenOnly,
          },
          active: state.hidden != HiddenFilter.exclude,
          onPressed: () => unawaited(_hiddenSheet(context, controller)),
          onClear: () => controller.setHidden(HiddenFilter.exclude),
        ),
      if (onlyFolder != null)
        Padding(
          padding: EdgeInsetsDirectional.only(end: spacing),
          child: FilterChip(
            label: Text(l10n.searchOnlyIn(nameOfFolder(l10n, onlyFolder))),
            selected: state.onlyInFolder,
            onSelected: (only) => controller.setOnlyInFolder(only: only),
          ),
        ),
    ];
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
        children: children,
      ),
    );
  }
}

/// A token chip's text: "Type: .jpg", or the keyword's own label.
String tokenLabel(SearchToken token, AppLocalizations l10n) => switch (token) {
  ExtensionToken(:final ext) => l10n.searchTokenExtension(ext),
  KeywordToken(:final keyword) => keyword.chipLabel(l10n),
  NameToken(:final raw) => raw,
};

Future<void> _typeSheet(
  BuildContext context,
  SearchScreenControllerProvider provider,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => Consumer(
    builder: (context, ref, _) {
      final l10n = context.l10n;
      final kinds = ref.watch(provider.select((s) => s.kinds));
      final controller = ref.read(provider.notifier);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final kind in browseKinds)
                    CheckboxListTile(
                      title: Text(kindLabel(l10n, kind)),
                      value: kinds.contains(kind),
                      onChanged: (on) => controller.setKinds(
                        on ?? false
                            ? {...kinds, kind}
                            : ({...kinds}..remove(kind)),
                      ),
                    ),
                ],
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: EdgeInsets.all(context.tokens.spacing),
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.searchDone),
                ),
              ),
            ),
          ],
        ),
      );
    },
  ),
);

Future<void> _sourceSheet(
  BuildContext context,
  SearchScreenControllerProvider provider,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => Consumer(
    builder: (context, ref, _) {
      final l10n = context.l10n;
      final state = ref.watch(provider);
      final base = state.query.copyWith(sources: const {}, panoramaOnly: false);
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final source in searchSources)
              Consumer(
                builder: (context, ref, _) {
                  final count =
                      ref
                          .watch(browseCountProvider(source.apply(base)))
                          .value ??
                      0;
                  final selected = state.source == source;
                  if (count == 0 && !selected) return const SizedBox.shrink();
                  return ListTile(
                    title: Text(source.label(l10n)),
                    trailing: Text(l10n.browseFileCount(count)),
                    selected: selected,
                    onTap: () {
                      ref.read(provider.notifier).setSource(source);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
          ],
        ),
      );
    },
  ),
);

Future<void> _dateSheet(
  BuildContext context,
  SearchScreenController controller,
) async {
  final l10n = context.l10n;
  final now = controller.clock();
  final choice = await showModalBottomSheet<DateFilter>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final (label, filter) in <(String, DateFilter)>[
            (l10n.searchDateToday, const DateLastDays(1)),
            (l10n.searchDateWeek, const DateLastDays(7)),
            (l10n.searchDateMonth, const DateThisMonth()),
            (l10n.searchDateYear, DateRange(DateTime(now.year), now)),
          ])
            ListTile(
              title: Text(label),
              onTap: () => Navigator.of(context).pop(filter),
            ),
          ListTile(
            title: Text(l10n.searchDateCustom),
            onTap: () async {
              final navigator = Navigator.of(context);
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(1970),
                lastDate: now,
              );
              if (range == null) return;
              navigator.pop(DateRange(range.start, range.end));
            },
          ),
        ],
      ),
    ),
  );
  if (choice != null) controller.setDate(choice);
}

Future<void> _sizeSheet(
  BuildContext context,
  SearchScreenController controller,
) async {
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).toLanguageTag();
  String label(SizePreset p) {
    final probe = SearchState(minSizeBytes: p.min, maxSizeBytes: p.max);
    return sizeLabel(probe, l10n, locale)!;
  }

  // `(preset: null)` = Custom; null = dismissed.
  final choice = await showModalBottomSheet<({SizePreset? preset})>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final p in SizePreset.values)
            ListTile(
              title: Text(label(p)),
              onTap: () => Navigator.of(context).pop((preset: p)),
            ),
          ListTile(
            title: Text(l10n.searchSizeCustom),
            onTap: () => Navigator.of(context).pop((preset: null)),
          ),
        ],
      ),
    ),
  );
  if (choice == null) return;
  if (choice.preset case final p?) {
    controller.setSize(min: p.min, max: p.max);
    return;
  }
  if (!context.mounted) return;
  final range = await showDialog<({int? min, int? max})>(
    context: context,
    builder: (context) => const SizeRangeDialog(),
  );
  if (range == null || (range.min == null && range.max == null)) return;
  controller.setSize(min: range.min, max: range.max);
}

Future<void> _hiddenSheet(
  BuildContext context,
  SearchScreenController controller,
) async {
  final l10n = context.l10n;
  final choice = await showModalBottomSheet<HiddenFilter>(
    context: context,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text(l10n.searchHiddenInclude),
            onTap: () => Navigator.of(context).pop(HiddenFilter.include),
          ),
          ListTile(
            title: Text(l10n.searchHiddenOnly),
            onTap: () => Navigator.of(context).pop(HiddenFilter.only),
          ),
        ],
      ),
    ),
  );
  if (choice != null) controller.setHidden(choice);
}

/// Custom size range in MB; min > max is rejected.
class SizeRangeDialog extends StatefulWidget {
  const new({super.key});

  @override
  State<SizeRangeDialog> createState() => _SizeRangeDialogState();
}

class _SizeRangeDialogState extends State<SizeRangeDialog> {
  final _min = TextEditingController();
  final _max = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  static int? _bytes(String text) {
    final mb = double.tryParse(text.trim().replaceAll(',', '.'));
    return mb == null || mb < 0 ? null : (mb * 1024 * 1024).round();
  }

  void _ok() {
    final min = _bytes(_min.text);
    final max = _bytes(_max.text);
    if (min != null && max != null && min > max) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop((min: min, max: max));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatters = [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))];
    return AlertDialog(
      title: Text(l10n.searchSizeCustomTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('search-size-min'),
            controller: _min,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: formatters,
            decoration: InputDecoration(labelText: l10n.searchSizeMinLabel),
          ),
          TextField(
            key: const ValueKey('search-size-max'),
            controller: _max,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: formatters,
            decoration: InputDecoration(
              labelText: l10n.searchSizeMaxLabel,
              errorText: _invalid ? l10n.searchSizeInvalid : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(onPressed: _ok, child: Text(l10n.ok)),
      ],
    );
  }
}

/// Empty field, no chips: recent searches (Browse's, same repository) and
/// suggestions.
class _EmptySearch extends ConsumerWidget {
  const new({required this.provider});

  final SearchScreenControllerProvider provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final recents =
        ref.watch(recentSearchesProvider).value ?? const <RecentSearch>[];
    final controller = ref.read(provider.notifier);
    final title = Theme.of(context).textTheme.titleSmall;
    final suggestions = <(String, VoidCallback)>[
      (
        l10n.searchSuggestLarge,
        () => controller.setSize(min: 100 * 1024 * 1024),
      ),
      (
        l10n.searchSuggestDownloads,
        () => controller.setSource(BrowseSourceChip.downloads),
      ),
      (
        l10n.searchSuggestPdfs,
        () => controller
          ..edit('pdf')
          ..submit(),
      ),
      (l10n.searchSuggestHidden, () => controller.setHidden(HiddenFilter.only)),
      (l10n.searchSuggestWeek, () => controller.setDate(const DateLastDays(7))),
    ];
    return ListView(
      children: [
        if (recents.isNotEmpty) ...[
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              spacing * 2,
              spacing * 2,
              spacing * 2,
              spacing / 2,
            ),
            child: Text(l10n.searchRecent, style: title),
          ),
          for (final r in recents)
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(
                r.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => controller.openRecent(r),
            ),
        ],
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            spacing * 2,
            spacing * 2,
            spacing * 2,
            spacing / 2,
          ),
          child: Text(l10n.searchSuggestions, style: title),
        ),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing / 2,
            children: [
              for (final (label, onTap) in suggestions)
                ActionChip(label: Text(label), onPressed: onTap),
            ],
          ),
        ),
      ],
    );
  }
}
