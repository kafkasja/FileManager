import 'package:kfm/core/db/tables/swipe_sources_table.dart'
    show SwipeSourceKind, SwipeSourceOrigin;
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:meta/meta.dart';

export 'package:kfm/core/db/tables/swipe_sources_table.dart'
    show SwipeSourceKind, SwipeSourceOrigin;

/// Max files a list/group source keeps (the rest is cut, see OpenResult).
const kMaxSourceItems = 10000;

/// What a caller asks to swipe.
@immutable
sealed class SwipeSourceRequest {
  const new({required this.origin, required this.title, this.returnRoute});

  final SwipeSourceOrigin origin;

  /// Source bar text, 1–80 chars (longer is cut with an ellipsis).
  final String title;

  /// Where "Back to …" goes when the source is finished (e.g. '/browse').
  final String? returnRoute;
}

/// A P5 filter (C1 categories, X4 "On cloud"; B8 when the query fits).
final class FilterSourceRequest extends SwipeSourceRequest {
  const new({
    required super.origin,
    required super.title,
    required this.filter,
    super.returnRoute,
  });

  final FileFilter filter;
}

/// An explicit list in this order (C4/B8 results, C5/B3 one group, X1).
final class FilesSourceRequest extends SwipeSourceRequest {
  const new({
    required super.origin,
    required super.title,
    required this.fileIds,
    super.returnRoute,
  });

  final List<String> fileIds;
}

/// Several groups, swiped group by group (C2 "Duplicates in swipe mode").
final class GroupsSourceRequest extends SwipeSourceRequest {
  const new({
    required super.origin,
    required super.title,
    required this.groups,
    super.returnRoute,
  });

  /// Each inner list = one group in display order (e.g. C2's best first).
  final List<List<String>> groups;
}

/// The source currently open on a session (row of swipe_sources).
@immutable
class OpenSwipeSource {
  const new({
    required this.id,
    required this.sessionId,
    required this.kind,
    required this.origin,
    required this.title,
    required this.itemCount,
    required this.openedAfterSeq,
    this.filter,
    this.groupCount,
    this.returnRoute,
  });

  final int id;
  final int sessionId;
  final SwipeSourceKind kind;
  final SwipeSourceOrigin origin;
  final String title;
  final FileFilter? filter;
  final int itemCount;
  final int? groupCount;
  final String? returnRoute;
  final int openedAfterSeq;
}

/// Group position of the current card (kind = groups).
@immutable
class SwipeGroupPosition {
  const new({
    required this.group,
    required this.groupCount,
    required this.index,
    required this.groupSize,
  });

  /// 1-based.
  final int group;
  final int groupCount;

  /// 1-based position inside the group (counting already-swiped files).
  final int index;
  final int groupSize;
}

/// Why a request opened nothing.
enum SwipeSourceProblem { empty, noMedia, invalidFilter, noMatches }

@immutable
sealed class SwipeSourceOpenResult {
  const new();
}

final class SwipeSourceOpened extends SwipeSourceOpenResult {
  const new({
    required this.files,
    this.skippedNotMedia = 0,
    this.skippedMissing = 0,
    this.truncated = false,
  });

  /// Files in the source (list/group) or matching now (filter).
  final int files;
  final int skippedNotMedia;
  final int skippedMissing;

  /// More than kMaxSourceItems were given.
  final bool truncated;
}

final class SwipeSourceNotOpened extends SwipeSourceOpenResult {
  const new(this.problem);
  final SwipeSourceProblem problem;
}

/// Max title length in `swipe_sources.title`.
const kMaxSourceTitle = 80;

/// [raw] trimmed and cut to [kMaxSourceTitle] UTF-16 units (what the column
/// check counts) with '…', never splitting a surrogate pair. '…' when
/// nothing is left, so the 1–80 check always holds.
String swipeSourceTitle(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '…';
  if (t.length <= kMaxSourceTitle) return t;
  var end = kMaxSourceTitle - 1;
  final last = t.codeUnitAt(end - 1);
  if (last >= 0xD800 && last <= 0xDBFF) end--; // high surrogate: keep pairs
  return '${t.substring(0, end).trimRight()}…';
}
