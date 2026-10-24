import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/filters/ui/filter_sheet.dart';
import 'package:kfm/features/presets/ui/preset_chip.dart';
import 'package:kfm/features/rename/data/rename_providers.dart';
import 'package:kfm/features/reviewed/ui/reviewed_badge.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/session/ui/clear_sheet.dart';
import 'package:kfm/features/stats/data/stats_repository.dart';
import 'package:kfm/features/stats/ui/session_summary_sheet.dart';
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
import 'package:kfm/features/swipe/ui/swipe_settings_section.dart';
import 'package:kfm/features/swipe/ui/swipe_toast.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/trash/domain/delete_batch_policy.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/features/trash/ui/pending_unavailable_sheet.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/ui/undo_button.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Swipe tab (TASK-S1): one file large in the middle, left = trash,
/// right = keep, undo always visible.
class SwipeScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref
      ..listen(swipeFileOpEventsProvider, (_, next) {
        if (next.value case SwipeFileOpFailed(
          :final file,
          :final action,
          :final error,
        )) {
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
    final needsChoice = ref.watch(needsDeleteModeChoiceProvider);
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
    final deck = ref.watch(swipeDeckControllerProvider);
    final value = deck.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabSwipe),
        actions: [
          const PresetChip(),
          if (value != null && value.swiped > 0)
            TextButton(
              onPressed: () => _finish(context, ref, value),
              child: Text(l10n.swipeDone),
            ),
          if (value != null)
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
          if (value != null)
            PopupMenuButton<String>(
              onSelected: (_) => showClearSheet(context, ref),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'clear', child: Text(l10n.clearMenu)),
              ],
            ),
        ],
      ),
      body: switch (deck) {
        AsyncData(:final value) => _Deck(deck: value),
        AsyncError() => _Message(
          icon: Icons.error_outline,
          text: l10n.swipeErrorGeneric,
          action: TextButton(
            onPressed: () => ref.invalidate(swipeDeckControllerProvider),
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
    // P3: an unapplied rename batch would be dropped: ask first.
    final renameCount = await ref.read(
      renameBatchCountProvider(deck.session.id).future,
    );
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
          deck.session.deleteMode == DeleteMode.permanent
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
        .read(swipeDeckControllerProvider.notifier)
        .finish();
    if (!context.mounted) return;
    if (!result.sessionEnded) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.newSessionFailed)));
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
    ref.read(swipeDeckControllerProvider.notifier).restoreNoticeSeen();
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.restoredSnack),
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
  bool _onApplied(SwipeAction action) {
    final deck = widget.deck;
    final done = ref.read(swipeDeckControllerProvider.notifier).apply(action);
    if (!done) return false;
    if (ref.read(hapticsEnabledProvider).value ?? true) {
      HapticFeedback.lightImpact().ignore();
    }
    final label = actionLabel(
      context.l10n,
      action,
      deleteMode: deck.session.deleteMode,
      tagName: _tagName(action),
    );
    _toast.show(label);
    SemanticsService.sendAnnouncement(
      View.of(context),
      label,
      Directionality.of(context),
    ).ignore();
    return true;
  }

  SwipeHint? _hintFor(SwipeDirection d) {
    final action = widget.deck.session.layout.actionFor(d);
    if (action == null) return null;
    final tokens = context.tokens;
    final label = actionLabel(
      context.l10n,
      action,
      deleteMode: widget.deck.session.deleteMode,
      tagName: _tagName(action),
    );
    return (
      color: switch (action.type) {
        SwipeActionType.trash => tokens.swipeTrash,
        SwipeActionType.keep => tokens.swipeKeep,
        _ => tokens.swipeOther,
      },
      icon: swipeActionIcon(action.type),
      label: label,
    );
  }

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
    final outcome = await ref.read(swipeDeckControllerProvider.notifier).undo();
    if (mounted) showUndoOutcome(context, outcome);
  }

  String? _tagName(SwipeAction action) =>
      ref.read(tagsByIdProvider).value?[action.tagId]?.name;

  /// P2: released on a direction whose action can't run right now.
  void _onBlocked(SwipeDirection direction) {
    final problem = ref
        .read(swipeDeckControllerProvider.notifier)
        .problemFor(direction);
    if (problem != null) _explain(problem); // unmapped: nothing to explain
  }

  void _explain(SwipeActionProblem problem) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (problem) {
          SwipeActionProblem.tagMissing => l10n.swipeProblemTagMissing,
          SwipeActionProblem.unsupported => l10n.swipeProblemUnsupported,
        }),
      ),
    );
  }

  void _tick() {
    if (ref.read(hapticsEnabledProvider).value ?? true) {
      HapticFeedback.selectionClick().ignore();
    }
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
    final Widget body;
    if (current == null) {
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
                  canSwipe: (d) =>
                      deck.session.layout.actionFor(d) != null &&
                      ref
                              .read(swipeDeckControllerProvider.notifier)
                              .problemFor(d) ==
                          null,
                  onBlocked: _onBlocked,
                  verticalEnabled: deck.session.layout.hasVertical,
                  onSwiped: _onSwiped,
                  hintFor: _hintFor,
                  onThresholdCrossed: _tick,
                  // Video: tap = sound, double tap / expand = fullscreen (S5).
                  onTap: current.kind == FileKind.video
                      ? ref.read(videoMutedProvider.notifier).toggle
                      : () => openViewer(context, current).ignore(),
                  onDoubleTapDown: current.kind == FileKind.video
                      ? (_) => openViewer(context, current).ignore()
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
              _RenamePill(sessionId: deck.session.id),
            ],
          ),
        ),
        _PendingDeleteBanner(sessionId: deck.session.id),
        if (deck.newFiles > 0)
          ActionChip(
            avatar: const Icon(Icons.fiber_new_outlined),
            label: Text(l10n.newFilesChip(deck.newFiles)),
            onPressed: () => ref
                .read(swipeDeckControllerProvider.notifier)
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
            onBlocked: _explain,
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
          if (hero && file.kind == FileKind.video)
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
          onPressed: () => ref
              .read(swipeDeckControllerProvider.notifier)
              .retryDeletes()
              .ignore(),
          child: Text(l10n.deleteBatchRetry),
        ),
      ],
    );
  }
}

/// D1: the one confirmation before a "delete permanently" session.
class _PermanentModeConfirm extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
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
) {
  final failure = error is FileOpException ? error.failure : null;
  return switch (failure) {
    FileOpFailure.notFound => l.fileOpFolderMissing,
    FileOpFailure.userCancelled => l.fileOpDeclined,
    FileOpFailure.noSpace => l.fileOpNoSpace,
    FileOpFailure.unsupported ||
    FileOpFailure.permissionDenied => l.fileOpNeedsAllFiles,
    _ =>
      action.type == SwipeActionType.copyTo
          ? l.fileOpCopyFailed(file.name)
          : l.fileOpMoveFailed(file.name),
  };
}

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
