import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/app_info.dart';
import 'package:kfm/app/device_kind.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/diagnostics/error_log_providers.dart';
import 'package:kfm/core/utils/read_future.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';

/// Settings → About & advanced (TASK-E2): version, the promise, licences,
/// H5 error log; backup (X6) and Developer (debug) live in their files.
final versionEntry = SettingsEntry(
  id: 'about.version',
  titleBuilder: (c) => c.l10n.appTitle,
  subtitleBuilder: (c) => c.l10n.aboutVersion(appVersion),
  keywordsBuilder: (c) => c.l10n.settingsKeywordsVersion,
  builder: (c) => ListTile(
    leading: const Icon(Icons.info_outline),
    title: Text(c.l10n.appTitle),
    subtitle: Text(c.l10n.aboutVersion(appVersion)),
  ),
);

final promiseEntry = SettingsEntry(
  id: 'about.promise',
  titleBuilder: (c) => c.l10n.aboutPromise,
  selfExplanatory: true,
  builder: (c) => ListTile(
    leading: const Icon(Icons.verified_user_outlined),
    title: Text(c.l10n.aboutPromise),
  ),
);

/// Packages + C3's model and COCO notices (LicenseRegistry).
final licencesEntry = SettingsEntry(
  id: 'about.licences',
  titleBuilder: (c) => c.l10n.aboutLicences,
  selfExplanatory: true,
  builder: (c) => ListTile(
    leading: const Icon(Icons.gavel_outlined),
    title: Text(c.l10n.aboutLicences),
    onTap: () => showLicensePage(
      context: c,
      applicationName: c.l10n.appTitle,
      applicationVersion: appVersion,
    ),
  ),
);

final errorLogEntry = SettingsEntry(
  id: 'about.errorLog',
  titleBuilder: (c) => c.l10n.errorLogShare,
  subtitleBuilder: (c) => c.l10n.errorLogHelp,
  builder: (_) => const ErrorLogRows(),
);

/// H5: share / clear the on-device error log.
class ErrorLogRows extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final count = ref.watch(errorLogCountProvider).value ?? 0;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.bug_report_outlined),
          title: Text(l10n.errorLogShare),
          subtitle: Text(
            count == 0
                ? l10n.errorLogEmpty
                : l10n.errorLogShareSubtitleOn(count, deviceKind(context)),
          ),
          enabled: count > 0,
          onTap: () => _share(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.delete_sweep_outlined),
          title: Text(l10n.errorLogClear),
          enabled: count > 0,
          onTap: () => _clear(context, ref),
        ),
      ],
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final log = ref.read(errorLogProvider);
    final share = ref.read(errorLogSharerProvider);
    try {
      final header = await ref.readFuture(errorLogExportHeaderProvider.future);
      final file = await log.buildExport(header);
      if (!await share(file, l10n.errorLogShareSubject)) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.errorLogShareFailed)),
        );
      }
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorLogShareFailed)));
    }
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.errorLogClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.clearConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(errorLogProvider).clear();
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorLogCleared)));
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorLogClearFailed)));
    }
    if (context.mounted) ref.invalidate(errorLogCountProvider);
  }
}
