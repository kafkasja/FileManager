import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/desktop/widgets/file_explorer_parts.dart';
import 'package:kfm/desktop/widgets/file_type_icon.dart';
import 'package:kfm/features/trash/ui/widgets/expiry_badge.dart';

/// What the Properties dialog's buttons asked for.
enum TrashPropertiesAction { restore, deleteForever, openLocation }

/// Recycle-Bin-like Properties for trashed items (TASK-E3): name,
/// original location (opens the folder), deleted, size, type; for KFM's
/// pending items where they wait and days left. Several items: one
/// summary. Buttons Restore / Delete forever / Close.
Future<TrashPropertiesAction?> showTrashProperties(
  BuildContext context,
  List<TrashedItem> items, {
  required String systemLabel,
}) => showDialog<TrashPropertiesAction>(
  context: context,
  builder: (context) =>
      TrashPropertiesDialog(items: items, systemLabel: systemLabel),
);

class TrashPropertiesDialog extends StatelessWidget {
  const new({required this.items, required this.systemLabel, super.key});

  final List<TrashedItem> items;

  /// "Recycle Bin" / "System trash".
  final String systemLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final total = items.fold(0, (a, i) => a + i.original.sizeBytes);
    final single = items.length == 1 ? items.single : null;
    Widget row(String label, Widget value, {Key? key}) => Padding(
      key: key,
      padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
    Text text(String s) => Text(s, style: theme.textTheme.bodyMedium);
    final now = DateTime.now();
    final List<Widget> rows;
    if (single != null) {
      final pending = single.location == TrashLocation.pendingFolder;
      rows = [
        row(
          l10n.trashPropsOriginalLocation,
          key: const ValueKey('trash-props-location'),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InkWell(
              key: const ValueKey('trash-props-open-location'),
              onTap: () =>
                  Navigator.of(context).pop(TrashPropertiesAction.openLocation),
              child: Text(
                single.original.folderPath.replaceAll('/', r'\'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
        row(
          l10n.trashPropsDeleted,
          key: const ValueKey('trash-props-deleted'),
          text(formatDateAndTime(single.trashedAt, locale: locale)),
        ),
        row(
          l10n.detailsSize,
          key: const ValueKey('trash-props-size'),
          text(formatBytes(single.original.sizeBytes, locale: locale)),
        ),
        row(
          l10n.detailsType,
          key: const ValueKey('trash-props-type'),
          FileTypeText(single.original.name, style: theme.textTheme.bodyMedium),
        ),
        row(
          l10n.desktopTrashWhere,
          text(pending ? l10n.trashPropsWaiting : systemLabel),
        ),
        if (single.expiresAt case final e?)
          row(
            l10n.desktopTrashDaysLeft,
            text(switch (daysLeft(e, now)) {
              0 => l10n.trashExpiresToday,
              final d => l10n.trashDaysLeft(d),
            }),
          ),
      ];
    } else {
      rows = [row(l10n.detailsSize, text(formatBytes(total, locale: locale)))];
    }
    return AlertDialog(
      key: const ValueKey('trash-properties'),
      title: Row(
        children: [
          if (single != null)
            FileTypeIcon.path(single.original.path, size: 32)
          else
            const Icon(Icons.delete_outline, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              single?.original.name ??
                  l10n.trashPropsSummary(
                    items.length,
                    formatBytes(total, locale: locale),
                  ),
              key: const ValueKey('trash-props-name'),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
      actions: [
        FilledButton.icon(
          key: const ValueKey('trash-props-restore'),
          onPressed: () =>
              Navigator.of(context).pop(TrashPropertiesAction.restore),
          icon: const Icon(Icons.restore, size: 18),
          label: Text(l10n.trashRestore),
        ),
        OutlinedButton.icon(
          key: const ValueKey('trash-props-delete'),
          onPressed: () =>
              Navigator.of(context).pop(TrashPropertiesAction.deleteForever),
          icon: const Icon(Icons.delete_forever_outlined, size: 18),
          label: Text(l10n.trashDeleteForever),
        ),
        TextButton(
          key: const ValueKey('trash-props-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.desktopClose),
        ),
      ],
    );
  }
}
