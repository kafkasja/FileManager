// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kaf\'s File Manager';

  @override
  String get appTitleShort => 'KFM';

  @override
  String get tabSwipe => 'Swipe';

  @override
  String get tabBrowse => 'Browse';

  @override
  String get tabTrash => 'Trash';

  @override
  String get tabSettings => 'Settings';

  @override
  String get browsePlaceholder => 'Browsing is coming soon.';

  @override
  String get dbWriteError => 'Couldn\'t save your last change.';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get retry => 'Try again';

  @override
  String indexingCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Indexing $countString files…',
      one: 'Indexing 1 file…',
    );
    return '$_temp0';
  }

  @override
  String get indexingPaused => 'Indexing paused';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get settingsAbout => 'About';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutPromise =>
      'No ads, no account, no tracking. Everything stays on your device.';

  @override
  String get permGateTitle => 'Let KFM see your photos and videos';

  @override
  String get permGateWhy =>
      'Everything stays on your phone. No account, no upload.';

  @override
  String get permAllow => 'Allow';

  @override
  String get permOpenSettings => 'Open settings';

  @override
  String get permPermanentlyDeniedHelp =>
      'Photo access is turned off. In settings, open Permissions and allow Photos and videos.';

  @override
  String get permCheckFailed => 'Couldn\'t check the permissions.';

  @override
  String get limitedBanner => 'KFM can only see some photos.';

  @override
  String get limitedAllowAll => 'Allow all';

  @override
  String get allFilesSheetText =>
      'To show documents and downloads too, turn on All files access.';

  @override
  String get allFilesTurnOn => 'Turn on';

  @override
  String get notNow => 'Not now';

  @override
  String get settingsPermissions => 'Permissions';

  @override
  String get permRowMedia => 'Photos and videos';

  @override
  String get permRowAllFiles => 'All files access';

  @override
  String get permRowMediaManagement => 'Skip confirmation dialogs';

  @override
  String get permRowMediaManagementHelp =>
      'Optional. Lets KFM move and delete photos without asking each time (Media management).';

  @override
  String get permStatusGranted => 'Allowed';

  @override
  String get permStatusLimited => 'Some photos only';

  @override
  String get permStatusDenied => 'Not allowed';

  @override
  String get permStatusNotAsked => 'Not asked yet';

  @override
  String get permStatusNotRequired => 'Not needed on this phone';

  @override
  String get permChange => 'Change';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get thumbCacheTitle => 'Thumbnail cache';

  @override
  String get thumbCacheSizeUnknown => 'Size unknown';

  @override
  String get thumbCacheClear => 'Clear';

  @override
  String get settingsDeveloper => 'Developer';

  @override
  String devIndexedFiles(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString files in the index',
      one: '1 file in the index',
    );
    return '$_temp0';
  }

  @override
  String get devRescan => 'Full rescan';

  @override
  String get devIndexList => 'Show indexed files';

  @override
  String get swipeAllDone =>
      'All done! You\'ve gone through every photo and video.';

  @override
  String get swipeEmptyLibrary => 'No photos or videos found.';

  @override
  String get swipeLookingForPhotos => 'Looking for photos…';

  @override
  String get swipeErrorGeneric => 'Couldn\'t load your photos.';

  @override
  String get swipeDone => 'Done';

  @override
  String get swipeFinishTitle => 'Finish this session?';

  @override
  String get swipeFinishConfirm => 'Finish';

  @override
  String get cancel => 'Cancel';

  @override
  String get undo => 'Undo';

  @override
  String get undoHistoryTitle => 'Recent actions';

  @override
  String get undoRestored => 'Restored from the trash';

  @override
  String get undoPermanentlyDeleted =>
      'This file was permanently deleted and can\'t come back.';

  @override
  String get undoFailed => 'Couldn\'t undo this step.';

  @override
  String get undoNotPossibleYet => 'Undoing this isn\'t possible yet.';

  @override
  String get deleteBatchRetry => 'Retry';

  @override
  String get deleteCommitFailed =>
      'Couldn\'t delete files right now. They stay queued and nothing is lost.';

  @override
  String swipeProgress(int swiped, int remaining) {
    final intl.NumberFormat swipedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String swipedString = swipedNumberFormat.format(swiped);
    final intl.NumberFormat remainingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String remainingString = remainingNumberFormat.format(remaining);

    return '$swipedString done · $remainingString left';
  }

  @override
  String swipeFinishTrash(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString files will be moved to the trash.',
      one: '1 file will be moved to the trash.',
      zero: 'Nothing is waiting to be deleted.',
    );
    return '$_temp0';
  }

  @override
  String swipeFinishPermanent(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString files will be deleted permanently.',
      one: '1 file will be deleted permanently.',
      zero: 'Nothing is waiting to be deleted.',
    );
    return '$_temp0';
  }

  @override
  String sessionSummary(int count, String size) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Session finished: $countString files deleted, $size freed.',
      one: 'Session finished: 1 file deleted, $size freed.',
      zero: 'Session finished.',
    );
    return '$_temp0';
  }

  @override
  String deleteBatchWaiting(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString files waiting to be deleted',
      one: '1 file waiting to be deleted',
    );
    return '$_temp0';
  }

  @override
  String deleteBatchFailed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString files couldn\'t be deleted',
      one: '1 file couldn\'t be deleted',
    );
    return '$_temp0';
  }

  @override
  String get settingsDeleting => 'Deleting';

  @override
  String get deleteModeTrash => 'Move to trash (recommended)';

  @override
  String get deleteModeTrashHelp =>
      'Swiped files go to the phone\'s trash and can be restored.';

  @override
  String get deleteModePermanent => 'Delete permanently';

  @override
  String get deleteModePermanentHelp =>
      'Swiped files are deleted for good. No recovery.';

  @override
  String get deleteModePermanentWarning =>
      'Files deleted this way can\'t be restored, not even with undo.';

  @override
  String get deleteModeNextSession => 'Applies to your next session.';

  @override
  String get pendingRetentionLabel => 'Keep pending files for';

  @override
  String get pendingRetentionHelp =>
      'Documents and other files (and photos on Android 10 and older) wait in a hidden folder before they are deleted for good.';

  @override
  String get pendingEmptyNow => 'Empty pending folder now';

  @override
  String get pendingEmptyTitle => 'Delete everything in the pending folder?';

  @override
  String get pendingEmptyBody => 'These files can\'t be restored afterwards.';

  @override
  String get pendingEmptyConfirm => 'Delete';

  @override
  String get permanentConfirmTitle => 'Delete permanently this session?';

  @override
  String get permanentConfirmBody =>
      'Files you swipe to trash will be deleted forever. They can\'t be restored.';

  @override
  String get permanentConfirmYes => 'Delete permanently';

  @override
  String get permanentConfirmUseTrash => 'Use trash instead';

  @override
  String pendingRetentionDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String pendingEmptied(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString files deleted.',
      one: '1 file deleted.',
      zero: 'The pending folder is empty.',
    );
    return '$_temp0';
  }

  @override
  String get trashSystem => 'System trash';

  @override
  String get trashPending => 'Pending delete';

  @override
  String get trashNothingHere => 'Nothing here';

  @override
  String get trashExpiresToday => 'Expires today';

  @override
  String get trashSelect => 'Select';

  @override
  String get trashRestore => 'Restore';

  @override
  String get trashDeleteForever => 'Delete forever';

  @override
  String get trashDeleteForeverBody => 'This can\'t be undone.';

  @override
  String get trashEmptySection => 'Empty this section';

  @override
  String get trashCancelled => 'Cancelled';

  @override
  String get trashAlreadyRemoved => 'Some items were already removed.';

  @override
  String get trashSystemHelp =>
      'Photos and videos are kept by Android for 30 days. Your gallery app may also have its own bin.';

  @override
  String get trashLoadFailed => 'Couldn\'t load the trash.';

  @override
  String get trashNeedsPermission =>
      'Allow access to photos and videos to see the trash.';

  @override
  String trashDaysLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String trashDeleteForeverTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $countString items forever?',
      one: 'Delete 1 item forever?',
    );
    return '$_temp0';
  }

  @override
  String trashRestored(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString items restored',
      one: '1 item restored',
    );
    return '$_temp0';
  }

  @override
  String trashSelectedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String trashSectionSummary(int count, String size) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString items',
      one: '1 item',
    );
    return '$_temp0 · $size';
  }

  @override
  String get labelTrash => '→ Trash';

  @override
  String get labelDelete => '→ Delete';

  @override
  String get labelKept => '→ Kept';

  @override
  String get labelFavorite => '★ Favorite';

  @override
  String get labelRenameBatch => '→ Rename batch';

  @override
  String get settingsSwipe => 'Swiping';

  @override
  String get settingsHaptics => 'Vibration';

  @override
  String get settingsHapticsHelp => 'A short vibration when a swipe is done.';

  @override
  String labelMovedTo(String folder) {
    return '→ $folder';
  }

  @override
  String labelCopiedTo(String folder) {
    return '⧉ $folder';
  }

  @override
  String labelTagged(String tag) {
    return '# $tag';
  }

  @override
  String labelSentTo(String device) {
    return '→ $device';
  }

  @override
  String get restoredSnack => 'Continued where you left off';

  @override
  String get restoredStartFresh => 'Start fresh';

  @override
  String get clearMenu => 'Clear…';

  @override
  String get clearResetLayout => 'Reset action buttons';

  @override
  String get clearResetLayoutHelp => 'Back to: left = trash, right = keep';

  @override
  String get clearNewSession => 'Start a new session';

  @override
  String get clearNewSessionHelp =>
      'Ends the progress and undo history of this session.';

  @override
  String get clearConfirm => 'Clear';

  @override
  String get layoutResetDone => 'Action buttons reset';

  @override
  String get undoAction => 'Undo';

  @override
  String get newSessionFailed =>
      'Couldn\'t finish the deletes, so this session continues. Try again.';

  @override
  String get settingsFreshStart => 'Clear / fresh start…';

  @override
  String newFilesChip(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString new photos · Show',
      one: '1 new photo · Show',
    );
    return '$_temp0';
  }

  @override
  String clearNewSessionDeletes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString waiting deletes will be done.',
      one: '1 waiting delete will be done.',
      zero: 'Nothing is waiting to be deleted.',
    );
    return '$_temp0';
  }

  @override
  String get viewerClose => 'Close';

  @override
  String get videoCantPlay => 'Can\'t play this video';

  @override
  String get videoTapForSound => 'Tap for sound';

  @override
  String get videoOpenFullscreen => 'Open fullscreen';
}
