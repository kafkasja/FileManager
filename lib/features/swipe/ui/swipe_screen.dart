import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/file_op_messages.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/connect/data/remote_source_provider.dart';
import 'package:kfm/features/connect/ui/known_device_names.dart';
import 'package:kfm/features/connect/ui/known_devices_providers.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/filters/ui/filter_sheet.dart';
import 'package:kfm/features/presets/ui/preset_chip.dart';
import 'package:kfm/features/rename/data/rename_providers.dart';
import 'package:kfm/features/reviewed/ui/reviewed_badge.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/session/ui/clear_sheet.dart';
import 'package:kfm/features/stats/data/stats_repository.dart';
import 'package:kfm/features/stats/ui/session_summary_sheet.dart';
import 'package:kfm/features/swipe/data/file_source_resolver.dart';
import 'package:kfm/features/swipe/data/swipe_file_ops.dart';
import 'package:kfm/features/swipe/domain/action_label.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/domain/swipe_deck_state.dart';
import 'package:kfm/features/swipe/ui/file_viewer.dart';
import 'package:kfm/features/swipe/ui/media_view.dart';
import 'package:kfm/features/swipe/ui/swipe_action_bar.dart';
import 'package:kfm/features/swipe/ui/swipe_buttons_row.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_feedback.dart';
import 'package:kfm/features/swipe/ui/swipe_settings_section.dart';
import 'package:kfm/features/swipe/ui/swipe_source_bar.dart';
import 'package:kfm/features/swipe/ui/swipe_source_launcher.dart';
import 'package:kfm/features/swipe/ui/swipe_toast.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/transfers/ui/transfer_badge.dart';
import 'package:kfm/features/trash/domain/delete_batch_policy.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/features/trash/ui/pending_unavailable_sheet.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/ui/undo_button.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Swipe tab (TASK-S1): one file large in the middle, left = trash,
/// right = keep, undo always visible.
///
/// N8: with a `'remote:<fp>'` [sourceId] (inside a [SwipeDeckScope]) it
/// swipes a connected device's folder: no preset chip, filter, Clear…,
/// rename pill or D1 question; Done needs the connection.
class SwipeScreen extends ConsumerWidget {
  const new({super.key, this.sourceId = kLocalSourceId});

