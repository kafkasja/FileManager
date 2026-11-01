import 'dart:convert';

import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/filters/data/filter_query.dart';
import 'package:kfm/features/swipe/data/swipe_source_repository.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swipe_source_resolver.g.dart';

/// Validates and resolves a [SwipeSourceRequest] into a [PreparedSource]
/// (TASK-SS1). Reads only; the launcher writes the result.
class SwipeSourceResolver {
  new(this._index, this._files, {this._clock = DateTime.now});

  final MediaIndexDao _index;
  final FileSource _files;
  final DateTime Function() _clock;

  static const _chunk = 500;

  /// Ids not in the index are looked up one at a time, at most this many
  /// (X1's app-private copies aren't indexed). The rest count as missing.
  static const maxStatLookups = 500;

  /// The prepared source, or null with a [SwipeSourceNotOpened].
  Future<(PreparedSource?, SwipeSourceOpenResult)> prepare(
    SwipeSourceRequest r,
  ) async => switch (r) {
    FilterSourceRequest() => await _filter(r),
    FilesSourceRequest(:final fileIds) => await _list(r, [
      for (final id in fileIds) (id, null),
    ], grouped: false),
    GroupsSourceRequest(:final groups) => await _list(r, [
      for (final (g, ids) in groups.indexed)
        for (final id in ids) (id, g),
    ], grouped: true),
  };

  Future<(PreparedSource?, SwipeSourceOpenResult)> _filter(
    FilterSourceRequest r,
  ) async {
    final filter = r.filter;
    if (!filter.isValid) {
      return (
        null,
        const SwipeSourceNotOpened(SwipeSourceProblem.invalidFilter),
      );
    }
    // The deck's swipe base (images + videos). No reviewed clause: the
    // preset isn't known here.
    final query = toIndexQuery(filter, now: _clock());
    final count = query == null ? 0 : await _index.count(query);
    if (count == 0) {
      return (null, const SwipeSourceNotOpened(SwipeSourceProblem.noMatches));
    }
    return (
      PreparedSource(
        kind: SwipeSourceKind.filter,
        origin: r.origin,
        title: swipeSourceTitle(r.title),
        filterJson: jsonEncode(filter.toJson()),
        returnRoute: r.returnRoute,
      ),
      SwipeSourceOpened(files: count),
    );
  }

  Future<(PreparedSource?, SwipeSourceOpenResult)> _list(
    SwipeSourceRequest r,
    List<(String, int?)> flat, {
    required bool grouped,
  }) async {
    // Drop empty ids, de-duplicate (first occurrence wins), cap.
    final seen = <String>{};
    final ids = <(String, int?)>[];
    for (final e in flat) {
      if (e.$1.isEmpty || !seen.add(e.$1)) continue;
      ids.add(e);
    }
    if (ids.isEmpty) {
      return (null, const SwipeSourceNotOpened(SwipeSourceProblem.empty));
    }
    final truncated = ids.length > kMaxSourceItems;
    final kept = truncated ? ids.sublist(0, kMaxSourceItems) : ids;

    final kinds = <String, FileKind>{};
    for (var i = 0; i < kept.length; i += _chunk) {
      final end = i + _chunk > kept.length ? kept.length : i + _chunk;
      final found = await _index.byIds([
        for (final (id, _) in kept.sublist(i, end)) id,
      ]);
      for (final f in found) {
        kinds[f.id] = f.kind;
      }
    }
    var lookups = 0;
    for (final (id, _) in kept) {
      if (kinds.containsKey(id)) continue;
      if (lookups >= maxStatLookups) break;
      lookups++;
      final f = await _files.stat(id);
      if (f != null) kinds[id] = f.kind;
    }

    var notMedia = 0;
    var missing = 0;
    final media = <(String, int?)>[];
    for (final e in kept) {
      switch (kinds[e.$1]) {
        case null:
          missing++;
        case FileKind.image || FileKind.video:
          media.add(e);
        case _:
          notMedia++;
      }
    }
    if (media.isEmpty) {
      return (
        null,
        SwipeSourceNotOpened(
          notMedia > 0 ? SwipeSourceProblem.noMedia : SwipeSourceProblem.empty,
        ),
      );
    }

    // Renumber the groups that still have a file: 0..n-1, no gaps.
    final renumber = <int, int>{};
    final items = [
      for (final (id, g) in media)
        (id, g == null ? null : renumber.putIfAbsent(g, () => renumber.length)),
    ];
    return (
      PreparedSource(
        kind: grouped ? SwipeSourceKind.groups : SwipeSourceKind.files,
        origin: r.origin,
        title: swipeSourceTitle(r.title),
        items: items,
        groupCount: grouped ? renumber.length : null,
        returnRoute: r.returnRoute,
      ),
      SwipeSourceOpened(
        files: items.length,
        skippedNotMedia: notMedia,
        skippedMissing: missing,
        truncated: truncated,
      ),
    );
  }
}

@Riverpod(keepAlive: true)
SwipeSourceResolver swipeSourceResolver(Ref ref) => SwipeSourceResolver(
  ref.watch(mediaIndexDaoProvider),
  ref.watch(fileSourceProvider),
);
