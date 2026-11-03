import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/windows/windows_file_source.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/windows/folder_picker.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';

/// Settings → "Folders KFM scans" (TASK-PL1, Windows only, order 450): the
/// index roots, with Add, Remove and "Reset to defaults". Every change
/// starts a full scan, which also drops the files of a removed folder.
class WindowsRootsSection extends ConsumerWidget {
  const new({super.key, this.onRootsChanged});

  /// Tests replace the rescan; null = `MediaIndexer.fullScan`.
  final void Function(WidgetRef ref)? onRootsChanged;

  Future<void> _changed(WidgetRef ref) async {
    if (onRootsChanged case final cb?) {
      cb(ref);
    } else {
      ref.read(mediaIndexerProvider).fullScan().ignore();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final roots = ref.watch(windowsIndexRootStatusProvider).value ?? const [];
    final store = ref.watch(windowsIndexRootsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(dense: true, subtitle: Text(l10n.windowsRootsHint)),
        for (final root in roots)
          ListTile(
            leading: Icon(
              root.available
                  ? Icons.folder_outlined
                  : Icons.folder_off_outlined,
            ),
            title: Text(_display(root.path), overflow: TextOverflow.ellipsis),
            subtitle: root.available
                ? null
                : Text(l10n.windowsRootsNotAvailable),
            trailing: roots.length > 1
                ? IconButton(
                    tooltip: l10n.windowsRootsRemove(_display(root.path)),
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      await store.remove(root.path);
                      await _changed(ref);
                    },
                  )
                : null,
          ),
        ListTile(
          leading: const Icon(Icons.create_new_folder_outlined),
          title: Text(l10n.windowsRootsAdd),
          onTap: () async {
            final picked = await ref.read(pickFolderProvider)(
              confirmLabel: l10n.windowsRootsAddConfirm,
            );
            if (picked == null) return;
            await store.add(normalizeWindowsPath(picked));
            await _changed(ref);
          },
        ),
        ListTile(
          leading: const Icon(Icons.restart_alt),
          title: Text(l10n.windowsRootsReset),
          onTap: () async {
            await store.resetToDefaults();
            await _changed(ref);
          },
        ),
      ],
    );
  }
}

/// How a root is shown: the way Explorer writes it.
String _display(String path) => windowsIoPath(path).replaceAll('/', r'\');
