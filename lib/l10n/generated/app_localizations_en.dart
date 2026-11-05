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
  String dbResetNotice(String name) {
    return 'KFM\'s data was damaged, so KFM started fresh. Your photos and files were not touched; sessions, tags and settings are reset. The damaged copy was kept as $name.';
  }

  @override
  String get dbUnavailableNotice =>
      'KFM can\'t open its data right now. Another program may be using it. Close it and restart KFM. Your files were not touched.';

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
  String get videoDamaged => 'This file can\'t be played — it may be damaged';

  @override
  String get imageDamaged => 'This file can\'t be shown — it may be damaged';

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
  String get aiLabelsJobError =>
      'The AI models are missing or changed, so labeling stopped. Download them again.';

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
  String get aiModelsPrivacyTitle => 'Privacy';

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
  String get transferChecking => 'Checking…';

  @override
  String shareClientGone(String name) {
    return 'Disconnected: $name';
  }

  @override
  String get shareKeepsRunningNoNotification =>
      'Sharing keeps running when you leave the app. Notifications are off for KFM, so come back here to stop it.';

  @override
  String get shareStopConfirmTitle => 'Stop sharing?';

  @override
  String get shareStopConfirmBody =>
      'Files are still being sent or received. Stopping now interrupts them; they continue the next time you share.';

  @override
  String get shareKeepSharing => 'Keep sharing';

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
  String get rememberedConnected => 'Connected';

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
  String get transferPause => 'Pause';

  @override
  String get transferResume => 'Resume';

  @override
  String get transferReconnect => 'Reconnect';

  @override
  String get transferPausedByYou => 'Paused';

  @override
  String get transferRetrying => 'Trying again soon';

  @override
  String get transferSourceChanged => 'The file changed while it was sent';

  @override
  String get transferModeCopy => 'Copy';

  @override
  String get transferModeMove => 'Move';

  @override
  String transferMoveDownloadNote(String device) {
    return 'Each file is checked after it arrives; only then does its original go to the trash on $device.';
  }

  @override
  String get transferMoveToDevice => 'Move to device';

  @override
  String transferMoveFromDevice(String device) {
    return 'Moving from $device';
  }

  @override
  String transferMoveToDeviceTitle(String device) {
    return 'Moving to $device';
  }

  @override
  String transferMoveQueued(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moving $count files to $device',
      one: 'Moving 1 file to $device',
    );
    return '$_temp0';
  }

  @override
  String transferMoveDownloadQueued(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moving $count files from $device',
      one: 'Moving 1 file from $device',
    );
    return '$_temp0';
  }

  @override
  String get transferVerifying => 'Verifying…';

  @override
  String get transferVerified => 'Verified';

  @override
  String get transferVerifyFailed => 'Verification failed. Original kept.';

  @override
  String get transferAlreadyMoved => 'Already moved';

  @override
  String get transferOriginalPending => 'Verified · original not deleted yet';

  @override
  String get transferOriginalTrashed => 'Verified · original moved to trash';

  @override
  String transferOriginalTrashedOn(String device) {
    return 'Verified · original moved to trash on $device';
  }

  @override
  String get transferOriginalDeleted => 'Verified · original deleted';

  @override
  String get transferOriginalGone => 'Verified · original was already gone';

  @override
  String get transferOriginalKeptDeclined =>
      'Verified · original kept (you declined)';

  @override
  String transferOriginalKeptDeclinedOn(String device) {
    return 'Verified · original kept (declined on $device)';
  }

  @override
  String get transferOriginalKeptCancelled =>
      'Verified · original kept (cancelled)';

  @override
  String get transferOriginalKeptChanged => 'Original kept (changed)';

  @override
  String get transferOriginalKeptFailed =>
      'Verified · original kept (couldn’t delete it)';

  @override
  String get transferDeleteOriginals => 'Delete originals';

  @override
  String get transferDeletingOriginals => 'Deleting originals…';

  @override
  String get permanentMoveTitle => 'Delete originals permanently?';

  @override
  String permanentMoveBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Your delete setting is “Delete permanently”: the $count originals are deleted for good once their copies are verified.',
      one: 'Your delete setting is “Delete permanently”: the original is deleted for good once its copy is verified.',
    );
    return '$_temp0';
  }

  @override
  String get permanentMoveUseTrash => 'Use trash instead';

  @override
  String get permanentMoveConfirm => 'Delete permanently';

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

  @override
  String get errorLogShare => 'Share error log';

  @override
  String get errorLogEmpty => 'No errors logged';

  @override
  String get errorLogShareSubject => 'KFM error log';

  @override
  String get errorLogShareFailed => 'Couldn\'t share the error log';

  @override
  String get errorLogClear => 'Clear error log';

  @override
  String get errorLogClearConfirm =>
      'Clear the error log? This can\'t be undone.';

  @override
  String get errorLogCleared => 'Error log cleared';

  @override
  String get errorLogClearFailed => 'Couldn\'t clear the error log';

  @override
  String get devThrowTestError => 'Throw test error';

  @override
  String get themeColorLabel => 'Color';

  @override
  String get accentBlue => 'Blue';

  @override
  String get accentGreen => 'Green';

  @override
  String get accentPurple => 'Purple';

  @override
  String get accentOrange => 'Orange';

  @override
  String get accentMono => 'Mono';

  @override
  String get accentSystem => 'System colors';

  @override
  String get settingsAccessibility => 'Accessibility';

  @override
  String get leftHandedTitle => 'Left-handed';

  @override
  String get textSizeLabel => 'Text size';

  @override
  String get textSizeSystem => 'System';

  @override
  String get textSizeLarge => 'Large';

  @override
  String get textSizeExtraLarge => 'Extra large';

  @override
  String get textSizePreview => 'This is how text will look.';

  @override
  String get externalPlacesTitle => 'Places';

  @override
  String get externalInternal => 'Internal storage';

  @override
  String get externalGeneric => 'External storage';

  @override
  String get externalSdCard => 'SD card';

  @override
  String get externalUsbDrive => 'USB drive';

  @override
  String externalFreeOf(String free, String total) {
    return '$free free of $total';
  }

  @override
  String externalAttached(String label) {
    return '$label connected';
  }

  @override
  String get externalOpen => 'Open';

  @override
  String get externalRemoved => 'Storage removed';

  @override
  String externalGrantTitle(String label) {
    return 'Allow access to $label';
  }

  @override
  String get externalGrantExplain =>
      'Android asks once which drive KFM may use. On the next screen, choose the drive itself (not a folder inside it) and tap “Use this folder”.';

  @override
  String get externalGrantContinue => 'Continue';

  @override
  String get externalPickRootTitle => 'Pick the drive itself';

  @override
  String get externalPickRootHint =>
      'That was a folder inside the drive. Pick the drive’s top level so KFM can see all of it.';

  @override
  String get externalRetry => 'Pick again';

  @override
  String get externalGrantFailed =>
      'Android didn’t keep the access. Try again.';

  @override
  String externalAllFilesTitle(String label) {
    return 'Open $label';
  }

  @override
  String externalAllFilesExplain(String label) {
    return 'To open $label, KFM needs All files access. Android doesn’t let apps choose a whole SD card or USB drive any other way. On the next screen, turn on access for KFM, then come back.';
  }

  @override
  String externalAllFilesStillOff(String label) {
    return 'All files access is still off, so $label can’t be opened.';
  }

  @override
  String get externalFormatHelp =>
      'The USB drive didn’t open. Android reads FAT32 and exFAT drives; NTFS drives often don’t work. Reformat it on a computer or try another drive.';

  @override
  String externalCameraLabel(String model) {
    return 'Camera · $model';
  }

  @override
  String get externalCameraUnsupported =>
      'This camera can’t be opened here. Close other camera apps, or set the camera to USB mass storage.';

  @override
  String get externalPermissionNeeded => 'Permission needed · Tap to allow';

  @override
  String get externalCameraReadOnly => 'Connected · read-only';

  @override
  String get externalCameraNotYet => 'Opening cameras isn’t available yet.';

  @override
  String get externalLoadError => 'Couldn’t read the storage list.';

  @override
  String get privacySectionTitle => 'Privacy';

  @override
  String get privacyStripLocation => 'Remove location when sharing';

  @override
  String get privacyStripLocationHelp =>
      'Photos and videos you share or send to another device go without location info. Your originals keep it.';

  @override
  String get privacyAllowAccess => 'Allow access to photo locations';

  @override
  String get privacyAllowAccessHelp =>
      'Without it, photos you send arrive without their location.';

  @override
  String get privacyNoOriginalNote =>
      'KFM can\'t read the original location of your photos; they\'re sent without it anyway.';

  @override
  String get privacyShareAction => 'Share';

  @override
  String privacyShareTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Share $count files',
      one: 'Share 1 file',
    );
    return '$_temp0';
  }

  @override
  String get privacyShareRemoveLocation => 'Remove location';

  @override
  String get privacyShareRemoveLocationHelp =>
      'From photos and videos. Your originals keep it.';

  @override
  String privacyRemovingLocation(int done, int total) {
    return 'Removing location… $done/$total';
  }

  @override
  String get privacyShareNoApp => 'No app can receive these files';

  @override
  String privacyCouldNotStrip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Location couldn\'t be removed from $count files, so they weren\'t shared',
      one: 'Location couldn\'t be removed from 1 file, so it wasn\'t shared',
    );
    return '$_temp0';
  }

  @override
  String privacyFailedLine(String name, String reason) {
    return '$name: $reason';
  }

  @override
  String get privacyFailStillHasLocation =>
      'location info was still found after removing it';

  @override
  String get privacyFailUnsupported => 'this video\'s info can\'t be edited';

  @override
  String get privacyFailReadFailed => 'the file couldn\'t be read';

  @override
  String get privacyTransferNotRemoved =>
      'Location couldn\'t be removed, so it wasn\'t sent';

  @override
  String get privacyMoveWarningTitle => 'Move without location?';

  @override
  String get privacyMoveWarningBody =>
      'The copies will have no location, and the originals with location will be deleted from this device.';

  @override
  String get privacyMoveAnyway => 'Move anyway';

  @override
  String get privacyCopyInstead => 'Copy instead';

  @override
  String externalJobTitleCopy(int count, String place) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copying $count files to $place',
      one: 'Copying 1 file to $place',
    );
    return '$_temp0';
  }

  @override
  String externalJobTitleMove(int count, String place) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moving $count files to $place',
      one: 'Moving 1 file to $place',
    );
    return '$_temp0';
  }

  @override
  String externalJobProgress(int done, int total, String size) {
    return '$done of $total · $size';
  }

  @override
  String get externalJobQueued => 'Waiting';

  @override
  String get externalJobRunning => 'In progress';

  @override
  String get externalJobPaused => 'Paused';

  @override
  String get externalJobPausedUnplugged =>
      'Paused · connect the storage again to continue';

  @override
  String get externalJobDone => 'Done';

  @override
  String get externalJobCancelled => 'Cancelled';

  @override
  String externalJobFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files failed',
      one: '1 file failed',
    );
    return '$_temp0';
  }

  @override
  String get externalJobStoppedNoSpace => 'Stopped: not enough space';

  @override
  String get externalJobResume => 'Resume';

  @override
  String get externalJobPause => 'Pause';

  @override
  String get externalJobDetails => 'Details';

  @override
  String externalJobStartedCopy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copying $count files…',
      one: 'Copying 1 file…',
    );
    return '$_temp0';
  }

  @override
  String externalJobStartedMove(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moving $count files…',
      one: 'Moving 1 file…',
    );
    return '$_temp0';
  }

  @override
  String get externalJobView => 'View';

  @override
  String externalNotEnoughSpace(String place) {
    return 'Not enough space on $place';
  }

  @override
  String get externalStagingNoSpace =>
      'Not enough free space on this phone to copy through it';

  @override
  String externalFat32TooLarge(String name) {
    return '$name: 4 GB or larger, too big for this drive (FAT32)';
  }

  @override
  String externalRenamedForDrive(String from, String to) {
    return '$from saved as $to';
  }

  @override
  String externalCollisionTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files are already there',
      one: '1 file is already there',
    );
    return '$_temp0';
  }

  @override
  String get externalCollisionKeepBoth => 'Keep both';

  @override
  String get externalCollisionSkip => 'Skip';

  @override
  String get externalCollisionReplace => 'Replace';

  @override
  String get externalApplyToAll =>
      'Your choice applies to every file of this job.';

  @override
  String get externalCameraDeleteWarning =>
      'Camera photos have no trash: deleting them here deletes them for good.';

  @override
  String externalOriginalNotRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count originals weren’t removed',
      one: '1 original wasn’t removed',
    );
    return '$_temp0';
  }

  @override
  String get externalDeleteOriginals => 'Delete originals';

  @override
  String get externalSwipeFolder => 'Swipe this folder';

  @override
  String get externalSwipeFolderEmpty => 'No photos or videos in this folder';

  @override
  String get externalNoJobs =>
      'No copies or moves between storage places in the last 7 days';

  @override
  String get externalClearFinished => 'Clear finished';

  @override
  String get externalVerifyFailed => 'Verification failed. Original kept.';

  @override
  String get externalSourceGone => 'The file is gone';

  @override
  String get externalAlreadyMoved => 'Already moved';

  @override
  String get externalSkippedExists => 'Skipped: already there';

  @override
  String get externalFileFailed => 'Couldn’t copy';

  @override
  String externalLogLine(String name, String reason) {
    return '$name: $reason';
  }

  @override
  String get externalFolderEmpty => 'This folder is empty';

  @override
  String get externalFolderError => 'Couldn’t open this folder';

  @override
  String get externalSortByName => 'Name';

  @override
  String get externalSortByDate => 'Date';

  @override
  String get externalSortBySize => 'Size';

  @override
  String get externalShowAll => 'All files';

  @override
  String get externalShowMedia => 'Photos and videos';

  @override
  String get externalCopyTo => 'Copy to…';

  @override
  String get externalMoveTo => 'Move to…';

  @override
  String get externalDelete => 'Delete';

  @override
  String get externalReadOnly => 'Read-only';

  @override
  String externalDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files deleted',
      one: '1 file deleted',
    );
    return '$_temp0';
  }

  @override
  String get externalDeleteFailed => 'Couldn’t delete';

  @override
  String get swipeSetupTitle => 'Swipe setup';

  @override
  String get swipeSetupTuneTooltip => 'Swipe setup';

  @override
  String get swipeSetupPresets => 'Presets';

  @override
  String get swipeSetupDirections => 'Swipe directions';

  @override
  String get swipeSetupFilter => 'Filter';

  @override
  String get swipeSetupEditFilter => 'Edit filter';

  @override
  String get swipeSetupExtras => 'Extras';

  @override
  String swipeSetupModified(String name) {
    return 'Changes not saved to $name';
  }

  @override
  String get swipeSetupSave => 'Save';

  @override
  String get swipeSetupSaveAsNew => 'Save as new…';

  @override
  String get swipeSetupRevert => 'Revert';

  @override
  String swipeSetupSavedTo(String name) {
    return 'Saved to “$name”';
  }

  @override
  String swipeSetupRemoteTitle(String device) {
    return 'Setup for swiping on $device';
  }

  @override
  String swipeSetupPresetSemantics(String name) {
    return 'Preset $name';
  }

  @override
  String swipeSetupPresetModifiedSemantics(String name) {
    return 'Preset $name, modified';
  }

  @override
  String swipeSetupDirectionSemantics(String direction, String action) {
    return '$direction: $action';
  }

  @override
  String get swipeSetupFilterOn => 'Filter on';

  @override
  String get swipeSetupPresetBroken => 'Can\'t load';

  @override
  String get ejectAction => 'Eject';

  @override
  String ejectRunningJobs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers still running',
      one: '1 transfer still running',
    );
    return '$_temp0';
  }

  @override
  String get ejectRunningJobsBody =>
      'Pausing stops after the current file. Paused transfers can be resumed later.';

  @override
  String get ejectWait => 'Wait';

  @override
  String get ejectPauseAndEject => 'Pause & eject';

  @override
  String ejectWaiting(String label) {
    return 'Finishing work on $label…';
  }

  @override
  String ejectHintTitle(String label) {
    return 'Eject $label';
  }

  @override
  String get ejectHint =>
      'Android lets only its own settings eject storage. Tap the drive, then Eject (on some phones: ⋮ → Unmount).';

  @override
  String get ejectOpenSettings => 'Open settings';

  @override
  String ejectSafe(String label) {
    return '$label can be safely removed';
  }

  @override
  String get ejectNotYet => 'Not ejected yet';

  @override
  String get ejectOpenAgain => 'Open settings again';

  @override
  String get ejectCameraSafe => 'Camera can be disconnected';

  @override
  String get ejectRefused => 'This storage is being ejected';

  @override
  String get ejectFailed => 'Can\'t open the storage settings';

  @override
  String get sendTo => 'Send to…';

  @override
  String sendSheetTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Send $count files to…',
      one: 'Send 1 file to…',
    );
    return '$_temp0';
  }

  @override
  String get sendSheetConnected => 'Connected';

  @override
  String get sendSheetConnectedToYou => 'Connected to you';

  @override
  String get sendSheetRemembered => 'Remembered';

  @override
  String get sendSheetNearby => 'Nearby';

  @override
  String get sendSheetOnline => 'Nearby now';

  @override
  String sendAskReceive(String device) {
    return 'Ask $device to open Receive files';
  }

  @override
  String sendSwitchDevice(String from, String to) {
    return 'Disconnect from $from to send to $to?';
  }

  @override
  String get sendSwitchAction => 'Disconnect';

  @override
  String sendConnecting(String device) {
    return 'Connecting to $device…';
  }

  @override
  String sendConfirmTitle(int count, String size, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Send $count files ($size) to $device?',
      one: 'Send 1 file ($size) to $device?',
    );
    return '$_temp0';
  }

  @override
  String sendConfirmHint(String device) {
    return '$device decides whether to take them. Nothing else is shared.';
  }

  @override
  String sendSharedFolderInstead(String device) {
    return 'Put them in a shared folder on $device…';
  }

  @override
  String get sendAction => 'Send';

  @override
  String sendWaiting(String device) {
    return 'Waiting for $device to accept…';
  }

  @override
  String sendDeclined(String device) {
    return '$device declined';
  }

  @override
  String sendNoAnswer(String device) {
    return 'No answer from $device';
  }

  @override
  String sendNoSpace(String device) {
    return 'Not enough space on $device';
  }

  @override
  String sendStopped(String device) {
    return 'Stopped by $device';
  }

  @override
  String sendSending(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sending $count files to $device',
      one: 'Sending 1 file to $device',
    );
    return '$_temp0';
  }

  @override
  String get sendPairToSend => 'Connect to send files';

  @override
  String sendConfirmPanelTitle(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Send $count files to $device',
      one: 'Send 1 file to $device',
    );
    return '$_temp0';
  }

  @override
  String get receiveFiles => 'Receive files';

  @override
  String get receiveFilesHint => 'Let another device send you files';

  @override
  String get receiveReadyTitle => 'Ready to receive files';

  @override
  String receiveReadyHint(String device) {
    return 'On the other device: Send to… → $device, or scan this code';
  }

  @override
  String offerTitle(String device, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$device wants to send you $count files',
      one: '$device wants to send you 1 file',
    );
    return '$_temp0';
  }

  @override
  String offerSize(String size) {
    return 'Total $size';
  }

  @override
  String offerMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'and $count more',
      one: 'and 1 more',
    );
    return '$_temp0';
  }

  @override
  String offerSaveTo(String folder) {
    return 'Save to $folder';
  }

  @override
  String get offerChangeFolder => 'Change';

  @override
  String get offerFolderExcluded => 'Files can\'t be saved there';

  @override
  String offerRemember(String device) {
    return 'Remember $device';
  }

  @override
  String offerAlwaysAccept(String device) {
    return 'Always accept files from $device';
  }

  @override
  String get offerAccept => 'Accept';

  @override
  String get offerDecline => 'Decline';

  @override
  String offerAutoDecline(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Declines in $seconds seconds',
      one: 'Declines in 1 second',
    );
    return '$_temp0';
  }

  @override
  String get offerNotificationChannel => 'Incoming files';

  @override
  String offerNotificationTitle(String device) {
    return '$device wants to send you files';
  }

  @override
  String offerNotificationBody(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files · $size · Tap to answer',
      one: '1 file · $size · Tap to answer',
    );
    return '$_temp0';
  }

  @override
  String offerReceiving(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Receiving $count files from $device',
      one: 'Receiving 1 file from $device',
    );
    return '$_temp0';
  }

  @override
  String offerReceived(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Received $count files from $device',
      one: 'Received 1 file from $device',
    );
    return '$_temp0';
  }

  @override
  String get offerOpenFolder => 'Open';

  @override
  String get rememberedAcceptFiles => 'Accept files without asking';

  @override
  String get rememberedAcceptFilesHint =>
      'Files this device sends go to your Download folder without a prompt';

  @override
  String connectSendOnly(String device) {
    return 'Connected to $device to send files';
  }

  @override
  String shareSessionSending(String device) {
    return '$device · sending files';
  }

  @override
  String get transferReceivedSection => 'Received';

  @override
  String get transferOfferedSection => 'Offered';

  @override
  String get transferWaitingForYou => 'Waiting for you';

  @override
  String get transferPreparing => 'Preparing…';

  @override
  String transferFromDeviceOffer(String device, int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'From $device · $count files · $size',
      one: 'From $device · 1 file · $size',
    );
    return '$_temp0';
  }

  @override
  String transferToDeviceOffer(String device, int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'To $device · $count files · $size',
      one: 'To $device · 1 file · $size',
    );
    return '$_temp0';
  }

  @override
  String transferOfferReceiving(int done, int count) {
    return '$done of $count received';
  }

  @override
  String get transferOfferDone => 'Done';

  @override
  String get transferOfferCancelled => 'Stopped';

  @override
  String get transferOfferDeclined => 'Declined';

  @override
  String get transferOfferExpired => 'No answer';

  @override
  String get transferOfferStop => 'Stop';

  @override
  String get transferOfferAnswer => 'Answer';

  @override
  String get transferOfferOpenFolder => 'Open folder';

  @override
  String get transferOfferAccepted => 'Accepted';

  @override
  String get transfersEmptyReceived => 'Files other devices send you show here';

  @override
  String shareInTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shared files',
      one: '1 shared file',
    );
    return '$_temp0';
  }

  @override
  String get shareInSwipe => 'Swipe through them';

  @override
  String get shareInMoveTo => 'Move to…';

  @override
  String get shareInCopyTo => 'Copy to…';

  @override
  String get shareInSendToDevice => 'Send to…';

  @override
  String shareInCopiedSubtitle(String size) {
    return '$size · Copied from another app';
  }

  @override
  String get shareInCopyDeleteNote =>
      'Files copied from another app are removed from KFM when you delete them. The original stays in that app.';

  @override
  String get shareInOnlyFiles => 'Only files can be shared into KFM';

  @override
  String get shareInPreparing => 'Getting the shared files…';

  @override
  String shareInCopying(String done, String total) {
    return 'Copying $done of $total';
  }

  @override
  String get shareInCancel => 'Cancel';

  @override
  String shareInFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files couldn\'t be read',
      one: '1 file couldn\'t be read',
    );
    return '$_temp0';
  }

  @override
  String get shareInFailedAll =>
      'The shared files couldn\'t be read. Try sharing them again.';

  @override
  String get shareInNoSpace => 'Not enough free space to copy the shared files';

  @override
  String get shareInEmpty => 'No shared files left here';

  @override
  String get shareInDone => 'Done';

  @override
  String get backupSectionTitle => 'Backup';

  @override
  String get backupExport => 'Export backup';

  @override
  String get backupExportHelp =>
      'Tags, presets, favorites, reviewed labels and settings in one file. Your photos stay where they are.';

  @override
  String get backupImport => 'Import backup';

  @override
  String get backupImportHelp =>
      'Adds a backup\'s data to this phone. Nothing here is deleted.';

  @override
  String get backupUndoImport => 'Undo last import';

  @override
  String get backupUndoImportHelp =>
      'Go back to how things were before the last import';

  @override
  String get backupExported => 'Backup saved';

  @override
  String backupExportFailed(String error) {
    return 'Couldn\'t save the backup: $error';
  }

  @override
  String backupImportFailed(String error) {
    return 'Couldn\'t import the backup: $error';
  }

  @override
  String get backupNotKfm => 'This isn\'t a KFM backup.';

  @override
  String get backupTooNew =>
      'This backup was made by a newer version of KFM. Update the app first.';

  @override
  String get backupPreviewTitle => 'Import backup';

  @override
  String get backupScanning => 'Scanning…';

  @override
  String backupPreviewNewTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new tags',
      one: '1 new tag',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewReusedTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags already on this phone',
      one: '1 tag already on this phone',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewNewPresets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new presets',
      one: '1 new preset',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewSkippedPresets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count presets already on this phone',
      one: '1 preset already on this phone',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewMatched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files found on this phone',
      one: '1 file found on this phone',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewFileTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags added to files',
      one: '1 tag added to a file',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewFavorites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new favorites',
      one: '1 new favorite',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewReviewed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviewed labels',
      one: '1 reviewed label',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewUnmatched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files not found on this phone',
      one: '1 file not found on this phone',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewUnmatchedMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'and $count more',
      one: 'and 1 more',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewFilePath(String folder, String name) {
    return '$folder/$name';
  }

  @override
  String get backupApplySettings => 'Also apply settings';

  @override
  String backupPreviewSettings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count settings change',
      one: '1 setting changes',
      zero: 'No settings change',
    );
    return '$_temp0';
  }

  @override
  String get backupPreviewNothing => 'Nothing new to import.';

  @override
  String get backupImportedSuffix => 'imported';

  @override
  String get backupImportButton => 'Import';

  @override
  String get backupImported => 'Backup imported';

  @override
  String get backupUndoConfirmTitle => 'Undo last import?';

  @override
  String get backupUndoConfirmBody =>
      'Tags, presets, favorites, reviewed labels and settings go back to how they were before the import. Changes you made after it are lost too.';

  @override
  String get backupUndoConfirm => 'Undo import';

  @override
  String get backupUndone => 'Import undone';

  @override
  String backupUndoFailed(String error) {
    return 'Couldn\'t undo the import: $error';
  }

  @override
  String get backupSettingThemeMode => 'Theme';

  @override
  String get backupSettingThemeAccent => 'Colour theme';

  @override
  String get backupSettingLeftHanded => 'Left-handed mode';

  @override
  String get backupSettingTextSize => 'Text size';

  @override
  String get backupSettingLanguage => 'Language';

  @override
  String get backupSettingBigFileThreshold => 'Big file size';

  @override
  String get backupSettingPendingRetention => 'Keep deleted files for';

  @override
  String get backupSettingSameTimeWindow => 'Same-time window';

  @override
  String get backupSettingBrowseSort => 'Sort files by';

  @override
  String get backupSettingBrowseSortDescending => 'Sort direction';

  @override
  String get backupSettingBrowseShowSizes => 'Show file sizes';

  @override
  String get backupSettingBrowseHighlightBig => 'Highlight big files';

  @override
  String get backupSettingSearchSecondLanguage => 'Second search language';

  @override
  String get backupSettingSwipeLayout => 'Basic swipe directions';

  @override
  String get backupSettingDeleteMode => 'Delete mode';

  @override
  String get backupSettingHaptics => 'Vibration feedback';

  @override
  String get backupSettingSwipeButtons => 'Swipe buttons';

  @override
  String get backupSettingSessionSummary => 'Session summary';

  @override
  String get backupSettingBasicIncludeReviewed =>
      'Show reviewed files in Basic';

  @override
  String get backupSettingReviewedBadge => 'Reviewed badge';

  @override
  String get backupSettingActivePreset => 'Active preset';

  @override
  String get backupSettingActionBar => 'Action bar';

  @override
  String get backupSettingFoldersDropAction => 'Drop on a folder';

  @override
  String get backupSettingSimilarEnabled => 'Similar photos';

  @override
  String get backupSettingSimilarStrictness => 'Similar photos strictness';

  @override
  String get backupSettingSimilarBlur => 'Blurry photo threshold';

  @override
  String get backupSettingSimilarScreenshots =>
      'Include screenshots in similar photos';

  @override
  String get backupSettingAiWifiOnly => 'Download models on Wi-Fi only';

  @override
  String get backupSettingStripLocation => 'Remove location when sharing';

  @override
  String get backupSettingOther => 'Other setting';

  @override
  String get apkInstall => 'Install';

  @override
  String get apkNewApp => 'New app';

  @override
  String apkUpdateFromTo(String from, String to) {
    return 'Update from $from to $to';
  }

  @override
  String get apkSameVersion => 'This version is already installed';

  @override
  String apkDowngrade(String installed) {
    return 'Older than the installed version ($installed)';
  }

  @override
  String get apkUnknownInstalled =>
      'Android will show whether this is a new app or an update';

  @override
  String get apkSignerMismatch =>
      'Signed by a different developer. Android will refuse this update. Uninstall the old app first (its data is lost).';

  @override
  String get apkSignerUnknown =>
      'Updates must be signed by the same developer.';

  @override
  String get apkTrustNote => 'Only install apps from sources you trust.';

  @override
  String get apkInvalid => 'This file isn\'t a valid app package.';

  @override
  String get apkNoSpace => 'Not enough space to inspect this file.';

  @override
  String apkReadFailed(String error) {
    return 'Couldn\'t read this file: $error';
  }

  @override
  String apkInstallFailed(String error) {
    return 'Couldn\'t start the installer: $error';
  }

  @override
  String get apkNoInstaller => 'No app on this device can install packages.';

  @override
  String get apkPermissionWhy =>
      'To install apps, Android asks you to allow KFM in \"Install unknown apps\". KFM never installs anything without Android\'s own confirmation.';

  @override
  String get apkOpenSettings => 'Open settings';

  @override
  String get apkPermissionDenied => 'Permission not granted.';

  @override
  String apkPackageLine(String package, String version) {
    return '$package · version $version';
  }

  @override
  String get updatesSectionTitle => 'Updates';

  @override
  String get updatesCheckSetting => 'Check for updates';

  @override
  String get updatesCheckSettingHelp =>
      'Once a day KFM asks GitHub if there\'s a newer version. Nothing about you or your files is sent; GitHub sees your IP address like any website.';

  @override
  String get updatesCheckNow => 'Check now';

  @override
  String updatesCurrentVersion(String version) {
    return 'Installed version $version';
  }

  @override
  String get updatesChecking => 'Checking…';

  @override
  String get updatesUpToDate => 'You\'re up to date';

  @override
  String get updatesNoReleases => 'No releases found';

  @override
  String updatesAvailable(String version) {
    return 'KFM $version is available';
  }

  @override
  String get updatesLastCheckFailed => 'Last check failed';

  @override
  String get updatesFailedOffline =>
      'Couldn\'t reach GitHub. Check your connection.';

  @override
  String get updatesFailedBusy => 'GitHub is busy. Try again later.';

  @override
  String updatesFailed(String error) {
    return 'Update check failed: $error';
  }

  @override
  String get updatesWhatsNew => 'What\'s new';

  @override
  String get updatesDownload => 'Download';

  @override
  String get updatesDismiss => 'Hide until the next version';

  @override
  String get updatesNoNotes => 'No release notes.';

  @override
  String get updatesNoBrowser => 'No browser app found';

  @override
  String updatesOpenFailed(String error) {
    return 'Couldn\'t open the page: $error';
  }

  @override
  String get cloudSettingsTitle => 'Cloud';

  @override
  String get cloudDestinations => 'Cloud destinations';

  @override
  String get cloudDestinationsNone =>
      'Save files into a folder of your cloud app';

  @override
  String cloudDestinationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count folders',
      one: '1 folder',
    );
    return '$_temp0';
  }

  @override
  String get cloudHowItWorks =>
      'KFM saves files into a folder of your cloud app (Google Drive, OneDrive, Dropbox…). The cloud app uploads them; KFM never signs in anywhere.';

  @override
  String get cloudEmpty => 'No cloud folders yet';

  @override
  String get cloudAdd => 'Add cloud folder';

  @override
  String cloudAdded(String name) {
    return 'Added $name';
  }

  @override
  String get cloudAddFailed => 'Couldn\'t keep access to that folder';

  @override
  String get cloudRename => 'Rename';

  @override
  String get cloudRemove => 'Remove';

  @override
  String cloudRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get cloudRemoveConfirm =>
      'KFM won\'t save files here any more. Files already in the cloud stay there.';

  @override
  String get cloudForgetUploads => 'Also forget which files were uploaded here';

  @override
  String get cloudNeedsReconnecting => 'Needs reconnecting';

  @override
  String get cloudReconnect => 'Reconnect';

  @override
  String get cloudNoFolderPicking =>
      'If your cloud app isn\'t listed in the folder picker, it doesn\'t let other apps save into its folders.';

  @override
  String cloudSavedToFolder(String name) {
    return 'Saved to $name';
  }

  @override
  String cloudVerified(String name) {
    return 'Verified in $name';
  }

  @override
  String cloudFailed(String reason) {
    return 'Failed: $reason';
  }

  @override
  String get cloudWaiting => 'Waiting';

  @override
  String cloudUploading(String name) {
    return 'Saving to $name…';
  }

  @override
  String get cloudVerifyFailed => 'Couldn\'t verify the copy — original kept';

  @override
  String get cloudVerifyUnavailable =>
      'Couldn\'t read the copy back — original kept';

  @override
  String get cloudCancelled => 'Cancelled';

  @override
  String get cloudDestinationRemovedError => 'Destination removed';

  @override
  String get cloudSourceGone => 'The file is gone';

  @override
  String get cloudSourceChanged => 'The file changed while it was copied';

  @override
  String get cloudUnsupported => 'This file can\'t be saved to the cloud';

  @override
  String get cloudLocationNotRemoved =>
      'Location couldn\'t be removed, so it wasn\'t uploaded';

  @override
  String get cloudCopyMissing => 'The cloud copy is missing — original kept';

  @override
  String get cloudNoSpace => 'The cloud app is out of space';

  @override
  String get cloudWriteError => 'The cloud app didn\'t accept the file';

  @override
  String cloudCopyLeftOver(String reason) {
    return '$reason. A copy was left in the cloud folder';
  }

  @override
  String get cloudOriginalNotFound => 'Original not found, nothing deleted';

  @override
  String get cloudGpsNote =>
      'Photos are uploaded without their location because KFM can\'t read it.';

  @override
  String get cloudGpsAllow => 'Allow';

  @override
  String get cloudGpsMoveTitle => 'Move without location?';

  @override
  String get cloudGpsMoveWarning =>
      'Location data may be removed from the cloud copy, and the original will be deleted.';

  @override
  String get cloudGpsMoveAnyway => 'Move anyway';

  @override
  String get cloudTransfersSection => 'Cloud';

  @override
  String get cloudTransfersEmpty =>
      'Nothing saved to the cloud in the last 7 days';

  @override
  String get cloudPickerGroup => 'Cloud';

  @override
  String cloudStartedCopy(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saving $count files to $name…',
      one: 'Saving 1 file to $name…',
    );
    return '$_temp0';
  }

  @override
  String cloudStartedMove(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moving $count files to $name…',
      one: 'Moving 1 file to $name…',
    );
    return '$_temp0';
  }

  @override
  String get cloudNothingToSend => 'These files can\'t be saved to the cloud';

  @override
  String cloudOriginalsKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count originals were kept',
      one: '1 original was kept',
    );
    return '$_temp0';
  }

  @override
  String cloudOriginalsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moved $count files',
      one: 'Moved 1 file',
    );
    return '$_temp0';
  }

  @override
  String get cloudDeleteOriginals => 'Delete originals';

  @override
  String get cloudOriginalNotDeleted => 'Original not deleted';

  @override
  String get cloudRetry => 'Retry';

  @override
  String get tutorialStepTrash => 'Swipe left to throw away';

  @override
  String get tutorialStepKeep => 'Swipe right to keep';

  @override
  String get tutorialStepUndo => 'Made a mistake? Tap Undo';

  @override
  String get tutorialSkip => 'Skip';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialDone => 'Done';

  @override
  String get tutorialDemoCard => 'Example photo';

  @override
  String get tutorialShowAgain => 'Show tutorial again';

  @override
  String get hintPresets =>
      'A preset saves your swipe setup and filter. Switch with one tap.';

  @override
  String get hintActionBar =>
      'Extra actions live here. Turn them off in Settings → Swiping.';

  @override
  String get hintDismiss => 'Close hint';

  @override
  String get cloudBadgeOnCloud =>
      'Uploaded by KFM (last known, not a live check)';

  @override
  String get cloudBadgeChanged => 'Changed since it was uploaded';

  @override
  String get cloudShowBadge => 'Show cloud icon';

  @override
  String cloudInfoUploaded(String destination, String date) {
    return 'Uploaded by KFM to $destination · $date';
  }

  @override
  String cloudInfoChanged(String destination) {
    return 'Changed since upload to $destination';
  }

  @override
  String cloudInfoRemoved(String destination) {
    return '$destination (removed)';
  }

  @override
  String get cloudFilterRow => 'Cloud';

  @override
  String get cloudFilterAny => 'Any';

  @override
  String get cloudFilterOn => 'On cloud';

  @override
  String get cloudFilterNotOn => 'Not on cloud';

  @override
  String get cloudSwipeOnCloud => 'Swipe files already on cloud';

  @override
  String get cloudSwipeOnCloudTitle => 'On cloud';

  @override
  String get backupUndoBlocked =>
      'the trash dialog was declined, so nothing changed';

  @override
  String fileOpInUse(String name) {
    return '$name is in use by another program';
  }

  @override
  String get fileOpNoTrash => 'This drive has no Recycle Bin';

  @override
  String deleteNoRecycleBin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'these $count files',
      one: 'this file',
    );
    return 'This drive has no Recycle Bin. Delete $_temp0 permanently?';
  }

  @override
  String get windowsRootsHint =>
      'KFM shows the photos, videos and files in these folders.';

  @override
  String get windowsRootsNotAvailable => 'Not available';

  @override
  String get windowsRootsAdd => 'Add folder';

  @override
  String get windowsRootsAddConfirm => 'Add';

  @override
  String windowsRootsRemove(String folder) {
    return 'Remove $folder';
  }

  @override
  String get windowsRootsReset => 'Reset to defaults';

  @override
  String get shareNotificationOpen => 'Open KFM';

  @override
  String get shareNotificationQuit => 'Quit';

  @override
  String get shareKeepsRunningTray =>
      'Sharing keeps running when you close the window. Stop it here or from the tray icon.';

  @override
  String get trayNoticeTitle => 'KFM keeps sharing';

  @override
  String get trayNoticeBody =>
      'KFM is still sharing this PC. Stop it from the tray icon.';

  @override
  String get settingsStopSharingOnClose =>
      'Stop sharing when the window closes';

  @override
  String get settingsStopSharingOnCloseHint =>
      'Otherwise KFM keeps sharing from the tray icon.';

  @override
  String get sharePublicNetwork => 'Your Wi-Fi is set to Public';

  @override
  String get sharePublicNetworkHint =>
      'Set it to Private to share. Windows Settings → Network & internet → Wi-Fi → your network → Private network.';

  @override
  String get shareFirewallTitle => 'Windows will ask about the firewall';

  @override
  String get shareFirewallBody =>
      'So your phone can reach this PC, Windows Firewall asks to allow KFM. Allow it on private networks only.';

  @override
  String get desktopNavSort => 'Sort';

  @override
  String get desktopNavDevices => 'Devices';

  @override
  String get desktopSidebarPlaces => 'Places';

  @override
  String get desktopSidebarCollections => 'Collections';

  @override
  String get desktopFavorites => 'Favorites';

  @override
  String get desktopSidebarCollapse => 'Collapse sidebar';

  @override
  String get desktopSidebarExpand => 'Expand sidebar';

  @override
  String get desktopNoPlaces => 'No folders yet';

  @override
  String get desktopDetailsNothing => 'Select a file to see its details';

  @override
  String desktopShortcutHint(String label, String keys) {
    return '$label ($keys)';
  }

  @override
  String desktopStatusItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String desktopStatusSelected(int count, String size) {
    return '$count selected · $size';
  }

  @override
  String get desktopSortHistory => 'History';

  @override
  String get desktopSortHistoryEmpty => 'Nothing sorted yet';

  @override
  String get desktopSortUndoToHere => 'Undo back to here';

  @override
  String desktopSortUndoManyTitle(int count) {
    return 'Undo $count actions?';
  }

  @override
  String desktopSortUndoManyBody(int count) {
    return 'The newest $count actions are undone one by one, back to the one you clicked.';
  }

  @override
  String desktopSortUndoManyConfirm(int count) {
    return 'Undo $count';
  }

  @override
  String get desktopSortSelectHint =>
      'Select files, then choose what to do with them';

  @override
  String desktopSortActed(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$label · $_temp0';
  }

  @override
  String get desktopLayoutLargeIcons => 'Large icons';

  @override
  String get desktopLayoutGrid => 'Grid';

  @override
  String get desktopLayoutDetails => 'Details';

  @override
  String get desktopQuickLook => 'Quick look';

  @override
  String get desktopClose => 'Close';

  @override
  String get desktopPrevious => 'Previous';

  @override
  String get desktopNext => 'Next';

  @override
  String desktopTypeFile(String ext) {
    return '$ext file';
  }

  @override
  String get desktopTypeUnknown => 'File';

  @override
  String get desktopTypeFolder => 'Folder';

  @override
  String desktopQuickLookTitle(String name, String size, String date) {
    return '$name · $size · $date';
  }

  @override
  String desktopSortLeft(int count) {
    return '$count left';
  }

  @override
  String get desktopBrowseBack => 'Back';

  @override
  String get desktopBrowseForward => 'Forward';

  @override
  String get desktopBrowseUp => 'Up one level';

  @override
  String get desktopBrowseOpen => 'Open';

  @override
  String get desktopBrowseEmptyFolder => 'This folder is empty';

  @override
  String get desktopBrowseSortThese => 'Sort these';

  @override
  String get desktopBrowseCopy => 'Copy';

  @override
  String get desktopBrowseCut => 'Cut';

  @override
  String get desktopBrowsePaste => 'Paste';

  @override
  String get desktopBrowseNothingIndexed => 'KFM hasn\'t found files here yet';

  @override
  String desktopDragCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String desktopDropMoveTo(String name) {
    return 'Move to $name';
  }

  @override
  String desktopDropCopyTo(String name) {
    return 'Copy to $name';
  }

  @override
  String desktopDropTag(String name) {
    return 'Add tag $name';
  }

  @override
  String get desktopDropFavorite => 'Add to Favorites';

  @override
  String get desktopDropSend => 'Send to a device';

  @override
  String get desktopDropTrash => 'Move to Trash';

  @override
  String get desktopDropCtrlHint => 'Hold Ctrl to copy';

  @override
  String get desktopDropNothing => 'Nothing to copy here';

  @override
  String desktopDragOffer(String files, String action) {
    return '$files · $action';
  }

  @override
  String desktopTrashAll(int count) {
    return 'All ($count)';
  }

  @override
  String desktopTrashGroup(String name, String summary) {
    return '$name · $summary';
  }

  @override
  String get desktopTrashRecycleBin => 'Recycle Bin';

  @override
  String get desktopTrashOriginalLocation => 'Original location';

  @override
  String get desktopTrashDeleted => 'Date deleted';

  @override
  String get desktopTrashDaysLeft => 'Kept for';

  @override
  String get desktopTrashWhere => 'Where';

  @override
  String get desktopRefresh => 'Refresh';

  @override
  String get desktopDevicesTitle => 'Connect a phone or another PC';

  @override
  String get desktopDevicesHint =>
      'Both devices need KFM and the same Wi-Fi. Nothing is shared until you choose below.';

  @override
  String get desktopDevicesShareHint =>
      'Show a QR code and a code for your phone';

  @override
  String get desktopDevicesConnectHint =>
      'Connect to a device that shows a code';

  @override
  String get desktopCompare => 'Compare';

  @override
  String desktopCompareTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return 'Compare $_temp0';
  }

  @override
  String get desktopCompareHint =>
      'Number keys switch Keep / Remove · zoom and pan move all photos together';

  @override
  String desktopCompareRemove(int count) {
    return 'Remove $count';
  }

  @override
  String get desktopCompareKeep => 'Keep';

  @override
  String get desktopCompareRemoveOne => 'Remove';

  @override
  String desktopCompareFacts(String size, String resolution, String date) {
    return '$size · $resolution · $date';
  }

  @override
  String get desktopZoomIn => 'Zoom in';

  @override
  String get desktopZoomOut => 'Zoom out';

  @override
  String get desktopZoomFit => 'Fit';

  @override
  String get desktopSortFavorite => 'Favorite';

  @override
  String get desktopSortTag => 'Tag…';

  @override
  String get backupSettingDesktopBrowseLayout => 'PC Browse view';

  @override
  String get backupSettingDesktopBrowseSort => 'PC Browse sort';

  @override
  String ejectWindowsInUse(String label) {
    return '$label is still in use by another program. Close it and try again.';
  }

  @override
  String ejectWindowsFailed(String label) {
    return 'Windows couldn\'t eject $label';
  }

  @override
  String desktopSystemDrive(String drive) {
    return 'Local disk ($drive)';
  }

  @override
  String driveUsbUnnamed(String drive) {
    return 'USB drive ($drive)';
  }

  @override
  String driveSdUnnamed(String drive) {
    return 'SD card ($drive)';
  }

  @override
  String driveRemovableUnnamed(String drive) {
    return 'Removable disk ($drive)';
  }

  @override
  String driveNetworkUnnamed(String drive) {
    return 'Network drive ($drive)';
  }

  @override
  String desktopSortPreset(String name) {
    return 'Preset: $name';
  }

  @override
  String get desktopSortManagePresets => 'Manage presets…';

  @override
  String get desktopSortSetup => 'Sort setup…';

  @override
  String get videoPlay => 'Play';

  @override
  String get videoPause => 'Pause';

  @override
  String get videoSoundOn => 'Turn sound on';

  @override
  String get videoSoundOff => 'Turn sound off';

  @override
  String desktopDragItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String opTreeMoved(int folders, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: 'Moved $folders folders',
      one: 'Moved 1 folder',
      zero: 'Moved',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files files',
      one: '1 file',
    );
    return '$_temp0 ($_temp1)';
  }

  @override
  String opTreeCopied(int folders, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: 'Copied $folders folders',
      one: 'Copied 1 folder',
      zero: 'Copied',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files files',
      one: '1 file',
    );
    return '$_temp0 ($_temp1)';
  }

  @override
  String get opFolderIntoItself => 'A folder can\'t go into itself';

  @override
  String get jobsChannelProgress => 'Transfers in progress';

  @override
  String get jobsChannelProgressDescription =>
      'Progress of copies and transfers while KFM is in the background';

  @override
  String get jobsChannelResults => 'Finished transfers';

  @override
  String get jobsChannelResultsDescription =>
      'Shows when a copy or transfer ends';

  @override
  String jobsReceivingFrom(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Receiving $count files from $device',
      one: 'Receiving 1 file from $device',
    );
    return '$_temp0';
  }

  @override
  String jobsCombinedTitle(int count, String percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers · $percent',
      one: '1 transfer · $percent',
    );
    return '$_temp0';
  }

  @override
  String jobsProgressLine(String done, String total) {
    return '$done of $total';
  }

  @override
  String jobsSpeedLine(String speed) {
    return '$speed/s';
  }

  @override
  String jobsTimeLeft(String time) {
    return '$time left';
  }

  @override
  String jobsMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min',
      one: '1 min',
    );
    return '$_temp0';
  }

  @override
  String jobsHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String jobsSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count s',
      one: '1 s',
    );
    return '$_temp0';
  }

  @override
  String jobsPausedOne(String title) {
    return 'Paused · $title';
  }

  @override
  String jobsPausedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers paused',
      one: '1 transfer paused',
    );
    return '$_temp0';
  }

  @override
  String get jobsPausedOpenKfm => 'Paused, open KFM to continue';

  @override
  String get jobsWaiting => 'Waiting';

  @override
  String jobsEndSent(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sent $count files to $device',
      one: 'Sent 1 file to $device',
    );
    return '$_temp0';
  }

  @override
  String jobsEndReceived(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Received $count files from $device',
      one: 'Received 1 file from $device',
    );
    return '$_temp0';
  }

  @override
  String jobsEndMovedTo(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moved $count files to $device',
      one: 'Moved 1 file to $device',
    );
    return '$_temp0';
  }

  @override
  String jobsEndMovedFrom(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moved $count files from $device',
      one: 'Moved 1 file from $device',
    );
    return '$_temp0';
  }

  @override
  String jobsEndCopied(int count, String place) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copied $count files to $place',
      one: 'Copied 1 file to $place',
    );
    return '$_temp0';
  }

  @override
  String jobsEndMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers finished',
      one: '1 transfer finished',
    );
    return '$_temp0';
  }

  @override
  String jobsEndFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files failed · Tap to see',
      one: '1 file failed · Tap to see',
    );
    return '$_temp0';
  }

  @override
  String get jobsNotificationsOff =>
      'Notifications are off: transfers keep running, but their progress only shows inside KFM.';

  @override
  String jobsIndicatorLabel(String title, String percent) {
    return '$title, $percent. Open transfers';
  }

  @override
  String get jobsQuitTitle => 'Quit KFM?';

  @override
  String jobsQuitBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count transfers are still running. Quitting stops them; you can continue them in Transfers next time.',
      one: '1 transfer is still running. Quitting stops it; you can continue it in Transfers next time.',
    );
    return '$_temp0';
  }

  @override
  String get jobsQuitAction => 'Quit';

  @override
  String get jobsQuitKeep => 'Keep running';

  @override
  String get trayNoticeTransfersTitle => 'KFM keeps transferring';

  @override
  String get trayNoticeTransfersBody =>
      'Transfers continue in the background. Open KFM again from the tray icon.';

  @override
  String jobsEndFailedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers failed',
      one: 'Transfer failed',
    );
    return '$_temp0';
  }

  @override
  String get desktopFileIcons => 'File icons';

  @override
  String get desktopFileIconsWindows => 'Windows';

  @override
  String get desktopFileIconsKfm => 'KFM';

  @override
  String get desktopIconChoiceTitle => 'Which file icons?';

  @override
  String get desktopIconChoiceBody =>
      'Pick how files and folders look. You can change this later in Settings.';

  @override
  String get desktopIconChoiceWindowsHint => 'The same icons as File Explorer';

  @override
  String get desktopIconChoiceKfmHint => 'KFM\'s own simple icons';

  @override
  String get desktopIconChoiceDone => 'Done';

  @override
  String get backupSettingFileIcons => 'File icons (desktop)';

  @override
  String get desktopHome => 'Home';

  @override
  String desktopTabSearch(String query) {
    return 'Search: $query';
  }

  @override
  String get desktopTabNew => 'New tab';

  @override
  String get desktopTabDuplicate => 'Duplicate tab';

  @override
  String get desktopTabClose => 'Close tab';

  @override
  String get desktopTabCloseOthers => 'Close other tabs';

  @override
  String get desktopTabCloseRight => 'Close tabs to the right';

  @override
  String get desktopTabReopen => 'Reopen closed tab';

  @override
  String desktopAddressNotFound(String path) {
    return 'KFM can\'t find \'$path\'. Check the spelling and try again.';
  }

  @override
  String get desktopAddressLabel => 'Address';

  @override
  String desktopSearchIn(String name) {
    return 'Search $name';
  }

  @override
  String desktopSearchNone(String query) {
    return 'No files match \'$query\'.';
  }

  @override
  String get desktopColumnFolder => 'Folder';

  @override
  String get desktopQuickAccess => 'Quick access';

  @override
  String get desktopPinToQuickAccess => 'Pin to Quick access';

  @override
  String get desktopUnpinFromQuickAccess => 'Unpin from Quick access';

  @override
  String get desktopThisPc => 'This PC';

  @override
  String get desktopConnectDevice => 'Connect a device';

  @override
  String get desktopOpenInNewTab => 'Open in new tab';

  @override
  String get desktopCmdNew => 'New';

  @override
  String get desktopCmdView => 'View';

  @override
  String get desktopCmdSortBy => 'Sort';

  @override
  String get desktopViewNavPane => 'Navigation pane';

  @override
  String get desktopViewHidden => 'Hidden items';

  @override
  String get desktopViewPreviewPane => 'Preview pane';

  @override
  String get desktopViewDetailsPane => 'Details pane';

  @override
  String get desktopSortAscending => 'Ascending';

  @override
  String get desktopSortDescending => 'Descending';

  @override
  String get desktopCopyAsPath => 'Copy as path';

  @override
  String desktopPathCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paths copied',
      one: 'Path copied',
    );
    return '$_temp0';
  }

  @override
  String get desktopOpenFileLocation => 'Open file location';

  @override
  String get desktopShowInExplorer => 'Show in Windows Explorer';

  @override
  String get desktopProperties => 'Properties';

  @override
  String get desktopOpenInKfm => 'Open in KFM viewer';

  @override
  String desktopStatusLeft(int count) {
    return '$count left';
  }

  @override
  String desktopStatusDriveFree(String drive, String free, String total) {
    return '$drive $free free of $total';
  }

  @override
  String get desktopFolderGone => 'This folder no longer exists.';

  @override
  String get trashPropsOriginalLocation => 'Original location';

  @override
  String get trashPropsDeleted => 'Deleted';

  @override
  String get trashPropsWaiting => 'Waiting, not in the Recycle Bin yet';

  @override
  String trashPropsSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0 · $size';
  }

  @override
  String get trashEmpty => 'Empty trash';

  @override
  String trashEmptyTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Delete $_temp0 forever?';
  }

  @override
  String trashEmptyBody(String size) {
    return '$size will be deleted, including files still waiting in KFM. This can\'t be undone.';
  }

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsSorting => 'Sorting';

  @override
  String get settingsFilesDisplay => 'Files & display';

  @override
  String get settingsSmart => 'Smart features';

  @override
  String get settingsStorageCleanup => 'Storage & cleanup';

  @override
  String get settingsConnectSharing => 'Connect & sharing';

  @override
  String get settingsPrivacyAccess => 'Privacy & access';

  @override
  String get settingsAboutAdvanced => 'About & advanced';

  @override
  String get thumbCacheHelp =>
      'Small previews KFM saves so folders open fast. Clear frees the space; your files aren\'t touched and the previews come back when needed.';

  @override
  String get errorLogHelp =>
      'Errors KFM ran into, without file names or paths. Share it to report a problem.';

  @override
  String get devSettingsHelp =>
      'Index tools for checking KFM on a device (debug builds only).';

  @override
  String get settingsShowSessionSummaryHelp =>
      'After Done, a short overview of what you kept, deleted and moved.';

  @override
  String get reviewedResetHelp =>
      'Files you already sorted show up as new again. Nothing is deleted.';

  @override
  String get settingsFreshStartHelp =>
      'Choose what to clear: the current session, history, tags or everything.';

  @override
  String get tutorialShowAgainHelp =>
      'The short swipe tutorial and the one-time tips once more.';

  @override
  String get settingsDropActionHelp =>
      'What happens when you drag files onto a folder.';

  @override
  String get storageBigFileThresholdHelp =>
      'Used by the big-file highlight and Storage → Big files.';

  @override
  String get settingsDeleteMode => 'When you delete';

  @override
  String get settingsDeleteModeHelp =>
      'Move deleted files to the trash, or delete them for good.';

  @override
  String get settingsPermissionsHelp =>
      'What KFM may read on this phone, and a button to change it.';

  @override
  String get backupRestoreTitle => 'Backup & restore';

  @override
  String get backupRestoreHelp =>
      'Moves your tags, favorites, presets and settings to another device. Files are not copied.';

  @override
  String get cloudDestinationsHelp =>
      'Cloud apps on this device that KFM can send files to.';

  @override
  String get connectADevice => 'Connect a device';

  @override
  String get connectADeviceHelp =>
      'See and send files between your phone and PC over Wi-Fi.';

  @override
  String get transfersSettingHelp =>
      'Every Wi-Fi transfer, running and finished.';

  @override
  String get privacyDevicesTitle => 'Devices that can see your files';

  @override
  String get privacyDevicesHelp =>
      'Remembered devices and what they may do. Forget one to block it.';

  @override
  String get privacyNeverTitle => 'What KFM never does';

  @override
  String get privacyNeverBody =>
      'No ads, no account, no tracking. KFM never uploads your files: only devices you connect and cloud apps you choose get them.';

  @override
  String get a11yScreenReaderTitle => 'Screen readers';

  @override
  String get a11yScreenReaderBody =>
      'File tiles read their name, type, size and date. Swipe cards offer their actions in the actions menu.';

  @override
  String get settingsKeywordsTheme => 'dark,light,night,mode,appearance';

  @override
  String get settingsKeywordsAccent => 'colour,color,accent';

  @override
  String get settingsKeywordsTextSize => 'font,big text,zoom,larger';

  @override
  String get settingsKeywordsThumbCache => 'cache,previews,space,free up';

  @override
  String get settingsKeywordsVersion => 'version,about,app';

  @override
  String get settingsKeywordsPermissions => 'permission,access,allow,storage';

  @override
  String get settingsKeywordsSimilar => 'duplicates,blurry,similar';

  @override
  String get settingsKeywordsAiLabels =>
      'ai,labels,recognition,models,download';

  @override
  String get settingsKeywordsLocation => 'location,gps,place,exif';

  @override
  String get settingsKeywordsBackup => 'export,import,restore,backup';

  @override
  String get settingsKeywordsCloud => 'cloud,drive,onedrive,upload';

  @override
  String get settingsKeywordsConnect => 'share,wifi,pc,phone,qr,send';

  @override
  String get settingsKeywordsPrivacy => 'privacy,tracking,ads,upload';

  @override
  String get settingsKeywordsScreenReader =>
      'talkback,narrator,blind,screen reader';

  @override
  String get settingsKeywordsBigFiles => 'big,large,size,threshold';

  @override
  String get settingsSearchHint => 'Search settings';

  @override
  String get settingsSearchClear => 'Clear search';

  @override
  String get settingsSummarySeparator => ', ';

  @override
  String get settingsSearchEmpty => 'No setting matches. Try another word.';

  @override
  String get privacyTransferNote =>
      'Location info is removed (Settings → Privacy & access)';

  @override
  String durationShortSeconds(int count) {
    return '$count s';
  }

  @override
  String durationShortMinutes(int count) {
    return '$count min';
  }

  @override
  String durationShortMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String durationShortHours(int count) {
    return '$count h';
  }

  @override
  String durationShortHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get unitSecondsShort => 's';

  @override
  String get unitMinutesShort => 'min';

  @override
  String get unitHoursShort => 'h';

  @override
  String get unitMegabytesShort => 'MB';

  @override
  String get unitGigabytesShort => 'GB';

  @override
  String get unitInputAmount => 'Amount';

  @override
  String unitInputRange(String min, String max) {
    return 'Enter a value from $min to $max';
  }

  @override
  String get unitInputSave => 'Save';

  @override
  String bigFileThresholdLine(String size) {
    return 'Files of $size or more count as big';
  }

  @override
  String get settingsHighlightBigLine =>
      'Big files get a red size label, even with sizes off';

  @override
  String get settingsSameTimeWindowAbout =>
      'Browse → Same time groups photos and videos taken this close together';

  @override
  String sameTimeWindowLine(String time) {
    return 'Photos and videos taken within $time of each other are grouped';
  }

  @override
  String get deleteModeTrashHelpDevice =>
      'Deleted files go to the trash and can be restored.';

  @override
  String similarStartBodyOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'KFM checks your photos on this phone, groups look-alikes and suggests the sharpest one to keep. Nothing leaves the phone and nothing is removed unless you choose it.',
      'pc': 'KFM checks your photos on this PC, groups look-alikes and suggests the sharpest one to keep. Nothing leaves the PC and nothing is removed unless you choose it.',
      'other': 'KFM checks your photos on this device, groups look-alikes and suggests the sharpest one to keep. Nothing leaves the device and nothing is removed unless you choose it.',
    });
    return '$_temp0';
  }

  @override
  String aiLabelsEnableOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'Label photos on this phone',
      'pc': 'Label photos on this PC',
      'other': 'Label photos on this device',
    });
    return '$_temp0';
  }

  @override
  String aiLabelsHelpOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'Runs on this phone only. No photo or result ever leaves it.',
      'pc': 'Runs on this PC only. No photo or result ever leaves it.',
      'other': 'Runs on this device only. No photo or result ever leaves it.',
    });
    return '$_temp0';
  }

  @override
  String aiLabelsWorkerErrorOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'Labeling couldn\'t start on this phone.',
      'pc': 'Labeling couldn\'t start on this PC.',
      'other': 'Labeling couldn\'t start on this device.',
    });
    return '$_temp0';
  }

  @override
  String aiLabelsCardBodyOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'KFM can label your photos on this phone. Nothing is uploaded.',
      'pc': 'KFM can label your photos on this PC. Nothing is uploaded.',
      'other': 'KFM can label your photos on this device. Nothing is uploaded.',
    });
    return '$_temp0';
  }

  @override
  String aiModelsHowBodyOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'Each photo\'s small thumbnail is analysed on this phone, once, in the background. Only label words like \"cat\" are stored in KFM\'s database.',
      'pc': 'Each photo\'s small thumbnail is analysed on this PC, once, in the background. Only label words like \"cat\" are stored in KFM\'s database.',
      'other': 'Each photo\'s small thumbnail is analysed on this device, once, in the background. Only label words like \"cat\" are stored in KFM\'s database.',
    });
    return '$_temp0';
  }

  @override
  String aiModelsPrivacyBodyOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'Runs fully on this phone. No photo, thumbnail or result ever leaves it. No account, no tracking. The only network use is this one download.',
      'pc': 'Runs fully on this PC. No photo, thumbnail or result ever leaves it. No account, no tracking. The only network use is this one download.',
      'other': 'Runs fully on this device. No photo, thumbnail or result ever leaves it. No account, no tracking. The only network use is this one download.',
    });
    return '$_temp0';
  }

  @override
  String detailsAddedOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'Added to phone',
      'pc': 'Added to PC',
      'other': 'Added to device',
    });
    return '$_temp0';
  }

  @override
  String errorLogShareSubtitleOn(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count errors',
      one: '1 error',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count errors',
      one: '1 error',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count errors',
      one: '1 error',
    );
    String _temp3 = intl.Intl.selectLogic(device, {
      'phone':
          '$_temp0. Stays on this phone until you share it. Folder and file names are hidden.',
      'pc':
          '$_temp1. Stays on this PC until you share it. Folder and file names are hidden.',
      'other':
          '$_temp2. Stays on this device until you share it. Folder and file names are hidden.',
    });
    return '$_temp3';
  }

  @override
  String transfersLocalSectionOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'On this phone',
      'pc': 'On this PC',
      'other': 'On this device',
    });
    return '$_temp0';
  }

  @override
  String get cloudBadgeHelpDevice =>
      'The cloud icon means KFM handed this file to your cloud app. KFM remembers that here, so it shows offline too. It isn\'t a live check: KFM can\'t see whether the upload finished or whether the copy was deleted later. If the file changes after upload, the icon changes too. Only files uploaded with KFM are marked.';

  @override
  String get aiLabelsUnsupportedWindows =>
      'Not available on Windows yet. On Android, KFM can find photos by what\'s in them.';

  @override
  String get aiModelsDownloadInline => 'Download';

  @override
  String get aiModelsHowItWorks => 'How it works';

  @override
  String get whereKfmLooksTitle => 'Where KFM looks';

  @override
  String get whereKfmLooksHelp =>
      'The private list of your files that Search, Sort and Storage use. It never leaves this device.';

  @override
  String get whereKfmLooksPhoneBody =>
      'KFM keeps a private list of the photos, videos and files Android shows it, so Search, Swipe and Storage cover your whole phone. The list stays on this phone and is never uploaded. KFM never changes or moves anything by looking.';

  @override
  String get lookEverywhereTitle => 'Look everywhere';

  @override
  String get lookEverywhereOnHelp =>
      'KFM keeps a private list of your photos, videos and files on this PC so Search, Sort, Storage and Similar photos cover everything. The list stays on this PC. KFM never uploads, changes or moves anything by looking, and skips Windows and program folders.';

  @override
  String get lookEverywhereOffHelp =>
      'KFM only looks in the folder you have open. Search and Sort cover that folder.';

  @override
  String get lookEverywhereChosenHelp =>
      'KFM only looks in the folders below. Turn this on to cover all your files.';

  @override
  String get lookEverywhereChoose => 'Choose folders instead…';

  @override
  String get lookEverywhereOffConfirmTitle => 'Only look where you are?';

  @override
  String get lookEverywhereOffConfirmBody =>
      'Search and Sort will only cover folders you open. Tags, favorites and reviewed marks are kept.';

  @override
  String get lookEverywhereOffConfirm => 'Only open folders';

  @override
  String get settingsKeywordsIndex =>
      'index,scan,folders,look everywhere,search';

  @override
  String get languageStepTitle => 'Choose your language';

  @override
  String get languageStepBody =>
      'You can change it later in Settings → General.';

  @override
  String languageSystemNamed(String language) {
    return 'System ($language)';
  }

  @override
  String get languageStepContinue => 'Continue';

  @override
  String get leftHandedThumbHelp =>
      'Puts Undo, the main buttons and the selection bar on the left, where your thumb is. Swipe directions don\'t change.';

  @override
  String get reduceMotionTitle => 'Reduce motion';

  @override
  String get reduceMotionHelp =>
      'Swiped cards fade instead of flying away, and screens change without sliding. Also follows the system setting.';

  @override
  String get highContrastTitle => 'High contrast';

  @override
  String get highContrastHelp =>
      'Stronger colors for text, buttons and outlines. Also follows the system setting.';

  @override
  String get backupSettingReduceMotion => 'Reduce motion';

  @override
  String get backupSettingHighContrast => 'High contrast';

  @override
  String get settingsKeywordsMotion => 'animation,motion,vestibular,fade';

  @override
  String get settingsKeywordsContrast => 'contrast,colors,low vision';

  @override
  String a11yFileLabel(String name, String kind, String size, String date) {
    return '$name, $kind, $size, $date';
  }

  @override
  String get a11yKindAudio => 'Audio';

  @override
  String get a11yKindDocument => 'Document';

  @override
  String a11yKindDocumentExt(String ext) {
    return '$ext document';
  }

  @override
  String get a11yKindArchive => 'Archive';

  @override
  String get a11yKindFile => 'File';

  @override
  String a11yKindFileExt(String ext) {
    return '$ext file';
  }

  @override
  String get desktopFileIconsHint =>
      'How files and folders look in the lists: Windows\' own icons or KFM\'s.';

  @override
  String desktopDiskCapped(int count) {
    return 'Showing the first $count files of this folder.';
  }

  @override
  String get desktopPreviewNothing => 'Select a file to preview it';

  @override
  String get desktopCmdMore => 'More';

  @override
  String get desktopSelectAll => 'Select all';

  @override
  String folderLabel(String folder, String place) {
    return '$folder · $place';
  }

  @override
  String swipeFolderSemantics(String folder) {
    return 'Folder: $folder';
  }

  @override
  String get swipeFolderDetails => 'Details';

  @override
  String get settingsSwipeShowFolder => 'Show the file\'s folder';

  @override
  String get settingsSwipeShowFolderHelp =>
      'One line above the card. Tap it to copy the path or open the folder.';

  @override
  String get backupSettingSwipeShowFolder => 'Show the file\'s folder';

  @override
  String get browseRefreshFailed => 'Couldn\'t refresh. Try again.';

  @override
  String get sameTimeChangeWindow => 'Change window';

  @override
  String get shareInfoTooltip => 'About sharing';

  @override
  String receivedSavedOne(String name, String folder) {
    return '$name saved to $folder';
  }

  @override
  String receivedSavedMany(int count, String folder) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files saved to $folder',
      one: '1 file saved to $folder',
    );
    return '$_temp0';
  }

  @override
  String get showInFolder => 'Show in folder';

  @override
  String get receiveFolderTitle => 'Received files go to';

  @override
  String get receiveFolderReset => 'Use the default folder';

  @override
  String get receiveFolderHelp =>
      'Files other devices send you land here, in a folder per device.';

  @override
  String linkSendTo(String device) {
    return 'Send to $device';
  }

  @override
  String linkSending(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sending $count files to $device',
      one: 'Sending 1 file to $device',
    );
    return '$_temp0';
  }

  @override
  String linkSendFailed(String device) {
    return 'Couldn\'t send to $device. Try again.';
  }

  @override
  String linkConnectedTo(String device) {
    return 'Connected to $device';
  }

  @override
  String get linkOpen => 'Open';

  @override
  String get linkNearbyDevices => 'Nearby devices';

  @override
  String get linkNearbyDevicesHint => 'Connect a phone or PC';

  @override
  String linkReconnectTo(String device) {
    return 'Connect to $device';
  }

  @override
  String linkReconnecting(String device) {
    return 'Connecting to $device…';
  }

  @override
  String linkLetSee(String device) {
    return 'Let $device see my files';
  }

  @override
  String get linkLetSeeHint =>
      'It can browse all your files on this device. You can still send files either way.';

  @override
  String linkLetTake(String device) {
    return 'Let $device take files without asking';
  }

  @override
  String get linkLetTakeHint =>
      'Otherwise you\'re asked first and see each file\'s name, size and type.';

  @override
  String linkYourChoices(String device) {
    return 'What $device may do with your files:';
  }

  @override
  String takePromptTitle(String device, int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$device wants to take $_temp0 ($size)';
  }

  @override
  String takePromptMoveTitle(String device, int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$device wants to move $_temp0 ($size)';
  }

  @override
  String get takePromptMoveNote =>
      'The originals go to the trash here once the copies are checked.';

  @override
  String takePromptFileLine(String size, String type) {
    return '$size · $type';
  }

  @override
  String takePromptAlways(String device) {
    return 'Always allow $device';
  }

  @override
  String get takePromptAllow => 'Allow';

  @override
  String takePromptTimedOut(String device) {
    return '$device\'s request ended: no answer';
  }

  @override
  String transferErrorTakeDeclined(String device) {
    return 'Declined by $device';
  }

  @override
  String transferErrorTakeNoAnswer(String device) {
    return 'No answer from $device';
  }

  @override
  String linkOneWay(String device) {
    return '$device can\'t be reached from here: you can still send it files.';
  }

  @override
  String linkTheySeeYours(String device) {
    return '$device can see your files';
  }

  @override
  String linkTheyDontSeeYours(String device) {
    return '$device can\'t see your files';
  }

  @override
  String get linkLimitFolders => 'Limit to folders…';

  @override
  String linkSeeTheirFiles(String device) {
    return 'Browse $device';
  }

  @override
  String get linkShowMyCode =>
      'Or connect from the other device with this code';

  @override
  String get linkTitle => 'Connect a device';

  @override
  String get linkShowCode => 'Show my code';

  @override
  String get linkShowCodeHint =>
      'The other device scans or types it. Then you both see each other\'s files.';

  @override
  String get viewerMore => 'More';

  @override
  String get viewerOpen => 'Open';

  @override
  String viewerOpenDownloading(String name) {
    return 'Downloading $name to open it';
  }

  @override
  String viewerOpenFailed(String name) {
    return 'Couldn\'t download $name';
  }
}
