import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/browse/ui/widgets/browse_parts.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';

/// The user's answer to a name collision: the choice, and whether it
/// applies to every remaining collision of the batch.
typedef CollisionAnswer = (CollisionChoice, bool applyToAll);

/// "photo.jpg already exists in Holiday" → Replace / Keep both / Skip
/// (TASK-B4 §6). Dismissing it = Skip for this file only.
/// [showApplyToAll]: false for a single-file operation.
Future<CollisionAnswer> showCollisionDialog(
  BuildContext context, {
  required FileRef incoming,
  required FileRef existing,
  bool showApplyToAll = true,
}) async =>
    await showDialog<CollisionAnswer>(
      context: context,
      builder: (_) => CollisionDialog(
        name: incoming.name,
        folder: nameOfFolder(context.l10n, existing.folderPath),
        showApplyToAll: showApplyToAll,
      ),
    ) ??
    (CollisionChoice.skip, false);

class CollisionDialog extends StatefulWidget {
  const new({
    required this.name,
    required this.folder,
    this.showApplyToAll = true,
    super.key,
  });

  final String name;

  /// Display name of the target folder.
  final String folder;
  final bool showApplyToAll;

  @override
  State<CollisionDialog> createState() => _CollisionDialogState();
}

class _CollisionDialogState extends State<CollisionDialog> {
  bool _applyToAll = false;

  void _answer(CollisionChoice choice) =>
      Navigator.of(context).pop<CollisionAnswer>((choice, _applyToAll));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.collisionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.collisionBody(widget.name, widget.folder)),
          if (widget.showApplyToAll)
            CheckboxListTile(
              value: _applyToAll,
              onChanged: (v) => setState(() => _applyToAll = v ?? false),
              title: Text(l10n.collisionApplyAll),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsetsDirectional.zero,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _answer(CollisionChoice.skip),
          child: Text(l10n.collisionSkip),
        ),
        TextButton(
          onPressed: () => _answer(CollisionChoice.replace),
          child: Text(l10n.collisionReplace),
        ),
        FilledButton(
          onPressed: () => _answer(CollisionChoice.keepBoth),
          child: Text(l10n.collisionKeepBoth),
        ),
      ],
    );
  }
}
