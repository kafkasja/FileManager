import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:meta/meta.dart';

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
  }) => SwipeDeckState(
    session: session ?? this.session,
    upcoming: upcoming ?? this.upcoming,
    swiped: swiped ?? this.swiped,
    remaining: remaining ?? this.remaining,
    hasMore: hasMore ?? this.hasMore,
    newFiles: newFiles ?? this.newFiles,
    restored: restored ?? this.restored,
  );
}
