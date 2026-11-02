import 'package:flutter/foundation.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/ai_labels/ui/ai_labels_settings_section.dart';
import 'package:kfm/features/browse/ui/browse_settings_section.dart';
import 'package:kfm/features/connect/ui/connect_settings_section.dart';
import 'package:kfm/features/folders/ui/folders_settings_section.dart';
import 'package:kfm/features/privacy/ui/privacy_settings_section.dart';
import 'package:kfm/features/search/ui/search_settings_section.dart';
import 'package:kfm/features/settings/ui/about_section.dart';
import 'package:kfm/features/settings/ui/accessibility_section.dart';
import 'package:kfm/features/settings/ui/appearance_section.dart';
import 'package:kfm/features/settings/ui/developer_section.dart';
import 'package:kfm/features/settings/ui/permissions_section.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';
import 'package:kfm/features/settings/ui/storage_cache_section.dart';
import 'package:kfm/features/similar/ui/similar_section.dart';
import 'package:kfm/features/smart_groups/ui/smart_groups_settings_section.dart';
import 'package:kfm/features/storage/ui/storage_overview_section.dart';
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
      order: 150,
      titleBuilder: (c) => c.l10n.settingsAccessibility,
      builder: (_) => const AccessibilitySection(),
    ),
    SettingsSection(
      order: 200,
      titleBuilder: (c) => c.l10n.settingsSwipe,
      builder: (_) => const SwipeSettingsSection(),
    ),
    SettingsSection(
      order: 250,
      titleBuilder: (c) => c.l10n.settingsBrowse,
      builder: (_) => const BrowseSettingsSection(),
    ),
    SettingsSection(
      order: 260,
      titleBuilder: (c) => c.l10n.searchSettingsTitle,
      builder: (_) => const SearchSettingsSection(),
    ),
    SettingsSection(
      order: 300,
      titleBuilder: (c) => c.l10n.settingsDeleting,
      builder: (_) => const DeletingSection(),
    ),
    SettingsSection(
      order: 350,
      titleBuilder: (c) => c.l10n.settingsFiles,
      builder: (_) => const FoldersSettingsSection(),
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
    SettingsSection(
      order: 560,
      titleBuilder: (c) => c.l10n.similarTitle,
      builder: (_) => const SimilarSection(),
    ),
    SettingsSection(
      order: 550,
      titleBuilder: (c) => c.l10n.storageOverviewTitle,
      builder: (_) => const StorageOverviewSection(),
    ),
    SettingsSection(
      order: 600,
      titleBuilder: (c) => c.l10n.aiLabelsTitle,
      builder: (_) => const AiLabelsSettingsSection(),
    ),
    SettingsSection(
      order: 650,
      titleBuilder: (c) => c.l10n.groupsTitle,
      builder: (_) => const SmartGroupsSettingsSection(),
    ),
    // X2: next to the device-connect settings it applies to.
    SettingsSection(
      order: 690,
      titleBuilder: (c) => c.l10n.privacySectionTitle,
      builder: (_) => const PrivacySettingsSection(),
    ),
    // N1 planned order 600 ("after Storage"), but C3 took 600; 700 keeps
    // every existing section in place.
    SettingsSection(
      order: 700,
      titleBuilder: (c) => c.l10n.connectSettingsTitle,
      builder: (_) => const ConnectSettingsSection(),
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
