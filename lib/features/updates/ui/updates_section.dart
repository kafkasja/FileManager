import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/updates/data/update_checker.dart';
import 'package:kfm/features/updates/domain/update_status.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Settings → Updates (TASK-X7): the opt-in daily check, "Check now" (works
/// with the switch off) and the installed version.
class UpdatesSettingsSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = ref.watch(updateCheckEnabledProvider).value ?? false;
    final status = ref.watch(updateCheckerProvider);
    final current = ref.watch(currentAppVersionProvider);
    return Column(
      children: [
        SwitchListTile(
          key: const ValueKey('updates-check-enabled'),
          secondary: const Icon(Icons.system_update_outlined),
          title: Text(l10n.updatesCheckSetting),
          subtitle: Text(l10n.updatesCheckSettingHelp),
          value: enabled,
          onChanged: (v) => ref
              .read(settingsRepositoryProvider)
              .write(AppSettings.updateCheckEnabled, v)
              .fireAndForget(),
        ),
        ListTile(
          key: const ValueKey('updates-check-now'),
          leading: const Icon(Icons.refresh),
          title: Text(l10n.updatesCheckNow),
          subtitle: Text(
            _statusLine(l10n, status) ?? l10n.updatesCurrentVersion('$current'),
          ),
          enabled: status is! UpdateChecking,
          onTap: () => unawaited(_checkNow(context, ref)),
        ),
      ],
    );
  }

  static String? _statusLine(AppLocalizations l10n, UpdateStatus? s) =>
      switch (s) {
        null => null,
        UpdateChecking() => l10n.updatesChecking,
        UpToDate(noReleases: true) => l10n.updatesNoReleases,
        UpToDate() => l10n.updatesUpToDate,
        UpdateAvailable(:final release) => l10n.updatesAvailable(
          '${release.version}',
        ),
        UpdateCheckFailed() => l10n.updatesLastCheckFailed,
      };

  Future<void> _checkNow(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = context.l10n;
    final result = await ref
        .read(updateCheckerProvider.notifier)
        .checkNow(manual: true);
    final text = switch (result) {
      null || UpdateChecking() => null,
      UpToDate(noReleases: true) => l10n.updatesNoReleases,
      UpToDate() => l10n.updatesUpToDate,
      UpdateAvailable(:final release) => l10n.updatesAvailable(
        '${release.version}',
      ),
      UpdateCheckFailed(:final error) => failureText(l10n, error),
    };
    if (text != null) {
      messenger?.showSnackBar(SnackBar(content: Text(text)));
    }
  }

  static String failureText(AppLocalizations l10n, Object error) =>
      switch (error) {
        ReleaseCheckException(failure: ReleaseCheckFailure.offline) =>
          l10n.updatesFailedOffline,
        ReleaseCheckException(failure: ReleaseCheckFailure.busy) =>
          l10n.updatesFailedBusy,
        _ => l10n.updatesFailed('$error'),
      };
}