  final String sourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final peer = peerOfSourceId(sourceId);
    ref
      ..listen(swipeFileOpEventsProvider, (_, next) {
        if (next.value case SwipeFileOpFailed(
          :final file,
          :final action,
          :final error,
        )) {
          // N8: the Swipe tab and a remote screen can both be alive.
          if (sourceIdOfFile(file.id) != sourceId) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                fileOpFailureText(context.l10n, file, action, error),
              ),
            ),
          );
        }
      })
      ..listen(deleteQueueErrorsProvider, (_, next) {
        if (next is AsyncData) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.deleteCommitFailed)));
        }
      });
    final needsChoice = peer == null
        ? ref.watch(needsDeleteModeChoiceProvider)
        : const AsyncData(false);
    if (needsChoice.value != false) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tabSwipe)),
        body: needsChoice.value == true
            ? const _PermanentModeConfirm()
            : needsChoice.hasError
            ? _Message(icon: Icons.error_outline, text: l10n.swipeErrorGeneric)
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final deckProvider = swipeDeckForSourceProvider(sourceId);
    final deck = ref.watch(deckProvider);
    final value = deck.value;
    final connected =
        peer != null && ref.watch(remotePeerConnectedProvider(peer));
    final device = _deviceName(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(peer == null ? l10n.tabSwipe : device),
        actions: [
          // N9: only while a transfer runs; opens the Transfers page.
          const TransferBadge(),
          if (peer == null) const PresetChip(),
          if (value != null && value.swiped > 0)
            TextButton(
              onPressed: peer != null && !connected
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.remoteSwipeFinishNeedsConnection(device),
                        ),
                      ),
                    )
                  : () => _finish(context, ref, value),
              child: Text(l10n.swipeDone),
            ),
          // SS1: the main filter is hidden (and kept) while a source is open.
          if (value != null && value.source == null && peer == null)
            IconButton(
              tooltip: l10n.filterButton,
              onPressed: () => showFilterSheet(context),
              icon: Badge(
                isLabelVisible: !FileFilter.decode(value.session.filterJson)
                    .isEmpty,
                smallSize: 8,
                child: const Icon(Icons.filter_list),
              ),
            ),
          if (value != null && peer == null)
            PopupMenuButton<String>(
              onSelected: (_) => showClearSheet(context, ref),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'clear', child: Text(l10n.clearMenu)),
              ],
            ),
        ],
      ),
      body: switch (deck) {
        AsyncData(:final value) => PopScope(
          // SS1: system back closes an open source.
          canPop: value.source == null,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            unawaited(ref.read(deckProvider.notifier).closeSource());
          },
          child: Column(
            children: [
              SwipeSourceBar(deck: value),
              Expanded(child: _Deck(deck: value)),
            ],
          ),
        ),
        AsyncError() => _Message(
          icon: Icons.error_outline,
          text: l10n.swipeErrorGeneric,
          action: TextButton(
            onPressed: () => ref.invalidate(deckProvider),
            child: Text(l10n.retry),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Future<void> _finish(
    BuildContext context,
    WidgetRef ref,
    SwipeDeckState deck,
  ) async {
    final l10n = context.l10n;
    final remote = deck.session.isRemote;
    final device = _deviceName(context);
    // P3: an unapplied rename batch would be dropped: ask first.
    final renameCount = remote
        ? 0
        : await ref.read(renameBatchCountProvider(deck.session.id).future);
    if (!context.mounted) return;
    if (renameCount > 0) {
      final choice = await showDialog<_RenameChoice>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.renameBeforeFinishTitle(renameCount)),
          content: Text(l10n.renameBeforeFinishBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _RenameChoice.discard),
              child: Text(l10n.renameDiscard),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, _RenameChoice.rename),
              child: Text(l10n.renameOpen),
            ),
          ],
        ),
      );
      if (!context.mounted || choice == null) return;
      if (choice == _RenameChoice.rename) {
        context.go(AppRoutes.renameBatch);
        return;
      }
    }
    final summary = await ref.read(
      pendingDeleteSummaryProvider(deck.session.id).future,
    );
    if (!context.mounted) return;
    final waiting = summary.queued + summary.failed;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.swipeFinishTitle),
        content: Text(
          remote
              ? l10n.remoteSwipeFinishBody(waiting, device)
              : deck.session.deleteMode == DeleteMode.permanent
              ? l10n.swipeFinishPermanent(waiting)
              : l10n.swipeFinishTrash(waiting),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.swipeFinishConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await ref
        .read(swipeDeckForSourceProvider(deck.session.sourceId).notifier)
        .finish();
    if (!context.mounted) return;
    if (!result.sessionEnded) {
      final text = !remote
          ? l10n.newSessionFailed
          : result.commit.userCancelled
          ? l10n.remoteSwipeDeclined(device)
          : result.commit.sourceUnavailable
          ? l10n.remoteSwipeWaiting(device)
          : l10n.newSessionFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
      return;
    }
    if (remote) {
      // N8: the session on that device is over: back to where it started.
      final locale = Localizations.localeOf(context).toLanguageTag();
      final messenger = ScaffoldMessenger.of(context);
      final count = result.commit.committed + summary.committed;
      final size = formatBytes(
        result.commit.bytes + summary.committedBytes,
        locale: locale,
      );
      await Navigator.of(context).maybePop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.sessionSummaryTrash(count, size))),
      );
      return;
    }
    // H2: files the pending folder couldn't take weren't deleted.
    final unavailable =
        result.commit.folderUnavailable + summary.folderUnavailable;
    if (unavailable > 0) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.pendingUnavailableAfterDone(unavailable)),
            action: SnackBarAction(
              label: l10n.pendingUnavailableOptions,
              onPressed: () => showPendingUnavailableSheet(context),
            ),
          ),
        );
      return;
    }
    // P8: the summary sheet (setting, on by default).
    if (await ref
        .read(settingsRepositoryProvider)
        .read(AppSettings.statsShowSessionSummary)) {
      final stats = await ref
          .read(statsRepositoryProvider)
          .forSession(deck.session.id);
      if (!context.mounted) return;
      if (stats.reviewed > 0) {
        await showSessionSummary(context, stats);
        return;
      }
    }
    if (!context.mounted) return;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final count = result.commit.committed + summary.committed;
    final size = formatBytes(
      result.commit.bytes + summary.committedBytes,
      locale: locale,
    );
    // Trash mode frees nothing yet: say where the files went.
    final message = deck.session.deleteMode == DeleteMode.permanent
        ? l10n.sessionSummary(count, size)
        : l10n.sessionSummaryTrash(count, size);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Deck extends ConsumerStatefulWidget {
  const new({required this.deck});

  final SwipeDeckState deck;

  @override
  ConsumerState<_Deck> createState() => _DeckState();
}

