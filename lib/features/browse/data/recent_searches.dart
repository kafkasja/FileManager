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
  const new({required this.title, required this.query, required this.at});

  factory fromJson(Map<String, Object?> j) => RecentSearch(
    title: j['title']! as String,
    query: indexQueryFromJson((j['query']! as Map).cast<String, Object?>()),
    at: DateTime.fromMillisecondsSinceEpoch(j['at']! as int, isUtc: true),
  );

  /// What the user typed / picked, e.g. "beach" or "PDF > 10 MB".
  final String title;
  final IndexQuery query;
  final DateTime at;

  Map<String, Object?> toJson() => {
    'title': title,
    'query': indexQueryToJson(query),
    'at': at.millisecondsSinceEpoch,
  };
}

/// The last [max] searches, newest first, kept across restarts (user
/// decision 2026-10-29). B8 and C4 call [add] when a search runs.
class RecentSearchesRepository {
  new(this._settings, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const max = 5;

  final SettingsRepository _settings;
  final DateTime Function() _clock;

  Stream<List<RecentSearch>> watch() =>
      _settings.watch(AppSettings.browseRecentSearches).map(decode);

  /// Moves an equal query to the front instead of adding it twice.
  Future<void> add(String title, IndexQuery query) async {
    final current = decode(
      await _settings.read(AppSettings.browseRecentSearches),
    );
    final next = [
      RecentSearch(title: title, query: query, at: _clock().toUtc()),
      for (final r in current)
        if (r.query != query) r,
    ].take(max).toList();
    await _write(next);
  }

  Future<void> remove(RecentSearch search) async {
    final current = decode(
      await _settings.read(AppSettings.browseRecentSearches),
    );
    await _write([
      for (final r in current)
        if (r.query != search.query || r.title != search.title) r,
    ]);
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
RecentSearchesRepository recentSearchesRepository(Ref ref) =>
    RecentSearchesRepository(ref.watch(settingsRepositoryProvider));

@riverpod
Stream<List<RecentSearch>> recentSearches(Ref ref) =>
    ref.watch(recentSearchesRepositoryProvider).watch();
