import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/file_reveal.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/windows/windows_file_source.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/windows/folder_picker.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/details/ui/file_details_sheet.dart';
import 'package:kfm/features/folders/ui/folder_picker_sheet.dart';

/// Settings row "Received files go to: Downloads › KFM" with Change and
/// Open (TASK-E1 D). E2 places it in its Connect & sharing section (setting
/// `connect.receiveFolder`); a change only affects new receives.
class ReceiveFolderTile extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final root = ref.watch(receiveDownloadsRootProvider);
    final custom = ref.watch(receiveFolderSettingProvider);
    return ListTile(
      key: const ValueKey('settings-receive-folder'),
      leading: const Icon(Icons.download_for_offline_outlined),
      title: Text(l10n.receiveFolderTitle),
      subtitle: Text(
        prettyFolder(root, downloads: platformDownloadsFolder()),
        key: const ValueKey('receive-folder-path'),
      ),
      onTap: () => unawaited(_change(context, ref)),
      trailing: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton(
            key: const ValueKey('receive-folder-change'),
            onPressed: () => unawaited(_change(context, ref)),
            child: Text(l10n.offerChangeFolder),
          ),
          IconButton(
            key: const ValueKey('receive-folder-open'),
            tooltip: l10n.offerOpenFolder,
            icon: const Icon(Icons.folder_open_outlined),
            onPressed: () => openFolderInBrowse(context, root),
          ),
          if (custom.isNotEmpty)
            IconButton(
              key: const ValueKey('receive-folder-reset'),
              tooltip: l10n.receiveFolderReset,
              icon: const Icon(Icons.restart_alt),
              onPressed: () => ref
                  .read(receiveFolderSettingProvider.notifier)
                  .set('')
                  .fireAndForget(),
            ),
        ],
      ),
    );
  }

  Future<void> _change(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final String? picked;
    if (isWindowsHost) {
      final raw = await ref.read(pickFolderProvider)(
        confirmLabel: l10n.receiveFolderTitle,
      );
      picked = raw == null ? null : normalizeWindowsPath(raw);
    } else {
      // Android: a KFM folder on primary storage.
      picked = await showFolderPicker(context, title: l10n.receiveFolderTitle);
    }
    if (picked == null || picked.isEmpty) return;
    ref.read(receiveFolderSettingProvider.notifier).set(picked).fireAndForget();
  }
}