class _DeckState extends ConsumerState<_Deck> {
  final SwipeToastController _toast = SwipeToastController();

  /// P9: buttons and screen-reader actions fly the current card out.
  final SwipeCardController _cardController = SwipeCardController();

  /// H2: the "couldn't be moved to the pending folder" snackbar showing.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _unavailableSnack;

  @override
  void initState() {
    super.initState();
    if (widget.deck.restored) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showRestored());
    }
  }

  /// SE2: once per app start when a session with history was continued.
  void _showRestored() {
    if (!mounted) return;
    ref.read(SwipeDeckScope.providerOf(context).notifier).restoreNoticeSeen();
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (widget.deck.source) {
          final source? => l10n.swipeSourceRestored(source.title),
          null => l10n.restoredSnack,
        }),
        // Actions make a SnackBar persistent by default; these time out.
        persist: false,
        action: SnackBarAction(
          label: l10n.restoredStartFresh,
          onPressed: () => showClearSheet(context, ref),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _toast.dispose();
    super.dispose();
  }

  /// S4: vibration + "→ Trash" pill + screen-reader announcement.
  void _onSwiped(SwipeDirection direction) {
    final action = widget.deck.session.layout.actionFor(direction);
    if (action != null) _onApplied(action);
  }

  /// A swipe or an action bar tap (P4): apply, then the same feedback.
  bool _onApplied(SwipeAction action) =>
      SwipeFeedback.apply(context, ref, widget.deck, _toast, action);

  /// P9: what TalkBack reads for the card, and its actions (always on).
  Widget _cardSemantics(SwipeDeckState deck, FileRef current, Widget card) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final layout = deck.session.layout;
    final tags = ref.watch(tagsByIdProvider).value ?? const {};
    final undoable =
        ref.watch(undoableCountProvider(deck.session.id)).value ?? 0;
    return Semantics(
      label: l10n.swipeCardSemantics(
        current.kind == FileKind.video
            ? l10n.fileKindVideo
            : l10n.fileKindPhoto,
        current.name,
        formatBytes(current.sizeBytes, locale: locale),
        formatDate(current.sortDate, locale: locale),
      ),
      customSemanticsActions: {
        for (final d in swipeButtonOrder)
          if (layout.actionFor(d) case final a?)
            CustomSemanticsAction(
              label: swipeActionName(
                l10n,
                a,
                deck.session.deleteMode,
                tags: tags,
                deviceNameOf: (id) => knownDeviceName(ref, id),
              ),
            ): () =>
                _cardController.flyOff(d),
        if (undoable > 0)
          CustomSemanticsAction(label: l10n.undo): _undoFromSemantics,
      },
      child: card,
    );
  }

  Future<void> _undoFromSemantics() async {
    final outcome = await ref
        .read(SwipeDeckScope.providerOf(context).notifier)
        .undo();
    if (mounted) showUndoOutcome(context, outcome);
  }

  @override
  void didUpdateWidget(covariant _Deck oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new undo brought a file back: say so (the card animates in below).
    final mark = widget.deck.undoMark;
    if (mark != null && mark.tick != oldWidget.deck.undoMark?.tick) {
      _toast.show(context.l10n.undoneLabel);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the vibration setting loaded, so a swipe never reads a default.
    ref.watch(hapticsEnabledProvider);
    final deck = widget.deck;
    final l10n = context.l10n;
    // H2: a commit hit files the pending folder couldn't take.
    ref.listen(pendingDeleteSummaryProvider(deck.session.id), (prev, next) {
      final before = prev?.value?.folderUnavailable;
      final now = next.value?.folderUnavailable ?? 0;
      if (before == null || now <= before) return;
      // One snackbar with the session total, replaced as rows fail one by
      // one (snackbars queue otherwise).
      _unavailableSnack?.close();
      _unavailableSnack = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pendingUnavailableSnack(now)),
          action: SnackBarAction(
            label: l10n.pendingUnavailableOptions,
            onPressed: () => showPendingUnavailableSheet(context),
          ),
        ),
      );
    });
    final spacing = context.tokens.spacing;
    final current = deck.current;
    final peer = peerOfSourceId(deck.session.sourceId);
    final Widget body;
    if (current == null && peer != null) {
      body = _RemoteDeckEnd(deck: deck, peerFingerprint: peer);
    } else if (current == null && deck.source != null) {
      body = SwipeSourceFinished(deck: deck);
    } else if (current == null) {
      final scanning = ref.watch(indexStatusProvider).value is IndexScanning;
      final filtered = !FileFilter.decode(deck.session.filterJson).isEmpty;
      body = scanning && deck.swiped == 0
          ? _Message(
              icon: Icons.hourglass_empty,
              text: l10n.swipeLookingForPhotos,
            )
          : filtered
          ? _Message(
              icon: Icons.filter_list_off,
              text: deck.remaining == 0 && deck.swiped == 0
                  ? l10n.filterNoMatches
                  : l10n.filterAllDone,
              action: TextButton(
                onPressed: () => showFilterSheet(context),
                child: Text(l10n.filterChange),
              ),
            )
          : _Message(
              icon: deck.swiped > 0
                  ? Icons.check_circle_outline
                  : Icons.photo_library_outlined,
              text: deck.swiped > 0
                  ? l10n.swipeAllDone
                  : l10n.swipeEmptyLibrary,
              // H3/F4: some phones report access but show 0 photos.
              action: deck.swiped > 0
                  ? null
                  : Column(
                      children: [
                        SizedBox(height: spacing),
                        Text(
                          l10n.swipeEmptyLibraryHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        TextButton(
                          onPressed: () => ref
                              .read(storageAccessControllerProvider.notifier)
                              .openAppSettings(),
                          child: Text(l10n.permOpenSettings),
                        ),
                      ],
                    ),
            );
    } else {
      final next = deck.upcoming.length > 1 ? deck.upcoming[1] : null;
      body = Padding(
        padding: EdgeInsetsDirectional.all(spacing * 2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (next != null)
              Transform.scale(
                scale: 0.95,
                child: _CardFace(
                  key: ValueKey('under:${next.id}'),
                  file: next,
                  active: false,
                  // Under-card too, so it doesn't pop in when it moves up.
                  reviewed:
                      deck.showReviewedBadge &&
                      deck.reviewedIds.contains(next.id),
                ),
              ),
            _UndoReturn(
              mark: deck.undoMark?.fileId == current.id ? deck.undoMark : null,
              child: _cardSemantics(
                deck,
                current,
                SwipeCard(
                  key: ValueKey(current.id),
                  controller: _cardController,
                  canSwipe: (d) => SwipeFeedback.canSwipe(ref, deck, d),
                  onBlocked: (d) => SwipeFeedback.blocked(context, ref, d),
                  verticalEnabled: deck.session.layout.hasVertical,
                  onSwiped: _onSwiped,
                  hintFor: (d) => SwipeFeedback.hintFor(context, ref, deck, d),
                  onThresholdCrossed: () => SwipeFeedback.tick(ref),
                  // Video: tap = sound, double tap / expand = fullscreen (S5).
                  onTap: current.kind == FileKind.video
                      ? ref.read(videoMutedProvider.notifier).toggle
                      : () => openViewer(context, current).ignore(),
                  onDoubleTapDown: current.kind == FileKind.video
                      ? (_) => openViewer(context, current).ignore()
                      : null,
                  // S5/H3: outside the card's gestures, so no double-tap wait.
                  foreground: current.kind == FileKind.video
                      ? _ExpandButton(file: current)
                      : null,
                  child: _CardFace(
                    file: current,
                    hero: true,
                    reviewed:
                        deck.showReviewedBadge &&
                        deck.reviewedIds.contains(current.id),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(top: spacing),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.swipeProgress(deck.swiped, deck.remaining),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (peer == null) _RenamePill(sessionId: deck.session.id),
            ],
          ),
        ),
        _PendingDeleteBanner(sessionId: deck.session.id),
        if (deck.newFiles > 0)
          ActionChip(
            avatar: const Icon(Icons.fiber_new_outlined),
            label: Text(l10n.newFilesChip(deck.newFiles)),
            onPressed: () => ref
                .read(SwipeDeckScope.providerOf(context).notifier)
                .showNewFiles()
                .ignore(),
          ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              body,
              // Above the card area, so the last swipe's label still shows
              // on the "All done" screen.
              Align(
                alignment: AlignmentDirectional.topCenter,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(top: spacing * 4),
                  child: SwipeToast(controller: _toast),
                ),
              ),
            ],
          ),
        ),
        _Precache(upcoming: deck.upcoming),
        // P9: buttons instead of (or next to) swiping.
        if (current != null &&
            (ref.watch(swipeButtonsModeProvider).value ?? false) &&
            !ref.watch(viewerOpenProvider))
          SwipeButtonsRow(
            layout: deck.session.layout,
            deleteMode: deck.session.deleteMode,
            controller: _cardController,
            tags: ref.watch(tagsByIdProvider).value ?? const {},
          ),
        // P4: optional extra buttons (only while there is a file to act on).
        if (current != null)
          SwipeActionBar(
            layout: deck.session.layout,
            deleteMode: deck.session.deleteMode,
            onApply: _onApplied,
            onBlocked: (p) => SwipeFeedback.explain(context, p),
            problemOf: ref
                .read(SwipeDeckScope.providerOf(context).notifier)
                .problemForAction,
          ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            spacing * 2,
            0,
            spacing * 2,
            spacing * 2,
          ),
          child: Row(
            children: [
              // Hidden while the viewer is on top, so ✕ and undo are never
              // on screen together (S3).
              if (!ref.watch(viewerOpenProvider))
                UndoButton(sessionId: deck.session.id)
              else
                const SizedBox(height: 48),
            ],
          ),
        ),
      ],
    );
  }
}

