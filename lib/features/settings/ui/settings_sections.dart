import 'package:flutter/foundation.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/ai_labels/ui/ai_labels_settings_section.dart';
import 'package:kfm/features/backup/ui/backup_section.dart';
import 'package:kfm/features/browse/ui/browse_settings_section.dart';
import 'package:kfm/features/cloud/ui/cloud_settings_section.dart';
import 'package:kfm/features/connect/ui/connect_settings_section.dart';
import 'package:kfm/features/folders/ui/folders_settings_section.dart';
import 'package:kfm/features/privacy/ui/privacy_settings_section.dart';
import 'package:kfm/features/search/ui/search_settings_section.dart';
import 'package:kfm/features/settings/ui/about_advanced_entries.dart';
import 'package:kfm/features/settings/ui/accessibility_entries.dart';
import 'package:kfm/features/settings/ui/developer_section.dart';
import 'package:kfm/features/settings/ui/general_entries.dart';
import 'package:kfm/features/settings/ui/permissions_section.dart';
import 'package:kfm/features/settings/ui/privacy_entries.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';
import 'package:kfm/features/settings/ui/storage_cleanup_entries.dart';
import 'package:kfm/features/settings/ui/windows_roots_section.dart';
import 'package:kfm/features/similar/ui/similar_section.dart';
import 'package:kfm/features/smart_groups/ui/smart_groups_settings_section.dart';
import 'package:kfm/features/storage/ui/storage_overview_section.dart';
import 'package:kfm/features/swipe/ui/swipe_settings_section.dart';
import 'package:kfm/features/trash/ui/deleting_section.dart';
import 'package:kfm/features/updates/ui/updates_section.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_sections.g.dart';

/// The 9 Settings sections (TASK-E2 §2), sorted by [SettingsSection.order].
/// Features own their [SettingsEntry]s; add an entry to its section here.
/// Rules (`settings_structure_test.dart`, per form factor): ≥ 2 entries per
/// shown section, unique ids, a description unless self-explanatory, no
/// phone-only rows on desktop.
@Riverpod(keepAlive: true)
List<SettingsSection> settingsSections(Ref ref) => List.unmodifiable(
  <SettingsSection>[
    SettingsSection(
      order: 100,
      id: 'general',
      titleBuilder: (c) => c.l10n.settingsGeneral,
      entries: [
        themeEntry,
        accentEntry,
        // TODO(E3): `general.fileIcons` ("File icons: Windows / KFM", desktop
        // only) goes here; E3 owns the key, the dialog and the entry.
        languageEntry,
        searchLanguageEntry,
        updatesEntry,
        updatesNowEntry,
        tutorialEntry,
      ],
    ),
    SettingsSection(
      order: 200,
      id: 'swipe',
      titleBuilder: (c) => c.l10n.settingsSwipe,
      desktopTitleBuilder: (c) => c.l10n.settingsSorting,
      entries: [
        swipeCustomizeEntry,
        swipeButtonsModeEntry,
        // TODO(E4): `swipe.showFolder` ("Show the file's folder", phone) goes
        // here; E4 builds the setting and the entry.
        swipePresetsEntry,
        swipeReviewedBadgeEntry,
        swipeSessionSummaryEntry,
        swipeStatsEntry,
        swipeResetReviewedEntry,
        swipeFreshStartEntry,
      ],
    ),
    SettingsSection(
      order: 300,
      id: 'files',
      titleBuilder: (c) => c.l10n.settingsFilesDisplay,
      entries: [
        showSizesEntry,
        highlightBigEntry,
        bigFileThresholdEntry,
        sameTimeWindowEntry,
        dropActionEntry,
        cloudDestinationsEntry,
        cloudBadgeEntry,
      ],
    ),
    SettingsSection(
      order: 400,
      id: 'smart',
      titleBuilder: (c) => c.l10n.settingsSmart,
      entries: [similarEntry, aiLabelsEntry, placeNamesEntry],
    ),
    SettingsSection(
      order: 500,
      id: 'storage',
      titleBuilder: (c) => c.l10n.settingsStorageCleanup,
      entries: [deleteModeEntry, retentionEntry, thumbCacheEntry],
    ),
    SettingsSection(
      order: 600,
      id: 'connect',
      titleBuilder: (c) => c.l10n.settingsConnectSharing,
      entries: [
        connectEntry,
        // TODO(E1): `connect.receiveFolder` goes here.
        rememberedDevicesEntry,
        transfersEntry,
        stopSharingOnCloseEntry,
        resetIdentityEntry,
      ],
    ),
    SettingsSection(
      order: 700,
      id: 'privacy',
      titleBuilder: (c) => c.l10n.settingsPrivacyAccess,
      entries: [
        // E2 §6: Look everywhere (Windows) / Android's index explained.
        whereKfmLooksEntry,
        permissionsEntry,
        stripLocationEntry,
        privacyDevicesEntry,
        privacyNeverEntry,
      ],
    ),
    SettingsSection(
      order: 800,
      id: 'a11y',
      titleBuilder: (c) => c.l10n.settingsAccessibility,
      entries: [
        textSizeEntry,
        leftHandedEntry,
        hapticsEntry,
        screenReaderEntry,
      ],
    ),
    SettingsSection(
      order: 900,
      id: 'about',
      titleBuilder: (c) => c.l10n.settingsAboutAdvanced,
      entries: [
        versionEntry,
        promiseEntry,
        licencesEntry,
        backupEntry,
        errorLogEntry,
        if (kDebugMode) developerEntry,
      ],
    ),
  ]..sort((a, b) => a.order.compareTo(b.order)),
);
