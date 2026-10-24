import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/session/domain/clear_session.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/swipe/data/swipe_action_dispatcher.dart';
import 'package:kfm/features/swipe/data/swipe_queue_repository.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/domain/swipe_deck_state.dart';
import 'package:kfm/features/trash/data/delete_queue.dart';
import 'package:kfm/features/trash/data/trash_providers.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';
import 'package:kfm/features/undo/domain/undo_service.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swipe_deck_controller.g.dart';

@Riverpod(keepAlive: true)
SwipeQueueRepository swipeQueueRepository(Ref ref) =>
    SwipeQueueRepository(ref.watch(mediaIndexDaoProvider));

@Riverpod(keepAlive: true)
ClearSessionUseCase clearSessionUseCase(Ref ref) => ClearSessionUseCase(
  ref.watch(sessionRepositoryProvider),
  ref.watch(deleteQueueProvider),
);

@Riverpod(keepAlive: true)
SwipeActionDispatcher swipeActionDispatcher(Ref ref) => SwipeActionDispatcher(
  ref.watch(undoRepositoryProvider),
  ref.watch(deleteQueueProvider),
);

/// D1: no active session and the setting is "delete permanently" → the
/// user confirms once before the session starts (resumed sessions never ask).
@riverpod
Future<bool> needsDeleteModeChoice(Ref ref) async {
  if (await ref.watch(sessionRepositoryProvider).active() != null) return false;
  final mode = await ref.watch(deleteModeSettingProvider.future);
  return mode == DeleteMode.permanent;
}

/// Starts a session with the chosen mode (the setting itself is unchanged).
Future<void> startSessionWith(WidgetRef ref, DeleteMode mode) async {
  await ref.read(sessionRepositoryProvider).getOrCreateActive(deleteMode: mode);
  ref
    ..invalidate(needsDeleteModeChoiceProvider)
    ..invalidate(swipeDeckControllerProvider);
}

/// The swipe deck (TASK-S1). Swipes advance the state immediately; all
/// saving happens in the background through the write queue.
@Riverpod(keepAlive: true)
class SwipeDeckController extends _$SwipeDeckController {
  /// Refill the window when fewer than this many files are left in it.
  static const refillBelow = 20;

  IndexCursor? _next;

  /// SE2: where this deck resumed (after the last swiped file); null = top.
  IndexCursor? _resumeAt;

  /// SE2: files sorted after this (epoch ms) and not acted on are "new".
  int? _newAfterMs;

  /// SE2: the "continued where you left off" note shows once per process.
  static bool _restoreNoticeShown = false;

  /// Tests simulate a new app process.
  @visibleForTesting
  static void debugResetRestoreNotice() => _restoreNoticeShown = false;

  /// Files acted on in this session (not shown again unless undone).
  Set<String> _acted = {};
  bool _refilling = false;

  @override
  Future<SwipeDeckState> build() async {
    final sessions = ref.watch(sessionRepositoryProvider);
    final undo = ref.watch(undoRepositoryProvider);
    final queue = ref.watch(swipeQueueRepositoryProvider);
    await ref.read(deleteQueueProvider).recoverStuck();

    final session = await sessions.getOrCreateActive();
    await undo.prepare(session.id);
    _acted = await undo.actedFileIds(session.id);
    _resumeAt = await _resumePoint(session);
    final resumeMs = _resumeAt?.sortValue as int?;
    final startedMs = session.startedAt.millisecondsSinceEpoch;
    _newAfterMs = resumeMs == null
        ? null
        : (resumeMs > startedMs ? resumeMs : startedMs);
    final window = await queue.window(skip: _acted, after: _resumeAt);
    _next = window.next;

    // The first scan fills the index while the deck is open: top up then.
    ref.listen(mediaIndexChangesProvider, (_, _) => unawaited(_reloadIfLow()));

    final restored = !_restoreNoticeShown && _acted.isNotEmpty;
    _restoreNoticeShown = true;
    return SwipeDeckState(
      session: session,
      upcoming: window.files,
      swiped: _acted.length,
      remaining: await _remaining(),
      hasMore: window.next != null,
      newFiles: await _countNew(const []),
      restored: restored,
    );
  }

