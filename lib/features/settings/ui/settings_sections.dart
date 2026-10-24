import 'package:flutter/foundation.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/settings/ui/about_section.dart';
import 'package:kfm/features/settings/ui/appearance_section.dart';
import 'package:kfm/features/settings/ui/developer_section.dart';
import 'package:kfm/features/settings/ui/permissions_section.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';
import 'package:kfm/features/settings/ui/storage_cache_section.dart';
import 'package:kfm/features/swipe/ui/swipe_settings_section.dart';
import 'package:kfm/features/trash/ui/deleting_section.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_sections.g.dart';

/// Every Settings section, sorted by [SettingsSection.order]. Add one line
/// per feature.
@Riverpod(keepAlive: true)
List<SettingsSection> settingsSections(Ref ref) => List.unmodifiable(
  <SettingsSection>[
    SettingsSection(
      order: 100,
      titleBuilder: (c) => c.l10n.settingsAppearance,
      builder: (_) => const AppearanceSection(),
    ),
    SettingsSection(
      order: 200,
      titleBuilder: (c) => c.l10n.settingsSwipe,
      builder: (_) => const SwipeSettingsSection(),
    ),
    SettingsSection(
      order: 300,
      titleBuilder: (c) => c.l10n.settingsDeleting,
      builder: (_) => const DeletingSection(),
    ),
    SettingsSection(
      order: 400,
      titleBuilder: (c) => c.l10n.settingsPermissions,
      builder: (_) => const PermissionsSection(),
    ),
    SettingsSection(
      order: 500,
      titleBuilder: (c) => c.l10n.settingsStorage,
      builder: (_) => const StorageCacheSection(),
    ),
    if (kDebugMode)
      SettingsSection(
        order: 990,
        titleBuilder: (c) => c.l10n.settingsDeveloper,
        builder: (_) => const DeveloperSection(),
      ),
    SettingsSection(
      order: 900,
      titleBuilder: (c) => c.l10n.settingsAbout,
      builder: (_) => const AboutSection(),
    ),
  ]..sort((a, b) => a.order.compareTo(b.order)),
);
