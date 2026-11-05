import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/search/domain/normalize.dart';
import 'package:kfm/features/settings/ui/settings_entry_view.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';

/// One settings search result (TASK-E2 §3).
@immutable
class SettingsSearchHit {
  const new(this.section, this.entry);

  final SettingsSection section;
  final SettingsEntry entry;
}

/// Whether every word of [query] occurs in [texts], case- and
/// diacritic-folded with B8's [normalizeSearchWord].
bool settingsTextMatches(String query, Iterable<String> texts) {
  final words = normalizeSearchWord(query)
      .split(' ')
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return false;
  final haystack = normalizeSearchWord(texts.join(' '));
  return words.every(haystack.contains);
}

/// The visible entries on [formFactor] whose title, description, keywords
/// or section title match [query], in screen order.
List<SettingsSearchHit> searchSettings(
  BuildContext context,
  WidgetRef ref,
  List<SettingsSection> sections,
  FormFactor formFactor,
  String query,
) => [
  for (final s in sections)
    for (final e in visibleEntries(ref, s, formFactor))
      if (settingsTextMatches(query, [
        e.titleBuilder(context),
        e.subtitleBuilder?.call(context) ?? '',
        (e.keywordsBuilder?.call(context) ?? '').replaceAll(',', ' '),
        s.title(context, formFactor),
      ]))
        SettingsSearchHit(s, e),
];

/// "Row title · Section" results, or the empty text.
class SettingsSearchResults extends StatelessWidget {
  const new({
    required this.hits,
    required this.formFactor,
    required this.onOpen,
    super.key,
  });

  final List<SettingsSearchHit> hits;
  final FormFactor formFactor;
  final ValueChanged<SettingsSearchHit> onOpen;

  @override
  Widget build(BuildContext context) {
    if (hits.isEmpty) {
      return Padding(
        padding: const EdgeInsetsDirectional.all(24),
        child: Text(
          context.l10n.settingsSearchEmpty,
          key: const ValueKey('settings-search-empty'),
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final hit in hits)
          ListTile(
            key: ValueKey('settings-hit-${hit.entry.id}'),
            leading: const Icon(Icons.subdirectory_arrow_right),
            title: Text(hit.entry.titleBuilder(context)),
            subtitle: Text(hit.section.title(context, formFactor)),
            onTap: () => onOpen(hit),
          ),
      ],
    );
  }
}
