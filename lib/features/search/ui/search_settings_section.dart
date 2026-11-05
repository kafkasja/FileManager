import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/app_info.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/search/data/search_vocabulary.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';

/// Settings → General, under Language (B8, TASK-E2): "Smart search words
/// also in". The picker only appears once a second term file is bundled
/// (L2); the tip always.
final searchLanguageEntry = SettingsEntry(
  id: 'general.searchLanguage',
  titleBuilder: (c) => c.l10n.searchSettingsAlsoSearchIn,
  subtitleBuilder: (c) => c.l10n.searchSettingsAlsoSearchInHelp,
  builder: (_) => const SearchLanguageRows(),
);

class SearchLanguageRows extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final languages = ref.watch(availableSearchLanguagesProvider).value;
    final main = ref.watch(searchMainLanguageProvider).value;
    final secondary = ref.watch(searchSecondaryLanguageProvider).value ?? '';
    final showPicker =
        languages != null && languages.length > 1 && main != null;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.lightbulb_outline),
          subtitle: Text(l10n.searchSettingsTip),
        ),
        if (showPicker)
          ListTile(
            key: const ValueKey('searchSecondaryLanguage'),
            leading: const Icon(Icons.translate),
            title: Text(l10n.searchSettingsAlsoSearchIn),
            // The dropdown sits under the help text, full width: "English
            // (already included)" and longer translations don't fit as a
            // trailing widget on a small phone (L2).
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.searchSettingsAlsoSearchInHelp),
                DropdownButton<String>(
                  isExpanded: true,
                  // The main language counts as none; an unbundled stored value
                  // too (the dropdown needs its value among the items).
                  value: secondary != main && languages.contains(secondary)
                      ? secondary
                      : '',
                  onChanged: (v) {
                    if (v == null) return;
                    ref
                        .read(settingsRepositoryProvider)
                        .write(AppSettings.searchSecondaryLanguage, v)
                        .fireAndForget();
                  },
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(l10n.searchSettingsNone),
                    ),
                    for (final lang in languages)
                      DropdownMenuItem(
                        value: lang,
                        enabled: lang != main,
                        child: Text(
                          lang == main
                              ? l10n.searchSettingsAlreadyIncluded(_name(lang))
                              : _name(lang),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Shown in its own language.
  static String _name(String lang) => languageNames[lang] ?? lang;
}
