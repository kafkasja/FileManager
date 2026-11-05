import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/utils/human_units.dart';
import 'package:kfm/features/browse/ui/same_time_controller.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';
import 'package:kfm/features/settings/ui/widgets/settings_tiles.dart';
import 'package:kfm/features/settings/ui/widgets/unit_input_row.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'browse_settings_section.g.dart';

/// A size label on every photo/video tile in Browse.
@Riverpod(keepAlive: true)
Stream<bool> browseShowSizes(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.browseShowSizes);

/// Big files (at least `AppSettings.storageBigFileThresholdBytes`, the one
/// threshold Storage → Big files uses too) get a colored size label.
@Riverpod(keepAlive: true)
Stream<bool> browseHighlightBig(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.browseHighlightBig);

// Settings → Files & display (TASK-E2): the Browse rows.

final showSizesEntry = SettingsEntry(
  id: 'files.showSizes',
  titleBuilder: (c) => c.l10n.settingsShowSizes,
  subtitleBuilder: (c) => c.l10n.settingsShowSizesHelp,
  builder: (_) => BoolSettingSwitch(
    icon: Icons.straighten,
    title: (l10n) => l10n.settingsShowSizes,
    subtitle: (l10n) => l10n.settingsShowSizesHelp,
    provider: browseShowSizesProvider,
    setting: AppSettings.browseShowSizes,
  ),
);

final highlightBigEntry = SettingsEntry(
  id: 'files.highlightBig',
  titleBuilder: (c) => c.l10n.settingsHighlightBig,
  subtitleBuilder: (c) => c.l10n.settingsHighlightBigLine,
  builder: (_) => BoolSettingSwitch(
    icon: Icons.priority_high,
    title: (l10n) => l10n.settingsHighlightBig,
    subtitle: (l10n) => l10n.settingsHighlightBigLine,
    provider: browseHighlightBigProvider,
    setting: AppSettings.browseHighlightBig,
  ),
);

final sameTimeWindowEntry = SettingsEntry(
  id: 'files.sameTimeWindow',
  titleBuilder: (c) => c.l10n.settingsSameTimeWindow,
  subtitleBuilder: (c) => c.l10n.settingsSameTimeWindowAbout,
  builder: (_) => const SameTimeWindowRow(),
);

/// B3: "taken within" for the same-time groups, any value 1 s … 24 h
/// (TASK-E2 §4).
class SameTimeWindowRow extends ConsumerWidget {
  const new({super.key});

  static const presets = [5, 60, 300, 3600];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final window = ref.watch(sameTimeWindowProvider).value ?? 5;
    return UnitInputRow.duration(
      icon: Icons.burst_mode_outlined,
      title: l10n.settingsSameTimeWindow,
      subtitle: l10n.sameTimeWindowLine(formatShortDuration(l10n, window)),
      value: window,
      presets: presets,
      format: (v) => formatShortDuration(l10n, v),
      onSaved: (v) => ref
          .read(settingsRepositoryProvider)
          .write(AppSettings.sameTimeWindowSeconds, v)
          .fireAndForget(),
    );
  }
}
