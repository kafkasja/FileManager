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
  /// **'{count, plural, =0{Session finished.} =1{Session finished: 1 file deleted ({size}).} other{Session finished: {count} files deleted ({size}).}}'**
  String sessionSummary(int count, String size);

  /// No description provided for @sessionSummaryTrash.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Session finished.} =1{Session finished: 1 file moved to the trash ({size}).} other{Session finished: {count} files moved to the trash ({size}).}}'**
  String sessionSummaryTrash(int count, String size);

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

  /// No description provided for @swipeActionMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to folder…'**
  String get swipeActionMoveTo;

  /// No description provided for @swipeActionCopyTo.
  ///
  /// In en, this message translates to:
  /// **'Copy to folder…'**
  String get swipeActionCopyTo;

  /// No description provided for @swipeActionAddTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag…'**
  String get swipeActionAddTag;

  /// No description provided for @swipeActionFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get swipeActionFavorite;

  /// No description provided for @swipeActionMoveToNamed.
  ///
  /// In en, this message translates to:
  /// **'Move to {folder}'**
  String swipeActionMoveToNamed(String folder);

  /// No description provided for @swipeActionCopyToNamed.
  ///
  /// In en, this message translates to:
  /// **'Copy to {folder}'**
  String swipeActionCopyToNamed(String folder);

  /// No description provided for @swipeActionTagNamed.
  ///
  /// In en, this message translates to:
  /// **'Tag: {tag}'**
  String swipeActionTagNamed(String tag);

  /// No description provided for @swipeActionTagMissing.
  ///
  /// In en, this message translates to:
  /// **'Tag no longer exists'**
  String get swipeActionTagMissing;

  /// No description provided for @moveConsentNotice.
  ///
  /// In en, this message translates to:
  /// **'Android may ask before each move'**
  String get moveConsentNotice;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @folderPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder'**
  String get folderPickerTitle;

  /// No description provided for @folderPickerRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get folderPickerRecent;

  /// No description provided for @folderPickerWithPhotos.
  ///
  /// In en, this message translates to:
  /// **'Folders with photos'**
  String get folderPickerWithPhotos;

  /// No description provided for @folderPickerNew.
  ///
  /// In en, this message translates to:
  /// **'New folder…'**
  String get folderPickerNew;

  /// No description provided for @folderPickerNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get folderPickerNewTitle;

  /// No description provided for @folderPickerNewIn.
  ///
  /// In en, this message translates to:
  /// **'Inside {folder}'**
  String folderPickerNewIn(String folder);

  /// No description provided for @folderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderNameHint;

  /// No description provided for @folderNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'That name can\'t be used'**
  String get folderNameInvalid;

  /// No description provided for @folderNeedsAllFiles.
  ///
  /// In en, this message translates to:
  /// **'Needs All files access'**
  String get folderNeedsAllFiles;

  /// No description provided for @folderFileCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String folderFileCount(int count);

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @tagPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a tag'**
  String get tagPickerTitle;

  /// No description provided for @tagPickerNew.
  ///
  /// In en, this message translates to:
  /// **'New tag…'**
  String get tagPickerNew;

  /// No description provided for @tagNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get tagNewTitle;

  /// No description provided for @tagNameHint.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagNameHint;

  /// No description provided for @tagNameTaken.
  ///
  /// In en, this message translates to:
  /// **'A tag with this name already exists'**
  String get tagNameTaken;

  /// No description provided for @tagNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 1 to 40 characters'**
  String get tagNameInvalid;

  /// No description provided for @tagsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get tagsEmpty;

  /// No description provided for @swipeProblemTagMissing.
  ///
  /// In en, this message translates to:
  /// **'Tag no longer exists. Change it in Customize swipes.'**
  String get swipeProblemTagMissing;

  /// No description provided for @swipeProblemUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This swipe can\'t be used yet'**
  String get swipeProblemUnsupported;

  /// No description provided for @fileOpFolderMissing.
  ///
  /// In en, this message translates to:
  /// **'Folder not found. Pick it again in Customize swipes.'**
  String get fileOpFolderMissing;

  /// No description provided for @fileOpDeclined.
  ///
  /// In en, this message translates to:
  /// **'Not moved: permission declined'**
  String get fileOpDeclined;

  /// No description provided for @fileOpNoSpace.
  ///
  /// In en, this message translates to:
  /// **'Not enough space'**
  String get fileOpNoSpace;

  /// No description provided for @fileOpNeedsAllFiles.
  ///
  /// In en, this message translates to:
  /// **'This folder needs All files access'**
  String get fileOpNeedsAllFiles;

  /// No description provided for @fileOpMoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move {name}'**
  String fileOpMoveFailed(String name);

  /// No description provided for @fileOpCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t copy {name}'**
  String fileOpCopyFailed(String name);

  /// No description provided for @undoneLabel.
  ///
  /// In en, this message translates to:
  /// **'↩ Undone'**
  String get undoneLabel;

  /// No description provided for @swipeActionRenameBatch.
  ///
  /// In en, this message translates to:
  /// **'Add to rename batch'**
  String get swipeActionRenameBatch;

  /// No description provided for @renamePill.
  ///
  /// In en, this message translates to:
  /// **'✎ {count}'**
  String renamePill(int count);

  /// No description provided for @renameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename batch'**
  String get renameTitle;

  /// No description provided for @renamePatternLabel.
  ///
  /// In en, this message translates to:
  /// **'Name pattern'**
  String get renamePatternLabel;

  /// The {…} tokens are passed in literally; never translate them.
  ///
  /// In en, this message translates to:
  /// **'holiday_{n}'**
  String renamePatternHint(String n);

  /// No description provided for @renameStart.
  ///
  /// In en, this message translates to:
  /// **'Start at'**
  String get renameStart;

  /// No description provided for @renamePadding.
  ///
  /// In en, this message translates to:
  /// **'Digits'**
  String get renamePadding;

  /// The {…} tokens are passed in literally; never translate them.
  ///
  /// In en, this message translates to:
  /// **'{n} = number · {date} = date · {orig} = original name'**
  String renameTokensHelp(String n, String date, String orig);

  /// No description provided for @renameMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing or changed: skipped'**
  String get renameMissing;

  /// No description provided for @renameCollision.
  ///
  /// In en, this message translates to:
  /// **'Name was taken: \"{name}\" is used instead'**
  String renameCollision(String name);

  /// No description provided for @renameApply.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameApply;

  /// No description provided for @renameDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard batch'**
  String get renameDiscard;

  /// No description provided for @renameDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this rename batch?'**
  String get renameDiscardTitle;

  /// No description provided for @renameDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'The files stay as they are; only the batch is dropped.'**
  String get renameDiscardBody;

  /// No description provided for @renameErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Type a name pattern'**
  String get renameErrorEmpty;

  /// No description provided for @renameErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'These characters can\'t be used: / \\ : * ? \" < > |'**
  String get renameErrorInvalid;

  /// The {…} tokens are passed in literally; never translate them.
  ///
  /// In en, this message translates to:
  /// **'Add {n} so every file gets its own number'**
  String renameErrorNeedsCounter(String n);

  /// No description provided for @renameErrorTooLong.
  ///
  /// In en, this message translates to:
  /// **'The names would be too long'**
  String get renameErrorTooLong;

  /// No description provided for @renameRunning.
  ///
  /// In en, this message translates to:
  /// **'Renaming…'**
  String get renameRunning;

  /// No description provided for @renameDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Renamed 1 file} other{Renamed {count} files}}'**
  String renameDone(int count);

  /// No description provided for @renameDoneSkipped.
  ///
  /// In en, this message translates to:
  /// **'Renamed {renamed} · skipped {skipped}'**
  String renameDoneSkipped(int renamed, int skipped);

  /// No description provided for @renameDeclined.
  ///
  /// In en, this message translates to:
  /// **'Nothing renamed: permission declined'**
  String get renameDeclined;

  /// No description provided for @renameNoUndoAfterDone.
  ///
  /// In en, this message translates to:
  /// **'You can undo this until you tap Done.'**
  String get renameNoUndoAfterDone;

  /// No description provided for @renameBeforeFinishTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Rename 1 file first?} other{Rename {count} files first?}}'**
  String renameBeforeFinishTitle(int count);

  /// No description provided for @renameBeforeFinishBody.
  ///
  /// In en, this message translates to:
  /// **'Your rename batch hasn\'t been applied yet. Discarding it keeps the current names.'**
  String get renameBeforeFinishBody;

  /// No description provided for @renameOpen.
  ///
  /// In en, this message translates to:
  /// **'Rename…'**
  String get renameOpen;

  /// No description provided for @labelRenameApplied.
  ///
  /// In en, this message translates to:
  /// **'✎ Renamed batch'**
  String get labelRenameApplied;

  /// No description provided for @clearRenameDropped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file in the rename batch will be dropped} other{{count} files in the rename batch will be dropped}}'**
  String clearRenameDropped(int count);

  /// No description provided for @barTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get barTrash;

  /// No description provided for @barDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get barDelete;

  /// No description provided for @barKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get barKeep;

  /// No description provided for @barFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get barFavorite;

  /// No description provided for @barRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get barRename;

  /// No description provided for @actionBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Action bar'**
  String get actionBarTitle;

  /// No description provided for @actionBarHelp.
  ///
  /// In en, this message translates to:
  /// **'Extra buttons under the card'**
  String get actionBarHelp;

  /// No description provided for @actionBarAdd.
  ///
  /// In en, this message translates to:
  /// **'Add action'**
  String get actionBarAdd;

  /// No description provided for @actionBarEmpty.
  ///
  /// In en, this message translates to:
  /// **'No buttons yet'**
  String get actionBarEmpty;

  /// No description provided for @actionBarRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionBarRemove;

  /// No description provided for @actionBarFull.
  ///
  /// In en, this message translates to:
  /// **'Up to 8 buttons'**
  String get actionBarFull;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTitle;

  /// No description provided for @filterButton.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterButton;

  /// No description provided for @filterKinds.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get filterKinds;

  /// No description provided for @filterPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get filterPhotos;

  /// No description provided for @filterVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get filterVideos;

  /// No description provided for @filterScreenshotsOnly.
  ///
  /// In en, this message translates to:
  /// **'Screenshots only'**
  String get filterScreenshotsOnly;

  /// No description provided for @filterDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get filterDate;

  /// No description provided for @filterAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get filterAny;

  /// No description provided for @filterThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get filterThisMonth;

  /// No description provided for @filterLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get filterLast30Days;

  /// No description provided for @filterCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Pick dates…'**
  String get filterCustomRange;

  /// No description provided for @filterRange.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String filterRange(String from, String to);

  /// No description provided for @filterSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get filterSize;

  /// No description provided for @filterOverMb.
  ///
  /// In en, this message translates to:
  /// **'Over {mb} MB'**
  String filterOverMb(int mb);

  /// No description provided for @filterFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get filterFolders;

  /// No description provided for @filterFolderCount.
  ///
  /// In en, this message translates to:
  /// **'{folder} ({count})'**
  String filterFolderCount(String folder, int count);

  /// No description provided for @filterFolderMissing.
  ///
  /// In en, this message translates to:
  /// **'{folder} (missing)'**
  String filterFolderMissing(String folder);

  /// No description provided for @filterTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get filterTags;

  /// No description provided for @filterTagged.
  ///
  /// In en, this message translates to:
  /// **'Tagged'**
  String get filterTagged;

  /// No description provided for @filterUntagged.
  ///
  /// In en, this message translates to:
  /// **'Untagged'**
  String get filterUntagged;

  /// No description provided for @filterSpecificTags.
  ///
  /// In en, this message translates to:
  /// **'Specific…'**
  String get filterSpecificTags;

  /// No description provided for @filterFavoritesOnly.
  ///
  /// In en, this message translates to:
  /// **'Favorites only'**
  String get filterFavoritesOnly;

  /// No description provided for @filterMatches.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No files match} =1{1 file matches} other{{count} files match}}'**
  String filterMatches(int count);

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// No description provided for @filterProblemSize.
  ///
  /// In en, this message translates to:
  /// **'The minimum size is larger than the maximum'**
  String get filterProblemSize;

  /// No description provided for @filterProblemTags.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one tag'**
  String get filterProblemTags;

  /// No description provided for @filterProblemDate.
  ///
  /// In en, this message translates to:
  /// **'The start date is after the end date'**
  String get filterProblemDate;

  /// No description provided for @filterNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No files match this filter'**
  String get filterNoMatches;

  /// No description provided for @filterAllDone.
  ///
  /// In en, this message translates to:
  /// **'All matching files done'**
  String get filterAllDone;

  /// No description provided for @filterChange.
  ///
  /// In en, this message translates to:
  /// **'Change filter'**
  String get filterChange;

  /// No description provided for @presetBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get presetBasic;

  /// No description provided for @presetChipTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch preset'**
  String get presetChipTooltip;

  /// No description provided for @presetSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get presetSheetTitle;

  /// No description provided for @presetManage.
  ///
  /// In en, this message translates to:
  /// **'Manage presets'**
  String get presetManage;

  /// No description provided for @presetSaveAs.
  ///
  /// In en, this message translates to:
  /// **'Save as preset…'**
  String get presetSaveAs;

  /// No description provided for @presetNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Preset name'**
  String get presetNameLabel;

  /// No description provided for @presetIncludeFilter.
  ///
  /// In en, this message translates to:
  /// **'Include the current filter'**
  String get presetIncludeFilter;

  /// No description provided for @presetSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved “{name}”'**
  String presetSaved(String name);

  /// No description provided for @presetNameTaken.
  ///
  /// In en, this message translates to:
  /// **'A preset with this name already exists'**
  String get presetNameTaken;

  /// No description provided for @presetNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 1 to 40 characters'**
  String get presetNameInvalid;

  /// No description provided for @presetRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get presetRename;

  /// No description provided for @presetEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get presetEdit;

  /// No description provided for @presetDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get presetDuplicate;

  /// No description provided for @presetDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get presetDelete;

  /// No description provided for @presetDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String presetDeleteConfirm(String name);

  /// No description provided for @presetDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Its unfinished session ends. Your files aren\'t touched.'**
  String get presetDeleteBody;

  /// No description provided for @presetLoadError.
  ///
  /// In en, this message translates to:
  /// **'Can\'t load: edit or delete'**
  String get presetLoadError;

  /// No description provided for @presetNoSessionHint.
  ///
  /// In en, this message translates to:
  /// **'Start swiping in {name} to change the buttons for that session, or edit the preset in Manage presets.'**
  String presetNoSessionHint(String name);

  /// No description provided for @presetEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit preset'**
  String get presetEditorTitle;

  /// No description provided for @presetDirections.
  ///
  /// In en, this message translates to:
  /// **'Swipe buttons'**
  String get presetDirections;

  /// No description provided for @presetFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get presetFilter;

  /// No description provided for @presetEditorFilterNone.
  ///
  /// In en, this message translates to:
  /// **'No filter'**
  String get presetEditorFilterNone;

  /// No description provided for @presetEditorFilterOn.
  ///
  /// In en, this message translates to:
  /// **'Filter set'**
  String get presetEditorFilterOn;

  /// No description provided for @presetEditorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get presetEditorSave;

  /// No description provided for @presetEditorReplacesSession.
  ///
  /// In en, this message translates to:
  /// **'Also replaces the setup of this preset\'s unfinished session'**
  String get presetEditorReplacesSession;

  /// No description provided for @presetEditorDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard your changes?'**
  String get presetEditorDiscard;

  /// No description provided for @presetDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get presetDiscard;

  /// No description provided for @presetSwitchBlocked.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t finish the deletes, so you\'re still on {name}. Try again.'**
  String presetSwitchBlocked(String name);

  /// No description provided for @presetEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No presets yet'**
  String get presetEmptyTitle;

  /// No description provided for @presetEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'A preset saves your swipe buttons and, if you like, a filter. Switch between them with one tap.'**
  String get presetEmptyBody;

  /// No description provided for @presetEmptyQuickCleanup.
  ///
  /// In en, this message translates to:
  /// **'Quick cleanup'**
  String get presetEmptyQuickCleanup;

  /// No description provided for @presetEmptyQuickCleanupHelp.
  ///
  /// In en, this message translates to:
  /// **'Left = trash, right = keep, screenshots only'**
  String get presetEmptyQuickCleanupHelp;

  /// No description provided for @presetEmptySortHoliday.
  ///
  /// In en, this message translates to:
  /// **'Sort holiday'**
  String get presetEmptySortHoliday;

  /// No description provided for @presetEmptySortHolidayHelp.
  ///
  /// In en, this message translates to:
  /// **'Left = trash, right = move to a folder, up = favorite'**
  String get presetEmptySortHolidayHelp;

  /// No description provided for @presetCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get presetCreate;

  /// No description provided for @presetNew.
  ///
  /// In en, this message translates to:
  /// **'New preset'**
  String get presetNew;

  /// No description provided for @settingsPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get settingsPresets;

  /// No description provided for @settingsPresetsHelp.
  ///
  /// In en, this message translates to:
  /// **'Saved swipe setups'**
  String get settingsPresetsHelp;

  /// No description provided for @reviewedBadge.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get reviewedBadge;

  /// No description provided for @settingsShowReviewedBadge.
  ///
  /// In en, this message translates to:
  /// **'Show reviewed badge'**
  String get settingsShowReviewedBadge;

  /// No description provided for @settingsShowReviewedBadgeHelp.
  ///
  /// In en, this message translates to:
  /// **'A small mark on files you already swiped before'**
  String get settingsShowReviewedBadgeHelp;

  /// No description provided for @reviewedIncludeToggle.
  ///
  /// In en, this message translates to:
  /// **'Include files already reviewed here'**
  String get reviewedIncludeToggle;

  /// No description provided for @filterReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get filterReviewed;

  /// No description provided for @filterReviewedOnly.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get filterReviewedOnly;

  /// No description provided for @filterNotReviewed.
  ///
  /// In en, this message translates to:
  /// **'Not reviewed'**
  String get filterNotReviewed;

  /// No description provided for @reviewedInfoLine.
  ///
  /// In en, this message translates to:
  /// **'Reviewed in {preset} · {action} · {date}'**
  String reviewedInfoLine(String preset, String action, String date);

  /// No description provided for @reviewedReset.
  ///
  /// In en, this message translates to:
  /// **'Reset reviewed labels…'**
  String get reviewedReset;

  /// No description provided for @reviewedResetAll.
  ///
  /// In en, this message translates to:
  /// **'All presets'**
  String get reviewedResetAll;

  /// No description provided for @reviewedResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset reviewed labels for {name}? This can\'t be undone.'**
  String reviewedResetConfirm(String name);

  /// No description provided for @reviewedResetCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No files} =1{1 file} other{{count} files}}'**
  String reviewedResetCount(int count);

  /// No description provided for @reviewedResetDone.
  ///
  /// In en, this message translates to:
  /// **'Reviewed labels reset'**
  String get reviewedResetDone;

  /// No description provided for @presetIncludeReviewed.
  ///
  /// In en, this message translates to:
  /// **'Include files already reviewed in this preset'**
  String get presetIncludeReviewed;

  /// No description provided for @settingsStats.
  ///
  /// In en, this message translates to:
  /// **'Swipe stats'**
  String get settingsStats;

  /// No description provided for @settingsStatsHelp.
  ///
  /// In en, this message translates to:
  /// **'Files reviewed and space freed'**
  String get settingsStatsHelp;

  /// No description provided for @settingsShowSessionSummary.
  ///
  /// In en, this message translates to:
  /// **'Show summary after Done'**
  String get settingsShowSessionSummary;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe stats'**
  String get statsTitle;

  /// No description provided for @statsInTrashFreed.
  ///
  /// In en, this message translates to:
  /// **'{inTrash} in trash · {freed} freed'**
  String statsInTrashFreed(String inTrash, String freed);

  /// No description provided for @statsGoToTrash.
  ///
  /// In en, this message translates to:
  /// **'Go to Trash'**
  String get statsGoToTrash;

  /// No description provided for @statsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get statsThisWeek;

  /// No description provided for @statsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get statsThisMonth;

  /// No description provided for @statsAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get statsAllTime;

  /// No description provided for @statsReviewed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file reviewed} other{{count} files reviewed}}'**
  String statsReviewed(int count);

  /// No description provided for @statsFreed.
  ///
  /// In en, this message translates to:
  /// **'{size} freed'**
  String statsFreed(String size);

  /// No description provided for @statsRowLine.
  ///
  /// In en, this message translates to:
  /// **'{reviewed} · {freed}'**
  String statsRowLine(String reviewed, String freed);

  /// No description provided for @statsByPreset.
  ///
  /// In en, this message translates to:
  /// **'By preset'**
  String get statsByPreset;

  /// No description provided for @statsDeletedPresets.
  ///
  /// In en, this message translates to:
  /// **'Deleted presets'**
  String get statsDeletedPresets;

  /// No description provided for @statsWeekly.
  ///
  /// In en, this message translates to:
  /// **'Last 8 weeks'**
  String get statsWeekly;

  /// No description provided for @statsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset stats'**
  String get statsReset;

  /// No description provided for @statsResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset the reviewed and freed counters? Files in the trash stay counted.'**
  String get statsResetConfirm;

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Session finished'**
  String get summaryTitle;

  /// No description provided for @summaryReviewed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You reviewed 1 file} other{You reviewed {count} files}}'**
  String summaryReviewed(int count);

  /// No description provided for @summaryToTrash.
  ///
  /// In en, this message translates to:
  /// **'{size} moved to the trash'**
  String summaryToTrash(String size);

  /// No description provided for @summaryFreed.
  ///
  /// In en, this message translates to:
  /// **'{size} freed'**
  String summaryFreed(String size);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @settingsSwipeButtons.
  ///
  /// In en, this message translates to:
  /// **'Use buttons instead of swiping'**
  String get settingsSwipeButtons;

  /// No description provided for @settingsSwipeButtonsHelp.
  ///
  /// In en, this message translates to:
  /// **'Tap buttons to do what each swipe does'**
  String get settingsSwipeButtonsHelp;

  /// No description provided for @swipeCardSemantics.
  ///
  /// In en, this message translates to:
  /// **'{kind}, {name}, {size}, {date}'**
  String swipeCardSemantics(String kind, String name, String size, String date);

  /// No description provided for @fileKindPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get fileKindPhoto;

  /// No description provided for @fileKindVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get fileKindVideo;

  /// No description provided for @swipeButtonSemantics.
  ///
  /// In en, this message translates to:
  /// **'{action}, {direction}'**
  String swipeButtonSemantics(String action, String direction);

  /// No description provided for @pendingRetentionCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get pendingRetentionCustom;

  /// No description provided for @pendingRetentionCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep pending files for'**
  String get pendingRetentionCustomTitle;

  /// No description provided for @pendingRetentionCustomHelper.
  ///
  /// In en, this message translates to:
  /// **'1–90 days'**
  String get pendingRetentionCustomHelper;

  /// No description provided for @pendingRetentionCustomError.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to 90'**
  String get pendingRetentionCustomError;

  /// No description provided for @pendingRetentionCustomSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get pendingRetentionCustomSave;

  /// No description provided for @pendingPurgeFailedPermission.
  ///
  /// In en, this message translates to:
  /// **'Automatic cleanup couldn\'t run: permission needed'**
  String get pendingPurgeFailedPermission;

  /// No description provided for @pendingPurgeFailed.
  ///
  /// In en, this message translates to:
  /// **'Automatic cleanup couldn\'t run'**
  String get pendingPurgeFailed;

  /// No description provided for @pendingUnavailableSnack.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file couldn\'t be moved to the pending-delete folder. It\'s still on your device.} other{{count} files couldn\'t be moved to the pending-delete folder. They\'re still on your device.}}'**
  String pendingUnavailableSnack(int count);

  /// No description provided for @pendingUnavailableBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file wasn\'t deleted: the pending-delete folder can\'t be used} other{{count} files weren\'t deleted: the pending-delete folder can\'t be used}}'**
  String pendingUnavailableBanner(int count);

  /// No description provided for @pendingUnavailableOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get pendingUnavailableOptions;

  /// No description provided for @pendingUnavailableAfterDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file wasn\'t deleted. Find it in Trash.} other{{count} files weren\'t deleted. Find them in Trash.}}'**
  String pendingUnavailableAfterDone(int count);

  /// No description provided for @pendingUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move to the pending-delete folder'**
  String get pendingUnavailableTitle;

  /// No description provided for @pendingUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'KFM can\'t put these files in its pending-delete folder, so they weren\'t deleted.'**
  String get pendingUnavailableBody;

  /// No description provided for @pendingUnavailableGrantAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow All files access so KFM can use the folder'**
  String get pendingUnavailableGrantAccess;

  /// No description provided for @pendingUnavailableWarning.
  ///
  /// In en, this message translates to:
  /// **'Deleting permanently can\'t be undone. These files won\'t go to the trash and can\'t be restored.'**
  String get pendingUnavailableWarning;

  /// No description provided for @pendingUnavailableKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get pendingUnavailableKeep;

  /// No description provided for @pendingUnavailableDeleteOne.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get pendingUnavailableDeleteOne;

  /// No description provided for @pendingUnavailableDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 file permanently} other{Delete all {count} permanently}}'**
  String pendingUnavailableDeleteAll(int count);

  /// No description provided for @pendingUnavailableConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete this file permanently?} other{Delete {count} files permanently?}} This can\'t be undone.'**
  String pendingUnavailableConfirm(int count);

  /// No description provided for @pendingUnavailableConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get pendingUnavailableConfirmButton;

  /// No description provided for @pendingUnavailableDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file deleted permanently} other{{count} files deleted permanently}}'**
  String pendingUnavailableDeleted(int count);

  /// No description provided for @pendingUnavailableSection.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move to the pending folder'**
  String get pendingUnavailableSection;

  /// No description provided for @trashSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get trashSort;

  /// No description provided for @trashSortExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiring soonest'**
  String get trashSortExpiry;

  /// No description provided for @trashSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest deleted'**
  String get trashSortNewest;

  /// No description provided for @swipeEmptyLibraryHint.
  ///
  /// In en, this message translates to:
  /// **'If your phone has photos, KFM may not be allowed to see them. Check KFM\'s permissions in your phone\'s settings.'**
  String get swipeEmptyLibraryHint;
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
