import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:meta/meta.dart';

/// The last undo that brought a file back (the card animates in, and a
/// "↩ Undone" label shows). [tick] changes on every undo.
@immutable
class UndoMark {
  const new({required this.tick, required this.fileId, this.from});

  final int tick;
  final String fileId;

  /// The side the card left by (null: unknown, it just fades in).
  final SwipeDirection? from;
}

/// The deck: a window of upcoming files (never the whole 50k queue).
@immutable
class SwipeDeckState {
  const new({
    required this.session,
    required this.upcoming,
    required this.swiped,
    required this.remaining,
    required this.hasMore,
    this.newFiles = 0,
    this.restored = false,
    this.undoMark,
    this.reviewedIds = const {},
    this.showReviewedBadge = false,
  });

  final Session session;

  /// Next files, current first. Refilled in the background.
  final List<FileRef> upcoming;

  /// Files swiped in this session (progress).
  final int swiped;

  /// Files left, including [upcoming].
  final int remaining;

  /// More files exist beyond [upcoming].
  final bool hasMore;

  /// SE2: files added above the resume point since the session started
  /// ("N new photos · Show"); never forced into the deck.
  final int newFiles;

  /// SE2: this session was continued after the app process restarted.
  final bool restored;

  final UndoMark? undoMark;

  /// P7: files in [upcoming] reviewed before in this preset (badge).
  final Set<String> reviewedIds;

  /// P7: Basic, or a preset that includes reviewed files.
  final bool showReviewedBadge;

  FileRef? get current => upcoming.isEmpty ? null : upcoming.first;

  bool get isFinished => upcoming.isEmpty && !hasMore;

  SwipeDeckState copyWith({
    Session? session,
    List<FileRef>? upcoming,
    int? swiped,
    int? remaining,
    bool? hasMore,
    int? newFiles,
    bool? restored,
    UndoMark? undoMark,
    Set<String>? reviewedIds,
    bool? showReviewedBadge,
  }) => SwipeDeckState(
    session: session ?? this.session,
    upcoming: upcoming ?? this.upcoming,
    swiped: swiped ?? this.swiped,
    remaining: remaining ?? this.remaining,
    hasMore: hasMore ?? this.hasMore,
    newFiles: newFiles ?? this.newFiles,
    restored: restored ?? this.restored,
    undoMark: undoMark ?? this.undoMark,
    reviewedIds: reviewedIds ?? this.reviewedIds,
    showReviewedBadge: showReviewedBadge ?? this.showReviewedBadge,
  );
}
