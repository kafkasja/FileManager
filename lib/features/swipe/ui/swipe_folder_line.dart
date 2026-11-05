import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/adaptive_sheet.dart';
import 'package:kfm/app/haptics.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/browse/ui/widgets/browse_parts.dart';
import 'package:kfm/features/details/ui/file_details_sheet.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swipe_folder_line.g.dart';

/// E4: "Show the file's folder" on the swipe card (default on).
@Riverpod(keepAlive: true)
Stream<bool> swipeShowFolder(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.swipeShowFolder);

/// E4: one line in the progress row with the current file's folder
/// ("Camera · Internal storage"). Tap = a sheet with the full path, Copy
/// path, Open folder and Details; long press = copy. [remote] (a connected
/// device's deck, N8): its path is relative to the shared folder, so only
/// Copy is offered.
class SwipeFolderLine extends ConsumerWidget {
  const new({required this.file, this.remote = false, super.key});

  final FileRef file;
  final bool remote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!(ref.watch(swipeShowFolderProvider).value ?? true)) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final label = remote
        ? remoteFolderLabel(file.folderPath)
        : folderLabel(l10n, file.folderPath);
    final style = Theme.of(context).textTheme.labelMedium;
    return Semantics(
      button: true,
      label: l10n.swipeFolderSemantics(label),
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('swipe-folder-line'),
        onTap: () => unawaited(_openSheet(context, ref)),
        onLongPress: () => unawaited(copyFilePath(context, ref, file)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: spacing / 2),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context, WidgetRef ref) =>
      showAdaptiveSheet<void>(
        context: context,
        builder: (sheet) => _FolderSheet(file: file, remote: remote),
      );
}

class _FolderSheet extends ConsumerWidget {
  const new({required this.file, required this.remote});

  final FileRef file;
  final bool remote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                spacing * 3,
                0,
                spacing * 3,
                spacing,
              ),
              child: SelectableText(
                file.path,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text(l10n.detailsCopyPath),
              onTap: () {
                Navigator.of(context).pop();
                unawaited(copyFilePath(context, ref, file));
              },
            ),
            if (!remote)
              ListTile(
                leading: const Icon(Icons.folder_open_outlined),
                title: Text(l10n.detailsOpenFolder),
                onTap: () => openFolderInBrowse(
                  context,
                  file.folderPath,
                  highlightId: file.id,
                ),
              ),
            if (!remote)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.swipeFolderDetails),
                onTap: () {
                  Navigator.of(context).pop();
                  unawaited(showFileDetails(context, file));
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Copies [file]'s path, with a light vibration and "Path copied"
/// (Android 13+ shows its own "Copied" message instead).
Future<void> copyFilePath(
  BuildContext context,
  WidgetRef ref,
  FileRef file,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final copied = context.l10n.detailsPathCopied;
  final sdk = ref.read(deviceStorageProvider).value?.sdkInt ?? 0;
  await Clipboard.setData(ClipboardData(text: file.path));
  lightHaptic(ref);
  if (sdk >= 33) return;
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(copied), persist: false));
}

/// A connected device's folder: the last part of its path relative to the
/// shared folder.
String remoteFolderLabel(String folderPath) {
  final slash = folderPath.lastIndexOf('/');
  return slash < 0 ? folderPath : folderPath.substring(slash + 1);
}