/// Opens a video fullscreen (S5). Only the button itself takes taps.
class _ExpandButton extends StatelessWidget {
  const new({required this.file});

  final FileRef file;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      PositionedDirectional(
        end: 4,
        top: 4,
        child: IconButton(
          tooltip: context.l10n.videoOpenFullscreen,
          style: IconButton.styleFrom(
            backgroundColor: Colors.black54,
            foregroundColor: Colors.white,
          ),
          onPressed: () => openViewer(context, file).ignore(),
          icon: const Icon(Icons.open_in_full),
        ),
      ),
    ],
  );
}

class _CardFace extends StatelessWidget {
  const new({
    required this.file,
    this.hero = false,
    this.active = true,
    this.reviewed = false,
    super.key,
  });

  final FileRef file;

  /// P7: show the "Reviewed" pill.
  final bool reviewed;

  /// The card under the top one: its video is prepared, not played.
  final bool active;

  /// Only the top card flies into the viewer (S3).
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.tokens.radius);
    return Material(
      elevation: 2,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hero)
            Hero(
              tag: fileHeroTag(file),
              child: MediaView(file: file, active: active),
            )
          else
            MediaView(file: file, active: active),
          if (reviewed)
            const PositionedDirectional(
              start: 8,
              bottom: 12,
              child: ReviewedBadge(),
            ),
        ],
      ),
    );
  }
}

