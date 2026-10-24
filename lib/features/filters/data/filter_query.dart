import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/swipe/data/swipe_queue_repository.dart';

/// [f] on top of [base] (swipe: images + videos, newest first). Date bounds
/// are local calendar days converted to UTC, computed from [now]. Null = the
/// filter can't match anything here (e.g. documents in swipe mode). P7 adds
/// its reviewed clause here.
IndexQuery? toIndexQuery(
  FileFilter f, {
  required DateTime now,
  IndexQuery base = swipeQuery,
  ReviewedClause? reviewed,
}) {
  final kinds = f.kinds.isEmpty
      ? base.kinds
      : (base.kinds.isEmpty ? f.kinds : f.kinds.intersection(base.kinds));
  // `kinds: {}` would mean "all", never "none".
  if (f.kinds.isNotEmpty && kinds.isEmpty) return null;
  final (from, to) = switch (f.date) {
    DateAny() => (null, null),
    DateThisMonth() => (
      DateTime(now.year, now.month),
      DateTime(now.year, now.month + 1),
    ),
    DateLastDays(:final days) => (
      DateTime(now.year, now.month, now.day - days + 1),
      null,
    ),
    DateRange(:final from, :final to) => (
      DateTime(from.year, from.month, from.day),
      DateTime(to.year, to.month, to.day + 1),
    ),
  };
  return base.copyWith(
    kinds: kinds,
    from: from?.toUtc(),
    to: to?.toUtc(),
    minSizeBytes: f.minSizeBytes,
    maxSizeBytes: f.maxSizeBytes,
    folderPaths: f.folderPaths,
    screenshotsOnly: f.screenshotsOnly,
    tagged: switch (f.tagMode) {
      TagFilterMode.tagged => true,
      TagFilterMode.untagged => false,
      TagFilterMode.any || TagFilterMode.hasTags => null,
    },
    anyTagIds: f.tagMode == TagFilterMode.hasTags ? f.tagIds : const {},
    favoritesOnly: f.favoritesOnly,
    reviewed: reviewed,
  );
}
