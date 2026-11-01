import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/data/swipe_source_repository.dart';
import 'package:kfm/features/swipe/data/swipe_source_resolver.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swipe_source_launcher.g.dart';

/// Opens a swipe source on the active session (TASK-SS1). Callers then go to
/// the swipe tab themselves:
///
///   final r = await ref.read(swipeSourceLauncherProvider.notifier).open(req);
///   if (!context.mounted) return;
///   if (r is SwipeSourceOpened) context.go(AppRoutes.swipe);
///   showSwipeSourceResult(context, r);
@Riverpod(keepAlive: true)
class SwipeSourceLauncher extends _$SwipeSourceLauncher {
  /// State = a prepared source waiting for a session (D1 gate), else null.
  @override
  PreparedSource? build() => null;

  Future<SwipeSourceOpenResult> open(SwipeSourceRequest request) async {
    final (prepared, result) = await ref
        .read(swipeSourceResolverProvider)
        .prepare(request);
    if (prepared == null) return result;

    final active = await ref.read(sessionRepositoryProvider).active();
    if (active != null) {
      await attach(active.id, prepared);
      ref.invalidate(swipeDeckControllerProvider);
      return result;
    }
    // No session yet: the deck attaches this source in build().
    state = prepared;
    ref.invalidate(needsDeleteModeChoiceProvider);
    // D1 (V1 bug 6): in permanent mode a deck rebuild would create the
    // session and skip the question. D1's choice rebuilds the deck.
    final mode = DeleteMode.parse(
      await ref.read(settingsRepositoryProvider).read(AppSettings.deleteMode),
    );
    if (mode != DeleteMode.permanent) {
      ref.invalidate(swipeDeckControllerProvider);
    }
    return result;
  }

  /// Also used by the deck for a pending source.
  Future<void> attach(int sessionId, PreparedSource prepared) async {
    final undo = ref.read(undoRepositoryProvider);
    await ref.read(sessionRepositoryProvider).flush(); // main cursor on disk
    await undo.prepare(sessionId);
    await ref
        .read(swipeSourceRepositoryProvider)
        .open(
          sessionId: sessionId,
          source: prepared,
          lastSeq: undo.lastSeq(sessionId),
        );
  }

  /// The deck took the pending source.
  PreparedSource? takePending() {
    final pending = state;
    if (pending != null) state = null;
    return pending;
  }

  /// For actions recorded outside the deck on [sessionId] (C2 "Keep best,
  /// remove others"). The seq range is stored as a closed `outside` row, so
  /// the main deck's resume floor ignores these actions. Then the deck
  /// rebuilds (its acted set changed).
  Future<T> runOutsideDeck<T>({
    required int sessionId,
    required SwipeSourceOrigin origin,
    required String title,
    required Future<T> Function() body,
  }) async {
    final undo = ref.read(undoRepositoryProvider);
    await ref.read(sessionRepositoryProvider).flush();
    await undo.prepare(sessionId);
    final from = undo.lastSeq(sessionId);
    try {
      return await body();
    } finally {
      await ref
          .read(swipeSourceRepositoryProvider)
          .recordOutside(
            sessionId: sessionId,
            origin: origin,
            title: title,
            fromSeq: from,
            toSeq: undo.lastSeq(sessionId),
          );
      ref.invalidate(swipeDeckControllerProvider);
    }
  }
}

/// One snackbar for [result]; nothing for a clean open.
void showSwipeSourceResult(BuildContext context, SwipeSourceOpenResult result) {
  final l10n = context.l10n;
  final text = switch (result) {
    SwipeSourceOpened(truncated: true) => l10n.swipeSourceTruncated,
    SwipeSourceOpened(
      :final files,
      :final skippedNotMedia,
      :final skippedMissing,
    )
        when skippedNotMedia + skippedMissing > 0 =>
      l10n.swipeSourceSkipped(files, skippedNotMedia + skippedMissing),
    SwipeSourceOpened() => null,
    SwipeSourceNotOpened(:final problem) => switch (problem) {
      SwipeSourceProblem.empty => l10n.swipeSourceEmpty,
      SwipeSourceProblem.noMedia => l10n.swipeSourceNoMedia,
      SwipeSourceProblem.invalidFilter => l10n.swipeSourceInvalidFilter,
      SwipeSourceProblem.noMatches => l10n.swipeSourceNoMatches,
    },
  };
  if (text == null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// "Back to …" label for a source's origin.
String swipeSourceOriginLabel(AppLocalizations l10n, SwipeSourceOrigin o) =>
    switch (o) {
      SwipeSourceOrigin.storage => l10n.swipeSourceOriginStorage,
      SwipeSourceOrigin.similar => l10n.swipeSourceOriginSimilar,
      SwipeSourceOrigin.contentSearch => l10n.swipeSourceOriginSearch,
      SwipeSourceOrigin.smartGroup => l10n.swipeSourceOriginGroups,
      SwipeSourceOrigin.sameTime => l10n.swipeSourceOriginSameTime,
      SwipeSourceOrigin.search => l10n.swipeSourceOriginSearch,
      SwipeSourceOrigin.browse => l10n.swipeSourceOriginBrowse,
      SwipeSourceOrigin.sharedIn => l10n.swipeSourceOriginSharedIn,
      SwipeSourceOrigin.cloud => l10n.swipeSourceOriginCloud,
      SwipeSourceOrigin.externalPlace => l10n.swipeSourceOriginExternal,
      SwipeSourceOrigin.other => l10n.swipeSourceOriginOther,
    };

/// Origin icon for the source bar.
IconData swipeSourceOriginIcon(SwipeSourceOrigin o) => switch (o) {
  SwipeSourceOrigin.storage => Icons.pie_chart_outline,
  SwipeSourceOrigin.similar => Icons.burst_mode_outlined,
  SwipeSourceOrigin.contentSearch || SwipeSourceOrigin.search => Icons.search,
  SwipeSourceOrigin.smartGroup => Icons.auto_awesome_mosaic_outlined,
  SwipeSourceOrigin.sameTime => Icons.timer_outlined,
  SwipeSourceOrigin.browse => Icons.folder_outlined,
  SwipeSourceOrigin.sharedIn => Icons.share_outlined,
  SwipeSourceOrigin.cloud => Icons.cloud_outlined,
  SwipeSourceOrigin.externalPlace => Icons.usb,
  SwipeSourceOrigin.other => Icons.photo_library_outlined,
};
