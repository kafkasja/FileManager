import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/utils/read_future.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

/// The active session for callers outside the swipe tab (TASK-SS1, C2).
/// Without one: in permanent delete mode D1's choice is asked as a dialog
/// (Cancel → null, nothing created); in trash mode a session starts
/// silently. Never skips D1.
Future<Session?> ensureSwipeSession(BuildContext context, WidgetRef ref) async {
  final sessions = ref.read(sessionRepositoryProvider);
  final active = await sessions.active();
  if (active != null) return active;
  ref.invalidate(needsDeleteModeChoiceProvider);
  final needsChoice = await ref.readFuture(
    needsDeleteModeChoiceProvider.future,
  );
  if (!needsChoice) {
    await startSessionWith(ref, DeleteMode.trash);
    return await sessions.active();
  }
  if (!context.mounted) return null;
  final l10n = context.l10n;
  final choice = await showDialog<DeleteMode>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.permanentConfirmTitle),
      content: Text(l10n.permanentConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(DeleteMode.permanent),
          child: Text(l10n.permanentConfirmYes),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(DeleteMode.trash),
          child: Text(l10n.permanentConfirmUseTrash),
        ),
      ],
    ),
  );
  if (choice == null) return null;
  await startSessionWith(ref, choice);
  return await sessions.active();
}
