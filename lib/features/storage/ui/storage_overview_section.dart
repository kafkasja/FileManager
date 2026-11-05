import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';
import 'package:kfm/features/settings/ui/widgets/unit_input_row.dart';
import 'package:kfm/features/storage/ui/storage_providers.dart';

/// Settings → Files & display: where "Big files" starts (TASK-C1, E2).
final bigFileThresholdEntry = SettingsEntry(
  id: 'files.bigFileThreshold',
  titleBuilder: (c) => c.l10n.storageBigFileThreshold,
  subtitleBuilder: (c) => c.l10n.storageBigFileThresholdHelp,
  keywordsBuilder: (c) => c.l10n.settingsKeywordsBigFiles,
  builder: (_) => const BigFileThresholdRow(),
);

/// One threshold for the Browse highlight and Storage → Big files, any
/// value 1 MB … 1 TB (TASK-E2 §4).
class BigFileThresholdRow extends ConsumerWidget {
  const new({super.key});

  static const int _mb = 1024 * 1024;
  static const List<int> presets = [50 * _mb, 100 * _mb, 250 * _mb, 500 * _mb];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current =
        ref.watch(storageBigFileThresholdProvider).value ??
        AppSettings.storageBigFileThresholdBytes.defaultValue;
    String format(int v) => formatSizeSetting(context, v);
    return UnitInputRow.size(
      icon: Icons.sd_storage_outlined,
      title: l10n.storageBigFileThreshold,
      subtitle: l10n.bigFileThresholdLine(format(current)),
      value: current,
      presets: presets,
      format: format,
      onSaved: (v) => ref
          .read(settingsRepositoryProvider)
          .write(AppSettings.storageBigFileThresholdBytes, v)
          .fireAndForget(),
    );
  }
}
