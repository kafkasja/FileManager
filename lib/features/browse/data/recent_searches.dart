import 'dart:convert';
import 'dart:developer' as developer;

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/index_query_json.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recent_searches.g.dart';

/// A search the user ran (B8 name/date/type/size search, C4 smart search),
/// shown as a "recent" card at the front of Browse's carousel.
@immutable
class RecentSearch {
  const new({
    required this.title,
    required this.query,
    required this.at,
    this.text,
    this.demoted = const {},
  });

  factory fromJson(Map<String, Object?> j) => RecentSearch(
    title: j['title']! as String,
    query: indexQueryFromJson((j['query']! as Map).cast<String, Object?>()),
    at: DateTime.fromMillisecondsSinceEpoch(j['at']! as int, isUtc: true),
    text: j['text'] as String?,
    demoted: {
      for (final d in (j['demoted'] as List<Object?>?) ?? const <Object?>[])
        d! as String,
    },
  );

  /// What the user typed / picked, e.g. "beach" or "PDF > 10 MB".
  final String title;
  final IndexQuery query;
  final DateTime at;

  /// B8: the search field's text (may be empty), so opening the search
  /// rebuilds its word chips. Null for searches made elsewhere.
  final String? text;

  /// B8: lower-case words of [text] whose chip ✕ made them name words.
  final Set<String> demoted;

  Map<String, Object?> toJson() => {
    'title': title,
    'query': indexQueryToJson(query),
    'at': at.millisecondsSinceEpoch,
    'text': ?text,
    if (demoted.isNotEmpty) 'demoted': demoted.toList()..sort(),
  };
}

/// The last [max] searches, newest first, kept across restarts (user
/// decision 2026-10-29). B8 and C4 call [add] when a search runs.
///
/// [add] and [remove] read, change and write the list, so they run one at a
/// time (in call order). Callers may `.fireAndForget()`: a failed write is
/// published by the write queue, a failed read through `onError` (wired to
/// `dbWriteErrorsProvider`).
class RecentSearchesRepository {
  new(this._settings, {DateTime Function()? clock, this._onError})
    : _clock = clock ?? DateTime.now;

  static const max = 5;

  final SettingsRepository _settings;
  final DateTime Function() _clock;
  final void Function(Object error, StackTrace stackTrace)? _onError;

  /// The last queued [add] / [remove] (never fails, so the chain goes on).
  Future<void> _tail = Future<void>.value();

  Stream<List<RecentSearch>> watch() =>
      _settings.watch(AppSettings.browseRecentSearches).map(decode);

  /// Moves an equal query to the front instead of adding it twice.
  Future<void> add(
    String title,
    IndexQuery query, {
    String? text,
    Set<String> demoted = const {},
  }) => _serial(
    (current) => [
      RecentSearch(
        title: title,
        query: query,
        at: _clock().toUtc(),
        text: text,
        demoted: demoted,
      ),
      for (final r in current)
        if (r.query != query) r,
    ].take(max).toList(),
  );

  Future<void> remove(RecentSearch search) => _serial(
    (current) => [
      for (final r in current)
        if (r.query != search.query || r.title != search.title) r,
    ],
  );

  Future<void> _serial(
    List<RecentSearch> Function(List<RecentSearch> current) change,
  ) {
    final run = _tail.then((_) async {
      final String raw;
      try {
        raw = await _settings.read(AppSettings.browseRecentSearches);
      } on Object catch (e, st) {
        _onError?.call(e, st);
        rethrow;
      }
      // Write failures are published by the write queue itself.
      await _write(change(decode(raw)));
    });
    _tail = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  Future<void> _write(List<RecentSearch> list) => _settings.write(
    AppSettings.browseRecentSearches,
    jsonEncode([for (final r in list) r.toJson()]),
  );

  /// Corrupt data is logged and gives an empty list (never blocks Browse).
  static List<RecentSearch> decode(String raw) {
    if (raw.isEmpty) return const [];
    try {
      return List.unmodifiable([
        for (final item in jsonDecode(raw) as List<Object?>)
          RecentSearch.fromJson((item! as Map).cast<String, Object?>()),
      ]);
    } on Object catch (e, st) {
      developer.log(
        'corrupt recent searches, ignoring',
        name: 'kfm.browse',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }
}

@Riverpod(keepAlive: true)
RecentSearchesRepository recentSearchesRepository(Ref ref) {
  final queue = ref.watch(dbWriteQueueProvider);
  return RecentSearchesRepository(
    ref.watch(settingsRepositoryProvider),
    onError: (e, st) => queue.report('recentSearches', e, st),
  );
}

@riverpod
Stream<List<RecentSearch>> recentSearches(Ref ref) =>
    ref.watch(recentSearchesRepositoryProvider).watch();
