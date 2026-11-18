import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/routing_file_source.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/remote_source_provider.dart';
import 'package:kfm/features/connect/data/remote_swipe_queue_source.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/filters/data/filter_query.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/rename/data/rename_providers.dart';
import 'package:kfm/features/reviewed/data/reviewed_repository.dart';
import 'package:kfm/features/reviewed/domain/reviewed_rules.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/session/domain/clear_session.dart';
import 'package:kfm/features/session/domain/remote_deck_root.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/swipe/data/file_source_resolver.dart';
import 'package:kfm/features/swipe/data/swipe_action_dispatcher.dart';
import 'package:kfm/features/swipe/data/swipe_file_ops.dart';
import 'package:kfm/features/swipe/data/swipe_queue_repository.dart';
import 'package:kfm/features/swipe/data/swipe_queue_source.dart';
import 'package:kfm/features/swipe/data/swipe_source_repository.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/domain/swipe_deck_state.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';
import 'package:kfm/features/swipe/ui/swipe_source_launcher.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/transfers/data/swipe_sends.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';
import 'package:kfm/features/trash/data/delete_queue.dart';
import 'package:kfm/features/trash/data/trash_providers.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';
import 'package:kfm/features/undo/domain/undo_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swipe_deck_controller.g.dart';

@Riverpod(keepAlive: true)
SwipeQueueRepository swipeQueueRepository(Ref ref) =>
    SwipeQueueRepository(ref.watch(mediaIndexDaoProvider));

@Riverpod(keepAlive: true)
ClearSessionUseCase clearSessionUseCase(Ref ref) => ClearSessionUseCase(
  ref.watch(sessionRepositoryProvider),
  ref.watch(deleteQueueProvider),
  renames: ref.watch(renameBatchRepositoryProvider),
  clearSelection: () =>
      ref.read(selectionControllerProvider.notifier).clearAll(),
);

@Riverpod(keepAlive: true)
SwipeFileOps swipeFileOps(Ref ref) {
  final ops = SwipeFileOps(
    source: ref.watch(fileSourceProvider),
    undo: ref.watch(undoRepositoryProvider),
    lock: ref.watch(historyLockProvider),
    indexer: ref.watch(mediaIndexerProvider),
    remoteSource: (id) => ref.read(fileSourceResolverProvider)(id),
    crossPlaceCopy: switch (ref.watch(fileSourceProvider)) {
      final RoutingFileSource fs =>
        (file, target) async => fs.isCrossPlace(file, target)
            ? (await fs.crossPlace.copyVerified(file, target)).copy
            : null,
      _ => null,
    },
    queueDelete: ref.watch(deleteQueueProvider).queueInTransaction,
    copyLabels: ref.watch(fileIdRekeyerProvider).copyLabels,
  );
  ref.onDispose(ops.dispose);
  return ops;
}

/// Move/copy results for the swipe screen's snackbars (P2).
@Riverpod(keepAlive: true)
Stream<SwipeFileOpEvent> swipeFileOpEvents(Ref ref) =>
    ref.watch(swipeFileOpsProvider).events;

/// U2: the first delete swipe of a camera file in a session (permanent).
@Riverpod(keepAlive: true)
Stream<int> cameraDeleteWarnings(Ref ref) =>
    ref.watch(swipeActionDispatcherProvider).cameraDeleteWarnings;

