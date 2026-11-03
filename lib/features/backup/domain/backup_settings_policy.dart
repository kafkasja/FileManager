import 'dart:convert';

import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/setting_key.dart';
import 'package:meta/meta.dart';

/// How a backed-up setting is treated on import (TASK-X6).
enum BackupSettingKind {
  /// Copied as is.
  plain,

  /// SwipeLayout JSON: tag ids inside are remapped.
  layout,

  /// A preset id: remapped to the local preset.
  preset,
}

/// One allow-listed setting. Wraps the typed [SettingKey] so values are
/// checked against its decoder without exposing its type parameter.
@immutable
class BackupSetting {
  const new _(this.name, this.kind, this.defaultRaw, this._canonical);

  static BackupSetting of<T extends Object>(
    SettingKey<T> key, {
    BackupSettingKind kind = BackupSettingKind.plain,
  }) =>
      BackupSetting._(key.name, kind, key.encodeToDb(key.defaultValue), (json) {
        final value = key.decode(json);
        final raw = key.encodeToDb(value);
        // decode falls back to the default for wrong types: only a value that
        // survives the round trip unchanged is accepted.
        return raw == jsonEncode(json) ? raw : null;
      });

  final String name;
  final BackupSettingKind kind;

  /// The DB value of the default (a missing row reads as this).
  final String defaultRaw;
  final String? Function(Object? json) _canonical;

  /// The DB value for [json], or null when it isn't a valid value.
  String? canonical(Object? json) => _canonical(json);
}

/// Settings that move to another phone. Everything else is device state.
final List<BackupSetting> backupSettings = List.unmodifiable(<BackupSetting>[
  BackupSetting.of(AppSettings.themeMode),
  BackupSetting.of(AppSettings.themeAccent),
  BackupSetting.of(AppSettings.leftHanded),
  BackupSetting.of(AppSettings.textSize),
  BackupSetting.of(AppSettings.localeTag),
  BackupSetting.of(AppSettings.storageBigFileThresholdBytes),
  BackupSetting.of(AppSettings.pendingFolderRetentionDays),
  BackupSetting.of(AppSettings.sameTimeWindowSeconds),
  BackupSetting.of(AppSettings.browseSortField),
  BackupSetting.of(AppSettings.browseSortDescending),
  BackupSetting.of(AppSettings.browseShowSizes),
  BackupSetting.of(AppSettings.browseHighlightBig),
  BackupSetting.of(AppSettings.searchSecondaryLanguage),
  BackupSetting.of(
    AppSettings.swipeLayoutCurrent,
    kind: BackupSettingKind.layout,
  ),
  BackupSetting.of(AppSettings.deleteMode),
  BackupSetting.of(AppSettings.hapticsEnabled),
  BackupSetting.of(AppSettings.swipeButtonsMode),
  BackupSetting.of(AppSettings.statsShowSessionSummary),
  BackupSetting.of(AppSettings.basicIncludeReviewed),
  BackupSetting.of(AppSettings.showReviewedBadge),
  BackupSetting.of(AppSettings.activePresetId, kind: BackupSettingKind.preset),
  BackupSetting.of(AppSettings.actionBarEnabled),
  BackupSetting.of(AppSettings.foldersDropAction),
  BackupSetting.of(AppSettings.similarEnabled),
  BackupSetting.of(AppSettings.similarStrictness),
  BackupSetting.of(AppSettings.similarBlurThreshold),
  BackupSetting.of(AppSettings.similarIncludeScreenshots),
  BackupSetting.of(AppSettings.aiModelsWifiOnly),
  BackupSetting.of(AppSettings.privacyStripLocation),
  BackupSetting.of(AppSettings.cloudShowBadge),
]);

/// Never exported: device state, caches, grants, and network opt-ins that
/// must be chosen on each device (rule 7). The policy test fails when a new
/// `AppSettings` key is in neither list.
const Set<String> excludedBackupSettings = {
  'pending.lastPurgeAt',
  'pending.lastPurgeError',
  'connect.displayName',
  'selection.tipShown',
  'mediaPermissionAsked',
  'indexLastFullScanAt',
  'indexLastIncrementalAt',
  'sharePort',
  'indexGeneration',
  'index.hiddenScanned',
  'browse.recentSearches',
  'thumbCacheMaxMb',
  'swipe.recentTargets',
  'stats.resetAt',
  'similar.regroupNeeded',
  'smartGroups.onlinePlaceNames',
  'smartGroups.activated',
  'smartGroups.inputSignature',
  'aiLabels.enabled',
  'aiLabels.paused',
  'aiLabels.cardDismissed',
  'external.safGrants',
  // X3: a per-device note (cloud grants live in the DB, never exported).
  'cloud.gpsNoteDismissed',
  // X7: a network opt-in (chosen per device) and its cache.
  'updates.checkEnabled',
  'updates.lastCheckAt',
  'updates.dismissedVersion',
  'updates.latestJson',
  // L3: what this device's user has already seen.
  'onboarding.tutorialDone',
  'onboarding.seenHints',
  'onboarding.existingChecked',
};

final Map<String, BackupSetting> backupSettingsByName = Map.unmodifiable({
  for (final s in backupSettings) s.name: s,
});
