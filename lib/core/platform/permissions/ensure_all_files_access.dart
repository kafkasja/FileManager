import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Call before a feature shows non-media files (B1 folders, C1 documents,
/// D5 pending folder, X1 share-in). Returns true if All files access is
/// granted or not needed; otherwise explains it in a sheet and opens the
/// system page. "Not now" is remembered until the app restarts.
Future<bool> ensureAllFilesAccess(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(storageAccessControllerProvider.notifier);
  final access = await ref.read(storageAccessControllerProvider.future);
  if (access.canSeeAllFiles) return true;
  if (ref.read(allFilesNotNowProvider) || !context.mounted) return false;

  final turnOn = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _AllFilesSheet(),
  );
  if (turnOn != true) {
    ref.read(allFilesNotNowProvider.notifier).set();
    return false;
  }
  // permission_handler returns once the user leaves the system page.
  await controller.openAllFilesSettings();
  final updated = await controller.recheck();
  return updated.canSeeAllFiles;
}

class _AllFilesSheet extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.allFilesSheetText,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.notNow),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.allFilesTurnOn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
