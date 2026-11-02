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
      other: 'Session finished: $countString files deleted ($size).',
      one: 'Session finished: 1 file deleted ($size).',
      zero: 'Session finished.',
    );
    return '$_temp0';
  }

  @override
  String sessionSummaryTrash(int count, String size) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Session finished: $countString files moved to the trash ($size).',
      one: 'Session finished: 1 file moved to the trash ($size).',
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

  @override
  String get customizeSwipes => 'Customize swipes';

  @override
  String get customizeSwipesHelp => 'Choose what each swipe direction does';

  @override
  String get customizeSwipesIntro =>
      'Tap an arrow to change what swiping that way does.';

  @override
  String get swipeDirectionLeft => 'Swipe left';

  @override
  String get swipeDirectionRight => 'Swipe right';

  @override
  String get swipeDirectionUp => 'Swipe up';

  @override
  String get swipeDirectionDown => 'Swipe down';

  @override
  String get swipeActionNothing => 'Nothing';

  @override
  String get swipeActionTrash => 'Move to trash';

  @override
  String get swipeActionDelete => 'Delete permanently';

  @override
  String get swipeActionKeep => 'Keep';

  @override
  String get swipeActionNeedOne => 'At least one direction needs an action';

  @override
  String get swipeLayoutReset => 'Reset to basic';

  @override
  String get swipeLayoutResetTitle => 'Reset swipes?';

  @override
  String get swipeLayoutResetBody =>
      'Left goes back to trash and right to keep. Up and down will do nothing.';

  @override
  String get reset => 'Reset';

  @override
  String get swipeActionMoveTo => 'Move to folder…';

  @override
  String get swipeActionCopyTo => 'Copy to folder…';

  @override
  String get swipeActionAddTag => 'Add tag…';

  @override
  String get swipeActionFavorite => 'Add to favorites';

  @override
  String swipeActionMoveToNamed(String folder) {
    return 'Move to $folder';
  }

  @override
  String swipeActionCopyToNamed(String folder) {
    return 'Copy to $folder';
  }

  @override
  String swipeActionTagNamed(String tag) {
    return 'Tag: $tag';
  }

  @override
  String get swipeActionTagMissing => 'Tag no longer exists';

  @override
  String get moveConsentNotice => 'Android may ask before each move';

  @override
  String get turnOn => 'Turn on';

  @override
  String get folderPickerTitle => 'Choose a folder';

  @override
  String get folderPickerRecent => 'Recent';

  @override
  String get folderPickerWithPhotos => 'Folders with photos';

  @override
  String get folderPickerNew => 'New folder…';

  @override
  String get folderPickerNewTitle => 'New folder';

  @override
  String folderPickerNewIn(String folder) {
    return 'Inside $folder';
  }

  @override
  String get folderNameHint => 'Folder name';

  @override
  String get folderNameInvalid => 'That name can\'t be used';

  @override
  String get folderNeedsAllFiles => 'Needs All files access';

  @override
  String folderFileCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get create => 'Create';

  @override
  String get tagPickerTitle => 'Choose a tag';

  @override
  String get tagPickerNew => 'New tag…';

  @override
  String get tagNewTitle => 'New tag';

  @override
  String get tagNameHint => 'Tag name';

  @override
  String get tagNameTaken => 'A tag with this name already exists';

  @override
  String get tagNameInvalid => 'Use 1 to 40 characters';

  @override
  String get tagsEmpty => 'No tags yet';

  @override
  String get swipeProblemTagMissing =>
      'Tag no longer exists. Change it in Customize swipes.';

  @override
  String get swipeProblemUnsupported => 'This swipe can\'t be used yet';

  @override
  String get fileOpFolderMissing =>
      'Folder not found. Pick it again in Customize swipes.';

  @override
  String get fileOpDeclined => 'Not moved: permission declined';

  @override
  String get fileOpNoSpace => 'Not enough space';

  @override
  String get fileOpNeedsAllFiles => 'This folder needs All files access';

  @override
  String fileOpMoveFailed(String name) {
    return 'Couldn\'t move $name';
  }

  @override
  String fileOpCopyFailed(String name) {
    return 'Couldn\'t copy $name';
  }

  @override
  String get undoneLabel => '↩ Undone';

  @override
  String get swipeActionRenameBatch => 'Add to rename batch';

  @override
  String renamePill(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '✎ $countString';
  }

  @override
  String get renameTitle => 'Rename batch';

  @override
  String get renamePatternLabel => 'Name pattern';

  @override
  String renamePatternHint(String n) {
    return 'holiday_$n';
  }

  @override
  String get renameStart => 'Start at';

  @override
  String get renamePadding => 'Digits';

  @override
  String renameTokensHelp(String n, String date, String orig) {
    return '$n = number · $date = date · $orig = original name';
  }

  @override
  String get renameMissing => 'Missing or changed: skipped';

  @override
  String renameCollision(String name) {
    return 'Name was taken: \"$name\" is used instead';
  }

  @override
  String get renameApply => 'Rename';

  @override
  String get renameDiscard => 'Discard batch';

  @override
  String get renameDiscardTitle => 'Discard this rename batch?';

  @override
  String get renameDiscardBody =>
      'The files stay as they are; only the batch is dropped.';

  @override
  String get renameErrorEmpty => 'Type a name pattern';

  @override
  String get renameErrorInvalid =>
      'These characters can\'t be used: / \\ : * ? \" < > |';

  @override
  String renameErrorNeedsCounter(String n) {
    return 'Add $n so every file gets its own number';
  }

  @override
  String get renameErrorTooLong => 'The names would be too long';

  @override
  String get renameRunning => 'Renaming…';

  @override
  String renameDone(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Renamed $countString files',
      one: 'Renamed 1 file',
    );
    return '$_temp0';
  }

  @override
  String renameDoneSkipped(int renamed, int skipped) {
    final intl.NumberFormat renamedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String renamedString = renamedNumberFormat.format(renamed);
    final intl.NumberFormat skippedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String skippedString = skippedNumberFormat.format(skipped);

    return 'Renamed $renamedString · skipped $skippedString';
  }

  @override
  String get renameDeclined => 'Nothing renamed: permission declined';

  @override
  String get renameNoUndoAfterDone => 'You can undo this until you tap Done.';

  @override
  String renameBeforeFinishTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rename $countString files first?',
      one: 'Rename 1 file first?',
    );
    return '$_temp0';
  }

  @override
  String get renameBeforeFinishBody =>
      'Your rename batch hasn\'t been applied yet. Discarding it keeps the current names.';

  @override
  String get renameOpen => 'Rename…';

  @override
  String get labelRenameApplied => '✎ Renamed batch';

  @override
  String clearRenameDropped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString files in the rename batch will be dropped',
      one: '1 file in the rename batch will be dropped',
    );
    return '$_temp0';
  }

  @override
  String get barTrash => 'Trash';

  @override
  String get barDelete => 'Delete';

  @override
  String get barKeep => 'Keep';

  @override
  String get barFavorite => 'Favorite';

  @override
  String get barRename => 'Rename';

  @override
  String get actionBarTitle => 'Action bar';

  @override
  String get actionBarHelp => 'Extra buttons under the card';

  @override
  String get actionBarAdd => 'Add action';

  @override
  String get actionBarEmpty => 'No buttons yet';

  @override
  String get actionBarRemove => 'Remove';

  @override
  String get actionBarFull => 'Up to 8 buttons';

  @override
  String get filterTitle => 'Filter';

  @override
  String get filterButton => 'Filter';

  @override
  String get filterKinds => 'Show';

  @override
  String get filterPhotos => 'Photos';

  @override
  String get filterVideos => 'Videos';

  @override
  String get filterScreenshotsOnly => 'Screenshots only';

  @override
  String get filterDate => 'Date';

  @override
  String get filterAny => 'Any';

  @override
  String get filterThisMonth => 'This month';

  @override
  String get filterLast30Days => 'Last 30 days';

  @override
  String get filterCustomRange => 'Pick dates…';

  @override
  String filterRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get filterSize => 'Size';

  @override
  String filterOverMb(int mb) {
    final intl.NumberFormat mbNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String mbString = mbNumberFormat.format(mb);

    return 'Over $mbString MB';
  }

  @override
  String get filterFolders => 'Folders';

  @override
  String filterFolderCount(String folder, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$folder ($countString)';
  }

  @override
  String filterFolderMissing(String folder) {
    return '$folder (missing)';
  }

  @override
  String get filterTags => 'Tags';

  @override
  String get filterTagged => 'Tagged';

  @override
  String get filterUntagged => 'Untagged';

  @override
  String get filterSpecificTags => 'Specific…';

  @override
  String get filterFavoritesOnly => 'Favorites only';

  @override
  String filterMatches(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString files match',
      one: '1 file matches',
      zero: 'No files match',
    );
    return '$_temp0';
  }

  @override
  String get filterApply => 'Apply';

  @override
  String get filterProblemSize => 'The minimum size is larger than the maximum';

  @override
  String get filterProblemTags => 'Pick at least one tag';

  @override
  String get filterProblemDate => 'The start date is after the end date';

  @override
  String get filterNoMatches => 'No files match this filter';

  @override
  String get filterAllDone => 'All matching files done';

  @override
  String get filterChange => 'Change filter';

  @override
  String get presetBasic => 'Basic';

  @override
  String get presetChipTooltip => 'Switch preset';

  @override
  String get presetSheetTitle => 'Presets';

  @override
  String get presetManage => 'Manage presets';

  @override
  String get presetSaveAs => 'Save as preset…';

  @override
  String get presetNameLabel => 'Preset name';

  @override
  String get presetIncludeFilter => 'Include the current filter';

  @override
  String presetSaved(String name) {
    return 'Saved “$name”';
  }

  @override
  String get presetNameTaken => 'A preset with this name already exists';

  @override
  String get presetNameInvalid => 'Use 1 to 40 characters';

  @override
  String get presetRename => 'Rename';

  @override
  String get presetEdit => 'Edit';

  @override
  String get presetDuplicate => 'Duplicate';

  @override
  String get presetDelete => 'Delete';

  @override
  String presetDeleteConfirm(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get presetDeleteBody =>
      'Its unfinished session ends. Your files aren\'t touched.';

  @override
  String get presetLoadError => 'Can\'t load: edit or delete';

  @override
  String presetNoSessionHint(String name) {
    return 'Start swiping in $name to change the buttons for that session, or edit the preset in Manage presets.';
  }

  @override
  String get presetEditorTitle => 'Edit preset';

  @override
  String get presetDirections => 'Swipe buttons';

  @override
  String get presetFilter => 'Filter';

  @override
  String get presetEditorFilterNone => 'No filter';

  @override
  String get presetEditorFilterOn => 'Filter set';

  @override
  String get presetEditorSave => 'Save';

  @override
  String get presetEditorReplacesSession =>
      'Also replaces the setup of this preset\'s unfinished session';

  @override
  String get presetEditorDiscard => 'Discard your changes?';

  @override
  String get presetDiscard => 'Discard';

  @override
  String presetSwitchBlocked(String name) {
    return 'Couldn\'t finish the deletes, so you\'re still on $name. Try again.';
  }

  @override
  String get presetEmptyTitle => 'No presets yet';

  @override
  String get presetEmptyBody =>
      'A preset saves your swipe buttons and, if you like, a filter. Switch between them with one tap.';

  @override
  String get presetEmptyQuickCleanup => 'Quick cleanup';

  @override
  String get presetEmptyQuickCleanupHelp =>
      'Left = trash, right = keep, screenshots only';

  @override
  String get presetEmptySortHoliday => 'Sort holiday';

  @override
  String get presetEmptySortHolidayHelp =>
      'Left = trash, right = move to a folder, up = favorite';

  @override
  String get presetCreate => 'Create';

  @override
  String get presetNew => 'New preset';

  @override
  String get settingsPresets => 'Presets';

  @override
  String get settingsPresetsHelp => 'Saved swipe setups';

  @override
  String get reviewedBadge => 'Reviewed';

  @override
  String get settingsShowReviewedBadge => 'Show reviewed badge';

  @override
  String get settingsShowReviewedBadgeHelp =>
      'A small mark on files you already swiped before';

  @override
  String get reviewedIncludeToggle => 'Include files already reviewed here';

  @override
  String get filterReviewed => 'Reviewed';

  @override
  String get filterReviewedOnly => 'Reviewed';

  @override
  String get filterNotReviewed => 'Not reviewed';

  @override
  String reviewedInfoLine(String preset, String action, String date) {
    return 'Reviewed in $preset · $action · $date';
  }

  @override
  String get reviewedReset => 'Reset reviewed labels…';

  @override
  String get reviewedResetAll => 'All presets';

  @override
  String reviewedResetConfirm(String name) {
    return 'Reset reviewed labels for $name? This can\'t be undone.';
  }

  @override
  String reviewedResetCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString files',
      one: '1 file',
      zero: 'No files',
    );
    return '$_temp0';
  }

  @override
  String get reviewedResetDone => 'Reviewed labels reset';

  @override
  String get presetIncludeReviewed =>
      'Include files already reviewed in this preset';

  @override
  String get settingsStats => 'Swipe stats';

  @override
  String get settingsStatsHelp => 'Files reviewed and space freed';

  @override
  String get settingsShowSessionSummary => 'Show summary after Done';

  @override
  String get statsTitle => 'Swipe stats';

  @override
  String statsInTrashFreed(String inTrash, String freed) {
    return '$inTrash in trash · $freed freed';
  }

  @override
  String get statsGoToTrash => 'Go to Trash';

  @override
  String get statsThisWeek => 'This week';

  @override
  String get statsThisMonth => 'This month';

  @override
  String get statsAllTime => 'All time';

  @override
  String statsReviewed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString files reviewed',
      one: '1 file reviewed',
    );
    return '$_temp0';
  }

  @override
  String statsFreed(String size) {
    return '$size freed';
  }

  @override
  String statsRowLine(String reviewed, String freed) {
    return '$reviewed · $freed';
  }

  @override
  String get statsByPreset => 'By preset';

  @override
  String get statsDeletedPresets => 'Deleted presets';

  @override
  String get statsWeekly => 'Last 8 weeks';

  @override
  String get statsReset => 'Reset stats';

  @override
  String get statsResetConfirm =>
      'Reset the reviewed and freed counters? Files in the trash stay counted.';

  @override
  String get summaryTitle => 'Session finished';

  @override
  String summaryReviewed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You reviewed $countString files',
      one: 'You reviewed 1 file',
    );
    return '$_temp0';
  }

  @override
  String summaryToTrash(String size) {
    return '$size moved to the trash';
  }

  @override
  String summaryFreed(String size) {
    return '$size freed';
  }

  @override
  String get ok => 'OK';

  @override
  String get settingsSwipeButtons => 'Use buttons instead of swiping';

  @override
  String get settingsSwipeButtonsHelp =>
      'Tap buttons to do what each swipe does';

  @override
  String swipeCardSemantics(
    String kind,
    String name,
    String size,
    String date,
  ) {
    return '$kind, $name, $size, $date';
  }

  @override
  String get fileKindPhoto => 'Photo';

  @override
  String get fileKindVideo => 'Video';

  @override
  String swipeButtonSemantics(String action, String direction) {
    return '$action, $direction';
  }

  @override
  String get pendingRetentionCustom => 'Custom…';

  @override
  String get pendingRetentionCustomTitle => 'Keep pending files for';

  @override
  String get pendingRetentionCustomHelper => '1–90 days';

  @override
  String get pendingRetentionCustomError => 'Enter a number from 1 to 90';

  @override
  String get pendingRetentionCustomSave => 'Save';

  @override
  String get pendingPurgeFailedPermission =>
      'Automatic cleanup couldn\'t run: permission needed';

  @override
  String get pendingPurgeFailed => 'Automatic cleanup couldn\'t run';

  @override
  String pendingUnavailableSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count files couldn\'t be moved to the pending-delete folder. They\'re still on your device.',
      one: '1 file couldn\'t be moved to the pending-delete folder. It\'s still on your device.',
    );
    return '$_temp0';
  }

  @override
  String pendingUnavailableBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count files weren\'t deleted: the pending-delete folder can\'t be used',
      one: '1 file wasn\'t deleted: the pending-delete folder can\'t be used',
    );
    return '$_temp0';
  }

  @override
  String get pendingUnavailableOptions => 'Options';

  @override
  String pendingUnavailableAfterDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files weren\'t deleted. Find them in Trash.',
      one: '1 file wasn\'t deleted. Find it in Trash.',
    );
    return '$_temp0';
  }

  @override
  String get pendingUnavailableTitle =>
      'Couldn\'t move to the pending-delete folder';

  @override
  String get pendingUnavailableBody =>
      'KFM can\'t put these files in its pending-delete folder, so they weren\'t deleted.';

  @override
  String get pendingUnavailableGrantAccess =>
      'Allow All files access so KFM can use the folder';

  @override
  String get pendingUnavailableWarning =>
      'Deleting permanently can\'t be undone. These files won\'t go to the trash and can\'t be restored.';

  @override
  String get pendingUnavailableKeep => 'Keep';

  @override
  String get pendingUnavailableDeleteOne => 'Delete permanently';

  @override
  String pendingUnavailableDeleteAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete all $count permanently',
      one: 'Delete 1 file permanently',
    );
    return '$_temp0';
  }

  @override
  String pendingUnavailableConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count files permanently?',
      one: 'Delete this file permanently?',
    );
    return '$_temp0 This can\'t be undone.';
  }

  @override
  String get pendingUnavailableConfirmButton => 'Delete permanently';

  @override
  String pendingUnavailableDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files deleted permanently',
      one: '1 file deleted permanently',
    );
    return '$_temp0';
  }

  @override
  String get pendingUnavailableSection =>
      'Couldn\'t move to the pending folder';

  @override
  String get trashSort => 'Sort';

  @override
  String get trashSortExpiry => 'Expiring soonest';

  @override
  String get trashSortNewest => 'Newest deleted';

  @override
  String get swipeEmptyLibraryHint =>
      'If your phone has photos, KFM may not be allowed to see them. Check KFM\'s permissions in your phone\'s settings.';

  @override
  String get browseKindAll => 'All';

  @override
  String get browseKindImages => 'Images';

  @override
  String get browseKindVideos => 'Videos';

  @override
  String get browseKindAudio => 'Audio';

  @override
  String get browseKindDocuments => 'Documents';

  @override
  String get browseKindArchives => 'Archives';

  @override
  String get browseKindOther => 'Other';

  @override
  String get browseSourceCamera => 'Camera';

  @override
  String get browseSourceScreenshots => 'Screenshots';

  @override
  String get browseSourceWhatsapp => 'WhatsApp';

  @override
  String get browseSourceSnapchat => 'Snapchat';

  @override
  String get browseSourceDownloads => 'Downloads';

  @override
  String get browseSourceVideos => 'Videos';

  @override
  String get browseSourcePanoramas => 'Panoramas';

  @override
  String get browseSourceScreenRecordings => 'Screen recordings';

  @override
  String get browseSourceExpertRaw => 'Expert RAW';

  @override
  String get browseSourceGifs => 'GIFs';

  @override
  String get browseSourceCollages => 'Collages';

  @override
  String get browseSourceClippedImages => 'Clipped images';

  @override
  String get browseSourceLiveMessages => 'Live messages';

  @override
  String get browseSourceVideoCaptures => 'Video captures';

  @override
  String get browseSourceTelegram => 'Telegram';

  @override
  String get browseSourceInstagram => 'Instagram';

  @override
  String get browseSourceOther => 'Other apps';

  @override
  String get browseSourceHidden => 'Hidden';

  @override
  String get browsePanoramaHint => 'Best guess: wide photos and PANO files';

  @override
  String get browseModeAll => 'All files';

  @override
  String get browseModeFolders => 'Folders';

  @override
  String get browseShowHidden => 'Show hidden files';

  @override
  String get browseSwipeThese => 'Swipe these';

  @override
  String get browseNeedsAllFiles =>
      'Grant access to see documents, downloads and hidden files';

  @override
  String get browseGrantAccess => 'Grant access';

  @override
  String get browseEmpty => 'No files here';

  @override
  String searchKwType(String name) {
    return 'Type: $name';
  }

  @override
  String searchKwSource(String name) {
    return 'Source: $name';
  }

  @override
  String get searchKwHidden => 'Hidden files';

  @override
  String get searchKwTiny => 'Tiny (< 10 KB)';

  @override
  String get searchKwLarge => 'Large (> 100 MB)';

  @override
  String get searchKwToday => 'Today';

  @override
  String get searchKwWeek => 'Last 7 days';

  @override
  String searchTermsLoadError(String language) {
    return 'Search words for $language couldn\'t be loaded';
  }

  @override
  String get searchSettingsTitle => 'Search';

  @override
  String get searchSettingsAlsoSearchIn => 'Also search in';

  @override
  String get searchSettingsAlsoSearchInHelp =>
      'Smart words like \'video\' or \'cloud\' also work in this language.';

  @override
  String get searchSettingsNone => 'None';

  @override
  String searchSettingsAlreadyIncluded(String language) {
    return '$language (already included)';
  }

  @override
  String get searchSettingsTip =>
      'Type words like \'video\', \'pdf\', \'whatsapp\', \'hidden\' or \'large\' to filter. Tap ✕ on a chip to search the name instead.';

  @override
  String get searchOpen => 'Search';

  @override
  String get searchHint => 'Search files';

  @override
  String get searchClearText => 'Clear search';

  @override
  String get searchChipType => 'Type';

  @override
  String searchChipTypes(int count) {
    return '$count types';
  }

  @override
  String get searchChipSource => 'Source';

  @override
  String get searchChipDate => 'Date';

  @override
  String get searchDateToday => 'Today';

  @override
  String get searchDateWeek => 'Last 7 days';

  @override
  String get searchDateMonth => 'This month';

  @override
  String get searchDateYear => 'This year';

  @override
  String get searchDateCustom => 'Custom…';

  @override
  String searchDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String searchDateSince(String from) {
    return 'Since $from';
  }

  @override
  String get searchChipSize => 'Size';

  @override
  String searchSizeOver(String size) {
    return '> $size';
  }

  @override
  String searchSizeUnder(String size) {
    return '< $size';
  }

  @override
  String get searchSizeTiny => 'Tiny (< 10 KB)';

  @override
  String searchSizeBetween(String min, String max) {
    return '$min – $max';
  }

  @override
  String get searchSizeCustom => 'Custom…';

  @override
  String get searchSizeCustomTitle => 'File size';

  @override
  String get searchSizeMinLabel => 'At least (MB)';

  @override
  String get searchSizeMaxLabel => 'At most (MB)';

  @override
  String get searchSizeInvalid =>
      'The minimum can\'t be larger than the maximum';

  @override
  String get searchChipHidden => 'Hidden files';

  @override
  String get searchHiddenInclude => 'Include hidden files';

  @override
  String get searchHiddenOnly => 'Only hidden files';

  @override
  String searchOnlyIn(String folder) {
    return 'Only in $folder';
  }

  @override
  String searchTokenExtension(String ext) {
    return 'Type: .$ext';
  }

  @override
  String searchTokenAsName(String word) {
    return 'Search names for “$word” instead';
  }

  @override
  String get searchRecent => 'Recent searches';

  @override
  String get searchSuggestions => 'Try';

  @override
  String get searchSuggestLarge => 'Large files';

  @override
  String get searchSuggestDownloads => 'Downloads';

  @override
  String get searchSuggestPdfs => 'PDFs';

  @override
  String get searchSuggestHidden => 'Hidden files';

  @override
  String get searchSuggestWeek => 'This week';

  @override
  String get searchNoMatch => 'No files match';

  @override
  String get searchClearFilters => 'Clear filters';

  @override
  String searchWordsLoadError(String languages) {
    return 'Search words for $languages couldn\'t be loaded';
  }

  @override
  String get searchDone => 'Done';

  @override
  String get browseLoadError => 'Couldn\'t load the files.';

  @override
  String get browseOtherHint =>
      'Files from other apps and folders, grouped by folder';

  @override
  String get browseInternalStorage => 'Internal storage';

  @override
  String browseExternalVolume(String name) {
    return 'SD card or USB ($name)';
  }

  @override
  String browseFileCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get browseStorageRoot => 'Storage';

  @override
  String get browseFolderMenu => 'Folder options';

  @override
  String get openWith => 'Open with';

  @override
  String get openWithNone => 'No app can open this file';

  @override
  String get openWithFailed => 'Couldn\'t open this file.';

  @override
  String get textViewerTruncated => 'Showing the first 1 MB';

  @override
  String get textViewerLatin1 => 'Shown as Latin-1 (not UTF-8)';

  @override
  String get textViewerBinary => 'This doesn\'t look like a text file';

  @override
  String get textViewerError => 'Couldn\'t read this file.';

  @override
  String get browseSortTitle => 'Sort by';

  @override
  String get browseSortDate => 'Date';

  @override
  String get browseSortSize => 'Size';

  @override
  String get browseSortName => 'Name';

  @override
  String get browseSortNewestFirst => 'Newest first';

  @override
  String get browseSortOldestFirst => 'Oldest first';

  @override
  String get browseSortLargestFirst => 'Largest first';

  @override
  String get browseSortSmallestFirst => 'Smallest first';

  @override
  String get browseSortNameAsc => 'A–Z';

  @override
  String get browseSortNameDesc => 'Z–A';

  @override
  String get browseRecent => 'Recent search';

  @override
  String get settingsBrowse => 'Browse';

  @override
  String get settingsShowSizes => 'Show file sizes';

  @override
  String get settingsShowSizesHelp => 'A size label on every photo and video';

  @override
  String get settingsHighlightBig => 'Highlight big files';

  @override
  String get settingsHighlightBigHelp =>
      'Files of 100 MB or more get a red size label';

  @override
  String selectionCount(int count, String size) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString selected · $size',
      one: '1 selected · $size',
    );
    return '$_temp0';
  }

  @override
  String selectionCleared(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Selection cleared ($countString files)',
      one: 'Selection cleared (1 file)',
    );
    return '$_temp0';
  }

  @override
  String clearSelectionRow(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Clear selection ($countString files)',
      one: 'Clear selection (1 file)',
    );
    return '$_temp0';
  }

  @override
  String selectionAdded(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $countString files',
      one: 'Added 1 file',
      zero: 'Nothing new to add',
    );
    return '$_temp0';
  }

  @override
  String selectionViewTitle(int count) {
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
  String get selectionEnter => 'Select';

  @override
  String get selectionExit => 'Leave select mode';

  @override
  String get selectionEditTitle => 'Edit selection';

  @override
  String get selectionHint => 'Tap to add · Long-press and drag to add many';

  @override
  String get selectionEditHint => 'Tap selected files to remove them';

  @override
  String get selectionSelectAll => 'Select all';

  @override
  String get selectionClearAll => 'Clear all';

  @override
  String get selectionView => 'View selected';

  @override
  String get selectionRestore => 'Restore last selection';

  @override
  String get selectionDone => 'Done';

  @override
  String get selectionRemoved => 'Removed from selection';

  @override
  String get selectionTip =>
      'Already selected. To remove files, use Edit selection.';

  @override
  String get selectionMore => 'More';

  @override
  String get selectionPreview => 'Preview selected';

  @override
  String get previewOpen => 'Preview';

  @override
  String get previewSelect => 'Select';

  @override
  String get previewSelected => 'Selected';

  @override
  String get previewRemove => 'Remove from selection';

  @override
  String get previewPlay => 'Play';

  @override
  String get previewDetails => 'Details';

  @override
  String get previewFileGone => 'This file no longer exists';

  @override
  String get previewHeicUnsupported =>
      'Can\'t preview HEIC on this Android version';

  @override
  String previewDimensions(int width, int height) {
    return '$width × $height';
  }

  @override
  String previewTaken(String date) {
    return 'Taken $date';
  }

  @override
  String previewModified(String date) {
    return 'Modified $date';
  }

  @override
  String get browseModeSameTime => 'Same time';

  @override
  String get sameTimeEmpty => 'No photos taken at the same time';

  @override
  String sameTimeDayHeader(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groups',
      one: '1 group',
    );
    return '$date · $_temp0';
  }

  @override
  String sameTimeGroupTitle(int count, String start, String end) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0 · $start–$end';
  }

  @override
  String sameTimeMore(int count) {
    return '+$count more';
  }

  @override
  String get sameTimeSelectGroup => 'Select group';

  @override
  String get settingsSameTimeWindow => 'Same time window';

  @override
  String get settingsSameTimeWindowHelp =>
      'Browse → Same time groups photos and videos taken within this many seconds';

  @override
  String seconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String get fileMenuTooltip => 'File actions';

  @override
  String get fileMenuRename => 'Rename';

  @override
  String get fileMenuDuplicate => 'Duplicate';

  @override
  String get fileMenuCopyTo => 'Copy to…';

  @override
  String get fileMenuMoveTo => 'Move to…';

  @override
  String get fileMenuDelete => 'Delete';

  @override
  String get selectionActionMove => 'Move to…';

  @override
  String get selectionActionCopy => 'Copy to…';

  @override
  String get selectionActionDuplicate => 'Duplicate';

  @override
  String get selectionActionDelete => 'Delete';

  @override
  String get renameFolderTitle => 'Rename folder';

  @override
  String get renameAction => 'Rename';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameInvalid =>
      'Names can\'t be empty, contain / \\ : * ? \" < > | or be longer than 255 bytes';

  @override
  String get nameExists => 'Something with that name already exists here';

  @override
  String opMovedSummary(int done, String folder) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'Moved $done files to $folder',
      one: 'Moved 1 file to $folder',
    );
    return '$_temp0';
  }

  @override
  String opCopiedSummary(int done, String folder) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'Copied $done files to $folder',
      one: 'Copied 1 file to $folder',
    );
    return '$_temp0';
  }

  @override
  String opDuplicatedSummary(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'Duplicated $done files',
      one: 'Duplicated 1 file',
    );
    return '$_temp0';
  }

  @override
  String opRenamedSummary(String name) {
    return 'Renamed to $name';
  }

  @override
  String opTrashedSummary(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'Moved $done files to trash',
      one: 'Moved 1 file to trash',
    );
    return '$_temp0';
  }

  @override
  String opDeletedSummary(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'Deleted $done files permanently',
      one: 'Deleted 1 file permanently',
    );
    return '$_temp0';
  }

  @override
  String opFailedSummary(int failed) {
    String _temp0 = intl.Intl.pluralLogic(
      failed,
      locale: localeName,
      other: '$failed failed',
      one: '1 failed',
    );
    return '$_temp0';
  }

  @override
  String opSkippedSummary(int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped skipped',
      one: '1 skipped',
    );
    return '$_temp0';
  }

  @override
  String opCancelledSummary(int done, int total) {
    return 'Stopped: $done of $total done';
  }

  @override
  String opSkippedNeedAccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files skipped (need All files access)',
      one: '1 file skipped (needs All files access)',
    );
    return '$_temp0';
  }

  @override
  String get opUndone => 'Undone';

  @override
  String opUndoStopped(int done, int total) {
    return 'Undo stopped: $done of $total undone';
  }

  @override
  String get opUndoLast => 'Undo last file operation';

  @override
  String opUndoMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files no longer exist and weren\'t undone',
      one: '1 file no longer exists and wasn\'t undone',
    );
    return '$_temp0';
  }

  @override
  String opSpaceRefused(String needed, String free) {
    return 'Not enough space (needs $needed, $free free)';
  }

  @override
  String opFolderRenamed(String name) {
    return 'Folder renamed to $name';
  }

  @override
  String get collisionTitle => 'Name already used';

  @override
  String collisionBody(String name, String folder) {
    return '$name already exists in $folder';
  }

  @override
  String get collisionReplace => 'Replace';

  @override
  String get collisionKeepBoth => 'Keep both';

  @override
  String get collisionSkip => 'Skip';

  @override
  String get collisionApplyAll => 'Do this for all remaining';

  @override
  String progressMoving(int done, int total) {
    return 'Moving $done of $total';
  }

  @override
  String progressCopying(int done, int total) {
    return 'Copying $done of $total';
  }

  @override
  String progressDeleting(int done, int total) {
    return 'Deleting $done of $total';
  }

  @override
  String progressUndoing(int done, int total) {
    return 'Undoing $done of $total';
  }

  @override
  String get progressWorking => 'Working…';

  @override
  String get permanentConfirmAction => 'Delete';

  @override
  String get opPermanentConfirmTitle => 'Delete permanently?';

  @override
  String opPermanentConfirmBody(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Permanently delete $count files ($size)? This can\'t be undone.',
      one: 'Permanently delete 1 file ($size)? This can\'t be undone.',
    );
    return '$_temp0';
  }

  @override
  String get pendingFallbackTitle => 'Couldn\'t use the trash folder';

  @override
  String pendingFallbackBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Couldn\'t move $count files to the trash folder. Delete them permanently instead?',
      one: 'Couldn\'t move 1 file to the trash folder. Delete it permanently instead?',
    );
    return '$_temp0';
  }

  @override
  String get pendingFallbackAction => 'Delete permanently';

  @override
  String get pickerMoveTitle => 'Move to';

  @override
  String get pickerCopyTitle => 'Copy to';

  @override
  String get pickerAllFolders => 'All folders';

  @override
  String get pickerMoveHere => 'Move here';

  @override
  String get pickerCopyHere => 'Copy here';

  @override
  String get pickerChooseHere => 'Use this folder';

  @override
  String get pickerCurrentFolder => 'Current folder';

  @override
  String get browseNewFolder => 'New folder';

  @override
  String browseFolderCreated(String name) {
    return 'Created $name';
  }

  @override
  String get settingsFiles => 'Files';

  @override
  String get settingsDropAction => 'Dropping files on a folder';

  @override
  String get dropActionMove => 'Moves them';

  @override
  String get dropActionCopy => 'Copies them';

  @override
  String fileOpRenameFailed(String name) {
    return 'Couldn\'t rename $name';
  }

  @override
  String fileOpFailedGeneric(String name) {
    return 'Couldn\'t finish for $name';
  }

  @override
  String fileOpNotFound(String name) {
    return '$name no longer exists';
  }

  @override
  String fileOpPermission(String name) {
    return 'No permission to change $name';
  }

  @override
  String progressCompressing(String done, String total) {
    return 'Zipping $done of $total';
  }

  @override
  String progressExtracting(String done, String total) {
    return 'Extracting $done of $total';
  }

  @override
  String progressEtaMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'About $minutes minutes left',
      one: 'About 1 minute left',
    );
    return '$_temp0';
  }

  @override
  String get archiveCompress => 'Compress';

  @override
  String get archiveViewContents => 'View contents';

  @override
  String get archiveExtractHere => 'Extract here';

  @override
  String get archiveExtractTo => 'Extract to…';

  @override
  String get archiveExtractThis => 'Extract this';

  @override
  String get archiveExtractToTitle => 'Extract to';

  @override
  String get archiveCompressTitle => 'Compress to zip';

  @override
  String get archiveCompressAction => 'Compress';

  @override
  String archiveSaveIn(String folder) {
    return 'Saved in $folder';
  }

  @override
  String get archiveSaveTo => 'Save to…';

  @override
  String get archiveSaveToTitle => 'Save zip in';

  @override
  String get archiveWrongPlace => 'Can\'t zip files from this place yet';

  @override
  String archiveCreated(String name) {
    return 'Created $name';
  }

  @override
  String archiveExtracted(int count, String folder) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Extracted $count files to $folder',
      one: 'Extracted 1 file to $folder',
      zero: 'Nothing to extract',
    );
    return '$_temp0';
  }

  @override
  String get archiveBombTitle => 'Very large archive';

  @override
  String archiveBombBody(String size) {
    return 'This archive expands to $size. Extract anyway?';
  }

  @override
  String get archiveBombAction => 'Extract anyway';

  @override
  String get archiveUnsafePaths =>
      'This archive contains unsafe paths and was not extracted';

  @override
  String get archiveCorrupt => 'This zip is damaged or not a zip file';

  @override
  String get archiveCancelled => 'Stopped. Nothing was saved';

  @override
  String archiveIoError(String name) {
    return 'Couldn\'t read or write $name';
  }

  @override
  String get archivePasswordTitle => 'Password needed';

  @override
  String archivePasswordBody(String name) {
    return '$name is protected with a password';
  }

  @override
  String get archivePasswordLabel => 'Password';

  @override
  String get archivePasswordAction => 'Extract';

  @override
  String get archiveWrongPassword => 'Wrong password, try again';

  @override
  String get archivePasswordShow => 'Show password';

  @override
  String get archivePasswordHide => 'Hide password';

  @override
  String archiveSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items · $size',
      one: '1 item · $size',
    );
    return '$_temp0';
  }

  @override
  String get archiveEmpty => 'This zip is empty';

  @override
  String get archiveWrongDestination =>
      'Can\'t save to this place yet. Pick a folder on internal storage';

  @override
  String archiveReplaceFailed(String name) {
    return 'The old zip was kept. The new one is saved as $name';
  }

  @override
  String get collectionsOpen => 'Tags & favorites';

  @override
  String get collectionsTitle => 'Tags & favorites';

  @override
  String get collectionsFavorites => 'Favorites';

  @override
  String get collectionsTags => 'Tags';

  @override
  String get collectionsEmpty =>
      'No tags yet. Tag files from Browse, or set a swipe direction to “Add tag” in swipe settings.';

  @override
  String collectionsFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
      zero: 'No files',
    );
    return '$_temp0';
  }

  @override
  String get collectionsTagMenu => 'Tag options';

  @override
  String get tagMenuEdit => 'Rename or change color';

  @override
  String get tagMenuDelete => 'Delete tag';

  @override
  String get tagEditTitle => 'Edit tag';

  @override
  String get tagSave => 'Save';

  @override
  String tagDeleteTitle(String name) {
    return 'Delete tag “$name”?';
  }

  @override
  String tagDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The $count files stay; only the tag is removed.',
      one: 'The file stays; only the tag is removed.',
      zero: 'No files have this tag.',
    );
    return '$_temp0';
  }

  @override
  String tagDeleteUsedIn(String places) {
    return 'Used in: $places. That direction will show “Tag no longer exists” until you pick another.';
  }

  @override
  String get tagUsedCurrentSetup => 'current swipe setup';

  @override
  String get tagDeleteConfirm => 'Delete';

  @override
  String tagDeleted(String name) {
    return 'Tag “$name” deleted';
  }

  @override
  String get tagGone => 'This tag was deleted';

  @override
  String get fileMenuFavoriteAdd => 'Add to favorites';

  @override
  String get fileMenuFavoriteRemove => 'Remove from favorites';

  @override
  String get fileMenuTags => 'Tags…';

  @override
  String get selectionTagsMenu => 'Tags & favorites…';

  @override
  String get selectionTagAdd => 'Add tag…';

  @override
  String get selectionTagRemove => 'Remove tag…';

  @override
  String get tagRemoveTitle => 'Remove a tag';

  @override
  String get tagRemoveNone => 'None of these files have tags';

  @override
  String get fileTagsTitle => 'Tags';

  @override
  String tagAddedSummary(int count, String tag) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tagged $count files “$tag”',
      one: 'Tagged 1 file “$tag”',
      zero: 'All files already had “$tag”',
    );
    return '$_temp0';
  }

  @override
  String tagRemovedSummary(int count, String tag) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removed “$tag” from $count files',
      one: 'Removed “$tag” from 1 file',
      zero: 'No file had “$tag”',
    );
    return '$_temp0';
  }

  @override
  String favoriteAddedSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count files to favorites',
      one: 'Added 1 file to favorites',
      zero: 'Already in favorites',
    );
    return '$_temp0';
  }

  @override
  String favoriteRemovedSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removed $count files from favorites',
      one: 'Removed 1 file from favorites',
      zero: 'Not in favorites',
    );
    return '$_temp0';
  }

  @override
  String get tagWriteError => 'Couldn\'t save the change. Try again';

  @override
  String get swipeSourceSelectionTitle => 'Selected files';

  @override
  String get sameTimeSwipeGroup => 'Swipe this group';

  @override
  String get swipeSourceClose => 'Back to all files';

  @override
  String swipeSourceGroupPosition(
    int group,
    int groupCount,
    int index,
    int groupSize,
  ) {
    return 'Group $group of $groupCount · $index/$groupSize';
  }

  @override
  String swipeSourceDone(String title) {
    return 'All done in $title';
  }

  @override
  String get swipeSourceBackToMain => 'Back to swiping';

  @override
  String swipeSourceBackToOrigin(String origin) {
    return 'Back to $origin';
  }

  @override
  String swipeSourceRestored(String title) {
    return 'Continued in $title';
  }

  @override
  String swipeSourcePendingLine(String title) {
    return 'Opens: $title';
  }

  @override
  String swipeSourceSkipped(int files, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: 'Swiping $files files',
      one: 'Swiping 1 file',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped can\'t be swiped here',
      one: '1 can\'t be swiped here',
    );
    return '$_temp0 · $_temp1 (photos and videos only)';
  }

  @override
  String get swipeSourceTruncated => 'Showing the first 10,000 files';

  @override
  String get swipeSourceEmpty => 'Nothing to swipe here';

  @override
  String get swipeSourceNoMedia => 'Only photos and videos can be swiped';

  @override
  String get swipeSourceInvalidFilter => 'This filter can\'t be used';

  @override
  String get swipeSourceNoMatches => 'No photos or videos match';

  @override
  String get swipeSourceOriginStorage => 'Storage overview';

  @override
  String get swipeSourceOriginSimilar => 'Similar photos';

  @override
  String get swipeSourceOriginSearch => 'Search';

  @override
  String get swipeSourceOriginGroups => 'Groups';

  @override
  String get swipeSourceOriginSameTime => 'Same time';

  @override
  String get swipeSourceOriginBrowse => 'Browse';

  @override
  String get swipeSourceOriginSharedIn => 'Shared files';

  @override
  String get swipeSourceOriginCloud => 'Cloud';

  @override
  String get swipeSourceOriginExternal => 'External storage';

  @override
  String get swipeSourceOriginOther => 'Previous screen';

  @override
  String get storageOverviewTitle => 'Storage overview';

  @override
  String storageUsedFree(String used, String free) {
    return '$used used · $free free';
  }

  @override
  String get storageSpaceUnknown => 'Free space unknown';

  @override
  String get storageScanning => 'Still scanning… the numbers keep growing';

  @override
  String get storageCatVideos => 'Videos';

  @override
  String get storageCatScreenshots => 'Screenshots';

  @override
  String storageCatBigFiles(String size) {
    return 'Big files (over $size)';
  }

  @override
  String get storageCatWhatsapp => 'WhatsApp';

  @override
  String get storageCatDownloads => 'Downloads';

  @override
  String storageCategorySummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files · $size',
      one: '1 file · $size',
      zero: 'No files',
    );
    return '$_temp0';
  }

  @override
  String get storageCleanUp => 'Clean up';

  @override
  String get storageCleanUpMediaOnly => 'Clean up shows photos and videos only';

  @override
  String get storageNeedsAccess =>
      'Turn on All files access to see these files';

  @override
  String get storageOverlapNote => 'A file can be in more than one category.';

  @override
  String get storageBiggestFiles => 'Biggest files';

  @override
  String get storageWhatsappHint =>
      'Includes WhatsApp\'s hidden Sent and Status folders';

  @override
  String get storageBigFileThreshold => 'Big files start at';

  @override
  String get similarTitle => 'Similar photos';

  @override
  String get similarSourceTitle => 'Similar photos';

  @override
  String get similarStorageHint => 'Look-alike and blurry photos';

  @override
  String get similarTabSimilar => 'Similar';

  @override
  String get similarTabBlurry => 'Blurry';

  @override
  String get similarStartTitle => 'Find similar and blurry photos';

  @override
  String get similarStartBody =>
      'KFM checks your photos on this phone, groups look-alikes and suggests the sharpest one to keep. Nothing leaves the phone and nothing is removed unless you choose it.';

  @override
  String get similarStart => 'Start';

  @override
  String similarChecking(int done, int total) {
    return 'Checking photos… $done of $total';
  }

  @override
  String get similarGrouping => 'Grouping look-alike photos…';

  @override
  String get similarNoGroups => 'No similar photos found yet';

  @override
  String get similarNoBlurry => 'No blurry photos found';

  @override
  String similarGroupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get similarBest => 'Best';

  @override
  String get similarKeepBest => 'Keep best, remove others';

  @override
  String get similarSwipeGroup => 'Swipe this group';

  @override
  String get similarSwipeAll => 'Swipe all groups';

  @override
  String get similarCleanDuplicates => 'Clean duplicates';

  @override
  String similarRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removed $count photos',
      one: 'Removed 1 photo',
    );
    return '$_temp0';
  }

  @override
  String get similarKeptAll => 'Kept all photos';

  @override
  String get similarBlurryHint => 'Tap to pick, long-press to view';

  @override
  String similarRemoveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remove $count',
      zero: 'Remove',
    );
    return '$_temp0';
  }

  @override
  String similarCleanProgress(int group, int total, int keep) {
    return 'Group $group of $total · keeping $keep';
  }

  @override
  String get similarCleanDone => 'All groups done';

  @override
  String get similarSkip => 'Skip';

  @override
  String get similarNextGroup => 'Next group';

  @override
  String get similarKeep => 'Keep';

  @override
  String get similarRemove => 'Remove';

  @override
  String get similarSettingEnabled => 'Find similar and blurry photos';

  @override
  String get similarSettingEnabledHint =>
      'Checks photos in the background while KFM is open';

  @override
  String get similarSettingStrictness => 'How alike';

  @override
  String get similarStrictnessLoose => 'Loosely alike';

  @override
  String get similarStrictnessNormal => 'Normal';

  @override
  String get similarStrictnessStrict => 'Nearly identical';

  @override
  String get similarSettingScreenshots => 'Include screenshots';

  @override
  String get groupsTitle => 'Groups';

  @override
  String get groupsScreenshots => 'Screenshots';

  @override
  String get groupsSelfies => 'Selfies (automatic)';

  @override
  String get groupsDocuments => 'Documents';

  @override
  String get groupsTrips => 'Trips';

  @override
  String get groupsPlaces => 'Places';

  @override
  String smartGroupPlace(int n) {
    return 'Place $n';
  }

  @override
  String smartGroupTrip(DateTime start, DateTime end) {
    final intl.DateFormat startDateFormat = intl.DateFormat.yMMMd(localeName);
    final String startString = startDateFormat.format(start);
    final intl.DateFormat endDateFormat = intl.DateFormat.yMMMd(localeName);
    final String endString = endDateFormat.format(end);

    return '$startString – $endString';
  }

  @override
  String groupsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String groupsProgress(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Finding trips and places… $done of $total photos',
      one: 'Finding trips and places… $done of 1 photo',
    );
    return '$_temp0';
  }

  @override
  String get groupsGrouping => 'Grouping trips and places…';

  @override
  String get groupsEmpty =>
      'No groups yet. Trips and places appear here as KFM finds them.';

  @override
  String get groupsRename => 'Rename';

  @override
  String get groupsRenameHint => 'Leave empty for the automatic name';

  @override
  String get groupsRenameSave => 'Save';

  @override
  String get groupsRenameCancel => 'Cancel';

  @override
  String get groupsChanged => 'This group changed';

  @override
  String get groupsChangedBody =>
      'Trips and places are recalculated as photos are added or removed.';

  @override
  String get groupsBack => 'Back to groups';

  @override
  String get groupsSwipe => 'Swipe this group';

  @override
  String get groupsLocationRow =>
      'Allow location access to group photos by place';

  @override
  String get groupsOnlineNames => 'Look up place names online';

  @override
  String get groupsOnlineNamesHelp =>
      'Sends the approximate centre of each place group to your phone\'s geocoding service to get names like \'Paris\'';

  @override
  String get groupsJobError =>
      'Couldn\'t update the groups. They\'ll be tried again later.';

  @override
  String groupsFailedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos couldn\'t be read',
      one: '1 photo couldn\'t be read',
    );
    return '$_temp0';
  }

  @override
  String smartGroupTripOneDay(DateTime day) {
    final intl.DateFormat dayDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dayString = dayDateFormat.format(day);

    return '$dayString';
  }

  @override
  String get aiLabelsTitle => 'Photo labels (AI)';

  @override
  String get aiLabelsEnable => 'Label photos on this phone';

  @override
  String get aiLabelsEnableHint =>
      'Find photos by what\'s in them, like cat, beach or food';

  @override
  String get aiLabelsEnableNeedsModels => 'Download the AI models first';

  @override
  String get aiLabelsPause => 'Pause labeling';

  @override
  String get aiLabelsResume => 'Resume labeling';

  @override
  String get aiLabelsPausedLine => 'Labeling is paused';

  @override
  String aiLabelsProgress(int processed, int total) {
    final intl.NumberFormat processedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String processedString = processedNumberFormat.format(processed);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$processedString of $totalString photos labeled',
      one: '$processedString of 1 photo labeled',
    );
    return '$_temp0';
  }

  @override
  String aiLabelsFailed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString photos couldn\'t be labeled',
      one: '1 photo couldn\'t be labeled',
    );
    return '$_temp0';
  }

  @override
  String get aiLabelsReset => 'Reset labels';

  @override
  String get aiLabelsResetConfirm => 'Reset all photo labels?';

  @override
  String get aiLabelsResetConfirmBody =>
      'Every photo will be labeled again from the start.';

  @override
  String get aiLabelsResetAction => 'Reset';

  @override
  String get aiLabelsHelp =>
      'Runs on this phone only. No photo or result ever leaves it.';

  @override
  String get aiLabelsJobError =>
      'The AI models are missing or changed, so labeling stopped. Download them again.';

  @override
  String get aiLabelsWorkerError => 'Labeling couldn\'t start on this phone.';

  @override
  String get aiLabelsCrashError =>
      'Labeling stopped after an error. It will be tried again later.';

  @override
  String get aiLabelsNeedsAndroid8 => 'Needs Android 8 or newer';

  @override
  String get aiLabelsUnsupported => 'Not available on this device yet';

  @override
  String get aiLabelsCardTitle =>
      'Find photos by what\'s in them (cat, beach, food…)';

  @override
  String get aiLabelsCardBody =>
      'KFM can label your photos on this phone. Nothing is uploaded.';

  @override
  String get aiLabelsCardTurnOn => 'Turn on';

  @override
  String get aiLabelsCardNotNow => 'Not now';

  @override
  String get aiLabelsTurnedOn => 'Photo labeling is on';

  @override
  String get aiCancel => 'Cancel';

  @override
  String get aiModelsTitle => 'AI models';

  @override
  String get aiModelsNotDownloaded => 'AI models not downloaded';

  @override
  String get aiModelsAbout => 'About AI models / Download…';

  @override
  String get aiModelsChecking => 'Checking AI models…';

  @override
  String aiModelsDownloading(double done, double total) {
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String totalString = totalNumberFormat.format(total);

    return 'Downloading $doneString of $totalString MB';
  }

  @override
  String get aiModelsWaitingWifi => 'Waiting for Wi-Fi';

  @override
  String get aiModelsVerifying => 'Checking the download…';

  @override
  String aiModelsInstalled(double size) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String sizeString = sizeNumberFormat.format(size);

    return 'Installed, $sizeString MB';
  }

  @override
  String get aiModelsNeedUpdate => 'AI models need an update — download again';

  @override
  String aiModelsPartial(double done, double total) {
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String totalString = totalNumberFormat.format(total);

    return 'Download paused at $doneString of $totalString MB';
  }

  @override
  String get aiModelsErrorNetwork => 'Download failed: no connection.';

  @override
  String aiModelsErrorHttp(String code) {
    return 'Download failed (server error $code).';
  }

  @override
  String get aiModelsErrorChecksum =>
      'The downloaded file didn\'t match the expected one. It was deleted and nothing was installed.';

  @override
  String get aiModelsErrorDiskFull => 'Download failed: not enough free space.';

  @override
  String get aiModelsErrorOther => 'Download failed.';

  @override
  String get aiModelsRetry => 'Retry';

  @override
  String get aiModelsCancel => 'Cancel download';

  @override
  String get aiModelsWifiOnly => 'Download on Wi-Fi only';

  @override
  String get aiModelsUseMobileData => 'Use mobile data this time';

  @override
  String get aiModelsWillUseWifi => 'Will download on Wi-Fi';

  @override
  String get aiModelsRemove => 'Remove AI models';

  @override
  String aiModelsRemoveTitle(double size) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String sizeString = sizeNumberFormat.format(size);

    return 'Remove AI models ($sizeString MB)?';
  }

  @override
  String get aiModelsRemoveBody =>
      'New photos won\'t be labeled anymore. You can download the models again later.';

  @override
  String get aiModelsRemoveAlsoLabels => 'Also delete the photo labels';

  @override
  String get aiModelsRemoveConfirm => 'Remove';

  @override
  String get aiModelsDetailsIntro =>
      'KFM can label your photos (cat, beach, food, person…) so you can find them by what\'s in them. This needs two small AI models that are not part of the app. They are downloaded only if you tap Download.';

  @override
  String get aiModelsHowTitle => 'How it works';

  @override
  String get aiModelsHowBody =>
      'Each photo\'s small thumbnail is analysed on this phone, once, in the background. Only label words like \"cat\" are stored in KFM\'s database.';

  @override
  String get aiModelsPrivacyTitle => 'Privacy';

  @override
  String get aiModelsPrivacyBody =>
      'Runs fully on this device. No photo, thumbnail or result ever leaves the phone. No account, no tracking. The only network use is this one download.';

  @override
  String get aiModelsBatteryBody =>
      'Labeling runs while KFM is open and pauses when the battery is below 20% and not charging.';

  @override
  String get aiModelsRemovableBody =>
      'You can remove the models at any time in Settings.';

  @override
  String aiModelsDownloadButton(double size) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String sizeString = sizeNumberFormat.format(size);

    return 'Download ($sizeString MB)';
  }

  @override
  String get aiModelsInstalledDone => 'AI models installed. Labeling is on.';

  @override
  String get aiModelClassifierWhat =>
      'Image classifier: recognises about 1,000 kinds of objects, animals, food and scenes.';

  @override
  String get aiModelClassifierUse =>
      'KFM uses it for labels like cat, dog, bird, food, beach, mountain, car and document.';

  @override
  String get aiModelDetectorWhat =>
      'Object detector: finds people (and counts them), pets, vehicles and food items.';

  @override
  String get aiModelDetectorUse =>
      'KFM uses it for labels like person, crowd, cat, dog, car and food.';

  @override
  String aiModelSize(double size) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String sizeString = sizeNumberFormat.format(size);

    return 'Download size: $sizeString MB';
  }

  @override
  String aiModelPublisher(String publisher) {
    return 'Publisher: $publisher';
  }

  @override
  String aiModelLicence(String licence) {
    return 'Licence: $licence';
  }

  @override
  String aiModelSource(String url) {
    return 'Downloaded from: $url';
  }

  @override
  String aiModelOriginal(String url) {
    return 'Original release: $url';
  }

  @override
  String get aiModelsLicences => 'View licences';

  @override
  String get aboutLicences => 'Open-source licences';

  @override
  String searchChipLabel(String label) {
    return 'Content: $label';
  }

  @override
  String get searchChipBlurry => 'Blurry photos';

  @override
  String searchStillLabeling(double percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.percentPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return 'Still labeling photos ($percentString) — results may be incomplete';
  }

  @override
  String get searchLabelingOff => 'Turn on photo labeling to search by content';

  @override
  String get searchLabelingOffTurnOn => 'Turn on';

  @override
  String get searchContentWordsLoadError =>
      'Content search words couldn\'t be loaded';

  @override
  String get fileMenuDetails => 'Details';

  @override
  String get selectionActionDetails => 'Details';

  @override
  String get detailsSheetLabel => 'File details';

  @override
  String get detailsLoading => 'Loading details';

  @override
  String get detailsPartial => 'Couldn\'t read some details';

  @override
  String get detailsGone => 'This file no longer exists';

  @override
  String get detailsWhatIsThis => 'What is this?';

  @override
  String get detailsHintUsually =>
      'Usually not needed, but check before deleting it';

  @override
  String get detailsHintCareful => 'Careful: deleting it can lose data';

  @override
  String get detailsCameFrom => 'Came from';

  @override
  String detailsSavedBy(String app) {
    return 'Saved by $app';
  }

  @override
  String detailsInSourceFolder(String source) {
    return 'In the $source folder';
  }

  @override
  String detailsNotInstalled(String package) {
    return '$package (not installed)';
  }

  @override
  String detailsDownloadedFrom(String host) {
    return 'Downloaded from $host';
  }

  @override
  String detailsLinkedFrom(String host) {
    return 'Link was on $host';
  }

  @override
  String get detailsShowFullAddress => 'Tap to show the full address';

  @override
  String detailsTakenWith(String camera) {
    return 'Taken with $camera';
  }

  @override
  String detailsEditedWith(String app) {
    return 'Made or edited with $app';
  }

  @override
  String get detailsWhere => 'Where';

  @override
  String get detailsPath => 'Path';

  @override
  String get detailsCopyPath => 'Copy path';

  @override
  String get detailsPathCopied => 'Path copied';

  @override
  String get detailsStorage => 'Storage';

  @override
  String get detailsStorageInternal => 'Internal storage';

  @override
  String get detailsStorageRemovable => 'SD card or USB drive';

  @override
  String get detailsHidden => 'Hidden';

  @override
  String get detailsOpenFolder => 'Open folder';

  @override
  String get detailsFileSection => 'File';

  @override
  String get detailsType => 'Type';

  @override
  String detailsTypeValue(String mime, String ext) {
    return '$mime (.$ext)';
  }

  @override
  String detailsTypeUnknown(String ext) {
    return 'Unknown file type (.$ext)';
  }

  @override
  String get detailsTypeUnknownNoExt => 'Unknown file type';

  @override
  String get detailsSize => 'Size';

  @override
  String detailsBytes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bytes',
      one: '1 byte',
    );
    return '$_temp0';
  }

  @override
  String get detailsModified => 'Modified';

  @override
  String get detailsAdded => 'Added to phone';

  @override
  String get detailsTaken => 'Taken';

  @override
  String get detailsDimensions => 'Dimensions';

  @override
  String get detailsDuration => 'Duration';

  @override
  String get detailsCameraSettings => 'Camera settings';

  @override
  String get detailsLens => 'Lens';

  @override
  String get detailsDescription => 'Description';

  @override
  String detailsIso(int value) {
    return 'ISO $value';
  }

  @override
  String detailsExposure(String value) {
    return '$value s';
  }

  @override
  String detailsFNumber(String value) {
    return 'f/$value';
  }

  @override
  String detailsFocalLength(String value) {
    return '$value mm';
  }

  @override
  String get detailsLocation => 'Location';

  @override
  String detailsLatLng(String lat, String lng) {
    return '$lat, $lng';
  }

  @override
  String get detailsInKfm => 'In KFM';

  @override
  String get detailsTags => 'Tags';

  @override
  String get detailsFavorite => 'Favorite';

  @override
  String detailsReviewed(String date) {
    return 'Reviewed $date';
  }

  @override
  String get detailsAppInfo => 'App info';

  @override
  String get detailsAppInfoFailed => 'Couldn\'t open App info';

  @override
  String detailsSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get detailsSummaryTotal => 'Total size';

  @override
  String get detailsSummaryKinds => 'Kinds';

  @override
  String detailsSummaryKindCount(String kind, int count) {
    return '$kind: $count';
  }

  @override
  String get detailsSummaryOldest => 'Oldest';

  @override
  String get detailsSummaryNewest => 'Newest';

  @override
  String get detailsSummaryFolders => 'Folders';

  @override
  String detailsSummaryFolderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count folders',
      one: 'In 1 folder',
    );
    return '$_temp0';
  }

  @override
  String detailsSummaryMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected files are no longer indexed',
      one: '1 selected file is no longer indexed',
    );
    return '$_temp0';
  }

  @override
  String get connectSettingsTitle => 'Connect a device';

  @override
  String get connectShareThisDevice => 'Share this device';

  @override
  String get connectShareThisDeviceHint =>
      'Let a phone or PC on the same Wi-Fi connect to this one';

  @override
  String get connectToDevice => 'Connect to a device';

  @override
  String get connectToDeviceHint => 'Scan a QR code or type a code';

  @override
  String get connectChooseHint =>
      'On the other device, open Settings → Connect a device → Share this device.';

  @override
  String get connectScanQr => 'Scan QR code';

  @override
  String get connectScanQrHint =>
      'Point the camera at the code on the other device';

  @override
  String get connectTypeCode => 'Type a code';

  @override
  String get connectTypeCodeHint => 'For a PC, or when there’s no camera';

  @override
  String get connectCameraDenied =>
      'KFM needs the camera to scan the code. You can type the code instead.';

  @override
  String get connectOpenSettings => 'Open settings';

  @override
  String get connectAllowCamera => 'Allow camera';

  @override
  String get connectNotKfmCode => 'Not a KFM code';

  @override
  String get connectUpdateKfm => 'Update KFM on both devices';

  @override
  String get connectDebugPasteLabel => 'Pairing link (debug builds only)';

  @override
  String get connectDebugPasteGo => 'Use link';

  @override
  String get connectNearbyTitle => 'Nearby devices';

  @override
  String get connectNearbySearching =>
      'Looking for devices sharing on this Wi-Fi…';

  @override
  String get connectNearbyFailed =>
      'Can’t search this Wi-Fi. Enter the address shown on the other device instead.';

  @override
  String get connectEnterAddress => 'Enter address';

  @override
  String get connectAddressLabel => 'Address shown on the other device';

  @override
  String get connectAddressInvalid => 'Enter it like 192.168.1.23:48211';

  @override
  String connectHostPort(String host, int port) {
    return '$host:$port';
  }

  @override
  String get connectNext => 'Next';

  @override
  String connectCodeFor(String name) {
    return 'Type the code shown on $name';
  }

  @override
  String get connectCodeForAddress => 'Type the code shown on the other device';

  @override
  String get connectCodeLabel => 'Code';

  @override
  String get connectCodeInvalidChar => 'Only letters and numbers';

  @override
  String get connectConnect => 'Connect';

  @override
  String get connectCancel => 'Cancel';

  @override
  String get connectConnecting => 'Connecting…';

  @override
  String connectWaiting(String name) {
    return 'Waiting for $name to accept…';
  }

  @override
  String connectConnected(String name) {
    return 'Connected to $name';
  }

  @override
  String get connectDisconnect => 'Disconnect';

  @override
  String get connectTryAgain => 'Try again';

  @override
  String get connectBack => 'Back';

  @override
  String get connectOtherDevice => 'the other device';

  @override
  String get connectErrorUnreachable =>
      'Devices can’t reach each other on this Wi-Fi. Try a hotspot.';

  @override
  String connectErrorWrongDevice(String name) {
    return 'This isn’t $name.';
  }

  @override
  String connectErrorWrongCode(String name) {
    return 'Wrong code, or this isn’t $name. Check the code and try again.';
  }

  @override
  String get connectErrorSecretUsed => 'Code already used';

  @override
  String get connectErrorExpired => 'This code expired. Scan the new one.';

  @override
  String get connectErrorTooMany =>
      'Too many attempts. Wait a moment, then try again.';

  @override
  String connectErrorBusy(String name) {
    return '$name is busy with another request. Try again in a moment.';
  }

  @override
  String connectErrorDeclined(String name) {
    return '$name declined the connection.';
  }

  @override
  String connectErrorTimedOut(String name) {
    return 'No answer from $name.';
  }

  @override
  String get connectErrorCancelled => 'Request cancelled';

  @override
  String get connectErrorFailed => 'Pairing failed. Try again.';

  @override
  String connectErrorNetwork(String name) {
    return 'The connection to $name was lost.';
  }

  @override
  String connectErrorBadResponse(String name) {
    return '$name didn’t answer like KFM. Update KFM on both devices.';
  }

  @override
  String get shareTitle => 'Share this device';

  @override
  String get sharePreparing => 'Preparing…';

  @override
  String get shareSharing => 'Sharing';

  @override
  String shareSharingAs(String name) {
    return 'Devices on the same Wi-Fi can connect to “$name”.';
  }

  @override
  String get shareKeepOpen =>
      'Sharing stops when you leave this screen or the app.';

  @override
  String get shareStop => 'Stop sharing';

  @override
  String get shareStopped => 'Sharing stopped';

  @override
  String get shareStartAgain => 'Share again';

  @override
  String get shareNoNetwork => 'Connect to Wi-Fi or turn on hotspot';

  @override
  String get shareNoNetworkHint =>
      'Both devices must be on the same Wi-Fi, or one must use the other\'s hotspot.';

  @override
  String get shareFailed => 'Couldn\'t start sharing';

  @override
  String get shareRetry => 'Try again';

  @override
  String shareDebugAddress(String address, int port) {
    return '$address:$port';
  }

  @override
  String shareDebugFingerprint(String fingerprint) {
    return 'Fingerprint: $fingerprint';
  }

  @override
  String get shareQrHint => 'Scan this with KFM on the other device';

  @override
  String get shareQrSemantics => 'QR code for pairing';

  @override
  String shareExpiresIn(String time) {
    return 'New code in $time';
  }

  @override
  String get shareTypeCodeTitle => 'No camera? Type this code';

  @override
  String shareAddress(String address) {
    return 'Address: $address';
  }

  @override
  String shareCodeCooldown(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other:
          'Too many wrong attempts. Typed codes work again in $seconds seconds.',
      one: 'Too many wrong attempts. Typed codes work again in 1 second.',
    );
    return '$_temp0';
  }

  @override
  String get shareTypedCodesOff =>
      'Typed codes are turned off for now. Scan the QR, or stop and start sharing again.';

  @override
  String get shareRotatedLocked =>
      'Too many wrong attempts. New code generated';

  @override
  String get sharePrivacyNote =>
      'While sharing, devices on this Wi-Fi can see this device’s name.';

  @override
  String get shareDiscoveryFailed =>
      'Nearby devices can’t list this one. They can enter the address instead.';

  @override
  String get devResetIdentity => 'Reset device identity';

  @override
  String get devResetIdentityDone => 'New device identity created';

  @override
  String get pairCompareWords => 'Check that both devices show these words';

  @override
  String connectNoFoldersYet(String name) {
    return '$name hasn’t shared any folders yet';
  }

  @override
  String connectFoldersShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shared folders',
      one: '1 shared folder',
    );
    return '$_temp0';
  }

  @override
  String connectDisconnected(String name) {
    return 'Disconnected from $name';
  }

  @override
  String acceptTitle(String name) {
    return '$name wants to connect';
  }

  @override
  String acceptTitleRemembered(String name) {
    return '$name (remembered) wants to connect';
  }

  @override
  String acceptPlatform(String platform) {
    return 'Device type: $platform';
  }

  @override
  String acceptAutoDecline(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Declines on its own in $seconds seconds',
      one: 'Declines on its own in 1 second',
    );
    return '$_temp0';
  }

  @override
  String get acceptDecline => 'Decline';

  @override
  String get acceptAccept => 'Accept';

  @override
  String get acceptRequestCancelled => 'Request cancelled';

  @override
  String get acceptTimedOut => 'No answer in time. The request was declined.';

  @override
  String shareConnectedTo(String name) {
    return 'Connected: $name';
  }

  @override
  String get shareDisconnectClient => 'Disconnect';

  @override
  String get sharedFoldersTitle => 'Shared folders';

  @override
  String sharedFoldersFor(String name) {
    return 'Folders $name can see';
  }

  @override
  String get sharedFoldersHint =>
      'Nothing is shared until you pick a folder. Shared folders are read-only unless you allow changes.';

  @override
  String get sharedFoldersMediaOnly =>
      'Without All files access, only photo folders can be shared.';

  @override
  String get sharedFolderCamera => 'Camera';

  @override
  String get sharedFolderPictures => 'Pictures';

  @override
  String get sharedFolderScreenshots => 'Screenshots';

  @override
  String get sharedFolderDownloads => 'Downloads';

  @override
  String get sharedFolderDocuments => 'Documents';

  @override
  String get sharedFolderAllStorage => 'All storage';

  @override
  String get sharedFolderAllowChanges =>
      'Allow changes (move, rename, delete, upload)';

  @override
  String get sharedFoldersChoose => 'Choose folder…';

  @override
  String get sharedFoldersDone => 'Done';

  @override
  String get sharedFoldersWholeStorageTitle => 'Share all your files?';

  @override
  String get sharedFoldersWholeStorageBody =>
      'The other device will see all your files.';

  @override
  String get sharedFoldersWholeStorageConfirm => 'Share everything';

  @override
  String get folderChooserTitle => 'Choose a folder';

  @override
  String get folderChooserShareThis => 'Share this folder';

  @override
  String get folderChooserEmpty => 'No subfolders';

  @override
  String get folderChooserError => 'Can’t open this folder';

  @override
  String shareClientFolders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shared folders',
      one: '1 shared folder',
      zero: 'No folders shared',
    );
    return '$_temp0';
  }

  @override
  String connectDisconnectedStopped(String name) {
    return '$name stopped sharing.';
  }

  @override
  String connectDisconnectedNetwork(String name) {
    return 'Lost the connection to $name. Check that both devices are on the same Wi-Fi.';
  }

  @override
  String get shareKeepOpenDesktop =>
      'Sharing stops when you leave this screen.';

  @override
  String get shareKeepsRunning =>
      'Sharing keeps running when you leave the app. Stop it here or from the notification.';

  @override
  String get shareNotificationChannel => 'Device sharing';

  @override
  String get shareNotificationWaiting => 'Sharing this device';

  @override
  String shareNotificationWith(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: 'Sharing with $name and $others more',
      zero: 'Sharing with $name',
    );
    return '$_temp0';
  }

  @override
  String get shareNotificationText =>
      'Devices on the same Wi-Fi can connect. Tap to open KFM.';

  @override
  String get shareNotificationStop => 'Stop';

  @override
  String get remoteNotConnected => 'The other device isn’t connected';

  @override
  String remoteBrowseAction(String device) {
    return 'Browse $device';
  }

  @override
  String get remoteBrowseRoots => 'Shared folders';

  @override
  String get remoteReadOnly => 'Read only';

  @override
  String remoteDeviceNotConnected(String device) {
    return '$device isn’t connected';
  }

  @override
  String get remoteReconnect => 'Connect again';

  @override
  String get remoteFileGone => 'This file is no longer available';

  @override
  String remoteNotAllowed(String device) {
    return 'Not allowed on $device';
  }

  @override
  String remoteDeclined(String device) {
    return '$device declined';
  }

  @override
  String remoteDeleteDeclined(String device) {
    return '$device declined the delete';
  }

  @override
  String get remoteEmptyFolder => 'No files here';

  @override
  String remoteShowingFirst(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Showing the first $count files',
      one: 'Showing the first file',
    );
    return '$_temp0';
  }

  @override
  String remoteTrashConfirm(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Move $count files to the trash on $device?',
      one: 'Move 1 file to the trash on $device?',
    );
    return '$_temp0';
  }

  @override
  String remoteTrashConfirmHint(String device) {
    return '$device may ask to confirm.';
  }

  @override
  String remoteTrashed(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moved $count files to the trash on $device',
      one: 'Moved 1 file to the trash on $device',
    );
    return '$_temp0';
  }

  @override
  String remoteMoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moved $count files',
      one: 'Moved 1 file',
    );
    return '$_temp0';
  }

  @override
  String remoteCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copied $count files',
      one: 'Copied 1 file',
    );
    return '$_temp0';
  }

  @override
  String remoteSomeFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files couldn’t be changed',
      one: '1 file couldn’t be changed',
    );
    return '$_temp0';
  }

  @override
  String remotePickFolderTitle(String device) {
    return 'Choose a folder on $device';
  }

  @override
  String get remotePickHere => 'Choose this folder';

  @override
  String get remoteConnectedDevice => 'Connected device';

  @override
  String remoteTrashRequest(String device, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$device wants to move $_temp0 to trash';
  }

  @override
  String remoteTrashDone(String device, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$device moved $_temp0 to trash';
  }

  @override
  String remoteTrashDeclinedByYou(String device) {
    return 'You declined $device’s request';
  }

  @override
  String remoteWriteRequest(String device, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$device wants to change $_temp0';
  }

  @override
  String get shareMediaOnlyHint =>
      'Without All files access, other devices see only photos, videos and audio.';

  @override
  String get rememberThisDevice => 'Remember this device';

  @override
  String get acceptAlwaysAllow => 'Always allow this device';

  @override
  String get acceptAlwaysAllowHint => 'Next time it connects without asking';

  @override
  String shareAutoAccepted(String name) {
    return '$name connected';
  }

  @override
  String shareRememberedFolders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count folders',
      one: '1 folder',
    );
    return 'Sharing $_temp0';
  }

  @override
  String get shareFoldersMissing => 'Some shared folders no longer exist';

  @override
  String get shareFoldersChange => 'Change';

  @override
  String connectErrorKeyChanged(String name) {
    return '$name has changed. Scan the QR code again.';
  }

  @override
  String get connectErrorNotAllowed => 'Not allowed. Scan the QR code again.';

  @override
  String connectErrorOffline(String name) {
    return 'Can’t reach $name. Open “Share this device” on $name.';
  }

  @override
  String get rememberedDevicesTitle => 'Remembered devices';

  @override
  String get rememberedDevicesHint =>
      'Reconnect without scanning, or forget a device';

  @override
  String get rememberedEmpty =>
      'No remembered devices yet. Devices you pair with “Remember this device” on show up here.';

  @override
  String get rememberedLoadFailed => 'Couldn’t load remembered devices';

  @override
  String get rememberedOnline => 'Sharing now';

  @override
  String get rememberedOffline => 'Not sharing right now';

  @override
  String get rememberedConnectsToUs => 'Connects to this device';

  @override
  String rememberedStatusWords(String status, String words) {
    return '$status · $words';
  }

  @override
  String get rememberedReconnect => 'Reconnect';

  @override
  String get rememberedShareFromHere => 'Share from this device';

  @override
  String get rememberedAlwaysAllow => 'Always allow';

  @override
  String get rememberedAlwaysAllowHint =>
      'When it connects to this device, don’t ask';

  @override
  String get rememberedRemove => 'Remove';

  @override
  String rememberedRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get rememberedRemoveBody =>
      'It is disconnected now and must scan the QR code to connect again. A lost or stolen remembered device still needs this device to be sharing and someone to tap Accept; removing it makes even that impossible.';

  @override
  String get rememberedRemoveAll => 'Remove all';

  @override
  String get rememberedRemoveAllTitle => 'Remove all remembered devices?';

  @override
  String get rememberedRemoveAllBody =>
      'Every device must scan the QR code again to connect.';

  @override
  String get rememberedRemoveFailed => 'Couldn’t remove the device. Try again.';

  @override
  String get resetIdentityTitle => 'Reset this device’s identity';

  @override
  String get resetIdentityHint =>
      'Forget all devices and make every device scan again';

  @override
  String get resetIdentityConfirmTitle => 'Reset this device’s identity?';

  @override
  String get resetIdentityConfirmBody =>
      'Sharing stops, this device gets a new key and every remembered device is forgotten. Other devices must scan the QR code again. Use this if a device may be compromised or before giving this one away.';

  @override
  String get resetIdentityConfirm => 'Reset';

  @override
  String get resetIdentityDone =>
      'New identity created. Other devices must scan again.';

  @override
  String get resetIdentityFailed => 'Couldn’t reset the identity. Try again.';

  @override
  String swipeProblemFolderNotOnSource(String device) {
    return 'Pick a folder on $device';
  }

  @override
  String swipeProblemReadOnly(String device) {
    return 'Read-only on $device';
  }

  @override
  String swipeProblemNotOnDevice(String device) {
    return 'Not available for files on $device';
  }

  @override
  String remoteSwipeWaiting(String device) {
    return 'Waiting for $device…';
  }

  @override
  String remoteSwipeContinue(String device) {
    return 'Continue swiping on $device';
  }

  @override
  String remoteSwipeSwiped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count swiped',
      one: '1 swiped',
      zero: 'Nothing swiped yet',
    );
    return '$_temp0';
  }

  @override
  String remoteSwipePaused(String device) {
    return 'Paused · $device not connected';
  }

  @override
  String remoteSwipeOrphaned(String device) {
    return '$device isn\'t remembered any more';
  }

  @override
  String remoteSwipeFinishNeedsConnection(String device) {
    return 'Connect to $device to finish';
  }

  @override
  String remoteSwipeFinishBody(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files will be moved to the trash on $device.',
      one: '1 file will be moved to the trash on $device.',
      zero: 'Nothing is waiting to be deleted.',
    );
    return '$_temp0';
  }

  @override
  String remoteSwipeRestoreOnDevice(String device) {
    return 'Restore it from the Trash on $device';
  }

  @override
  String remoteSwipeDeclined(String device) {
    return '$device declined the delete';
  }

  @override
  String get remoteSwipeAllDone => 'All done in this folder.';

  @override
  String get remoteSwipeDiscard => 'Discard session';

  @override
  String remoteSwipeDiscardTitle(String device) {
    return 'Discard the swipe session on $device?';
  }

  @override
  String get remoteSwipeDiscardBody =>
      'Your swipes there are forgotten. Nothing is deleted on that device.';

  @override
  String get remoteSwipeUnknownDevice => 'the other device';

  @override
  String get transfersTitle => 'Transfers';

  @override
  String get transfersDownloads => 'Downloads';

  @override
  String get transfersUploads => 'Uploads';

  @override
  String get transfersEmptyDownloads =>
      'No downloads yet. Select files on a connected device and tap Download.';

  @override
  String get transfersEmptyUploads =>
      'No uploads yet. Select files and tap Send to device.';

  @override
  String transferFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String transferFromDevice(String device) {
    return 'From $device';
  }

  @override
  String transferToDevice(String device) {
    return 'To $device';
  }

  @override
  String transferSpeedEta(String speed, String eta) {
    return '$speed/s · $eta left';
  }

  @override
  String transferProgress(String done, String total) {
    return '$done of $total';
  }

  @override
  String get transferStatusQueued => 'Waiting';

  @override
  String transferStatusWaitingFor(String device) {
    return 'Waiting for $device';
  }

  @override
  String get transferStatusRunning => 'Transferring';

  @override
  String get transferStatusDone => 'Done';

  @override
  String transferStatusFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files failed',
      one: '1 file failed',
    );
    return '$_temp0';
  }

  @override
  String get transferStatusCancelled => 'Cancelled';

  @override
  String get transferCancel => 'Cancel';

  @override
  String get transferRetry => 'Retry';

  @override
  String get transferClearFinished => 'Clear finished';

  @override
  String transferNoSpaceOn(String device) {
    return 'Not enough space on $device';
  }

  @override
  String get transferNoSpaceHere => 'Not enough space on this device';

  @override
  String transferNotAllowedOn(String device) {
    return 'Not allowed on $device';
  }

  @override
  String transferNoWritableFolder(String device) {
    return 'No writable folder shared by $device';
  }

  @override
  String get transferInvalidName => 'This file name can’t be used here';

  @override
  String get transferNoLocation => 'Location info isn’t included';

  @override
  String get transferAlreadySent => 'Already sent';

  @override
  String transferConnectToPick(String device) {
    return 'Connect to $device to pick a folder';
  }

  @override
  String transfersRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers running',
      one: '1 transfer running',
      zero: 'Nothing running',
    );
    return '$_temp0';
  }

  @override
  String transferLostConnection(String device) {
    return 'Lost the connection to $device';
  }

  @override
  String get transferInterrupted => 'Stopped when KFM closed';

  @override
  String get transferSourceGone => 'The file is gone';

  @override
  String get transferIncomplete => 'The transfer was cut off';

  @override
  String get transferFailedGeneric => 'Couldn’t transfer this file';

  @override
  String get transferDownloadAction => 'Download';

  @override
  String transferDownloadQueued(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Downloading $count files from $device',
      one: 'Downloading 1 file from $device',
    );
    return '$_temp0';
  }

  @override
  String transferUploadQueued(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sending $count files to $device',
      one: 'Sending 1 file to $device',
    );
    return '$_temp0';
  }

  @override
  String get transferShow => 'Show';

  @override
  String get transferSendToDevice => 'Send to device';

  @override
  String get transferConnectFirst => 'Connect to a device first';

  @override
  String transferDownloadTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Download $count files?',
      one: 'Download 1 file?',
    );
    return '$_temp0';
  }

  @override
  String transferDownloadTo(String folder) {
    return 'Saved in $folder';
  }

  @override
  String get transferChangeFolder => 'Change folder';

  @override
  String get transferPickDeviceTitle => 'Send to which device?';

  @override
  String get transferNoRememberedDevices =>
      'No remembered devices yet. Connect to one with “Remember this device” on.';

  @override
  String get swipeProblemDeviceMissing =>
      'That device isn’t remembered any more';

  @override
  String get swipeActionSendToDevice => 'Send to device…';

  @override
  String swipeActionSendToNamed(String device) {
    return 'Send to $device';
  }

  @override
  String rememberedRemoveTransfers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Its $count transfers are removed too.',
      one: 'Its 1 transfer is removed too.',
    );
    return '$_temp0';
  }
}
