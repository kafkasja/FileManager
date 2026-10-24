import 'package:kfm/core/db/settings/setting_key.dart';

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
