import 'package:flutter/foundation.dart' show setEquals;
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:kfm/core/utils/debouncer.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/browse/data/recent_searches.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/browse/ui/widgets/browse_parts.dart';
import 'package:kfm/features/browse/ui/widgets/sources_row.dart';
import 'package:kfm/features/filters/data/filter_query.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/search/data/search_vocabulary.dart';
import 'package:kfm/features/search/domain/search_keyword.dart';
import 'package:kfm/features/search/domain/search_parser.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_controller.g.dart';

/// The Size chip's presets (TASK-B8 §5).
enum SizePreset {
  over10Mb(min: 10 * _mb),
  over100Mb(min: 100 * _mb),
  over1Gb(min: 1024 * _mb),
  under1Mb(max: _mb),
  tiny(max: 10 * 1024);

  new({this.min, this.max});

  final int? min;
  final int? max;
}

const int _mb = 1024 * 1024;

/// Sources offered by the Source chip (Videos and Hidden have their own
/// chips).
final List<BrowseSourceChip> searchSources = [
  for (final s in BrowseSourceChip.values)
    if (s != BrowseSourceChip.videos && s != BrowseSourceChip.hidden) s,
];

/// What the search screen shows. Immutable.
@immutable
class SearchState {
  const new({
    this.text = '',
    this.tokens = const [],
    this.demoted = const {},
    this.kinds = const {},
    this.source,
    this.date = const DateAny(),
    this.from,
    this.to,
    this.minSizeBytes,
    this.maxSizeBytes,
    this.hidden = HiddenFilter.exclude,
    this.folder,
    this.onlyIn,
    this.query = IndexQuery.all,
    this.matchesNothing = false,
  });

  /// The field's text (immediate).
  final String text;

  /// [text] parsed (debounced, in step with [query]).
  final List<SearchToken> tokens;

  /// Lower-case raws whose chip's ✕ turned them into a name search.
  final Set<String> demoted;

  final Set<FileKind> kinds;
  final BrowseSourceChip? source;

  /// The Date chip's choice; [from]/[to] are its bounds, fixed when picked.
  final DateFilter date;
  final DateTime? from;
  final DateTime? to;

  final int? minSizeBytes;
  final int? maxSizeBytes;
  final HiddenFilter hidden;

  /// The folder the search was opened from (null = Browse's top level).
  final String? folder;

  /// The "Only in" chip's folder (subfolders included), null = off. Usually
  /// [folder]; a reopened recent search brings back its own.
  final String? onlyIn;

  /// What gets paged (debounced; carries the Browse sort).
  final IndexQuery query;

  /// A chip and the typed words of the same family have nothing in common
  /// ("video" typed + Type: Images): no results, whatever [query] says.
  final bool matchesNothing;

  bool get hasDate => from != null || to != null;
  bool get hasSize => minSizeBytes != null || maxSizeBytes != null;
  bool get onlyInFolder => onlyIn != null;

  bool get hasChips =>
      kinds.isNotEmpty ||
      source != null ||
      hasDate ||
      hasSize ||
      hidden != HiddenFilter.exclude ||
      onlyInFolder;

  /// Nothing typed or picked: the recent searches and suggestions show.
  /// Uses the parsed [tokens] (not [text]), so while a keystroke waits for
  /// its parse the previous results stay up.
  bool get isEmpty => tokens.isEmpty && !hasChips;

  /// The name words of [tokens], lower-case (for highlighting).
  List<String> get nameWords => [
    for (final t in tokens)
      if (t is NameToken)
        for (final w in t.raw.toLowerCase().split(RegExp(r'\s+')))
          if (w.isNotEmpty) w,
  ];

  /// The tokens that show as chips (extensions and keywords).
  List<SearchToken> get chipTokens => [
    for (final t in tokens)
      if (t is! NameToken) t,
  ];

