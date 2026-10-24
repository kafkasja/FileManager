import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/app_info.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/app/theme/theme_providers.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Theme mode + language (F6).
class AppearanceSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final locale = ref.watch(appLocaleProvider).value;
    final spacing = context.tokens.spacing;

    final tags = [
      for (final l in AppLocalizations.supportedLocales) l.toLanguageTag(),
    ];
    final current = locale?.toLanguageTag() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(title: Text(l10n.themeLabel)),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
          child: SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.themeSystem),
                icon: const Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.themeLight),
                icon: const Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.themeDark),
                icon: const Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) => settings
                .write(AppSettings.themeMode, s.single.name)
                .fireAndForget(),
          ),
        ),
        ListTile(
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
        ),
      ],
    );
  }
}
