import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/features/browse/ui/open_file.dart';
import 'package:kfm/features/details/ui/file_details_sheet.dart';
import 'package:path/path.dart' as p;

/// Shows [path] in the system file manager with it selected (TASK-E3 /
/// E1 shared): Windows Explorer via `SHOpenFolderAndSelectItems`; macOS
/// Finder `open -R`; Linux opens the folder. Throws when it couldn't.
Future<void> revealInFolder(WidgetRef ref, String path) =>
    revealInFolderWith(ref.read(fileRevealerProvider), path);

/// Same as [revealInFolder] for code that holds a [Ref].
Future<void> revealInFolderWith(FileRevealer revealer, String path) =>
    revealer(path);

/// Reveals one path; replaced in tests.
typedef FileRevealer = Future<void> Function(String path);

final fileRevealerProvider = Provider<FileRevealer>((ref) {
  if (isWindowsHost) {
    final channel = ref.watch(windowsChannelProvider);
    return channel.revealInExplorer;
  }
  return (path) async {
    if (Platform.isMacOS) {
      await Process.run('open', ['-R', path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [p.dirname(path)]);
    } else {
      throw UnsupportedError('reveal is desktop only');
    }
  };
});

/// "Show in folder" for the file at [path] (TASK-E1): on Windows Explorer
/// opens with it selected ([revealInFolder]); elsewhere (or when that
/// fails) KFM's Browse opens its folder.
Future<void> showInFolder(
  BuildContext context,
  WidgetRef ref,
  String path,
) async {
  if (isWindowsHost) {
    try {
      await revealInFolder(ref, path);
      return;
    } on Object {
      // Explorer didn't start: KFM's own Browse instead.
    }
  }
  if (!context.mounted) return;
  openFolderInBrowse(context, p.posix.dirname(path));
}

/// Opens the file at [path] like a tap in Browse (its viewer or app).
Future<void> openFileAt(
  BuildContext context,
  WidgetRef ref,
  String path,
) async {
  final f = await ref.read(fileSourceProvider).statPath(path);
  if (f == null || !context.mounted) return;
  await openFile(context, ref, f);
}

/// Copies [path] (in the platform's own form) and says so.
Future<void> copyPathToClipboard(BuildContext context, String path) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final copied = context.l10n.detailsPathCopied;
  await Clipboard.setData(
    ClipboardData(text: isWindowsHost ? path.replaceAll('/', r'\') : path),
  );
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(copied)));
}

/// [folder] for people: the part from the downloads folder on as
/// "Downloads › KFM › Phone", otherwise its last three folders.
String prettyFolder(String folder, {required String downloads}) {
  final f = folder.replaceAll(r'\', '/');
  final d = downloads.replaceAll(r'\', '/');
  final List<String> parts;
  if (f.toLowerCase() == d.toLowerCase() ||
      f.toLowerCase().startsWith('${d.toLowerCase()}/')) {
    parts = [
      p.posix.basename(d),
      ...f.substring(d.length).split('/').where((s) => s.isNotEmpty),
    ];
  } else {
    final all = f.split('/').where((s) => s.isNotEmpty).toList();
    parts = all.length <= 3 ? all : all.sublist(all.length - 3);
  }
  return parts.join(' › ');
}

/// The "… saved to …" snackbar after a receive (TASK-E1): Show in folder,
/// and ⋮ Open / Copy path. [path] is the file (one file) or null (several:
/// Show in folder opens [folder]).
void showSavedSnackBar(
  BuildContext context,
  WidgetRef ref, {
  required String text,
  required String folder,
  String? path,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final l10n = context.l10n;
  final file = path;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: const ValueKey('saved-snackbar'),
        persist: false,
        duration: const Duration(seconds: 8),
        content: Row(
          children: [
            Expanded(child: Text(text)),
            if (file != null)
              PopupMenuButton<String>(
                key: const ValueKey('saved-more'),
                tooltip: l10n.selectionMore,
                iconColor: Theme.of(context).colorScheme.onInverseSurface,
                onSelected: (v) {
                  if (!context.mounted) return;
                  switch (v) {
                    case 'open':
                      unawaited(openFileAt(context, ref, file));
                    case 'copy':
                      unawaited(copyPathToClipboard(context, file));
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'open',
                    child: Text(l10n.offerOpenFolder),
                  ),
                  PopupMenuItem(
                    value: 'copy',
                    child: Text(l10n.detailsCopyPath),
                  ),
                ],
              ),
          ],
        ),
        action: SnackBarAction(
          key: const ValueKey('saved-show'),
          label: l10n.showInFolder,
          onPressed: () {
            if (!context.mounted) return;
            if (file != null) {
              unawaited(showInFolder(context, ref, file));
            } else {
              openFolderInBrowse(context, folder);
            }
          },
        ),
      ),
    );
}

/// ⋮ Show in folder / Open / Copy path for a received file (TASK-E1:
/// Transfers rows and received offers). [path] resolves the file lazily
/// (an `ms:` id needs the file source); null hides the menu's file items.
class ReceivedFileMenu extends ConsumerWidget {
  const new({required this.folder, required this.path, super.key});

  final String folder;
  final Future<String?> Function() path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.selectionMore,
      icon: const Icon(Icons.more_vert),
      onSelected: (v) async {
        final file = await path();
        if (!context.mounted) return;
        switch (v) {
          case 'show' when file != null:
            await showInFolder(context, ref, file);
          case 'show':
            openFolderInBrowse(context, folder);
          case 'open' when file != null:
            await openFileAt(context, ref, file);
          case 'copy':
            await copyPathToClipboard(context, file ?? folder);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'show', child: Text(l10n.showInFolder)),
        PopupMenuItem(value: 'open', child: Text(l10n.offerOpenFolder)),
        PopupMenuItem(value: 'copy', child: Text(l10n.detailsCopyPath)),
      ],
    );
  }
}