  SearchState copyWith({
    String? text,
    List<SearchToken>? tokens,
    Set<String>? demoted,
    Set<FileKind>? kinds,
    BrowseSourceChip? Function()? source,
    DateFilter? date,
    DateTime? Function()? from,
    DateTime? Function()? to,
    int? Function()? minSizeBytes,
    int? Function()? maxSizeBytes,
    HiddenFilter? hidden,
    String? Function()? onlyIn,
    IndexQuery? query,
    bool? matchesNothing,
  }) => SearchState(
    text: text ?? this.text,
    tokens: tokens ?? this.tokens,
    demoted: demoted ?? this.demoted,
    kinds: kinds ?? this.kinds,
    source: source == null ? this.source : source(),
    date: date ?? this.date,
    from: from == null ? this.from : from(),
    to: to == null ? this.to : to(),
    minSizeBytes: minSizeBytes == null ? this.minSizeBytes : minSizeBytes(),
    maxSizeBytes: maxSizeBytes == null ? this.maxSizeBytes : maxSizeBytes(),
    hidden: hidden ?? this.hidden,
    folder: folder,
    onlyIn: onlyIn == null ? this.onlyIn : onlyIn(),
    query: query ?? this.query,
    matchesNothing: matchesNothing ?? this.matchesNothing,
  );
}

/// The search screen's text, tokens and filter chips (TASK-B8 §5–§6). The
/// text is parsed 150 ms after the last keystroke; chips apply at once.
/// [folder] is the folder it was opened from ("Only in" chip).
///
/// Recording a recent search: on submit, when the screen closes, or
/// [recordDelay] after a chip change with no change (text or chip) since.
/// Typing cancels a pending chip record, so half-typed text is only saved
/// by submit or close. Empty searches, searches that can't match, and the
/// same query twice in a row are never recorded. What's recorded is always
/// `_parsed` of the current state: exactly what the screen shows.
@riverpod
class SearchScreenController extends _$SearchScreenController {
  static const debounce = Duration(milliseconds: 150);

  /// Chip changes are recorded as a recent search once they settle.
  static const recordDelay = Duration(milliseconds: 1500);

  final _parse = Debouncer(debounce);
  final _record = Debouncer(recordDelay);
  SearchVocabulary _vocab = SearchVocabulary.empty;
  FileSort _sort = FileSort.newestFirst;
  AppLocalizations? _l10n;
  late RecentSearchesRepository _recents;

  SearchState? _latest;

  /// Typed or picked since the last recorded search.
  bool _unrecorded = false;

  /// The query last recorded (or reopened) here.
  IndexQuery? _lastRecorded;

  /// The clock for date chips (tests override it).
  DateTime Function() clock = DateTime.now;

  @override
  SearchState build(String? folder) {
    _recents = ref.read(recentSearchesRepositoryProvider);
    _vocab = ref.read(searchVocabularyProvider).value ?? SearchVocabulary.empty;
    _sort = ref.read(browseViewControllerProvider).sort;
    // Listen, don't watch: a new vocabulary or sort must not reset the text.
    ref
      ..listen(searchVocabularyProvider, (_, next) {
        if (next.value case final vocab?) {
          _vocab = vocab;
          _rebuild();
        }
      })
      ..listen(browseViewControllerProvider, (_, view) {
        if (view.sort.field == _sort.field &&
            view.sort.descending == _sort.descending) {
          return;
        }
        _sort = view.sort;
        _rebuild();
      })
      ..onDispose(() {
        _parse.cancel();
        _record.cancel();
        // `state` can't be read while disposing: the last value is kept.
        final last = _latest;
        if (_unrecorded && last != null) _recordNow(last);
      });
    listenSelf((_, next) => _latest = next);
    return SearchState(
      folder: folder,
      query: IndexQuery(sort: _sort),
    );
  }

  /// The screen hands over its strings (recent search titles).
  // ignore: use_setters_to_change_properties, reads better at the call site
  void attach(AppLocalizations l10n) => _l10n = l10n;

  void edit(String text) {
    if (text == state.text) return;
    state = state.copyWith(text: text);
    _unrecorded = true;
    _record.cancel();
    _parse.run(_rebuild);
  }

