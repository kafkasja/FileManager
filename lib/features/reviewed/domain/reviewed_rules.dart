import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';

/// Modified times compare in whole seconds: MediaStore stores seconds,
/// dart:io milliseconds (TASK-P7).
bool sameSecond(int aMs, int bMs) => aMs ~/ 1000 == bMs ~/ 1000;

/// Which reviewed predicate the deck uses. An explicit filter value wins;
/// otherwise reviewed files are skipped unless [includeReviewed].
ReviewedClause? deckReviewedClause({
  required int presetKey,
  required ReviewedFilterMode mode,
  required bool includeReviewed,
}) => switch (mode) {
  ReviewedFilterMode.reviewed => ReviewedClause(
    presetKey: presetKey,
    reviewed: true,
  ),
  ReviewedFilterMode.notReviewed => ReviewedClause(
    presetKey: presetKey,
    reviewed: false,
  ),
  ReviewedFilterMode.any =>
    includeReviewed
        ? null
        : ReviewedClause(presetKey: presetKey, reviewed: false),
};
