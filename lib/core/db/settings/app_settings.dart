import 'package:kfm/core/db/settings/setting_key.dart';
import 'package:kfm/core/files/file_query.dart';

/// The settings registry: one entry per setting, owner task in the comment.
abstract final class AppSettings {
  /// F6. 'system' | 'light' | 'dark'.
  static final SettingKey<String> themeMode = SettingKey.string(
    'themeMode',
    'system',
  );

  /// F6. '' = follow the system language.
  static final SettingKey<String> localeTag = SettingKey.string(
    'localeTag',
    '',
  );

  /// D4.
  static final SettingKey<int> pendingFolderRetentionDays = SettingKey.integer(
    'pendingRetentionDays',
    7,
  );

  /// H2. ISO-8601 UTC of the last background purge; '' = never ran.
  static final SettingKey<String> pendingLastPurgeAt = SettingKey.string(
    'pending.lastPurgeAt',
    '',
  );

  /// H2. FileOpFailure.name of the last automatic purge failure; '' = ok.
  static final SettingKey<String> pendingLastPurgeError = SettingKey.string(
    'pending.lastPurgeError',
    '',
  );

  /// B3.
  static final SettingKey<int> sameTimeWindowSeconds = SettingKey.integer(
    'sameTimeWindowSeconds',
    5,
  );

  /// F4. Set once the media permission dialog was shown; Android can't tell
  /// "never asked" from "denied" otherwise.
  static final SettingKey<bool> mediaPermissionAsked = SettingKey.boolean(
    'mediaPermissionAsked',
    defaultValue: false,
  );

  /// F5. ISO-8601 UTC of the last completed full scan; '' = never.
  static final SettingKey<String> indexLastFullScanAt = SettingKey.string(
    'indexLastFullScanAt',
    '',
  );

  /// F5. ISO-8601 UTC start of the last completed incremental scan.
  static final SettingKey<String> indexLastIncrementalAt = SettingKey.string(
    'indexLastIncrementalAt',
    '',
  );

  /// F5. Generation of the last committed full scan.
  static final SettingKey<int> indexGeneration = SettingKey.integer(
    'indexGeneration',
    0,
  );

  /// B1. A full scan with hidden files ran while All files access was on
  /// (reset when access is lost, so regaining it catches up once).
  static final SettingKey<bool> indexHiddenScanned = SettingKey.boolean(
    'index.hiddenScanned',
    defaultValue: false,
  );

  /// B2. Browse sort field (one sort for every folder and filter).
  static final SettingKey<FileSortField> browseSortField =
      SettingKey.enumeration(
        'browse.sort.field',
        FileSortField.date,
        FileSortField.values,
      );

  /// B2. Browse sort direction.
  static final SettingKey<bool> browseSortDescending = SettingKey.boolean(
    'browse.sort.descending',
    defaultValue: true,
  );

  /// Browse: a size label on every photo/video tile (user request
  /// 2026-10-29: sizes easy to see).
  static final SettingKey<bool> browseShowSizes = SettingKey.boolean(
    'browse.showSizes',
    defaultValue: true,
  );

  /// Browse: files of 100 MB or more get a highlighted size label.
  static final SettingKey<bool> browseHighlightBig = SettingKey.boolean(
    'browse.highlightBig',
    defaultValue: false,
  );

  /// Browse: the last searches (JSON list, `RecentSearchesRepository`).
  static final SettingKey<String> browseRecentSearches = SettingKey.string(
    'browse.recentSearches',
    '',
  );

  /// F5. Disk cap for the thumbnail cache.
  static final SettingKey<int> thumbCacheMaxMb = SettingKey.integer(
    'thumbCacheMaxMb',
    300,
  );

  /// SE1. The current SwipeLayout JSON ('' = SwipeLayout.basic). New
  /// sessions start with it; only SE3 "Reset action buttons" resets it.
  static final SettingKey<String> swipeLayoutCurrent = SettingKey.string(
    'swipe.layout.current',
    '',
  );

  /// D1. 'trash' | 'permanent' (parse with DeleteMode.parse).
  static final SettingKey<String> deleteMode = SettingKey.string(
    'delete.mode',
    'trash',
  );

  /// S4. Vibration on each swipe.
  static final SettingKey<bool> hapticsEnabled = SettingKey.boolean(
    'feedback.haptics',
    defaultValue: true,
  );

  /// P2. Last 5 move/copy target folders, newest first (JSON list).
  static final SettingKey<String> swipeRecentTargets = SettingKey.string(
    'swipe.recentTargets',
    '[]',
  );

  /// P9. A row of buttons under the swipe card.
  static final SettingKey<bool> swipeButtonsMode = SettingKey.boolean(
    'swipe.buttonsMode',
    defaultValue: false,
  );

  /// P8. Counters only include events after this (ISO-8601 UTC); '' = never.
  static final SettingKey<String> statsResetAt = SettingKey.string(
    'stats.resetAt',
    '',
  );

  /// P8. Summary sheet after Done.
  static final SettingKey<bool> statsShowSessionSummary = SettingKey.boolean(
    'stats.showSessionSummary',
    defaultValue: true,
  );

  /// P7. Basic mode also shows files already reviewed in Basic.
  static final SettingKey<bool> basicIncludeReviewed = SettingKey.boolean(
    'reviewed.basicInclude',
    defaultValue: true,
  );

  /// P7. Small "Reviewed" badge on swipe cards.
  static final SettingKey<bool> showReviewedBadge = SettingKey.boolean(
    'swipe.showReviewedBadge',
    defaultValue: true,
  );

  /// P6. The preset the swipe tab uses; 0 = Basic.
  static final SettingKey<int> activePresetId = SettingKey.integer(
    'presets.active',
    0,
  );

  /// P4. Extra action buttons under the card (off by default).
  static final SettingKey<bool> actionBarEnabled = SettingKey.boolean(
    'swipe.actionBar.enabled',
    defaultValue: false,
  );
}
