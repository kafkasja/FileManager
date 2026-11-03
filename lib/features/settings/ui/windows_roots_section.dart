import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/windows/windows_file_source.dart';
import 'package:kfm/core/index/index_providers.dart';
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
            final path = await showDialog<String>(
              context: context,
              builder: (_) => const _AddRootDialog(),
            );
            if (path == null) return;
            await store.add(path);
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

/// Asks for a folder path (the native folder picker comes with the
/// Windows build, TASK-PL1 part 2).
class _AddRootDialog extends StatefulWidget {
  const new();

  @override
  State<_AddRootDialog> createState() => _AddRootDialogState();
}

class _AddRootDialogState extends State<_AddRootDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim();
    final path = normalizeWindowsPath(raw);
    if (raw.isEmpty || !Directory(windowsIoPath(path)).existsSync()) {
      setState(() => _error = context.l10n.windowsRootsPathMissing);
      return;
    }
    Navigator.of(context).pop(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.windowsRootsAdd),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.windowsRootsPathLabel,
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.windowsRootsAddConfirm),
        ),
      ],
    );
  }
}
