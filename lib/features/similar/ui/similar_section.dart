import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/layout/adaptive_list_tile.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/setting_key.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';
import 'package:kfm/features/similar/ui/similar_providers.dart';

/// Settings → Smart features (TASK-C2, E2): one entry with How alike and
/// screenshots inline.
final similarEntry = SettingsEntry(
  id: 'smart.similar',
  titleBuilder: (c) => c.l10n.similarSettingEnabled,
  subtitleBuilder: (c) => c.l10n.similarSettingEnabledHint,
  keywordsBuilder: (c) => c.l10n.settingsKeywordsSimilar,
  builder: (_) => const SimilarSection(),
);

/// Settings → Similar photos (TASK-C2): on/off, strictness, screenshots.
class SimilarSection extends ConsumerWidget {
  const new({super.key});

  static const strictnessValues = ['loose', 'normal', 'strict'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsRepositoryProvider);
    final enabled = ref.watch(similarEnabledProvider).value ?? false;
    final strictness =
        ref.watch(similarStrictnessProvider).value ??
        AppSettings.similarStrictness.defaultValue;
    final screenshots =
        ref.watch(similarIncludeScreenshotsProvider).value ?? false;

    Future<void> regroup<T extends Object>(SettingKey<T> key, T value) async {
      // The scan job sees the change, regroups and starts a run.
      await settings.write(key, value);
    }

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.burst_mode_outlined),
          title: Text(l10n.similarSettingEnabled),
          subtitle: Text(l10n.similarSettingEnabledHint),
          value: enabled,
          onChanged: (v) =>
              settings.write(AppSettings.similarEnabled, v).fireAndForget(),
        ),
        if (enabled) ...[
          AdaptiveListTile(
            title: Text(l10n.similarSettingStrictness),
            trailing: DropdownButton<String>(
              value: strictnessValues.contains(strictness) ? strictness : null,
              onChanged: (v) {
                if (v != null) {
                  regroup(AppSettings.similarStrictness, v).fireAndForget();
                }
              },
              items: [
                for (final s in strictnessValues)
                  DropdownMenuItem(
                    value: s,
                    child: Text(switch (s) {
                      'loose' => l10n.similarStrictnessLoose,
                      'strict' => l10n.similarStrictnessStrict,
                      _ => l10n.similarStrictnessNormal,
                    }),
                  ),
              ],
            ),
          ),
          SwitchListTile(
            title: Text(l10n.similarSettingScreenshots),
            value: screenshots,
            onChanged: (v) => regroup(
              AppSettings.similarIncludeScreenshots,
              v,
            ).fireAndForget(),
          ),
        ],
      ],
    );
  }
}
