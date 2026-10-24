import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Kaf\'s File Manager'**
  String get appTitle;

  /// No description provided for @appTitleShort.
  ///
  /// In en, this message translates to:
  /// **'KFM'**
  String get appTitleShort;

  /// No description provided for @tabSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe'**
  String get tabSwipe;

  /// No description provided for @tabBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get tabBrowse;

  /// No description provided for @tabTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get tabTrash;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @browsePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Browsing is coming soon.'**
  String get browsePlaceholder;

  /// No description provided for @dbWriteError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your last change.'**
  String get dbWriteError;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// Chip shown while the media index scans the device.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Indexing 1 file…} other{Indexing {count} files…}}'**
  String indexingCount(int count);

  /// No description provided for @indexingPaused.
  ///
  /// In en, this message translates to:
  /// **'Indexing paused'**
  String get indexingPaused;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutPromise.
  ///
  /// In en, this message translates to:
  /// **'No ads, no account, no tracking. Everything stays on your device.'**
  String get aboutPromise;

  /// No description provided for @permGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Let KFM see your photos and videos'**
  String get permGateTitle;

  /// No description provided for @permGateWhy.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on your phone. No account, no upload.'**
  String get permGateWhy;

  /// No description provided for @permAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get permAllow;

  /// No description provided for @permOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get permOpenSettings;

  /// No description provided for @permPermanentlyDeniedHelp.
  ///
  /// In en, this message translates to:
  /// **'Photo access is turned off. In settings, open Permissions and allow Photos and videos.'**
  String get permPermanentlyDeniedHelp;

  /// No description provided for @permCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check the permissions.'**
  String get permCheckFailed;

  /// No description provided for @limitedBanner.
  ///
  /// In en, this message translates to:
  /// **'KFM can only see some photos.'**
  String get limitedBanner;

  /// No description provided for @limitedAllowAll.
  ///
  /// In en, this message translates to:
  /// **'Allow all'**
  String get limitedAllowAll;

  /// No description provided for @allFilesSheetText.
  ///
  /// In en, this message translates to:
  /// **'To show documents and downloads too, turn on All files access.'**
  String get allFilesSheetText;

  /// No description provided for @allFilesTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get allFilesTurnOn;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @settingsPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get settingsPermissions;

  /// No description provided for @permRowMedia.
  ///
  /// In en, this message translates to:
  /// **'Photos and videos'**
  String get permRowMedia;

  /// No description provided for @permRowAllFiles.
  ///
  /// In en, this message translates to:
  /// **'All files access'**
  String get permRowAllFiles;

  /// No description provided for @permRowMediaManagement.
  ///
  /// In en, this message translates to:
  /// **'Skip confirmation dialogs'**
  String get permRowMediaManagement;

  /// No description provided for @permRowMediaManagementHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional. Lets KFM move and delete photos without asking each time (Media management).'**
  String get permRowMediaManagementHelp;

  /// No description provided for @permStatusGranted.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get permStatusGranted;

  /// No description provided for @permStatusLimited.
  ///
  /// In en, this message translates to:
  /// **'Some photos only'**
  String get permStatusLimited;

  /// No description provided for @permStatusDenied.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get permStatusDenied;

  /// No description provided for @permStatusNotAsked.
  ///
  /// In en, this message translates to:
  /// **'Not asked yet'**
  String get permStatusNotAsked;

  /// No description provided for @permStatusNotRequired.
  ///
  /// In en, this message translates to:
  /// **'Not needed on this phone'**
  String get permStatusNotRequired;

  /// No description provided for @permChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get permChange;

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// No description provided for @thumbCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail cache'**
  String get thumbCacheTitle;

  /// No description provided for @thumbCacheSizeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Size unknown'**
  String get thumbCacheSizeUnknown;

  /// No description provided for @thumbCacheClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get thumbCacheClear;

  /// No description provided for @settingsDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get settingsDeveloper;

  /// No description provided for @devIndexedFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file in the index} other{{count} files in the index}}'**
  String devIndexedFiles(int count);

  /// No description provided for @devRescan.
  ///
  /// In en, this message translates to:
  /// **'Full rescan'**
  String get devRescan;

  /// No description provided for @devIndexList.
  ///
  /// In en, this message translates to:
  /// **'Show indexed files'**
  String get devIndexList;

  /// No description provided for @swipeAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done! You\'ve gone through every photo and video.'**
  String get swipeAllDone;

  /// No description provided for @swipeEmptyLibrary.
  ///
  /// In en, this message translates to:
  /// **'No photos or videos found.'**
  String get swipeEmptyLibrary;

  /// No description provided for @swipeLookingForPhotos.
  ///
  /// In en, this message translates to:
  /// **'Looking for photos…'**
  String get swipeLookingForPhotos;

  /// No description provided for @swipeErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your photos.'**
  String get swipeErrorGeneric;

  /// No description provided for @swipeDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get swipeDone;

  /// No description provided for @swipeFinishTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish this session?'**
  String get swipeFinishTitle;

  /// No description provided for @swipeFinishConfirm.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get swipeFinishConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @undoHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent actions'**
  String get undoHistoryTitle;

  /// No description provided for @undoRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored from the trash'**
  String get undoRestored;

  /// No description provided for @undoPermanentlyDeleted.
  ///
  /// In en, this message translates to:
  /// **'This file was permanently deleted and can\'t come back.'**
  String get undoPermanentlyDeleted;

  /// No description provided for @undoFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t undo this step.'**
  String get undoFailed;

  /// No description provided for @undoNotPossibleYet.
  ///
  /// In en, this message translates to:
  /// **'Undoing this isn\'t possible yet.'**
  String get undoNotPossibleYet;

  /// No description provided for @deleteBatchRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get deleteBatchRetry;

  /// No description provided for @deleteCommitFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete files right now. They stay queued and nothing is lost.'**
  String get deleteCommitFailed;

  /// No description provided for @swipeProgress.
  ///
  /// In en, this message translates to:
  /// **'{swiped} done · {remaining} left'**
  String swipeProgress(int swiped, int remaining);

  /// No description provided for @swipeFinishTrash.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing is waiting to be deleted.} =1{1 file will be moved to the trash.} other{{count} files will be moved to the trash.}}'**
  String swipeFinishTrash(int count);

  /// No description provided for @swipeFinishPermanent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing is waiting to be deleted.} =1{1 file will be deleted permanently.} other{{count} files will be deleted permanently.}}'**
  String swipeFinishPermanent(int count);

  /// No description provided for @sessionSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Session finished.} =1{Session finished: 1 file deleted, {size} freed.} other{Session finished: {count} files deleted, {size} freed.}}'**
  String sessionSummary(int count, String size);

  /// No description provided for @deleteBatchWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file waiting to be deleted} other{{count} files waiting to be deleted}}'**
  String deleteBatchWaiting(int count);

  /// No description provided for @deleteBatchFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file couldn\'t be deleted} other{{count} files couldn\'t be deleted}}'**
  String deleteBatchFailed(int count);

  /// No description provided for @settingsDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting'**
  String get settingsDeleting;

  /// No description provided for @deleteModeTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to trash (recommended)'**
  String get deleteModeTrash;

  /// No description provided for @deleteModeTrashHelp.
  ///
  /// In en, this message translates to:
  /// **'Swiped files go to the phone\'s trash and can be restored.'**
  String get deleteModeTrashHelp;

  /// No description provided for @deleteModePermanent.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteModePermanent;

  /// No description provided for @deleteModePermanentHelp.
  ///
  /// In en, this message translates to:
  /// **'Swiped files are deleted for good. No recovery.'**
  String get deleteModePermanentHelp;

  /// No description provided for @deleteModePermanentWarning.
  ///
  /// In en, this message translates to:
  /// **'Files deleted this way can\'t be restored, not even with undo.'**
  String get deleteModePermanentWarning;

  /// No description provided for @deleteModeNextSession.
  ///
  /// In en, this message translates to:
  /// **'Applies to your next session.'**
  String get deleteModeNextSession;

  /// No description provided for @pendingRetentionLabel.
  ///
  /// In en, this message translates to:
  /// **'Keep pending files for'**
  String get pendingRetentionLabel;

  /// No description provided for @pendingRetentionHelp.
  ///
  /// In en, this message translates to:
  /// **'Documents and other files (and photos on Android 10 and older) wait in a hidden folder before they are deleted for good.'**
  String get pendingRetentionHelp;

  /// No description provided for @pendingEmptyNow.
  ///
  /// In en, this message translates to:
  /// **'Empty pending folder now'**
  String get pendingEmptyNow;

  /// No description provided for @pendingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete everything in the pending folder?'**
  String get pendingEmptyTitle;

  /// No description provided for @pendingEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'These files can\'t be restored afterwards.'**
  String get pendingEmptyBody;

  /// No description provided for @pendingEmptyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get pendingEmptyConfirm;

  /// No description provided for @permanentConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently this session?'**
  String get permanentConfirmTitle;

  /// No description provided for @permanentConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Files you swipe to trash will be deleted forever. They can\'t be restored.'**
  String get permanentConfirmBody;

  /// No description provided for @permanentConfirmYes.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get permanentConfirmYes;

  /// No description provided for @permanentConfirmUseTrash.
  ///
  /// In en, this message translates to:
  /// **'Use trash instead'**
  String get permanentConfirmUseTrash;

  /// No description provided for @pendingRetentionDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String pendingRetentionDays(int count);

  /// No description provided for @pendingEmptied.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{The pending folder is empty.} =1{1 file deleted.} other{{count} files deleted.}}'**
  String pendingEmptied(int count);

  /// No description provided for @trashSystem.
  ///
  /// In en, this message translates to:
  /// **'System trash'**
  String get trashSystem;

  /// No description provided for @trashPending.
  ///
  /// In en, this message translates to:
  /// **'Pending delete'**
  String get trashPending;

  /// No description provided for @trashNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get trashNothingHere;

  /// No description provided for @trashExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get trashExpiresToday;

  /// No description provided for @trashSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get trashSelect;

  /// No description provided for @trashRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get trashRestore;

  /// No description provided for @trashDeleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get trashDeleteForever;

  /// No description provided for @trashDeleteForeverBody.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get trashDeleteForeverBody;

  /// No description provided for @trashEmptySection.
  ///
  /// In en, this message translates to:
  /// **'Empty this section'**
  String get trashEmptySection;

  /// No description provided for @trashCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get trashCancelled;

  /// No description provided for @trashAlreadyRemoved.
  ///
  /// In en, this message translates to:
  /// **'Some items were already removed.'**
  String get trashAlreadyRemoved;

  /// No description provided for @trashSystemHelp.
  ///
  /// In en, this message translates to:
  /// **'Photos and videos are kept by Android for 30 days. Your gallery app may also have its own bin.'**
  String get trashSystemHelp;

  /// No description provided for @trashLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the trash.'**
  String get trashLoadFailed;

  /// No description provided for @trashNeedsPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow access to photos and videos to see the trash.'**
  String get trashNeedsPermission;

  /// No description provided for @trashDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
  String trashDaysLeft(int count);

  /// No description provided for @trashDeleteForeverTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 item forever?} other{Delete {count} items forever?}}'**
  String trashDeleteForeverTitle(int count);

  /// No description provided for @trashRestored.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item restored} other{{count} items restored}}'**
  String trashRestored(int count);

  /// No description provided for @trashSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String trashSelectedCount(int count);

  /// No description provided for @trashSectionSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}} · {size}'**
  String trashSectionSummary(int count, String size);

  /// No description provided for @labelTrash.
  ///
  /// In en, this message translates to:
  /// **'→ Trash'**
  String get labelTrash;

  /// No description provided for @labelDelete.
  ///
  /// In en, this message translates to:
  /// **'→ Delete'**
  String get labelDelete;

  /// No description provided for @labelKept.
  ///
  /// In en, this message translates to:
  /// **'→ Kept'**
  String get labelKept;

  /// No description provided for @labelFavorite.
  ///
  /// In en, this message translates to:
  /// **'★ Favorite'**
  String get labelFavorite;

  /// No description provided for @labelRenameBatch.
  ///
  /// In en, this message translates to:
  /// **'→ Rename batch'**
  String get labelRenameBatch;

  /// No description provided for @settingsSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swiping'**
  String get settingsSwipe;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsHelp.
  ///
  /// In en, this message translates to:
  /// **'A short vibration when a swipe is done.'**
  String get settingsHapticsHelp;

  /// No description provided for @labelMovedTo.
  ///
  /// In en, this message translates to:
  /// **'→ {folder}'**
  String labelMovedTo(String folder);

  /// No description provided for @labelCopiedTo.
  ///
  /// In en, this message translates to:
  /// **'⧉ {folder}'**
  String labelCopiedTo(String folder);

  /// No description provided for @labelTagged.
  ///
  /// In en, this message translates to:
  /// **'# {tag}'**
  String labelTagged(String tag);

  /// No description provided for @labelSentTo.
  ///
  /// In en, this message translates to:
  /// **'→ {device}'**
  String labelSentTo(String device);

  /// No description provided for @restoredSnack.
  ///
  /// In en, this message translates to:
  /// **'Continued where you left off'**
  String get restoredSnack;

  /// No description provided for @restoredStartFresh.
  ///
  /// In en, this message translates to:
  /// **'Start fresh'**
  String get restoredStartFresh;

  /// No description provided for @clearMenu.
  ///
  /// In en, this message translates to:
  /// **'Clear…'**
  String get clearMenu;

  /// No description provided for @clearResetLayout.
  ///
  /// In en, this message translates to:
  /// **'Reset action buttons'**
  String get clearResetLayout;

  /// No description provided for @clearResetLayoutHelp.
  ///
  /// In en, this message translates to:
  /// **'Back to: left = trash, right = keep'**
  String get clearResetLayoutHelp;

  /// No description provided for @clearNewSession.
  ///
  /// In en, this message translates to:
  /// **'Start a new session'**
  String get clearNewSession;

  /// No description provided for @clearNewSessionHelp.
  ///
  /// In en, this message translates to:
  /// **'Ends the progress and undo history of this session.'**
  String get clearNewSessionHelp;

  /// No description provided for @clearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearConfirm;

  /// No description provided for @layoutResetDone.
  ///
  /// In en, this message translates to:
  /// **'Action buttons reset'**
  String get layoutResetDone;

  /// No description provided for @undoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoAction;

  /// No description provided for @newSessionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t finish the deletes, so this session continues. Try again.'**
  String get newSessionFailed;

  /// No description provided for @settingsFreshStart.
  ///
  /// In en, this message translates to:
  /// **'Clear / fresh start…'**
  String get settingsFreshStart;

  /// No description provided for @newFilesChip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new photo · Show} other{{count} new photos · Show}}'**
  String newFilesChip(int count);

  /// No description provided for @clearNewSessionDeletes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing is waiting to be deleted.} =1{1 waiting delete will be done.} other{{count} waiting deletes will be done.}}'**
  String clearNewSessionDeletes(int count);

  /// No description provided for @viewerClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get viewerClose;

  /// No description provided for @videoCantPlay.
  ///
  /// In en, this message translates to:
  /// **'Can\'t play this video'**
  String get videoCantPlay;

  /// No description provided for @videoTapForSound.
  ///
  /// In en, this message translates to:
  /// **'Tap for sound'**
  String get videoTapForSound;

  /// No description provided for @videoOpenFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Open fullscreen'**
  String get videoOpenFullscreen;

  /// No description provided for @customizeSwipes.
  ///
  /// In en, this message translates to:
  /// **'Customize swipes'**
  String get customizeSwipes;

  /// No description provided for @customizeSwipesHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose what each swipe direction does'**
  String get customizeSwipesHelp;

  /// No description provided for @customizeSwipesIntro.
  ///
  /// In en, this message translates to:
  /// **'Tap an arrow to change what swiping that way does.'**
  String get customizeSwipesIntro;

  /// No description provided for @swipeDirectionLeft.
  ///
  /// In en, this message translates to:
  /// **'Swipe left'**
  String get swipeDirectionLeft;

  /// No description provided for @swipeDirectionRight.
  ///
  /// In en, this message translates to:
  /// **'Swipe right'**
  String get swipeDirectionRight;

  /// No description provided for @swipeDirectionUp.
  ///
  /// In en, this message translates to:
  /// **'Swipe up'**
  String get swipeDirectionUp;

  /// No description provided for @swipeDirectionDown.
  ///
  /// In en, this message translates to:
  /// **'Swipe down'**
  String get swipeDirectionDown;

  /// No description provided for @swipeActionNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get swipeActionNothing;

  /// No description provided for @swipeActionTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get swipeActionTrash;

  /// No description provided for @swipeActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get swipeActionDelete;

  /// No description provided for @swipeActionKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get swipeActionKeep;

  /// No description provided for @swipeActionNeedOne.
  ///
  /// In en, this message translates to:
  /// **'At least one direction needs an action'**
  String get swipeActionNeedOne;

  /// No description provided for @swipeLayoutReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to basic'**
  String get swipeLayoutReset;

  /// No description provided for @swipeLayoutResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset swipes?'**
  String get swipeLayoutResetTitle;

  /// No description provided for @swipeLayoutResetBody.
  ///
  /// In en, this message translates to:
  /// **'Left goes back to trash and right to keep. Up and down will do nothing.'**
  String get swipeLayoutResetBody;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
