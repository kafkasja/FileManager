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
}