  /// SE2: resume right after the latest non-undone action's file (more
  /// current than the debounced cursor), else the saved cursor file. A
  /// committed delete's file is gone from the index, so its stored FileRef
  /// gives the sort position.
  Future<IndexCursor?> _resumePoint(Session session) async {
    final dao = ref.read(mediaIndexDaoProvider);
    final stack = await ref
        .read(undoRepositoryProvider)
        .stack(session.id, limit: 50);
    for (final action in stack) {
      final file = await dao.byId(action.fileId) ?? _trashedOriginal(action);
      if (file != null) {
        return IndexCursor(file.sortDate.millisecondsSinceEpoch, file.id);
      }
    }
    final saved = session.cursorFileId;
    final file = saved == null ? null : await dao.byId(saved);
    return file == null
        ? null
        : IndexCursor(file.sortDate.millisecondsSinceEpoch, file.id);
  }

  static FileRef? _trashedOriginal(SessionAction action) {
    final previous = action.previous;
    final item = previous is TrashPreviousState ? previous.trashedItem : null;
    final original = item?['original'];
    return original is Map
        ? FileRef.fromJson(original.cast<String, Object?>())
        : null;
  }

  IndexQuery? _newQuery() {
    final after = _newAfterMs;
    if (after == null) return null;
    return swipeQuery.copyWith(
      from: DateTime.fromMillisecondsSinceEpoch(after + 1, isUtc: true),
    );
  }

  /// Not-acted files newer than the resume point, minus those in [shown].
  Future<int> _countNew(List<FileRef> shown) async {
    final query = _newQuery();
    final threshold = _newAfterMs;
    if (query == null || threshold == null) return 0;
    final dao = ref.read(mediaIndexDaoProvider);
    final total = await dao.count(query);
    bool isNew(FileRef f) => f.sortDate.millisecondsSinceEpoch > threshold;
    final acted = (await dao.byIds(_acted.toList())).where(isNew).length;
    final count = total - acted - shown.where(isNew).length;
    return count < 0 ? 0 : count;
  }

  /// SE2 chip "Show": put the new files in front of the deck.
  Future<void> showNewFiles() async {
    final deck = state.value;
    final query = _newQuery();
    if (deck == null || query == null) return;
    final page = await ref.read(mediaIndexDaoProvider).page(query, limit: 500);
    final latest = state.value ?? deck;
    final present = {for (final f in latest.upcoming) f.id};
    final fresh = [
      for (final f in page.items)
        if (!_acted.contains(f.id) && !present.contains(f.id)) f,
    ];
    state = AsyncData(
      latest.copyWith(upcoming: [...fresh, ...latest.upcoming], newFiles: 0),
    );
  }

  /// The restore note was shown.
  void restoreNoticeSeen() {
    final deck = state.value;
    if (deck != null && deck.restored) {
      state = AsyncData(deck.copyWith(restored: false));
    }
  }

  /// Returns false when nothing happened (no file, or the direction has no
  /// action: the card snaps back and nothing is recorded).
  bool swipe(SwipeDirection direction) {
    final deck = state.value;
    final file = deck?.current;
    if (deck == null || file == null) return false;
    final action = deck.session.layout.actionFor(direction);
    if (action == null) return false;

    ref
        .read(swipeActionDispatcherProvider)
        .dispatch(deck.session, file, action);
    _acted.add(file.id);
    final rest = deck.upcoming.sublist(1);
    state = AsyncData(
      deck.copyWith(
        upcoming: rest,
        swiped: deck.swiped + 1,
        remaining: deck.remaining > 0 ? deck.remaining - 1 : 0,
      ),
    );
    ref
        .read(sessionRepositoryProvider)
        .saveCursor(deck.session.id, deck.swiped + 1, file.id);
    ref.read(deleteQueueProvider).maybeCommit(deck.session.id).ignore();
    if (rest.length < refillBelow && deck.hasMore) unawaited(_refill());
    return true;
  }

