import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// The name the import preview shows for the allow-listed setting [name]
/// (`BackupSetting.name`); null for a key without a label (a test keeps
/// every backed-up setting labelled).
String? backupSettingLabelOrNull(AppLocalizations l10n, String name) {
  final labels = <String, String>{
    AppSettings.themeMode.name: l10n.backupSettingThemeMode,
    AppSettings.themeAccent.name: l10n.backupSettingThemeAccent,
    AppSettings.leftHanded.name: l10n.backupSettingLeftHanded,
    AppSettings.reduceMotion.name: l10n.backupSettingReduceMotion,
    AppSettings.highContrast.name: l10n.backupSettingHighContrast,
    AppSettings.textSize.name: l10n.backupSettingTextSize,
    AppSettings.localeTag.name: l10n.backupSettingLanguage,
    AppSettings.storageBigFileThresholdBytes.name:
        l10n.backupSettingBigFileThreshold,
    AppSettings.pendingFolderRetentionDays.name:
        l10n.backupSettingPendingRetention,
    AppSettings.sameTimeWindowSeconds.name: l10n.backupSettingSameTimeWindow,
    AppSettings.browseSortField.name: l10n.backupSettingBrowseSort,
    AppSettings.browseSortDescending.name:
        l10n.backupSettingBrowseSortDescending,
    AppSettings.browseShowSizes.name: l10n.backupSettingBrowseShowSizes,
    AppSettings.desktopBrowseLayout.name: l10n.backupSettingDesktopBrowseLayout,
    AppSettings.desktopBrowseSort.name: l10n.backupSettingDesktopBrowseSort,
    AppSettings.desktopIconStyle.name: l10n.backupSettingFileIcons,
    AppSettings.browseHighlightBig.name: l10n.backupSettingBrowseHighlightBig,
    AppSettings.searchSecondaryLanguage.name:
        l10n.backupSettingSearchSecondLanguage,
    AppSettings.swipeLayoutCurrent.name: l10n.backupSettingSwipeLayout,
    AppSettings.deleteMode.name: l10n.backupSettingDeleteMode,
    AppSettings.hapticsEnabled.name: l10n.backupSettingHaptics,
    AppSettings.swipeButtonsMode.name: l10n.backupSettingSwipeButtons,
    AppSettings.statsShowSessionSummary.name: l10n.backupSettingSessionSummary,
    AppSettings.basicIncludeReviewed.name:
        l10n.backupSettingBasicIncludeReviewed,
    AppSettings.showReviewedBadge.name: l10n.backupSettingReviewedBadge,
    AppSettings.activePresetId.name: l10n.backupSettingActivePreset,
    AppSettings.actionBarEnabled.name: l10n.backupSettingActionBar,
    AppSettings.foldersDropAction.name: l10n.backupSettingFoldersDropAction,
    AppSettings.similarEnabled.name: l10n.backupSettingSimilarEnabled,
    AppSettings.similarStrictness.name: l10n.backupSettingSimilarStrictness,
    AppSettings.similarBlurThreshold.name: l10n.backupSettingSimilarBlur,
    AppSettings.similarIncludeScreenshots.name:
        l10n.backupSettingSimilarScreenshots,
    AppSettings.aiModelsWifiOnly.name: l10n.backupSettingAiWifiOnly,
    AppSettings.privacyStripLocation.name: l10n.backupSettingStripLocation,
    AppSettings.cloudShowBadge.name: l10n.cloudShowBadge,
  };
  return labels[name];
}

/// [backupSettingLabelOrNull], never a raw key.
String backupSettingLabel(AppLocalizations l10n, String name) =>
    backupSettingLabelOrNull(l10n, name) ?? l10n.backupSettingOther;
