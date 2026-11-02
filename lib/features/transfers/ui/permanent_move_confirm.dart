import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

/// Asked when a move starts while this device's delete setting is
/// permanent (TASK-N11; U2 and X3 reuse it). Returns the delete mode for
/// this job only ("Use trash instead" → trash; the setting is unchanged),
/// or null when dismissed (nothing starts).
Future<DeleteMode?> confirmPermanentMove(
  BuildContext context, {
  required int count,
}) {
  final l10n = context.l10n;
  return showDialog<DeleteMode>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.permanentMoveTitle),
      content: Text(l10n.permanentMoveBody(count)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const ValueKey('permanent-move-trash'),
          onPressed: () => Navigator.pop(context, DeleteMode.trash),
          child: Text(l10n.permanentMoveUseTrash),
        ),
        FilledButton(
          key: const ValueKey('permanent-move-confirm'),
          onPressed: () => Navigator.pop(context, DeleteMode.permanent),
          child: Text(l10n.permanentMoveConfirm),
        ),
      ],
    ),
  );
}