  /// Enter on the keyboard: apply now and record the search.
  void submit() {
    _flushParse();
    _recordNow(state);
  }

  /// A token chip's ✕: that word becomes a plain name search. The text
  /// stays as typed; a pending parse runs first so no keystroke is lost.
  void demote(SearchToken token) {
    _flushParse();
    state = state.copyWith(
      demoted: {...state.demoted, token.raw.toLowerCase()},
    );
    _changed();
  }

  void setKinds(Set<FileKind> kinds) {
    state = state.copyWith(kinds: Set.unmodifiable(kinds));
    _changed();
  }

  void setSource(BrowseSourceChip? source) {
    state = state.copyWith(source: () => source);
    _changed();
  }

  /// Bounds are fixed now (via [dateBounds]), so the query stays the same
  /// while the screen is open.
  void setDate(DateFilter date) {
    final (:from, :to) = dateBounds(date, clock());
    state = state.copyWith(date: date, from: () => from, to: () => to);
    _changed();
  }

  /// False (and nothing changes) when [min] > [max].
  bool setSize({int? min, int? max}) {
    if (min != null && max != null && min > max) return false;
    state = state.copyWith(minSizeBytes: () => min, maxSizeBytes: () => max);
    _changed();
    return true;
  }

  void setHidden(HiddenFilter hidden) {
    state = state.copyWith(hidden: hidden);
    _changed();
  }

  /// On = the folder the screen was opened from.
  void setOnlyInFolder({required bool only}) {
    final folder = state.folder;
    state = state.copyWith(onlyIn: () => only ? folder : null);
    _changed();
  }

  /// Empties the field and every chip.
  void clearAll() {
    _parse.cancel();
    _record.cancel();
    _unrecorded = false;
    state = SearchState(
      folder: state.folder,
      query: IndexQuery(sort: _sort),
    );
    _rebuild();
  }

  /// A recent search tapped: its text, word chips and filter chips come
  /// back, so the screen's query is the stored one again (with the current
  /// Browse sort). The text is re-parsed (with its ✕'d words), then every
  /// filter the words don't produce becomes a chip. Searches recorded
  /// elsewhere (no text) get their extensions and name words as text.
  /// Opening records nothing; a later change does.
  void openRecent(RecentSearch recent) {
    _parse.cancel();
    _record.cancel();
    final q = recent.query;
    final nameWords = [
      ...?q.nameContains?.split(RegExp(r'\s+')).where((w) => w.isNotEmpty),
    ];
    final text =
        recent.text ??
        [
          for (final e in q.extensions.toList()..sort()) '.$e',
          ...nameWords,
        ].join(' ');
    final demoted = recent.text != null
        ? recent.demoted
        : {for (final w in nameWords) w.toLowerCase()};
    final typed = applyTokens(IndexQuery.all, _tokensOf(text, demoted));

    // Typed words override these chip values when they set them.
    final from = typed.from == null ? q.from : null;
    final to = q.to;
    final chipSources =
        typed.sources.isNotEmpty && setEquals(q.sources, typed.sources)
        ? const <SourceBucket>{}
        : q.sources;
    BrowseSourceChip? source;
    if (chipSources.isNotEmpty) {
      for (final s in searchSources) {
        final applied = s.apply(IndexQuery.all);
        if (!applied.panoramaOnly && setEquals(applied.sources, chipSources)) {
          source = s;
        }
      }
    } else if (q.panoramaOnly && !typed.panoramaOnly) {
      source = BrowseSourceChip.panoramas;
    }

    state = SearchState(
      folder: state.folder,
      text: text,
      demoted: demoted,
      kinds: typed.kinds.isNotEmpty && setEquals(q.kinds, typed.kinds)
          ? const {}
          : q.kinds,
      source: source,
      date: switch ((from, to)) {
        (null, null) => const DateAny(),
        (final f?, null) => DateRange(f.toLocal(), clock()),
        (null, final t?) => DateRange(DateTime(1970), dayBefore(t)),
        (final f?, final t?) => DateRange(f.toLocal(), dayBefore(t)),
      },
      from: from,
      to: to,
      minSizeBytes: typed.minSizeBytes == null ? q.minSizeBytes : null,
      maxSizeBytes: typed.maxSizeBytes == null ? q.maxSizeBytes : null,
      hidden: typed.hidden == HiddenFilter.exclude
          ? q.hidden
          : HiddenFilter.exclude,
      onlyIn: q.folderPath,
      query: state.query,
    );
    _rebuild();
    _unrecorded = false;
    _lastRecorded = state.query;
  }

