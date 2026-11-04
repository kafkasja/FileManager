import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_startup_check.dart';

/// Q6: the startup database check reset a damaged database or couldn't
/// open it. Stays until dismissed (once per start).
class DbStartupBanner extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<DbStartupBanner> createState() => _DbStartupBannerState();
}

class _DbStartupBannerState extends ConsumerState<DbStartupBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(dbStartupReportProvider);
    if (_dismissed || report.state == DbStartupState.ok) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = switch (report.state) {
      DbStartupState.reset => l10n.dbResetNotice(report.backupName ?? ''),
      _ => l10n.dbUnavailableNotice,
    };
    return MaterialBanner(
      backgroundColor: scheme.errorContainer,
      leading: Icon(Icons.warning_amber, color: scheme.onErrorContainer),
      content: Text(text, style: TextStyle(color: scheme.onErrorContainer)),
      actions: [
        TextButton(
          onPressed: () => setState(() => _dismissed = true),
          child: Text(l10n.dismiss),
        ),
      ],
    );
  }
}
