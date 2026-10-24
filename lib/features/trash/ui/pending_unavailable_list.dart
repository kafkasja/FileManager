import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/platform/permissions/ensure_all_files_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/trash/data/trash_providers.dart';

/// H2: deletes the pending-delete folder couldn't take. Shared by the sheet
/// and the Trash page: warning, Keep / Delete permanently per file, and
/// "Delete all N permanently". Every permanent delete asks first.
class PendingUnavailableList extends ConsumerWidget {
  const new({required this.items, super.key});

  final List<UnavailableDelete> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.tokens.spacing;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final access = ref.watch(storageAccessControllerProvider).value;
    final queue = ref.read(deleteQueueProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.pendingUnavailableBody),
        if (access != null && !access.canSeeAllFiles)
          ListTile(
            contentPadding: EdgeInsetsDirectional.zero,
            leading: const Icon(Icons.folder_open_outlined),
            title: Text(l10n.pendingUnavailableGrantAccess),
            trailing: TextButton(
              onPressed: () async {
                if (await ensureAllFilesAccess(context, ref)) {
                  await queue.retryUnavailable();
                }
              },
              child: Text(l10n.turnOn),
            ),
          ),
        SizedBox(height: spacing),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.all(spacing * 1.5),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: scheme.onErrorContainer),
                SizedBox(width: spacing),
                Expanded(
                  child: Text(
                    l10n.pendingUnavailableWarning,
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsetsDirectional.zero,
            leading: SizedBox.square(
              dimension: 48,
              child: switch (item.file) {
                final file? => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Thumbnail(file: file),
                ),
                null => const Icon(Icons.insert_drive_file_outlined),
              },
            ),
            title: Text(
              item.file?.name ?? item.row.fileId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [
                ?item.file?.folderPath,
                formatBytes(item.row.sizeBytes, locale: locale),
              ].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Wrap(
              children: [
                TextButton(
                  onPressed: () => queue.keepUnavailable([item.row.id]),
                  child: Text(l10n.pendingUnavailableKeep),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_forever_outlined,
                    color: scheme.error,
                  ),
                  tooltip: l10n.pendingUnavailableDeleteOne,
                  onPressed: () => _deletePermanently(context, ref, [item]),
                ),
              ],
            ),
          ),
        SizedBox(height: spacing),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: items.isEmpty
              ? null
              : () => _deletePermanently(context, ref, items),
          child: Text(l10n.pendingUnavailableDeleteAll(items.length)),
        ),
      ],
    );
  }

  Future<void> _deletePermanently(
    BuildContext context,
    WidgetRef ref,
    List<UnavailableDelete> chosen,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.warning_amber, color: scheme.error),
          content: Text(l10n.pendingUnavailableConfirm(chosen.length)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.pendingUnavailableConfirmButton),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final result = await ref
        .read(deleteQueueProvider)
        .deleteUnavailablePermanently([for (final c in chosen) c.row.id]);
    if (result.committed > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.pendingUnavailableDeleted(result.committed)),
        ),
      );
    }
  }
}