/// Decodes the next 3 images at display size so they appear instantly.
class _Precache extends StatelessWidget {
  const new({required this.upcoming});

  final List<FileRef> upcoming;

  @override
  Widget build(BuildContext context) {
    final widthPx =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      for (final f in upcoming.skip(1).take(3)) {
        if (f.kind != FileKind.image) continue;
        precacheImage(
          displayImageProvider(f, widthPx),
          context,
          // A file that can't be decoded shows its placeholder when it
          // becomes current; nothing to report for a preload.
          onError: (_, _) {},
        ).ignore();
      }
    });
    return const SizedBox.shrink();
  }
}

/// "N files waiting to be deleted · Retry" when commits are held back
/// (declined dialog or failure), or files failed (D2).
class _PendingDeleteBanner extends ConsumerWidget {
  const new({required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(pendingDeleteSummaryProvider(sessionId)).value;
    if (summary == null) return const SizedBox.shrink();
    final held = summary.queued >= kBatchThreshold + kUndoSafeZone;
    if (!held && summary.failed == 0) return const SizedBox.shrink();
    final l10n = context.l10n;
    // H2: Retry alone won't help; the user picks Keep / Delete permanently.
    if (summary.folderUnavailable > 0) {
      return MaterialBanner(
        leading: const Icon(Icons.folder_off_outlined),
        content: Text(l10n.pendingUnavailableBanner(summary.folderUnavailable)),
        actions: [
          TextButton(
            onPressed: () => showPendingUnavailableSheet(context),
            child: Text(l10n.pendingUnavailableOptions),
          ),
        ],
      );
    }
    return MaterialBanner(
      leading: const Icon(Icons.delete_sweep_outlined),
      content: Text(
        summary.failed > 0
            ? l10n.deleteBatchFailed(summary.failed)
            : l10n.deleteBatchWaiting(summary.queued),
      ),
      actions: [
        TextButton(
          onPressed: () => _retry(context, ref),
          child: Text(l10n.deleteBatchRetry),
        ),
      ],
    );
  }
}

/// N8: the other device's name for messages (from [SwipeDeckScope]).
String _deviceName(BuildContext context) {
  final named = SwipeDeckScope.deviceNameOf(context);
  return named.isEmpty ? context.l10n.remoteSwipeUnknownDevice : named;
}

/// Banner Retry. N8: a remote device's answer needs words.
Future<void> _retry(BuildContext context, WidgetRef ref) async {
  final result = await ref
      .read(SwipeDeckScope.providerOf(context).notifier)
      .retryDeletes();
  if (!context.mounted || !SwipeDeckScope.isRemote(context)) return;
  final device = _deviceName(context);
  final text = result.userCancelled
      ? context.l10n.remoteSwipeDeclined(device)
      : result.sourceUnavailable
      ? context.l10n.remoteSwipeWaiting(device)
      : null;
  if (text == null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// N8: a remote deck without a card: "Waiting for <A>…" with Connect
/// again (N6 reconnect) while the device is away, else "All done".
class _RemoteDeckEnd extends ConsumerStatefulWidget {
  const new({required this.deck, required this.peerFingerprint});

  final SwipeDeckState deck;
  final String peerFingerprint;

  @override
  ConsumerState<_RemoteDeckEnd> createState() => _RemoteDeckEndState();
}

class _RemoteDeckEndState extends ConsumerState<_RemoteDeckEnd> {
  bool _connecting = false;

  Future<void> _reconnect() async {
    setState(() => _connecting = true);
    final device = _deviceName(context);
    try {
      await ref
          .read(knownDeviceConnectorProvider)
          .reconnect(widget.peerFingerprint);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.remoteDeviceNotConnected(device)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connected = ref.watch(
      remotePeerConnectedProvider(widget.peerFingerprint),
    );
    if (connected && !widget.deck.waiting) {
      return _Message(
        icon: Icons.check_circle_outline,
        text: l10n.remoteSwipeAllDone,
      );
    }
    return _Message(
      icon: Icons.link_off,
      text: l10n.remoteSwipeWaiting(_deviceName(context)),
      action: Padding(
        padding: EdgeInsetsDirectional.only(top: context.tokens.spacing * 2),
        child: _connecting
            ? const CircularProgressIndicator()
            : FilledButton(
                onPressed: connected ? null : () => unawaited(_reconnect()),
                child: Text(l10n.remoteReconnect),
              ),
      ),
    );
  }
}

/// D1: the one confirmation before a "delete permanently" session.
class _PermanentModeConfirm extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pending = ref.watch(swipeSourceLauncherProvider);
    final spacing = context.tokens.spacing;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.all(spacing * 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_forever_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: spacing * 2),
            Text(
              l10n.permanentConfirmTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing),
            Text(l10n.permanentConfirmBody, textAlign: TextAlign.center),
            if (pending != null) ...[
              SizedBox(height: spacing),
              Text(
                l10n.swipeSourcePendingLine(pending.title),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
            SizedBox(height: spacing * 3),
            FilledButton(
              onPressed: () => startSessionWith(ref, DeleteMode.trash),
              child: Text(l10n.permanentConfirmUseTrash),
            ),
            SizedBox(height: spacing),
            OutlinedButton(
              onPressed: () => startSessionWith(ref, DeleteMode.permanent),
              child: Text(l10n.permanentConfirmYes),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const new({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsetsDirectional.all(context.tokens.spacing * 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
          SizedBox(height: context.tokens.spacing * 2),
          Text(text, textAlign: TextAlign.center),
          ?action,
        ],
      ),
    ),
  );
}

/// P2: why a move/copy swipe didn't happen.
String fileOpFailureText(
  AppLocalizations l,
  FileRef file,
  SwipeAction action,
  Object error,
) => fileOpFailureMessage(
  l,
  error,
  file,
  verb: action.type == SwipeActionType.copyTo
      ? FileOpVerb.copy
      : FileOpVerb.move,
  swipeTarget: true,
);

/// Undo: the card that came back slides in from the side it left by (or
/// fades in when unknown). Plays once per undo ([UndoMark.tick]).
class _UndoReturn extends StatelessWidget {
  const new({required this.mark, required this.child});

  final UndoMark? mark;
  final Widget child;

  static const duration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    final mark = this.mark;
    if (mark == null) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final from = switch (mark.from) {
          SwipeDirection.left => Offset(-size.width, 0),
          SwipeDirection.right => Offset(size.width, 0),
          SwipeDirection.up => Offset(0, -size.height),
          SwipeDirection.down => Offset(0, size.height),
          null => Offset.zero,
        };
        return TweenAnimationBuilder<double>(
          key: ValueKey('undo:${mark.tick}'),
          tween: Tween(begin: 0, end: 1),
          duration: duration,
          curve: Curves.easeOutCubic,
          child: child,
          builder: (context, t, child) => Transform.translate(
            offset: from * (1 - t),
            child: Opacity(
              opacity: mark.from == null ? t : 1,
              child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
            ),
          ),
        );
      },
    );
  }
}

enum _RenameChoice { rename, discard }

/// P3: "✎ N" while files wait in the rename batch; opens the screen.
class _RenamePill extends ConsumerWidget {
  const new({required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(renameBatchCountProvider(sessionId)).value ?? 0;
    if (count == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: ActionChip(
        visualDensity: VisualDensity.compact,
        label: Text(context.l10n.renamePill(count)),
        onPressed: () => context.go(AppRoutes.renameBatch),
      ),
    );
  }
}
