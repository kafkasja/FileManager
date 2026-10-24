import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Settings → Permissions (F4): current state of each access with a button
/// to change it.
class PermissionsSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(storageAccessControllerProvider.notifier);
    final access = ref.watch(storageAccessControllerProvider);
    final a = access.value;
    if (a == null) {
      return access.hasError
          ? ListTile(
              title: Text(l10n.permCheckFailed),
              trailing: TextButton(
                onPressed: controller.recheck,
                child: Text(l10n.retry),
              ),
            )
          : const ListTile(title: LinearProgressIndicator());
    }

    Future<void> thenRecheck(Future<void> Function() open) async {
      await open();
      await controller.recheck();
    }

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: Text(l10n.permRowMedia),
          subtitle: Text(_mediaStatus(l10n, a.media)),
          trailing: switch (a.media) {
            MediaAccess.granted => null,
            MediaAccess.permanentlyDenied => TextButton(
              onPressed: controller.openAppSettings,
              child: Text(l10n.permOpenSettings),
            ),
            MediaAccess.limited => TextButton(
              onPressed: controller.requestMedia,
              child: Text(l10n.limitedAllowAll),
            ),
            MediaAccess.unknown || MediaAccess.denied => TextButton(
              onPressed: controller.requestMedia,
              child: Text(l10n.permAllow),
            ),
          },
        ),
        ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(l10n.permRowAllFiles),
          subtitle: Text(switch (a.allFiles) {
            AllFilesAccess.notRequired => l10n.permStatusNotRequired,
            AllFilesAccess.granted => l10n.permStatusGranted,
            AllFilesAccess.notGranted => l10n.permStatusDenied,
          }),
          trailing: a.allFiles == AllFilesAccess.notRequired
              ? null
              : TextButton(
                  onPressed: () => thenRecheck(controller.openAllFilesSettings),
                  child: Text(
                    a.allFiles == AllFilesAccess.granted
                        ? l10n.permChange
                        : l10n.allFilesTurnOn,
                  ),
                ),
        ),
        if (a.mediaManagementSupported)
          ListTile(
            leading: const Icon(Icons.bolt_outlined),
            title: Text(l10n.permRowMediaManagement),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.mediaManagement
                      ? l10n.permStatusGranted
                      : l10n.permStatusDenied,
                ),
                Text(l10n.permRowMediaManagementHelp),
              ],
            ),
            isThreeLine: true,
            trailing: TextButton(
              onPressed: () =>
                  thenRecheck(controller.openMediaManagementSettings),
              child: Text(
                a.mediaManagement ? l10n.permChange : l10n.allFilesTurnOn,
              ),
            ),
          ),
      ],
    );
  }

  static String _mediaStatus(AppLocalizations l10n, MediaAccess media) =>
      switch (media) {
        MediaAccess.granted => l10n.permStatusGranted,
        MediaAccess.limited => l10n.permStatusLimited,
        MediaAccess.unknown => l10n.permStatusNotAsked,
        MediaAccess.denied ||
        MediaAccess.permanentlyDenied => l10n.permStatusDenied,
      };
}
