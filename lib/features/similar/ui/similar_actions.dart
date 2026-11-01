import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/similar/data/similar_repository.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';
import 'package:kfm/features/swipe/ui/ensure_swipe_session.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_source_launcher.dart';

/// One removal done from the Similar / Clean duplicates screens (TASK-C2),
/// kept for its Undo.
@immutable
class SimilarOp {
  const new({
    required this.sessionId,
    required this.firstSeq,
    required this.members,
    required this.removed,
  });

  final int sessionId;

  /// First recorded action (null: nothing was removed, only dismissed).
  final int? firstSeq;

  /// Group members dismissed by the operation.
  final List<String> members;
  final int removed;
}

/// Removes [toRemove] as normal `trash` actions on the active swipe session
/// (safe zone, batching, undo and delete mode apply; plan §8) and dismisses
/// [members]. Null when the D1 dialog was cancelled. Errors propagate.
Future<SimilarOp?> removeSimilar(
  BuildContext context,
  WidgetRef ref, {
  required List<FileRef> toRemove,
  required List<String> members,
}) async {
  final session = await ensureSwipeSession(context, ref);
  if (session == null || !context.mounted) return null;
  final title = context.l10n.similarSourceTitle;
  final firstSeq = await ref
      .read(swipeSourceLauncherProvider.notifier)
      .runOutsideDeck<int?>(
        sessionId: session.id,
        origin: SwipeSourceOrigin.similar,
        title: title,
        body: () async {
          int? first;
          final dispatcher = ref.read(swipeActionDispatcherProvider);
          for (final f in toRemove) {
            final seq = dispatcher.dispatch(session, f, SwipeAction.trash);
            first ??= seq;
          }
          await ref.read(similarRepositoryProvider).dismiss(members);
          return first;
        },
      );
  ref.read(deleteQueueProvider).maybeCommit(session.id).ignore();
  return SimilarOp(
    sessionId: session.id,
    firstSeq: firstSeq,
    members: members,
    removed: toRemove.length,
  );
}

/// Reverts [op]: undoes its actions (and anything newer, S2 semantics) and
/// shows the group again.
Future<void> undoSimilar(WidgetRef ref, SimilarOp op) async {
  final first = op.firstSeq;
  if (first != null) {
    await ref.read(undoServiceProvider).undoUntil(op.sessionId, first);
  }
  await ref.read(similarRepositoryProvider).undismiss(op.members);
  ref.invalidate(swipeDeckControllerProvider);
}

/// Shows "Removed N photos · Undo" for [op].
void showSimilarOpSnack(
  BuildContext context,
  WidgetRef ref,
  SimilarOp op, {
  VoidCallback? onUndone,
}) {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          op.removed == 0
              ? l10n.similarKeptAll
              : l10n.similarRemoved(op.removed),
        ),
        persist: false,
        action: SnackBarAction(
          label: l10n.undoAction,
          onPressed: () async {
            try {
              await undoSimilar(ref, op);
              onUndone?.call();
            } on Object {
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.swipeErrorGeneric)),
              );
            }
          },
        ),
      ),
    );
}

/// "Swipe this group" / "Swipe all groups" through SS1.
Future<void> swipeSimilar(
  BuildContext context,
  WidgetRef ref,
  List<SimilarGroup> groups,
) async {
  final l10n = context.l10n;
  final request = groups.length == 1
      ? FilesSourceRequest(
          origin: SwipeSourceOrigin.similar,
          title: l10n.similarSourceTitle,
          fileIds: [for (final f in groups.single.members) f.id],
          returnRoute: AppRoutes.similar,
        )
      : GroupsSourceRequest(
          origin: SwipeSourceOrigin.similar,
          title: l10n.similarSourceTitle,
          groups: [
            for (final g in groups) [for (final f in g.members) f.id],
          ],
          returnRoute: AppRoutes.similar,
        );
  final SwipeSourceOpenResult r;
  try {
    r = await ref.read(swipeSourceLauncherProvider.notifier).open(request);
  } on Object {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.swipeErrorGeneric)));
    }
    return;
  }
  if (!context.mounted) return;
  if (r is SwipeSourceOpened) context.go(AppRoutes.swipe);
  showSwipeSourceResult(context, r);
}
