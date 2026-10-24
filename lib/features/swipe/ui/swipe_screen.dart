import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/session/ui/clear_sheet.dart';
import 'package:kfm/features/swipe/domain/action_label.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/domain/swipe_deck_state.dart';
import 'package:kfm/features/swipe/ui/file_viewer.dart';
import 'package:kfm/features/swipe/ui/media_view.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_settings_section.dart';
import 'package:kfm/features/swipe/ui/swipe_toast.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';
import 'package:kfm/features/trash/domain/delete_batch_policy.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/ui/undo_button.dart';

/// Swipe tab (TASK-S1): one file large in the middle, left = trash,
/// right = keep, undo always visible.
class SwipeScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.listen(deleteQueueErrorsProvider, (_, next) {
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
          if (value != null && value.swiped > 0)
            TextButton(
              onPressed: () => _finish(context, ref, value),
              child: Text(l10n.swipeDone),
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
    final locale = Localizations.localeOf(context).toLanguageTag();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.sessionSummary(
            result.commit.committed + summary.committed,
            formatBytes(
              result.commit.bytes + summary.committedBytes,
              locale: locale,
            ),
          ),
        ),
      ),
    );
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
    final deck = widget.deck;
    final action = deck.session.layout.actionFor(direction);
    final done = ref
        .read(swipeDeckControllerProvider.notifier)
        .swipe(direction);
    if (!done || action == null) return;
    if (ref.read(hapticsEnabledProvider).value ?? true) {
      HapticFeedback.lightImpact().ignore();
    }
    final label = actionLabel(
      context.l10n,
      action,
      deleteMode: deck.session.deleteMode,
    );
    _toast.show(label);
    SemanticsService.sendAnnouncement(
      View.of(context),
      label,
      Directionality.of(context),
    ).ignore();
  }

  SwipeHint? _hintFor(SwipeDirection d) {
    final action = widget.deck.session.layout.actionFor(d);
    if (action == null) return null;
    final tokens = context.tokens;
    final label = actionLabel(
      context.l10n,
      action,
      deleteMode: widget.deck.session.deleteMode,
    );
    return switch (action.type) {
      SwipeActionType.trash => (
        color: tokens.swipeTrash,
        icon: Icons.delete_outline,
        label: label,
      ),
      SwipeActionType.keep => (
        color: tokens.swipeKeep,
        icon: Icons.check,
        label: label,
      ),
      _ => (
        color: tokens.swipeOther,
        icon: Icons.drive_file_move_outline,
        label: label,
      ),
    };
  }

  void _tick() {
    if (ref.read(hapticsEnabledProvider).value ?? true) {
      HapticFeedback.selectionClick().ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the vibration setting loaded, so a swipe never reads a default.
    ref.watch(hapticsEnabledProvider);
    final deck = widget.deck;
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final current = deck.current;
    final Widget body;
    if (current == null) {
      final scanning = ref.watch(indexStatusProvider).value is IndexScanning;
      body = scanning && deck.swiped == 0
          ? _Message(
              icon: Icons.hourglass_empty,
              text: l10n.swipeLookingForPhotos,
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
                ),
              ),
            SwipeCard(
              key: ValueKey(current.id),
              canSwipe: (d) => deck.session.layout.actionFor(d) != null,
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
              child: _CardFace(file: current, hero: true),
            ),
            Align(
              alignment: AlignmentDirectional.topCenter,
              child: Padding(
                padding: EdgeInsetsDirectional.only(top: spacing * 2),
                child: SwipeToast(controller: _toast),
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
          child: Text(
            l10n.swipeProgress(deck.swiped, deck.remaining),
            style: Theme.of(context).textTheme.labelLarge,
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
        Expanded(child: body),
        _Precache(upcoming: deck.upcoming),
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
    super.key,
  });

  final FileRef file;

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
