import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/core/utils/read_future.dart';
import 'package:kfm/features/rename/data/rename_providers.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/stats/data/stats_repository.dart';
import 'package:kfm/features/stats/ui/session_summary_sheet.dart';
import 'package:kfm/features/swipe/domain/swipe_deck_state.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/features/trash/ui/pending_unavailable_sheet.dart';

/// Done = SE3 "Start a new session" (moved out of the Swipe screen so the
/// desktop Sort screen runs the same flow, TASK-PL3): asks about an
/// unapplied rename batch, confirms the commit, then shows the summary.
Future<void> finishSwipeSession(
  BuildContext context,
  WidgetRef ref,
  SwipeDeckState deck,
) async {
  final l10n = context.l10n;
  final remote = deck.session.isRemote;
  final device = swipeDeviceName(context);
  // P3: an unapplied rename batch would be dropped: ask first.
  final renameCount = remote
      ? 0
      : await ref.readFuture(renameBatchCountProvider(deck.session.id).future);
  if (!context.mounted) return;
  if (renameCount > 0) {
    final choice = await showDialog<RenameChoice>(
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
            onPressed: () => Navigator.pop(context, RenameChoice.discard),
            child: Text(l10n.renameDiscard),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, RenameChoice.rename),
            child: Text(l10n.renameOpen),
          ),
        ],
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == RenameChoice.rename) {
      context.go(AppRoutes.renameBatch);
      return;
    }
  }
  final summary = await ref.readFuture(
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
          persist: false,
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
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

enum RenameChoice { rename, discard }

/// N8: the other device's name for messages (from [SwipeDeckScope]).
String swipeDeviceName(BuildContext context) {
  final named = SwipeDeckScope.deviceNameOf(context);
  return named.isEmpty ? context.l10n.remoteSwipeUnknownDevice : named;
}
