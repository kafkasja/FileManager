import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/windows/windows_file_source.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/windows/folder_picker.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';

/// Settings → Privacy & access → Where KFM looks (TASK-E2 §6): on Windows
/// the "Look everywhere" switch (replaces "Folders KFM scans"), on the
/// phone a plain explanation of Android's index.
final whereKfmLooksEntry = SettingsEntry(
  id: 'privacy.whereKfmLooks',
  titleBuilder: (c) => c.l10n.whereKfmLooksTitle,
  subtitleBuilder: (c) => c.l10n.whereKfmLooksHelp,
  keywordsBuilder: (c) => c.l10n.settingsKeywordsIndex,
  // Desktop: Windows only (macOS/Linux have no index scope yet).
  visible: (ref) => !ref.watch(formFactorProvider).isDesktop || isWindowsHost,
  builder: (_) => Consumer(
    builder: (c, ref, _) => ref.watch(formFactorProvider).isDesktop
        ? const LookEverywhereRows()
        : ListTile(
            leading: const Icon(Icons.travel_explore_outlined),
            title: Text(c.l10n.whereKfmLooksTitle),
            subtitle: Text(c.l10n.whereKfmLooksPhoneBody),
          ),
  ),
);

/// "Look everywhere" (on by default) with what it does and doesn't, and
/// "Choose folders instead…" under it.
class LookEverywhereRows extends ConsumerWidget {
  const new({super.key, this.onScopeChanged});

  /// Tests replace the rescan; null = `MediaIndexer.fullScan`.
  final void Function(WidgetRef ref)? onScopeChanged;

  Future<void> _set(WidgetRef ref, IndexScope scope) async {
    await ref.read(windowsIndexRootsProvider).setScope(scope);
    if (onScopeChanged case final cb?) {
      cb(ref);
    } else {
      ref.read(mediaIndexerProvider).fullScan().ignore();
    }
  }

  Future<void> _turnOff(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.lookEverywhereOffConfirmTitle),
        content: Text(l10n.lookEverywhereOffConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('look-everywhere-off-confirm'),
            onPressed: () => Navigator.pop(c, true),
            child: Text(l10n.lookEverywhereOffConfirm),
          ),
        ],
      ),
    );
    if (ok == true) await _set(ref, IndexScope.whereIAm);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scope = ref.watch(windowsIndexScopeProvider).value;
    if (scope == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const ValueKey('look-everywhere'),
          secondary: const Icon(Icons.travel_explore_outlined),
          title: Text(l10n.lookEverywhereTitle),
          subtitle: Text(switch (scope) {
            IndexScope.everywhere => l10n.lookEverywhereOnHelp,
            IndexScope.whereIAm => l10n.lookEverywhereOffHelp,
            IndexScope.chosenFolders => l10n.lookEverywhereChosenHelp,
          }),
          isThreeLine: true,
          value: scope == IndexScope.everywhere,
          onChanged: (on) =>
              on ? _set(ref, IndexScope.everywhere) : _turnOff(context, ref),
        ),
        if (scope == IndexScope.chosenFolders)
          WindowsRootsSection(onRootsChanged: onScopeChanged)
        else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 56),
              child: TextButton(
                key: const ValueKey('look-choose-folders'),
                onPressed: () => _set(ref, IndexScope.chosenFolders),
                child: Text(l10n.lookEverywhereChoose),
              ),
            ),
          ),
      ],
    );
  }
}

/// The chosen folders (TASK-PL1; E2: shown under Look everywhere when
/// "Choose folders instead…" is on), with Add, Remove and "Reset to
/// defaults". Every change starts a full scan, which also drops the files
/// of a removed folder.
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
    final roots = ref.watch(windowsChosenRootStatusProvider).value ?? const [];
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