@Riverpod(keepAlive: true)
SwipeActionDispatcher swipeActionDispatcher(Ref ref) => SwipeActionDispatcher(
  ref.watch(undoRepositoryProvider),
  ref.watch(deleteQueueProvider),
  fileOps: ref.watch(swipeFileOpsProvider),
  tags: ref.watch(tagRepositoryProvider),
  favorites: ref.watch(favoritesRepositoryProvider),
  renames: ref.watch(renameBatchRepositoryProvider),
  // N9: sends queue a transfer in the undo row's transaction.
  sends: swipeSendQueue(
    ref.watch(transfersRepositoryProvider).dao,
    downloadsRoot: ref.read(downloadsRootProvider),
    // E1: read when the send is queued (the setting may change).
    currentDownloadsRoot: () => ref.read(downloadsRootProvider),
  ),
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

/// The Swipe tab's deck: this device's files (N8: one deck per source).
final SwipeDeckControllerProvider swipeDeckControllerProvider =
    swipeDeckForSourceProvider(kLocalSourceId);

/// Which deck the widgets below swipe (N8): the Swipe tab's (default) or a
/// connected device's (`/connect/swipe/:fp`). [deviceName] names that
/// device in messages.
class SwipeDeckScope extends InheritedWidget {
  const new({
    required this.sourceId,
    required super.child,
    this.deviceName = '',
    super.key,
  });

  final String sourceId;
  final String deviceName;

  static SwipeDeckScope? _of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SwipeDeckScope>();

  /// The deck provider for [context] (local outside any scope).
  static SwipeDeckControllerProvider providerOf(BuildContext context) =>
      swipeDeckForSourceProvider(_of(context)?.sourceId ?? kLocalSourceId);

  static bool isRemote(BuildContext context) =>
      (_of(context)?.sourceId ?? kLocalSourceId) != kLocalSourceId;

  static String deviceNameOf(BuildContext context) =>
      _of(context)?.deviceName ?? '';

  @override
  bool updateShouldNotify(SwipeDeckScope oldWidget) =>
      oldWidget.sourceId != sourceId || oldWidget.deviceName != deviceName;
}

/// N8: starts (or continues) the swipe session on the device
/// [peerFingerprint] in [root]'s folder and rebuilds its deck.
Future<void> startRemoteSwipe(
  WidgetRef ref,
  String peerFingerprint,
  RemoteDeckRoot root,
) async {
  await ref.read(sessionRepositoryProvider).startRemote(peerFingerprint, root);
  ref.invalidate(swipeDeckForSourceProvider(remoteSourceId(peerFingerprint)));
}

/// The swipe deck (TASK-S1). Swipes advance the state immediately; all
/// saving happens in the background through the write queue.
///
/// N8: one per source: [kLocalSourceId] (the Swipe tab,
/// [swipeDeckControllerProvider]) or `'remote:<fp>'` (a connected device's
/// folder; built only while its screen is open).
@Riverpod(keepAlive: true, name: 'swipeDeckForSourceProvider')
class SwipeDeckController extends _$SwipeDeckController {
  /// Refill the window when fewer than this many files are left in it.
  static const refillBelow = 20;

  IndexCursor? _next;

  /// SE2: where this deck resumed (after the last swiped file); null = top.
  IndexCursor? _resumeAt;

  /// P5: the session's filter on top of the swipe base. Null = the filter
  /// can't match anything (empty deck, "no matches").
  IndexQuery? _query = swipeQuery;

  /// SE2: files sorted after this (epoch ms) and not acted on are "new".
  /// Null until the deck knows its newest file.
  int? _newAfterMs;

  /// SE2: the "continued where you left off" note shows once per process.
  static bool _restoreNoticeShown = false;

  /// Tests simulate a new app process.
  @visibleForTesting
  static void debugResetRestoreNotice() => _restoreNoticeShown = false;

  /// SS1: what the deck pages through (the main deck's index query, or a
  /// swipe source).
  late SwipeQueueSource _queue;

  /// SS1: highest closedAtSeq of the session's closed sources: the main
  /// deck resumes only after actions above it.
  int? _floor;

  /// Files acted on in this session (not shown again unless undone).
  Set<String> _acted = {};
  bool _refilling = false;

  /// Bumped by every build. Async updates that started before a rebuild
  /// (e.g. Done → new session) must not write their old deck back: while
  /// rebuilding, `state.value` still returns the previous deck (V1 bug 2).
  int _generation = 0;

  bool _stale(int generation) =>
      generation != _generation || !ref.mounted || state.isLoading;

  /// N8: [kLocalSourceId] or `'remote:<fp>'`.
  String _sourceId = kLocalSourceId;

  /// N8: the connected device's fingerprint (remote decks only).
  String? _peer;

  /// N8: files swiped on a remote deck, so an undo shows them again without
  /// asking the device.
  final Map<String, FileRef> _swipedRemote = {};

  @override
  Future<SwipeDeckState> build(String sourceId) async {
    unawaited(_loadKnownDevices());
    _generation++;
    _sourceId = sourceId;
    _peer = peerOfSourceId(sourceId);
    if (_peer case final fp?) return await _buildRemote(fp);
    if (sourceId != kLocalSourceId) {
      throw ArgumentError.value(sourceId, 'sourceId');
    }
    final sessions = ref.watch(sessionRepositoryProvider);
    final undo = ref.watch(undoRepositoryProvider);
    // Rebuild when the queue's source changes (tests swap the index).
    ref.watch(swipeQueueRepositoryProvider);
    await ref.read(deleteQueueProvider).recoverStuck();

    final sources = ref.read(swipeSourceRepositoryProvider);
    await sources.prune();

    // SS1: a debounced cursor write (e.g. cleared by an undo below the
    // floor) must be on disk: the resume point may fall back to it.
    await sessions.flush();
    final session = await sessions.getOrCreateActive();
    await undo.prepare(session.id);
    // SS1: a source opened before this session existed (D1 gate).
    final launcher = ref.read(swipeSourceLauncherProvider.notifier);
    final pending = launcher.takePending();
    if (pending != null) await launcher.attach(session.id, pending);
    final open = await sources.openFor(session.id);
    // X1: a "Shared files" deck and the main deck don't use up each other's
    // files: what was only kept/tagged in one is still offered by the other
    // (and not counted there). Trashed/moved files stay skipped everywhere.
    _acted = await undo.actedFileIds(
      session.id,
      detachedRanges: switch (open) {
        null => await sources.closedRanges(
          session.id,
          origin: SwipeSourceOrigin.sharedIn,
        ),
        OpenSwipeSource(origin: SwipeSourceOrigin.sharedIn) => [
          (0, open.openedAfterSeq),
        ],
        _ => const [],
      },
    );
    _presetKey = session.presetId ?? 0;
    final dao = ref.read(mediaIndexDaoProvider);
    final repo = ref.read(swipeQueueRepositoryProvider);
    final generation = _generation;
    // PL3: the desktop Sort grid acts on files in any order, so "after the
    // latest action" would hide files above it: it always starts at the top
    // and skips acted files by id.
    final fromTop = ref.read(formFactorProvider).isDesktop;
    switch (open) {
      case null:
        _floor = await sources.mainFloor(session.id);
        _resumeAt = fromTop ? null : await _resumePoint(session, floor: _floor);
        _query = await _queryFor(FileFilter.decode(session.filterJson));
        _queue = IndexQueueSource(repo, dao, _query);
      case OpenSwipeSource(kind: SwipeSourceKind.filter, :final filter?):
        _resumeAt = fromTop
            ? null
            : await _resumePoint(
                session,
                floor: open.openedAfterSeq,
                cursorFallback: false,
              );
        // Decision 5: skip-reviewed doesn't apply; an explicit value does.
        _query = toIndexQuery(
          filter,
          now: DateTime.now(),
          reviewed: deckReviewedClause(
            presetKey: _presetKey,
            mode: filter.reviewed,
            includeReviewed: true,
          ),
        );
        _queue = IndexQueueSource(repo, dao, _query, offersNewFiles: false);
      case OpenSwipeSource(:final id, :final groupCount):
        _resumeAt = null;
        _queue = ListQueueSource(
          dao,
          ref.read(fileSourceProvider),
          await sources.items(id),
          groupCount: groupCount,
          onGone: (gone) {
            if (_stale(generation)) return;
            sources.dropItems(id, gone).fireAndForget();
          },
        );
    }
    final resumeMs = _resumeAt?.sortValue;
    final startedMs = session.startedAt.millisecondsSinceEpoch;
    _newAfterMs = !_queue.offersNewFiles || resumeMs is! int
        ? null
        : (resumeMs > startedMs ? resumeMs : startedMs);
    final filter = FileFilter.decode(session.filterJson);
    final badgeOn = await ref
        .read(settingsRepositoryProvider)
        .read(AppSettings.showReviewedBadge);
    _showBadge =
        badgeOn &&
        (open != null || _presetKey == 0 || await _includeReviewed(filter));
    final window = await _window(skip: _acted, after: _resumeAt);
    _next = window.next;
    // A fresh deck starts at the newest file: anything newer arrives later.
    if (_queue.offersNewFiles) _newAfterMs ??= _newestMs(window.files);

    // P2: a move/copy finishes (or fails) after the card has gone.
    final fileOps = ref.read(swipeFileOpsProvider).events.listen(_onFileOp);
    ref.onDispose(fileOps.cancel);
    // U2 follow-up: a file of an upcoming card was moved outside the deck
    // (B4, a local job): the card must not keep a dead id.
    final idChanges = ref
        .read(fileSourceProvider)
        .idChanges
        .listen((c) => unawaited(_onIdChange(c, generation)));
    ref.onDispose(idChanges.cancel);
    // Tags must be loaded before the first tag swipe is checked.
    ref.listen(tagsByIdProvider, (_, _) {});

    // The first scan fills the index while the deck is open: top up then.
    ref.listen(
      mediaIndexChangesProvider,
      (_, _) => unawaited(_onIndexChanged()),
    );

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
      reviewedIds: await _reviewedAmong(window.files),
      showReviewedBadge: _showBadge,
      source: open,
      groupPositionOf: open?.kind == SwipeSourceKind.groups
          ? _queue.groupPositionOf
          : null,
    );
  }

  /// N8: a connected device's folder. Always trash mode; no filter, preset,
  /// new-files chip or swipe sources. Acted files are skipped, so the deck
  /// continues where it was. Not connected → an empty, waiting deck (never
  /// an error), refilled on reconnect.
  Future<SwipeDeckState> _buildRemote(String fp) async {
    final sessions = ref.watch(sessionRepositoryProvider);
    final undo = ref.watch(undoRepositoryProvider);
    ref.watch(fileSourceResolverProvider);
    await ref.read(deleteQueueProvider).recoverStuck();
    await sessions.flush();
    final session =
        await sessions.active(sourceId: _sourceId) ??
        (throw StateError('no swipe session on $fp'));
    await undo.prepare(session.id);
    _acted = await undo.actedFileIds(session.id);
    _presetKey = 0;
    _query = null;
    _resumeAt = null;
    _floor = null;
    _newAfterMs = null;
    final settings = ref.read(settingsRepositoryProvider);
    final includeReviewed = await settings.read(
      AppSettings.basicIncludeReviewed,
    );
    _showBadge =
        includeReviewed && await settings.read(AppSettings.showReviewedBadge);
    final reviewed = ref.read(reviewedRepositoryProvider);
    final root = RemoteDeckRoot.decode(session.filterJson);
    _queue = root == null
        ? IndexQueueSource(
            ref.read(swipeQueueRepositoryProvider),
            ref.read(mediaIndexDaoProvider),
            null,
            offersNewFiles: false,
          )
        : RemoteQueueSource(
            ref.read(remoteSourceProvider(fp)).page,
            root,
            exclude: includeReviewed
                ? null
                : (files) => reviewed.reviewedAmong(0, files),
          );
    var window = const SwipeWindow([], null);
    var waiting = false;
    try {
      window = await _window(skip: _acted);
    } on FileOpException catch (e) {
      if (e.failure != FileOpFailure.unavailable) rethrow;
      waiting = true;
    }
    _next = window.next;

    final fileOps = ref.read(swipeFileOpsProvider).events.listen(_onFileOp);
    ref.onDispose(fileOps.cancel);
    ref.listen(tagsByIdProvider, (_, _) {});
    // Back online: load what was missing and commit what waited (D2).
    // Per-peer family stays auto-dispose; this listen keeps it alive.
    // ignore: riverpod_lint/only_use_keep_alive_inside_keep_alive
    ref.listen(remotePeerConnectedProvider(fp), (before, now) {
      if (now && before != true) unawaited(_onReconnected());
    });

    return SwipeDeckState(
      session: session,
      upcoming: window.files,
      swiped: _acted.length,
      remaining: await _remaining(),
      hasMore: waiting || window.next != null,
      reviewedIds: await _reviewedAmong(window.files),
      showReviewedBadge: _showBadge,
      waiting: waiting,
    );
  }

  /// N8: the device is connected again.
  Future<void> _onReconnected() async {
    final deck = state.value;
    if (deck == null) return;
    if (deck.waiting) await _load(after: _next);
    final sessionId = (state.value ?? deck).session.id;
    await ref.read(deleteQueueProvider).maybeCommit(sessionId);
  }

  /// N8: the remote rules for [problemFor] (null for this device's deck).
  RemoteSwipeRules? _remoteRules() {
    final fp = _peer;
    if (fp == null) return null;
    return switch (ref.read(remoteConnectionControllerProvider)) {
      RemoteConnected(:final peerFingerprint, :final roots)
          when peerFingerprint == fp =>
        RemoteSwipeRules(
          roots: {for (final r in roots) r.id: r.readOnly},
          peerDeviceId: _knownIdOf(fp),
        ),
      _ => RemoteSwipeRules(peerDeviceId: _knownIdOf(fp)),
    };
  }

  /// N9: remembered devices, read once per deck build (a one-off query: a
  /// live watch here would hold the database in widget tests). Null until
  /// loaded: sends are then not pre-checked.
  List<KnownDevice>? _known;

  Future<void> _loadKnownDevices() async {
    try {
      _known = await ref.read(knownDevicesRepositoryProvider).all();
    } on Object catch (e) {
      developer.log('remembered devices not loaded: $e', name: 'kfm.swipe');
    }
  }

  /// N9: the remembered row id of [fp] (null = not remembered / unknown).
  String? _knownIdOf(String fp) {
    for (final d in _known ?? const <KnownDevice>[]) {
      if (d.fingerprint == fp) return d.id;
    }
    return null;
  }

  /// SS1: closes the open source; the main deck continues where it was.
  Future<void> closeSource() async {
    final deck = state.value;
    final open = deck?.source;
    if (deck == null || open == null) return;
    final generation = _generation;
    try {
      final undo = ref.read(undoRepositoryProvider);
      await undo.prepare(deck.session.id);
      await ref
          .read(swipeSourceRepositoryProvider)
          .close(open.id, lastSeq: undo.lastSeq(deck.session.id));
    } on Object catch (e, st) {
      if (!_stale(generation)) state = AsyncError(e, st);
      return;
    }
    ref.invalidateSelf();
    await future;
  }

  /// SE2: resume right after the latest non-undone action's file (more
  /// current than the debounced cursor), else the saved cursor file. A
  /// committed delete's file is gone from the index, so its stored FileRef
  /// gives the sort position.
  ///
  /// SS1: only actions after [floor] count (the main deck after a closed
  /// source; a filter source's own actions). Nothing above the floor → the
  /// saved cursor ([cursorFallback]) or the top.
  Future<IndexCursor?> _resumePoint(
    Session session, {
    int? floor,
    bool cursorFallback = true,
  }) async {
    final dao = ref.read(mediaIndexDaoProvider);
    final undo = ref.read(undoRepositoryProvider);
    final stack = [
      for (final a in await undo.stack(session.id, limit: 50))
        if (a.seq > (floor ?? 0)) a,
    ];
    for (final action in stack) {
      final file = await dao.byId(action.fileId) ?? _trashedOriginal(action);
      if (file != null) {
        return IndexCursor(file.sortDate.millisecondsSinceEpoch, file.id);
      }
    }
    // H4: everything was undone. The saved cursor still points at the last
    // (now undone) swipe: start from the top instead.
    if (!cursorFallback) return null;
    if (floor == null && stack.isEmpty && await undo.hasAny(session.id)) {
      return null;
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
    final query = _query;
    if (after == null || query == null) return null;
    final newFrom = DateTime.fromMillisecondsSinceEpoch(after + 1, isUtc: true);
    final from = query.from;
    // Never widens a date filter.
    return query.copyWith(
      from: () => from != null && from.isAfter(newFrom) ? from : newFrom,
    );
  }

  /// The file [id] from its source, or null (also while a device isn't
  /// connected: N8).
  Future<FileRef?> _statQuietly(String id) async {
    try {
      return await ref.read(fileSourceResolverProvider).forFile(id).stat(id);
    } on FileOpException catch (e) {
      if (e.failure == FileOpFailure.unavailable) return null;
      rethrow;
    }
  }

  Future<SwipeWindow> _window({
    required Set<String> skip,
    IndexCursor? after,
  }) async {
    // A remote listing's cursor is the device's (N8); a local one is never
    // a String.
    assert(_peer != null || after?.sortValue is! String, 'remote cursor');
    return await _queue.window(skip: skip, after: after);
  }

  /// P5: the session's current filter.
  FileFilter get filter => FileFilter.decode(state.value?.session.filterJson);

  /// P5: saves [f] on the session and rebuilds the deck from the resume
  /// point. Undo history is untouched.
  Future<void> applyFilter(FileFilter f) async {
    final deck = state.value;
    if (deck == null) return;
    await ref
        .read(sessionRepositoryProvider)
        .saveFilter(deck.session.id, f.isEmpty ? null : jsonEncode(f.toJson()));
    ref.invalidateSelf();
    await future;
  }

  /// P5: how many files [f] would leave to swipe (the sheet's live count).
  Future<int> matchCount(FileFilter f) async =>
      await _remainingFor(await _queryFor(f));

  /// P7: the preset (0 = Basic) this deck's labels belong to.
  int _presetKey = 0;
  bool _showBadge = false;

  /// [f] + the reviewed clause for this session.
  Future<IndexQuery?> _queryFor(FileFilter f) async => toIndexQuery(
    f,
    now: DateTime.now(),
    reviewed: deckReviewedClause(
      presetKey: _presetKey,
      mode: f.reviewed,
      includeReviewed: await _includeReviewed(f),
    ),
  );

  /// P7: the session override, else the preset's setting, else Basic's.
  Future<bool> includeReviewedDefault() async {
    if (_presetKey == 0) {
      return await ref
          .read(settingsRepositoryProvider)
          .read(AppSettings.basicIncludeReviewed);
    }
    final preset = await ref.read(presetRepositoryProvider).byId(_presetKey);
    return preset is Preset && preset.includeReviewed;
  }

  Future<bool> _includeReviewed(FileFilter f) async =>
      f.includeReviewed ?? await includeReviewedDefault();

  /// P7: badge ids for [files] (nothing when the badge isn't shown).
  Future<Set<String>> _reviewedAmong(List<FileRef> files) async => _showBadge
      ? await ref
            .read(reviewedRepositoryProvider)
            .reviewedAmong(_presetKey, files)
      : const {};

  /// P7: whether the active preset is Basic (0) — the filter sheet's
  /// include switch writes Basic's setting there, else the session.
  int get presetKey => _presetKey;

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

  /// Why [direction] can't run right now (P2), or null. Unmapped
  /// directions are not a problem: they simply do nothing.
  SwipeActionProblem? problemFor(SwipeDirection direction) {
    final action = state.value?.session.layout.actionFor(direction);
    return action == null ? null : problemForAction(action);
  }

  /// Why [action] can't run right now (P2: deleted tag, unsupported type)
  /// on [file] (default: the current file).
  SwipeActionProblem? problemForAction(SwipeAction action, {FileRef? file}) =>
      SwipeActionDispatcher.problemFor(
        action,
        ref.read(tagsByIdProvider).value ?? const {},
        remote: _remoteRules(),
        file: file ?? state.value?.current,
        knownDeviceIds: _known?.map((d) => d.id).toSet(),
      );

  /// Returns false when nothing happened (no file, the direction has no
  /// action, or it can't run: the card snaps back and nothing is recorded).
  bool swipe(SwipeDirection direction) {
    final action = state.value?.session.layout.actionFor(direction);
    return action != null && apply(action);
  }

  /// Applies [action] to the current file: a swipe or an action bar tap
  /// (P4). Same undo row, advance and stats either way. False = nothing
  /// happened.
  bool apply(SwipeAction action) {
    final deck = state.value;
    final file = deck?.current;
    if (deck == null || file == null) return false;
    if (problemForAction(action) != null) return false;

    ref
        .read(swipeActionDispatcherProvider)
        .dispatch(deck.session, file, action);
    _acted.add(file.id);
    if (_peer != null) _swipedRemote[file.id] = file;
    final rest = deck.upcoming.sublist(1);
    state = AsyncData(
      deck.copyWith(
        upcoming: rest,
        swiped: deck.swiped + 1,
        remaining: deck.remaining > 0 ? deck.remaining - 1 : 0,
      ),
    );
    // SS1: a source never moves the main deck's position. N8: a remote deck
    // skips acted files instead.
    if (deck.source == null && _peer == null) {
      ref
          .read(sessionRepositoryProvider)
          .saveCursor(deck.session.id, deck.swiped + 1, file.id);
    }
    ref.read(deleteQueueProvider).maybeCommit(deck.session.id).ignore();
    if (rest.length < refillBelow && deck.hasMore) unawaited(_refill());
    return true;
  }

  /// PL3 (desktop Sort grid): applies [action] to each of [files] that is
  /// in the deck, in deck order. Each file gets its own undo row through the
  /// same dispatcher as a swipe (batched-delete rules unchanged). Files the
  /// action can't run on are left in the deck; [ApplyManyResult.problem]
  /// says why.
  ApplyManyResult applyToFiles(Iterable<FileRef> files, SwipeAction action) {
    final deck = state.value;
    if (deck == null) return const ApplyManyResult(0);
    final wanted = {for (final f in files) f.id};
    final dispatcher = ref.read(swipeActionDispatcherProvider);
    final done = <String>{};
    SwipeActionProblem? problem;
    FileRef? last;
    for (final file in deck.upcoming) {
      if (!wanted.contains(file.id)) continue;
      final p = problemForAction(action, file: file);
      if (p != null) {
        problem ??= p;
        continue;
      }
      dispatcher.dispatch(deck.session, file, action);
      _acted.add(file.id);
      if (_peer != null) _swipedRemote[file.id] = file;
      done.add(file.id);
      last = file;
    }
    if (done.isEmpty) return ApplyManyResult(0, problem: problem);
    final rest = [
      for (final f in deck.upcoming)
        if (!done.contains(f.id)) f,
    ];
    final left = deck.remaining - done.length;
    state = AsyncData(
      deck.copyWith(
        upcoming: rest,
        swiped: deck.swiped + done.length,
        remaining: left > 0 ? left : 0,
      ),
    );
    if (deck.source == null && _peer == null && last != null) {
      ref
          .read(sessionRepositoryProvider)
          .saveCursor(deck.session.id, deck.swiped + done.length, last.id);
    }
    // The batch check reads the undo log: let this batch's rows land first
    // (one swipe at a time, the next swipe's check sees the earlier rows).
    final deletes = ref.read(deleteQueueProvider);
    ref
        .read(dbWriteQueueProvider)
        .flush()
        .then((_) => deletes.maybeCommit(deck.session.id))
        .ignore();
    if (rest.length < refillBelow && deck.hasMore) unawaited(_refill());
    return ApplyManyResult(done.length, problem: problem);
  }

  /// PL3: the grid scrolled to the end of the window: load the next one.
  Future<void> loadMore() async {
    if (state.value?.hasMore ?? false) await _refill();
  }

  /// Undoes the last action and shows its file again.
  Future<UndoOutcome> undo() async {
    final deck = state.value;
    if (deck == null) return const NothingToUndo();
    final outcome = await ref
        .read(undoServiceProvider)
        .undoLast(deck.session.id);
    if (outcome case Undone(reshow: false)) {
      // An applied rename batch was reverted: no file comes back.
    } else if (outcome case Undone(:final action, file: final undoneFile)) {
      final file =
          undoneFile ??
          _swipedRemote.remove(action.fileId) ??
          await ref.read(mediaIndexDaoProvider).byId(action.fileId) ??
          await _statQuietly(action.fileId);
      _acted.remove(action.fileId);
      final latest = state.value ?? deck;
      if (file != null) {
        // The side the card left by: the direction mapped to that action.
        final from = latest.session.layout.directions.entries
            .where((e) => e.value == action.action)
            .map((e) => e.key)
            .firstOrNull;
        state = AsyncData(
          latest.copyWith(
            upcoming: [file, ...latest.upcoming.where((f) => f.id != file.id)],
            swiped: latest.swiped > 0 ? latest.swiped - 1 : 0,
            remaining: latest.remaining + 1,
            undoMark: UndoMark(
              tick: (latest.undoMark?.tick ?? 0) + 1,
              fileId: file.id,
              from: from,
            ),
            // It may still carry an older label (P7).
            reviewedIds: (await _reviewedAmong([file])).isEmpty
                ? latest.reviewedIds.difference({file.id})
                : {...latest.reviewedIds, file.id},
          ),
        );
      }
      // SS1: a source action leaves the main position alone. Undoing an
      // action at or below the main deck's floor (or an older one while a
      // source is open) clears the cursor so the file is never skipped.
      final open = deck.source;
      final swiped = (state.value ?? latest).swiped;
      final sessionsRepo = ref.read(sessionRepositoryProvider);
      if (_peer != null) {
        // N8: no cursor on a remote deck.
      } else if (open != null) {
        if (action.seq <= open.openedAfterSeq) {
          sessionsRepo.saveCursor(deck.session.id, swiped, null);
        }
      } else if (_floor != null) {
        // Above a floor the cursor is the fallback once every main action
        // after it is undone: the undone file must not be the resume point
        // (it would be skipped). Cleared = first unacted file.
        sessionsRepo.saveCursor(deck.session.id, swiped, null);
      } else {
        sessionsRepo.saveCursor(deck.session.id, swiped, file?.id);
      }
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
      // N8: the remote screen closes; its next "Swipe these" starts anew.
      if (_peer != null) return result;
      ref.invalidate(needsDeleteModeChoiceProvider);
      // D1: a permanent-mode setting asks before every new session. A
      // rebuild here would create that session at once and skip the
      // question (V1 bug 6); the choice starts it (startSessionWith).
      // Read directly: an unlistened StreamProvider's future never completes.
      final mode = DeleteMode.parse(
        await ref.read(settingsRepositoryProvider).read(AppSettings.deleteMode),
      );
      if (mode != DeleteMode.permanent) {
        ref.invalidateSelf();
      }
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

  /// P2: a move/copy swipe finished in the background.
  void _onFileOp(SwipeFileOpEvent event) {
    final deck = state.value;
    if (deck == null) return;
    // N8: every deck hears every move/copy; only its own files count.
    if (sourceIdOfFile(event.file.id) != _sourceId) return;
    switch (event) {
      case SwipeFileOpDone(:final result):
        // The moved file (new id?) or the copy is never offered.
        _acted.add(result.id);
        if (deck.upcoming.any((f) => f.id == result.id)) {
          state = AsyncData(
            deck.copyWith(
              upcoming: [
                for (final f in deck.upcoming)
                  if (f.id != result.id) f,
              ],
            ),
          );
        }
      case SwipeFileOpFailed(:final file):
        // Nothing happened to the file: offer it again (front of the deck).
        _acted.remove(file.id);
        state = AsyncData(
          deck.copyWith(
            upcoming: [file, ...deck.upcoming.where((f) => f.id != file.id)],
            swiped: deck.swiped > 0 ? deck.swiped - 1 : 0,
            remaining: deck.remaining + 1,
          ),
        );
    }
  }

  /// An upcoming card's file got a new id (B4, a U2 job, a rename). Moved
  /// to another place (e.g. the SD card) and no longer in this deck's
  /// filter: the card goes. Otherwise the card shows the file under its new
  /// id (never a dead one: swiping it would fail).
  Future<void> _onIdChange(FileIdChange change, int generation) async {
    final before = state.value;
    if (before == null || _stale(generation)) return;
    final old = before.upcoming.where((f) => f.id == change.oldId).firstOrNull;
    if (old == null) return;
    final now = change.newRef;
    var keep = true;
    final queue = _queue;
    if (placeIdOf(old) != placeIdOf(now) && queue is IndexQueueSource) {
      final q = queue.query;
      // The job indexed the copy before it announced the move.
      keep =
          q != null &&
          await ref.read(mediaIndexDaoProvider).countAmong(q, [now.id]) > 0;
    }
    final deck = state.value;
    if (deck == null || _stale(generation)) return;
    final i = deck.upcoming.indexWhere((f) => f.id == change.oldId);
    if (i < 0) return;
    final upcoming = [...deck.upcoming];
    if (!keep || upcoming.any((f) => f.id == now.id)) {
      upcoming.removeAt(i);
    } else {
      upcoming[i] = now;
    }
    state = AsyncData(deck.copyWith(upcoming: upcoming));
    // The left count follows the index (`_onIndexChanged`).
  }

  /// Picks up layout changes (SE3 reset, P1 Customize swipes); applies from
  /// the next swipe.
  Future<void> reloadSession() async {
    final session = await ref
        .read(sessionRepositoryProvider)
        .active(sourceId: _sourceId);
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

  /// Index changed (scan, camera, other apps): top up a low window, or at
  /// least refresh "N left" and the new-photos chip.
  Future<void> _onIndexChanged() async {
    final generation = _generation;
    var deck = state.value;
    if (deck == null || _stale(generation)) return;
    // U1 follow-up (g): cards on a volume that was just detached leave the
    // deck, the current one too (queries already hide those rows; the
    // window loaded before doesn't). They come back with a later reload.
    final dao = ref.read(mediaIndexDaoProvider);
    if (dao.excludedRoots.isNotEmpty &&
        deck.upcoming.any((f) => dao.isExcludedFolder(f.folderPath))) {
      deck = deck.copyWith(
        upcoming: [
          for (final f in deck.upcoming)
            if (!dao.isExcludedFolder(f.folderPath)) f,
        ],
      );
      state = AsyncData(deck);
    }
    if (deck.upcoming.length < refillBelow) {
      // Re-read from the resume point: skipping by id stays correct when new
      // files were indexed anywhere after it; newer ones come via the chip.
      await _load(after: _resumeAt);
      return;
    }
    if (_refilling) return;
    final remaining = await _remaining();
    final newFiles = await _countNew(deck.upcoming);
    final latest = state.value;
    if (latest == null || _stale(generation)) return;
    state = AsyncData(
      latest.copyWith(remaining: remaining, newFiles: newFiles),
    );
  }

  /// Newer than what the deck started with: offered via the chip (SE2),
  /// never slipped into the deck.
  bool _isNew(FileRef f) {
    final after = _newAfterMs;
    return after != null && f.sortDate.millisecondsSinceEpoch > after;
  }

  static int? _newestMs(List<FileRef> files) => files.isEmpty
      ? null
      : files
            .map((f) => f.sortDate.millisecondsSinceEpoch)
            .reduce((a, b) => a > b ? a : b);

  Future<void> _load({required IndexCursor? after}) async {
    if (_refilling) return;
    final generation = _generation;
    _refilling = true;
    try {
      final before = state.value;
      if (before == null || _stale(generation)) return;
      final shown = {for (final f in before.upcoming) f.id};
      final SwipeWindow window;
      try {
        window = await _window(skip: {..._acted, ...shown}, after: after);
      } on FileOpException catch (e) {
        // N8: the device went away: keep the deck, wait for it.
        if (_peer == null || e.failure != FileOpFailure.unavailable) rethrow;
        if (!_stale(generation)) {
          final latest = state.value ?? before;
          state = AsyncData(latest.copyWith(waiting: true, hasMore: true));
        }
        return;
      }
      if (_stale(generation)) return;
      _next = window.next;
      if (_queue.offersNewFiles) {
        _newAfterMs ??= _newestMs([...before.upcoming, ...window.files]);
      }
      final latest = state.value ?? before;
      final present = {for (final f in latest.upcoming) f.id};
      final added = await _reviewedAmong(window.files);
      final remaining = await _remaining();
      final newFiles = await _countNew(latest.upcoming);
      if (_stale(generation)) return;
      state = AsyncData(
        latest.copyWith(
          upcoming: [
            ...latest.upcoming,
            ...window.files.where(
              (f) =>
                  !present.contains(f.id) &&
                  !_acted.contains(f.id) &&
                  !_isNew(f),
            ),
          ],
          hasMore: window.next != null,
          remaining: remaining,
          newFiles: newFiles,
          reviewedIds: {...latest.reviewedIds, ...added},
          waiting: false,
        ),
      );
    } on Object catch (e, st) {
      if (!_stale(generation)) state = AsyncError(e, st);
    } finally {
      _refilling = false;
    }
  }

  /// Files in the queue not yet acted on.
  Future<int> _remaining() => _queue.remaining(_acted);

  Future<int> _remainingFor(IndexQuery? query) async {
    if (query == null) return 0;
    final total = await ref.read(swipeQueueRepositoryProvider).count(query);
    final acted = await ref
        .read(mediaIndexDaoProvider)
        .countAmong(query, _acted.toList());
    final left = total - acted;
    return left < 0 ? 0 : left;
  }
}

/// What [SwipeDeckController.applyToFiles] did.
@immutable
class ApplyManyResult {
  const new(this.applied, {this.problem});

  /// Files acted on (one undo row each).
  final int applied;

  /// Why some (or all) files were skipped; null = none were.
  final SwipeActionProblem? problem;
}
