import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';

/// Settings → Privacy & access (TASK-E2): what KFM never does, in plain
/// words, at the end of the section.
final privacyNeverEntry = SettingsEntry(
  id: 'privacy.never',
  titleBuilder: (c) => c.l10n.privacyNeverTitle,
  subtitleBuilder: (c) => c.l10n.privacyNeverBody,
  keywordsBuilder: (c) => c.l10n.settingsKeywordsPrivacy,
  builder: (c) => ListTile(
    leading: const Icon(Icons.shield_outlined),
    title: Text(c.l10n.privacyNeverTitle),
    subtitle: Text(c.l10n.privacyNeverBody),
  ),
);
