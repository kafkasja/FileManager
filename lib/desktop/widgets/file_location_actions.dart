import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/file_reveal.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/desktop/shell/desktop_address_bar.dart';
import 'package:kfm/desktop/shell/desktop_location.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/desktop/tabs/desktop_tabs_controller.dart';
import 'package:kfm/desktop/widgets/desktop_context_menu.dart';
import 'package:kfm/desktop/widgets/desktop_keys.dart';
import 'package:kfm/features/details/ui/file_details_sheet.dart';

/// "Where is this file?" (TASK-E3), shared by Sort, Browse and search.

/// Copy as path: Windows paths, no quotes, one per line (Ctrl+Shift+C).
Future<void> copyPathsAsText(WidgetRef ref, List<String> paths) async {
  if (paths.isEmpty) return;
  final text = [for (final p in paths) windowsPathOf(p)].join('\r\n');
  await Clipboard.setData(ClipboardData(text: text));
  final context = ref.context;
  if (!context.mounted) return;
  ref
      .read(desktopStatusMessageProvider.notifier)
      .show(context.l10n.desktopPathCopied(paths.length));
}

/// Opens [file]'s folder in a new tab with it selected and scrolled to.
void openFileLocation(WidgetRef ref, FileRef file) {
  ref.read(desktopRevealRequestProvider.notifier).request(file.path);
  ref
      .read(desktopTabsControllerProvider.notifier)
      .openInNewTab(FolderLocation(file.folderPath));
}

/// Windows Explorer with [path] selected.
Future<void> showInExplorer(WidgetRef ref, String path) async {
  try {
    await revealInFolder(ref, path);
  } on Object catch (e) {
    final context = ref.context;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.toString()), persist: false));
  }
}

/// Windows' Properties sheet; elsewhere KFM's details (B10).
Future<void> showFileProperties(
  BuildContext context,
  WidgetRef ref,
  FileRef file,
) async {
  if (isWindowsHost) {
    final ok = await ref
        .read(windowsChannelProvider)
        .showProperties(file.path)
        .catchError((Object _) => false);
    if (ok) return;
  }
  if (context.mounted) await showFileDetails(context, file);
}

/// The menu entries for [files] (Open file location only where the
/// file isn't in the open folder already).
List<DesktopMenuEntry> fileLocationMenuEntries(
  BuildContext context,
  WidgetRef ref,
  List<FileRef> files, {
  bool openLocation = true,
}) {
  final l10n = context.l10n;
  final single = files.length == 1 ? files.single : null;
  return [
    if (openLocation && single != null)
      DesktopMenuEntry(
        key: const ValueKey('menu-open-location'),
        label: l10n.desktopOpenFileLocation,
        icon: Icons.folder_open_outlined,
        divider: true,
        onSelected: () => openFileLocation(ref, single),
      ),
    if (single != null && isWindowsHost)
      DesktopMenuEntry(
        key: const ValueKey('menu-show-in-explorer'),
        label: l10n.desktopShowInExplorer,
        icon: Icons.open_in_browser,
        divider: !openLocation,
        onSelected: () => unawaited(showInExplorer(ref, single.path)),
      ),
    DesktopMenuEntry(
      key: const ValueKey('menu-copy-path'),
      label: l10n.desktopCopyAsPath,
      icon: Icons.content_paste_go,
      shortcut: DesktopKeys.label(DesktopKeys.copyAsPath),
      onSelected: () =>
          unawaited(copyPathsAsText(ref, [for (final f in files) f.path])),
    ),
    if (single != null)
      DesktopMenuEntry(
        key: const ValueKey('menu-properties'),
        label: l10n.desktopProperties,
        icon: Icons.info_outline,
        shortcut: DesktopKeys.label(DesktopKeys.properties),
        onSelected: () => unawaited(showFileProperties(context, ref, single)),
      ),
  ];
}
