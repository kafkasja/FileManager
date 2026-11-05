import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/app_info.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/layout/adaptive_list_tile.dart';
import 'package:kfm/app/layout/segment_label.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/app/theme/theme_providers.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/settings/ui/accent_swatches.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Settings → General (TASK-E2): theme (F6), color (L1), language (F6).
final themeEntry = SettingsEntry(
  id: 'general.theme',
  titleBuilder: (c) => c.l10n.themeLabel,
  keywordsBuilder: (c) => c.l10n.settingsKeywordsTheme,
  selfExplanatory: true,
  builder: (_) => const ThemeRow(),
);

final accentEntry = SettingsEntry(
  id: 'general.accent',
  titleBuilder: (c) => c.l10n.themeColorLabel,
  keywordsBuilder: (c) => c.l10n.settingsKeywordsAccent,
  selfExplanatory: true,
  builder: (c) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ListTile(title: Text(c.l10n.themeColorLabel)),
      const AccentSwatches(),
    ],
  ),
);

final languageEntry = SettingsEntry(
  id: 'general.language',
  titleBuilder: (c) => c.l10n.languageLabel,
  // Every language's own name, so "Türkçe" finds the row in English too.
  keywordsBuilder: (_) => languageNames.values.join(','),
  selfExplanatory: true,
  builder: (_) => const LanguageRow(),
);

/// System / Light / Dark.
class ThemeRow extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final spacing = context.tokens.spacing;
    final compact = compactSegments(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(title: Text(l10n.themeLabel)),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: !compact,
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: SegmentLabel(l10n.themeSystem),
                icon: compact
                    ? null
                    : const Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: SegmentLabel(l10n.themeLight),
                icon: compact ? null : const Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: SegmentLabel(l10n.themeDark),
                icon: compact ? null : const Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) => settings
                .write(AppSettings.themeMode, s.single.name)
                .fireAndForget(),
          ),
        ),
      ],
    );
  }
}

/// The app language (System + every bundled one, in its own language).
class LanguageRow extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    final locale = ref.watch(appLocaleProvider).value;
    final tags = [
      for (final l in AppLocalizations.supportedLocales) l.toLanguageTag(),
    ];
    final current = locale?.toLanguageTag() ?? '';
    // L2: "Nederlands" at big text doesn't fit as a trailing dropdown.
    return AdaptiveListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.languageLabel),
      trailing: DropdownButton<String>(
        value: tags.contains(current) ? current : '',
        onChanged: (tag) {
          if (tag == null) return;
          settings.write(AppSettings.localeTag, tag).fireAndForget();
        },
        items: [
          DropdownMenuItem(value: '', child: Text(l10n.languageSystem)),
          for (final tag in tags)
            DropdownMenuItem(
              value: tag,
              child: Text(languageNames[tag] ?? tag),
            ),
        ],
      ),
    );
  }
}