  void _changed() {
    _unrecorded = true;
    _rebuild();
    _record.run(() {
      if (ref.mounted) _recordNow(state);
    });
  }

  /// Runs a pending parse now.
  void _flushParse() {
    _parse.cancel();
    _rebuild();
  }

  /// Parses the text and builds the query.
  void _rebuild() {
    if (!ref.mounted) return;
    state = _parsed(state);
  }

  /// [text] parsed, with the [demoted] words as name words.
  List<SearchToken> _tokensOf(String text, Set<String> demoted) => [
    for (final t in parseSearch(text, _vocab))
      if (t is! NameToken && demoted.contains(t.raw.toLowerCase()))
        NameToken(t.raw)
      else
        t,
  ];

  /// [s] with its text parsed and its query built: the one path for what
  /// the screen shows and what gets recorded.
  SearchState _parsed(SearchState s) {
    final tokens = _tokensOf(s.text, s.demoted);
    final raws = {for (final t in tokens) t.raw.toLowerCase()};
    final query = buildQuery(s, tokens, _sort);
    return s.copyWith(
      tokens: List.unmodifiable(tokens),
      demoted: {
        for (final d in s.demoted)
          if (raws.contains(d)) d,
      },
      // Can't match: the screen shows "No files match"; this query (the
      // chips' type and source left out) only feeds the source sheet.
      query:
          query ??
          buildQuery(
            s.copyWith(kinds: const {}, source: () => null),
            tokens,
            _sort,
          ),
      matchesNothing: query == null,
    );
  }

  void _recordNow(SearchState current) {
    _record.cancel();
    _unrecorded = false;
    final l10n = _l10n;
    if (l10n == null) return;
    final s = _parsed(current);
    if (s.isEmpty || s.matchesNothing) return;
    if (s.query == _lastRecorded) return;
    final title = searchTitle(s, l10n);
    if (title.isEmpty) return;
    _lastRecorded = s.query;
    _recents
        .add(
          title,
          s.query,
          text: s.text.trim().replaceAll(RegExp(r'\s+'), ' '),
          demoted: s.demoted,
        )
        .fireAndForget();
  }
}

/// The calendar day before [exclusiveEnd] (a local midnight, e.g. a date
/// chip's `to`), as a local date. Calendar arithmetic, so DST days (23 or
/// 25 hours) don't shift it.
@visibleForTesting
DateTime dayBefore(DateTime exclusiveEnd) {
  final t = exclusiveEnd.toLocal();
  return DateTime(t.year, t.month, t.day - 1);
}

/// [a] AND [b] for one family's set (kinds or sources), where empty = any:
/// one empty → the other; else their intersection, null if that's empty.
Set<T>? _both<T>(Set<T> a, Set<T> b) {
  if (a.isEmpty) return b;
  if (b.isEmpty) return a;
  final both = a.intersection(b);
  return both.isEmpty ? null : Set.unmodifiable(both);
}