  /// Undoes the last action and shows its file again.
  Future<UndoOutcome> undo() async {
    final deck = state.value;
    if (deck == null) return const NothingToUndo();
    final outcome = await ref
        .read(undoServiceProvider)
        .undoLast(deck.session.id);
    if (outcome case Undone(:final action)) {
      final file =
          await ref.read(mediaIndexDaoProvider).byId(action.fileId) ??
          await ref.read(fileSourceProvider).stat(action.fileId);
      _acted.remove(action.fileId);
      final latest = state.value ?? deck;
      if (file != null) {
        state = AsyncData(
          latest.copyWith(
            upcoming: [file, ...latest.upcoming.where((f) => f.id != file.id)],
            swiped: latest.swiped > 0 ? latest.swiped - 1 : 0,
            remaining: latest.remaining + 1,
          ),
        );
      }
      ref
          .read(sessionRepositoryProvider)
          .saveCursor(
            deck.session.id,
            (state.value ?? latest).swiped,
            file?.id,
          );
    } else if (outcome is PermanentlyDeleted) {
      final latest = state.value ?? deck;
      state = AsyncData(
        latest.copyWith(swiped: latest.swiped > 0 ? latest.swiped - 1 : 0),
      );
    }
    return outcome;
  }

  /// Done = SE3 "Start a new session": commit every queued delete
  /// (including the last 10), end the session, start a fresh deck. If any
  /// delete is still queued (declined dialog), the session stays active.
  Future<ClearResult> finish() => clear(const ClearRequest(newSession: true));

  /// SE3 Clear… sheet.
  Future<ClearResult> clear(ClearRequest request) async {
    final deck = state.value;
    if (deck == null || request.isEmpty) return const ClearResult();
    final result = await ref
        .read(clearSessionUseCaseProvider)
        .execute(deck.session, request);
    if (result.sessionEnded) {
      ref
        ..invalidate(needsDeleteModeChoiceProvider)
        ..invalidateSelf();
    } else if (result.layoutBefore != null) {
      await reloadSession();
    }
    return result;
  }

  /// Snackbar Undo after "Reset action buttons".
  Future<void> undoLayoutReset(SwipeLayout before) async {
    final deck = state.value;
    if (deck == null) return;
    await ref
        .read(clearSessionUseCaseProvider)
        .undoLayoutReset(deck.session.id, before);
    await reloadSession();
  }

  /// Picks up layout changes (SE3 reset, P1 Customize swipes); applies from
  /// the next swipe.
  Future<void> reloadSession() async {
    final session = await ref.read(sessionRepositoryProvider).active();
    final latest = state.value;
    if (session != null && latest != null) {
      state = AsyncData(latest.copyWith(session: session));
    }
  }

  /// Retry a declined or failed batch (banner).
  Future<CommitResult> retryDeletes() async {
    final deck = state.value;
    if (deck == null) return const CommitResult();
    return await ref.read(deleteQueueProvider).commitEligible(deck.session.id);
  }

  Future<void> _refill() => _load(after: _next);

  Future<void> _reloadIfLow() async {
    final deck = state.value;
    if (deck == null || deck.upcoming.length >= refillBelow) return;
    // Re-read from the resume point: skipping by id stays correct when new
    // files were indexed anywhere after it; newer ones come via the chip.
    await _load(after: _resumeAt);
  }

  Future<void> _load({required IndexCursor? after}) async {
    if (_refilling) return;
    _refilling = true;
    try {
      final before = state.value;
      if (before == null) return;
      final shown = {for (final f in before.upcoming) f.id};
      final window = await ref
          .read(swipeQueueRepositoryProvider)
          .window(skip: {..._acted, ...shown}, after: after);
      _next = window.next;
      final latest = state.value ?? before;
      final present = {for (final f in latest.upcoming) f.id};
      state = AsyncData(
        latest.copyWith(
          upcoming: [
            ...latest.upcoming,
            ...window.files.where(
              (f) => !present.contains(f.id) && !_acted.contains(f.id),
            ),
          ],
          hasMore: window.next != null,
          remaining: await _remaining(),
          newFiles: await _countNew(latest.upcoming),
        ),
      );
    } on Object catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _refilling = false;
    }
  }

  /// Files in the queue not yet acted on.
  Future<int> _remaining() async {
    final queue = ref.read(swipeQueueRepositoryProvider);
    final total = await queue.count();
    final actedStillThere =
        (await ref.read(mediaIndexDaoProvider).byIds(_acted.toList()))
            .where((f) => f.kind == FileKind.image || f.kind == FileKind.video)
            .length;
    final left = total - actedStillThere;
    return left < 0 ? 0 : left;
  }
}
