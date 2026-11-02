import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/app_info.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/diagnostics/error_log_providers.dart';

/// Version + the app's promises (F6), H5 error log share/clear.
class AboutSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final count = ref.watch(errorLogCountProvider).value ?? 0;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.appTitle),
          subtitle: Text(l10n.aboutVersion(appVersion)),
        ),
        ListTile(
          leading: const Icon(Icons.verified_user_outlined),
          title: Text(l10n.aboutPromise),
        ),
        ListTile(
          leading: const Icon(Icons.bug_report_outlined),
          title: Text(l10n.errorLogShare),
          subtitle: Text(
            count == 0 ? l10n.errorLogEmpty : l10n.errorLogShareSubtitle(count),
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
        // Packages + C3's model and COCO notices (LicenseRegistry).
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: Text(l10n.aboutLicences),
          onTap: () => showLicensePage(
            context: context,
            applicationName: l10n.appTitle,
            applicationVersion: appVersion,
          ),
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
      final header = await ref.read(errorLogExportHeaderProvider.future);
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
