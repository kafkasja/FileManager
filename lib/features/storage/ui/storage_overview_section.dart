import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/storage/ui/storage_providers.dart';

/// Settings → Storage overview (TASK-C1): where "Big files" starts.
class StorageOverviewSection extends ConsumerWidget {
  const new({super.key});

  static const int _mb = 1024 * 1024;
  static const List<int> options = [50 * _mb, 100 * _mb, 250 * _mb, 500 * _mb];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final current =
        ref.watch(storageBigFileThresholdProvider).value ??
        AppSettings.storageBigFileThresholdBytes.defaultValue;
    return ListTile(
      leading: const Icon(Icons.sd_storage_outlined),
      title: Text(l10n.storageBigFileThreshold),
      trailing: DropdownButton<int>(
        value: options.contains(current) ? current : null,
        onChanged: (v) {
          if (v == null) return;
          ref
              .read(settingsRepositoryProvider)
              .write(AppSettings.storageBigFileThresholdBytes, v)
              .fireAndForget();
        },
        items: [
          for (final o in options)
            DropdownMenuItem(
              value: o,
              child: Text(formatBytes(o, locale: locale)),
            ),
        ],
      ),
    );
  }
}
