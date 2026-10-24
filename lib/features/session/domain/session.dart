import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:meta/meta.dart';

/// A swipe session (SE1), with layout and filter parsed.
@immutable
class Session {
  const new({
    required this.id,
    required this.layout,
    required this.deleteMode,
    required this.cursor,
    required this.startedAt,
    required this.updatedAt,
    this.filterJson,
    this.cursorFileId,
    this.presetId,
  });

  final int id;
  final SwipeLayout layout;
  final DeleteMode deleteMode;

  /// P5 filter JSON; null = all media.
  final String? filterJson;

  /// Files swiped so far.
  final int cursor;

  /// Last swiped file; the deck resumes after it.
  final String? cursorFileId;
  final int? presetId;
  final DateTime startedAt;
  final DateTime updatedAt;
}
