import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/pending_folder.dart';
import 'package:kfm/core/platform/permissions/ensure_all_files_access.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/trash/data/trash_providers.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

/// Settings → Deleting: delete mode (D1) and pending-folder retention (D4).
class DeletingSection extends ConsumerWidget {
  const new({super.key});

  static const retentionPresets = [1, 3, 7, 14, 30];

  /// Dropdown value of "Custom…" (never stored).
  static const _custom = 0;

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
              onChanged: (v) async {
                if (v == null) return;
                final value = v == _custom
                    ? await showDialog<int>(
                        context: context,
                        builder: (_) => _CustomRetentionDialog(initial: days),
                      )
                    : v;
                if (value == null) return;
                settings
                    .write(AppSettings.pendingFolderRetentionDays, value)
                    .fireAndForget();
              },
              items: [
                for (final d in retentionPresets)
                  DropdownMenuItem(
                    value: d,
                    child: Text(l10n.pendingRetentionDays(d)),
                  ),
                DropdownMenuItem(
                  value: _custom,
                  child: Text(l10n.pendingRetentionCustom),
                ),
              ],
            ),
          ),
          // H2: the automatic cleanup failed (shown until a purge succeeds).
          if (ref.watch(_purgeErrorProvider).value case final error?
              when error.isNotEmpty)
            ListTile(
              leading: Icon(Icons.error_outline, color: scheme.error),
              title: Text(
                error == FileOpFailure.permissionDenied.name
                    ? l10n.pendingPurgeFailedPermission
                    : l10n.pendingPurgeFailed,
                style: TextStyle(color: scheme.error),
              ),
              trailing: error == FileOpFailure.permissionDenied.name
                  ? TextButton(
                      onPressed: () => ensureAllFilesAccess(context, ref),
                      child: Text(l10n.turnOn),
                    )
                  : null,
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

final StreamProvider<String> _purgeErrorProvider = StreamProvider.autoDispose(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(AppSettings.pendingLastPurgeError),
);

/// H2: "Custom…" retention, 1–90 days. Returns the value, or null.
class _CustomRetentionDialog extends StatefulWidget {
  const new({required this.initial});

  final int initial;

  @override
  State<_CustomRetentionDialog> createState() => _CustomRetentionDialogState();
}

class _CustomRetentionDialogState extends State<_CustomRetentionDialog> {
  late final TextEditingController _text = TextEditingController(
    text: '${widget.initial}',
  );

  int? get _value {
    final v = int.tryParse(_text.text);
    return v != null &&
            v >= kPendingRetentionRange.min &&
            v <= kPendingRetentionRange.max
        ? v
        : null;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = _value;
    return AlertDialog(
      title: Text(l10n.pendingRetentionCustomTitle),
      content: TextField(
        controller: _text,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          helperText: l10n.pendingRetentionCustomHelper,
          errorText: value == null ? l10n.pendingRetentionCustomError : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: value == null ? null : () => Navigator.pop(context, value),
          child: Text(l10n.pendingRetentionCustomSave),
        ),
      ],
    );
  }
}

final StreamProvider<Session?> _activeSessionProvider =
    StreamProvider.autoDispose(
      (ref) => ref.watch(sessionRepositoryProvider).watchActive(),
    );
