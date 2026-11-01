import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:kfm/features/filters/data/filter_query.dart';
import 'package:kfm/features/storage/domain/storage_category.dart';

/// What a category's totals count: every kind, hidden rows when the
/// category says so, only what's visible with [canSeeAllFiles]. Null =
/// nothing of it is visible.
IndexQuery? storageTotalsQuery(
  StorageCategory c, {
  required DateTime now,
  required bool canSeeAllFiles,
}) => toIndexQuery(c.filter, now: now, base: IndexQuery.all)
    ?.copyWith(
      hidden: c.countHidden ? HiddenFilter.include : HiddenFilter.exclude,
    )
    .visible(canSeeAllFiles: canSeeAllFiles);

/// What "Clean up" swipes: the SS1 filter source's own query (photos and
/// videos, hidden excluded).
IndexQuery? storageSwipeQuery(StorageCategory c, {required DateTime now}) =>
    toIndexQuery(c.filter, now: now);

Future<StorageCategoryTotal> storageCategoryTotal(
  MediaIndexDao dao,
  StorageCategory c, {
  required DateTime now,
  required bool canSeeAllFiles,
}) async {
  final totals = storageTotalsQuery(
    c,
    now: now,
    canSeeAllFiles: canSeeAllFiles,
  );
  final swipe = storageSwipeQuery(c, now: now);
  final (count, bytes, swipeable) = await (
    totals == null ? Future.value(0) : dao.count(totals),
    totals == null ? Future.value(0) : dao.totalBytes(totals),
    swipe == null ? Future.value(0) : dao.count(swipe),
  ).wait;
  // Downloads (and anything non-media) is incomplete without access.
  final needsAccess =
      !canSeeAllFiles &&
      (totals == null || c.filter.sources.contains(SourceBucket.downloads));
  return StorageCategoryTotal(
    category: c,
    fileCount: count,
    totalBytes: bytes,
    swipeableCount: swipeable,
    needsAccess: needsAccess,
  );
}

/// The 20 biggest visible files (hidden excluded).
Future<List<FileRef>> biggestFiles(
  MediaIndexDao dao, {
  required bool canSeeAllFiles,
  int limit = 20,
}) async {
  final q = IndexQuery.all
      .copyWith(sort: const FileSort(FileSortField.size))
      .visible(canSeeAllFiles: canSeeAllFiles);
  if (q == null) return const [];
  return (await dao.page(q, limit: limit)).items;
}
