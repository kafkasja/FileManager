import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_tr.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('nl'),
    Locale('tr'),
  ];

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

  /// Bottom tab: the swipe-to-sort screen (verb used as a name).
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

  /// No description provided for @dbWriteError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your last change.'**
  String get dbWriteError;

  /// Startup banner after a corrupt database file was moved aside.
  ///
  /// In en, this message translates to:
  /// **'KFM\'s data was damaged, so KFM started fresh. Your photos and files were not touched; sessions, tags and settings are reset. The damaged copy was kept as {name}.'**
  String dbResetNotice(String name);

  /// No description provided for @dbUnavailableNotice.
  ///
  /// In en, this message translates to:
  /// **'KFM can\'t open its data right now. Another program may be using it. Close it and restart KFM. Your files were not touched.'**
  String get dbUnavailableNotice;

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

  /// Clears the thumbnail cache.
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

  /// Button that ends the swipe session and commits pending deletes.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get swipeDone;

  /// No description provided for @swipeFinishTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish this session?'**
  String get swipeFinishTitle;

  /// Confirms ending the swipe session.
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

  /// No description provided for @videoDamaged.
  ///
  /// In en, this message translates to:
  /// **'This file can\'t be played — it may be damaged'**
  String get videoDamaged;

  /// No description provided for @imageDamaged.
  ///
  /// In en, this message translates to:
  /// **'This file can\'t be shown — it may be damaged'**
  String get imageDamaged;

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

  /// Swipe action: keep the file where it is (opposite of trash).
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

  /// Action bar button: keep the file (swipe action).
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

  /// Badge on a file already sorted (reviewed) in this preset.
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

  /// Filter chip: files already reviewed (sorted) in a preset.
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

  /// Keep the pending trash file instead of deleting it.
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

  /// No description provided for @browseKindAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get browseKindAll;

  /// No description provided for @browseKindImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get browseKindImages;

  /// No description provided for @browseKindVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get browseKindVideos;

  /// No description provided for @browseKindAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get browseKindAudio;

  /// No description provided for @browseKindDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get browseKindDocuments;

  /// No description provided for @browseKindArchives.
  ///
  /// In en, this message translates to:
  /// **'Archives'**
  String get browseKindArchives;

  /// No description provided for @browseKindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get browseKindOther;

  /// No description provided for @browseSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get browseSourceCamera;

  /// No description provided for @browseSourceScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get browseSourceScreenshots;

  /// No description provided for @browseSourceWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get browseSourceWhatsapp;

  /// No description provided for @browseSourceSnapchat.
  ///
  /// In en, this message translates to:
  /// **'Snapchat'**
  String get browseSourceSnapchat;

  /// No description provided for @browseSourceDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get browseSourceDownloads;

  /// No description provided for @browseSourceVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get browseSourceVideos;

  /// No description provided for @browseSourcePanoramas.
  ///
  /// In en, this message translates to:
  /// **'Panoramas'**
  String get browseSourcePanoramas;

  /// No description provided for @browseSourceScreenRecordings.
  ///
  /// In en, this message translates to:
  /// **'Screen recordings'**
  String get browseSourceScreenRecordings;

  /// No description provided for @browseSourceExpertRaw.
  ///
  /// In en, this message translates to:
  /// **'Expert RAW'**
  String get browseSourceExpertRaw;

  /// No description provided for @browseSourceGifs.
  ///
  /// In en, this message translates to:
  /// **'GIFs'**
  String get browseSourceGifs;

  /// No description provided for @browseSourceCollages.
  ///
  /// In en, this message translates to:
  /// **'Collages'**
  String get browseSourceCollages;

  /// No description provided for @browseSourceClippedImages.
  ///
  /// In en, this message translates to:
  /// **'Clipped images'**
  String get browseSourceClippedImages;

  /// No description provided for @browseSourceLiveMessages.
  ///
  /// In en, this message translates to:
  /// **'Live messages'**
  String get browseSourceLiveMessages;

  /// No description provided for @browseSourceVideoCaptures.
  ///
  /// In en, this message translates to:
  /// **'Video captures'**
  String get browseSourceVideoCaptures;

  /// No description provided for @browseSourceTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get browseSourceTelegram;

  /// No description provided for @browseSourceInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get browseSourceInstagram;

  /// No description provided for @browseSourceOther.
  ///
  /// In en, this message translates to:
  /// **'Other apps'**
  String get browseSourceOther;

  /// No description provided for @browseSourceHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get browseSourceHidden;

  /// No description provided for @browsePanoramaHint.
  ///
  /// In en, this message translates to:
  /// **'Best guess: wide photos and PANO files'**
  String get browsePanoramaHint;

  /// No description provided for @browseModeAll.
  ///
  /// In en, this message translates to:
  /// **'All files'**
  String get browseModeAll;

  /// No description provided for @browseModeFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get browseModeFolders;

  /// No description provided for @browseShowHidden.
  ///
  /// In en, this message translates to:
  /// **'Show hidden files'**
  String get browseShowHidden;

  /// No description provided for @browseSwipeThese.
  ///
  /// In en, this message translates to:
  /// **'Swipe these'**
  String get browseSwipeThese;

  /// No description provided for @browseNeedsAllFiles.
  ///
  /// In en, this message translates to:
  /// **'Grant access to see documents, downloads and hidden files'**
  String get browseNeedsAllFiles;

  /// No description provided for @browseGrantAccess.
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get browseGrantAccess;

  /// No description provided for @browseEmpty.
  ///
  /// In en, this message translates to:
  /// **'No files here'**
  String get browseEmpty;

  /// No description provided for @searchKwType.
  ///
  /// In en, this message translates to:
  /// **'Type: {name}'**
  String searchKwType(String name);

  /// No description provided for @searchKwSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {name}'**
  String searchKwSource(String name);

  /// No description provided for @searchKwHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden files'**
  String get searchKwHidden;

  /// No description provided for @searchKwTiny.
  ///
  /// In en, this message translates to:
  /// **'Tiny (< 10 KB)'**
  String get searchKwTiny;

  /// No description provided for @searchKwLarge.
  ///
  /// In en, this message translates to:
  /// **'Large (> 100 MB)'**
  String get searchKwLarge;

  /// No description provided for @searchKwToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get searchKwToday;

  /// No description provided for @searchKwWeek.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get searchKwWeek;

  /// No description provided for @searchTermsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Search words for {language} couldn\'t be loaded'**
  String searchTermsLoadError(String language);

  /// No description provided for @searchSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchSettingsTitle;

  /// No description provided for @searchSettingsAlsoSearchIn.
  ///
  /// In en, this message translates to:
  /// **'Also search in'**
  String get searchSettingsAlsoSearchIn;

  /// No description provided for @searchSettingsAlsoSearchInHelp.
  ///
  /// In en, this message translates to:
  /// **'Smart words like \'video\' or \'cloud\' also work in this language.'**
  String get searchSettingsAlsoSearchInHelp;

  /// No description provided for @searchSettingsNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get searchSettingsNone;

  /// No description provided for @searchSettingsAlreadyIncluded.
  ///
  /// In en, this message translates to:
  /// **'{language} (already included)'**
  String searchSettingsAlreadyIncluded(String language);

  /// No description provided for @searchSettingsTip.
  ///
  /// In en, this message translates to:
  /// **'Type words like \'video\', \'pdf\', \'whatsapp\', \'hidden\' or \'large\' to filter. Tap ✕ on a chip to search the name instead.'**
  String get searchSettingsTip;

  /// No description provided for @searchOpen.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchOpen;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search files'**
  String get searchHint;

  /// No description provided for @searchClearText.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClearText;

  /// No description provided for @searchChipType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get searchChipType;

  /// No description provided for @searchChipTypes.
  ///
  /// In en, this message translates to:
  /// **'{count} types'**
  String searchChipTypes(int count);

  /// No description provided for @searchChipSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get searchChipSource;

  /// No description provided for @searchChipDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get searchChipDate;

  /// No description provided for @searchDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get searchDateToday;

  /// No description provided for @searchDateWeek.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get searchDateWeek;

  /// No description provided for @searchDateMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get searchDateMonth;

  /// No description provided for @searchDateYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get searchDateYear;

  /// No description provided for @searchDateCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get searchDateCustom;

  /// No description provided for @searchDateRange.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String searchDateRange(String from, String to);

  /// No description provided for @searchDateSince.
  ///
  /// In en, this message translates to:
  /// **'Since {from}'**
  String searchDateSince(String from);

  /// No description provided for @searchChipSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get searchChipSize;

  /// No description provided for @searchSizeOver.
  ///
  /// In en, this message translates to:
  /// **'> {size}'**
  String searchSizeOver(String size);

  /// No description provided for @searchSizeUnder.
  ///
  /// In en, this message translates to:
  /// **'< {size}'**
  String searchSizeUnder(String size);

  /// No description provided for @searchSizeTiny.
  ///
  /// In en, this message translates to:
  /// **'Tiny (< 10 KB)'**
  String get searchSizeTiny;

  /// No description provided for @searchSizeBetween.
  ///
  /// In en, this message translates to:
  /// **'{min} – {max}'**
  String searchSizeBetween(String min, String max);

  /// No description provided for @searchSizeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get searchSizeCustom;

  /// No description provided for @searchSizeCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get searchSizeCustomTitle;

  /// No description provided for @searchSizeMinLabel.
  ///
  /// In en, this message translates to:
  /// **'At least (MB)'**
  String get searchSizeMinLabel;

  /// No description provided for @searchSizeMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'At most (MB)'**
  String get searchSizeMaxLabel;

  /// No description provided for @searchSizeInvalid.
  ///
  /// In en, this message translates to:
  /// **'The minimum can\'t be larger than the maximum'**
  String get searchSizeInvalid;

  /// No description provided for @searchChipHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden files'**
  String get searchChipHidden;

  /// No description provided for @searchHiddenInclude.
  ///
  /// In en, this message translates to:
  /// **'Include hidden files'**
  String get searchHiddenInclude;

  /// No description provided for @searchHiddenOnly.
  ///
  /// In en, this message translates to:
  /// **'Only hidden files'**
  String get searchHiddenOnly;

  /// No description provided for @searchOnlyIn.
  ///
  /// In en, this message translates to:
  /// **'Only in {folder}'**
  String searchOnlyIn(String folder);

  /// No description provided for @searchTokenExtension.
  ///
  /// In en, this message translates to:
  /// **'Type: .{ext}'**
  String searchTokenExtension(String ext);

  /// No description provided for @searchTokenAsName.
  ///
  /// In en, this message translates to:
  /// **'Search names for “{word}” instead'**
  String searchTokenAsName(String word);

  /// No description provided for @searchRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecent;

  /// No description provided for @searchSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Try'**
  String get searchSuggestions;

  /// No description provided for @searchSuggestLarge.
  ///
  /// In en, this message translates to:
  /// **'Large files'**
  String get searchSuggestLarge;

  /// No description provided for @searchSuggestDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get searchSuggestDownloads;

  /// No description provided for @searchSuggestPdfs.
  ///
  /// In en, this message translates to:
  /// **'PDFs'**
  String get searchSuggestPdfs;

  /// No description provided for @searchSuggestHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden files'**
  String get searchSuggestHidden;

  /// No description provided for @searchSuggestWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get searchSuggestWeek;

  /// No description provided for @searchNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No files match'**
  String get searchNoMatch;

  /// No description provided for @searchClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get searchClearFilters;

  /// No description provided for @searchWordsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Search words for {languages} couldn\'t be loaded'**
  String searchWordsLoadError(String languages);

  /// No description provided for @searchDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get searchDone;

  /// No description provided for @browseLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the files.'**
  String get browseLoadError;

  /// No description provided for @browseOtherHint.
  ///
  /// In en, this message translates to:
  /// **'Files from other apps and folders, grouped by folder'**
  String get browseOtherHint;

  /// No description provided for @browseInternalStorage.
  ///
  /// In en, this message translates to:
  /// **'Internal storage'**
  String get browseInternalStorage;

  /// No description provided for @browseExternalVolume.
  ///
  /// In en, this message translates to:
  /// **'SD card or USB ({name})'**
  String browseExternalVolume(String name);

  /// No description provided for @browseFileCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String browseFileCount(int count);

  /// No description provided for @browseStorageRoot.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get browseStorageRoot;

  /// No description provided for @browseFolderMenu.
  ///
  /// In en, this message translates to:
  /// **'Folder options'**
  String get browseFolderMenu;

  /// No description provided for @openWith.
  ///
  /// In en, this message translates to:
  /// **'Open with'**
  String get openWith;

  /// No description provided for @openWithNone.
  ///
  /// In en, this message translates to:
  /// **'No app can open this file'**
  String get openWithNone;

  /// No description provided for @openWithFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this file.'**
  String get openWithFailed;

  /// No description provided for @textViewerTruncated.
  ///
  /// In en, this message translates to:
  /// **'Showing the first 1 MB'**
  String get textViewerTruncated;

  /// No description provided for @textViewerLatin1.
  ///
  /// In en, this message translates to:
  /// **'Shown as Latin-1 (not UTF-8)'**
  String get textViewerLatin1;

  /// No description provided for @textViewerBinary.
  ///
  /// In en, this message translates to:
  /// **'This doesn\'t look like a text file'**
  String get textViewerBinary;

  /// No description provided for @textViewerError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read this file.'**
  String get textViewerError;

  /// No description provided for @browseSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get browseSortTitle;

  /// No description provided for @browseSortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get browseSortDate;

  /// No description provided for @browseSortSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get browseSortSize;

  /// No description provided for @browseSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get browseSortName;

  /// No description provided for @browseSortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get browseSortNewestFirst;

  /// No description provided for @browseSortOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get browseSortOldestFirst;

  /// No description provided for @browseSortLargestFirst.
  ///
  /// In en, this message translates to:
  /// **'Largest first'**
  String get browseSortLargestFirst;

  /// No description provided for @browseSortSmallestFirst.
  ///
  /// In en, this message translates to:
  /// **'Smallest first'**
  String get browseSortSmallestFirst;

  /// No description provided for @browseSortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'A–Z'**
  String get browseSortNameAsc;

  /// No description provided for @browseSortNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Z–A'**
  String get browseSortNameDesc;

  /// No description provided for @browseRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent search'**
  String get browseRecent;

  /// No description provided for @settingsBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get settingsBrowse;

  /// No description provided for @settingsShowSizes.
  ///
  /// In en, this message translates to:
  /// **'Show file sizes'**
  String get settingsShowSizes;

  /// No description provided for @settingsShowSizesHelp.
  ///
  /// In en, this message translates to:
  /// **'A size label on every photo and video'**
  String get settingsShowSizesHelp;

  /// No description provided for @settingsHighlightBig.
  ///
  /// In en, this message translates to:
  /// **'Highlight big files'**
  String get settingsHighlightBig;

  /// No description provided for @selectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected · {size}} other{{count} selected · {size}}}'**
  String selectionCount(int count, String size);

  /// No description provided for @selectionCleared.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Selection cleared (1 file)} other{Selection cleared ({count} files)}}'**
  String selectionCleared(int count);

  /// No description provided for @clearSelectionRow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Clear selection (1 file)} other{Clear selection ({count} files)}}'**
  String clearSelectionRow(int count);

  /// No description provided for @selectionAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing new to add} =1{Added 1 file} other{Added {count} files}}'**
  String selectionAdded(int count);

  /// No description provided for @selectionViewTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String selectionViewTitle(int count);

  /// No description provided for @selectionEnter.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectionEnter;

  /// No description provided for @selectionExit.
  ///
  /// In en, this message translates to:
  /// **'Leave select mode'**
  String get selectionExit;

  /// No description provided for @selectionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit selection'**
  String get selectionEditTitle;

  /// No description provided for @selectionHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to add · Long-press and drag to add many'**
  String get selectionHint;

  /// No description provided for @selectionEditHint.
  ///
  /// In en, this message translates to:
  /// **'Tap selected files to remove them'**
  String get selectionEditHint;

  /// No description provided for @selectionSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectionSelectAll;

  /// No description provided for @selectionClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get selectionClearAll;

  /// No description provided for @selectionView.
  ///
  /// In en, this message translates to:
  /// **'View selected'**
  String get selectionView;

  /// No description provided for @selectionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore last selection'**
  String get selectionRestore;

  /// No description provided for @selectionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get selectionDone;

  /// No description provided for @selectionRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from selection'**
  String get selectionRemoved;

  /// No description provided for @selectionTip.
  ///
  /// In en, this message translates to:
  /// **'Already selected. To remove files, use Edit selection.'**
  String get selectionTip;

  /// No description provided for @selectionMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get selectionMore;

  /// No description provided for @selectionPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview selected'**
  String get selectionPreview;

  /// No description provided for @previewOpen.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewOpen;

  /// No description provided for @previewSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get previewSelect;

  /// No description provided for @previewSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get previewSelected;

  /// No description provided for @previewRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from selection'**
  String get previewRemove;

  /// No description provided for @previewPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get previewPlay;

  /// No description provided for @previewDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get previewDetails;

  /// No description provided for @previewFileGone.
  ///
  /// In en, this message translates to:
  /// **'This file no longer exists'**
  String get previewFileGone;

  /// No description provided for @previewHeicUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Can\'t preview HEIC on this Android version'**
  String get previewHeicUnsupported;

  /// No description provided for @previewDimensions.
  ///
  /// In en, this message translates to:
  /// **'{width} × {height}'**
  String previewDimensions(int width, int height);

  /// No description provided for @previewTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken {date}'**
  String previewTaken(String date);

  /// No description provided for @previewModified.
  ///
  /// In en, this message translates to:
  /// **'Modified {date}'**
  String previewModified(String date);

  /// No description provided for @browseModeSameTime.
  ///
  /// In en, this message translates to:
  /// **'Same time'**
  String get browseModeSameTime;

  /// No description provided for @sameTimeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No photos taken at the same time'**
  String get sameTimeEmpty;

  /// No description provided for @sameTimeDayHeader.
  ///
  /// In en, this message translates to:
  /// **'{date} · {count, plural, =1{1 group} other{{count} groups}}'**
  String sameTimeDayHeader(String date, int count);

  /// No description provided for @sameTimeGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}} · {start}–{end}'**
  String sameTimeGroupTitle(int count, String start, String end);

  /// No description provided for @sameTimeMore.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String sameTimeMore(int count);

  /// No description provided for @sameTimeSelectGroup.
  ///
  /// In en, this message translates to:
  /// **'Select group'**
  String get sameTimeSelectGroup;

  /// No description provided for @settingsSameTimeWindow.
  ///
  /// In en, this message translates to:
  /// **'Same time window'**
  String get settingsSameTimeWindow;

  /// No description provided for @fileMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'File actions'**
  String get fileMenuTooltip;

  /// No description provided for @fileMenuRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get fileMenuRename;

  /// No description provided for @fileMenuDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get fileMenuDuplicate;

  /// No description provided for @fileMenuCopyTo.
  ///
  /// In en, this message translates to:
  /// **'Copy to…'**
  String get fileMenuCopyTo;

  /// No description provided for @fileMenuMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to…'**
  String get fileMenuMoveTo;

  /// No description provided for @fileMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get fileMenuDelete;

  /// No description provided for @selectionActionMove.
  ///
  /// In en, this message translates to:
  /// **'Move to…'**
  String get selectionActionMove;

  /// No description provided for @selectionActionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy to…'**
  String get selectionActionCopy;

  /// No description provided for @selectionActionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get selectionActionDuplicate;

  /// No description provided for @selectionActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get selectionActionDelete;

  /// No description provided for @renameFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename folder'**
  String get renameFolderTitle;

  /// No description provided for @renameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameAction;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @nameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Names can\'t be empty, contain / \\ : * ? \" < > | or be longer than 255 bytes'**
  String get nameInvalid;

  /// No description provided for @nameExists.
  ///
  /// In en, this message translates to:
  /// **'Something with that name already exists here'**
  String get nameExists;

  /// No description provided for @opMovedSummary.
  ///
  /// In en, this message translates to:
  /// **'{done, plural, =1{Moved 1 file to {folder}} other{Moved {done} files to {folder}}}'**
  String opMovedSummary(int done, String folder);

  /// No description provided for @opCopiedSummary.
  ///
  /// In en, this message translates to:
  /// **'{done, plural, =1{Copied 1 file to {folder}} other{Copied {done} files to {folder}}}'**
  String opCopiedSummary(int done, String folder);

  /// No description provided for @opDuplicatedSummary.
  ///
  /// In en, this message translates to:
  /// **'{done, plural, =1{Duplicated 1 file} other{Duplicated {done} files}}'**
  String opDuplicatedSummary(int done);

  /// No description provided for @opRenamedSummary.
  ///
  /// In en, this message translates to:
  /// **'Renamed to {name}'**
  String opRenamedSummary(String name);

  /// No description provided for @opTrashedSummary.
  ///
  /// In en, this message translates to:
  /// **'{done, plural, =1{Moved 1 file to trash} other{Moved {done} files to trash}}'**
  String opTrashedSummary(int done);

  /// No description provided for @opDeletedSummary.
  ///
  /// In en, this message translates to:
  /// **'{done, plural, =1{Deleted 1 file permanently} other{Deleted {done} files permanently}}'**
  String opDeletedSummary(int done);

  /// No description provided for @opFailedSummary.
  ///
  /// In en, this message translates to:
  /// **'{failed, plural, =1{1 failed} other{{failed} failed}}'**
  String opFailedSummary(int failed);

  /// No description provided for @opSkippedSummary.
  ///
  /// In en, this message translates to:
  /// **'{skipped, plural, =1{1 skipped} other{{skipped} skipped}}'**
  String opSkippedSummary(int skipped);

  /// No description provided for @opCancelledSummary.
  ///
  /// In en, this message translates to:
  /// **'Stopped: {done} of {total} done'**
  String opCancelledSummary(int done, int total);

  /// No description provided for @opSkippedNeedAccess.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file skipped (needs All files access)} other{{count} files skipped (need All files access)}}'**
  String opSkippedNeedAccess(int count);

  /// No description provided for @opUndone.
  ///
  /// In en, this message translates to:
  /// **'Undone'**
  String get opUndone;

  /// No description provided for @opUndoStopped.
  ///
  /// In en, this message translates to:
  /// **'Undo stopped: {done} of {total} undone'**
  String opUndoStopped(int done, int total);

  /// No description provided for @opUndoLast.
  ///
  /// In en, this message translates to:
  /// **'Undo last file operation'**
  String get opUndoLast;

  /// No description provided for @opUndoMissing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file no longer exists and wasn\'t undone} other{{count} files no longer exist and weren\'t undone}}'**
  String opUndoMissing(int count);

  /// No description provided for @opSpaceRefused.
  ///
  /// In en, this message translates to:
  /// **'Not enough space (needs {needed}, {free} free)'**
  String opSpaceRefused(String needed, String free);

  /// No description provided for @opFolderRenamed.
  ///
  /// In en, this message translates to:
  /// **'Folder renamed to {name}'**
  String opFolderRenamed(String name);

  /// No description provided for @collisionTitle.
  ///
  /// In en, this message translates to:
  /// **'Name already used'**
  String get collisionTitle;

  /// No description provided for @collisionBody.
  ///
  /// In en, this message translates to:
  /// **'{name} already exists in {folder}'**
  String collisionBody(String name, String folder);

  /// No description provided for @collisionReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get collisionReplace;

  /// No description provided for @collisionKeepBoth.
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get collisionKeepBoth;

  /// No description provided for @collisionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get collisionSkip;

  /// No description provided for @collisionApplyAll.
  ///
  /// In en, this message translates to:
  /// **'Do this for all remaining'**
  String get collisionApplyAll;

  /// No description provided for @progressMoving.
  ///
  /// In en, this message translates to:
  /// **'Moving {done} of {total}'**
  String progressMoving(int done, int total);

  /// No description provided for @progressCopying.
  ///
  /// In en, this message translates to:
  /// **'Copying {done} of {total}'**
  String progressCopying(int done, int total);

  /// No description provided for @progressDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting {done} of {total}'**
  String progressDeleting(int done, int total);

  /// No description provided for @progressUndoing.
  ///
  /// In en, this message translates to:
  /// **'Undoing {done} of {total}'**
  String progressUndoing(int done, int total);

  /// No description provided for @progressWorking.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get progressWorking;

  /// No description provided for @permanentConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get permanentConfirmAction;

  /// No description provided for @opPermanentConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently?'**
  String get opPermanentConfirmTitle;

  /// No description provided for @opPermanentConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Permanently delete 1 file ({size})? This can\'t be undone.} other{Permanently delete {count} files ({size})? This can\'t be undone.}}'**
  String opPermanentConfirmBody(int count, String size);

  /// No description provided for @pendingFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t use the trash folder'**
  String get pendingFallbackTitle;

  /// No description provided for @pendingFallbackBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Couldn\'t move 1 file to the trash folder. Delete it permanently instead?} other{Couldn\'t move {count} files to the trash folder. Delete them permanently instead?}}'**
  String pendingFallbackBody(int count);

  /// No description provided for @pendingFallbackAction.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get pendingFallbackAction;

  /// No description provided for @pickerMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to'**
  String get pickerMoveTitle;

  /// No description provided for @pickerCopyTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy to'**
  String get pickerCopyTitle;

  /// No description provided for @pickerAllFolders.
  ///
  /// In en, this message translates to:
  /// **'All folders'**
  String get pickerAllFolders;

  /// No description provided for @pickerMoveHere.
  ///
  /// In en, this message translates to:
  /// **'Move here'**
  String get pickerMoveHere;

  /// No description provided for @pickerCopyHere.
  ///
  /// In en, this message translates to:
  /// **'Copy here'**
  String get pickerCopyHere;

  /// No description provided for @pickerChooseHere.
  ///
  /// In en, this message translates to:
  /// **'Use this folder'**
  String get pickerChooseHere;

  /// No description provided for @pickerCurrentFolder.
  ///
  /// In en, this message translates to:
  /// **'Current folder'**
  String get pickerCurrentFolder;

  /// No description provided for @browseNewFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get browseNewFolder;

  /// No description provided for @browseFolderCreated.
  ///
  /// In en, this message translates to:
  /// **'Created {name}'**
  String browseFolderCreated(String name);

  /// No description provided for @settingsFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get settingsFiles;

  /// No description provided for @settingsDropAction.
  ///
  /// In en, this message translates to:
  /// **'Dropping files on a folder'**
  String get settingsDropAction;

  /// No description provided for @dropActionMove.
  ///
  /// In en, this message translates to:
  /// **'Moves them'**
  String get dropActionMove;

  /// No description provided for @dropActionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copies them'**
  String get dropActionCopy;

  /// No description provided for @fileOpRenameFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t rename {name}'**
  String fileOpRenameFailed(String name);

  /// No description provided for @fileOpFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t finish for {name}'**
  String fileOpFailedGeneric(String name);

  /// No description provided for @fileOpNotFound.
  ///
  /// In en, this message translates to:
  /// **'{name} no longer exists'**
  String fileOpNotFound(String name);

  /// No description provided for @fileOpPermission.
  ///
  /// In en, this message translates to:
  /// **'No permission to change {name}'**
  String fileOpPermission(String name);

  /// No description provided for @progressCompressing.
  ///
  /// In en, this message translates to:
  /// **'Zipping {done} of {total}'**
  String progressCompressing(String done, String total);

  /// No description provided for @progressExtracting.
  ///
  /// In en, this message translates to:
  /// **'Extracting {done} of {total}'**
  String progressExtracting(String done, String total);

  /// No description provided for @progressEtaMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{About 1 minute left} other{About {minutes} minutes left}}'**
  String progressEtaMinutes(int minutes);

  /// No description provided for @archiveCompress.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get archiveCompress;

  /// No description provided for @archiveViewContents.
  ///
  /// In en, this message translates to:
  /// **'View contents'**
  String get archiveViewContents;

  /// No description provided for @archiveExtractHere.
  ///
  /// In en, this message translates to:
  /// **'Extract here'**
  String get archiveExtractHere;

  /// No description provided for @archiveExtractTo.
  ///
  /// In en, this message translates to:
  /// **'Extract to…'**
  String get archiveExtractTo;

  /// No description provided for @archiveExtractThis.
  ///
  /// In en, this message translates to:
  /// **'Extract this'**
  String get archiveExtractThis;

  /// No description provided for @archiveExtractToTitle.
  ///
  /// In en, this message translates to:
  /// **'Extract to'**
  String get archiveExtractToTitle;

  /// No description provided for @archiveCompressTitle.
  ///
  /// In en, this message translates to:
  /// **'Compress to zip'**
  String get archiveCompressTitle;

  /// No description provided for @archiveCompressAction.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get archiveCompressAction;

  /// No description provided for @archiveSaveIn.
  ///
  /// In en, this message translates to:
  /// **'Saved in {folder}'**
  String archiveSaveIn(String folder);

  /// No description provided for @archiveSaveTo.
  ///
  /// In en, this message translates to:
  /// **'Save to…'**
  String get archiveSaveTo;

  /// No description provided for @archiveSaveToTitle.
  ///
  /// In en, this message translates to:
  /// **'Save zip in'**
  String get archiveSaveToTitle;

  /// No description provided for @archiveWrongPlace.
  ///
  /// In en, this message translates to:
  /// **'Can\'t zip files from this place yet'**
  String get archiveWrongPlace;

  /// No description provided for @archiveCreated.
  ///
  /// In en, this message translates to:
  /// **'Created {name}'**
  String archiveCreated(String name);

  /// No description provided for @archiveExtracted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing to extract} =1{Extracted 1 file to {folder}} other{Extracted {count} files to {folder}}}'**
  String archiveExtracted(int count, String folder);

  /// No description provided for @archiveBombTitle.
  ///
  /// In en, this message translates to:
  /// **'Very large archive'**
  String get archiveBombTitle;

  /// No description provided for @archiveBombBody.
  ///
  /// In en, this message translates to:
  /// **'This archive expands to {size}. Extract anyway?'**
  String archiveBombBody(String size);

  /// No description provided for @archiveBombAction.
  ///
  /// In en, this message translates to:
  /// **'Extract anyway'**
  String get archiveBombAction;

  /// No description provided for @archiveUnsafePaths.
  ///
  /// In en, this message translates to:
  /// **'This archive contains unsafe paths and was not extracted'**
  String get archiveUnsafePaths;

  /// No description provided for @archiveCorrupt.
  ///
  /// In en, this message translates to:
  /// **'This zip is damaged or not a zip file'**
  String get archiveCorrupt;

  /// No description provided for @archiveCancelled.
  ///
  /// In en, this message translates to:
  /// **'Stopped. Nothing was saved'**
  String get archiveCancelled;

  /// No description provided for @archiveIoError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read or write {name}'**
  String archiveIoError(String name);

  /// No description provided for @archivePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Password needed'**
  String get archivePasswordTitle;

  /// No description provided for @archivePasswordBody.
  ///
  /// In en, this message translates to:
  /// **'{name} is protected with a password'**
  String archivePasswordBody(String name);

  /// No description provided for @archivePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get archivePasswordLabel;

  /// No description provided for @archivePasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Extract'**
  String get archivePasswordAction;

  /// No description provided for @archiveWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password, try again'**
  String get archiveWrongPassword;

  /// No description provided for @archivePasswordShow.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get archivePasswordShow;

  /// No description provided for @archivePasswordHide.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get archivePasswordHide;

  /// No description provided for @archiveSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item · {size}} other{{count} items · {size}}}'**
  String archiveSummary(int count, String size);

  /// No description provided for @archiveEmpty.
  ///
  /// In en, this message translates to:
  /// **'This zip is empty'**
  String get archiveEmpty;

  /// No description provided for @archiveWrongDestination.
  ///
  /// In en, this message translates to:
  /// **'Can\'t save to this place yet. Pick a folder on internal storage'**
  String get archiveWrongDestination;

  /// No description provided for @archiveReplaceFailed.
  ///
  /// In en, this message translates to:
  /// **'The old zip was kept. The new one is saved as {name}'**
  String archiveReplaceFailed(String name);

  /// No description provided for @collectionsOpen.
  ///
  /// In en, this message translates to:
  /// **'Tags & favorites'**
  String get collectionsOpen;

  /// No description provided for @collectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags & favorites'**
  String get collectionsTitle;

  /// No description provided for @collectionsFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get collectionsFavorites;

  /// No description provided for @collectionsTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get collectionsTags;

  /// No description provided for @collectionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tags yet. Tag files from Browse, or set a swipe direction to “Add tag” in swipe settings.'**
  String get collectionsEmpty;

  /// No description provided for @collectionsFileCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No files} =1{1 file} other{{count} files}}'**
  String collectionsFileCount(int count);

  /// No description provided for @collectionsTagMenu.
  ///
  /// In en, this message translates to:
  /// **'Tag options'**
  String get collectionsTagMenu;

  /// No description provided for @tagMenuEdit.
  ///
  /// In en, this message translates to:
  /// **'Rename or change color'**
  String get tagMenuEdit;

  /// No description provided for @tagMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete tag'**
  String get tagMenuDelete;

  /// No description provided for @tagEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit tag'**
  String get tagEditTitle;

  /// No description provided for @tagSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get tagSave;

  /// No description provided for @tagDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete tag “{name}”?'**
  String tagDeleteTitle(String name);

  /// No description provided for @tagDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No files have this tag.} =1{The file stays; only the tag is removed.} other{The {count} files stay; only the tag is removed.}}'**
  String tagDeleteBody(int count);

  /// No description provided for @tagDeleteUsedIn.
  ///
  /// In en, this message translates to:
  /// **'Used in: {places}. That direction will show “Tag no longer exists” until you pick another.'**
  String tagDeleteUsedIn(String places);

  /// No description provided for @tagUsedCurrentSetup.
  ///
  /// In en, this message translates to:
  /// **'current swipe setup'**
  String get tagUsedCurrentSetup;

  /// No description provided for @tagDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tagDeleteConfirm;

  /// No description provided for @tagDeleted.
  ///
  /// In en, this message translates to:
  /// **'Tag “{name}” deleted'**
  String tagDeleted(String name);

  /// No description provided for @tagGone.
  ///
  /// In en, this message translates to:
  /// **'This tag was deleted'**
  String get tagGone;

  /// No description provided for @fileMenuFavoriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get fileMenuFavoriteAdd;

  /// No description provided for @fileMenuFavoriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get fileMenuFavoriteRemove;

  /// No description provided for @fileMenuTags.
  ///
  /// In en, this message translates to:
  /// **'Tags…'**
  String get fileMenuTags;

  /// No description provided for @selectionTagsMenu.
  ///
  /// In en, this message translates to:
  /// **'Tags & favorites…'**
  String get selectionTagsMenu;

  /// No description provided for @selectionTagAdd.
  ///
  /// In en, this message translates to:
  /// **'Add tag…'**
  String get selectionTagAdd;

  /// No description provided for @selectionTagRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove tag…'**
  String get selectionTagRemove;

  /// No description provided for @tagRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove a tag'**
  String get tagRemoveTitle;

  /// No description provided for @tagRemoveNone.
  ///
  /// In en, this message translates to:
  /// **'None of these files have tags'**
  String get tagRemoveNone;

  /// No description provided for @fileTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get fileTagsTitle;

  /// No description provided for @tagAddedSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{All files already had “{tag}”} =1{Tagged 1 file “{tag}”} other{Tagged {count} files “{tag}”}}'**
  String tagAddedSummary(int count, String tag);

  /// No description provided for @tagRemovedSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No file had “{tag}”} =1{Removed “{tag}” from 1 file} other{Removed “{tag}” from {count} files}}'**
  String tagRemovedSummary(int count, String tag);

  /// No description provided for @favoriteAddedSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Already in favorites} =1{Added 1 file to favorites} other{Added {count} files to favorites}}'**
  String favoriteAddedSummary(int count);

  /// No description provided for @favoriteRemovedSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Not in favorites} =1{Removed 1 file from favorites} other{Removed {count} files from favorites}}'**
  String favoriteRemovedSummary(int count);

  /// No description provided for @tagWriteError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the change. Try again'**
  String get tagWriteError;

  /// No description provided for @swipeSourceSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected files'**
  String get swipeSourceSelectionTitle;

  /// No description provided for @sameTimeSwipeGroup.
  ///
  /// In en, this message translates to:
  /// **'Swipe this group'**
  String get sameTimeSwipeGroup;

  /// No description provided for @swipeSourceClose.
  ///
  /// In en, this message translates to:
  /// **'Back to all files'**
  String get swipeSourceClose;

  /// No description provided for @swipeSourceGroupPosition.
  ///
  /// In en, this message translates to:
  /// **'Group {group} of {groupCount} · {index}/{groupSize}'**
  String swipeSourceGroupPosition(
    int group,
    int groupCount,
    int index,
    int groupSize,
  );

  /// No description provided for @swipeSourceDone.
  ///
  /// In en, this message translates to:
  /// **'All done in {title}'**
  String swipeSourceDone(String title);

  /// No description provided for @swipeSourceBackToMain.
  ///
  /// In en, this message translates to:
  /// **'Back to swiping'**
  String get swipeSourceBackToMain;

  /// No description provided for @swipeSourceBackToOrigin.
  ///
  /// In en, this message translates to:
  /// **'Back to {origin}'**
  String swipeSourceBackToOrigin(String origin);

  /// No description provided for @swipeSourceRestored.
  ///
  /// In en, this message translates to:
  /// **'Continued in {title}'**
  String swipeSourceRestored(String title);

  /// No description provided for @swipeSourcePendingLine.
  ///
  /// In en, this message translates to:
  /// **'Opens: {title}'**
  String swipeSourcePendingLine(String title);

  /// No description provided for @swipeSourceSkipped.
  ///
  /// In en, this message translates to:
  /// **'{files, plural, =1{Swiping 1 file} other{Swiping {files} files}} · {skipped, plural, =1{1 can\'t be swiped here} other{{skipped} can\'t be swiped here}} (photos and videos only)'**
  String swipeSourceSkipped(int files, int skipped);

  /// No description provided for @swipeSourceTruncated.
  ///
  /// In en, this message translates to:
  /// **'Showing the first 10,000 files'**
  String get swipeSourceTruncated;

  /// No description provided for @swipeSourceEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to swipe here'**
  String get swipeSourceEmpty;

  /// No description provided for @swipeSourceNoMedia.
  ///
  /// In en, this message translates to:
  /// **'Only photos and videos can be swiped'**
  String get swipeSourceNoMedia;

  /// No description provided for @swipeSourceInvalidFilter.
  ///
  /// In en, this message translates to:
  /// **'This filter can\'t be used'**
  String get swipeSourceInvalidFilter;

  /// No description provided for @swipeSourceNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No photos or videos match'**
  String get swipeSourceNoMatches;

  /// No description provided for @swipeSourceOriginStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage overview'**
  String get swipeSourceOriginStorage;

  /// No description provided for @swipeSourceOriginSimilar.
  ///
  /// In en, this message translates to:
  /// **'Similar photos'**
  String get swipeSourceOriginSimilar;

  /// No description provided for @swipeSourceOriginSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get swipeSourceOriginSearch;

  /// No description provided for @swipeSourceOriginGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get swipeSourceOriginGroups;

  /// No description provided for @swipeSourceOriginSameTime.
  ///
  /// In en, this message translates to:
  /// **'Same time'**
  String get swipeSourceOriginSameTime;

  /// No description provided for @swipeSourceOriginBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get swipeSourceOriginBrowse;

  /// No description provided for @swipeSourceOriginSharedIn.
  ///
  /// In en, this message translates to:
  /// **'Shared files'**
  String get swipeSourceOriginSharedIn;

  /// No description provided for @swipeSourceOriginCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get swipeSourceOriginCloud;

  /// No description provided for @swipeSourceOriginExternal.
  ///
  /// In en, this message translates to:
  /// **'External storage'**
  String get swipeSourceOriginExternal;

  /// No description provided for @swipeSourceOriginOther.
  ///
  /// In en, this message translates to:
  /// **'Previous screen'**
  String get swipeSourceOriginOther;

  /// No description provided for @storageOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage overview'**
  String get storageOverviewTitle;

  /// No description provided for @storageUsedFree.
  ///
  /// In en, this message translates to:
  /// **'{used} used · {free} free'**
  String storageUsedFree(String used, String free);

  /// No description provided for @storageSpaceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Free space unknown'**
  String get storageSpaceUnknown;

  /// No description provided for @storageScanning.
  ///
  /// In en, this message translates to:
  /// **'Still scanning… the numbers keep growing'**
  String get storageScanning;

  /// No description provided for @storageCatVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get storageCatVideos;

  /// No description provided for @storageCatScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get storageCatScreenshots;

  /// No description provided for @storageCatBigFiles.
  ///
  /// In en, this message translates to:
  /// **'Big files (over {size})'**
  String storageCatBigFiles(String size);

  /// No description provided for @storageCatWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get storageCatWhatsapp;

  /// No description provided for @storageCatDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get storageCatDownloads;

  /// No description provided for @storageCategorySummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No files} =1{1 file · {size}} other{{count} files · {size}}}'**
  String storageCategorySummary(int count, String size);

  /// No description provided for @storageCleanUp.
  ///
  /// In en, this message translates to:
  /// **'Clean up'**
  String get storageCleanUp;

  /// No description provided for @storageCleanUpMediaOnly.
  ///
  /// In en, this message translates to:
  /// **'Clean up shows photos and videos only'**
  String get storageCleanUpMediaOnly;

  /// No description provided for @storageNeedsAccess.
  ///
  /// In en, this message translates to:
  /// **'Turn on All files access to see these files'**
  String get storageNeedsAccess;

  /// No description provided for @storageOverlapNote.
  ///
  /// In en, this message translates to:
  /// **'A file can be in more than one category.'**
  String get storageOverlapNote;

  /// No description provided for @storageBiggestFiles.
  ///
  /// In en, this message translates to:
  /// **'Biggest files'**
  String get storageBiggestFiles;

  /// No description provided for @storageWhatsappHint.
  ///
  /// In en, this message translates to:
  /// **'Includes WhatsApp\'s hidden Sent and Status folders'**
  String get storageWhatsappHint;

  /// No description provided for @storageBigFileThreshold.
  ///
  /// In en, this message translates to:
  /// **'Big files start at'**
  String get storageBigFileThreshold;

  /// No description provided for @similarTitle.
  ///
  /// In en, this message translates to:
  /// **'Similar photos'**
  String get similarTitle;

  /// No description provided for @similarSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Similar photos'**
  String get similarSourceTitle;

  /// No description provided for @similarStorageHint.
  ///
  /// In en, this message translates to:
  /// **'Look-alike and blurry photos'**
  String get similarStorageHint;

  /// No description provided for @similarTabSimilar.
  ///
  /// In en, this message translates to:
  /// **'Similar'**
  String get similarTabSimilar;

  /// No description provided for @similarTabBlurry.
  ///
  /// In en, this message translates to:
  /// **'Blurry'**
  String get similarTabBlurry;

  /// No description provided for @similarStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Find similar and blurry photos'**
  String get similarStartTitle;

  /// No description provided for @similarStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get similarStart;

  /// No description provided for @similarChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking photos… {done} of {total}'**
  String similarChecking(int done, int total);

  /// No description provided for @similarGrouping.
  ///
  /// In en, this message translates to:
  /// **'Grouping look-alike photos…'**
  String get similarGrouping;

  /// No description provided for @similarNoGroups.
  ///
  /// In en, this message translates to:
  /// **'No similar photos found yet'**
  String get similarNoGroups;

  /// No description provided for @similarNoBlurry.
  ///
  /// In en, this message translates to:
  /// **'No blurry photos found'**
  String get similarNoBlurry;

  /// No description provided for @similarGroupCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo} other{{count} photos}}'**
  String similarGroupCount(int count);

  /// No description provided for @similarBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get similarBest;

  /// No description provided for @similarKeepBest.
  ///
  /// In en, this message translates to:
  /// **'Keep best, remove others'**
  String get similarKeepBest;

  /// No description provided for @similarSwipeGroup.
  ///
  /// In en, this message translates to:
  /// **'Swipe this group'**
  String get similarSwipeGroup;

  /// No description provided for @similarSwipeAll.
  ///
  /// In en, this message translates to:
  /// **'Swipe all groups'**
  String get similarSwipeAll;

  /// No description provided for @similarCleanDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Clean duplicates'**
  String get similarCleanDuplicates;

  /// No description provided for @similarRemoved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Removed 1 photo} other{Removed {count} photos}}'**
  String similarRemoved(int count);

  /// No description provided for @similarKeptAll.
  ///
  /// In en, this message translates to:
  /// **'Kept all photos'**
  String get similarKeptAll;

  /// No description provided for @similarBlurryHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick, long-press to view'**
  String get similarBlurryHint;

  /// No description provided for @similarRemoveCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Remove} other{Remove {count}}}'**
  String similarRemoveCount(int count);

  /// No description provided for @similarCleanProgress.
  ///
  /// In en, this message translates to:
  /// **'Group {group} of {total} · keeping {keep}'**
  String similarCleanProgress(int group, int total, int keep);

  /// No description provided for @similarCleanDone.
  ///
  /// In en, this message translates to:
  /// **'All groups done'**
  String get similarCleanDone;

  /// No description provided for @similarSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get similarSkip;

  /// No description provided for @similarNextGroup.
  ///
  /// In en, this message translates to:
  /// **'Next group'**
  String get similarNextGroup;

  /// Keep this photo of a group of look-alike photos.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get similarKeep;

  /// No description provided for @similarRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get similarRemove;

  /// No description provided for @similarSettingEnabled.
  ///
  /// In en, this message translates to:
  /// **'Find similar and blurry photos'**
  String get similarSettingEnabled;

  /// No description provided for @similarSettingEnabledHint.
  ///
  /// In en, this message translates to:
  /// **'Checks photos in the background while KFM is open'**
  String get similarSettingEnabledHint;

  /// No description provided for @similarSettingStrictness.
  ///
  /// In en, this message translates to:
  /// **'How alike'**
  String get similarSettingStrictness;

  /// No description provided for @similarStrictnessLoose.
  ///
  /// In en, this message translates to:
  /// **'Loosely alike'**
  String get similarStrictnessLoose;

  /// No description provided for @similarStrictnessNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get similarStrictnessNormal;

  /// No description provided for @similarStrictnessStrict.
  ///
  /// In en, this message translates to:
  /// **'Nearly identical'**
  String get similarStrictnessStrict;

  /// No description provided for @similarSettingScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Include screenshots'**
  String get similarSettingScreenshots;

  /// No description provided for @groupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsTitle;

  /// No description provided for @groupsScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get groupsScreenshots;

  /// No description provided for @groupsSelfies.
  ///
  /// In en, this message translates to:
  /// **'Selfies (automatic)'**
  String get groupsSelfies;

  /// No description provided for @groupsDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get groupsDocuments;

  /// No description provided for @groupsTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get groupsTrips;

  /// Smart groups by photo location (towns, countries), not storage places.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get groupsPlaces;

  /// No description provided for @smartGroupPlace.
  ///
  /// In en, this message translates to:
  /// **'Place {n}'**
  String smartGroupPlace(int n);

  /// Automatic trip title: its date range.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String smartGroupTrip(DateTime start, DateTime end);

  /// No description provided for @groupsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String groupsCount(int count);

  /// No description provided for @groupsProgress.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{Finding trips and places… {done} of 1 photo} other{Finding trips and places… {done} of {total} photos}}'**
  String groupsProgress(int done, int total);

  /// No description provided for @groupsGrouping.
  ///
  /// In en, this message translates to:
  /// **'Grouping trips and places…'**
  String get groupsGrouping;

  /// No description provided for @groupsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No groups yet. Trips and places appear here as KFM finds them.'**
  String get groupsEmpty;

  /// No description provided for @groupsRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get groupsRename;

  /// No description provided for @groupsRenameHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for the automatic name'**
  String get groupsRenameHint;

  /// No description provided for @groupsRenameSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get groupsRenameSave;

  /// No description provided for @groupsRenameCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get groupsRenameCancel;

  /// No description provided for @groupsChanged.
  ///
  /// In en, this message translates to:
  /// **'This group changed'**
  String get groupsChanged;

  /// No description provided for @groupsChangedBody.
  ///
  /// In en, this message translates to:
  /// **'Trips and places are recalculated as photos are added or removed.'**
  String get groupsChangedBody;

  /// No description provided for @groupsBack.
  ///
  /// In en, this message translates to:
  /// **'Back to groups'**
  String get groupsBack;

  /// No description provided for @groupsSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe this group'**
  String get groupsSwipe;

  /// No description provided for @groupsLocationRow.
  ///
  /// In en, this message translates to:
  /// **'Allow location access to group photos by place'**
  String get groupsLocationRow;

  /// No description provided for @groupsOnlineNames.
  ///
  /// In en, this message translates to:
  /// **'Look up place names online'**
  String get groupsOnlineNames;

  /// No description provided for @groupsOnlineNamesHelp.
  ///
  /// In en, this message translates to:
  /// **'Sends the approximate centre of each place group to your phone\'s geocoding service to get names like \'Paris\''**
  String get groupsOnlineNamesHelp;

  /// No description provided for @groupsJobError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the groups. They\'ll be tried again later.'**
  String get groupsJobError;

  /// No description provided for @groupsFailedFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo couldn\'t be read} other{{count} photos couldn\'t be read}}'**
  String groupsFailedFiles(int count);

  /// Automatic title of a one-day trip.
  ///
  /// In en, this message translates to:
  /// **'{day}'**
  String smartGroupTripOneDay(DateTime day);

  /// No description provided for @aiLabelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo labels (AI)'**
  String get aiLabelsTitle;

  /// No description provided for @aiLabelsEnableHint.
  ///
  /// In en, this message translates to:
  /// **'Find photos by what\'s in them, like cat, beach or food'**
  String get aiLabelsEnableHint;

  /// No description provided for @aiLabelsEnableNeedsModels.
  ///
  /// In en, this message translates to:
  /// **'Download the AI models first'**
  String get aiLabelsEnableNeedsModels;

  /// No description provided for @aiLabelsPause.
  ///
  /// In en, this message translates to:
  /// **'Pause labeling'**
  String get aiLabelsPause;

  /// No description provided for @aiLabelsResume.
  ///
  /// In en, this message translates to:
  /// **'Resume labeling'**
  String get aiLabelsResume;

  /// No description provided for @aiLabelsPausedLine.
  ///
  /// In en, this message translates to:
  /// **'Labeling is paused'**
  String get aiLabelsPausedLine;

  /// No description provided for @aiLabelsProgress.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{{processed} of 1 photo labeled} other{{processed} of {total} photos labeled}}'**
  String aiLabelsProgress(int processed, int total);

  /// No description provided for @aiLabelsFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo couldn\'t be labeled} other{{count} photos couldn\'t be labeled}}'**
  String aiLabelsFailed(int count);

  /// No description provided for @aiLabelsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset labels'**
  String get aiLabelsReset;

  /// No description provided for @aiLabelsResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset all photo labels?'**
  String get aiLabelsResetConfirm;

  /// No description provided for @aiLabelsResetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Every photo will be labeled again from the start.'**
  String get aiLabelsResetConfirmBody;

  /// No description provided for @aiLabelsResetAction.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get aiLabelsResetAction;

  /// No description provided for @aiLabelsJobError.
  ///
  /// In en, this message translates to:
  /// **'The AI models are missing or changed, so labeling stopped. Download them again.'**
  String get aiLabelsJobError;

  /// No description provided for @aiLabelsCrashError.
  ///
  /// In en, this message translates to:
  /// **'Labeling stopped after an error. It will be tried again later.'**
  String get aiLabelsCrashError;

  /// No description provided for @aiLabelsNeedsAndroid8.
  ///
  /// In en, this message translates to:
  /// **'Needs Android 8 or newer'**
  String get aiLabelsNeedsAndroid8;

  /// No description provided for @aiLabelsUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device yet'**
  String get aiLabelsUnsupported;

  /// No description provided for @aiLabelsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Find photos by what\'s in them (cat, beach, food…)'**
  String get aiLabelsCardTitle;

  /// No description provided for @aiLabelsCardTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get aiLabelsCardTurnOn;

  /// No description provided for @aiLabelsCardNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get aiLabelsCardNotNow;

  /// No description provided for @aiLabelsTurnedOn.
  ///
  /// In en, this message translates to:
  /// **'Photo labeling is on'**
  String get aiLabelsTurnedOn;

  /// No description provided for @aiCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get aiCancel;

  /// No description provided for @aiModelsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI models'**
  String get aiModelsTitle;

  /// No description provided for @aiModelsNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'AI models not downloaded'**
  String get aiModelsNotDownloaded;

  /// No description provided for @aiModelsAbout.
  ///
  /// In en, this message translates to:
  /// **'About AI models / Download…'**
  String get aiModelsAbout;

  /// No description provided for @aiModelsChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking AI models…'**
  String get aiModelsChecking;

  /// No description provided for @aiModelsDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading {done} of {total} MB'**
  String aiModelsDownloading(double done, double total);

  /// No description provided for @aiModelsWaitingWifi.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Wi-Fi'**
  String get aiModelsWaitingWifi;

  /// No description provided for @aiModelsVerifying.
  ///
  /// In en, this message translates to:
  /// **'Checking the download…'**
  String get aiModelsVerifying;

  /// No description provided for @aiModelsInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed, {size} MB'**
  String aiModelsInstalled(double size);

  /// No description provided for @aiModelsNeedUpdate.
  ///
  /// In en, this message translates to:
  /// **'AI models need an update — download again'**
  String get aiModelsNeedUpdate;

  /// No description provided for @aiModelsPartial.
  ///
  /// In en, this message translates to:
  /// **'Download paused at {done} of {total} MB'**
  String aiModelsPartial(double done, double total);

  /// No description provided for @aiModelsErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Download failed: no connection.'**
  String get aiModelsErrorNetwork;

  /// No description provided for @aiModelsErrorHttp.
  ///
  /// In en, this message translates to:
  /// **'Download failed (server error {code}).'**
  String aiModelsErrorHttp(String code);

  /// No description provided for @aiModelsErrorChecksum.
  ///
  /// In en, this message translates to:
  /// **'The downloaded file didn\'t match the expected one. It was deleted and nothing was installed.'**
  String get aiModelsErrorChecksum;

  /// No description provided for @aiModelsErrorDiskFull.
  ///
  /// In en, this message translates to:
  /// **'Download failed: not enough free space.'**
  String get aiModelsErrorDiskFull;

  /// No description provided for @aiModelsErrorOther.
  ///
  /// In en, this message translates to:
  /// **'Download failed.'**
  String get aiModelsErrorOther;

  /// No description provided for @aiModelsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get aiModelsRetry;

  /// No description provided for @aiModelsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get aiModelsCancel;

  /// No description provided for @aiModelsWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Download on Wi-Fi only'**
  String get aiModelsWifiOnly;

  /// No description provided for @aiModelsUseMobileData.
  ///
  /// In en, this message translates to:
  /// **'Use mobile data this time'**
  String get aiModelsUseMobileData;

  /// No description provided for @aiModelsWillUseWifi.
  ///
  /// In en, this message translates to:
  /// **'Will download on Wi-Fi'**
  String get aiModelsWillUseWifi;

  /// No description provided for @aiModelsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove AI models'**
  String get aiModelsRemove;

  /// No description provided for @aiModelsRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove AI models ({size} MB)?'**
  String aiModelsRemoveTitle(double size);

  /// No description provided for @aiModelsRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'New photos won\'t be labeled anymore. You can download the models again later.'**
  String get aiModelsRemoveBody;

  /// No description provided for @aiModelsRemoveAlsoLabels.
  ///
  /// In en, this message translates to:
  /// **'Also delete the photo labels'**
  String get aiModelsRemoveAlsoLabels;

  /// No description provided for @aiModelsRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get aiModelsRemoveConfirm;

  /// No description provided for @aiModelsDetailsIntro.
  ///
  /// In en, this message translates to:
  /// **'KFM can label your photos (cat, beach, food, person…) so you can find them by what\'s in them. This needs two small AI models that are not part of the app. They are downloaded only if you tap Download.'**
  String get aiModelsDetailsIntro;

  /// No description provided for @aiModelsHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get aiModelsHowTitle;

  /// No description provided for @aiModelsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get aiModelsPrivacyTitle;

  /// No description provided for @aiModelsBatteryBody.
  ///
  /// In en, this message translates to:
  /// **'Labeling runs while KFM is open and pauses when the battery is below 20% and not charging.'**
  String get aiModelsBatteryBody;

  /// No description provided for @aiModelsRemovableBody.
  ///
  /// In en, this message translates to:
  /// **'You can remove the models at any time in Settings.'**
  String get aiModelsRemovableBody;

  /// No description provided for @aiModelsDownloadButton.
  ///
  /// In en, this message translates to:
  /// **'Download ({size} MB)'**
  String aiModelsDownloadButton(double size);

  /// No description provided for @aiModelsInstalledDone.
  ///
  /// In en, this message translates to:
  /// **'AI models installed. Labeling is on.'**
  String get aiModelsInstalledDone;

  /// No description provided for @aiModelClassifierWhat.
  ///
  /// In en, this message translates to:
  /// **'Image classifier: recognises about 1,000 kinds of objects, animals, food and scenes.'**
  String get aiModelClassifierWhat;

  /// No description provided for @aiModelClassifierUse.
  ///
  /// In en, this message translates to:
  /// **'KFM uses it for labels like cat, dog, bird, food, beach, mountain, car and document.'**
  String get aiModelClassifierUse;

  /// No description provided for @aiModelDetectorWhat.
  ///
  /// In en, this message translates to:
  /// **'Object detector: finds people (and counts them), pets, vehicles and food items.'**
  String get aiModelDetectorWhat;

  /// No description provided for @aiModelDetectorUse.
  ///
  /// In en, this message translates to:
  /// **'KFM uses it for labels like person, crowd, cat, dog, car and food.'**
  String get aiModelDetectorUse;

  /// No description provided for @aiModelSize.
  ///
  /// In en, this message translates to:
  /// **'Download size: {size} MB'**
  String aiModelSize(double size);

  /// No description provided for @aiModelPublisher.
  ///
  /// In en, this message translates to:
  /// **'Publisher: {publisher}'**
  String aiModelPublisher(String publisher);

  /// No description provided for @aiModelLicence.
  ///
  /// In en, this message translates to:
  /// **'Licence: {licence}'**
  String aiModelLicence(String licence);

  /// No description provided for @aiModelSource.
  ///
  /// In en, this message translates to:
  /// **'Downloaded from: {url}'**
  String aiModelSource(String url);

  /// No description provided for @aiModelOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original release: {url}'**
  String aiModelOriginal(String url);

  /// No description provided for @aiModelsLicences.
  ///
  /// In en, this message translates to:
  /// **'View licences'**
  String get aiModelsLicences;

  /// No description provided for @aboutLicences.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get aboutLicences;

  /// Search chip for a photo-content word (C4), e.g. 'Content: cat'.
  ///
  /// In en, this message translates to:
  /// **'Content: {label}'**
  String searchChipLabel(String label);

  /// No description provided for @searchChipBlurry.
  ///
  /// In en, this message translates to:
  /// **'Blurry photos'**
  String get searchChipBlurry;

  /// No description provided for @searchStillLabeling.
  ///
  /// In en, this message translates to:
  /// **'Still labeling photos ({percent}) — results may be incomplete'**
  String searchStillLabeling(double percent);

  /// No description provided for @searchLabelingOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on photo labeling to search by content'**
  String get searchLabelingOff;

  /// No description provided for @searchLabelingOffTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get searchLabelingOffTurnOn;

  /// No description provided for @searchContentWordsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Content search words couldn\'t be loaded'**
  String get searchContentWordsLoadError;

  /// No description provided for @fileMenuDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get fileMenuDetails;

  /// No description provided for @selectionActionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get selectionActionDetails;

  /// No description provided for @detailsSheetLabel.
  ///
  /// In en, this message translates to:
  /// **'File details'**
  String get detailsSheetLabel;

  /// No description provided for @detailsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading details'**
  String get detailsLoading;

  /// No description provided for @detailsPartial.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read some details'**
  String get detailsPartial;

  /// No description provided for @detailsGone.
  ///
  /// In en, this message translates to:
  /// **'This file no longer exists'**
  String get detailsGone;

  /// No description provided for @detailsWhatIsThis.
  ///
  /// In en, this message translates to:
  /// **'What is this?'**
  String get detailsWhatIsThis;

  /// No description provided for @detailsHintUsually.
  ///
  /// In en, this message translates to:
  /// **'Usually not needed, but check before deleting it'**
  String get detailsHintUsually;

  /// No description provided for @detailsHintCareful.
  ///
  /// In en, this message translates to:
  /// **'Careful: deleting it can lose data'**
  String get detailsHintCareful;

  /// No description provided for @detailsCameFrom.
  ///
  /// In en, this message translates to:
  /// **'Came from'**
  String get detailsCameFrom;

  /// The app that saved the file, e.g. 'Saved by WhatsApp'.
  ///
  /// In en, this message translates to:
  /// **'Saved by {app}'**
  String detailsSavedBy(String app);

  /// A source folder name such as Camera or WhatsApp.
  ///
  /// In en, this message translates to:
  /// **'In the {source} folder'**
  String detailsInSourceFolder(String source);

  /// An Android package name of an app that isn't installed or visible.
  ///
  /// In en, this message translates to:
  /// **'{package} (not installed)'**
  String detailsNotInstalled(String package);

  /// Website host only, e.g. 'Downloaded from example.com'.
  ///
  /// In en, this message translates to:
  /// **'Downloaded from {host}'**
  String detailsDownloadedFrom(String host);

  /// The page that had the download link (referer host).
  ///
  /// In en, this message translates to:
  /// **'Link was on {host}'**
  String detailsLinkedFrom(String host);

  /// No description provided for @detailsShowFullAddress.
  ///
  /// In en, this message translates to:
  /// **'Tap to show the full address'**
  String get detailsShowFullAddress;

  /// Camera make and model from EXIF.
  ///
  /// In en, this message translates to:
  /// **'Taken with {camera}'**
  String detailsTakenWith(String camera);

  /// EXIF Software, e.g. Snapseed.
  ///
  /// In en, this message translates to:
  /// **'Made or edited with {app}'**
  String detailsEditedWith(String app);

  /// No description provided for @detailsWhere.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get detailsWhere;

  /// No description provided for @detailsPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get detailsPath;

  /// No description provided for @detailsCopyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get detailsCopyPath;

  /// No description provided for @detailsPathCopied.
  ///
  /// In en, this message translates to:
  /// **'Path copied'**
  String get detailsPathCopied;

  /// No description provided for @detailsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get detailsStorage;

  /// No description provided for @detailsStorageInternal.
  ///
  /// In en, this message translates to:
  /// **'Internal storage'**
  String get detailsStorageInternal;

  /// No description provided for @detailsStorageRemovable.
  ///
  /// In en, this message translates to:
  /// **'SD card or USB drive'**
  String get detailsStorageRemovable;

  /// No description provided for @detailsHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get detailsHidden;

  /// No description provided for @detailsOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get detailsOpenFolder;

  /// No description provided for @detailsFileSection.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get detailsFileSection;

  /// No description provided for @detailsType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get detailsType;

  /// MIME type and extension, e.g. 'image/jpeg (.jpg)'.
  ///
  /// In en, this message translates to:
  /// **'{mime} (.{ext})'**
  String detailsTypeValue(String mime, String ext);

  /// No description provided for @detailsTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown file type (.{ext})'**
  String detailsTypeUnknown(String ext);

  /// No description provided for @detailsTypeUnknownNoExt.
  ///
  /// In en, this message translates to:
  /// **'Unknown file type'**
  String get detailsTypeUnknownNoExt;

  /// No description provided for @detailsSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get detailsSize;

  /// No description provided for @detailsBytes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 byte} other{{count} bytes}}'**
  String detailsBytes(int count);

  /// No description provided for @detailsModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get detailsModified;

  /// No description provided for @detailsTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get detailsTaken;

  /// No description provided for @detailsDimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get detailsDimensions;

  /// No description provided for @detailsDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get detailsDuration;

  /// No description provided for @detailsCameraSettings.
  ///
  /// In en, this message translates to:
  /// **'Camera settings'**
  String get detailsCameraSettings;

  /// No description provided for @detailsLens.
  ///
  /// In en, this message translates to:
  /// **'Lens'**
  String get detailsLens;

  /// No description provided for @detailsDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get detailsDescription;

  /// No description provided for @detailsIso.
  ///
  /// In en, this message translates to:
  /// **'ISO {value}'**
  String detailsIso(int value);

  /// Exposure time, e.g. '1/120 s'.
  ///
  /// In en, this message translates to:
  /// **'{value} s'**
  String detailsExposure(String value);

  /// No description provided for @detailsFNumber.
  ///
  /// In en, this message translates to:
  /// **'f/{value}'**
  String detailsFNumber(String value);

  /// No description provided for @detailsFocalLength.
  ///
  /// In en, this message translates to:
  /// **'{value} mm'**
  String detailsFocalLength(String value);

  /// No description provided for @detailsLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get detailsLocation;

  /// Latitude and longitude as decimal text.
  ///
  /// In en, this message translates to:
  /// **'{lat}, {lng}'**
  String detailsLatLng(String lat, String lng);

  /// No description provided for @detailsInKfm.
  ///
  /// In en, this message translates to:
  /// **'In KFM'**
  String get detailsInKfm;

  /// No description provided for @detailsTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get detailsTags;

  /// No description provided for @detailsFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get detailsFavorite;

  /// No description provided for @detailsReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed {date}'**
  String detailsReviewed(String date);

  /// No description provided for @detailsAppInfo.
  ///
  /// In en, this message translates to:
  /// **'App info'**
  String get detailsAppInfo;

  /// No description provided for @detailsAppInfoFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open App info'**
  String get detailsAppInfoFailed;

  /// Selection summary heading.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String detailsSummaryTitle(int count);

  /// No description provided for @detailsSummaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total size'**
  String get detailsSummaryTotal;

  /// No description provided for @detailsSummaryKinds.
  ///
  /// In en, this message translates to:
  /// **'Kinds'**
  String get detailsSummaryKinds;

  /// e.g. 'Images: 3'.
  ///
  /// In en, this message translates to:
  /// **'{kind}: {count}'**
  String detailsSummaryKindCount(String kind, int count);

  /// No description provided for @detailsSummaryOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get detailsSummaryOldest;

  /// No description provided for @detailsSummaryNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get detailsSummaryNewest;

  /// No description provided for @detailsSummaryFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get detailsSummaryFolders;

  /// No description provided for @detailsSummaryFolderCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{In 1 folder} other{In {count} folders}}'**
  String detailsSummaryFolderCount(int count);

  /// No description provided for @detailsSummaryMissing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected file is no longer indexed} other{{count} selected files are no longer indexed}}'**
  String detailsSummaryMissing(int count);

  /// No description provided for @connectSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect a device'**
  String get connectSettingsTitle;

  /// No description provided for @connectShareThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Share this device'**
  String get connectShareThisDevice;

  /// No description provided for @connectShareThisDeviceHint.
  ///
  /// In en, this message translates to:
  /// **'Let a phone or PC on the same Wi-Fi connect to this one'**
  String get connectShareThisDeviceHint;

  /// No description provided for @connectToDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect to a device'**
  String get connectToDevice;

  /// No description provided for @connectToDeviceHint.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code or type a code'**
  String get connectToDeviceHint;

  /// No description provided for @connectChooseHint.
  ///
  /// In en, this message translates to:
  /// **'On the other device, open Settings → Connect a device → Share this device.'**
  String get connectChooseHint;

  /// No description provided for @connectScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get connectScanQr;

  /// No description provided for @connectScanQrHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the code on the other device'**
  String get connectScanQrHint;

  /// No description provided for @connectTypeCode.
  ///
  /// In en, this message translates to:
  /// **'Type a code'**
  String get connectTypeCode;

  /// No description provided for @connectTypeCodeHint.
  ///
  /// In en, this message translates to:
  /// **'For a PC, or when there’s no camera'**
  String get connectTypeCodeHint;

  /// No description provided for @connectCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'KFM needs the camera to scan the code. You can type the code instead.'**
  String get connectCameraDenied;

  /// No description provided for @connectOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get connectOpenSettings;

  /// No description provided for @connectAllowCamera.
  ///
  /// In en, this message translates to:
  /// **'Allow camera'**
  String get connectAllowCamera;

  /// No description provided for @connectNotKfmCode.
  ///
  /// In en, this message translates to:
  /// **'Not a KFM code'**
  String get connectNotKfmCode;

  /// No description provided for @connectUpdateKfm.
  ///
  /// In en, this message translates to:
  /// **'Update KFM on both devices'**
  String get connectUpdateKfm;

  /// No description provided for @connectDebugPasteLabel.
  ///
  /// In en, this message translates to:
  /// **'Pairing link (debug builds only)'**
  String get connectDebugPasteLabel;

  /// No description provided for @connectDebugPasteGo.
  ///
  /// In en, this message translates to:
  /// **'Use link'**
  String get connectDebugPasteGo;

  /// No description provided for @connectNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices'**
  String get connectNearbyTitle;

  /// No description provided for @connectNearbySearching.
  ///
  /// In en, this message translates to:
  /// **'Looking for devices sharing on this Wi-Fi…'**
  String get connectNearbySearching;

  /// No description provided for @connectNearbyFailed.
  ///
  /// In en, this message translates to:
  /// **'Can’t search this Wi-Fi. Enter the address shown on the other device instead.'**
  String get connectNearbyFailed;

  /// No description provided for @connectEnterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter address'**
  String get connectEnterAddress;

  /// No description provided for @connectAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address shown on the other device'**
  String get connectAddressLabel;

  /// No description provided for @connectAddressInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter it like 192.168.1.23:48211'**
  String get connectAddressInvalid;

  /// No description provided for @connectHostPort.
  ///
  /// In en, this message translates to:
  /// **'{host}:{port}'**
  String connectHostPort(String host, int port);

  /// No description provided for @connectNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get connectNext;

  /// No description provided for @connectCodeFor.
  ///
  /// In en, this message translates to:
  /// **'Type the code shown on {name}'**
  String connectCodeFor(String name);

  /// No description provided for @connectCodeForAddress.
  ///
  /// In en, this message translates to:
  /// **'Type the code shown on the other device'**
  String get connectCodeForAddress;

  /// No description provided for @connectCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get connectCodeLabel;

  /// No description provided for @connectCodeInvalidChar.
  ///
  /// In en, this message translates to:
  /// **'Only letters and numbers'**
  String get connectCodeInvalidChar;

  /// No description provided for @connectConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectConnect;

  /// No description provided for @connectCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get connectCancel;

  /// No description provided for @connectConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connectConnecting;

  /// No description provided for @connectWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to accept…'**
  String connectWaiting(String name);

  /// No description provided for @connectConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to {name}'**
  String connectConnected(String name);

  /// No description provided for @connectDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get connectDisconnect;

  /// No description provided for @connectTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get connectTryAgain;

  /// No description provided for @connectBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get connectBack;

  /// No description provided for @connectOtherDevice.
  ///
  /// In en, this message translates to:
  /// **'the other device'**
  String get connectOtherDevice;

  /// No description provided for @connectErrorUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Devices can’t reach each other on this Wi-Fi. Try a hotspot.'**
  String get connectErrorUnreachable;

  /// No description provided for @connectErrorWrongDevice.
  ///
  /// In en, this message translates to:
  /// **'This isn’t {name}.'**
  String connectErrorWrongDevice(String name);

  /// No description provided for @connectErrorWrongCode.
  ///
  /// In en, this message translates to:
  /// **'Wrong code, or this isn’t {name}. Check the code and try again.'**
  String connectErrorWrongCode(String name);

  /// No description provided for @connectErrorSecretUsed.
  ///
  /// In en, this message translates to:
  /// **'Code already used'**
  String get connectErrorSecretUsed;

  /// No description provided for @connectErrorExpired.
  ///
  /// In en, this message translates to:
  /// **'This code expired. Scan the new one.'**
  String get connectErrorExpired;

  /// No description provided for @connectErrorTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment, then try again.'**
  String get connectErrorTooMany;

  /// No description provided for @connectErrorBusy.
  ///
  /// In en, this message translates to:
  /// **'{name} is busy with another request. Try again in a moment.'**
  String connectErrorBusy(String name);

  /// No description provided for @connectErrorDeclined.
  ///
  /// In en, this message translates to:
  /// **'{name} declined the connection.'**
  String connectErrorDeclined(String name);

  /// No description provided for @connectErrorTimedOut.
  ///
  /// In en, this message translates to:
  /// **'No answer from {name}.'**
  String connectErrorTimedOut(String name);

  /// No description provided for @connectErrorCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get connectErrorCancelled;

  /// No description provided for @connectErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing failed. Try again.'**
  String get connectErrorFailed;

  /// No description provided for @connectErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'The connection to {name} was lost.'**
  String connectErrorNetwork(String name);

  /// No description provided for @connectErrorBadResponse.
  ///
  /// In en, this message translates to:
  /// **'{name} didn’t answer like KFM. Update KFM on both devices.'**
  String connectErrorBadResponse(String name);

  /// No description provided for @shareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share this device'**
  String get shareTitle;

  /// No description provided for @sharePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get sharePreparing;

  /// No description provided for @shareSharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get shareSharing;

  /// No description provided for @shareSharingAs.
  ///
  /// In en, this message translates to:
  /// **'Devices on the same Wi-Fi can connect to “{name}”.'**
  String shareSharingAs(String name);

  /// No description provided for @shareKeepOpen.
  ///
  /// In en, this message translates to:
  /// **'Sharing stops when you leave this screen or the app.'**
  String get shareKeepOpen;

  /// No description provided for @shareStop.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get shareStop;

  /// No description provided for @shareStopped.
  ///
  /// In en, this message translates to:
  /// **'Sharing stopped'**
  String get shareStopped;

  /// No description provided for @shareStartAgain.
  ///
  /// In en, this message translates to:
  /// **'Share again'**
  String get shareStartAgain;

  /// No description provided for @shareNoNetwork.
  ///
  /// In en, this message translates to:
  /// **'Connect to Wi-Fi or turn on hotspot'**
  String get shareNoNetwork;

  /// No description provided for @shareNoNetworkHint.
  ///
  /// In en, this message translates to:
  /// **'Both devices must be on the same Wi-Fi, or one must use the other\'s hotspot.'**
  String get shareNoNetworkHint;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start sharing'**
  String get shareFailed;

  /// No description provided for @shareRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get shareRetry;

  /// Debug builds only: interface address and port.
  ///
  /// In en, this message translates to:
  /// **'{address}:{port}'**
  String shareDebugAddress(String address, int port);

  /// Debug builds only.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint: {fingerprint}'**
  String shareDebugFingerprint(String fingerprint);

  /// No description provided for @shareQrHint.
  ///
  /// In en, this message translates to:
  /// **'Scan this with KFM on the other device'**
  String get shareQrHint;

  /// No description provided for @shareQrSemantics.
  ///
  /// In en, this message translates to:
  /// **'QR code for pairing'**
  String get shareQrSemantics;

  /// No description provided for @shareExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'New code in {time}'**
  String shareExpiresIn(String time);

  /// No description provided for @shareTypeCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'No camera? Type this code'**
  String get shareTypeCodeTitle;

  /// No description provided for @shareAddress.
  ///
  /// In en, this message translates to:
  /// **'Address: {address}'**
  String shareAddress(String address);

  /// No description provided for @shareCodeCooldown.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{Too many wrong attempts. Typed codes work again in 1 second.} other{Too many wrong attempts. Typed codes work again in {seconds} seconds.}}'**
  String shareCodeCooldown(int seconds);

  /// No description provided for @shareTypedCodesOff.
  ///
  /// In en, this message translates to:
  /// **'Typed codes are turned off for now. Scan the QR, or stop and start sharing again.'**
  String get shareTypedCodesOff;

  /// No description provided for @shareRotatedLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong attempts. New code generated'**
  String get shareRotatedLocked;

  /// No description provided for @sharePrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'While sharing, devices on this Wi-Fi can see this device’s name.'**
  String get sharePrivacyNote;

  /// No description provided for @shareDiscoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices can’t list this one. They can enter the address instead.'**
  String get shareDiscoveryFailed;

  /// No description provided for @devResetIdentity.
  ///
  /// In en, this message translates to:
  /// **'Reset device identity'**
  String get devResetIdentity;

  /// No description provided for @devResetIdentityDone.
  ///
  /// In en, this message translates to:
  /// **'New device identity created'**
  String get devResetIdentityDone;

  /// No description provided for @pairCompareWords.
  ///
  /// In en, this message translates to:
  /// **'Check that both devices show these words'**
  String get pairCompareWords;

  /// No description provided for @connectNoFoldersYet.
  ///
  /// In en, this message translates to:
  /// **'{name} hasn’t shared any folders yet'**
  String connectNoFoldersYet(String name);

  /// No description provided for @connectFoldersShared.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shared folder} other{{count} shared folders}}'**
  String connectFoldersShared(int count);

  /// No description provided for @connectDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected from {name}'**
  String connectDisconnected(String name);

  /// No description provided for @acceptTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to connect'**
  String acceptTitle(String name);

  /// No description provided for @acceptTitleRemembered.
  ///
  /// In en, this message translates to:
  /// **'{name} (remembered) wants to connect'**
  String acceptTitleRemembered(String name);

  /// No description provided for @acceptPlatform.
  ///
  /// In en, this message translates to:
  /// **'Device type: {platform}'**
  String acceptPlatform(String platform);

  /// No description provided for @acceptAutoDecline.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{Declines on its own in 1 second} other{Declines on its own in {seconds} seconds}}'**
  String acceptAutoDecline(int seconds);

  /// No description provided for @acceptDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get acceptDecline;

  /// No description provided for @acceptAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptAccept;

  /// No description provided for @acceptRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get acceptRequestCancelled;

  /// No description provided for @acceptTimedOut.
  ///
  /// In en, this message translates to:
  /// **'No answer in time. The request was declined.'**
  String get acceptTimedOut;

  /// No description provided for @shareConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected: {name}'**
  String shareConnectedTo(String name);

  /// No description provided for @shareDisconnectClient.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get shareDisconnectClient;

  /// No description provided for @sharedFoldersTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared folders'**
  String get sharedFoldersTitle;

  /// No description provided for @sharedFoldersFor.
  ///
  /// In en, this message translates to:
  /// **'Folders {name} can see'**
  String sharedFoldersFor(String name);

  /// No description provided for @sharedFoldersHint.
  ///
  /// In en, this message translates to:
  /// **'Nothing is shared until you pick a folder. Shared folders are read-only unless you allow changes.'**
  String get sharedFoldersHint;

  /// No description provided for @sharedFoldersMediaOnly.
  ///
  /// In en, this message translates to:
  /// **'Without All files access, only photo folders can be shared.'**
  String get sharedFoldersMediaOnly;

  /// No description provided for @sharedFolderCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get sharedFolderCamera;

  /// No description provided for @sharedFolderPictures.
  ///
  /// In en, this message translates to:
  /// **'Pictures'**
  String get sharedFolderPictures;

  /// No description provided for @sharedFolderScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get sharedFolderScreenshots;

  /// No description provided for @sharedFolderDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get sharedFolderDownloads;

  /// No description provided for @sharedFolderDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get sharedFolderDocuments;

  /// No description provided for @sharedFolderAllStorage.
  ///
  /// In en, this message translates to:
  /// **'All storage'**
  String get sharedFolderAllStorage;

  /// No description provided for @sharedFolderAllowChanges.
  ///
  /// In en, this message translates to:
  /// **'Allow changes (move, rename, delete, upload)'**
  String get sharedFolderAllowChanges;

  /// No description provided for @sharedFoldersChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose folder…'**
  String get sharedFoldersChoose;

  /// No description provided for @sharedFoldersDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get sharedFoldersDone;

  /// No description provided for @sharedFoldersWholeStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Share all your files?'**
  String get sharedFoldersWholeStorageTitle;

  /// No description provided for @sharedFoldersWholeStorageBody.
  ///
  /// In en, this message translates to:
  /// **'The other device will see all your files.'**
  String get sharedFoldersWholeStorageBody;

  /// No description provided for @sharedFoldersWholeStorageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Share everything'**
  String get sharedFoldersWholeStorageConfirm;

  /// No description provided for @folderChooserTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder'**
  String get folderChooserTitle;

  /// No description provided for @folderChooserShareThis.
  ///
  /// In en, this message translates to:
  /// **'Share this folder'**
  String get folderChooserShareThis;

  /// No description provided for @folderChooserEmpty.
  ///
  /// In en, this message translates to:
  /// **'No subfolders'**
  String get folderChooserEmpty;

  /// No description provided for @folderChooserError.
  ///
  /// In en, this message translates to:
  /// **'Can’t open this folder'**
  String get folderChooserError;

  /// No description provided for @shareClientFolders.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No folders shared} =1{1 shared folder} other{{count} shared folders}}'**
  String shareClientFolders(int count);

  /// No description provided for @connectDisconnectedStopped.
  ///
  /// In en, this message translates to:
  /// **'{name} stopped sharing.'**
  String connectDisconnectedStopped(String name);

  /// No description provided for @connectDisconnectedNetwork.
  ///
  /// In en, this message translates to:
  /// **'Lost the connection to {name}. Check that both devices are on the same Wi-Fi.'**
  String connectDisconnectedNetwork(String name);

  /// No description provided for @shareKeepOpenDesktop.
  ///
  /// In en, this message translates to:
  /// **'Sharing stops when you leave this screen.'**
  String get shareKeepOpenDesktop;

  /// No description provided for @shareKeepsRunning.
  ///
  /// In en, this message translates to:
  /// **'Sharing keeps running when you leave the app. Stop it here or from the notification.'**
  String get shareKeepsRunning;

  /// No description provided for @transferChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get transferChecking;

  /// No description provided for @shareClientGone.
  ///
  /// In en, this message translates to:
  /// **'Disconnected: {name}'**
  String shareClientGone(String name);

  /// No description provided for @shareKeepsRunningNoNotification.
  ///
  /// In en, this message translates to:
  /// **'Sharing keeps running when you leave the app. Notifications are off for KFM, so come back here to stop it.'**
  String get shareKeepsRunningNoNotification;

  /// No description provided for @shareStopConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing?'**
  String get shareStopConfirmTitle;

  /// No description provided for @shareStopConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Files are still being sent or received. Stopping now interrupts them; they continue the next time you share.'**
  String get shareStopConfirmBody;

  /// No description provided for @shareKeepSharing.
  ///
  /// In en, this message translates to:
  /// **'Keep sharing'**
  String get shareKeepSharing;

  /// No description provided for @shareNotificationChannel.
  ///
  /// In en, this message translates to:
  /// **'Device sharing'**
  String get shareNotificationChannel;

  /// No description provided for @shareNotificationWaiting.
  ///
  /// In en, this message translates to:
  /// **'Sharing this device'**
  String get shareNotificationWaiting;

  /// No description provided for @shareNotificationWith.
  ///
  /// In en, this message translates to:
  /// **'{others, plural, =0{Sharing with {name}} other{Sharing with {name} and {others} more}}'**
  String shareNotificationWith(String name, int others);

  /// No description provided for @shareNotificationText.
  ///
  /// In en, this message translates to:
  /// **'Devices on the same Wi-Fi can connect. Tap to open KFM.'**
  String get shareNotificationText;

  /// No description provided for @shareNotificationStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get shareNotificationStop;

  /// No description provided for @remoteNotConnected.
  ///
  /// In en, this message translates to:
  /// **'The other device isn’t connected'**
  String get remoteNotConnected;

  /// No description provided for @remoteBrowseAction.
  ///
  /// In en, this message translates to:
  /// **'Browse {device}'**
  String remoteBrowseAction(String device);

  /// No description provided for @remoteBrowseRoots.
  ///
  /// In en, this message translates to:
  /// **'Shared folders'**
  String get remoteBrowseRoots;

  /// No description provided for @remoteReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get remoteReadOnly;

  /// No description provided for @remoteDeviceNotConnected.
  ///
  /// In en, this message translates to:
  /// **'{device} isn’t connected'**
  String remoteDeviceNotConnected(String device);

  /// No description provided for @remoteReconnect.
  ///
  /// In en, this message translates to:
  /// **'Connect again'**
  String get remoteReconnect;

  /// No description provided for @remoteFileGone.
  ///
  /// In en, this message translates to:
  /// **'This file is no longer available'**
  String get remoteFileGone;

  /// No description provided for @remoteNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed on {device}'**
  String remoteNotAllowed(String device);

  /// No description provided for @remoteDeclined.
  ///
  /// In en, this message translates to:
  /// **'{device} declined'**
  String remoteDeclined(String device);

  /// No description provided for @remoteDeleteDeclined.
  ///
  /// In en, this message translates to:
  /// **'{device} declined the delete'**
  String remoteDeleteDeclined(String device);

  /// No description provided for @remoteEmptyFolder.
  ///
  /// In en, this message translates to:
  /// **'No files here'**
  String get remoteEmptyFolder;

  /// No description provided for @remoteShowingFirst.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Showing the first file} other{Showing the first {count} files}}'**
  String remoteShowingFirst(int count);

  /// No description provided for @remoteTrashConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Move 1 file to the trash on {device}?} other{Move {count} files to the trash on {device}?}}'**
  String remoteTrashConfirm(int count, String device);

  /// No description provided for @remoteTrashConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'{device} may ask to confirm.'**
  String remoteTrashConfirmHint(String device);

  /// No description provided for @remoteTrashed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moved 1 file to the trash on {device}} other{Moved {count} files to the trash on {device}}}'**
  String remoteTrashed(int count, String device);

  /// No description provided for @remoteMoved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moved 1 file} other{Moved {count} files}}'**
  String remoteMoved(int count);

  /// No description provided for @remoteCopied.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copied 1 file} other{Copied {count} files}}'**
  String remoteCopied(int count);

  /// No description provided for @remoteSomeFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file couldn’t be changed} other{{count} files couldn’t be changed}}'**
  String remoteSomeFailed(int count);

  /// No description provided for @remotePickFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder on {device}'**
  String remotePickFolderTitle(String device);

  /// No description provided for @remotePickHere.
  ///
  /// In en, this message translates to:
  /// **'Choose this folder'**
  String get remotePickHere;

  /// No description provided for @remoteConnectedDevice.
  ///
  /// In en, this message translates to:
  /// **'Connected device'**
  String get remoteConnectedDevice;

  /// No description provided for @remoteTrashRequest.
  ///
  /// In en, this message translates to:
  /// **'{device} wants to move {count, plural, =1{1 file} other{{count} files}} to trash'**
  String remoteTrashRequest(String device, int count);

  /// No description provided for @remoteTrashDone.
  ///
  /// In en, this message translates to:
  /// **'{device} moved {count, plural, =1{1 file} other{{count} files}} to trash'**
  String remoteTrashDone(String device, int count);

  /// No description provided for @remoteTrashDeclinedByYou.
  ///
  /// In en, this message translates to:
  /// **'You declined {device}’s request'**
  String remoteTrashDeclinedByYou(String device);

  /// No description provided for @remoteWriteRequest.
  ///
  /// In en, this message translates to:
  /// **'{device} wants to change {count, plural, =1{1 file} other{{count} files}}'**
  String remoteWriteRequest(String device, int count);

  /// No description provided for @shareMediaOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Without All files access, other devices see only photos, videos and audio.'**
  String get shareMediaOnlyHint;

  /// No description provided for @rememberThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Remember this device'**
  String get rememberThisDevice;

  /// No description provided for @acceptAlwaysAllow.
  ///
  /// In en, this message translates to:
  /// **'Always allow this device'**
  String get acceptAlwaysAllow;

  /// No description provided for @acceptAlwaysAllowHint.
  ///
  /// In en, this message translates to:
  /// **'Next time it connects without asking'**
  String get acceptAlwaysAllowHint;

  /// No description provided for @shareAutoAccepted.
  ///
  /// In en, this message translates to:
  /// **'{name} connected'**
  String shareAutoAccepted(String name);

  /// No description provided for @shareRememberedFolders.
  ///
  /// In en, this message translates to:
  /// **'Sharing {count, plural, =1{1 folder} other{{count} folders}}'**
  String shareRememberedFolders(int count);

  /// No description provided for @shareFoldersMissing.
  ///
  /// In en, this message translates to:
  /// **'Some shared folders no longer exist'**
  String get shareFoldersMissing;

  /// No description provided for @shareFoldersChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get shareFoldersChange;

  /// No description provided for @connectErrorKeyChanged.
  ///
  /// In en, this message translates to:
  /// **'{name} has changed. Scan the QR code again.'**
  String connectErrorKeyChanged(String name);

  /// No description provided for @connectErrorNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed. Scan the QR code again.'**
  String get connectErrorNotAllowed;

  /// No description provided for @connectErrorOffline.
  ///
  /// In en, this message translates to:
  /// **'Can’t reach {name}. Open “Share this device” on {name}.'**
  String connectErrorOffline(String name);

  /// No description provided for @rememberedDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Remembered devices'**
  String get rememberedDevicesTitle;

  /// No description provided for @rememberedDevicesHint.
  ///
  /// In en, this message translates to:
  /// **'Reconnect without scanning, or forget a device'**
  String get rememberedDevicesHint;

  /// No description provided for @rememberedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No remembered devices yet. Devices you pair with “Remember this device” on show up here.'**
  String get rememberedEmpty;

  /// No description provided for @rememberedLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load remembered devices'**
  String get rememberedLoadFailed;

  /// No description provided for @rememberedOnline.
  ///
  /// In en, this message translates to:
  /// **'Sharing now'**
  String get rememberedOnline;

  /// No description provided for @rememberedOffline.
  ///
  /// In en, this message translates to:
  /// **'Not sharing right now'**
  String get rememberedOffline;

  /// No description provided for @rememberedConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get rememberedConnected;

  /// No description provided for @rememberedConnectsToUs.
  ///
  /// In en, this message translates to:
  /// **'Connects to this device'**
  String get rememberedConnectsToUs;

  /// No description provided for @rememberedStatusWords.
  ///
  /// In en, this message translates to:
  /// **'{status} · {words}'**
  String rememberedStatusWords(String status, String words);

  /// No description provided for @rememberedReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get rememberedReconnect;

  /// No description provided for @rememberedShareFromHere.
  ///
  /// In en, this message translates to:
  /// **'Share from this device'**
  String get rememberedShareFromHere;

  /// No description provided for @rememberedAlwaysAllow.
  ///
  /// In en, this message translates to:
  /// **'Always allow'**
  String get rememberedAlwaysAllow;

  /// No description provided for @rememberedAlwaysAllowHint.
  ///
  /// In en, this message translates to:
  /// **'When it connects to this device, don’t ask'**
  String get rememberedAlwaysAllowHint;

  /// No description provided for @rememberedRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get rememberedRemove;

  /// No description provided for @rememberedRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String rememberedRemoveTitle(String name);

  /// No description provided for @rememberedRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'It is disconnected now and must scan the QR code to connect again. A lost or stolen remembered device still needs this device to be sharing and someone to tap Accept; removing it makes even that impossible.'**
  String get rememberedRemoveBody;

  /// No description provided for @rememberedRemoveAll.
  ///
  /// In en, this message translates to:
  /// **'Remove all'**
  String get rememberedRemoveAll;

  /// No description provided for @rememberedRemoveAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all remembered devices?'**
  String get rememberedRemoveAllTitle;

  /// No description provided for @rememberedRemoveAllBody.
  ///
  /// In en, this message translates to:
  /// **'Every device must scan the QR code again to connect.'**
  String get rememberedRemoveAllBody;

  /// No description provided for @rememberedRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t remove the device. Try again.'**
  String get rememberedRemoveFailed;

  /// No description provided for @resetIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset this device’s identity'**
  String get resetIdentityTitle;

  /// No description provided for @resetIdentityHint.
  ///
  /// In en, this message translates to:
  /// **'Forget all devices and make every device scan again'**
  String get resetIdentityHint;

  /// No description provided for @resetIdentityConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset this device’s identity?'**
  String get resetIdentityConfirmTitle;

  /// No description provided for @resetIdentityConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Sharing stops, this device gets a new key and every remembered device is forgotten. Other devices must scan the QR code again. Use this if a device may be compromised or before giving this one away.'**
  String get resetIdentityConfirmBody;

  /// No description provided for @resetIdentityConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetIdentityConfirm;

  /// No description provided for @resetIdentityDone.
  ///
  /// In en, this message translates to:
  /// **'New identity created. Other devices must scan again.'**
  String get resetIdentityDone;

  /// No description provided for @resetIdentityFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reset the identity. Try again.'**
  String get resetIdentityFailed;

  /// No description provided for @swipeProblemFolderNotOnSource.
  ///
  /// In en, this message translates to:
  /// **'Pick a folder on {device}'**
  String swipeProblemFolderNotOnSource(String device);

  /// No description provided for @swipeProblemReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only on {device}'**
  String swipeProblemReadOnly(String device);

  /// No description provided for @swipeProblemNotOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Not available for files on {device}'**
  String swipeProblemNotOnDevice(String device);

  /// No description provided for @remoteSwipeWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {device}…'**
  String remoteSwipeWaiting(String device);

  /// No description provided for @remoteSwipeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue swiping on {device}'**
  String remoteSwipeContinue(String device);

  /// No description provided for @remoteSwipeSwiped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing swiped yet} =1{1 swiped} other{{count} swiped}}'**
  String remoteSwipeSwiped(int count);

  /// No description provided for @remoteSwipePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused · {device} not connected'**
  String remoteSwipePaused(String device);

  /// No description provided for @remoteSwipeOrphaned.
  ///
  /// In en, this message translates to:
  /// **'{device} isn\'t remembered any more'**
  String remoteSwipeOrphaned(String device);

  /// No description provided for @remoteSwipeFinishNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Connect to {device} to finish'**
  String remoteSwipeFinishNeedsConnection(String device);

  /// No description provided for @remoteSwipeFinishBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing is waiting to be deleted.} =1{1 file will be moved to the trash on {device}.} other{{count} files will be moved to the trash on {device}.}}'**
  String remoteSwipeFinishBody(int count, String device);

  /// No description provided for @remoteSwipeRestoreOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Restore it from the Trash on {device}'**
  String remoteSwipeRestoreOnDevice(String device);

  /// No description provided for @remoteSwipeDeclined.
  ///
  /// In en, this message translates to:
  /// **'{device} declined the delete'**
  String remoteSwipeDeclined(String device);

  /// No description provided for @remoteSwipeAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done in this folder.'**
  String get remoteSwipeAllDone;

  /// No description provided for @remoteSwipeDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard session'**
  String get remoteSwipeDiscard;

  /// No description provided for @remoteSwipeDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard the swipe session on {device}?'**
  String remoteSwipeDiscardTitle(String device);

  /// No description provided for @remoteSwipeDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your swipes there are forgotten. Nothing is deleted on that device.'**
  String get remoteSwipeDiscardBody;

  /// No description provided for @remoteSwipeUnknownDevice.
  ///
  /// In en, this message translates to:
  /// **'the other device'**
  String get remoteSwipeUnknownDevice;

  /// No description provided for @transfersTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get transfersTitle;

  /// No description provided for @transfersDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get transfersDownloads;

  /// No description provided for @transfersUploads.
  ///
  /// In en, this message translates to:
  /// **'Uploads'**
  String get transfersUploads;

  /// No description provided for @transfersEmptyDownloads.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet. Select files on a connected device and tap Download.'**
  String get transfersEmptyDownloads;

  /// No description provided for @transfersEmptyUploads.
  ///
  /// In en, this message translates to:
  /// **'No uploads yet. Select files and tap Send to device.'**
  String get transfersEmptyUploads;

  /// No description provided for @transferFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String transferFiles(int count);

  /// No description provided for @transferFromDevice.
  ///
  /// In en, this message translates to:
  /// **'From {device}'**
  String transferFromDevice(String device);

  /// No description provided for @transferToDevice.
  ///
  /// In en, this message translates to:
  /// **'To {device}'**
  String transferToDevice(String device);

  /// No description provided for @transferSpeedEta.
  ///
  /// In en, this message translates to:
  /// **'{speed}/s · {eta} left'**
  String transferSpeedEta(String speed, String eta);

  /// No description provided for @transferProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String transferProgress(String done, String total);

  /// No description provided for @transferStatusQueued.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get transferStatusQueued;

  /// No description provided for @transferStatusWaitingFor.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {device}'**
  String transferStatusWaitingFor(String device);

  /// No description provided for @transferStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Transferring'**
  String get transferStatusRunning;

  /// No description provided for @transferStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get transferStatusDone;

  /// No description provided for @transferStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file failed} other{{count} files failed}}'**
  String transferStatusFailed(int count);

  /// No description provided for @transferStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get transferStatusCancelled;

  /// No description provided for @transferCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get transferCancel;

  /// No description provided for @transferRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get transferRetry;

  /// No description provided for @transferClearFinished.
  ///
  /// In en, this message translates to:
  /// **'Clear finished'**
  String get transferClearFinished;

  /// No description provided for @transferNoSpaceOn.
  ///
  /// In en, this message translates to:
  /// **'Not enough space on {device}'**
  String transferNoSpaceOn(String device);

  /// No description provided for @transferNoSpaceHere.
  ///
  /// In en, this message translates to:
  /// **'Not enough space on this device'**
  String get transferNoSpaceHere;

  /// No description provided for @transferNotAllowedOn.
  ///
  /// In en, this message translates to:
  /// **'Not allowed on {device}'**
  String transferNotAllowedOn(String device);

  /// No description provided for @transferNoWritableFolder.
  ///
  /// In en, this message translates to:
  /// **'No writable folder shared by {device}'**
  String transferNoWritableFolder(String device);

  /// No description provided for @transferInvalidName.
  ///
  /// In en, this message translates to:
  /// **'This file name can’t be used here'**
  String get transferInvalidName;

  /// No description provided for @transferNoLocation.
  ///
  /// In en, this message translates to:
  /// **'Location info isn’t included'**
  String get transferNoLocation;

  /// No description provided for @transferAlreadySent.
  ///
  /// In en, this message translates to:
  /// **'Already sent'**
  String get transferAlreadySent;

  /// No description provided for @transferConnectToPick.
  ///
  /// In en, this message translates to:
  /// **'Connect to {device} to pick a folder'**
  String transferConnectToPick(String device);

  /// No description provided for @transfersRunning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing running} =1{1 transfer running} other{{count} transfers running}}'**
  String transfersRunning(int count);

  /// No description provided for @transferLostConnection.
  ///
  /// In en, this message translates to:
  /// **'Lost the connection to {device}'**
  String transferLostConnection(String device);

  /// No description provided for @transferInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Stopped when KFM closed'**
  String get transferInterrupted;

  /// No description provided for @transferSourceGone.
  ///
  /// In en, this message translates to:
  /// **'The file is gone'**
  String get transferSourceGone;

  /// No description provided for @transferIncomplete.
  ///
  /// In en, this message translates to:
  /// **'The transfer was cut off'**
  String get transferIncomplete;

  /// No description provided for @transferFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t transfer this file'**
  String get transferFailedGeneric;

  /// No description provided for @transferPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get transferPause;

  /// No description provided for @transferResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get transferResume;

  /// No description provided for @transferReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get transferReconnect;

  /// No description provided for @transferPausedByYou.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get transferPausedByYou;

  /// No description provided for @transferRetrying.
  ///
  /// In en, this message translates to:
  /// **'Trying again soon'**
  String get transferRetrying;

  /// No description provided for @transferSourceChanged.
  ///
  /// In en, this message translates to:
  /// **'The file changed while it was sent'**
  String get transferSourceChanged;

  /// No description provided for @transferModeCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get transferModeCopy;

  /// Transfer mode: move = copy, verify, then remove the original.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get transferModeMove;

  /// No description provided for @transferMoveDownloadNote.
  ///
  /// In en, this message translates to:
  /// **'Each file is checked after it arrives; only then does its original go to the trash on {device}.'**
  String transferMoveDownloadNote(String device);

  /// No description provided for @transferMoveToDevice.
  ///
  /// In en, this message translates to:
  /// **'Move to device'**
  String get transferMoveToDevice;

  /// No description provided for @transferMoveFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Moving from {device}'**
  String transferMoveFromDevice(String device);

  /// No description provided for @transferMoveToDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Moving to {device}'**
  String transferMoveToDeviceTitle(String device);

  /// No description provided for @transferMoveQueued.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moving 1 file to {device}} other{Moving {count} files to {device}}}'**
  String transferMoveQueued(int count, String device);

  /// No description provided for @transferMoveDownloadQueued.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moving 1 file from {device}} other{Moving {count} files from {device}}}'**
  String transferMoveDownloadQueued(int count, String device);

  /// No description provided for @transferVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get transferVerifying;

  /// No description provided for @transferVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get transferVerified;

  /// No description provided for @transferVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Original kept.'**
  String get transferVerifyFailed;

  /// No description provided for @transferAlreadyMoved.
  ///
  /// In en, this message translates to:
  /// **'Already moved'**
  String get transferAlreadyMoved;

  /// No description provided for @transferOriginalPending.
  ///
  /// In en, this message translates to:
  /// **'Verified · original not deleted yet'**
  String get transferOriginalPending;

  /// No description provided for @transferOriginalTrashed.
  ///
  /// In en, this message translates to:
  /// **'Verified · original moved to trash'**
  String get transferOriginalTrashed;

  /// No description provided for @transferOriginalTrashedOn.
  ///
  /// In en, this message translates to:
  /// **'Verified · original moved to trash on {device}'**
  String transferOriginalTrashedOn(String device);

  /// No description provided for @transferOriginalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Verified · original deleted'**
  String get transferOriginalDeleted;

  /// No description provided for @transferOriginalGone.
  ///
  /// In en, this message translates to:
  /// **'Verified · original was already gone'**
  String get transferOriginalGone;

  /// No description provided for @transferOriginalKeptDeclined.
  ///
  /// In en, this message translates to:
  /// **'Verified · original kept (you declined)'**
  String get transferOriginalKeptDeclined;

  /// No description provided for @transferOriginalKeptDeclinedOn.
  ///
  /// In en, this message translates to:
  /// **'Verified · original kept (declined on {device})'**
  String transferOriginalKeptDeclinedOn(String device);

  /// No description provided for @transferOriginalKeptCancelled.
  ///
  /// In en, this message translates to:
  /// **'Verified · original kept (cancelled)'**
  String get transferOriginalKeptCancelled;

  /// No description provided for @transferOriginalKeptChanged.
  ///
  /// In en, this message translates to:
  /// **'Original kept (changed)'**
  String get transferOriginalKeptChanged;

  /// No description provided for @transferOriginalKeptFailed.
  ///
  /// In en, this message translates to:
  /// **'Verified · original kept (couldn’t delete it)'**
  String get transferOriginalKeptFailed;

  /// No description provided for @transferDeleteOriginals.
  ///
  /// In en, this message translates to:
  /// **'Delete originals'**
  String get transferDeleteOriginals;

  /// No description provided for @transferDeletingOriginals.
  ///
  /// In en, this message translates to:
  /// **'Deleting originals…'**
  String get transferDeletingOriginals;

  /// No description provided for @permanentMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete originals permanently?'**
  String get permanentMoveTitle;

  /// No description provided for @permanentMoveBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Your delete setting is “Delete permanently”: the original is deleted for good once its copy is verified.} other{Your delete setting is “Delete permanently”: the {count} originals are deleted for good once their copies are verified.}}'**
  String permanentMoveBody(int count);

  /// No description provided for @permanentMoveUseTrash.
  ///
  /// In en, this message translates to:
  /// **'Use trash instead'**
  String get permanentMoveUseTrash;

  /// No description provided for @permanentMoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get permanentMoveConfirm;

  /// No description provided for @transferDownloadAction.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get transferDownloadAction;

  /// No description provided for @transferDownloadQueued.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Downloading 1 file from {device}} other{Downloading {count} files from {device}}}'**
  String transferDownloadQueued(int count, String device);

  /// No description provided for @transferUploadQueued.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Sending 1 file to {device}} other{Sending {count} files to {device}}}'**
  String transferUploadQueued(int count, String device);

  /// No description provided for @transferShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get transferShow;

  /// No description provided for @transferSendToDevice.
  ///
  /// In en, this message translates to:
  /// **'Send to device'**
  String get transferSendToDevice;

  /// No description provided for @transferConnectFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect to a device first'**
  String get transferConnectFirst;

  /// No description provided for @transferDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Download 1 file?} other{Download {count} files?}}'**
  String transferDownloadTitle(int count);

  /// No description provided for @transferDownloadTo.
  ///
  /// In en, this message translates to:
  /// **'Saved in {folder}'**
  String transferDownloadTo(String folder);

  /// No description provided for @transferChangeFolder.
  ///
  /// In en, this message translates to:
  /// **'Change folder'**
  String get transferChangeFolder;

  /// No description provided for @transferPickDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Send to which device?'**
  String get transferPickDeviceTitle;

  /// No description provided for @transferNoRememberedDevices.
  ///
  /// In en, this message translates to:
  /// **'No remembered devices yet. Connect to one with “Remember this device” on.'**
  String get transferNoRememberedDevices;

  /// No description provided for @swipeProblemDeviceMissing.
  ///
  /// In en, this message translates to:
  /// **'That device isn’t remembered any more'**
  String get swipeProblemDeviceMissing;

  /// No description provided for @swipeActionSendToDevice.
  ///
  /// In en, this message translates to:
  /// **'Send to device…'**
  String get swipeActionSendToDevice;

  /// No description provided for @swipeActionSendToNamed.
  ///
  /// In en, this message translates to:
  /// **'Send to {device}'**
  String swipeActionSendToNamed(String device);

  /// No description provided for @rememberedRemoveTransfers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Its 1 transfer is removed too.} other{Its {count} transfers are removed too.}}'**
  String rememberedRemoveTransfers(int count);

  /// No description provided for @errorLogShare.
  ///
  /// In en, this message translates to:
  /// **'Share error log'**
  String get errorLogShare;

  /// No description provided for @errorLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No errors logged'**
  String get errorLogEmpty;

  /// No description provided for @errorLogShareSubject.
  ///
  /// In en, this message translates to:
  /// **'KFM error log'**
  String get errorLogShareSubject;

  /// No description provided for @errorLogShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share the error log'**
  String get errorLogShareFailed;

  /// No description provided for @errorLogClear.
  ///
  /// In en, this message translates to:
  /// **'Clear error log'**
  String get errorLogClear;

  /// No description provided for @errorLogClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear the error log? This can\'t be undone.'**
  String get errorLogClearConfirm;

  /// No description provided for @errorLogCleared.
  ///
  /// In en, this message translates to:
  /// **'Error log cleared'**
  String get errorLogCleared;

  /// No description provided for @errorLogClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t clear the error log'**
  String get errorLogClearFailed;

  /// Debug-only Developer tile (H5): throws an uncaught error to test the error log.
  ///
  /// In en, this message translates to:
  /// **'Throw test error'**
  String get devThrowTestError;

  /// Settings → Appearance (L1): heading above the color theme swatches.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get themeColorLabel;

  /// L1 color theme name (default); swatch tooltip and screen-reader label.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get accentBlue;

  /// L1 color theme name.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get accentGreen;

  /// L1 color theme name.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get accentPurple;

  /// L1 color theme name.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get accentOrange;

  /// L1 color theme name: grayscale, no accent color.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get accentMono;

  /// L1 color theme that follows the wallpaper colors (Android 12+ only).
  ///
  /// In en, this message translates to:
  /// **'System colors'**
  String get accentSystem;

  /// L4/L5 Settings section title.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get settingsAccessibility;

  /// L4 switch: mirror the bottom controls for left-handed use.
  ///
  /// In en, this message translates to:
  /// **'Left-handed'**
  String get leftHandedTitle;

  /// L5 picker title.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSizeLabel;

  /// L5 text size: follow the system font size only.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get textSizeSystem;

  /// L5 text size: 1.3x the system font size.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// L5 text size: 1.6x the system font size.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get textSizeExtraLarge;

  /// L5 live preview line under the text size picker, shown at the chosen size.
  ///
  /// In en, this message translates to:
  /// **'This is how text will look.'**
  String get textSizePreview;

  /// U1 section title above the storage places (internal storage, SD card, USB drive, camera) on the Browse root.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get externalPlacesTitle;

  /// U1 place row: the phone's own storage.
  ///
  /// In en, this message translates to:
  /// **'Internal storage'**
  String get externalInternal;

  /// U1 place row when Android doesn't say whether it is an SD card or a USB drive.
  ///
  /// In en, this message translates to:
  /// **'External storage'**
  String get externalGeneric;

  /// U1 place row label for an SD card without a name.
  ///
  /// In en, this message translates to:
  /// **'SD card'**
  String get externalSdCard;

  /// U1 place row label for a USB drive without a name.
  ///
  /// In en, this message translates to:
  /// **'USB drive'**
  String get externalUsbDrive;

  /// U1 place row subtitle, e.g. '12.3 GB free of 64 GB'.
  ///
  /// In en, this message translates to:
  /// **'{free} free of {total}'**
  String externalFreeOf(String free, String total);

  /// U1 snackbar when an SD card / USB drive / camera is plugged in.
  ///
  /// In en, this message translates to:
  /// **'{label} connected'**
  String externalAttached(String label);

  /// U1 snackbar action: open the place that was just connected.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get externalOpen;

  /// U1 snackbar when an SD card / USB drive is unplugged or unmounted.
  ///
  /// In en, this message translates to:
  /// **'Storage removed'**
  String get externalRemoved;

  /// U1 title of the one-time explanation before the system folder picker.
  ///
  /// In en, this message translates to:
  /// **'Allow access to {label}'**
  String externalGrantTitle(String label);

  /// U1 one-time explanation before the system folder picker for an SD card or USB drive.
  ///
  /// In en, this message translates to:
  /// **'Android asks once which drive KFM may use. On the next screen, choose the drive itself (not a folder inside it) and tap “Use this folder”.'**
  String get externalGrantExplain;

  /// U1 button that opens the system folder picker.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get externalGrantContinue;

  /// U1 title when the user picked a folder inside the drive.
  ///
  /// In en, this message translates to:
  /// **'Pick the drive itself'**
  String get externalPickRootTitle;

  /// U1 explanation when the user picked a subfolder in the system folder picker; nothing was saved.
  ///
  /// In en, this message translates to:
  /// **'That was a folder inside the drive. Pick the drive’s top level so KFM can see all of it.'**
  String get externalPickRootHint;

  /// U1 button that reopens the system folder picker after a wrong pick.
  ///
  /// In en, this message translates to:
  /// **'Pick again'**
  String get externalRetry;

  /// U1 snackbar when the folder grant could not be kept.
  ///
  /// In en, this message translates to:
  /// **'Android didn’t keep the access. Try again.'**
  String get externalGrantFailed;

  /// U1 title when an SD card / USB drive can only be opened with All files access (Android 11+ blocks picking a drive's root).
  ///
  /// In en, this message translates to:
  /// **'Open {label}'**
  String externalAllFilesTitle(String label);

  /// U1 explanation before opening the All files access system page for an SD card / USB drive.
  ///
  /// In en, this message translates to:
  /// **'To open {label}, KFM needs All files access. Android doesn’t let apps choose a whole SD card or USB drive any other way. On the next screen, turn on access for KFM, then come back.'**
  String externalAllFilesExplain(String label);

  /// U1 snackbar when the user came back from the system page without turning on All files access.
  ///
  /// In en, this message translates to:
  /// **'All files access is still off, so {label} can’t be opened.'**
  String externalAllFilesStillOff(String label);

  /// U1 help shown when a USB stick is plugged in but no storage appears within a few seconds.
  ///
  /// In en, this message translates to:
  /// **'The USB drive didn’t open. Android reads FAT32 and exFAT drives; NTFS drives often don’t work. Reformat it on a computer or try another drive.'**
  String get externalFormatHelp;

  /// U1 place row for a camera connected over USB.
  ///
  /// In en, this message translates to:
  /// **'Camera · {model}'**
  String externalCameraLabel(String model);

  /// U1 when a USB camera can't be opened (another app holds it or the phone doesn't allow it).
  ///
  /// In en, this message translates to:
  /// **'This camera can’t be opened here. Close other camera apps, or set the camera to USB mass storage.'**
  String get externalCameraUnsupported;

  /// U1 camera row subtitle while the USB permission isn't granted.
  ///
  /// In en, this message translates to:
  /// **'Permission needed · Tap to allow'**
  String get externalPermissionNeeded;

  /// U1 camera row subtitle when the camera is connected and allowed.
  ///
  /// In en, this message translates to:
  /// **'Connected · read-only'**
  String get externalCameraReadOnly;

  /// U1 snackbar when a connected camera is tapped (browsing cameras comes later).
  ///
  /// In en, this message translates to:
  /// **'Opening cameras isn’t available yet.'**
  String get externalCameraNotYet;

  /// U1 places section error row.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read the storage list.'**
  String get externalLoadError;

  /// X2 settings section title.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacySectionTitle;

  /// X2 switch: strip GPS/location from photos and videos that leave the device.
  ///
  /// In en, this message translates to:
  /// **'Remove location when sharing'**
  String get privacyStripLocation;

  /// X2 switch subtitle.
  ///
  /// In en, this message translates to:
  /// **'Photos and videos you share or send to another device go without location info. Your originals keep it.'**
  String get privacyStripLocationHelp;

  /// X2 row shown while ACCESS_MEDIA_LOCATION isn't granted; tapping asks for it.
  ///
  /// In en, this message translates to:
  /// **'Allow access to photo locations'**
  String get privacyAllowAccess;

  /// X2 row subtitle while Remove location is off.
  ///
  /// In en, this message translates to:
  /// **'Without it, photos you send arrive without their location.'**
  String get privacyAllowAccessHelp;

  /// X2 note while Remove location is on and location access isn't granted.
  ///
  /// In en, this message translates to:
  /// **'KFM can\'t read the original location of your photos; they\'re sent without it anyway.'**
  String get privacyNoOriginalNote;

  /// X2 file menu / selection action and the share sheet's confirm button: Android share sheet.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get privacyShareAction;

  /// X2 share sheet title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Share 1 file} other{Share {count} files}}'**
  String privacyShareTitle(int count);

  /// X2 share sheet switch.
  ///
  /// In en, this message translates to:
  /// **'Remove location'**
  String get privacyShareRemoveLocation;

  /// X2 share sheet switch subtitle.
  ///
  /// In en, this message translates to:
  /// **'From photos and videos. Your originals keep it.'**
  String get privacyShareRemoveLocationHelp;

  /// X2 progress dialog while copies without location are made.
  ///
  /// In en, this message translates to:
  /// **'Removing location… {done}/{total}'**
  String privacyRemovingLocation(int done, int total);

  /// X2 snackbar: the Android share sheet couldn't open.
  ///
  /// In en, this message translates to:
  /// **'No app can receive these files'**
  String get privacyShareNoApp;

  /// X2 dialog title; the list of files and reasons follows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Location couldn\'t be removed from 1 file, so it wasn\'t shared} other{Location couldn\'t be removed from {count} files, so they weren\'t shared}}'**
  String privacyCouldNotStrip(int count);

  /// X2 dialog line: file name and why its location couldn't be removed.
  ///
  /// In en, this message translates to:
  /// **'{name}: {reason}'**
  String privacyFailedLine(String name, String reason);

  /// X2 failure reason.
  ///
  /// In en, this message translates to:
  /// **'location info was still found after removing it'**
  String get privacyFailStillHasLocation;

  /// X2 failure reason (damaged or very large video metadata).
  ///
  /// In en, this message translates to:
  /// **'this video\'s info can\'t be edited'**
  String get privacyFailUnsupported;

  /// X2 failure reason.
  ///
  /// In en, this message translates to:
  /// **'the file couldn\'t be read'**
  String get privacyFailReadFailed;

  /// X2 transfer file error.
  ///
  /// In en, this message translates to:
  /// **'Location couldn\'t be removed, so it wasn\'t sent'**
  String get privacyTransferNotRemoved;

  /// X2 dialog before moving photos/videos to another device with Remove location on.
  ///
  /// In en, this message translates to:
  /// **'Move without location?'**
  String get privacyMoveWarningTitle;

  /// X2 move warning body.
  ///
  /// In en, this message translates to:
  /// **'The copies will have no location, and the originals with location will be deleted from this device.'**
  String get privacyMoveWarningBody;

  /// X2 move warning button.
  ///
  /// In en, this message translates to:
  /// **'Move anyway'**
  String get privacyMoveAnyway;

  /// X2 move warning default button: send copies, keep the originals.
  ///
  /// In en, this message translates to:
  /// **'Copy instead'**
  String get privacyCopyInstead;

  /// U2 job card title (On this phone).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copying 1 file to {place}} other{Copying {count} files to {place}}}'**
  String externalJobTitleCopy(int count, String place);

  /// U2 job card title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moving 1 file to {place}} other{Moving {count} files to {place}}}'**
  String externalJobTitleMove(int count, String place);

  /// U2 job card progress line.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} · {size}'**
  String externalJobProgress(int done, int total, String size);

  /// U2 job status.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get externalJobQueued;

  /// U2 job status.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get externalJobRunning;

  /// U2 job status (paused by the user or after a restart).
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get externalJobPaused;

  /// U2 job status when a place was removed mid-job.
  ///
  /// In en, this message translates to:
  /// **'Paused · connect the storage again to continue'**
  String get externalJobPausedUnplugged;

  /// U2 job status.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get externalJobDone;

  /// U2 job status.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get externalJobCancelled;

  /// U2 job status.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file failed} other{{count} files failed}}'**
  String externalJobFailed(int count);

  /// U2 job status.
  ///
  /// In en, this message translates to:
  /// **'Stopped: not enough space'**
  String get externalJobStoppedNoSpace;

  /// U2 job button.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get externalJobResume;

  /// U2 job button.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get externalJobPause;

  /// U2 job button: shows the job log.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get externalJobDetails;

  /// U2 snackbar after a copy job started.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copying 1 file…} other{Copying {count} files…}}'**
  String externalJobStartedCopy(int count);

  /// U2 snackbar after a move job started.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moving 1 file…} other{Moving {count} files…}}'**
  String externalJobStartedMove(int count);

  /// U2 snackbar action: open the Transfers page.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get externalJobView;

  /// U2 pre-check.
  ///
  /// In en, this message translates to:
  /// **'Not enough space on {place}'**
  String externalNotEnoughSpace(String place);

  /// U2 pre-check (files pass through an app folder on internal storage).
  ///
  /// In en, this message translates to:
  /// **'Not enough free space on this phone to copy through it'**
  String get externalStagingNoSpace;

  /// U2 job log line.
  ///
  /// In en, this message translates to:
  /// **'{name}: 4 GB or larger, too big for this drive (FAT32)'**
  String externalFat32TooLarge(String name);

  /// U2 job log line: the drive refuses some characters.
  ///
  /// In en, this message translates to:
  /// **'{from} saved as {to}'**
  String externalRenamedForDrive(String from, String to);

  /// U2 dialog before a job.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file is already there} other{{count} files are already there}}'**
  String externalCollisionTitle(int count);

  /// U2 collision choice (default).
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get externalCollisionKeepBoth;

  /// U2 collision choice.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get externalCollisionSkip;

  /// U2 collision choice: the old file is removed only after the new one is verified.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get externalCollisionReplace;

  /// U2 collision dialog body.
  ///
  /// In en, this message translates to:
  /// **'Your choice applies to every file of this job.'**
  String get externalApplyToAll;

  /// U2 shown once per session on the first delete swipe of a camera file.
  ///
  /// In en, this message translates to:
  /// **'Camera photos have no trash: deleting them here deletes them for good.'**
  String get externalCameraDeleteWarning;

  /// U2 job line for a move whose originals were kept.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 original wasn’t removed} other{{count} originals weren’t removed}}'**
  String externalOriginalNotRemoved(int count);

  /// U2 job button: retry deleting kept originals.
  ///
  /// In en, this message translates to:
  /// **'Delete originals'**
  String get externalDeleteOriginals;

  /// U2 place browser action.
  ///
  /// In en, this message translates to:
  /// **'Swipe this folder'**
  String get externalSwipeFolder;

  /// U2 snackbar.
  ///
  /// In en, this message translates to:
  /// **'No photos or videos in this folder'**
  String get externalSwipeFolderEmpty;

  /// U2 empty On this phone tab.
  ///
  /// In en, this message translates to:
  /// **'No copies or moves between storage places in the last 7 days'**
  String get externalNoJobs;

  /// U2 On this phone action.
  ///
  /// In en, this message translates to:
  /// **'Clear finished'**
  String get externalClearFinished;

  /// U2 job log line.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Original kept.'**
  String get externalVerifyFailed;

  /// U2 job log line.
  ///
  /// In en, this message translates to:
  /// **'The file is gone'**
  String get externalSourceGone;

  /// U2 job log line.
  ///
  /// In en, this message translates to:
  /// **'Already moved'**
  String get externalAlreadyMoved;

  /// U2 job log line.
  ///
  /// In en, this message translates to:
  /// **'Skipped: already there'**
  String get externalSkippedExists;

  /// U2 job log line (other errors).
  ///
  /// In en, this message translates to:
  /// **'Couldn’t copy'**
  String get externalFileFailed;

  /// U2 job log line.
  ///
  /// In en, this message translates to:
  /// **'{name}: {reason}'**
  String externalLogLine(String name, String reason);

  /// U2 place browser.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get externalFolderEmpty;

  /// U2 place browser error.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open this folder'**
  String get externalFolderError;

  /// U2 place browser sort option.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get externalSortByName;

  /// U2 place browser sort option.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get externalSortByDate;

  /// U2 place browser sort option.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get externalSortBySize;

  /// U2 place browser filter option.
  ///
  /// In en, this message translates to:
  /// **'All files'**
  String get externalShowAll;

  /// U2 place browser filter option.
  ///
  /// In en, this message translates to:
  /// **'Photos and videos'**
  String get externalShowMedia;

  /// U2 place browser file menu.
  ///
  /// In en, this message translates to:
  /// **'Copy to…'**
  String get externalCopyTo;

  /// U2 place browser file menu.
  ///
  /// In en, this message translates to:
  /// **'Move to…'**
  String get externalMoveTo;

  /// U2 place browser file menu.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get externalDelete;

  /// U2 place browser subtitle for cameras.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get externalReadOnly;

  /// U2 place browser snackbar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file deleted} other{{count} files deleted}}'**
  String externalDeleted(int count);

  /// U2 place browser snackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t delete'**
  String get externalDeleteFailed;

  /// S6 setup sheet title.
  ///
  /// In en, this message translates to:
  /// **'Swipe setup'**
  String get swipeSetupTitle;

  /// No description provided for @swipeSetupTuneTooltip.
  ///
  /// In en, this message translates to:
  /// **'Swipe setup'**
  String get swipeSetupTuneTooltip;

  /// No description provided for @swipeSetupPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get swipeSetupPresets;

  /// No description provided for @swipeSetupDirections.
  ///
  /// In en, this message translates to:
  /// **'Swipe directions'**
  String get swipeSetupDirections;

  /// No description provided for @swipeSetupFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get swipeSetupFilter;

  /// No description provided for @swipeSetupEditFilter.
  ///
  /// In en, this message translates to:
  /// **'Edit filter'**
  String get swipeSetupEditFilter;

  /// No description provided for @swipeSetupExtras.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get swipeSetupExtras;

  /// No description provided for @swipeSetupModified.
  ///
  /// In en, this message translates to:
  /// **'Changes not saved to {name}'**
  String swipeSetupModified(String name);

  /// No description provided for @swipeSetupSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get swipeSetupSave;

  /// No description provided for @swipeSetupSaveAsNew.
  ///
  /// In en, this message translates to:
  /// **'Save as new…'**
  String get swipeSetupSaveAsNew;

  /// No description provided for @swipeSetupRevert.
  ///
  /// In en, this message translates to:
  /// **'Revert'**
  String get swipeSetupRevert;

  /// No description provided for @swipeSetupSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to “{name}”'**
  String swipeSetupSavedTo(String name);

  /// No description provided for @swipeSetupRemoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup for swiping on {device}'**
  String swipeSetupRemoteTitle(String device);

  /// No description provided for @swipeSetupPresetSemantics.
  ///
  /// In en, this message translates to:
  /// **'Preset {name}'**
  String swipeSetupPresetSemantics(String name);

  /// No description provided for @swipeSetupPresetModifiedSemantics.
  ///
  /// In en, this message translates to:
  /// **'Preset {name}, modified'**
  String swipeSetupPresetModifiedSemantics(String name);

  /// No description provided for @swipeSetupDirectionSemantics.
  ///
  /// In en, this message translates to:
  /// **'{direction}: {action}'**
  String swipeSetupDirectionSemantics(String direction, String action);

  /// No description provided for @swipeSetupFilterOn.
  ///
  /// In en, this message translates to:
  /// **'Filter on'**
  String get swipeSetupFilterOn;

  /// S6 chip of a preset whose saved data can't be read.
  ///
  /// In en, this message translates to:
  /// **'Can\'t load'**
  String get swipeSetupPresetBroken;

  /// U3 button/tooltip on a removable place (SD card, USB drive, camera).
  ///
  /// In en, this message translates to:
  /// **'Eject'**
  String get ejectAction;

  /// No description provided for @ejectRunningJobs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transfer still running} other{{count} transfers still running}}'**
  String ejectRunningJobs(int count);

  /// No description provided for @ejectRunningJobsBody.
  ///
  /// In en, this message translates to:
  /// **'Pausing stops after the current file. Paused transfers can be resumed later.'**
  String get ejectRunningJobsBody;

  /// No description provided for @ejectWait.
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get ejectWait;

  /// No description provided for @ejectPauseAndEject.
  ///
  /// In en, this message translates to:
  /// **'Pause & eject'**
  String get ejectPauseAndEject;

  /// No description provided for @ejectWaiting.
  ///
  /// In en, this message translates to:
  /// **'Finishing work on {label}…'**
  String ejectWaiting(String label);

  /// No description provided for @ejectHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Eject {label}'**
  String ejectHintTitle(String label);

  /// No description provided for @ejectHint.
  ///
  /// In en, this message translates to:
  /// **'Android lets only its own settings eject storage. Tap the drive, then Eject (on some phones: ⋮ → Unmount).'**
  String get ejectHint;

  /// No description provided for @ejectOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get ejectOpenSettings;

  /// No description provided for @ejectSafe.
  ///
  /// In en, this message translates to:
  /// **'{label} can be safely removed'**
  String ejectSafe(String label);

  /// No description provided for @ejectNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not ejected yet'**
  String get ejectNotYet;

  /// No description provided for @ejectOpenAgain.
  ///
  /// In en, this message translates to:
  /// **'Open settings again'**
  String get ejectOpenAgain;

  /// No description provided for @ejectCameraSafe.
  ///
  /// In en, this message translates to:
  /// **'Camera can be disconnected'**
  String get ejectCameraSafe;

  /// No description provided for @ejectRefused.
  ///
  /// In en, this message translates to:
  /// **'This storage is being ejected'**
  String get ejectRefused;

  /// No description provided for @ejectFailed.
  ///
  /// In en, this message translates to:
  /// **'Can\'t open the storage settings'**
  String get ejectFailed;

  /// No description provided for @sendTo.
  ///
  /// In en, this message translates to:
  /// **'Send to…'**
  String get sendTo;

  /// No description provided for @sendSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Send 1 file to…} other{Send {count} files to…}}'**
  String sendSheetTitle(int count);

  /// No description provided for @sendSheetConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get sendSheetConnected;

  /// No description provided for @sendSheetConnectedToYou.
  ///
  /// In en, this message translates to:
  /// **'Connected to you'**
  String get sendSheetConnectedToYou;

  /// No description provided for @sendSheetRemembered.
  ///
  /// In en, this message translates to:
  /// **'Remembered'**
  String get sendSheetRemembered;

  /// No description provided for @sendSheetNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get sendSheetNearby;

  /// No description provided for @sendSheetOnline.
  ///
  /// In en, this message translates to:
  /// **'Nearby now'**
  String get sendSheetOnline;

  /// No description provided for @sendAskReceive.
  ///
  /// In en, this message translates to:
  /// **'Ask {device} to open Receive files'**
  String sendAskReceive(String device);

  /// No description provided for @sendSwitchDevice.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from {from} to send to {to}?'**
  String sendSwitchDevice(String from, String to);

  /// No description provided for @sendSwitchAction.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get sendSwitchAction;

  /// No description provided for @sendConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {device}…'**
  String sendConnecting(String device);

  /// No description provided for @sendConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Send 1 file ({size}) to {device}?} other{Send {count} files ({size}) to {device}?}}'**
  String sendConfirmTitle(int count, String size, String device);

  /// No description provided for @sendConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'{device} decides whether to take them. Nothing else is shared.'**
  String sendConfirmHint(String device);

  /// No description provided for @sendSharedFolderInstead.
  ///
  /// In en, this message translates to:
  /// **'Put them in a shared folder on {device}…'**
  String sendSharedFolderInstead(String device);

  /// No description provided for @sendAction.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendAction;

  /// No description provided for @sendWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {device} to accept…'**
  String sendWaiting(String device);

  /// No description provided for @sendDeclined.
  ///
  /// In en, this message translates to:
  /// **'{device} declined'**
  String sendDeclined(String device);

  /// No description provided for @sendNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No answer from {device}'**
  String sendNoAnswer(String device);

  /// No description provided for @sendNoSpace.
  ///
  /// In en, this message translates to:
  /// **'Not enough space on {device}'**
  String sendNoSpace(String device);

  /// No description provided for @sendStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped by {device}'**
  String sendStopped(String device);

  /// No description provided for @sendSending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Sending 1 file to {device}} other{Sending {count} files to {device}}}'**
  String sendSending(int count, String device);

  /// No description provided for @sendPairToSend.
  ///
  /// In en, this message translates to:
  /// **'Connect to send files'**
  String get sendPairToSend;

  /// No description provided for @sendConfirmPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Send 1 file to {device}} other{Send {count} files to {device}}}'**
  String sendConfirmPanelTitle(int count, String device);

  /// No description provided for @receiveFiles.
  ///
  /// In en, this message translates to:
  /// **'Receive files'**
  String get receiveFiles;

  /// No description provided for @receiveFilesHint.
  ///
  /// In en, this message translates to:
  /// **'Let another device send you files'**
  String get receiveFilesHint;

  /// No description provided for @receiveReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to receive files'**
  String get receiveReadyTitle;

  /// No description provided for @receiveReadyHint.
  ///
  /// In en, this message translates to:
  /// **'On the other device: Send to… → {device}, or scan this code'**
  String receiveReadyHint(String device);

  /// No description provided for @offerTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{device} wants to send you 1 file} other{{device} wants to send you {count} files}}'**
  String offerTitle(String device, int count);

  /// No description provided for @offerSize.
  ///
  /// In en, this message translates to:
  /// **'Total {size}'**
  String offerSize(String size);

  /// No description provided for @offerMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{and 1 more} other{and {count} more}}'**
  String offerMore(int count);

  /// No description provided for @offerSaveTo.
  ///
  /// In en, this message translates to:
  /// **'Save to {folder}'**
  String offerSaveTo(String folder);

  /// No description provided for @offerChangeFolder.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get offerChangeFolder;

  /// No description provided for @offerFolderExcluded.
  ///
  /// In en, this message translates to:
  /// **'Files can\'t be saved there'**
  String get offerFolderExcluded;

  /// No description provided for @offerRemember.
  ///
  /// In en, this message translates to:
  /// **'Remember {device}'**
  String offerRemember(String device);

  /// No description provided for @offerAlwaysAccept.
  ///
  /// In en, this message translates to:
  /// **'Always accept files from {device}'**
  String offerAlwaysAccept(String device);

  /// No description provided for @offerAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get offerAccept;

  /// No description provided for @offerDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get offerDecline;

  /// No description provided for @offerAutoDecline.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{Declines in 1 second} other{Declines in {seconds} seconds}}'**
  String offerAutoDecline(int seconds);

  /// No description provided for @offerNotificationChannel.
  ///
  /// In en, this message translates to:
  /// **'Incoming files'**
  String get offerNotificationChannel;

  /// No description provided for @offerNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} wants to send you files'**
  String offerNotificationTitle(String device);

  /// No description provided for @offerNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file · {size} · Tap to answer} other{{count} files · {size} · Tap to answer}}'**
  String offerNotificationBody(int count, String size);

  /// No description provided for @offerReceiving.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Receiving 1 file from {device}} other{Receiving {count} files from {device}}}'**
  String offerReceiving(int count, String device);

  /// No description provided for @offerReceived.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Received 1 file from {device}} other{Received {count} files from {device}}}'**
  String offerReceived(int count, String device);

  /// No description provided for @offerOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get offerOpenFolder;

  /// No description provided for @rememberedAcceptFiles.
  ///
  /// In en, this message translates to:
  /// **'Accept files without asking'**
  String get rememberedAcceptFiles;

  /// No description provided for @rememberedAcceptFilesHint.
  ///
  /// In en, this message translates to:
  /// **'Files this device sends go to your Download folder without a prompt'**
  String get rememberedAcceptFilesHint;

  /// No description provided for @connectSendOnly.
  ///
  /// In en, this message translates to:
  /// **'Connected to {device} to send files'**
  String connectSendOnly(String device);

  /// No description provided for @shareSessionSending.
  ///
  /// In en, this message translates to:
  /// **'{device} · sending files'**
  String shareSessionSending(String device);

  /// No description provided for @transferReceivedSection.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get transferReceivedSection;

  /// No description provided for @transferOfferedSection.
  ///
  /// In en, this message translates to:
  /// **'Offered'**
  String get transferOfferedSection;

  /// No description provided for @transferWaitingForYou.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get transferWaitingForYou;

  /// No description provided for @transferPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get transferPreparing;

  /// No description provided for @transferFromDeviceOffer.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{From {device} · 1 file · {size}} other{From {device} · {count} files · {size}}}'**
  String transferFromDeviceOffer(String device, int count, String size);

  /// No description provided for @transferToDeviceOffer.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{To {device} · 1 file · {size}} other{To {device} · {count} files · {size}}}'**
  String transferToDeviceOffer(String device, int count, String size);

  /// No description provided for @transferOfferReceiving.
  ///
  /// In en, this message translates to:
  /// **'{done} of {count} received'**
  String transferOfferReceiving(int done, int count);

  /// No description provided for @transferOfferDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get transferOfferDone;

  /// No description provided for @transferOfferCancelled.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get transferOfferCancelled;

  /// No description provided for @transferOfferDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get transferOfferDeclined;

  /// No description provided for @transferOfferExpired.
  ///
  /// In en, this message translates to:
  /// **'No answer'**
  String get transferOfferExpired;

  /// No description provided for @transferOfferStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get transferOfferStop;

  /// No description provided for @transferOfferAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get transferOfferAnswer;

  /// No description provided for @transferOfferOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get transferOfferOpenFolder;

  /// No description provided for @transferOfferAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get transferOfferAccepted;

  /// No description provided for @transfersEmptyReceived.
  ///
  /// In en, this message translates to:
  /// **'Files other devices send you show here'**
  String get transfersEmptyReceived;

  /// No description provided for @shareInTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shared file} other{{count} shared files}}'**
  String shareInTitle(int count);

  /// No description provided for @shareInSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe through them'**
  String get shareInSwipe;

  /// No description provided for @shareInMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to…'**
  String get shareInMoveTo;

  /// No description provided for @shareInCopyTo.
  ///
  /// In en, this message translates to:
  /// **'Copy to…'**
  String get shareInCopyTo;

  /// No description provided for @shareInSendToDevice.
  ///
  /// In en, this message translates to:
  /// **'Send to…'**
  String get shareInSendToDevice;

  /// No description provided for @shareInCopiedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{size} · Copied from another app'**
  String shareInCopiedSubtitle(String size);

  /// No description provided for @shareInCopyDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Files copied from another app are removed from KFM when you delete them. The original stays in that app.'**
  String get shareInCopyDeleteNote;

  /// No description provided for @shareInOnlyFiles.
  ///
  /// In en, this message translates to:
  /// **'Only files can be shared into KFM'**
  String get shareInOnlyFiles;

  /// No description provided for @shareInPreparing.
  ///
  /// In en, this message translates to:
  /// **'Getting the shared files…'**
  String get shareInPreparing;

  /// No description provided for @shareInCopying.
  ///
  /// In en, this message translates to:
  /// **'Copying {done} of {total}'**
  String shareInCopying(String done, String total);

  /// No description provided for @shareInCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get shareInCancel;

  /// No description provided for @shareInFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file couldn\'t be read} other{{count} files couldn\'t be read}}'**
  String shareInFailed(int count);

  /// No description provided for @shareInFailedAll.
  ///
  /// In en, this message translates to:
  /// **'The shared files couldn\'t be read. Try sharing them again.'**
  String get shareInFailedAll;

  /// No description provided for @shareInNoSpace.
  ///
  /// In en, this message translates to:
  /// **'Not enough free space to copy the shared files'**
  String get shareInNoSpace;

  /// No description provided for @shareInEmpty.
  ///
  /// In en, this message translates to:
  /// **'No shared files left here'**
  String get shareInEmpty;

  /// No description provided for @shareInDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get shareInDone;

  /// X6 settings section title.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupSectionTitle;

  /// X6 row: save a backup file.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get backupExport;

  /// X6 row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tags, presets, favorites, reviewed labels and settings in one file. Your photos stay where they are.'**
  String get backupExportHelp;

  /// X6 row: read a backup file.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get backupImport;

  /// X6 row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Adds a backup\'s data to this phone. Nothing here is deleted.'**
  String get backupImportHelp;

  /// X6 row: restore the pre-import state.
  ///
  /// In en, this message translates to:
  /// **'Undo last import'**
  String get backupUndoImport;

  /// X6 row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Go back to how things were before the last import'**
  String get backupUndoImportHelp;

  /// X6 snackbar after export.
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupExported;

  /// X6 export error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the backup: {error}'**
  String backupExportFailed(String error);

  /// X6 import error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t import the backup: {error}'**
  String backupImportFailed(String error);

  /// X6: picked file is not a backup.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a KFM backup.'**
  String get backupNotKfm;

  /// X6: backup schema too new.
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer version of KFM. Update the app first.'**
  String get backupTooNew;

  /// X6 preview screen title.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get backupPreviewTitle;

  /// X6: the file index is refreshed before matching.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get backupScanning;

  /// X6 preview count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new tag} other{{count} new tags}}'**
  String backupPreviewNewTags(int count);

  /// X6 preview count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 tag already on this phone} other{{count} tags already on this phone}}'**
  String backupPreviewReusedTags(int count);

  /// X6 preview count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new preset} other{{count} new presets}}'**
  String backupPreviewNewPresets(int count);

  /// X6 preview count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 preset already on this phone} other{{count} presets already on this phone}}'**
  String backupPreviewSkippedPresets(int count);

  /// X6 preview count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file found on this phone} other{{count} files found on this phone}}'**
  String backupPreviewMatched(int count);

  /// X6 preview count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 tag added to a file} other{{count} tags added to files}}'**
  String backupPreviewFileTags(int count);

  /// X6 preview count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new favorite} other{{count} new favorites}}'**
  String backupPreviewFavorites(int count);

  /// X6 preview count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reviewed label} other{{count} reviewed labels}}'**
  String backupPreviewReviewed(int count);

  /// X6 preview: expandable list title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file not found on this phone} other{{count} files not found on this phone}}'**
  String backupPreviewUnmatched(int count);

  /// X6 preview: files beyond the first 200.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{and 1 more} other{and {count} more}}'**
  String backupPreviewUnmatchedMore(int count);

  /// X6 preview: one unmatched file.
  ///
  /// In en, this message translates to:
  /// **'{folder}/{name}'**
  String backupPreviewFilePath(String folder, String name);

  /// X6 preview switch.
  ///
  /// In en, this message translates to:
  /// **'Also apply settings'**
  String get backupApplySettings;

  /// X6 preview: settings diff title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No settings change} =1{1 setting changes} other{{count} settings change}}'**
  String backupPreviewSettings(int count);

  /// X6 preview: empty plan.
  ///
  /// In en, this message translates to:
  /// **'Nothing new to import.'**
  String get backupPreviewNothing;

  /// X6: a same-named but different preset is added as 'Name (imported)'.
  ///
  /// In en, this message translates to:
  /// **'imported'**
  String get backupImportedSuffix;

  /// X6 preview button.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get backupImportButton;

  /// X6 snackbar after import (with Undo).
  ///
  /// In en, this message translates to:
  /// **'Backup imported'**
  String get backupImported;

  /// X6 confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Undo last import?'**
  String get backupUndoConfirmTitle;

  /// X6 confirm dialog body.
  ///
  /// In en, this message translates to:
  /// **'Tags, presets, favorites, reviewed labels and settings go back to how they were before the import. Changes you made after it are lost too.'**
  String get backupUndoConfirmBody;

  /// X6 confirm dialog button.
  ///
  /// In en, this message translates to:
  /// **'Undo import'**
  String get backupUndoConfirm;

  /// X6 snackbar.
  ///
  /// In en, this message translates to:
  /// **'Import undone'**
  String get backupUndone;

  /// X6 undo error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t undo the import: {error}'**
  String backupUndoFailed(String error);

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get backupSettingThemeMode;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Colour theme'**
  String get backupSettingThemeAccent;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Left-handed mode'**
  String get backupSettingLeftHanded;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get backupSettingTextSize;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get backupSettingLanguage;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Big file size'**
  String get backupSettingBigFileThreshold;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Keep deleted files for'**
  String get backupSettingPendingRetention;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Same-time window'**
  String get backupSettingSameTimeWindow;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Sort files by'**
  String get backupSettingBrowseSort;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Sort direction'**
  String get backupSettingBrowseSortDescending;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Show file sizes'**
  String get backupSettingBrowseShowSizes;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Highlight big files'**
  String get backupSettingBrowseHighlightBig;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Second search language'**
  String get backupSettingSearchSecondLanguage;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Basic swipe directions'**
  String get backupSettingSwipeLayout;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Delete mode'**
  String get backupSettingDeleteMode;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Vibration feedback'**
  String get backupSettingHaptics;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Swipe buttons'**
  String get backupSettingSwipeButtons;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Session summary'**
  String get backupSettingSessionSummary;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Show reviewed files in Basic'**
  String get backupSettingBasicIncludeReviewed;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Reviewed badge'**
  String get backupSettingReviewedBadge;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Active preset'**
  String get backupSettingActivePreset;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Action bar'**
  String get backupSettingActionBar;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Drop on a folder'**
  String get backupSettingFoldersDropAction;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Similar photos'**
  String get backupSettingSimilarEnabled;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Similar photos strictness'**
  String get backupSettingSimilarStrictness;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Blurry photo threshold'**
  String get backupSettingSimilarBlur;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Include screenshots in similar photos'**
  String get backupSettingSimilarScreenshots;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Download models on Wi-Fi only'**
  String get backupSettingAiWifiOnly;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Remove location when sharing'**
  String get backupSettingStripLocation;

  /// X6 import preview: the name of a setting the backup changes.
  ///
  /// In en, this message translates to:
  /// **'Other setting'**
  String get backupSettingOther;

  /// X5 info sheet button: hand the APK to Android's installer.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get apkInstall;

  /// X5: the APK's package isn't installed.
  ///
  /// In en, this message translates to:
  /// **'New app'**
  String get apkNewApp;

  /// X5: installed version → APK version.
  ///
  /// In en, this message translates to:
  /// **'Update from {from} to {to}'**
  String apkUpdateFromTo(String from, String to);

  /// X5: same version code as installed.
  ///
  /// In en, this message translates to:
  /// **'This version is already installed'**
  String get apkSameVersion;

  /// X5 warning: the APK has a lower version code.
  ///
  /// In en, this message translates to:
  /// **'Older than the installed version ({installed})'**
  String apkDowngrade(String installed);

  /// X5: another app's package that Android hides from KFM.
  ///
  /// In en, this message translates to:
  /// **'Android will show whether this is a new app or an update'**
  String get apkUnknownInstalled;

  /// X5 warning: signing certificates differ.
  ///
  /// In en, this message translates to:
  /// **'Signed by a different developer. Android will refuse this update. Uninstall the old app first (its data is lost).'**
  String get apkSignerMismatch;

  /// X5 note when the installed app can't be compared.
  ///
  /// In en, this message translates to:
  /// **'Updates must be signed by the same developer.'**
  String get apkSignerUnknown;

  /// X5 note on the info sheet.
  ///
  /// In en, this message translates to:
  /// **'Only install apps from sources you trust.'**
  String get apkTrustNote;

  /// X5: the APK couldn't be parsed.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t a valid app package.'**
  String get apkInvalid;

  /// X5: no room for the cache copy of a USB/SD APK.
  ///
  /// In en, this message translates to:
  /// **'Not enough space to inspect this file.'**
  String get apkNoSpace;

  /// X5: other inspect error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read this file: {error}'**
  String apkReadFailed(String error);

  /// X5 snackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the installer: {error}'**
  String apkInstallFailed(String error);

  /// X5: no installer activity.
  ///
  /// In en, this message translates to:
  /// **'No app on this device can install packages.'**
  String get apkNoInstaller;

  /// X5: before opening the permission page.
  ///
  /// In en, this message translates to:
  /// **'To install apps, Android asks you to allow KFM in \"Install unknown apps\". KFM never installs anything without Android\'s own confirmation.'**
  String get apkPermissionWhy;

  /// X5 button: the "Install unknown apps" page.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get apkOpenSettings;

  /// X5: back from settings without the permission.
  ///
  /// In en, this message translates to:
  /// **'Permission not granted.'**
  String get apkPermissionDenied;

  /// X5 info sheet subtitle.
  ///
  /// In en, this message translates to:
  /// **'{package} · version {version}'**
  String apkPackageLine(String package, String version);

  /// X7 Settings section title.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updatesSectionTitle;

  /// X7 switch (off by default).
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updatesCheckSetting;

  /// X7 switch subtitle.
  ///
  /// In en, this message translates to:
  /// **'Once a day KFM asks GitHub if there\'s a newer version. Nothing about you or your files is sent; GitHub sees your IP address like any website.'**
  String get updatesCheckSettingHelp;

  /// X7 manual check row (works with the switch off).
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get updatesCheckNow;

  /// X7 check-now subtitle before any check.
  ///
  /// In en, this message translates to:
  /// **'Installed version {version}'**
  String updatesCurrentVersion(String version);

  /// X7 while the request runs.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get updatesChecking;

  /// X7 result.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date'**
  String get updatesUpToDate;

  /// X7 manual check: GitHub has no release (404).
  ///
  /// In en, this message translates to:
  /// **'No releases found'**
  String get updatesNoReleases;

  /// X7 banner and result.
  ///
  /// In en, this message translates to:
  /// **'KFM {version} is available'**
  String updatesAvailable(String version);

  /// X7 Settings line after a failed check.
  ///
  /// In en, this message translates to:
  /// **'Last check failed'**
  String get updatesLastCheckFailed;

  /// X7 manual check snackbar: offline/timeout.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach GitHub. Check your connection.'**
  String get updatesFailedOffline;

  /// X7 manual check snackbar: 403/429 rate limit.
  ///
  /// In en, this message translates to:
  /// **'GitHub is busy. Try again later.'**
  String get updatesFailedBusy;

  /// X7 manual check snackbar: other errors.
  ///
  /// In en, this message translates to:
  /// **'Update check failed: {error}'**
  String updatesFailed(String error);

  /// X7 banner button: release notes sheet.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get updatesWhatsNew;

  /// X7 button: opens the release page in the browser.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get updatesDownload;

  /// X7 banner close tooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide until the next version'**
  String get updatesDismiss;

  /// X7 What's new sheet with an empty body.
  ///
  /// In en, this message translates to:
  /// **'No release notes.'**
  String get updatesNoNotes;

  /// X7 snackbar: Download couldn't open the page.
  ///
  /// In en, this message translates to:
  /// **'No browser app found'**
  String get updatesNoBrowser;

  /// X7 snackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the page: {error}'**
  String updatesOpenFailed(String error);

  /// X3 Settings section title.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get cloudSettingsTitle;

  /// X3 Settings row and screen title.
  ///
  /// In en, this message translates to:
  /// **'Cloud destinations'**
  String get cloudDestinations;

  /// X3 Settings row subtitle without destinations.
  ///
  /// In en, this message translates to:
  /// **'Save files into a folder of your cloud app'**
  String get cloudDestinationsNone;

  /// X3 Settings row subtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 folder} other{{count} folders}}'**
  String cloudDestinationsCount(int count);

  /// X3 destinations screen intro.
  ///
  /// In en, this message translates to:
  /// **'KFM saves files into a folder of your cloud app (Google Drive, OneDrive, Dropbox…). The cloud app uploads them; KFM never signs in anywhere.'**
  String get cloudHowItWorks;

  /// X3 destinations screen, empty list.
  ///
  /// In en, this message translates to:
  /// **'No cloud folders yet'**
  String get cloudEmpty;

  /// X3 button: opens the system folder picker.
  ///
  /// In en, this message translates to:
  /// **'Add cloud folder'**
  String get cloudAdd;

  /// X3 snackbar.
  ///
  /// In en, this message translates to:
  /// **'Added {name}'**
  String cloudAdded(String name);

  /// X3 snackbar: the grant could not be persisted.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t keep access to that folder'**
  String get cloudAddFailed;

  /// X3 destination menu.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get cloudRename;

  /// X3 destination menu and dialog button.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get cloudRemove;

  /// X3 remove dialog title.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String cloudRemoveTitle(String name);

  /// X3 remove dialog body.
  ///
  /// In en, this message translates to:
  /// **'KFM won\'t save files here any more. Files already in the cloud stay there.'**
  String get cloudRemoveConfirm;

  /// X3 remove dialog checkbox (off by default).
  ///
  /// In en, this message translates to:
  /// **'Also forget which files were uploaded here'**
  String get cloudForgetUploads;

  /// X3 chip: the folder permission was lost.
  ///
  /// In en, this message translates to:
  /// **'Needs reconnecting'**
  String get cloudNeedsReconnecting;

  /// X3 destination menu: pick the folder again.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get cloudReconnect;

  /// X3 help text.
  ///
  /// In en, this message translates to:
  /// **'If your cloud app isn\'t listed in the folder picker, it doesn\'t let other apps save into its folders.'**
  String get cloudNoFolderPicking;

  /// X3 status of a copy: handed to the cloud app (it uploads later).
  ///
  /// In en, this message translates to:
  /// **'Saved to {name}'**
  String cloudSavedToFolder(String name);

  /// X3 status of a move whose copy was checked.
  ///
  /// In en, this message translates to:
  /// **'Verified in {name}'**
  String cloudVerified(String name);

  /// X3 status.
  ///
  /// In en, this message translates to:
  /// **'Failed: {reason}'**
  String cloudFailed(String reason);

  /// X3 status of a queued file.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get cloudWaiting;

  /// X3 status while copying.
  ///
  /// In en, this message translates to:
  /// **'Saving to {name}…'**
  String cloudUploading(String name);

  /// X3 failure reason.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify the copy — original kept'**
  String get cloudVerifyFailed;

  /// X3 failure reason.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the copy back — original kept'**
  String get cloudVerifyUnavailable;

  /// X3 failure reason.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cloudCancelled;

  /// X3 failure reason.
  ///
  /// In en, this message translates to:
  /// **'Destination removed'**
  String get cloudDestinationRemovedError;

  /// X3 failure reason.
  ///
  /// In en, this message translates to:
  /// **'The file is gone'**
  String get cloudSourceGone;

  /// X3 failure reason.
  ///
  /// In en, this message translates to:
  /// **'The file changed while it was copied'**
  String get cloudSourceChanged;

  /// X3 failure reason.
  ///
  /// In en, this message translates to:
  /// **'This file can\'t be saved to the cloud'**
  String get cloudUnsupported;

  /// X3 failure reason (X2 option on).
  ///
  /// In en, this message translates to:
  /// **'Location couldn\'t be removed, so it wasn\'t uploaded'**
  String get cloudLocationNotRemoved;

  /// X3 outcome reason.
  ///
  /// In en, this message translates to:
  /// **'The cloud copy is missing — original kept'**
  String get cloudCopyMissing;

  /// X3 failure reason.
  ///
  /// In en, this message translates to:
  /// **'The cloud app is out of space'**
  String get cloudNoSpace;

  /// X3 failure reason (other errors).
  ///
  /// In en, this message translates to:
  /// **'The cloud app didn\'t accept the file'**
  String get cloudWriteError;

  /// X3 failure reason when KFM couldn't delete its unfinished or unverified copy from the cloud folder.
  ///
  /// In en, this message translates to:
  /// **'{reason}. A copy was left in the cloud folder'**
  String cloudCopyLeftOver(String reason);

  /// X3 outcome: Delete originals couldn't find the original file (gone or renamed outside KFM).
  ///
  /// In en, this message translates to:
  /// **'Original not found, nothing deleted'**
  String get cloudOriginalNotFound;

  /// X3 one-time note on the destinations screen.
  ///
  /// In en, this message translates to:
  /// **'Photos are uploaded without their location because KFM can\'t read it.'**
  String get cloudGpsNote;

  /// X3 GPS note / move dialog button: asks for the location permission.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get cloudGpsAllow;

  /// X3 dialog title.
  ///
  /// In en, this message translates to:
  /// **'Move without location?'**
  String get cloudGpsMoveTitle;

  /// X3 dialog before moving photos without the media location permission.
  ///
  /// In en, this message translates to:
  /// **'Location data may be removed from the cloud copy, and the original will be deleted.'**
  String get cloudGpsMoveWarning;

  /// X3 dialog button.
  ///
  /// In en, this message translates to:
  /// **'Move anyway'**
  String get cloudGpsMoveAnyway;

  /// X3 tab on the Transfers page.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get cloudTransfersSection;

  /// X3 Transfers tab, empty.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved to the cloud in the last 7 days'**
  String get cloudTransfersEmpty;

  /// X3 group in the Move/Copy folder picker.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get cloudPickerGroup;

  /// X3 snackbar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Saving 1 file to {name}…} other{Saving {count} files to {name}…}}'**
  String cloudStartedCopy(int count, String name);

  /// X3 snackbar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moving 1 file to {name}…} other{Moving {count} files to {name}…}}'**
  String cloudStartedMove(int count, String name);

  /// X3 snackbar: only camera or remote files were picked.
  ///
  /// In en, this message translates to:
  /// **'These files can\'t be saved to the cloud'**
  String get cloudNothingToSend;

  /// X3 snackbar at the end of a move job.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 original was kept} other{{count} originals were kept}}'**
  String cloudOriginalsKept(int count);

  /// X3 snackbar at the end of a move job.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moved 1 file} other{Moved {count} files}}'**
  String cloudOriginalsDeleted(int count);

  /// X3 button: delete the originals of verified moves.
  ///
  /// In en, this message translates to:
  /// **'Delete originals'**
  String get cloudDeleteOriginals;

  /// X3 move row whose original is still there.
  ///
  /// In en, this message translates to:
  /// **'Original not deleted'**
  String get cloudOriginalNotDeleted;

  /// X3 button.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get cloudRetry;

  /// L3 tutorial step 1 (the dummy card slides left).
  ///
  /// In en, this message translates to:
  /// **'Swipe left to throw away'**
  String get tutorialStepTrash;

  /// L3 tutorial step 2 (the dummy card slides right).
  ///
  /// In en, this message translates to:
  /// **'Swipe right to keep'**
  String get tutorialStepKeep;

  /// L3 tutorial step 3; a ring highlights the Undo button.
  ///
  /// In en, this message translates to:
  /// **'Made a mistake? Tap Undo'**
  String get tutorialStepUndo;

  /// L3: ends the tutorial at any step.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutorialSkip;

  /// L3: next tutorial step.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialNext;

  /// L3: last tutorial step.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tutorialDone;

  /// L3: screen-reader label of the tutorial's example card.
  ///
  /// In en, this message translates to:
  /// **'Example photo'**
  String get tutorialDemoCard;

  /// L3: Settings → Swiping row; also shows the one-time hints again.
  ///
  /// In en, this message translates to:
  /// **'Show tutorial again'**
  String get tutorialShowAgain;

  /// L3 one-time hint on the first open of Manage presets.
  ///
  /// In en, this message translates to:
  /// **'A preset saves your swipe setup and filter. Switch with one tap.'**
  String get hintPresets;

  /// L3 one-time hint the first time the action bar appears.
  ///
  /// In en, this message translates to:
  /// **'Extra actions live here. Turn them off in Settings → Swiping.'**
  String get hintActionBar;

  /// L3: tooltip of a one-time hint's close button.
  ///
  /// In en, this message translates to:
  /// **'Close hint'**
  String get hintDismiss;

  /// X4 tooltip / screen-reader label of the cloud icon on a file KFM uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded by KFM (last known, not a live check)'**
  String get cloudBadgeOnCloud;

  /// X4 tooltip / screen-reader label of the cloud icon when the file changed after its upload.
  ///
  /// In en, this message translates to:
  /// **'Changed since it was uploaded'**
  String get cloudBadgeChanged;

  /// X4 Settings → Cloud switch (also the X6 backup name of this setting).
  ///
  /// In en, this message translates to:
  /// **'Show cloud icon'**
  String get cloudShowBadge;

  /// X4 viewer info line, one per cloud folder the file was uploaded to.
  ///
  /// In en, this message translates to:
  /// **'Uploaded by KFM to {destination} · {date}'**
  String cloudInfoUploaded(String destination, String date);

  /// X4 viewer info line: the file changed after it was uploaded there.
  ///
  /// In en, this message translates to:
  /// **'Changed since upload to {destination}'**
  String cloudInfoChanged(String destination);

  /// X4: a cloud folder that was removed from KFM (in the viewer info line).
  ///
  /// In en, this message translates to:
  /// **'{destination} (removed)'**
  String cloudInfoRemoved(String destination);

  /// X4 filter sheet: heading of the cloud row (shown once KFM uploaded something).
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get cloudFilterRow;

  /// X4 filter sheet chip: no cloud filter.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get cloudFilterAny;

  /// X4 filter chip and search chip: files KFM uploaded and that haven't changed since.
  ///
  /// In en, this message translates to:
  /// **'On cloud'**
  String get cloudFilterOn;

  /// X4 filter chip and search chip: every other file.
  ///
  /// In en, this message translates to:
  /// **'Not on cloud'**
  String get cloudFilterNotOn;

  /// X4 Settings → Cloud row: opens swipe mode with the On cloud files.
  ///
  /// In en, this message translates to:
  /// **'Swipe files already on cloud'**
  String get cloudSwipeOnCloud;

  /// X4: title of the swipe source with the files already on cloud.
  ///
  /// In en, this message translates to:
  /// **'On cloud'**
  String get cloudSwipeOnCloudTitle;

  /// X6: reason inside backupUndoFailed when the open deck's queued deletes could not be committed (declined system trash dialog).
  ///
  /// In en, this message translates to:
  /// **'the trash dialog was declined, so nothing changed'**
  String get backupUndoBlocked;

  /// PL1: a file another program has open on Windows.
  ///
  /// In en, this message translates to:
  /// **'{name} is in use by another program'**
  String fileOpInUse(String name);

  /// PL1: trashing on a Windows drive without a Recycle Bin.
  ///
  /// In en, this message translates to:
  /// **'This drive has no Recycle Bin'**
  String get fileOpNoTrash;

  /// PL1: one question per delete batch on a Windows drive without a Recycle Bin. No keeps the files queued.
  ///
  /// In en, this message translates to:
  /// **'This drive has no Recycle Bin. Delete {count, plural, =1{this file} other{these {count} files}} permanently?'**
  String deleteNoRecycleBin(int count);

  /// PL1: explanation under the Windows index roots title.
  ///
  /// In en, this message translates to:
  /// **'KFM shows the photos, videos and files in these folders.'**
  String get windowsRootsHint;

  /// PL1: an index root folder that is gone or on an unplugged drive.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get windowsRootsNotAvailable;

  /// PL1: adds a folder to the Windows index roots.
  ///
  /// In en, this message translates to:
  /// **'Add folder'**
  String get windowsRootsAdd;

  /// PL1: confirm button of the add-folder dialog.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get windowsRootsAddConfirm;

  /// PL1: tooltip of the remove button of one index root.
  ///
  /// In en, this message translates to:
  /// **'Remove {folder}'**
  String windowsRootsRemove(String folder);

  /// PL1: back to Pictures, Videos, Downloads and Documents.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get windowsRootsReset;

  /// PL1: Windows tray menu entry that brings the window back.
  ///
  /// In en, this message translates to:
  /// **'Open KFM'**
  String get shareNotificationOpen;

  /// PL1: Windows tray menu entry: stop sharing and close KFM.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get shareNotificationQuit;

  /// PL1: share screen note on Windows (sharing continues in the tray).
  ///
  /// In en, this message translates to:
  /// **'Sharing keeps running when you close the window. Stop it here or from the tray icon.'**
  String get shareKeepsRunningTray;

  /// PL1: one-time dialog title before the window first hides to the tray.
  ///
  /// In en, this message translates to:
  /// **'KFM keeps sharing'**
  String get trayNoticeTitle;

  /// PL1: one-time dialog body before the window first hides to the tray.
  ///
  /// In en, this message translates to:
  /// **'KFM is still sharing this PC. Stop it from the tray icon.'**
  String get trayNoticeBody;

  /// PL1: Windows-only switch in Settings → Connect.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing when the window closes'**
  String get settingsStopSharingOnClose;

  /// PL1: subtitle of the stop-sharing-on-close switch.
  ///
  /// In en, this message translates to:
  /// **'Otherwise KFM keeps sharing from the tray icon.'**
  String get settingsStopSharingOnCloseHint;

  /// PL1: share screen title on Windows when the network profile is Public.
  ///
  /// In en, this message translates to:
  /// **'Your Wi-Fi is set to Public'**
  String get sharePublicNetwork;

  /// PL1: how to switch the Windows network profile to Private.
  ///
  /// In en, this message translates to:
  /// **'Set it to Private to share. Windows Settings → Network & internet → Wi-Fi → your network → Private network.'**
  String get sharePublicNetworkHint;

  /// PL1: explainer dialog title before the first share on Windows.
  ///
  /// In en, this message translates to:
  /// **'Windows will ask about the firewall'**
  String get shareFirewallTitle;

  /// PL1: firewall explainer dialog body (shown once).
  ///
  /// In en, this message translates to:
  /// **'So your phone can reach this PC, Windows Firewall asks to allow KFM. Allow it on private networks only.'**
  String get shareFirewallBody;

  /// PL3: desktop sidebar section for the swipe deck (sorting photos).
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get desktopNavSort;

  /// PL3: desktop sidebar section for Connect.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get desktopNavDevices;

  /// PL3: sidebar header above folders.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get desktopSidebarPlaces;

  /// PL3: sidebar header above favorites and tags.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get desktopSidebarCollections;

  /// PL3: sidebar entry for favorite files.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get desktopFavorites;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get desktopSidebarCollapse;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get desktopSidebarExpand;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'No folders yet'**
  String get desktopNoPlaces;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Select a file to see its details'**
  String get desktopDetailsNothing;

  /// PL3: a tooltip/hint with its keyboard shortcut, e.g. 'Undo (Ctrl+Z)'.
  ///
  /// In en, this message translates to:
  /// **'{label} ({keys})'**
  String desktopShortcutHint(String label, String keys);

  /// PL3: status bar item count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String desktopStatusItems(int count);

  /// PL3: status bar selection count and total size.
  ///
  /// In en, this message translates to:
  /// **'{count} selected · {size}'**
  String desktopStatusSelected(int count, String size);

  /// PL3: Sort toolbar button and panel title: the session's actions, newest first.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get desktopSortHistory;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Nothing sorted yet'**
  String get desktopSortHistoryEmpty;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Undo back to here'**
  String get desktopSortUndoToHere;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Undo {count} actions?'**
  String desktopSortUndoManyTitle(int count);

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'The newest {count} actions are undone one by one, back to the one you clicked.'**
  String desktopSortUndoManyBody(int count);

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Undo {count}'**
  String desktopSortUndoManyConfirm(int count);

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Select files, then choose what to do with them'**
  String get desktopSortSelectHint;

  /// PL3: feedback after an action on several files, e.g. '→ Trash · 3 files'.
  ///
  /// In en, this message translates to:
  /// **'{label} · {count, plural, =1{1 file} other{{count} files}}'**
  String desktopSortActed(String label, int count);

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Large icons'**
  String get desktopLayoutLargeIcons;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get desktopLayoutGrid;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get desktopLayoutDetails;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Quick look'**
  String get desktopQuickLook;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get desktopClose;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get desktopPrevious;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get desktopNext;

  /// PL3: Details Type column, e.g. 'JPG file'.
  ///
  /// In en, this message translates to:
  /// **'{ext} file'**
  String desktopTypeFile(String ext);

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get desktopTypeUnknown;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get desktopTypeFolder;

  /// PL3: Quick look header.
  ///
  /// In en, this message translates to:
  /// **'{name} · {size} · {date}'**
  String desktopQuickLookTitle(String name, String size, String date);

  /// PL3: Sort toolbar count of files still to sort.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String desktopSortLeft(int count);

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get desktopBrowseBack;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get desktopBrowseForward;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Up one level'**
  String get desktopBrowseUp;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get desktopBrowseOpen;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get desktopBrowseEmptyFolder;

  /// PL3: opens the folder's or selection's photos in Sort (SS1 'Swipe these').
  ///
  /// In en, this message translates to:
  /// **'Sort these'**
  String get desktopBrowseSortThese;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get desktopBrowseCopy;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get desktopBrowseCut;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get desktopBrowsePaste;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'KFM hasn\'t found files here yet'**
  String get desktopBrowseNothingIndexed;

  /// PL3: label next to the cursor while dragging files.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String desktopDragCount(int count);

  /// PL3: drop target hint while dragging (hold Ctrl to copy).
  ///
  /// In en, this message translates to:
  /// **'Move to {name}'**
  String desktopDropMoveTo(String name);

  /// PL3: drop target hint while dragging.
  ///
  /// In en, this message translates to:
  /// **'Copy to {name}'**
  String desktopDropCopyTo(String name);

  /// PL3: drop target hint over a tag in the sidebar.
  ///
  /// In en, this message translates to:
  /// **'Add tag {name}'**
  String desktopDropTag(String name);

  /// PL3: drop target hint over Favorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get desktopDropFavorite;

  /// PL3: drop target hint over Devices.
  ///
  /// In en, this message translates to:
  /// **'Send to a device'**
  String get desktopDropSend;

  /// PL3: drop target hint over Trash.
  ///
  /// In en, this message translates to:
  /// **'Move to Trash'**
  String get desktopDropTrash;

  /// PL3: second line of the drag hint.
  ///
  /// In en, this message translates to:
  /// **'Hold Ctrl to copy'**
  String get desktopDropCtrlHint;

  /// PL3: dropped items from Explorer could not be read.
  ///
  /// In en, this message translates to:
  /// **'Nothing to copy here'**
  String get desktopDropNothing;

  /// PL3: drag label, e.g. '3 files · Move to Pictures'.
  ///
  /// In en, this message translates to:
  /// **'{files} · {action}'**
  String desktopDragOffer(String files, String action);

  /// PL3: Trash filter chip with the item count.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String desktopTrashAll(int count);

  /// PL3: Trash filter chip, e.g. 'Recycle Bin · 3 items · 2 MB'.
  ///
  /// In en, this message translates to:
  /// **'{name} · {summary}'**
  String desktopTrashGroup(String name, String summary);

  /// PL3: the Windows Recycle Bin (use Windows' own name).
  ///
  /// In en, this message translates to:
  /// **'Recycle Bin'**
  String get desktopTrashRecycleBin;

  /// PL3: Trash column (as in the Windows Recycle Bin).
  ///
  /// In en, this message translates to:
  /// **'Original location'**
  String get desktopTrashOriginalLocation;

  /// PL3: Trash column.
  ///
  /// In en, this message translates to:
  /// **'Date deleted'**
  String get desktopTrashDeleted;

  /// PL3: Trash column with '7 days left' values.
  ///
  /// In en, this message translates to:
  /// **'Kept for'**
  String get desktopTrashDaysLeft;

  /// PL3: Trash column: Recycle Bin or Pending delete.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get desktopTrashWhere;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get desktopRefresh;

  /// PL3: Devices section heading.
  ///
  /// In en, this message translates to:
  /// **'Connect a phone or another PC'**
  String get desktopDevicesTitle;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Both devices need KFM and the same Wi-Fi. Nothing is shared until you choose below.'**
  String get desktopDevicesHint;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Show a QR code and a code for your phone'**
  String get desktopDevicesShareHint;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Connect to a device that shows a code'**
  String get desktopDevicesConnectHint;

  /// PL3: opens a similar group side by side.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get desktopCompare;

  /// PL3: Compare view title.
  ///
  /// In en, this message translates to:
  /// **'Compare {count, plural, =1{1 photo} other{{count} photos}}'**
  String desktopCompareTitle(int count);

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Number keys switch Keep / Remove · zoom and pan move all photos together'**
  String get desktopCompareHint;

  /// PL3: Compare: removes the photos marked Remove (C2 rules, undoable).
  ///
  /// In en, this message translates to:
  /// **'Remove {count}'**
  String desktopCompareRemove(int count);

  /// PL3: Compare panel state.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get desktopCompareKeep;

  /// PL3: Compare panel state.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get desktopCompareRemoveOne;

  /// PL3: Compare panel subtitle.
  ///
  /// In en, this message translates to:
  /// **'{size} · {resolution} · {date}'**
  String desktopCompareFacts(String size, String resolution, String date);

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get desktopZoomIn;

  /// PL3 desktop UI.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get desktopZoomOut;

  /// PL3: reset zoom.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get desktopZoomFit;

  /// PL3: Sort toolbar button (key F): adds the selection to Favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get desktopSortFavorite;

  /// PL3: Sort toolbar button (key T): pick a tag for the selection.
  ///
  /// In en, this message translates to:
  /// **'Tag…'**
  String get desktopSortTag;

  /// X6 import preview: the desktop Browse layout setting.
  ///
  /// In en, this message translates to:
  /// **'PC Browse view'**
  String get backupSettingDesktopBrowseLayout;

  /// X6 import preview: the desktop Browse sort setting.
  ///
  /// In en, this message translates to:
  /// **'PC Browse sort'**
  String get backupSettingDesktopBrowseSort;

  /// PL1: Windows refused to eject a drive because a file is open.
  ///
  /// In en, this message translates to:
  /// **'{label} is still in use by another program. Close it and try again.'**
  String ejectWindowsInUse(String label);

  /// PL1: ejecting a drive failed for another reason.
  ///
  /// In en, this message translates to:
  /// **'Windows couldn\'t eject {label}'**
  String ejectWindowsFailed(String label);

  /// PL1: the Windows system drive in the sidebar, e.g. 'Local disk (C:)'.
  ///
  /// In en, this message translates to:
  /// **'Local disk ({drive})'**
  String desktopSystemDrive(String drive);

  /// PL1: a USB drive without a volume label, e.g. 'USB drive (E:)'.
  ///
  /// In en, this message translates to:
  /// **'USB drive ({drive})'**
  String driveUsbUnnamed(String drive);

  /// PL1: an SD card (card reader) without a volume label, e.g. 'SD card (E:)'.
  ///
  /// In en, this message translates to:
  /// **'SD card ({drive})'**
  String driveSdUnnamed(String drive);

  /// PL1: another removable drive without a volume label, e.g. 'Removable disk (E:)'.
  ///
  /// In en, this message translates to:
  /// **'Removable disk ({drive})'**
  String driveRemovableUnnamed(String drive);

  /// PL1: a mapped network drive, e.g. 'Network drive (Z:)'.
  ///
  /// In en, this message translates to:
  /// **'Network drive ({drive})'**
  String driveNetworkUnnamed(String drive);

  /// PL3: desktop Sort presets dropdown button; name = the active preset (or Basic).
  ///
  /// In en, this message translates to:
  /// **'Preset: {name}'**
  String desktopSortPreset(String name);

  /// PL3: last entry of the desktop Sort presets dropdown.
  ///
  /// In en, this message translates to:
  /// **'Manage presets…'**
  String get desktopSortManagePresets;

  /// PL3: desktop Sort button that opens the directions/filter/extras setup as a dialog.
  ///
  /// In en, this message translates to:
  /// **'Sort setup…'**
  String get desktopSortSetup;

  /// PL3 Quick look video bar: play button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get videoPlay;

  /// PL3 Quick look video bar: pause button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get videoPause;

  /// PL3 Quick look video bar: sound button tooltip while muted.
  ///
  /// In en, this message translates to:
  /// **'Turn sound on'**
  String get videoSoundOn;

  /// PL3 Quick look video bar: sound button tooltip while sound is on.
  ///
  /// In en, this message translates to:
  /// **'Turn sound off'**
  String get videoSoundOff;

  /// PL3: drag label when folders are dragged (files and folders together).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String desktopDragItems(int count);

  /// PL3: snackbar after moving folders (with their files) by drag & drop or Ctrl+X/V.
  ///
  /// In en, this message translates to:
  /// **'{folders, plural, =0{Moved} =1{Moved 1 folder} other{Moved {folders} folders}} ({files, plural, =1{1 file} other{{files} files}})'**
  String opTreeMoved(int folders, int files);

  /// PL3: snackbar after copying folders (with their files).
  ///
  /// In en, this message translates to:
  /// **'{folders, plural, =0{Copied} =1{Copied 1 folder} other{Copied {folders} folders}} ({files, plural, =1{1 file} other{{files} files}})'**
  String opTreeCopied(int folders, int files);

  /// PL3: a folder was dropped or pasted into itself or one of its subfolders.
  ///
  /// In en, this message translates to:
  /// **'A folder can\'t go into itself'**
  String get opFolderIntoItself;

  /// X8: Android notification channel name of the ongoing progress notification.
  ///
  /// In en, this message translates to:
  /// **'Transfers in progress'**
  String get jobsChannelProgress;

  /// X8: Android notification channel description (progress).
  ///
  /// In en, this message translates to:
  /// **'Progress of copies and transfers while KFM is in the background'**
  String get jobsChannelProgressDescription;

  /// X8: Android notification channel name of the end notifications.
  ///
  /// In en, this message translates to:
  /// **'Finished transfers'**
  String get jobsChannelResults;

  /// X8: Android notification channel description (results).
  ///
  /// In en, this message translates to:
  /// **'Shows when a copy or transfer ends'**
  String get jobsChannelResultsDescription;

  /// X8: notification title while another device uploads into this one.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Receiving 1 file from {device}} other{Receiving {count} files from {device}}}'**
  String jobsReceivingFrom(int count, String device);

  /// X8: notification title when several jobs run; percent is preformatted (38%).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transfer · {percent}} other{{count} transfers · {percent}}}'**
  String jobsCombinedTitle(int count, String percent);

  /// X8: notification text: bytes done of total.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String jobsProgressLine(String done, String total);

  /// X8: notification text: speed.
  ///
  /// In en, this message translates to:
  /// **'{speed}/s'**
  String jobsSpeedLine(String speed);

  /// X8: notification text: time left (preformatted duration).
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String jobsTimeLeft(String time);

  /// X8: time left in minutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min} other{{count} min}}'**
  String jobsMinutes(int count);

  /// X8: time left in hours and minutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String jobsHoursMinutes(int hours, int minutes);

  /// X8: time left under a minute.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 s} other{{count} s}}'**
  String jobsSeconds(int count);

  /// X8: notification title of one paused job.
  ///
  /// In en, this message translates to:
  /// **'Paused · {title}'**
  String jobsPausedOne(String title);

  /// X8: notification title of several paused jobs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transfer paused} other{{count} transfers paused}}'**
  String jobsPausedMany(int count);

  /// X8: Android 15 time limit reached: jobs paused until KFM is opened.
  ///
  /// In en, this message translates to:
  /// **'Paused, open KFM to continue'**
  String get jobsPausedOpenKfm;

  /// X8: notification text while a job waits (no bytes yet).
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get jobsWaiting;

  /// X8: end notification of a send.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Sent 1 file to {device}} other{Sent {count} files to {device}}}'**
  String jobsEndSent(int count, String device);

  /// X8: end notification of a download or incoming upload.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Received 1 file from {device}} other{Received {count} files from {device}}}'**
  String jobsEndReceived(int count, String device);

  /// X8: end notification of a move to a device or place.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moved 1 file to {device}} other{Moved {count} files to {device}}}'**
  String jobsEndMovedTo(int count, String device);

  /// X8: end notification of a move from a device.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moved 1 file from {device}} other{Moved {count} files from {device}}}'**
  String jobsEndMovedFrom(int count, String device);

  /// X8: end notification of a local copy.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copied 1 file to {place}} other{Copied {count} files to {place}}}'**
  String jobsEndCopied(int count, String place);

  /// X8: end notification when several jobs ended together.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transfer finished} other{{count} transfers finished}}'**
  String jobsEndMany(int count);

  /// X8: end notification text when files failed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file failed · Tap to see} other{{count} files failed · Tap to see}}'**
  String jobsEndFailed(int count);

  /// X8: Transfers screen hint on Android when notifications are denied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off: transfers keep running, but their progress only shows inside KFM.'**
  String get jobsNotificationsOff;

  /// X8: screen reader label of the in-app progress indicator.
  ///
  /// In en, this message translates to:
  /// **'{title}, {percent}. Open transfers'**
  String jobsIndicatorLabel(String title, String percent);

  /// X8: Windows dialog before quitting while jobs run.
  ///
  /// In en, this message translates to:
  /// **'Quit KFM?'**
  String get jobsQuitTitle;

  /// X8: Windows quit dialog body.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transfer is still running. Quitting stops it; you can continue it in Transfers next time.} other{{count} transfers are still running. Quitting stops them; you can continue them in Transfers next time.}}'**
  String jobsQuitBody(int count);

  /// X8: Windows quit dialog confirm button.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get jobsQuitAction;

  /// X8: Windows quit dialog: don't quit.
  ///
  /// In en, this message translates to:
  /// **'Keep running'**
  String get jobsQuitKeep;

  /// X8: one-time dialog title before the window hides to the tray while jobs run.
  ///
  /// In en, this message translates to:
  /// **'KFM keeps transferring'**
  String get trayNoticeTransfersTitle;

  /// X8: one-time dialog body before the window hides to the tray while jobs run.
  ///
  /// In en, this message translates to:
  /// **'Transfers continue in the background. Open KFM again from the tray icon.'**
  String get trayNoticeTransfersBody;

  /// X8: end notification title when every file failed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Transfer failed} other{{count} transfers failed}}'**
  String jobsEndFailedTitle(int count);

  /// E3: desktop settings row and dialog: which icons files and folders show.
  ///
  /// In en, this message translates to:
  /// **'File icons'**
  String get desktopFileIcons;

  /// E3: file icon style option: Windows' own shell icons.
  ///
  /// In en, this message translates to:
  /// **'Windows'**
  String get desktopFileIconsWindows;

  /// E3: file icon style option: KFM's own icons.
  ///
  /// In en, this message translates to:
  /// **'KFM'**
  String get desktopFileIconsKfm;

  /// E3: first-run desktop dialog title.
  ///
  /// In en, this message translates to:
  /// **'Which file icons?'**
  String get desktopIconChoiceTitle;

  /// E3: first-run desktop dialog body.
  ///
  /// In en, this message translates to:
  /// **'Pick how files and folders look. You can change this later in Settings.'**
  String get desktopIconChoiceBody;

  /// E3: first-run dialog: what the Windows option means.
  ///
  /// In en, this message translates to:
  /// **'The same icons as File Explorer'**
  String get desktopIconChoiceWindowsHint;

  /// E3: first-run dialog: what the KFM option means.
  ///
  /// In en, this message translates to:
  /// **'KFM\'s own simple icons'**
  String get desktopIconChoiceKfmHint;

  /// E3: first-run icon dialog: confirm button.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get desktopIconChoiceDone;

  /// E3: backup import preview label for the desktop file icon style.
  ///
  /// In en, this message translates to:
  /// **'File icons (desktop)'**
  String get backupSettingFileIcons;

  /// E3: desktop Home location (Quick access + drives), tab title and nav pane row.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get desktopHome;

  /// E3: title of a desktop tab showing search results.
  ///
  /// In en, this message translates to:
  /// **'Search: {query}'**
  String desktopTabSearch(String query);

  /// E3: desktop tab strip: open a new tab.
  ///
  /// In en, this message translates to:
  /// **'New tab'**
  String get desktopTabNew;

  /// E3: desktop tab menu.
  ///
  /// In en, this message translates to:
  /// **'Duplicate tab'**
  String get desktopTabDuplicate;

  /// E3: desktop tab menu / close button.
  ///
  /// In en, this message translates to:
  /// **'Close tab'**
  String get desktopTabClose;

  /// E3: desktop tab menu.
  ///
  /// In en, this message translates to:
  /// **'Close other tabs'**
  String get desktopTabCloseOthers;

  /// E3: desktop tab menu.
  ///
  /// In en, this message translates to:
  /// **'Close tabs to the right'**
  String get desktopTabCloseRight;

  /// E3: desktop tab menu (Ctrl+Shift+T).
  ///
  /// In en, this message translates to:
  /// **'Reopen closed tab'**
  String get desktopTabReopen;

  /// E3: desktop address bar: the typed path doesn't exist.
  ///
  /// In en, this message translates to:
  /// **'KFM can\'t find \'{path}\'. Check the spelling and try again.'**
  String desktopAddressNotFound(String path);

  /// E3: screen reader label of the desktop address bar (click to type a path).
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get desktopAddressLabel;

  /// E3: desktop search box hint inside a folder.
  ///
  /// In en, this message translates to:
  /// **'Search {name}'**
  String desktopSearchIn(String name);

  /// E3: desktop search results: nothing found.
  ///
  /// In en, this message translates to:
  /// **'No files match \'{query}\'.'**
  String desktopSearchNone(String query);

  /// E3: Details column with the folder a file is in (search results, Sort).
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get desktopColumnFolder;

  /// E3: nav pane group / Home section of pinned folders.
  ///
  /// In en, this message translates to:
  /// **'Quick access'**
  String get desktopQuickAccess;

  /// E3: folder menu / drop on the Quick access header.
  ///
  /// In en, this message translates to:
  /// **'Pin to Quick access'**
  String get desktopPinToQuickAccess;

  /// E3: Quick access pin menu.
  ///
  /// In en, this message translates to:
  /// **'Unpin from Quick access'**
  String get desktopUnpinFromQuickAccess;

  /// E3: nav pane group with the drives / Home section.
  ///
  /// In en, this message translates to:
  /// **'This PC'**
  String get desktopThisPc;

  /// E3: nav pane Devices group: opens Devices.
  ///
  /// In en, this message translates to:
  /// **'Connect a device'**
  String get desktopConnectDevice;

  /// E3: folder menu entry (middle-click does the same).
  ///
  /// In en, this message translates to:
  /// **'Open in new tab'**
  String get desktopOpenInNewTab;

  /// E3: command bar: New menu.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get desktopCmdNew;

  /// E3: command bar: View menu.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get desktopCmdView;

  /// E3: command bar: sort order menu (name, date, size).
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get desktopCmdSortBy;

  /// E3: View menu toggle.
  ///
  /// In en, this message translates to:
  /// **'Navigation pane'**
  String get desktopViewNavPane;

  /// E3: View menu toggle.
  ///
  /// In en, this message translates to:
  /// **'Hidden items'**
  String get desktopViewHidden;

  /// E3: View menu toggle (Alt+P).
  ///
  /// In en, this message translates to:
  /// **'Preview pane'**
  String get desktopViewPreviewPane;

  /// E3: View menu toggle (Alt+Shift+P).
  ///
  /// In en, this message translates to:
  /// **'Details pane'**
  String get desktopViewDetailsPane;

  /// E3: Sort menu direction.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get desktopSortAscending;

  /// E3: Sort menu direction.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get desktopSortDescending;

  /// E3: file menu / command: copies the full path.
  ///
  /// In en, this message translates to:
  /// **'Copy as path'**
  String get desktopCopyAsPath;

  /// E3: status bar after Copy as path.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Path copied} other{{count} paths copied}}'**
  String desktopPathCopied(int count);

  /// E3: opens the file's folder in a new tab with the file selected.
  ///
  /// In en, this message translates to:
  /// **'Open file location'**
  String get desktopOpenFileLocation;

  /// E3: opens File Explorer with the file selected.
  ///
  /// In en, this message translates to:
  /// **'Show in Windows Explorer'**
  String get desktopShowInExplorer;

  /// E3: file menu (Alt+Enter).
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get desktopProperties;

  /// E3: file menu: KFM's own viewer (double-click opens the Windows app).
  ///
  /// In en, this message translates to:
  /// **'Open in KFM viewer'**
  String get desktopOpenInKfm;

  /// E3: status bar in Sort: files still to sort.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String desktopStatusLeft(int count);

  /// E3: status bar drive space.
  ///
  /// In en, this message translates to:
  /// **'{drive} {free} free of {total}'**
  String desktopStatusDriveFree(String drive, String free, String total);

  /// E3: a tab's folder was deleted or its drive ejected.
  ///
  /// In en, this message translates to:
  /// **'This folder no longer exists.'**
  String get desktopFolderGone;

  /// E3: trash Properties row.
  ///
  /// In en, this message translates to:
  /// **'Original location'**
  String get trashPropsOriginalLocation;

  /// E3: trash Properties row (date and time).
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get trashPropsDeleted;

  /// E3: trash Properties: a KFM pending delete.
  ///
  /// In en, this message translates to:
  /// **'Waiting, not in the Recycle Bin yet'**
  String get trashPropsWaiting;

  /// E3: trash Properties title for several items.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}} · {size}'**
  String trashPropsSummary(int count, String size);

  /// E3: desktop Trash command.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get trashEmpty;

  /// E3: Empty trash confirm title.
  ///
  /// In en, this message translates to:
  /// **'Delete {count, plural, =1{1 item} other{{count} items}} forever?'**
  String trashEmptyTitle(int count);

  /// E3: Empty trash confirm body.
  ///
  /// In en, this message translates to:
  /// **'{size} will be deleted, including files still waiting in KFM. This can\'t be undone.'**
  String trashEmptyBody(String size);

  /// E2 settings section title.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// E2 desktop title of the Swiping section (desktop sorts without swiping).
  ///
  /// In en, this message translates to:
  /// **'Sorting'**
  String get settingsSorting;

  /// E2 settings section title.
  ///
  /// In en, this message translates to:
  /// **'Files & display'**
  String get settingsFilesDisplay;

  /// E2 settings section title.
  ///
  /// In en, this message translates to:
  /// **'Smart features'**
  String get settingsSmart;

  /// E2 settings section title.
  ///
  /// In en, this message translates to:
  /// **'Storage & cleanup'**
  String get settingsStorageCleanup;

  /// E2 settings section title.
  ///
  /// In en, this message translates to:
  /// **'Connect & sharing'**
  String get settingsConnectSharing;

  /// E2 settings section title.
  ///
  /// In en, this message translates to:
  /// **'Privacy & access'**
  String get settingsPrivacyAccess;

  /// E2 settings section title.
  ///
  /// In en, this message translates to:
  /// **'About & advanced'**
  String get settingsAboutAdvanced;

  /// E2: description under Thumbnail cache.
  ///
  /// In en, this message translates to:
  /// **'Small previews KFM saves so folders open fast. Clear frees the space; your files aren\'t touched and the previews come back when needed.'**
  String get thumbCacheHelp;

  /// E2: description of the error log entry (search).
  ///
  /// In en, this message translates to:
  /// **'Errors KFM ran into, without file names or paths. Share it to report a problem.'**
  String get errorLogHelp;

  /// E2: description of the Developer entry.
  ///
  /// In en, this message translates to:
  /// **'Index tools for checking KFM on a device (debug builds only).'**
  String get devSettingsHelp;

  /// E2: description under Show summary after Done.
  ///
  /// In en, this message translates to:
  /// **'After Done, a short overview of what you kept, deleted and moved.'**
  String get settingsShowSessionSummaryHelp;

  /// E2: description under Reset reviewed labels.
  ///
  /// In en, this message translates to:
  /// **'Files you already sorted show up as new again. Nothing is deleted.'**
  String get reviewedResetHelp;

  /// E2: description under Clear / fresh start.
  ///
  /// In en, this message translates to:
  /// **'Choose what to clear: the current session, history, tags or everything.'**
  String get settingsFreshStartHelp;

  /// E2: description under Show tutorial again.
  ///
  /// In en, this message translates to:
  /// **'The short swipe tutorial and the one-time tips once more.'**
  String get tutorialShowAgainHelp;

  /// E2: description under Dropping files on a folder.
  ///
  /// In en, this message translates to:
  /// **'What happens when you drag files onto a folder.'**
  String get settingsDropActionHelp;

  /// E2: description under Big files start at.
  ///
  /// In en, this message translates to:
  /// **'Used by the big-file highlight and Storage → Big files.'**
  String get storageBigFileThresholdHelp;

  /// E2: title of the delete mode entry (search result).
  ///
  /// In en, this message translates to:
  /// **'When you delete'**
  String get settingsDeleteMode;

  /// E2: description of the delete mode entry.
  ///
  /// In en, this message translates to:
  /// **'Move deleted files to the trash, or delete them for good.'**
  String get settingsDeleteModeHelp;

  /// E2: description of the Android permissions entry (phone only).
  ///
  /// In en, this message translates to:
  /// **'What KFM may read on this phone, and a button to change it.'**
  String get settingsPermissionsHelp;

  /// E2: title of the backup entry in About & advanced.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupRestoreTitle;

  /// E2: description of Backup & restore.
  ///
  /// In en, this message translates to:
  /// **'Moves your tags, favorites, presets and settings to another device. Files are not copied.'**
  String get backupRestoreHelp;

  /// E2: description of the cloud destinations entry (search).
  ///
  /// In en, this message translates to:
  /// **'Cloud apps on this device that KFM can send files to.'**
  String get cloudDestinationsHelp;

  /// E2: one Settings row for sharing and connecting (E1 adjusts the target).
  ///
  /// In en, this message translates to:
  /// **'Connect a device'**
  String get connectADevice;

  /// E2: description under Connect a device (mentions both device kinds on purpose).
  ///
  /// In en, this message translates to:
  /// **'See and send files between your phone and PC over Wi-Fi.'**
  String get connectADeviceHelp;

  /// E2: description of the Transfers entry (search).
  ///
  /// In en, this message translates to:
  /// **'Every Wi-Fi transfer, running and finished.'**
  String get transfersSettingHelp;

  /// E2: Privacy & access row opening the remembered devices.
  ///
  /// In en, this message translates to:
  /// **'Devices that can see your files'**
  String get privacyDevicesTitle;

  /// E2: description under Devices that can see your files.
  ///
  /// In en, this message translates to:
  /// **'Remembered devices and what they may do. Forget one to block it.'**
  String get privacyDevicesHelp;

  /// E2: privacy note title.
  ///
  /// In en, this message translates to:
  /// **'What KFM never does'**
  String get privacyNeverTitle;

  /// E2: privacy note body.
  ///
  /// In en, this message translates to:
  /// **'No ads, no account, no tracking. KFM never uploads your files: only devices you connect and cloud apps you choose get them.'**
  String get privacyNeverBody;

  /// E2: Accessibility note title (TalkBack / Narrator).
  ///
  /// In en, this message translates to:
  /// **'Screen readers'**
  String get a11yScreenReaderTitle;

  /// E2: Accessibility note body.
  ///
  /// In en, this message translates to:
  /// **'File tiles read their name, type, size and date. Swipe cards offer their actions in the actions menu.'**
  String get a11yScreenReaderBody;

  /// E2 settings search words for Theme (comma-separated, not shown).
  ///
  /// In en, this message translates to:
  /// **'dark,light,night,mode,appearance'**
  String get settingsKeywordsTheme;

  /// E2 settings search words for the color theme.
  ///
  /// In en, this message translates to:
  /// **'colour,color,accent'**
  String get settingsKeywordsAccent;

  /// E2 settings search words for Text size.
  ///
  /// In en, this message translates to:
  /// **'font,big text,zoom,larger'**
  String get settingsKeywordsTextSize;

  /// E2 settings search words for the thumbnail cache.
  ///
  /// In en, this message translates to:
  /// **'cache,previews,space,free up'**
  String get settingsKeywordsThumbCache;

  /// E2 settings search words for the version row.
  ///
  /// In en, this message translates to:
  /// **'version,about,app'**
  String get settingsKeywordsVersion;

  /// E2 settings search words for App permissions.
  ///
  /// In en, this message translates to:
  /// **'permission,access,allow,storage'**
  String get settingsKeywordsPermissions;

  /// E2 settings search words for Similar photos.
  ///
  /// In en, this message translates to:
  /// **'duplicates,blurry,similar'**
  String get settingsKeywordsSimilar;

  /// E2 settings search words for Photo labels (AI).
  ///
  /// In en, this message translates to:
  /// **'ai,labels,recognition,models,download'**
  String get settingsKeywordsAiLabels;

  /// E2 settings search words for location privacy.
  ///
  /// In en, this message translates to:
  /// **'location,gps,place,exif'**
  String get settingsKeywordsLocation;

  /// E2 settings search words for Backup & restore.
  ///
  /// In en, this message translates to:
  /// **'export,import,restore,backup'**
  String get settingsKeywordsBackup;

  /// E2 settings search words for the cloud rows.
  ///
  /// In en, this message translates to:
  /// **'cloud,drive,onedrive,upload'**
  String get settingsKeywordsCloud;

  /// E2 settings search words for Connect a device.
  ///
  /// In en, this message translates to:
  /// **'share,wifi,pc,phone,qr,send'**
  String get settingsKeywordsConnect;

  /// E2 settings search words for the privacy note.
  ///
  /// In en, this message translates to:
  /// **'privacy,tracking,ads,upload'**
  String get settingsKeywordsPrivacy;

  /// E2 settings search words for the screen reader note.
  ///
  /// In en, this message translates to:
  /// **'talkback,narrator,blind,screen reader'**
  String get settingsKeywordsScreenReader;

  /// E2 settings search words for Big files start at.
  ///
  /// In en, this message translates to:
  /// **'big,large,size,threshold'**
  String get settingsKeywordsBigFiles;

  /// E2: settings search field hint / button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get settingsSearchHint;

  /// E2: clears the settings search.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get settingsSearchClear;

  /// E2: settings search without results.
  ///
  /// In en, this message translates to:
  /// **'No setting matches. Try another word.'**
  String get settingsSearchEmpty;

  /// X2 note in the send-to-device folder picker while Remove location is on (E2: new section name).
  ///
  /// In en, this message translates to:
  /// **'Location info is removed (Settings → Privacy & access)'**
  String get privacyTransferNote;

  /// E2: short duration, seconds only ("45 s").
  ///
  /// In en, this message translates to:
  /// **'{count} s'**
  String durationShortSeconds(int count);

  /// E2: short duration, whole minutes ("2 min").
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String durationShortMinutes(int count);

  /// E2: short duration, minutes and seconds ("1 min 30 s").
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {seconds} s'**
  String durationShortMinutesSeconds(int minutes, int seconds);

  /// E2: short duration, whole hours ("1 h").
  ///
  /// In en, this message translates to:
  /// **'{count} h'**
  String durationShortHours(int count);

  /// E2: short duration, hours and minutes ("1 h 30 min").
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationShortHoursMinutes(int hours, int minutes);

  /// E2: unit picker label for seconds.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get unitSecondsShort;

  /// E2: unit picker label for minutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get unitMinutesShort;

  /// E2: unit picker label for hours.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get unitHoursShort;

  /// E2: unit picker label for megabytes.
  ///
  /// In en, this message translates to:
  /// **'MB'**
  String get unitMegabytesShort;

  /// E2: unit picker label for gigabytes.
  ///
  /// In en, this message translates to:
  /// **'GB'**
  String get unitGigabytesShort;

  /// E2: label of the number field in the value sheet.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get unitInputAmount;

  /// E2: error under the number field.
  ///
  /// In en, this message translates to:
  /// **'Enter a value from {min} to {max}'**
  String unitInputRange(String min, String max);

  /// E2: saves the typed value.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get unitInputSave;

  /// E2: row text under Big files start at, with the current value.
  ///
  /// In en, this message translates to:
  /// **'Files of {size} or more count as big'**
  String bigFileThresholdLine(String size);

  /// E2: Highlight big files description (the size is set in Big files start at).
  ///
  /// In en, this message translates to:
  /// **'Big files get a red size label, even with sizes off'**
  String get settingsHighlightBigLine;

  /// E2: Same time window description (search).
  ///
  /// In en, this message translates to:
  /// **'Browse → Same time groups photos and videos taken this close together'**
  String get settingsSameTimeWindowAbout;

  /// E2: row text under Same time window, with the current value ("2 min").
  ///
  /// In en, this message translates to:
  /// **'Photos and videos taken within {time} of each other are grouped'**
  String sameTimeWindowLine(String time);

  /// D1/E2: trash delete mode help (no device noun).
  ///
  /// In en, this message translates to:
  /// **'Deleted files go to the trash and can be restored.'**
  String get deleteModeTrashHelpDevice;

  /// C2/E2: Similar photos start screen body. device: phone | pc | other (TASK-E2 deviceKind).
  ///
  /// In en, this message translates to:
  /// **'{device, select, phone{KFM checks your photos on this phone, groups look-alikes and suggests the sharpest one to keep. Nothing leaves the phone and nothing is removed unless you choose it.} pc{KFM checks your photos on this PC, groups look-alikes and suggests the sharpest one to keep. Nothing leaves the PC and nothing is removed unless you choose it.} other{KFM checks your photos on this device, groups look-alikes and suggests the sharpest one to keep. Nothing leaves the device and nothing is removed unless you choose it.}}'**
  String similarStartBodyOn(String device);

  /// C3/E2: AI labels switch. device: phone | pc | other (TASK-E2 deviceKind).
  ///
  /// In en, this message translates to:
  /// **'{device, select, phone{Label photos on this phone} pc{Label photos on this PC} other{Label photos on this device}}'**
  String aiLabelsEnableOn(String device);

  /// C3/E2: AI labels privacy line in Settings. device: phone | pc | other (TASK-E2 deviceKind).
  ///
  /// In en, this message translates to:
  /// **'{device, select, phone{Runs on this phone only. No photo or result ever leaves it.} pc{Runs on this PC only. No photo or result ever leaves it.} other{Runs on this device only. No photo or result ever leaves it.}}'**
  String aiLabelsHelpOn(String device);

  /// C3/E2: labeling worker failed. device: phone | pc | other (TASK-E2 deviceKind).
  ///
  /// In en, this message translates to:
  /// **'{device, select, phone{Labeling couldn\'t start on this phone.} pc{Labeling couldn\'t start on this PC.} other{Labeling couldn\'t start on this device.}}'**
  String aiLabelsWorkerErrorOn(String device);

  /// C3/E2: Browse/Search card body. device: phone | pc | other (TASK-E2 deviceKind).
  ///
  /// In en, this message translates to:
  /// **'{device, select, phone{KFM can label your photos on this phone. Nothing is uploaded.} pc{KFM can label your photos on this PC. Nothing is uploaded.} other{KFM can label your photos on this device. Nothing is uploaded.}}'**
  String aiLabelsCardBodyOn(String device);

  /// C3/E2: AI models screen, how it works. device: phone | pc | other (TASK-E2 deviceKind).
  ///
  /// In en, this message translates to:
  /// **'{device, select, phone{Each photo\'s small thumbnail is analysed on this phone, once, in the background. Only label words like \"cat\" are stored in KFM\'s database.} pc{Each photo\'s small thumbnail is analysed on this PC, once, in the background. Only label words like \"cat\" are stored in KFM\'s database.} other{Each photo\'s small thumbnail is analysed on this device, once, in the background. Only label words like \"cat\" are stored in KFM\'s database.}}'**
  String aiModelsHowBodyOn(String device);

  /// C3/E2: AI models screen, privacy. device: phone | pc | other (TASK-E2 deviceKind).
  ///
  /// In en, this message translates to:
  /// **'{device, select, phone{Runs fully on this phone. No photo, thumbnail or result ever leaves it. No account, no tracking. The only network use is this one download.} pc{Runs fully on this PC. No photo, thumbnail or result ever leaves it. No account, no tracking. The only network use is this one download.} other{Runs fully on this device. No photo, thumbnail or result ever leaves it. No account, no tracking. The only network use is this one download.}}'**
  String aiModelsPrivacyBodyOn(String device);

  /// B10/E2: file details fact label. device: phone | pc | other (TASK-E2 deviceKind).
  ///
  /// In en, this message translates to:
  /// **'{device, select, phone{Added to phone} pc{Added to PC} other{Added to device}}'**
  String detailsAddedOn(String device);

  /// H5/E2: error log row subtitle. Tag and preset names may still appear. device: phone | pc | other (TASK-E2 deviceKind).
  ///
  /// In en, this message translates to:
  /// **'{device, select, phone{{count, plural, =1{1 error} other{{count} errors}}. Stays on this phone until you share it. Folder and file names are hidden.} pc{{count, plural, =1{1 error} other{{count} errors}}. Stays on this PC until you share it. Folder and file names are hidden.} other{{count, plural, =1{1 error} other{{count} errors}}. Stays on this device until you share it. Folder and file names are hidden.}}'**
  String errorLogShareSubtitleOn(int count, String device);

  /// U2/E2: Transfers section of local jobs. device: phone | pc | other (TASK-E2 deviceKind).
  ///
  /// In en, this message translates to:
  /// **'{device, select, phone{On this phone} pc{On this PC} other{On this device}}'**
  String transfersLocalSectionOn(String device);

  /// X4/E2: help text under the Show cloud icon switch (no device noun).
  ///
  /// In en, this message translates to:
  /// **'The cloud icon means KFM handed this file to your cloud app. KFM remembers that here, so it shows offline too. It isn\'t a live check: KFM can\'t see whether the upload finished or whether the copy was deleted later. If the file changes after upload, the icon changes too. Only files uploaded with KFM are marked.'**
  String get cloudBadgeHelpDevice;

  /// E2: Photo labels row on Windows (never hidden).
  ///
  /// In en, this message translates to:
  /// **'Not available on Windows yet. On Android, KFM can find photos by what\'s in them.'**
  String get aiLabelsUnsupportedWindows;

  /// E2: inline button in Settings → Smart features → Photo labels; the size is in the row text.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get aiModelsDownloadInline;

  /// E2: Photo labels row link to the models details screen.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get aiModelsHowItWorks;

  /// E2: Privacy & access entry about the file index.
  ///
  /// In en, this message translates to:
  /// **'Where KFM looks'**
  String get whereKfmLooksTitle;

  /// E2: description of Where KFM looks (search).
  ///
  /// In en, this message translates to:
  /// **'The private list of your files that Search, Sort and Storage use. It never leaves this device.'**
  String get whereKfmLooksHelp;

  /// E2: phone explanation of the index (read-only row).
  ///
  /// In en, this message translates to:
  /// **'KFM keeps a private list of the photos, videos and files Android shows it, so Search, Swipe and Storage cover your whole phone. The list stays on this phone and is never uploaded. KFM never changes or moves anything by looking.'**
  String get whereKfmLooksPhoneBody;

  /// E2: Windows switch that replaces 'Folders KFM scans' (on by default).
  ///
  /// In en, this message translates to:
  /// **'Look everywhere'**
  String get lookEverywhereTitle;

  /// E2: Look everywhere on.
  ///
  /// In en, this message translates to:
  /// **'KFM keeps a private list of your photos, videos and files on this PC so Search, Sort, Storage and Similar photos cover everything. The list stays on this PC. KFM never uploads, changes or moves anything by looking, and skips Windows and program folders.'**
  String get lookEverywhereOnHelp;

  /// E2: Look everywhere off.
  ///
  /// In en, this message translates to:
  /// **'KFM only looks in the folder you have open. Search and Sort cover that folder.'**
  String get lookEverywhereOffHelp;

  /// E2: Look everywhere off with chosen folders.
  ///
  /// In en, this message translates to:
  /// **'KFM only looks in the folders below. Turn this on to cover all your files.'**
  String get lookEverywhereChosenHelp;

  /// E2: link under Look everywhere to the chosen-folders list.
  ///
  /// In en, this message translates to:
  /// **'Choose folders instead…'**
  String get lookEverywhereChoose;

  /// E2: confirm before turning Look everywhere off.
  ///
  /// In en, this message translates to:
  /// **'Only look where you are?'**
  String get lookEverywhereOffConfirmTitle;

  /// E2: confirm body.
  ///
  /// In en, this message translates to:
  /// **'Search and Sort will only cover folders you open. Tags, favorites and reviewed marks are kept.'**
  String get lookEverywhereOffConfirmBody;

  /// E2: confirm button.
  ///
  /// In en, this message translates to:
  /// **'Only open folders'**
  String get lookEverywhereOffConfirm;

  /// E2 settings search words for Where KFM looks.
  ///
  /// In en, this message translates to:
  /// **'index,scan,folders,look everywhere,search'**
  String get settingsKeywordsIndex;

  /// E2: first-launch language step title.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageStepTitle;

  /// E2: first-launch language step body.
  ///
  /// In en, this message translates to:
  /// **'You can change it later in Settings → General.'**
  String get languageStepBody;

  /// E2: the System choice with the language it resolves to.
  ///
  /// In en, this message translates to:
  /// **'System ({language})'**
  String languageSystemNamed(String language);

  /// E2: first-launch language step button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get languageStepContinue;

  /// E2 §7: Left-handed switch description (thumb side).
  ///
  /// In en, this message translates to:
  /// **'Puts Undo, the main buttons and the selection bar on the left, where your thumb is. Swipe directions don\'t change.'**
  String get leftHandedThumbHelp;

  /// E2: Accessibility switch.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reduceMotionTitle;

  /// E2: Reduce motion description.
  ///
  /// In en, this message translates to:
  /// **'Swiped cards fade instead of flying away, and screens change without sliding. Also follows the system setting.'**
  String get reduceMotionHelp;

  /// E2: Accessibility switch.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrastTitle;

  /// E2: High contrast description.
  ///
  /// In en, this message translates to:
  /// **'Stronger colors for text, buttons and outlines. Also follows the system setting.'**
  String get highContrastHelp;

  /// X6/E2: backup preview name of the Reduce motion setting.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get backupSettingReduceMotion;

  /// X6/E2: backup preview name of the High contrast setting.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get backupSettingHighContrast;

  /// E2 settings search words for Reduce motion.
  ///
  /// In en, this message translates to:
  /// **'animation,motion,vestibular,fade'**
  String get settingsKeywordsMotion;

  /// E2 settings search words for High contrast.
  ///
  /// In en, this message translates to:
  /// **'contrast,colors,low vision'**
  String get settingsKeywordsContrast;

  /// E2 §7: what screen readers say for a file tile/row.
  ///
  /// In en, this message translates to:
  /// **'{name}, {kind}, {size}, {date}'**
  String a11yFileLabel(String name, String kind, String size, String date);

  /// E2: spoken file kind.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get a11yKindAudio;

  /// E2: spoken file kind.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get a11yKindDocument;

  /// E2: spoken file kind with its extension (PDF document).
  ///
  /// In en, this message translates to:
  /// **'{ext} document'**
  String a11yKindDocumentExt(String ext);

  /// E2: spoken file kind.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get a11yKindArchive;

  /// E2: spoken file kind.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get a11yKindFile;

  /// E2: spoken file kind with its extension.
  ///
  /// In en, this message translates to:
  /// **'{ext} file'**
  String a11yKindFileExt(String ext);

  /// E3: description of the desktop File icons setting.
  ///
  /// In en, this message translates to:
  /// **'How files and folders look in the lists: Windows\' own icons or KFM\'s.'**
  String get desktopFileIconsHint;

  /// E4: a folder with its place, e.g. 'Camera · Internal storage' (swipe folder line, viewer).
  ///
  /// In en, this message translates to:
  /// **'{folder} · {place}'**
  String folderLabel(String folder, String place);

  /// E4: screen reader label of the folder line on the swipe screen.
  ///
  /// In en, this message translates to:
  /// **'Folder: {folder}'**
  String swipeFolderSemantics(String folder);

  /// E4: folder sheet on the swipe screen, opens the file's details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get swipeFolderDetails;

  /// E4: swipe setting; one line with the current file's folder.
  ///
  /// In en, this message translates to:
  /// **'Show the file\'s folder'**
  String get settingsSwipeShowFolder;

  /// E4: help text of the 'Show the file's folder' setting.
  ///
  /// In en, this message translates to:
  /// **'One line above the card. Tap it to copy the path or open the folder.'**
  String get settingsSwipeShowFolderHelp;

  /// E4: backup settings list label.
  ///
  /// In en, this message translates to:
  /// **'Show the file\'s folder'**
  String get backupSettingSwipeShowFolder;

  /// E4: pull to refresh in Browse failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh. Try again.'**
  String get browseRefreshFailed;

  /// E4: button on Same time's empty state; opens Settings where the time window is set.
  ///
  /// In en, this message translates to:
  /// **'Change window'**
  String get sameTimeChangeWindow;

  /// E1: tooltip of the (i) button on the share screen that shows the privacy and keep-running notes when they don't fit.
  ///
  /// In en, this message translates to:
  /// **'About sharing'**
  String get shareInfoTooltip;

  /// E1: snackbar after one received file. folder is like 'Downloads › KFM › Phone'.
  ///
  /// In en, this message translates to:
  /// **'{name} saved to {folder}'**
  String receivedSavedOne(String name, String folder);

  /// E1: snackbar after several received files.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file saved to {folder}} other{{count} files saved to {folder}}}'**
  String receivedSavedMany(int count, String folder);

  /// E1: opens the folder of a received file (Explorer with the file selected on Windows).
  ///
  /// In en, this message translates to:
  /// **'Show in folder'**
  String get showInFolder;

  /// E1: settings row title; the subtitle is the folder (like 'Downloads › KFM'). Also the folder picker's title.
  ///
  /// In en, this message translates to:
  /// **'Received files go to'**
  String get receiveFolderTitle;

  /// E1: tooltip of the reset button on the receive folder row (back to Downloads › KFM).
  ///
  /// In en, this message translates to:
  /// **'Use the default folder'**
  String get receiveFolderReset;

  /// E1: description under the 'Received files go to' settings row (E2 settings search).
  ///
  /// In en, this message translates to:
  /// **'Files other devices send you land here, in a folder per device.'**
  String get receiveFolderHelp;

  /// E1: first entry of file menus and the selection bar while a device is linked; one tap sends.
  ///
  /// In en, this message translates to:
  /// **'Send to {device}'**
  String linkSendTo(String device);

  /// E1: snackbar after Send to <device>.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Sending 1 file to {device}} other{Sending {count} files to {device}}}'**
  String linkSending(int count, String device);

  /// E1: snackbar when Send to <device> could not queue the files.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send to {device}. Try again.'**
  String linkSendFailed(String device);

  /// E1: chip above the phone tabs and in the desktop status bar while a device is linked.
  ///
  /// In en, this message translates to:
  /// **'Connected to {device}'**
  String linkConnectedTo(String device);

  /// E1: button on the 'Connected to <device>' chip; opens the device's files.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get linkOpen;

  /// E1: card on Browse that opens the Connect screen.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices'**
  String get linkNearbyDevices;

  /// E1: second line of the 'Nearby devices' card on Browse.
  ///
  /// In en, this message translates to:
  /// **'Connect a phone or PC'**
  String get linkNearbyDevicesHint;

  /// E1: tooltip of a remembered device in the desktop navigation pane.
  ///
  /// In en, this message translates to:
  /// **'Connect to {device}'**
  String linkReconnectTo(String device);

  /// E1: snackbar while a remembered device in the desktop navigation pane reconnects.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {device}…'**
  String linkReconnecting(String device);
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
      <String>['en', 'nl', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nl':
      return AppLocalizationsNl();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
