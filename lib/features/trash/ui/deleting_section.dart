import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/pending_folder.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/trash/data/trash_providers.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

/// Settings → Deleting: delete mode (D1) and pending-folder retention (D4).
class DeletingSection extends ConsumerWidget {
  const new({super.key});

  static const retentionPresets = [1, 3, 7, 14, 30];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    final mode = ref.watch(deleteModeSettingProvider).value ?? DeleteMode.trash;
    final days = clampRetentionDays(
      ref.watch(pendingRetentionDaysProvider).value ??
          kPendingRetentionRange.fallback,
    );
    final sessionActive = ref.watch(_activeSessionProvider).value != null;
    final scheme = Theme.of(context).colorScheme;

    void setMode(DeleteMode? m) {
      if (m == null) return;
      settings.write(AppSettings.deleteMode, m.name).fireAndForget();
    }

    return RadioGroup<DeleteMode>(
      groupValue: mode,
      onChanged: setMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioListTile<DeleteMode>(
            value: DeleteMode.trash,
            title: Text(l10n.deleteModeTrash),
            subtitle: Text(l10n.deleteModeTrashHelp),
          ),
          RadioListTile<DeleteMode>(
            value: DeleteMode.permanent,
            title: Text(l10n.deleteModePermanent),
            subtitle: Text(l10n.deleteModePermanentHelp),
          ),
          if (mode == DeleteMode.permanent)
            ListTile(
              leading: Icon(Icons.warning_amber_outlined, color: scheme.error),
              title: Text(
                l10n.deleteModePermanentWarning,
                style: TextStyle(color: scheme.error),
              ),
            ),
          if (sessionActive)
            ListTile(
              dense: true,
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.deleteModeNextSession),
            ),
          ListTile(
            title: Text(l10n.pendingRetentionLabel),
            subtitle: Text(l10n.pendingRetentionHelp),
            isThreeLine: true,
            trailing: DropdownButton<int>(
              value: retentionPresets.contains(days) ? days : null,
              hint: Text(l10n.pendingRetentionDays(days)),
              onChanged: (v) {
                if (v == null) return;
                settings
                    .write(AppSettings.pendingFolderRetentionDays, v)
                    .fireAndForget();
              },
              items: [
                for (final d in retentionPresets)
                  DropdownMenuItem(
                    value: d,
                    child: Text(l10n.pendingRetentionDays(d)),
                  ),
              ],
            ),
          ),
          if (ref.watch(pendingFolderProvider) != null)
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined),
              title: Text(l10n.pendingEmptyNow),
              onTap: () => _emptyNow(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _emptyNow(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.pendingEmptyTitle),
        content: Text(l10n.pendingEmptyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.pendingEmptyConfirm),
          ),
        ],
      ),
    );
    final folder = ref.read(pendingFolderProvider);
    if (ok != true || folder == null) return;
    final items = await folder.all();
    await folder.deleteNow([for (final i in items) i.id]);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.pendingEmptied(items.length))));
  }
}

final StreamProvider<Session?> _activeSessionProvider =
    StreamProvider.autoDispose(
      (ref) => ref.watch(sessionRepositoryProvider).watchActive(),
    );