/// [s]'s chips + [tokens] as an [IndexQuery] (not yet narrowed by access:
/// the pages apply `visible`). Typed type words OR among themselves
/// ("video photo" = both), and so do typed source words; a Type or Source
/// chip then ANDs with them, so typing narrows. Null when a chip and the
/// typed words of its family have nothing in common (nothing can match).
IndexQuery? buildQuery(SearchState s, List<SearchToken> tokens, FileSort sort) {
  final onlyIn = s.onlyIn;
  final typed = applyTokens(
    IndexQuery(
      sort: sort,
      hidden: s.hidden,
      from: s.from,
      to: s.to,
      minSizeBytes: s.minSizeBytes,
      maxSizeBytes: s.maxSizeBytes,
      folderPath: onlyIn,
      includeSubfolders: onlyIn != null,
    ),
    tokens,
  );
  final chip = s.source?.apply(IndexQuery.all) ?? IndexQuery.all;
  final kinds = _both(s.kinds, typed.kinds);
  final sources = _both(chip.sources, typed.sources);
  if (kinds == null || sources == null) return null;
  return typed.copyWith(
    kinds: kinds,
    sources: sources,
    panoramaOnly: typed.panoramaOnly || chip.panoramaOnly,
  );
}

/// Whether [q] (built without access narrowing) would show files that
/// need All files access: non-media kinds or extensions, hidden files,
/// Downloads, or a name search (documents match names too).
bool queryNeedsAllFiles(IndexQuery q) =>
    q.visible(canSeeAllFiles: false) == null ||
    q.kinds.any((k) => !mediaKinds.contains(k)) ||
    q.extensions.any((e) => !mediaKinds.contains(kindFor(null, 'x.$e'))) ||
    q.hidden != HiddenFilter.exclude ||
    q.sources.contains(SourceBucket.downloads) ||
    (q.nameContains?.trim().isNotEmpty ?? false);

/// The label of the Date chip for [s] (null = no date).
String? dateLabel(SearchState s, AppLocalizations l10n, String locale) {
  if (!s.hasDate) return null;
  return switch (s.date) {
    DateLastDays(days: 1) => l10n.searchDateToday,
    DateLastDays(days: 7) => l10n.searchDateWeek,
    DateLastDays() => l10n.searchDateSince(
      formatDate(s.from!.toLocal(), locale: locale),
    ),
    DateThisMonth() => l10n.searchDateMonth,
    DateRange(:final from, :final to) => l10n.searchDateRange(
      formatDate(from, locale: locale),
      formatDate(to, locale: locale),
    ),
    DateAny() => l10n.searchChipDate,
  };
}

/// The label of the Size chip for [s] (null = no size).
String? sizeLabel(SearchState s, AppLocalizations l10n, String locale) {
  final min = s.minSizeBytes;
  final max = s.maxSizeBytes;
  String fmt(int b) => formatBytes(b, locale: locale);
  if (min == null && max == null) return null;
  if (min == null && max == SizePreset.tiny.max) return l10n.searchSizeTiny;
  if (min != null && max != null) {
    return l10n.searchSizeBetween(fmt(min), fmt(max));
  }
  return min != null
      ? l10n.searchSizeOver(fmt(min))
      : l10n.searchSizeUnder(fmt(max!));
}

/// The label of the Type chip (null = all types).
String? typeLabel(SearchState s, AppLocalizations l10n) => switch (s.kinds) {
  final k when k.isEmpty => null,
  final k when k.length == 1 => kindLabel(l10n, k.first),
  final k => l10n.searchChipTypes(k.length),
};

/// A recent search's title: the text, else the chips' labels.
String searchTitle(SearchState s, AppLocalizations l10n, {String? locale}) {
  final text = s.text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.isNotEmpty) return text;
  final loc = locale ?? l10n.localeName;
  return [
    ?typeLabel(s, l10n),
    if (s.source case final source?) source.label(l10n),
    ?dateLabel(s, l10n, loc),
    ?sizeLabel(s, l10n, loc),
    if (s.hidden == HiddenFilter.include) l10n.searchHiddenInclude,
    if (s.hidden == HiddenFilter.only) l10n.searchHiddenOnly,
    if (s.onlyIn case final onlyIn?)
      l10n.searchOnlyIn(nameOfFolder(l10n, onlyIn)),
  ].join(' · ');
}
