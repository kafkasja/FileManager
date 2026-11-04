// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Kaf\'s File Manager';

  @override
  String get appTitleShort => 'KFM';

  @override
  String get tabSwipe => 'Swipen';

  @override
  String get tabBrowse => 'Bladeren';

  @override
  String get tabTrash => 'Prullenbak';

  @override
  String get tabSettings => 'Instellingen';

  @override
  String get dbWriteError => 'Je laatste wijziging kan niet worden opgeslagen.';

  @override
  String dbResetNotice(String name) {
    return 'De gegevens van KFM waren beschadigd, dus KFM is opnieuw begonnen. Je foto\'s en bestanden zijn niet aangeraakt; sessies, tags en instellingen zijn gewist. De beschadigde kopie is bewaard als $name.';
  }

  @override
  String get dbUnavailableNotice =>
      'KFM kan zijn gegevens nu niet openen. Misschien gebruikt een ander programma ze. Sluit dat en start KFM opnieuw. Je bestanden zijn niet aangeraakt.';

  @override
  String get dismiss => 'Sluiten';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String indexingCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bestanden indexeren…',
      one: '1 bestand indexeren…',
    );
    return '$_temp0';
  }

  @override
  String get indexingPaused => 'Indexeren gepauzeerd';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get settingsAppearance => 'Weergave';

  @override
  String get themeLabel => 'Thema';

  @override
  String get themeSystem => 'Systeem';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeDark => 'Donker';

  @override
  String get languageLabel => 'Taal';

  @override
  String get languageSystem => 'Systeem';

  @override
  String get settingsAbout => 'Over';

  @override
  String aboutVersion(String version) {
    return 'Versie $version';
  }

  @override
  String get aboutPromise =>
      'Geen advertenties, geen account, geen tracking. Alles blijft op je apparaat.';

  @override
  String get permGateTitle => 'Laat KFM je foto\'s en video\'s zien';

  @override
  String get permGateWhy =>
      'Alles blijft op je telefoon. Geen account, geen upload.';

  @override
  String get permAllow => 'Toestaan';

  @override
  String get permOpenSettings => 'Instellingen openen';

  @override
  String get permPermanentlyDeniedHelp =>
      'Toegang tot foto\'s staat uit. Open in de instellingen Toestemmingen en sta Foto\'s en video\'s toe.';

  @override
  String get permCheckFailed => 'Kan de toestemmingen niet controleren.';

  @override
  String get limitedBanner => 'KFM ziet maar een deel van je foto\'s.';

  @override
  String get limitedAllowAll => 'Alles toestaan';

  @override
  String get allFilesSheetText =>
      'Zet Toegang tot alle bestanden aan om ook documenten en downloads te zien.';

  @override
  String get allFilesTurnOn => 'Aanzetten';

  @override
  String get notNow => 'Niet nu';

  @override
  String get settingsPermissions => 'Toestemmingen';

  @override
  String get permRowMedia => 'Foto\'s en video\'s';

  @override
  String get permRowAllFiles => 'Toegang tot alle bestanden';

  @override
  String get permRowMediaManagement => 'Bevestigingsvensters overslaan';

  @override
  String get permRowMediaManagementHelp =>
      'Optioneel. KFM kan dan foto\'s verplaatsen en verwijderen zonder het elke keer te vragen (Mediabeheer).';

  @override
  String get permStatusGranted => 'Toegestaan';

  @override
  String get permStatusLimited => 'Alleen sommige foto\'s';

  @override
  String get permStatusDenied => 'Niet toegestaan';

  @override
  String get permStatusNotAsked => 'Nog niet gevraagd';

  @override
  String get permStatusNotRequired => 'Niet nodig op deze telefoon';

  @override
  String get permChange => 'Wijzigen';

  @override
  String get settingsStorage => 'Opslag';

  @override
  String get thumbCacheTitle => 'Miniaturencache';

  @override
  String get thumbCacheSizeUnknown => 'Grootte onbekend';

  @override
  String get thumbCacheClear => 'Wissen';

  @override
  String get settingsDeveloper => 'Ontwikkelaar';

  @override
  String devIndexedFiles(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bestanden in de index',
      one: '1 bestand in de index',
    );
    return '$_temp0';
  }

  @override
  String get devRescan => 'Alles scannen';

  @override
  String get devIndexList => 'Geïndexeerde bestanden tonen';

  @override
  String get swipeAllDone =>
      'Helemaal klaar! Je hebt alle foto\'s en video\'s gehad.';

  @override
  String get swipeEmptyLibrary => 'Geen foto\'s of video\'s gevonden.';

  @override
  String get swipeLookingForPhotos => 'Foto\'s zoeken…';

  @override
  String get swipeErrorGeneric => 'Kan je foto\'s niet laden.';

  @override
  String get swipeDone => 'Klaar';

  @override
  String get swipeFinishTitle => 'Deze sessie afronden?';

  @override
  String get swipeFinishConfirm => 'Afronden';

  @override
  String get cancel => 'Annuleren';

  @override
  String get undo => 'Ongedaan maken';

  @override
  String get undoHistoryTitle => 'Recente acties';

  @override
  String get undoRestored => 'Teruggezet uit de prullenbak';

  @override
  String get undoPermanentlyDeleted =>
      'Dit bestand is definitief verwijderd en kan niet terugkomen.';

  @override
  String get undoFailed => 'Kan deze stap niet ongedaan maken.';

  @override
  String get undoNotPossibleYet => 'Dit kan nog niet ongedaan worden gemaakt.';

  @override
  String get deleteBatchRetry => 'Opnieuw proberen';

  @override
  String get deleteCommitFailed =>
      'Kan de bestanden nu niet verwijderen. Ze blijven in de wachtrij en er gaat niets verloren.';

  @override
  String swipeProgress(int swiped, int remaining) {
    final intl.NumberFormat swipedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String swipedString = swipedNumberFormat.format(swiped);
    final intl.NumberFormat remainingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String remainingString = remainingNumberFormat.format(remaining);

    return '$swipedString klaar · $remainingString te gaan';
  }

  @override
  String swipeFinishTrash(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bestanden worden naar de prullenbak verplaatst.',
      one: '1 bestand wordt naar de prullenbak verplaatst.',
      zero: 'Er wacht niets om verwijderd te worden.',
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
      other: '$countString bestanden worden definitief verwijderd.',
      one: '1 bestand wordt definitief verwijderd.',
      zero: 'Er wacht niets om verwijderd te worden.',
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
      other: 'Sessie afgerond: $countString bestanden verwijderd ($size).',
      one: 'Sessie afgerond: 1 bestand verwijderd ($size).',
      zero: 'Sessie afgerond.',
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
      other:
          'Sessie afgerond: $countString bestanden naar de prullenbak verplaatst ($size).',
      one: 'Sessie afgerond: 1 bestand naar de prullenbak verplaatst ($size).',
      zero: 'Sessie afgerond.',
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
      other: '$countString bestanden wachten op verwijdering',
      one: '1 bestand wacht op verwijdering',
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
      other: '$countString bestanden kunnen niet worden verwijderd',
      one: '1 bestand kan niet worden verwijderd',
    );
    return '$_temp0';
  }

  @override
  String get settingsDeleting => 'Verwijderen';

  @override
  String get deleteModeTrash => 'Naar de prullenbak (aanbevolen)';

  @override
  String get deleteModeTrashHelp =>
      'Geswipete bestanden gaan naar de prullenbak van de telefoon en kunnen worden hersteld.';

  @override
  String get deleteModePermanent => 'Definitief verwijderen';

  @override
  String get deleteModePermanentHelp =>
      'Geswipete bestanden worden voorgoed verwijderd. Geen herstel mogelijk.';

  @override
  String get deleteModePermanentWarning =>
      'Bestanden die zo worden verwijderd, kunnen niet worden hersteld, ook niet met ongedaan maken.';

  @override
  String get deleteModeNextSession => 'Geldt vanaf je volgende sessie.';

  @override
  String get pendingRetentionLabel => 'Bestanden in de wachtmap bewaren voor';

  @override
  String get pendingRetentionHelp =>
      'Documenten en andere bestanden (en foto\'s op Android 10 en ouder) wachten in een verborgen map voordat ze voorgoed worden verwijderd.';

  @override
  String get pendingEmptyNow => 'Wachtmap nu legen';

  @override
  String get pendingEmptyTitle => 'Alles in de wachtmap verwijderen?';

  @override
  String get pendingEmptyBody =>
      'Deze bestanden kunnen daarna niet meer worden hersteld.';

  @override
  String get pendingEmptyConfirm => 'Verwijderen';

  @override
  String get permanentConfirmTitle => 'Deze sessie definitief verwijderen?';

  @override
  String get permanentConfirmBody =>
      'Bestanden die je naar de prullenbak swipet, worden voorgoed verwijderd. Ze kunnen niet worden hersteld.';

  @override
  String get permanentConfirmYes => 'Definitief verwijderen';

  @override
  String get permanentConfirmUseTrash => 'Toch de prullenbak gebruiken';

  @override
  String pendingRetentionDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dagen',
      one: '1 dag',
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
      other: '$countString bestanden verwijderd.',
      one: '1 bestand verwijderd.',
      zero: 'De wachtmap is leeg.',
    );
    return '$_temp0';
  }

  @override
  String get trashSystem => 'Systeemprullenbak';

  @override
  String get trashPending => 'Wacht op verwijdering';

  @override
  String get trashNothingHere => 'Niets hier';

  @override
  String get trashExpiresToday => 'Verloopt vandaag';

  @override
  String get trashSelect => 'Selecteren';

  @override
  String get trashRestore => 'Herstellen';

  @override
  String get trashDeleteForever => 'Voorgoed verwijderen';

  @override
  String get trashDeleteForeverBody => 'Dit kan niet ongedaan worden gemaakt.';

  @override
  String get trashEmptySection => 'Dit onderdeel legen';

  @override
  String get trashCancelled => 'Geannuleerd';

  @override
  String get trashAlreadyRemoved => 'Sommige items waren al verwijderd.';

  @override
  String get trashSystemHelp =>
      'Android bewaart foto\'s en video\'s 30 dagen. Je galerij-app heeft misschien ook een eigen prullenbak.';

  @override
  String get trashLoadFailed => 'Kan de prullenbak niet laden.';

  @override
  String get trashNeedsPermission =>
      'Sta toegang tot foto\'s en video\'s toe om de prullenbak te zien.';

  @override
  String trashDaysLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nog $countString dagen',
      one: 'Nog 1 dag',
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
      other: '$countString items voorgoed verwijderen?',
      one: '1 item voorgoed verwijderen?',
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
      other: '$countString items hersteld',
      one: '1 item hersteld',
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
      other: '$countString geselecteerd',
      one: '1 geselecteerd',
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
  String get labelTrash => '→ Prullenbak';

  @override
  String get labelDelete => '→ Verwijderen';

  @override
  String get labelKept => '→ Bewaard';

  @override
  String get labelFavorite => '★ Favoriet';

  @override
  String get labelRenameBatch => '→ Hernoemreeks';

  @override
  String get settingsSwipe => 'Swipen';

  @override
  String get settingsHaptics => 'Trillen';

  @override
  String get settingsHapticsHelp =>
      'Een korte trilling als een swipe klaar is.';

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
  String get restoredSnack => 'Verder waar je was gebleven';

  @override
  String get restoredStartFresh => 'Opnieuw beginnen';

  @override
  String get clearMenu => 'Wissen…';

  @override
  String get clearResetLayout => 'Actieknoppen resetten';

  @override
  String get clearResetLayoutHelp =>
      'Terug naar: links = prullenbak, rechts = bewaren';

  @override
  String get clearNewSession => 'Nieuwe sessie starten';

  @override
  String get clearNewSessionHelp =>
      'Beëindigt de voortgang en de geschiedenis voor ongedaan maken van deze sessie.';

  @override
  String get clearConfirm => 'Wissen';

  @override
  String get layoutResetDone => 'Actieknoppen gereset';

  @override
  String get undoAction => 'Ongedaan maken';

  @override
  String get newSessionFailed =>
      'Kan de verwijderingen niet afronden, dus deze sessie gaat door. Probeer het opnieuw.';

  @override
  String get settingsFreshStart => 'Wissen / opnieuw beginnen…';

  @override
  String newFilesChip(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString nieuwe foto\'s · Tonen',
      one: '1 nieuwe foto · Tonen',
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
      other: '$countString wachtende verwijderingen worden uitgevoerd.',
      one: '1 wachtende verwijdering wordt uitgevoerd.',
      zero: 'Er wacht niets om verwijderd te worden.',
    );
    return '$_temp0';
  }

  @override
  String get viewerClose => 'Sluiten';

  @override
  String get videoCantPlay => 'Kan deze video niet afspelen';

  @override
  String get videoDamaged =>
      'Dit bestand kan niet worden afgespeeld — het is mogelijk beschadigd';

  @override
  String get imageDamaged =>
      'Dit bestand kan niet worden weergegeven — het is mogelijk beschadigd';

  @override
  String get videoTapForSound => 'Tik voor geluid';

  @override
  String get videoOpenFullscreen => 'Volledig scherm';

  @override
  String get customizeSwipes => 'Swipes aanpassen';

  @override
  String get customizeSwipesHelp => 'Kies wat elke swiperichting doet';

  @override
  String get customizeSwipesIntro =>
      'Tik op een pijl om te wijzigen wat swipen in die richting doet.';

  @override
  String get swipeDirectionLeft => 'Naar links swipen';

  @override
  String get swipeDirectionRight => 'Naar rechts swipen';

  @override
  String get swipeDirectionUp => 'Omhoog swipen';

  @override
  String get swipeDirectionDown => 'Omlaag swipen';

  @override
  String get swipeActionNothing => 'Niets';

  @override
  String get swipeActionTrash => 'Naar de prullenbak';

  @override
  String get swipeActionDelete => 'Definitief verwijderen';

  @override
  String get swipeActionKeep => 'Bewaren';

  @override
  String get swipeActionNeedOne =>
      'Minstens één richting heeft een actie nodig';

  @override
  String get swipeLayoutReset => 'Terug naar basis';

  @override
  String get swipeLayoutResetTitle => 'Swipes resetten?';

  @override
  String get swipeLayoutResetBody =>
      'Links wordt weer prullenbak en rechts bewaren. Omhoog en omlaag doen niets.';

  @override
  String get reset => 'Resetten';

  @override
  String get swipeActionMoveTo => 'Naar map verplaatsen…';

  @override
  String get swipeActionCopyTo => 'Naar map kopiëren…';

  @override
  String get swipeActionAddTag => 'Tag toevoegen…';

  @override
  String get swipeActionFavorite => 'Aan favorieten toevoegen';

  @override
  String swipeActionMoveToNamed(String folder) {
    return 'Verplaatsen naar $folder';
  }

  @override
  String swipeActionCopyToNamed(String folder) {
    return 'Kopiëren naar $folder';
  }

  @override
  String swipeActionTagNamed(String tag) {
    return 'Tag: $tag';
  }

  @override
  String get swipeActionTagMissing => 'Tag bestaat niet meer';

  @override
  String get moveConsentNotice =>
      'Android vraagt misschien bij elke verplaatsing om toestemming';

  @override
  String get turnOn => 'Aanzetten';

  @override
  String get folderPickerTitle => 'Kies een map';

  @override
  String get folderPickerRecent => 'Recent';

  @override
  String get folderPickerWithPhotos => 'Mappen met foto\'s';

  @override
  String get folderPickerNew => 'Nieuwe map…';

  @override
  String get folderPickerNewTitle => 'Nieuwe map';

  @override
  String folderPickerNewIn(String folder) {
    return 'In $folder';
  }

  @override
  String get folderNameHint => 'Mapnaam';

  @override
  String get folderNameInvalid => 'Deze naam kan niet worden gebruikt';

  @override
  String get folderNeedsAllFiles => 'Vereist Toegang tot alle bestanden';

  @override
  String folderFileCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bestanden',
      one: '1 bestand',
    );
    return '$_temp0';
  }

  @override
  String get create => 'Maken';

  @override
  String get tagPickerTitle => 'Kies een tag';

  @override
  String get tagPickerNew => 'Nieuwe tag…';

  @override
  String get tagNewTitle => 'Nieuwe tag';

  @override
  String get tagNameHint => 'Tagnaam';

  @override
  String get tagNameTaken => 'Er bestaat al een tag met deze naam';

  @override
  String get tagNameInvalid => 'Gebruik 1 tot 40 tekens';

  @override
  String get tagsEmpty => 'Nog geen tags';

  @override
  String get swipeProblemTagMissing =>
      'Tag bestaat niet meer. Wijzig dit in Swipes aanpassen.';

  @override
  String get swipeProblemUnsupported =>
      'Deze swipe kan nog niet worden gebruikt';

  @override
  String get fileOpFolderMissing =>
      'Map niet gevonden. Kies hem opnieuw in Swipes aanpassen.';

  @override
  String get fileOpDeclined => 'Niet verplaatst: toestemming geweigerd';

  @override
  String get fileOpNoSpace => 'Niet genoeg ruimte';

  @override
  String get fileOpNeedsAllFiles =>
      'Deze map vereist Toegang tot alle bestanden';

  @override
  String fileOpMoveFailed(String name) {
    return 'Kan $name niet verplaatsen';
  }

  @override
  String fileOpCopyFailed(String name) {
    return 'Kan $name niet kopiëren';
  }

  @override
  String get undoneLabel => '↩ Ongedaan gemaakt';

  @override
  String get swipeActionRenameBatch => 'Aan hernoemreeks toevoegen';

  @override
  String renamePill(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '✎ $countString';
  }

  @override
  String get renameTitle => 'Hernoemreeks';

  @override
  String get renamePatternLabel => 'Naampatroon';

  @override
  String renamePatternHint(String n) {
    return 'vakantie_$n';
  }

  @override
  String get renameStart => 'Beginnen bij';

  @override
  String get renamePadding => 'Cijfers';

  @override
  String renameTokensHelp(String n, String date, String orig) {
    return '$n = nummer · $date = datum · $orig = oorspronkelijke naam';
  }

  @override
  String get renameMissing => 'Ontbreekt of gewijzigd: overgeslagen';

  @override
  String renameCollision(String name) {
    return 'Naam was al in gebruik: \"$name\" wordt gebruikt';
  }

  @override
  String get renameApply => 'Naam wijzigen';

  @override
  String get renameDiscard => 'Reeks weggooien';

  @override
  String get renameDiscardTitle => 'Deze hernoemreeks weggooien?';

  @override
  String get renameDiscardBody =>
      'De bestanden blijven zoals ze zijn; alleen de reeks vervalt.';

  @override
  String get renameErrorEmpty => 'Typ een naampatroon';

  @override
  String get renameErrorInvalid =>
      'Deze tekens kunnen niet worden gebruikt: / \\ : * ? \" < > |';

  @override
  String renameErrorNeedsCounter(String n) {
    return 'Voeg $n toe zodat elk bestand een eigen nummer krijgt';
  }

  @override
  String get renameErrorTooLong => 'De namen zouden te lang worden';

  @override
  String get renameRunning => 'Naam wijzigen…';

  @override
  String renameDone(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Naam van $countString bestanden gewijzigd',
      one: 'Naam van 1 bestand gewijzigd',
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

    return 'Gewijzigd: $renamedString · overgeslagen: $skippedString';
  }

  @override
  String get renameDeclined => 'Niets hernoemd: toestemming geweigerd';

  @override
  String get renameNoUndoAfterDone =>
      'Je kunt dit ongedaan maken tot je op Klaar tikt.';

  @override
  String renameBeforeFinishTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eerst de naam van $countString bestanden wijzigen?',
      one: 'Eerst de naam van 1 bestand wijzigen?',
    );
    return '$_temp0';
  }

  @override
  String get renameBeforeFinishBody =>
      'Je hernoemreeks is nog niet toegepast. Als je hem weggooit, blijven de huidige namen.';

  @override
  String get renameOpen => 'Naam wijzigen…';

  @override
  String get labelRenameApplied => '✎ Reeks hernoemd';

  @override
  String clearRenameDropped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bestanden in de hernoemreeks vervallen',
      one: '1 bestand in de hernoemreeks vervalt',
    );
    return '$_temp0';
  }

  @override
  String get barTrash => 'Prullenbak';

  @override
  String get barDelete => 'Verwijderen';

  @override
  String get barKeep => 'Bewaren';

  @override
  String get barFavorite => 'Favoriet';

  @override
  String get barRename => 'Naam wijzigen';

  @override
  String get actionBarTitle => 'Actiebalk';

  @override
  String get actionBarHelp => 'Extra knoppen onder de kaart';

  @override
  String get actionBarAdd => 'Actie toevoegen';

  @override
  String get actionBarEmpty => 'Nog geen knoppen';

  @override
  String get actionBarRemove => 'Verwijderen';

  @override
  String get actionBarFull => 'Maximaal 8 knoppen';

  @override
  String get filterTitle => 'Filter';

  @override
  String get filterButton => 'Filter';

  @override
  String get filterKinds => 'Tonen';

  @override
  String get filterPhotos => 'Foto\'s';

  @override
  String get filterVideos => 'Video\'s';

  @override
  String get filterScreenshotsOnly => 'Alleen screenshots';

  @override
  String get filterDate => 'Datum';

  @override
  String get filterAny => 'Alle';

  @override
  String get filterThisMonth => 'Deze maand';

  @override
  String get filterLast30Days => 'Afgelopen 30 dagen';

  @override
  String get filterCustomRange => 'Datums kiezen…';

  @override
  String filterRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get filterSize => 'Grootte';

  @override
  String filterOverMb(int mb) {
    final intl.NumberFormat mbNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String mbString = mbNumberFormat.format(mb);

    return 'Meer dan $mbString MB';
  }

  @override
  String get filterFolders => 'Mappen';

  @override
  String filterFolderCount(String folder, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$folder ($countString)';
  }

  @override
  String filterFolderMissing(String folder) {
    return '$folder (ontbreekt)';
  }

  @override
  String get filterTags => 'Tags';

  @override
  String get filterTagged => 'Met tags';

  @override
  String get filterUntagged => 'Zonder tags';

  @override
  String get filterSpecificTags => 'Specifiek…';

  @override
  String get filterFavoritesOnly => 'Alleen favorieten';

  @override
  String filterMatches(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bestanden gevonden',
      one: '1 bestand gevonden',
      zero: 'Geen bestanden gevonden',
    );
    return '$_temp0';
  }

  @override
  String get filterApply => 'Toepassen';

  @override
  String get filterProblemSize =>
      'De minimale grootte is groter dan de maximale';

  @override
  String get filterProblemTags => 'Kies minstens één tag';

  @override
  String get filterProblemDate => 'De startdatum ligt na de einddatum';

  @override
  String get filterNoMatches => 'Geen bestanden voor dit filter';

  @override
  String get filterAllDone => 'Alle gevonden bestanden zijn klaar';

  @override
  String get filterChange => 'Filter wijzigen';

  @override
  String get presetBasic => 'Basis';

  @override
  String get presetChipTooltip => 'Andere voorinstelling';

  @override
  String get presetSheetTitle => 'Voorinstellingen';

  @override
  String get presetManage => 'Voorinstellingen beheren';

  @override
  String get presetSaveAs => 'Opslaan als voorinstelling…';

  @override
  String get presetNameLabel => 'Naam voorinstelling';

  @override
  String get presetIncludeFilter => 'Huidige filter meenemen';

  @override
  String presetSaved(String name) {
    return '“$name” opgeslagen';
  }

  @override
  String get presetNameTaken =>
      'Er bestaat al een voorinstelling met deze naam';

  @override
  String get presetNameInvalid => 'Gebruik 1 tot 40 tekens';

  @override
  String get presetRename => 'Naam wijzigen';

  @override
  String get presetEdit => 'Bewerken';

  @override
  String get presetDuplicate => 'Dupliceren';

  @override
  String get presetDelete => 'Verwijderen';

  @override
  String presetDeleteConfirm(String name) {
    return '“$name” verwijderen?';
  }

  @override
  String get presetDeleteBody =>
      'De onafgemaakte sessie wordt beëindigd. Je bestanden blijven ongewijzigd.';

  @override
  String get presetLoadError => 'Kan niet laden: bewerk of verwijder';

  @override
  String presetNoSessionHint(String name) {
    return 'Begin met swipen in $name om de knoppen voor die sessie te wijzigen, of bewerk de voorinstelling via Voorinstellingen beheren.';
  }

  @override
  String get presetEditorTitle => 'Voorinstelling bewerken';

  @override
  String get presetDirections => 'Swipeknoppen';

  @override
  String get presetFilter => 'Filter';

  @override
  String get presetEditorFilterNone => 'Geen filter';

  @override
  String get presetEditorFilterOn => 'Filter ingesteld';

  @override
  String get presetEditorSave => 'Opslaan';

  @override
  String get presetEditorReplacesSession =>
      'Vervangt ook de instellingen van de onafgemaakte sessie van deze voorinstelling';

  @override
  String get presetEditorDiscard => 'Je wijzigingen weggooien?';

  @override
  String get presetDiscard => 'Weggooien';

  @override
  String presetSwitchBlocked(String name) {
    return 'Verwijderen kon niet worden afgerond, dus je zit nog in $name. Probeer het opnieuw.';
  }

  @override
  String get presetEmptyTitle => 'Nog geen voorinstellingen';

  @override
  String get presetEmptyBody =>
      'Een voorinstelling bewaart je swipeknoppen en, als je wilt, een filter. Wissel met één tik.';

  @override
  String get presetEmptyQuickCleanup => 'Snel opruimen';

  @override
  String get presetEmptyQuickCleanupHelp =>
      'Links = prullenbak, rechts = bewaren, alleen screenshots';

  @override
  String get presetEmptySortHoliday => 'Vakantie sorteren';

  @override
  String get presetEmptySortHolidayHelp =>
      'Links = prullenbak, rechts = naar een map, omhoog = favoriet';

  @override
  String get presetCreate => 'Maken';

  @override
  String get presetNew => 'Nieuwe voorinstelling';

  @override
  String get settingsPresets => 'Voorinstellingen';

  @override
  String get settingsPresetsHelp => 'Opgeslagen swipe-instellingen';

  @override
  String get reviewedBadge => 'Bekeken';

  @override
  String get settingsShowReviewedBadge => 'Bekeken-markering tonen';

  @override
  String get settingsShowReviewedBadgeHelp =>
      'Een klein teken op bestanden die je al eerder hebt geswipet';

  @override
  String get reviewedIncludeToggle => 'Ook bestanden die hier al bekeken zijn';

  @override
  String get filterReviewed => 'Bekeken';

  @override
  String get filterReviewedOnly => 'Bekeken';

  @override
  String get filterNotReviewed => 'Niet bekeken';

  @override
  String reviewedInfoLine(String preset, String action, String date) {
    return 'Bekeken in $preset · $action · $date';
  }

  @override
  String get reviewedReset => 'Bekeken-markeringen wissen…';

  @override
  String get reviewedResetAll => 'Alle voorinstellingen';

  @override
  String reviewedResetConfirm(String name) {
    return 'Bekeken-markeringen voor $name wissen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String reviewedResetCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bestanden',
      one: '1 bestand',
      zero: 'Geen bestanden',
    );
    return '$_temp0';
  }

  @override
  String get reviewedResetDone => 'Bekeken-markeringen gewist';

  @override
  String get presetIncludeReviewed =>
      'Ook bestanden die al in deze voorinstelling bekeken zijn';

  @override
  String get settingsStats => 'Swipestatistieken';

  @override
  String get settingsStatsHelp => 'Bekeken bestanden en vrijgemaakte ruimte';

  @override
  String get settingsShowSessionSummary => 'Overzicht tonen na Klaar';

  @override
  String get statsTitle => 'Swipestatistieken';

  @override
  String statsInTrashFreed(String inTrash, String freed) {
    return '$inTrash in de prullenbak · $freed vrijgemaakt';
  }

  @override
  String get statsGoToTrash => 'Naar Prullenbak';

  @override
  String get statsThisWeek => 'Deze week';

  @override
  String get statsThisMonth => 'Deze maand';

  @override
  String get statsAllTime => 'Altijd';

  @override
  String statsReviewed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bestanden bekeken',
      one: '1 bestand bekeken',
    );
    return '$_temp0';
  }

  @override
  String statsFreed(String size) {
    return '$size vrijgemaakt';
  }

  @override
  String statsRowLine(String reviewed, String freed) {
    return '$reviewed · $freed';
  }

  @override
  String get statsByPreset => 'Per voorinstelling';

  @override
  String get statsDeletedPresets => 'Verwijderde voorinstellingen';

  @override
  String get statsWeekly => 'Afgelopen 8 weken';

  @override
  String get statsReset => 'Statistieken wissen';

  @override
  String get statsResetConfirm =>
      'De tellers voor bekeken en vrijgemaakt wissen? Bestanden in de prullenbak blijven meegeteld.';

  @override
  String get summaryTitle => 'Sessie afgerond';

  @override
  String summaryReviewed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Je hebt $countString bestanden bekeken',
      one: 'Je hebt 1 bestand bekeken',
    );
    return '$_temp0';
  }

  @override
  String summaryToTrash(String size) {
    return '$size naar de prullenbak verplaatst';
  }

  @override
  String summaryFreed(String size) {
    return '$size vrijgemaakt';
  }

  @override
  String get ok => 'OK';

  @override
  String get settingsSwipeButtons => 'Knoppen gebruiken in plaats van swipen';

  @override
  String get settingsSwipeButtonsHelp =>
      'Tik op knoppen om te doen wat elke swipe doet';

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
  String get fileKindPhoto => 'Foto';

  @override
  String get fileKindVideo => 'Video';

  @override
  String swipeButtonSemantics(String action, String direction) {
    return '$action, $direction';
  }

  @override
  String get pendingRetentionCustom => 'Aangepast…';

  @override
  String get pendingRetentionCustomTitle =>
      'Bestanden in de wachtmap bewaren voor';

  @override
  String get pendingRetentionCustomHelper => '1–90 dagen';

  @override
  String get pendingRetentionCustomError => 'Voer een getal van 1 tot 90 in';

  @override
  String get pendingRetentionCustomSave => 'Opslaan';

  @override
  String get pendingPurgeFailedPermission =>
      'Automatisch opruimen is mislukt: toestemming nodig';

  @override
  String get pendingPurgeFailed => 'Automatisch opruimen is mislukt';

  @override
  String pendingUnavailableSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count bestanden konden niet naar de wachtmap worden verplaatst. Ze staan nog op je apparaat.',
      one: '1 bestand kon niet naar de wachtmap worden verplaatst. Het staat nog op je apparaat.',
    );
    return '$_temp0';
  }

  @override
  String pendingUnavailableBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count bestanden zijn niet verwijderd: de wachtmap kan niet worden gebruikt',
      one: '1 bestand is niet verwijderd: de wachtmap kan niet worden gebruikt',
    );
    return '$_temp0';
  }

  @override
  String get pendingUnavailableOptions => 'Opties';

  @override
  String pendingUnavailableAfterDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count bestanden zijn niet verwijderd. Je vindt ze in Prullenbak.',
      one: '1 bestand is niet verwijderd. Je vindt het in Prullenbak.',
    );
    return '$_temp0';
  }

  @override
  String get pendingUnavailableTitle => 'Kan niet naar de wachtmap verplaatsen';

  @override
  String get pendingUnavailableBody =>
      'KFM kan deze bestanden niet in de wachtmap zetten, dus ze zijn niet verwijderd.';

  @override
  String get pendingUnavailableGrantAccess =>
      'Sta Toegang tot alle bestanden toe zodat KFM de map kan gebruiken';

  @override
  String get pendingUnavailableWarning =>
      'Definitief verwijderen kan niet ongedaan worden gemaakt. Deze bestanden gaan niet naar de prullenbak en kunnen niet worden hersteld.';

  @override
  String get pendingUnavailableKeep => 'Bewaren';

  @override
  String get pendingUnavailableDeleteOne => 'Definitief verwijderen';

  @override
  String pendingUnavailableDeleteAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count definitief verwijderen',
      one: '1 bestand definitief verwijderen',
    );
    return '$_temp0';
  }

  @override
  String pendingUnavailableConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden definitief verwijderen?',
      one: 'Dit bestand definitief verwijderen?',
    );
    return '$_temp0 Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get pendingUnavailableConfirmButton => 'Definitief verwijderen';

  @override
  String pendingUnavailableDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden definitief verwijderd',
      one: '1 bestand definitief verwijderd',
    );
    return '$_temp0';
  }

  @override
  String get pendingUnavailableSection =>
      'Kan niet naar de wachtmap verplaatsen';

  @override
  String get trashSort => 'Sorteren';

  @override
  String get trashSortExpiry => 'Verloopt het eerst';

  @override
  String get trashSortNewest => 'Laatst verwijderd';

  @override
  String get swipeEmptyLibraryHint =>
      'Als je telefoon foto\'s heeft, mag KFM ze misschien niet zien. Controleer de toestemmingen van KFM in de instellingen van je telefoon.';

  @override
  String get browseKindAll => 'Alle';

  @override
  String get browseKindImages => 'Afbeeldingen';

  @override
  String get browseKindVideos => 'Video\'s';

  @override
  String get browseKindAudio => 'Audio';

  @override
  String get browseKindDocuments => 'Documenten';

  @override
  String get browseKindArchives => 'Archieven';

  @override
  String get browseKindOther => 'Overig';

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
  String get browseSourceVideos => 'Video\'s';

  @override
  String get browseSourcePanoramas => 'Panorama\'s';

  @override
  String get browseSourceScreenRecordings => 'Schermopnamen';

  @override
  String get browseSourceExpertRaw => 'Expert RAW';

  @override
  String get browseSourceGifs => 'GIF\'s';

  @override
  String get browseSourceCollages => 'Collages';

  @override
  String get browseSourceClippedImages => 'Uitgeknipte afbeeldingen';

  @override
  String get browseSourceLiveMessages => 'Live-berichten';

  @override
  String get browseSourceVideoCaptures => 'Video-opnamen';

  @override
  String get browseSourceTelegram => 'Telegram';

  @override
  String get browseSourceInstagram => 'Instagram';

  @override
  String get browseSourceOther => 'Andere apps';

  @override
  String get browseSourceHidden => 'Verborgen';

  @override
  String get browsePanoramaHint =>
      'Beste schatting: brede foto\'s en PANO-bestanden';

  @override
  String get browseModeAll => 'Alle bestanden';

  @override
  String get browseModeFolders => 'Mappen';

  @override
  String get browseShowHidden => 'Verborgen bestanden tonen';

  @override
  String get browseSwipeThese => 'Deze swipen';

  @override
  String get browseNeedsAllFiles =>
      'Geef toegang om documenten, downloads en verborgen bestanden te zien';

  @override
  String get browseGrantAccess => 'Toegang geven';

  @override
  String get browseEmpty => 'Geen bestanden hier';

  @override
  String searchKwType(String name) {
    return 'Type: $name';
  }

  @override
  String searchKwSource(String name) {
    return 'Bron: $name';
  }

  @override
  String get searchKwHidden => 'Verborgen bestanden';

  @override
  String get searchKwTiny => 'Piepklein (< 10 KB)';

  @override
  String get searchKwLarge => 'Groot (> 100 MB)';

  @override
  String get searchKwToday => 'Vandaag';

  @override
  String get searchKwWeek => 'Afgelopen 7 dagen';

  @override
  String searchTermsLoadError(String language) {
    return 'Zoekwoorden voor $language konden niet worden geladen';
  }

  @override
  String get searchSettingsTitle => 'Zoeken';

  @override
  String get searchSettingsAlsoSearchIn => 'Ook zoeken in';

  @override
  String get searchSettingsAlsoSearchInHelp =>
      'Slimme woorden zoals \'video\' of \'cloud\' werken ook in deze taal.';

  @override
  String get searchSettingsNone => 'Geen';

  @override
  String searchSettingsAlreadyIncluded(String language) {
    return '$language (al inbegrepen)';
  }

  @override
  String get searchSettingsTip =>
      'Typ woorden zoals \'video\', \'pdf\', \'whatsapp\', \'verborgen\' of \'groot\' om te filteren. Tik op ✕ op een chip om in plaats daarvan op naam te zoeken.';

  @override
  String get searchOpen => 'Zoeken';

  @override
  String get searchHint => 'Bestanden zoeken';

  @override
  String get searchClearText => 'Zoekopdracht wissen';

  @override
  String get searchChipType => 'Type';

  @override
  String searchChipTypes(int count) {
    return '$count typen';
  }

  @override
  String get searchChipSource => 'Bron';

  @override
  String get searchChipDate => 'Datum';

  @override
  String get searchDateToday => 'Vandaag';

  @override
  String get searchDateWeek => 'Afgelopen 7 dagen';

  @override
  String get searchDateMonth => 'Deze maand';

  @override
  String get searchDateYear => 'Dit jaar';

  @override
  String get searchDateCustom => 'Aangepast…';

  @override
  String searchDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String searchDateSince(String from) {
    return 'Sinds $from';
  }

  @override
  String get searchChipSize => 'Grootte';

  @override
  String searchSizeOver(String size) {
    return '> $size';
  }

  @override
  String searchSizeUnder(String size) {
    return '< $size';
  }

  @override
  String get searchSizeTiny => 'Piepklein (< 10 KB)';

  @override
  String searchSizeBetween(String min, String max) {
    return '$min – $max';
  }

  @override
  String get searchSizeCustom => 'Aangepast…';

  @override
  String get searchSizeCustomTitle => 'Bestandsgrootte';

  @override
  String get searchSizeMinLabel => 'Minimaal (MB)';

  @override
  String get searchSizeMaxLabel => 'Maximaal (MB)';

  @override
  String get searchSizeInvalid =>
      'Het minimum mag niet groter zijn dan het maximum';

  @override
  String get searchChipHidden => 'Verborgen bestanden';

  @override
  String get searchHiddenInclude => 'Verborgen bestanden meenemen';

  @override
  String get searchHiddenOnly => 'Alleen verborgen bestanden';

  @override
  String searchOnlyIn(String folder) {
    return 'Alleen in $folder';
  }

  @override
  String searchTokenExtension(String ext) {
    return 'Type: .$ext';
  }

  @override
  String searchTokenAsName(String word) {
    return 'In plaats daarvan namen zoeken op “$word”';
  }

  @override
  String get searchRecent => 'Recente zoekopdrachten';

  @override
  String get searchSuggestions => 'Probeer';

  @override
  String get searchSuggestLarge => 'Grote bestanden';

  @override
  String get searchSuggestDownloads => 'Downloads';

  @override
  String get searchSuggestPdfs => 'PDF\'s';

  @override
  String get searchSuggestHidden => 'Verborgen bestanden';

  @override
  String get searchSuggestWeek => 'Deze week';

  @override
  String get searchNoMatch => 'Geen bestanden gevonden';

  @override
  String get searchClearFilters => 'Filters wissen';

  @override
  String searchWordsLoadError(String languages) {
    return 'Zoekwoorden voor $languages konden niet worden geladen';
  }

  @override
  String get searchDone => 'Klaar';

  @override
  String get browseLoadError => 'Kan de bestanden niet laden.';

  @override
  String get browseOtherHint =>
      'Bestanden van andere apps en mappen, per map gegroepeerd';

  @override
  String get browseInternalStorage => 'Interne opslag';

  @override
  String browseExternalVolume(String name) {
    return 'SD-kaart of USB ($name)';
  }

  @override
  String browseFileCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bestanden',
      one: '1 bestand',
    );
    return '$_temp0';
  }

  @override
  String get browseStorageRoot => 'Opslag';

  @override
  String get browseFolderMenu => 'Mapopties';

  @override
  String get openWith => 'Openen met';

  @override
  String get openWithNone => 'Geen app kan dit bestand openen';

  @override
  String get openWithFailed => 'Kan dit bestand niet openen.';

  @override
  String get textViewerTruncated => 'De eerste 1 MB wordt getoond';

  @override
  String get textViewerLatin1 => 'Getoond als Latin-1 (geen UTF-8)';

  @override
  String get textViewerBinary => 'Dit lijkt geen tekstbestand';

  @override
  String get textViewerError => 'Kan dit bestand niet lezen.';

  @override
  String get browseSortTitle => 'Sorteren op';

  @override
  String get browseSortDate => 'Datum';

  @override
  String get browseSortSize => 'Grootte';

  @override
  String get browseSortName => 'Naam';

  @override
  String get browseSortNewestFirst => 'Nieuwste eerst';

  @override
  String get browseSortOldestFirst => 'Oudste eerst';

  @override
  String get browseSortLargestFirst => 'Grootste eerst';

  @override
  String get browseSortSmallestFirst => 'Kleinste eerst';

  @override
  String get browseSortNameAsc => 'A–Z';

  @override
  String get browseSortNameDesc => 'Z–A';

  @override
  String get browseRecent => 'Recente zoekopdracht';

  @override
  String get settingsBrowse => 'Bladeren';

  @override
  String get settingsShowSizes => 'Bestandsgroottes tonen';

  @override
  String get settingsShowSizesHelp => 'Een groottelabel op elke foto en video';

  @override
  String get settingsHighlightBig => 'Grote bestanden markeren';

  @override
  String get settingsHighlightBigHelp =>
      'Bestanden van 100 MB of meer krijgen een rood groottelabel';

  @override
  String selectionCount(int count, String size) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString geselecteerd · $size',
      one: '1 geselecteerd · $size',
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
      other: 'Selectie gewist ($countString bestanden)',
      one: 'Selectie gewist (1 bestand)',
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
      other: 'Selectie wissen ($countString bestanden)',
      one: 'Selectie wissen (1 bestand)',
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
      other: '$countString bestanden toegevoegd',
      one: '1 bestand toegevoegd',
      zero: 'Niets nieuws om toe te voegen',
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
      other: '$countString geselecteerd',
      one: '1 geselecteerd',
    );
    return '$_temp0';
  }

  @override
  String get selectionEnter => 'Selecteren';

  @override
  String get selectionExit => 'Selectiemodus verlaten';

  @override
  String get selectionEditTitle => 'Selectie bewerken';

  @override
  String get selectionHint =>
      'Tik om toe te voegen · Lang indrukken en slepen voor meer';

  @override
  String get selectionEditHint =>
      'Tik op geselecteerde bestanden om ze te verwijderen uit de selectie';

  @override
  String get selectionSelectAll => 'Alles selecteren';

  @override
  String get selectionClearAll => 'Alles wissen';

  @override
  String get selectionView => 'Selectie bekijken';

  @override
  String get selectionRestore => 'Vorige selectie herstellen';

  @override
  String get selectionDone => 'Klaar';

  @override
  String get selectionRemoved => 'Uit selectie verwijderd';

  @override
  String get selectionTip =>
      'Al geselecteerd. Gebruik Selectie bewerken om bestanden te verwijderen.';

  @override
  String get selectionMore => 'Meer';

  @override
  String get selectionPreview => 'Selectie voorvertonen';

  @override
  String get previewOpen => 'Voorvertoning';

  @override
  String get previewSelect => 'Selecteren';

  @override
  String get previewSelected => 'Geselecteerd';

  @override
  String get previewRemove => 'Uit selectie verwijderen';

  @override
  String get previewPlay => 'Afspelen';

  @override
  String get previewDetails => 'Details';

  @override
  String get previewFileGone => 'Dit bestand bestaat niet meer';

  @override
  String get previewHeicUnsupported =>
      'HEIC kan op deze Android-versie niet worden voorvertoond';

  @override
  String previewDimensions(int width, int height) {
    return '$width × $height';
  }

  @override
  String previewTaken(String date) {
    return 'Gemaakt op $date';
  }

  @override
  String previewModified(String date) {
    return 'Gewijzigd op $date';
  }

  @override
  String get browseModeSameTime => 'Zelfde moment';

  @override
  String get sameTimeEmpty => 'Geen foto\'s op hetzelfde moment gemaakt';

  @override
  String sameTimeDayHeader(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groepen',
      one: '1 groep',
    );
    return '$date · $_temp0';
  }

  @override
  String sameTimeGroupTitle(int count, String start, String end) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden',
      one: '1 bestand',
    );
    return '$_temp0 · $start–$end';
  }

  @override
  String sameTimeMore(int count) {
    return '+$count meer';
  }

  @override
  String get sameTimeSelectGroup => 'Groep selecteren';

  @override
  String get settingsSameTimeWindow => 'Tijdvenster voor zelfde moment';

  @override
  String get settingsSameTimeWindowHelp =>
      'Bladeren → Zelfde moment groepeert foto\'s en video\'s die binnen zoveel seconden zijn gemaakt';

  @override
  String seconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconden',
      one: '1 seconde',
    );
    return '$_temp0';
  }

  @override
  String get fileMenuTooltip => 'Bestandsacties';

  @override
  String get fileMenuRename => 'Naam wijzigen';

  @override
  String get fileMenuDuplicate => 'Dupliceren';

  @override
  String get fileMenuCopyTo => 'Kopiëren naar…';

  @override
  String get fileMenuMoveTo => 'Verplaatsen naar…';

  @override
  String get fileMenuDelete => 'Verwijderen';

  @override
  String get selectionActionMove => 'Verplaatsen naar…';

  @override
  String get selectionActionCopy => 'Kopiëren naar…';

  @override
  String get selectionActionDuplicate => 'Dupliceren';

  @override
  String get selectionActionDelete => 'Verwijderen';

  @override
  String get renameFolderTitle => 'Mapnaam wijzigen';

  @override
  String get renameAction => 'Naam wijzigen';

  @override
  String get nameLabel => 'Naam';

  @override
  String get nameInvalid =>
      'Namen mogen niet leeg zijn, geen / \\ : * ? \" < > | bevatten en niet langer zijn dan 255 bytes';

  @override
  String get nameExists => 'Hier bestaat al iets met die naam';

  @override
  String opMovedSummary(int done, String folder) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '$done bestanden verplaatst naar $folder',
      one: '1 bestand verplaatst naar $folder',
    );
    return '$_temp0';
  }

  @override
  String opCopiedSummary(int done, String folder) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '$done bestanden gekopieerd naar $folder',
      one: '1 bestand gekopieerd naar $folder',
    );
    return '$_temp0';
  }

  @override
  String opDuplicatedSummary(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '$done bestanden gedupliceerd',
      one: '1 bestand gedupliceerd',
    );
    return '$_temp0';
  }

  @override
  String opRenamedSummary(String name) {
    return 'Naam gewijzigd in $name';
  }

  @override
  String opTrashedSummary(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '$done bestanden naar de prullenbak verplaatst',
      one: '1 bestand naar de prullenbak verplaatst',
    );
    return '$_temp0';
  }

  @override
  String opDeletedSummary(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '$done bestanden definitief verwijderd',
      one: '1 bestand definitief verwijderd',
    );
    return '$_temp0';
  }

  @override
  String opFailedSummary(int failed) {
    String _temp0 = intl.Intl.pluralLogic(
      failed,
      locale: localeName,
      other: '$failed mislukt',
      one: '1 mislukt',
    );
    return '$_temp0';
  }

  @override
  String opSkippedSummary(int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped overgeslagen',
      one: '1 overgeslagen',
    );
    return '$_temp0';
  }

  @override
  String opCancelledSummary(int done, int total) {
    return 'Gestopt: $done van $total klaar';
  }

  @override
  String opSkippedNeedAccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count bestanden overgeslagen (vereisen Toegang tot alle bestanden)',
      one: '1 bestand overgeslagen (vereist Toegang tot alle bestanden)',
    );
    return '$_temp0';
  }

  @override
  String get opUndone => 'Ongedaan gemaakt';

  @override
  String opUndoStopped(int done, int total) {
    return 'Ongedaan maken gestopt: $done van $total ongedaan gemaakt';
  }

  @override
  String get opUndoLast => 'Laatste bestandsactie ongedaan maken';

  @override
  String opUndoMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden bestaan niet meer en zijn niet ongedaan gemaakt',
      one: '1 bestand bestaat niet meer en is niet ongedaan gemaakt',
    );
    return '$_temp0';
  }

  @override
  String opSpaceRefused(String needed, String free) {
    return 'Niet genoeg ruimte ($needed nodig, $free vrij)';
  }

  @override
  String opFolderRenamed(String name) {
    return 'Mapnaam gewijzigd in $name';
  }

  @override
  String get collisionTitle => 'Naam al in gebruik';

  @override
  String collisionBody(String name, String folder) {
    return '$name bestaat al in $folder';
  }

  @override
  String get collisionReplace => 'Vervangen';

  @override
  String get collisionKeepBoth => 'Beide bewaren';

  @override
  String get collisionSkip => 'Overslaan';

  @override
  String get collisionApplyAll => 'Dit doen voor alle resterende';

  @override
  String progressMoving(int done, int total) {
    return '$done van $total verplaatsen';
  }

  @override
  String progressCopying(int done, int total) {
    return '$done van $total kopiëren';
  }

  @override
  String progressDeleting(int done, int total) {
    return '$done van $total verwijderen';
  }

  @override
  String progressUndoing(int done, int total) {
    return '$done van $total ongedaan maken';
  }

  @override
  String get progressWorking => 'Bezig…';

  @override
  String get permanentConfirmAction => 'Verwijderen';

  @override
  String get opPermanentConfirmTitle => 'Definitief verwijderen?';

  @override
  String opPermanentConfirmBody(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count bestanden ($size) definitief verwijderen? Dit kan niet ongedaan worden gemaakt.',
      one:
          '1 bestand ($size) definitief verwijderen? Dit kan niet ongedaan worden gemaakt.',
    );
    return '$_temp0';
  }

  @override
  String get pendingFallbackTitle => 'Kan de prullenbakmap niet gebruiken';

  @override
  String pendingFallbackBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Kan $count bestanden niet naar de prullenbakmap verplaatsen. In plaats daarvan definitief verwijderen?',
      one: 'Kan 1 bestand niet naar de prullenbakmap verplaatsen. In plaats daarvan definitief verwijderen?',
    );
    return '$_temp0';
  }

  @override
  String get pendingFallbackAction => 'Definitief verwijderen';

  @override
  String get pickerMoveTitle => 'Verplaatsen naar';

  @override
  String get pickerCopyTitle => 'Kopiëren naar';

  @override
  String get pickerAllFolders => 'Alle mappen';

  @override
  String get pickerMoveHere => 'Hierheen verplaatsen';

  @override
  String get pickerCopyHere => 'Hierheen kopiëren';

  @override
  String get pickerChooseHere => 'Deze map gebruiken';

  @override
  String get pickerCurrentFolder => 'Huidige map';

  @override
  String get browseNewFolder => 'Nieuwe map';

  @override
  String browseFolderCreated(String name) {
    return '$name gemaakt';
  }

  @override
  String get settingsFiles => 'Bestanden';

  @override
  String get settingsDropAction => 'Bestanden op een map neerzetten';

  @override
  String get dropActionMove => 'Verplaatst ze';

  @override
  String get dropActionCopy => 'Kopieert ze';

  @override
  String fileOpRenameFailed(String name) {
    return 'Kan naam van $name niet wijzigen';
  }

  @override
  String fileOpFailedGeneric(String name) {
    return 'Kan niet voltooien voor $name';
  }

  @override
  String fileOpNotFound(String name) {
    return '$name bestaat niet meer';
  }

  @override
  String fileOpPermission(String name) {
    return 'Geen toestemming om $name te wijzigen';
  }

  @override
  String progressCompressing(String done, String total) {
    return '$done van $total zippen';
  }

  @override
  String progressExtracting(String done, String total) {
    return '$done van $total uitpakken';
  }

  @override
  String progressEtaMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Nog ongeveer $minutes minuten',
      one: 'Nog ongeveer 1 minuut',
    );
    return '$_temp0';
  }

  @override
  String get archiveCompress => 'Comprimeren';

  @override
  String get archiveViewContents => 'Inhoud bekijken';

  @override
  String get archiveExtractHere => 'Hier uitpakken';

  @override
  String get archiveExtractTo => 'Uitpakken naar…';

  @override
  String get archiveExtractThis => 'Dit uitpakken';

  @override
  String get archiveExtractToTitle => 'Uitpakken naar';

  @override
  String get archiveCompressTitle => 'Comprimeren tot ZIP';

  @override
  String get archiveCompressAction => 'Comprimeren';

  @override
  String archiveSaveIn(String folder) {
    return 'Opgeslagen in $folder';
  }

  @override
  String get archiveSaveTo => 'Opslaan in…';

  @override
  String get archiveSaveToTitle => 'ZIP opslaan in';

  @override
  String get archiveWrongPlace =>
      'Bestanden van deze locatie kunnen nog niet worden gezipt';

  @override
  String archiveCreated(String name) {
    return '$name gemaakt';
  }

  @override
  String archiveExtracted(int count, String folder) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden uitgepakt naar $folder',
      one: '1 bestand uitgepakt naar $folder',
      zero: 'Niets om uit te pakken',
    );
    return '$_temp0';
  }

  @override
  String get archiveBombTitle => 'Zeer groot archief';

  @override
  String archiveBombBody(String size) {
    return 'Uitgepakt wordt dit archief $size. Toch uitpakken?';
  }

  @override
  String get archiveBombAction => 'Toch uitpakken';

  @override
  String get archiveUnsafePaths =>
      'Dit archief bevat onveilige paden en is niet uitgepakt';

  @override
  String get archiveCorrupt => 'Deze ZIP is beschadigd of geen ZIP-bestand';

  @override
  String get archiveCancelled => 'Gestopt. Er is niets opgeslagen';

  @override
  String archiveIoError(String name) {
    return 'Kan $name niet lezen of schrijven';
  }

  @override
  String get archivePasswordTitle => 'Wachtwoord vereist';

  @override
  String archivePasswordBody(String name) {
    return '$name is beveiligd met een wachtwoord';
  }

  @override
  String get archivePasswordLabel => 'Wachtwoord';

  @override
  String get archivePasswordAction => 'Uitpakken';

  @override
  String get archiveWrongPassword => 'Verkeerd wachtwoord, probeer het opnieuw';

  @override
  String get archivePasswordShow => 'Wachtwoord tonen';

  @override
  String get archivePasswordHide => 'Wachtwoord verbergen';

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
  String get archiveEmpty => 'Deze ZIP is leeg';

  @override
  String get archiveWrongDestination =>
      'Kan nog niet op deze locatie opslaan. Kies een map in de interne opslag';

  @override
  String archiveReplaceFailed(String name) {
    return 'De oude ZIP is bewaard. De nieuwe is opgeslagen als $name';
  }

  @override
  String get collectionsOpen => 'Tags en favorieten';

  @override
  String get collectionsTitle => 'Tags en favorieten';

  @override
  String get collectionsFavorites => 'Favorieten';

  @override
  String get collectionsTags => 'Tags';

  @override
  String get collectionsEmpty =>
      'Nog geen tags. Tag bestanden via Bladeren, of stel in de swipe-instellingen een richting in op “Tag toevoegen”.';

  @override
  String collectionsFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden',
      one: '1 bestand',
      zero: 'Geen bestanden',
    );
    return '$_temp0';
  }

  @override
  String get collectionsTagMenu => 'Tagopties';

  @override
  String get tagMenuEdit => 'Naam of kleur wijzigen';

  @override
  String get tagMenuDelete => 'Tag verwijderen';

  @override
  String get tagEditTitle => 'Tag bewerken';

  @override
  String get tagSave => 'Opslaan';

  @override
  String tagDeleteTitle(String name) {
    return 'Tag “$name” verwijderen?';
  }

  @override
  String tagDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'De $count bestanden blijven; alleen de tag wordt verwijderd.',
      one: 'Het bestand blijft; alleen de tag wordt verwijderd.',
      zero: 'Geen bestanden hebben deze tag.',
    );
    return '$_temp0';
  }

  @override
  String tagDeleteUsedIn(String places) {
    return 'Gebruikt in: $places. Die richting toont “Tag bestaat niet meer” totdat je een andere kiest.';
  }

  @override
  String get tagUsedCurrentSetup => 'huidige swipe-instelling';

  @override
  String get tagDeleteConfirm => 'Verwijderen';

  @override
  String tagDeleted(String name) {
    return 'Tag “$name” verwijderd';
  }

  @override
  String get tagGone => 'Deze tag is verwijderd';

  @override
  String get fileMenuFavoriteAdd => 'Aan favorieten toevoegen';

  @override
  String get fileMenuFavoriteRemove => 'Verwijderen uit favorieten';

  @override
  String get fileMenuTags => 'Tags…';

  @override
  String get selectionTagsMenu => 'Tags en favorieten…';

  @override
  String get selectionTagAdd => 'Tag toevoegen…';

  @override
  String get selectionTagRemove => 'Tag verwijderen…';

  @override
  String get tagRemoveTitle => 'Een tag verwijderen';

  @override
  String get tagRemoveNone => 'Geen van deze bestanden heeft tags';

  @override
  String get fileTagsTitle => 'Tags';

  @override
  String tagAddedSummary(int count, String tag) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden getagd met “$tag”',
      one: '1 bestand getagd met “$tag”',
      zero: 'Alle bestanden hadden “$tag” al',
    );
    return '$_temp0';
  }

  @override
  String tagRemovedSummary(int count, String tag) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '“$tag” verwijderd van $count bestanden',
      one: '“$tag” verwijderd van 1 bestand',
      zero: 'Geen bestand had “$tag”',
    );
    return '$_temp0';
  }

  @override
  String favoriteAddedSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden toegevoegd aan favorieten',
      one: '1 bestand toegevoegd aan favorieten',
      zero: 'Al in favorieten',
    );
    return '$_temp0';
  }

  @override
  String favoriteRemovedSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden verwijderd uit favorieten',
      one: '1 bestand verwijderd uit favorieten',
      zero: 'Niet in favorieten',
    );
    return '$_temp0';
  }

  @override
  String get tagWriteError =>
      'Kan de wijziging niet opslaan. Probeer het opnieuw';

  @override
  String get swipeSourceSelectionTitle => 'Geselecteerde bestanden';

  @override
  String get sameTimeSwipeGroup => 'Deze groep swipen';

  @override
  String get swipeSourceClose => 'Terug naar alle bestanden';

  @override
  String swipeSourceGroupPosition(
    int group,
    int groupCount,
    int index,
    int groupSize,
  ) {
    return 'Groep $group van $groupCount · $index/$groupSize';
  }

  @override
  String swipeSourceDone(String title) {
    return 'Alles klaar in $title';
  }

  @override
  String get swipeSourceBackToMain => 'Terug naar swipen';

  @override
  String swipeSourceBackToOrigin(String origin) {
    return 'Terug naar $origin';
  }

  @override
  String swipeSourceRestored(String title) {
    return 'Verder in $title';
  }

  @override
  String swipeSourcePendingLine(String title) {
    return 'Opent: $title';
  }

  @override
  String swipeSourceSkipped(int files, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files bestanden swipen',
      one: '1 bestand swipen',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped kunnen hier niet worden geswipet',
      one: '1 kan hier niet worden geswipet',
    );
    return '$_temp0 · $_temp1 (alleen foto\'s en video\'s)';
  }

  @override
  String get swipeSourceTruncated =>
      'De eerste 10.000 bestanden worden getoond';

  @override
  String get swipeSourceEmpty => 'Niets om hier te swipen';

  @override
  String get swipeSourceNoMedia =>
      'Alleen foto\'s en video\'s kunnen worden geswipet';

  @override
  String get swipeSourceInvalidFilter => 'Dit filter kan niet worden gebruikt';

  @override
  String get swipeSourceNoMatches => 'Geen foto\'s of video\'s gevonden';

  @override
  String get swipeSourceOriginStorage => 'Opslagoverzicht';

  @override
  String get swipeSourceOriginSimilar => 'Vergelijkbare foto\'s';

  @override
  String get swipeSourceOriginSearch => 'Zoeken';

  @override
  String get swipeSourceOriginGroups => 'Groepen';

  @override
  String get swipeSourceOriginSameTime => 'Zelfde moment';

  @override
  String get swipeSourceOriginBrowse => 'Bladeren';

  @override
  String get swipeSourceOriginSharedIn => 'Gedeelde bestanden';

  @override
  String get swipeSourceOriginCloud => 'Cloud';

  @override
  String get swipeSourceOriginExternal => 'Externe opslag';

  @override
  String get swipeSourceOriginOther => 'Vorig scherm';

  @override
  String get storageOverviewTitle => 'Opslagoverzicht';

  @override
  String storageUsedFree(String used, String free) {
    return '$used gebruikt · $free vrij';
  }

  @override
  String get storageSpaceUnknown => 'Vrije ruimte onbekend';

  @override
  String get storageScanning => 'Nog aan het scannen… de aantallen groeien nog';

  @override
  String get storageCatVideos => 'Video\'s';

  @override
  String get storageCatScreenshots => 'Screenshots';

  @override
  String storageCatBigFiles(String size) {
    return 'Grote bestanden (meer dan $size)';
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
      other: '$count bestanden · $size',
      one: '1 bestand · $size',
      zero: 'Geen bestanden',
    );
    return '$_temp0';
  }

  @override
  String get storageCleanUp => 'Opruimen';

  @override
  String get storageCleanUpMediaOnly =>
      'Opruimen toont alleen foto\'s en video\'s';

  @override
  String get storageNeedsAccess =>
      'Zet Toegang tot alle bestanden aan om deze bestanden te zien';

  @override
  String get storageOverlapNote =>
      'Een bestand kan in meer dan één categorie staan.';

  @override
  String get storageBiggestFiles => 'Grootste bestanden';

  @override
  String get storageWhatsappHint =>
      'Inclusief de verborgen mappen Sent en Status van WhatsApp';

  @override
  String get storageBigFileThreshold => 'Grote bestanden vanaf';

  @override
  String get similarTitle => 'Vergelijkbare foto\'s';

  @override
  String get similarSourceTitle => 'Vergelijkbare foto\'s';

  @override
  String get similarStorageHint => 'Gelijkende en wazige foto\'s';

  @override
  String get similarTabSimilar => 'Vergelijkbaar';

  @override
  String get similarTabBlurry => 'Wazig';

  @override
  String get similarStartTitle => 'Vergelijkbare en wazige foto\'s zoeken';

  @override
  String get similarStartBody =>
      'KFM controleert je foto\'s op deze telefoon, groepeert gelijkende foto\'s en stelt de scherpste voor om te bewaren. Er verlaat niets de telefoon en er wordt niets verwijderd tenzij jij dat kiest.';

  @override
  String get similarStart => 'Starten';

  @override
  String similarChecking(int done, int total) {
    return 'Foto\'s controleren… $done van $total';
  }

  @override
  String get similarGrouping => 'Gelijkende foto\'s groeperen…';

  @override
  String get similarNoGroups => 'Nog geen vergelijkbare foto\'s gevonden';

  @override
  String get similarNoBlurry => 'Geen wazige foto\'s gevonden';

  @override
  String similarGroupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto\'s',
      one: '1 foto',
    );
    return '$_temp0';
  }

  @override
  String get similarBest => 'Beste';

  @override
  String get similarKeepBest => 'Beste bewaren, rest verwijderen';

  @override
  String get similarSwipeGroup => 'Deze groep swipen';

  @override
  String get similarSwipeAll => 'Alle groepen swipen';

  @override
  String get similarCleanDuplicates => 'Duplicaten opruimen';

  @override
  String similarRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto\'s verwijderd',
      one: '1 foto verwijderd',
    );
    return '$_temp0';
  }

  @override
  String get similarKeptAll => 'Alle foto\'s bewaard';

  @override
  String get similarBlurryHint =>
      'Tik om te kiezen, houd ingedrukt om te bekijken';

  @override
  String similarRemoveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verwijderen',
      zero: 'Verwijderen',
    );
    return '$_temp0';
  }

  @override
  String similarCleanProgress(int group, int total, int keep) {
    return 'Groep $group van $total · $keep bewaren';
  }

  @override
  String get similarCleanDone => 'Alle groepen klaar';

  @override
  String get similarSkip => 'Overslaan';

  @override
  String get similarNextGroup => 'Volgende groep';

  @override
  String get similarKeep => 'Bewaren';

  @override
  String get similarRemove => 'Verwijderen';

  @override
  String get similarSettingEnabled => 'Vergelijkbare en wazige foto\'s zoeken';

  @override
  String get similarSettingEnabledHint =>
      'Controleert foto\'s op de achtergrond terwijl KFM open is';

  @override
  String get similarSettingStrictness => 'Hoe gelijk';

  @override
  String get similarStrictnessLoose => 'Enigszins gelijk';

  @override
  String get similarStrictnessNormal => 'Normaal';

  @override
  String get similarStrictnessStrict => 'Bijna identiek';

  @override
  String get similarSettingScreenshots => 'Screenshots meenemen';

  @override
  String get groupsTitle => 'Groepen';

  @override
  String get groupsScreenshots => 'Screenshots';

  @override
  String get groupsSelfies => 'Selfies (automatisch)';

  @override
  String get groupsDocuments => 'Documenten';

  @override
  String get groupsTrips => 'Reizen';

  @override
  String get groupsPlaces => 'Plaatsen';

  @override
  String smartGroupPlace(int n) {
    return 'Plaats $n';
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
      other: '$count bestanden',
      one: '1 bestand',
    );
    return '$_temp0';
  }

  @override
  String groupsProgress(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Reizen en plaatsen zoeken… $done van $total foto\'s',
      one: 'Reizen en plaatsen zoeken… $done van 1 foto',
    );
    return '$_temp0';
  }

  @override
  String get groupsGrouping => 'Reizen en plaatsen groeperen…';

  @override
  String get groupsEmpty =>
      'Nog geen groepen. Reizen en plaatsen verschijnen hier zodra KFM ze vindt.';

  @override
  String get groupsRename => 'Naam wijzigen';

  @override
  String get groupsRenameHint => 'Laat leeg voor de automatische naam';

  @override
  String get groupsRenameSave => 'Opslaan';

  @override
  String get groupsRenameCancel => 'Annuleren';

  @override
  String get groupsChanged => 'Deze groep is gewijzigd';

  @override
  String get groupsChangedBody =>
      'Reizen en plaatsen worden opnieuw berekend als er foto\'s bijkomen of verdwijnen.';

  @override
  String get groupsBack => 'Terug naar groepen';

  @override
  String get groupsSwipe => 'Deze groep swipen';

  @override
  String get groupsLocationRow =>
      'Sta locatietoegang toe om foto\'s op plaats te groeperen';

  @override
  String get groupsOnlineNames => 'Plaatsnamen online opzoeken';

  @override
  String get groupsOnlineNamesHelp =>
      'Stuurt het geschatte midden van elke plaatsgroep naar de geocodeerdienst van je telefoon om namen als \'Parijs\' te krijgen';

  @override
  String get groupsJobError =>
      'Kan de groepen niet bijwerken. Het wordt later opnieuw geprobeerd.';

  @override
  String groupsFailedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto\'s konden niet worden gelezen',
      one: '1 foto kon niet worden gelezen',
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
  String get aiLabelsTitle => 'Fotolabels (AI)';

  @override
  String get aiLabelsEnable => 'Foto\'s labelen op deze telefoon';

  @override
  String get aiLabelsEnableHint =>
      'Vind foto\'s op wat erop staat, zoals kat, strand of eten';

  @override
  String get aiLabelsEnableNeedsModels => 'Download eerst de AI-modellen';

  @override
  String get aiLabelsPause => 'Labelen pauzeren';

  @override
  String get aiLabelsResume => 'Labelen hervatten';

  @override
  String get aiLabelsPausedLine => 'Labelen is gepauzeerd';

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
      other: '$processedString van $totalString foto\'s gelabeld',
      one: '$processedString van 1 foto gelabeld',
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
      other: '$countString foto\'s konden niet worden gelabeld',
      one: '1 foto kon niet worden gelabeld',
    );
    return '$_temp0';
  }

  @override
  String get aiLabelsReset => 'Labels resetten';

  @override
  String get aiLabelsResetConfirm => 'Alle fotolabels resetten?';

  @override
  String get aiLabelsResetConfirmBody =>
      'Elke foto wordt opnieuw vanaf het begin gelabeld.';

  @override
  String get aiLabelsResetAction => 'Resetten';

  @override
  String get aiLabelsHelp =>
      'Werkt alleen op deze telefoon. Geen enkele foto of uitkomst verlaat het apparaat.';

  @override
  String get aiLabelsJobError =>
      'De AI-modellen ontbreken of zijn gewijzigd, dus het labelen is gestopt. Download ze opnieuw.';

  @override
  String get aiLabelsWorkerError =>
      'Labelen kan niet starten op deze telefoon.';

  @override
  String get aiLabelsCrashError =>
      'Labelen is gestopt na een fout. Het wordt later opnieuw geprobeerd.';

  @override
  String get aiLabelsNeedsAndroid8 => 'Vereist Android 8 of nieuwer';

  @override
  String get aiLabelsUnsupported => 'Nog niet beschikbaar op dit apparaat';

  @override
  String get aiLabelsCardTitle =>
      'Vind foto\'s op wat erop staat (kat, strand, eten…)';

  @override
  String get aiLabelsCardBody =>
      'KFM kan je foto\'s labelen op deze telefoon. Er wordt niets geüpload.';

  @override
  String get aiLabelsCardTurnOn => 'Aanzetten';

  @override
  String get aiLabelsCardNotNow => 'Niet nu';

  @override
  String get aiLabelsTurnedOn => 'Foto\'s labelen staat aan';

  @override
  String get aiCancel => 'Annuleren';

  @override
  String get aiModelsTitle => 'AI-modellen';

  @override
  String get aiModelsNotDownloaded => 'AI-modellen niet gedownload';

  @override
  String get aiModelsAbout => 'Over AI-modellen / Downloaden…';

  @override
  String get aiModelsChecking => 'AI-modellen controleren…';

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

    return '$doneString van $totalString MB downloaden';
  }

  @override
  String get aiModelsWaitingWifi => 'Wachten op Wi-Fi';

  @override
  String get aiModelsVerifying => 'Download controleren…';

  @override
  String aiModelsInstalled(double size) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String sizeString = sizeNumberFormat.format(size);

    return 'Geïnstalleerd, $sizeString MB';
  }

  @override
  String get aiModelsNeedUpdate =>
      'AI-modellen hebben een update nodig — download opnieuw';

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

    return 'Download gepauzeerd bij $doneString van $totalString MB';
  }

  @override
  String get aiModelsErrorNetwork => 'Download mislukt: geen verbinding.';

  @override
  String aiModelsErrorHttp(String code) {
    return 'Download mislukt (serverfout $code).';
  }

  @override
  String get aiModelsErrorChecksum =>
      'Het gedownloade bestand kwam niet overeen met het verwachte bestand. Het is verwijderd en er is niets geïnstalleerd.';

  @override
  String get aiModelsErrorDiskFull =>
      'Download mislukt: niet genoeg vrije ruimte.';

  @override
  String get aiModelsErrorOther => 'Download mislukt.';

  @override
  String get aiModelsRetry => 'Opnieuw proberen';

  @override
  String get aiModelsCancel => 'Download annuleren';

  @override
  String get aiModelsWifiOnly => 'Alleen via Wi-Fi downloaden';

  @override
  String get aiModelsUseMobileData => 'Deze keer mobiele data gebruiken';

  @override
  String get aiModelsWillUseWifi => 'Wordt via Wi-Fi gedownload';

  @override
  String get aiModelsRemove => 'AI-modellen verwijderen';

  @override
  String aiModelsRemoveTitle(double size) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String sizeString = sizeNumberFormat.format(size);

    return 'AI-modellen verwijderen ($sizeString MB)?';
  }

  @override
  String get aiModelsRemoveBody =>
      'Nieuwe foto\'s worden niet meer gelabeld. Je kunt de modellen later opnieuw downloaden.';

  @override
  String get aiModelsRemoveAlsoLabels => 'Ook de fotolabels verwijderen';

  @override
  String get aiModelsRemoveConfirm => 'Verwijderen';

  @override
  String get aiModelsDetailsIntro =>
      'KFM kan je foto\'s labelen (kat, strand, eten, persoon…) zodat je ze kunt vinden op wat erop staat. Hiervoor zijn twee kleine AI-modellen nodig die niet in de app zitten. Ze worden alleen gedownload als je op Downloaden tikt.';

  @override
  String get aiModelsHowTitle => 'Hoe het werkt';

  @override
  String get aiModelsHowBody =>
      'De kleine miniatuur van elke foto wordt één keer op deze telefoon geanalyseerd, op de achtergrond. Alleen labelwoorden zoals \"kat\" worden opgeslagen in de database van KFM.';

  @override
  String get aiModelsPrivacyTitle => 'Privacy';

  @override
  String get aiModelsPrivacyBody =>
      'Werkt volledig op dit apparaat. Geen enkele foto, miniatuur of uitkomst verlaat de telefoon. Geen account, geen tracking. Het enige netwerkgebruik is deze ene download.';

  @override
  String get aiModelsBatteryBody =>
      'Labelen gebeurt terwijl KFM open is en pauzeert als de batterij onder 20% zit en niet oplaadt.';

  @override
  String get aiModelsRemovableBody =>
      'Je kunt de modellen altijd verwijderen in Instellingen.';

  @override
  String aiModelsDownloadButton(double size) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String sizeString = sizeNumberFormat.format(size);

    return 'Downloaden ($sizeString MB)';
  }

  @override
  String get aiModelsInstalledDone =>
      'AI-modellen geïnstalleerd. Labelen staat aan.';

  @override
  String get aiModelClassifierWhat =>
      'Beeldclassificatie: herkent zo\'n 1000 soorten objecten, dieren, eten en scènes.';

  @override
  String get aiModelClassifierUse =>
      'KFM gebruikt dit voor labels zoals kat, hond, vogel, eten, strand, berg, auto en document.';

  @override
  String get aiModelDetectorWhat =>
      'Objectdetectie: vindt mensen (en telt ze), huisdieren, voertuigen en eten.';

  @override
  String get aiModelDetectorUse =>
      'KFM gebruikt dit voor labels zoals persoon, menigte, kat, hond, auto en eten.';

  @override
  String aiModelSize(double size) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String sizeString = sizeNumberFormat.format(size);

    return 'Downloadgrootte: $sizeString MB';
  }

  @override
  String aiModelPublisher(String publisher) {
    return 'Uitgever: $publisher';
  }

  @override
  String aiModelLicence(String licence) {
    return 'Licentie: $licence';
  }

  @override
  String aiModelSource(String url) {
    return 'Gedownload van: $url';
  }

  @override
  String aiModelOriginal(String url) {
    return 'Originele release: $url';
  }

  @override
  String get aiModelsLicences => 'Licenties bekijken';

  @override
  String get aboutLicences => 'Opensourcelicenties';

  @override
  String searchChipLabel(String label) {
    return 'Inhoud: $label';
  }

  @override
  String get searchChipBlurry => 'Wazige foto\'s';

  @override
  String searchStillLabeling(double percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.percentPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return 'Foto\'s worden nog gelabeld ($percentString) — resultaten kunnen onvolledig zijn';
  }

  @override
  String get searchLabelingOff =>
      'Zet foto\'s labelen aan om op inhoud te zoeken';

  @override
  String get searchLabelingOffTurnOn => 'Aanzetten';

  @override
  String get searchContentWordsLoadError =>
      'Kan de zoekwoorden voor inhoud niet laden';

  @override
  String get fileMenuDetails => 'Details';

  @override
  String get selectionActionDetails => 'Details';

  @override
  String get detailsSheetLabel => 'Bestandsdetails';

  @override
  String get detailsLoading => 'Details laden';

  @override
  String get detailsPartial => 'Kan sommige details niet lezen';

  @override
  String get detailsGone => 'Dit bestand bestaat niet meer';

  @override
  String get detailsWhatIsThis => 'Wat is dit?';

  @override
  String get detailsHintUsually =>
      'Meestal niet nodig, maar controleer het voordat je het verwijdert';

  @override
  String get detailsHintCareful => 'Let op: verwijderen kan gegevens kosten';

  @override
  String get detailsCameFrom => 'Afkomstig van';

  @override
  String detailsSavedBy(String app) {
    return 'Opgeslagen door $app';
  }

  @override
  String detailsInSourceFolder(String source) {
    return 'In de map $source';
  }

  @override
  String detailsNotInstalled(String package) {
    return '$package (niet geïnstalleerd)';
  }

  @override
  String detailsDownloadedFrom(String host) {
    return 'Gedownload van $host';
  }

  @override
  String detailsLinkedFrom(String host) {
    return 'Link stond op $host';
  }

  @override
  String get detailsShowFullAddress => 'Tik om het volledige adres te tonen';

  @override
  String detailsTakenWith(String camera) {
    return 'Gemaakt met $camera';
  }

  @override
  String detailsEditedWith(String app) {
    return 'Gemaakt of bewerkt met $app';
  }

  @override
  String get detailsWhere => 'Waar';

  @override
  String get detailsPath => 'Pad';

  @override
  String get detailsCopyPath => 'Pad kopiëren';

  @override
  String get detailsPathCopied => 'Pad gekopieerd';

  @override
  String get detailsStorage => 'Opslag';

  @override
  String get detailsStorageInternal => 'Interne opslag';

  @override
  String get detailsStorageRemovable => 'SD-kaart of USB-stick';

  @override
  String get detailsHidden => 'Verborgen';

  @override
  String get detailsOpenFolder => 'Map openen';

  @override
  String get detailsFileSection => 'Bestand';

  @override
  String get detailsType => 'Type';

  @override
  String detailsTypeValue(String mime, String ext) {
    return '$mime (.$ext)';
  }

  @override
  String detailsTypeUnknown(String ext) {
    return 'Onbekend bestandstype (.$ext)';
  }

  @override
  String get detailsTypeUnknownNoExt => 'Onbekend bestandstype';

  @override
  String get detailsSize => 'Grootte';

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
  String get detailsModified => 'Gewijzigd';

  @override
  String get detailsAdded => 'Toegevoegd aan telefoon';

  @override
  String get detailsTaken => 'Gemaakt';

  @override
  String get detailsDimensions => 'Afmetingen';

  @override
  String get detailsDuration => 'Duur';

  @override
  String get detailsCameraSettings => 'Camera-instellingen';

  @override
  String get detailsLens => 'Lens';

  @override
  String get detailsDescription => 'Beschrijving';

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
  String get detailsLocation => 'Locatie';

  @override
  String detailsLatLng(String lat, String lng) {
    return '$lat, $lng';
  }

  @override
  String get detailsInKfm => 'In KFM';

  @override
  String get detailsTags => 'Tags';

  @override
  String get detailsFavorite => 'Favoriet';

  @override
  String detailsReviewed(String date) {
    return 'Bekeken op $date';
  }

  @override
  String get detailsAppInfo => 'App-info';

  @override
  String get detailsAppInfoFailed => 'Kan App-info niet openen';

  @override
  String detailsSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden',
      one: '1 bestand',
    );
    return '$_temp0';
  }

  @override
  String get detailsSummaryTotal => 'Totale grootte';

  @override
  String get detailsSummaryKinds => 'Soorten';

  @override
  String detailsSummaryKindCount(String kind, int count) {
    return '$kind: $count';
  }

  @override
  String get detailsSummaryOldest => 'Oudste';

  @override
  String get detailsSummaryNewest => 'Nieuwste';

  @override
  String get detailsSummaryFolders => 'Mappen';

  @override
  String detailsSummaryFolderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count mappen',
      one: 'In 1 map',
    );
    return '$_temp0';
  }

  @override
  String detailsSummaryMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count geselecteerde bestanden staan niet meer in de index',
      one: '1 geselecteerd bestand staat niet meer in de index',
    );
    return '$_temp0';
  }

  @override
  String get connectSettingsTitle => 'Apparaat verbinden';

  @override
  String get connectShareThisDevice => 'Dit apparaat delen';

  @override
  String get connectShareThisDeviceHint =>
      'Laat een telefoon of pc op hetzelfde Wi-Fi-netwerk verbinding maken met dit apparaat';

  @override
  String get connectToDevice => 'Verbinden met een apparaat';

  @override
  String get connectToDeviceHint => 'Scan een QR-code of typ een code';

  @override
  String get connectChooseHint =>
      'Open op het andere apparaat Instellingen → Apparaat verbinden → Dit apparaat delen.';

  @override
  String get connectScanQr => 'QR-code scannen';

  @override
  String get connectScanQrHint =>
      'Richt de camera op de code op het andere apparaat';

  @override
  String get connectTypeCode => 'Code typen';

  @override
  String get connectTypeCodeHint => 'Voor een pc, of als er geen camera is';

  @override
  String get connectCameraDenied =>
      'KFM heeft de camera nodig om de code te scannen. Je kunt de code ook typen.';

  @override
  String get connectOpenSettings => 'Instellingen openen';

  @override
  String get connectAllowCamera => 'Camera toestaan';

  @override
  String get connectNotKfmCode => 'Geen KFM-code';

  @override
  String get connectUpdateKfm => 'Update KFM op beide apparaten';

  @override
  String get connectDebugPasteLabel => 'Koppellink (alleen debugbuilds)';

  @override
  String get connectDebugPasteGo => 'Link gebruiken';

  @override
  String get connectNearbyTitle => 'Apparaten in de buurt';

  @override
  String get connectNearbySearching =>
      'Zoeken naar apparaten die delen op deze Wi-Fi…';

  @override
  String get connectNearbyFailed =>
      'Kan niet zoeken op deze Wi-Fi. Voer in plaats daarvan het adres in dat op het andere apparaat staat.';

  @override
  String get connectEnterAddress => 'Adres invoeren';

  @override
  String get connectAddressLabel => 'Adres op het andere apparaat';

  @override
  String get connectAddressInvalid => 'Voer het zo in: 192.168.1.23:48211';

  @override
  String connectHostPort(String host, int port) {
    return '$host:$port';
  }

  @override
  String get connectNext => 'Volgende';

  @override
  String connectCodeFor(String name) {
    return 'Typ de code die op $name staat';
  }

  @override
  String get connectCodeForAddress =>
      'Typ de code die op het andere apparaat staat';

  @override
  String get connectCodeLabel => 'Code';

  @override
  String get connectCodeInvalidChar => 'Alleen letters en cijfers';

  @override
  String get connectConnect => 'Verbinden';

  @override
  String get connectCancel => 'Annuleren';

  @override
  String get connectConnecting => 'Verbinden…';

  @override
  String connectWaiting(String name) {
    return 'Wachten tot $name accepteert…';
  }

  @override
  String connectConnected(String name) {
    return 'Verbonden met $name';
  }

  @override
  String get connectDisconnect => 'Verbinding verbreken';

  @override
  String get connectTryAgain => 'Opnieuw proberen';

  @override
  String get connectBack => 'Terug';

  @override
  String get connectOtherDevice => 'het andere apparaat';

  @override
  String get connectErrorUnreachable =>
      'De apparaten kunnen elkaar niet bereiken op deze Wi-Fi. Probeer een hotspot.';

  @override
  String connectErrorWrongDevice(String name) {
    return 'Dit is niet $name.';
  }

  @override
  String connectErrorWrongCode(String name) {
    return 'Verkeerde code, of dit is niet $name. Controleer de code en probeer het opnieuw.';
  }

  @override
  String get connectErrorSecretUsed => 'Code al gebruikt';

  @override
  String get connectErrorExpired => 'Deze code is verlopen. Scan de nieuwe.';

  @override
  String get connectErrorTooMany =>
      'Te veel pogingen. Wacht even en probeer het dan opnieuw.';

  @override
  String connectErrorBusy(String name) {
    return '$name is bezig met een ander verzoek. Probeer het zo opnieuw.';
  }

  @override
  String connectErrorDeclined(String name) {
    return '$name heeft de verbinding geweigerd.';
  }

  @override
  String connectErrorTimedOut(String name) {
    return 'Geen antwoord van $name.';
  }

  @override
  String get connectErrorCancelled => 'Verzoek geannuleerd';

  @override
  String get connectErrorFailed => 'Koppelen is mislukt. Probeer het opnieuw.';

  @override
  String connectErrorNetwork(String name) {
    return 'De verbinding met $name is verbroken.';
  }

  @override
  String connectErrorBadResponse(String name) {
    return '$name antwoordde niet zoals KFM. Update KFM op beide apparaten.';
  }

  @override
  String get shareTitle => 'Dit apparaat delen';

  @override
  String get sharePreparing => 'Voorbereiden…';

  @override
  String get shareSharing => 'Delen';

  @override
  String shareSharingAs(String name) {
    return 'Apparaten op dezelfde Wi-Fi kunnen verbinden met ‘$name’.';
  }

  @override
  String get shareKeepOpen =>
      'Delen stopt als je dit scherm of de app verlaat.';

  @override
  String get shareStop => 'Stoppen met delen';

  @override
  String get shareStopped => 'Delen gestopt';

  @override
  String get shareStartAgain => 'Opnieuw delen';

  @override
  String get shareNoNetwork =>
      'Maak verbinding met Wi-Fi of zet een hotspot aan';

  @override
  String get shareNoNetworkHint =>
      'Beide apparaten moeten op dezelfde Wi-Fi zitten, of het ene moet de hotspot van het andere gebruiken.';

  @override
  String get shareFailed => 'Kan delen niet starten';

  @override
  String get shareRetry => 'Opnieuw proberen';

  @override
  String shareDebugAddress(String address, int port) {
    return '$address:$port';
  }

  @override
  String shareDebugFingerprint(String fingerprint) {
    return 'Vingerafdruk: $fingerprint';
  }

  @override
  String get shareQrHint => 'Scan dit met KFM op het andere apparaat';

  @override
  String get shareQrSemantics => 'QR-code om te koppelen';

  @override
  String shareExpiresIn(String time) {
    return 'Nieuwe code over $time';
  }

  @override
  String get shareTypeCodeTitle => 'Geen camera? Typ deze code';

  @override
  String shareAddress(String address) {
    return 'Adres: $address';
  }

  @override
  String shareCodeCooldown(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other:
          'Te veel verkeerde pogingen. Getypte codes werken weer over $seconds seconden.',
      one: 'Te veel verkeerde pogingen. Getypte codes werken weer over 1 seconde.',
    );
    return '$_temp0';
  }

  @override
  String get shareTypedCodesOff =>
      'Getypte codes staan voorlopig uit. Scan de QR-code, of stop met delen en start opnieuw.';

  @override
  String get shareRotatedLocked =>
      'Te veel verkeerde pogingen. Nieuwe code gemaakt';

  @override
  String get sharePrivacyNote =>
      'Tijdens het delen zien apparaten op deze Wi-Fi de naam van dit apparaat.';

  @override
  String get shareDiscoveryFailed =>
      'Apparaten in de buurt zien dit apparaat niet. Ze kunnen in plaats daarvan het adres invoeren.';

  @override
  String get devResetIdentity => 'Apparaat-ID resetten';

  @override
  String get devResetIdentityDone => 'Nieuwe apparaat-ID gemaakt';

  @override
  String get pairCompareWords =>
      'Controleer of beide apparaten deze woorden tonen';

  @override
  String connectNoFoldersYet(String name) {
    return '$name heeft nog geen mappen gedeeld';
  }

  @override
  String connectFoldersShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gedeelde mappen',
      one: '1 gedeelde map',
    );
    return '$_temp0';
  }

  @override
  String connectDisconnected(String name) {
    return 'Verbinding met $name verbroken';
  }

  @override
  String acceptTitle(String name) {
    return '$name wil verbinden';
  }

  @override
  String acceptTitleRemembered(String name) {
    return '$name (onthouden) wil verbinden';
  }

  @override
  String acceptPlatform(String platform) {
    return 'Type apparaat: $platform';
  }

  @override
  String acceptAutoDecline(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Wordt over $seconds seconden vanzelf geweigerd',
      one: 'Wordt over 1 seconde vanzelf geweigerd',
    );
    return '$_temp0';
  }

  @override
  String get acceptDecline => 'Weigeren';

  @override
  String get acceptAccept => 'Accepteren';

  @override
  String get acceptRequestCancelled => 'Verzoek geannuleerd';

  @override
  String get acceptTimedOut =>
      'Niet op tijd beantwoord. Het verzoek is geweigerd.';

  @override
  String shareConnectedTo(String name) {
    return 'Verbonden: $name';
  }

  @override
  String get shareDisconnectClient => 'Verbinding verbreken';

  @override
  String get sharedFoldersTitle => 'Gedeelde mappen';

  @override
  String sharedFoldersFor(String name) {
    return 'Mappen die $name kan zien';
  }

  @override
  String get sharedFoldersHint =>
      'Er wordt niets gedeeld tot je een map kiest. Gedeelde mappen zijn alleen-lezen, tenzij je wijzigingen toestaat.';

  @override
  String get sharedFoldersMediaOnly =>
      'Zonder toegang tot alle bestanden kun je alleen fotomappen delen.';

  @override
  String get sharedFolderCamera => 'Camera';

  @override
  String get sharedFolderPictures => 'Afbeeldingen';

  @override
  String get sharedFolderScreenshots => 'Screenshots';

  @override
  String get sharedFolderDownloads => 'Downloads';

  @override
  String get sharedFolderDocuments => 'Documenten';

  @override
  String get sharedFolderAllStorage => 'Alle opslag';

  @override
  String get sharedFolderAllowChanges =>
      'Wijzigingen toestaan (verplaatsen, naam wijzigen, verwijderen, uploaden)';

  @override
  String get sharedFoldersChoose => 'Map kiezen…';

  @override
  String get sharedFoldersDone => 'Klaar';

  @override
  String get sharedFoldersWholeStorageTitle => 'Al je bestanden delen?';

  @override
  String get sharedFoldersWholeStorageBody =>
      'Het andere apparaat ziet al je bestanden.';

  @override
  String get sharedFoldersWholeStorageConfirm => 'Alles delen';

  @override
  String get folderChooserTitle => 'Kies een map';

  @override
  String get folderChooserShareThis => 'Deze map delen';

  @override
  String get folderChooserEmpty => 'Geen submappen';

  @override
  String get folderChooserError => 'Kan deze map niet openen';

  @override
  String shareClientFolders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gedeelde mappen',
      one: '1 gedeelde map',
      zero: 'Geen mappen gedeeld',
    );
    return '$_temp0';
  }

  @override
  String connectDisconnectedStopped(String name) {
    return '$name is gestopt met delen.';
  }

  @override
  String connectDisconnectedNetwork(String name) {
    return 'Verbinding met $name verbroken. Controleer of beide apparaten op dezelfde Wi-Fi zitten.';
  }

  @override
  String get shareKeepOpenDesktop => 'Delen stopt als je dit scherm verlaat.';

  @override
  String get shareKeepsRunning =>
      'Delen gaat door als je de app verlaat. Stop het hier of via de melding.';

  @override
  String get transferChecking => 'Nakijken…';

  @override
  String shareClientGone(String name) {
    return 'Niet meer verbonden: $name';
  }

  @override
  String get shareKeepsRunningNoNotification =>
      'Delen gaat door als je de app verlaat. Meldingen staan uit voor KFM, dus kom hier terug om het te stoppen.';

  @override
  String get shareStopConfirmTitle => 'Stoppen met delen?';

  @override
  String get shareStopConfirmBody =>
      'Er worden nog bestanden verstuurd of ontvangen. Als je nu stopt, worden ze onderbroken; ze gaan verder als je weer deelt.';

  @override
  String get shareKeepSharing => 'Blijven delen';

  @override
  String get shareNotificationChannel => 'Apparaat delen';

  @override
  String get shareNotificationWaiting => 'Dit apparaat wordt gedeeld';

  @override
  String shareNotificationWith(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: 'Gedeeld met $name en $others andere',
      zero: 'Gedeeld met $name',
    );
    return '$_temp0';
  }

  @override
  String get shareNotificationText =>
      'Apparaten op dezelfde Wi-Fi kunnen verbinden. Tik om KFM te openen.';

  @override
  String get shareNotificationStop => 'Stoppen';

  @override
  String get remoteNotConnected => 'Het andere apparaat is niet verbonden';

  @override
  String remoteBrowseAction(String device) {
    return 'Bladeren op $device';
  }

  @override
  String get remoteBrowseRoots => 'Gedeelde mappen';

  @override
  String get remoteReadOnly => 'Alleen-lezen';

  @override
  String remoteDeviceNotConnected(String device) {
    return '$device is niet verbonden';
  }

  @override
  String get remoteReconnect => 'Opnieuw verbinden';

  @override
  String get remoteFileGone => 'Dit bestand is niet meer beschikbaar';

  @override
  String remoteNotAllowed(String device) {
    return 'Niet toegestaan op $device';
  }

  @override
  String remoteDeclined(String device) {
    return '$device heeft geweigerd';
  }

  @override
  String remoteDeleteDeclined(String device) {
    return '$device heeft het verwijderen geweigerd';
  }

  @override
  String get remoteEmptyFolder => 'Geen bestanden hier';

  @override
  String remoteShowingFirst(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eerste $count bestanden worden getoond',
      one: 'Eerste bestand wordt getoond',
    );
    return '$_temp0';
  }

  @override
  String remoteTrashConfirm(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden naar de prullenbak op $device verplaatsen?',
      one: '1 bestand naar de prullenbak op $device verplaatsen?',
    );
    return '$_temp0';
  }

  @override
  String remoteTrashConfirmHint(String device) {
    return '$device vraagt misschien om bevestiging.';
  }

  @override
  String remoteTrashed(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden naar de prullenbak op $device verplaatst',
      one: '1 bestand naar de prullenbak op $device verplaatst',
    );
    return '$_temp0';
  }

  @override
  String remoteMoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden verplaatst',
      one: '1 bestand verplaatst',
    );
    return '$_temp0';
  }

  @override
  String remoteCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden gekopieerd',
      one: '1 bestand gekopieerd',
    );
    return '$_temp0';
  }

  @override
  String remoteSomeFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden konden niet worden gewijzigd',
      one: '1 bestand kon niet worden gewijzigd',
    );
    return '$_temp0';
  }

  @override
  String remotePickFolderTitle(String device) {
    return 'Kies een map op $device';
  }

  @override
  String get remotePickHere => 'Deze map kiezen';

  @override
  String get remoteConnectedDevice => 'Verbonden apparaat';

  @override
  String remoteTrashRequest(String device, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden',
      one: '1 bestand',
    );
    return '$device wil $_temp0 naar de prullenbak verplaatsen';
  }

  @override
  String remoteTrashDone(String device, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden',
      one: '1 bestand',
    );
    return '$device heeft $_temp0 naar de prullenbak verplaatst';
  }

  @override
  String remoteTrashDeclinedByYou(String device) {
    return 'Je hebt het verzoek van $device geweigerd';
  }

  @override
  String remoteWriteRequest(String device, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden',
      one: '1 bestand',
    );
    return '$device wil $_temp0 wijzigen';
  }

  @override
  String get shareMediaOnlyHint =>
      'Zonder toegang tot alle bestanden zien andere apparaten alleen foto\'s, video\'s en audio.';

  @override
  String get rememberThisDevice => 'Dit apparaat onthouden';

  @override
  String get acceptAlwaysAllow => 'Dit apparaat altijd toestaan';

  @override
  String get acceptAlwaysAllowHint =>
      'De volgende keer verbindt het zonder te vragen';

  @override
  String shareAutoAccepted(String name) {
    return '$name is verbonden';
  }

  @override
  String shareRememberedFolders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mappen',
      one: '1 map',
    );
    return '$_temp0 gedeeld';
  }

  @override
  String get shareFoldersMissing => 'Sommige gedeelde mappen bestaan niet meer';

  @override
  String get shareFoldersChange => 'Wijzigen';

  @override
  String connectErrorKeyChanged(String name) {
    return '$name is veranderd. Scan de QR-code opnieuw.';
  }

  @override
  String get connectErrorNotAllowed =>
      'Niet toegestaan. Scan de QR-code opnieuw.';

  @override
  String connectErrorOffline(String name) {
    return 'Kan $name niet bereiken. Open \'Dit apparaat delen\' op $name.';
  }

  @override
  String get rememberedDevicesTitle => 'Onthouden apparaten';

  @override
  String get rememberedDevicesHint =>
      'Opnieuw verbinden zonder scannen, of een apparaat vergeten';

  @override
  String get rememberedEmpty =>
      'Nog geen onthouden apparaten. Apparaten die je koppelt met \'Dit apparaat onthouden\' aan, verschijnen hier.';

  @override
  String get rememberedLoadFailed => 'Kan onthouden apparaten niet laden';

  @override
  String get rememberedOnline => 'Deelt nu';

  @override
  String get rememberedOffline => 'Deelt nu niet';

  @override
  String get rememberedConnected => 'Verbonden';

  @override
  String get rememberedConnectsToUs => 'Verbindt met dit apparaat';

  @override
  String rememberedStatusWords(String status, String words) {
    return '$status · $words';
  }

  @override
  String get rememberedReconnect => 'Opnieuw verbinden';

  @override
  String get rememberedShareFromHere => 'Delen vanaf dit apparaat';

  @override
  String get rememberedAlwaysAllow => 'Altijd toestaan';

  @override
  String get rememberedAlwaysAllowHint =>
      'Niet vragen als het met dit apparaat verbindt';

  @override
  String get rememberedRemove => 'Verwijderen';

  @override
  String rememberedRemoveTitle(String name) {
    return '$name verwijderen?';
  }

  @override
  String get rememberedRemoveBody =>
      'De verbinding wordt nu verbroken en het apparaat moet de QR-code scannen om opnieuw te verbinden. Een verloren of gestolen onthouden apparaat heeft nog steeds nodig dat dit apparaat deelt en dat iemand op Accepteren tikt; door het te verwijderen kan zelfs dat niet meer.';

  @override
  String get rememberedRemoveAll => 'Alles verwijderen';

  @override
  String get rememberedRemoveAllTitle =>
      'Alle onthouden apparaten verwijderen?';

  @override
  String get rememberedRemoveAllBody =>
      'Elk apparaat moet de QR-code opnieuw scannen om te verbinden.';

  @override
  String get rememberedRemoveFailed =>
      'Kan het apparaat niet verwijderen. Probeer het opnieuw.';

  @override
  String get resetIdentityTitle => 'ID van dit apparaat resetten';

  @override
  String get resetIdentityHint =>
      'Alle apparaten vergeten en elk apparaat opnieuw laten scannen';

  @override
  String get resetIdentityConfirmTitle => 'ID van dit apparaat resetten?';

  @override
  String get resetIdentityConfirmBody =>
      'Delen stopt, dit apparaat krijgt een nieuwe sleutel en alle onthouden apparaten worden vergeten. Andere apparaten moeten de QR-code opnieuw scannen. Gebruik dit als een apparaat misschien gehackt is, of voordat je dit apparaat weggeeft.';

  @override
  String get resetIdentityConfirm => 'Resetten';

  @override
  String get resetIdentityDone =>
      'Nieuwe ID gemaakt. Andere apparaten moeten opnieuw scannen.';

  @override
  String get resetIdentityFailed =>
      'Kan de ID niet resetten. Probeer het opnieuw.';

  @override
  String swipeProblemFolderNotOnSource(String device) {
    return 'Kies een map op $device';
  }

  @override
  String swipeProblemReadOnly(String device) {
    return 'Alleen-lezen op $device';
  }

  @override
  String swipeProblemNotOnDevice(String device) {
    return 'Niet beschikbaar voor bestanden op $device';
  }

  @override
  String remoteSwipeWaiting(String device) {
    return 'Wachten op $device…';
  }

  @override
  String remoteSwipeContinue(String device) {
    return 'Verder swipen op $device';
  }

  @override
  String remoteSwipeSwiped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count geswipet',
      one: '1 geswipet',
      zero: 'Nog niets geswipet',
    );
    return '$_temp0';
  }

  @override
  String remoteSwipePaused(String device) {
    return 'Gepauzeerd · $device niet verbonden';
  }

  @override
  String remoteSwipeOrphaned(String device) {
    return '$device wordt niet meer onthouden';
  }

  @override
  String remoteSwipeFinishNeedsConnection(String device) {
    return 'Verbind met $device om af te ronden';
  }

  @override
  String remoteSwipeFinishBody(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count bestanden worden naar de prullenbak op $device verplaatst.',
      one: '1 bestand wordt naar de prullenbak op $device verplaatst.',
      zero: 'Er wacht niets om verwijderd te worden.',
    );
    return '$_temp0';
  }

  @override
  String remoteSwipeRestoreOnDevice(String device) {
    return 'Herstel het vanuit de prullenbak op $device';
  }

  @override
  String remoteSwipeDeclined(String device) {
    return '$device heeft het verwijderen geweigerd';
  }

  @override
  String get remoteSwipeAllDone => 'Alles klaar in deze map.';

  @override
  String get remoteSwipeDiscard => 'Sessie wissen';

  @override
  String remoteSwipeDiscardTitle(String device) {
    return 'Swipesessie op $device wissen?';
  }

  @override
  String get remoteSwipeDiscardBody =>
      'Je swipes daar worden vergeten. Er wordt niets verwijderd op dat apparaat.';

  @override
  String get remoteSwipeUnknownDevice => 'het andere apparaat';

  @override
  String get transfersTitle => 'Overdrachten';

  @override
  String get transfersDownloads => 'Downloads';

  @override
  String get transfersUploads => 'Uploads';

  @override
  String get transfersEmptyDownloads =>
      'Nog geen downloads. Selecteer bestanden op een verbonden apparaat en tik op Downloaden.';

  @override
  String get transfersEmptyUploads =>
      'Nog geen uploads. Selecteer bestanden en tik op Naar apparaat versturen.';

  @override
  String transferFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden',
      one: '1 bestand',
    );
    return '$_temp0';
  }

  @override
  String transferFromDevice(String device) {
    return 'Van $device';
  }

  @override
  String transferToDevice(String device) {
    return 'Naar $device';
  }

  @override
  String transferSpeedEta(String speed, String eta) {
    return '$speed/s · nog $eta';
  }

  @override
  String transferProgress(String done, String total) {
    return '$done van $total';
  }

  @override
  String get transferStatusQueued => 'Wachten';

  @override
  String transferStatusWaitingFor(String device) {
    return 'Wachten op $device';
  }

  @override
  String get transferStatusRunning => 'Bezig met overdracht';

  @override
  String get transferStatusDone => 'Klaar';

  @override
  String transferStatusFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden mislukt',
      one: '1 bestand mislukt',
    );
    return '$_temp0';
  }

  @override
  String get transferStatusCancelled => 'Geannuleerd';

  @override
  String get transferCancel => 'Annuleren';

  @override
  String get transferRetry => 'Opnieuw proberen';

  @override
  String get transferClearFinished => 'Voltooide wissen';

  @override
  String transferNoSpaceOn(String device) {
    return 'Niet genoeg ruimte op $device';
  }

  @override
  String get transferNoSpaceHere => 'Niet genoeg ruimte op dit apparaat';

  @override
  String transferNotAllowedOn(String device) {
    return 'Niet toegestaan op $device';
  }

  @override
  String transferNoWritableFolder(String device) {
    return '$device deelt geen map waarin geschreven mag worden';
  }

  @override
  String get transferInvalidName =>
      'Deze bestandsnaam kan hier niet worden gebruikt';

  @override
  String get transferNoLocation => 'Locatiegegevens zijn niet meegestuurd';

  @override
  String get transferAlreadySent => 'Al verstuurd';

  @override
  String transferConnectToPick(String device) {
    return 'Verbind met $device om een map te kiezen';
  }

  @override
  String transfersRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overdrachten bezig',
      one: '1 overdracht bezig',
      zero: 'Niets bezig',
    );
    return '$_temp0';
  }

  @override
  String transferLostConnection(String device) {
    return 'Verbinding met $device verbroken';
  }

  @override
  String get transferInterrupted => 'Gestopt toen KFM werd gesloten';

  @override
  String get transferSourceGone => 'Het bestand is weg';

  @override
  String get transferIncomplete => 'De overdracht is onderbroken';

  @override
  String get transferFailedGeneric => 'Kan dit bestand niet overdragen';

  @override
  String get transferPause => 'Pauzeren';

  @override
  String get transferResume => 'Hervatten';

  @override
  String get transferReconnect => 'Opnieuw verbinden';

  @override
  String get transferPausedByYou => 'Gepauzeerd';

  @override
  String get transferRetrying => 'Zo meteen opnieuw proberen';

  @override
  String get transferSourceChanged =>
      'Het bestand is gewijzigd tijdens het versturen';

  @override
  String get transferModeCopy => 'Kopiëren';

  @override
  String get transferModeMove => 'Verplaatsen';

  @override
  String transferMoveDownloadNote(String device) {
    return 'Elk bestand wordt na aankomst gecontroleerd; pas dan gaat het origineel naar de prullenbak op $device.';
  }

  @override
  String get transferMoveToDevice => 'Verplaatsen naar apparaat';

  @override
  String transferMoveFromDevice(String device) {
    return 'Verplaatsen van $device';
  }

  @override
  String transferMoveToDeviceTitle(String device) {
    return 'Verplaatsen naar $device';
  }

  @override
  String transferMoveQueued(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden worden naar $device verplaatst',
      one: '1 bestand wordt naar $device verplaatst',
    );
    return '$_temp0';
  }

  @override
  String transferMoveDownloadQueued(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden worden van $device verplaatst',
      one: '1 bestand wordt van $device verplaatst',
    );
    return '$_temp0';
  }

  @override
  String get transferVerifying => 'Controleren…';

  @override
  String get transferVerified => 'Gecontroleerd';

  @override
  String get transferVerifyFailed => 'Controle mislukt. Origineel bewaard.';

  @override
  String get transferAlreadyMoved => 'Al verplaatst';

  @override
  String get transferOriginalPending =>
      'Gecontroleerd · origineel nog niet verwijderd';

  @override
  String get transferOriginalTrashed =>
      'Gecontroleerd · origineel naar de prullenbak verplaatst';

  @override
  String transferOriginalTrashedOn(String device) {
    return 'Gecontroleerd · origineel naar de prullenbak op $device verplaatst';
  }

  @override
  String get transferOriginalDeleted => 'Gecontroleerd · origineel verwijderd';

  @override
  String get transferOriginalGone => 'Gecontroleerd · origineel was al weg';

  @override
  String get transferOriginalKeptDeclined =>
      'Gecontroleerd · origineel bewaard (door jou geweigerd)';

  @override
  String transferOriginalKeptDeclinedOn(String device) {
    return 'Gecontroleerd · origineel bewaard (geweigerd op $device)';
  }

  @override
  String get transferOriginalKeptCancelled =>
      'Gecontroleerd · origineel bewaard (geannuleerd)';

  @override
  String get transferOriginalKeptChanged => 'Origineel bewaard (gewijzigd)';

  @override
  String get transferOriginalKeptFailed =>
      'Gecontroleerd · origineel bewaard (verwijderen mislukt)';

  @override
  String get transferDeleteOriginals => 'Originelen verwijderen';

  @override
  String get transferDeletingOriginals => 'Originelen verwijderen…';

  @override
  String get permanentMoveTitle => 'Originelen definitief verwijderen?';

  @override
  String permanentMoveBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Je verwijderinstelling is \'Definitief verwijderen\': de $count originelen worden voorgoed verwijderd zodra de kopieën zijn gecontroleerd.',
      one: 'Je verwijderinstelling is \'Definitief verwijderen\': het origineel wordt voorgoed verwijderd zodra de kopie is gecontroleerd.',
    );
    return '$_temp0';
  }

  @override
  String get permanentMoveUseTrash => 'Toch de prullenbak gebruiken';

  @override
  String get permanentMoveConfirm => 'Definitief verwijderen';

  @override
  String get transferDownloadAction => 'Downloaden';

  @override
  String transferDownloadQueued(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden worden gedownload van $device',
      one: '1 bestand wordt gedownload van $device',
    );
    return '$_temp0';
  }

  @override
  String transferUploadQueued(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden worden naar $device verstuurd',
      one: '1 bestand wordt naar $device verstuurd',
    );
    return '$_temp0';
  }

  @override
  String get transferShow => 'Tonen';

  @override
  String get transferSendToDevice => 'Versturen naar apparaat';

  @override
  String get transferConnectFirst => 'Maak eerst verbinding met een apparaat';

  @override
  String transferDownloadTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden downloaden?',
      one: '1 bestand downloaden?',
    );
    return '$_temp0';
  }

  @override
  String transferDownloadTo(String folder) {
    return 'Opgeslagen in $folder';
  }

  @override
  String get transferChangeFolder => 'Andere map';

  @override
  String get transferPickDeviceTitle => 'Naar welk apparaat versturen?';

  @override
  String get transferNoRememberedDevices =>
      'Nog geen onthouden apparaten. Maak verbinding met een apparaat terwijl \'Dit apparaat onthouden\' aanstaat.';

  @override
  String get swipeProblemDeviceMissing =>
      'Dat apparaat wordt niet meer onthouden';

  @override
  String get swipeActionSendToDevice => 'Versturen naar apparaat…';

  @override
  String swipeActionSendToNamed(String device) {
    return 'Versturen naar $device';
  }

  @override
  String rememberedRemoveTransfers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'De $count bijbehorende overdrachten worden ook verwijderd.',
      one: 'De bijbehorende overdracht wordt ook verwijderd.',
    );
    return '$_temp0';
  }

  @override
  String get errorLogShare => 'Foutenlogboek delen';

  @override
  String errorLogShareSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fouten',
      one: '1 fout',
    );
    return '$_temp0. Blijft op deze telefoon tot je het deelt. Map- en bestandsnamen worden verborgen.';
  }

  @override
  String get errorLogEmpty => 'Geen fouten gelogd';

  @override
  String get errorLogShareSubject => 'KFM-foutenlogboek';

  @override
  String get errorLogShareFailed => 'Kan het foutenlogboek niet delen';

  @override
  String get errorLogClear => 'Foutenlogboek wissen';

  @override
  String get errorLogClearConfirm =>
      'Foutenlogboek wissen? Dit kan niet ongedaan worden gemaakt.';

  @override
  String get errorLogCleared => 'Foutenlogboek gewist';

  @override
  String get errorLogClearFailed => 'Kan het foutenlogboek niet wissen';

  @override
  String get devThrowTestError => 'Testfout veroorzaken';

  @override
  String get themeColorLabel => 'Kleur';

  @override
  String get accentBlue => 'Blauw';

  @override
  String get accentGreen => 'Groen';

  @override
  String get accentPurple => 'Paars';

  @override
  String get accentOrange => 'Oranje';

  @override
  String get accentMono => 'Zwart-wit';

  @override
  String get accentSystem => 'Systeemkleuren';

  @override
  String get settingsAccessibility => 'Toegankelijkheid';

  @override
  String get leftHandedTitle => 'Linkshandig';

  @override
  String get leftHandedSubtitle =>
      'Zet Ongedaan maken en de knoppen onderaan aan de andere kant. Swiperichtingen blijven hetzelfde.';

  @override
  String get textSizeLabel => 'Tekstgrootte';

  @override
  String get textSizeSystem => 'Systeem';

  @override
  String get textSizeLarge => 'Groot';

  @override
  String get textSizeExtraLarge => 'Extra groot';

  @override
  String get textSizePreview => 'Zo ziet tekst eruit.';

  @override
  String get externalPlacesTitle => 'Locaties';

  @override
  String get externalInternal => 'Interne opslag';

  @override
  String get externalGeneric => 'Externe opslag';

  @override
  String get externalSdCard => 'SD-kaart';

  @override
  String get externalUsbDrive => 'USB-stick';

  @override
  String externalFreeOf(String free, String total) {
    return '$free vrij van $total';
  }

  @override
  String externalAttached(String label) {
    return '$label verbonden';
  }

  @override
  String get externalOpen => 'Openen';

  @override
  String get externalRemoved => 'Opslag verwijderd';

  @override
  String externalGrantTitle(String label) {
    return 'Toegang tot $label toestaan';
  }

  @override
  String get externalGrantExplain =>
      'Android vraagt één keer welke schijf KFM mag gebruiken. Kies op het volgende scherm de schijf zelf (geen map erin) en tik op \'Deze map gebruiken\'.';

  @override
  String get externalGrantContinue => 'Doorgaan';

  @override
  String get externalPickRootTitle => 'Kies de schijf zelf';

  @override
  String get externalPickRootHint =>
      'Dat was een map op de schijf. Kies het hoogste niveau van de schijf, zodat KFM alles kan zien.';

  @override
  String get externalRetry => 'Opnieuw kiezen';

  @override
  String get externalGrantFailed =>
      'Android heeft de toegang niet bewaard. Probeer het opnieuw.';

  @override
  String externalAllFilesTitle(String label) {
    return '$label openen';
  }

  @override
  String externalAllFilesExplain(String label) {
    return 'Om $label te openen heeft KFM Toegang tot alle bestanden nodig. Android laat apps een hele SD-kaart of USB-stick niet op een andere manier kiezen. Zet op het volgende scherm de toegang voor KFM aan en kom dan terug.';
  }

  @override
  String externalAllFilesStillOff(String label) {
    return 'Toegang tot alle bestanden staat nog uit, dus $label kan niet worden geopend.';
  }

  @override
  String get externalFormatHelp =>
      'De USB-stick kan niet worden geopend. Android leest FAT32- en exFAT-schijven; NTFS werkt vaak niet. Formatteer de stick op een computer of probeer een andere.';

  @override
  String externalCameraLabel(String model) {
    return 'Camera · $model';
  }

  @override
  String get externalCameraUnsupported =>
      'Deze camera kan hier niet worden geopend. Sluit andere camera-apps of zet de camera op USB-massaopslag.';

  @override
  String get externalPermissionNeeded =>
      'Toestemming nodig · Tik om toe te staan';

  @override
  String get externalCameraReadOnly => 'Verbonden · alleen-lezen';

  @override
  String get externalCameraNotYet =>
      'Camera\'s openen is nog niet beschikbaar.';

  @override
  String get externalLoadError => 'Kan de opslaglijst niet lezen.';

  @override
  String get privacySectionTitle => 'Privacy';

  @override
  String get privacyStripLocation => 'Locatie verwijderen bij delen';

  @override
  String get privacyStripLocationHelp =>
      'Foto\'s en video\'s die je deelt of naar een ander apparaat verstuurt, gaan zonder locatiegegevens. Je originelen houden ze.';

  @override
  String get privacyAllowAccess => 'Toegang tot fotolocaties toestaan';

  @override
  String get privacyAllowAccessHelp =>
      'Zonder deze toestemming komen verstuurde foto\'s aan zonder locatie.';

  @override
  String get privacyNoOriginalNote =>
      'KFM kan de oorspronkelijke locatie van je foto\'s niet lezen; ze worden hoe dan ook zonder locatie verstuurd.';

  @override
  String get privacyShareAction => 'Delen';

  @override
  String privacyShareTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden delen',
      one: '1 bestand delen',
    );
    return '$_temp0';
  }

  @override
  String get privacyShareRemoveLocation => 'Locatie verwijderen';

  @override
  String get privacyShareRemoveLocationHelp =>
      'Uit foto\'s en video\'s. Je originelen houden de locatie.';

  @override
  String privacyRemovingLocation(int done, int total) {
    return 'Locatie verwijderen… $done/$total';
  }

  @override
  String get privacyShareNoApp => 'Geen app kan deze bestanden ontvangen';

  @override
  String privacyCouldNotStrip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Locatie kon niet uit $count bestanden worden verwijderd, dus ze zijn niet gedeeld',
      one: 'Locatie kon niet uit 1 bestand worden verwijderd, dus het is niet gedeeld',
    );
    return '$_temp0';
  }

  @override
  String privacyFailedLine(String name, String reason) {
    return '$name: $reason';
  }

  @override
  String get privacyFailStillHasLocation =>
      'na het verwijderen was er nog steeds locatie-informatie';

  @override
  String get privacyFailUnsupported =>
      'de gegevens van deze video kunnen niet worden bewerkt';

  @override
  String get privacyFailReadFailed => 'het bestand kon niet worden gelezen';

  @override
  String get privacyTransferNotRemoved =>
      'Locatie kon niet worden verwijderd, dus het is niet verstuurd';

  @override
  String get privacyTransferNote =>
      'Locatie-informatie wordt verwijderd (Instellingen → Privacy)';

  @override
  String get privacyMoveWarningTitle => 'Verplaatsen zonder locatie?';

  @override
  String get privacyMoveWarningBody =>
      'De kopieën hebben geen locatie, en de originelen met locatie worden van dit apparaat verwijderd.';

  @override
  String get privacyMoveAnyway => 'Toch verplaatsen';

  @override
  String get privacyCopyInstead => 'Liever kopiëren';

  @override
  String externalJobTitleCopy(int count, String place) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden kopiëren naar $place',
      one: '1 bestand kopiëren naar $place',
    );
    return '$_temp0';
  }

  @override
  String externalJobTitleMove(int count, String place) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden verplaatsen naar $place',
      one: '1 bestand verplaatsen naar $place',
    );
    return '$_temp0';
  }

  @override
  String externalJobProgress(int done, int total, String size) {
    return '$done van $total · $size';
  }

  @override
  String get externalJobQueued => 'Wachten';

  @override
  String get externalJobRunning => 'Bezig';

  @override
  String get externalJobPaused => 'Gepauzeerd';

  @override
  String get externalJobPausedUnplugged =>
      'Gepauzeerd · sluit de opslag opnieuw aan om door te gaan';

  @override
  String get externalJobDone => 'Klaar';

  @override
  String get externalJobCancelled => 'Geannuleerd';

  @override
  String externalJobFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden mislukt',
      one: '1 bestand mislukt',
    );
    return '$_temp0';
  }

  @override
  String get externalJobStoppedNoSpace => 'Gestopt: onvoldoende ruimte';

  @override
  String get externalJobResume => 'Hervatten';

  @override
  String get externalJobPause => 'Pauzeren';

  @override
  String get externalJobDetails => 'Details';

  @override
  String externalJobStartedCopy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden kopiëren…',
      one: '1 bestand kopiëren…',
    );
    return '$_temp0';
  }

  @override
  String externalJobStartedMove(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden verplaatsen…',
      one: '1 bestand verplaatsen…',
    );
    return '$_temp0';
  }

  @override
  String get externalJobView => 'Bekijken';

  @override
  String externalNotEnoughSpace(String place) {
    return 'Onvoldoende ruimte op $place';
  }

  @override
  String get externalStagingNoSpace =>
      'Onvoldoende vrije ruimte op deze telefoon om via de telefoon te kopiëren';

  @override
  String externalFat32TooLarge(String name) {
    return '$name: 4 GB of groter, te groot voor deze schijf (FAT32)';
  }

  @override
  String externalRenamedForDrive(String from, String to) {
    return '$from opgeslagen als $to';
  }

  @override
  String externalCollisionTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden staan er al',
      one: '1 bestand staat er al',
    );
    return '$_temp0';
  }

  @override
  String get externalCollisionKeepBoth => 'Beide bewaren';

  @override
  String get externalCollisionSkip => 'Overslaan';

  @override
  String get externalCollisionReplace => 'Vervangen';

  @override
  String get externalApplyToAll =>
      'Je keuze geldt voor alle bestanden in deze taak.';

  @override
  String get externalCameraDeleteWarning =>
      'Camerafoto\'s hebben geen prullenbak: als je ze hier verwijdert, zijn ze voorgoed weg.';

  @override
  String externalOriginalNotRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count originelen zijn niet verwijderd',
      one: '1 origineel is niet verwijderd',
    );
    return '$_temp0';
  }

  @override
  String get externalDeleteOriginals => 'Originelen verwijderen';

  @override
  String get externalSwipeFolder => 'Deze map swipen';

  @override
  String get externalSwipeFolderEmpty => 'Geen foto\'s of video\'s in deze map';

  @override
  String get transfersLocalSection => 'Op deze telefoon';

  @override
  String get externalNoJobs =>
      'Geen kopieën of verplaatsingen tussen locaties in de afgelopen 7 dagen';

  @override
  String get externalClearFinished => 'Voltooide wissen';

  @override
  String get externalVerifyFailed => 'Controle mislukt. Origineel bewaard.';

  @override
  String get externalSourceGone => 'Het bestand is weg';

  @override
  String get externalAlreadyMoved => 'Al verplaatst';

  @override
  String get externalSkippedExists => 'Overgeslagen: staat er al';

  @override
  String get externalFileFailed => 'Kopiëren mislukt';

  @override
  String externalLogLine(String name, String reason) {
    return '$name: $reason';
  }

  @override
  String get externalFolderEmpty => 'Deze map is leeg';

  @override
  String get externalFolderError => 'Kan deze map niet openen';

  @override
  String get externalSortByName => 'Naam';

  @override
  String get externalSortByDate => 'Datum';

  @override
  String get externalSortBySize => 'Grootte';

  @override
  String get externalShowAll => 'Alle bestanden';

  @override
  String get externalShowMedia => 'Foto\'s en video\'s';

  @override
  String get externalCopyTo => 'Kopiëren naar…';

  @override
  String get externalMoveTo => 'Verplaatsen naar…';

  @override
  String get externalDelete => 'Verwijderen';

  @override
  String get externalReadOnly => 'Alleen-lezen';

  @override
  String externalDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden verwijderd',
      one: '1 bestand verwijderd',
    );
    return '$_temp0';
  }

  @override
  String get externalDeleteFailed => 'Verwijderen mislukt';

  @override
  String get swipeSetupTitle => 'Swipe-instellingen';

  @override
  String get swipeSetupTuneTooltip => 'Swipe-instellingen';

  @override
  String get swipeSetupPresets => 'Voorinstellingen';

  @override
  String get swipeSetupDirections => 'Swiperichtingen';

  @override
  String get swipeSetupFilter => 'Filter';

  @override
  String get swipeSetupEditFilter => 'Filter bewerken';

  @override
  String get swipeSetupExtras => 'Extra\'s';

  @override
  String swipeSetupModified(String name) {
    return 'Wijzigingen niet opgeslagen in $name';
  }

  @override
  String get swipeSetupSave => 'Opslaan';

  @override
  String get swipeSetupSaveAsNew => 'Opslaan als nieuwe…';

  @override
  String get swipeSetupRevert => 'Terugzetten';

  @override
  String swipeSetupSavedTo(String name) {
    return 'Opgeslagen in \'$name\'';
  }

  @override
  String swipeSetupRemoteTitle(String device) {
    return 'Instellingen voor swipen op $device';
  }

  @override
  String swipeSetupPresetSemantics(String name) {
    return 'Voorinstelling $name';
  }

  @override
  String swipeSetupPresetModifiedSemantics(String name) {
    return 'Voorinstelling $name, gewijzigd';
  }

  @override
  String swipeSetupDirectionSemantics(String direction, String action) {
    return '$direction: $action';
  }

  @override
  String get swipeSetupFilterOn => 'Filter aan';

  @override
  String get swipeSetupPresetBroken => 'Kan niet laden';

  @override
  String get ejectAction => 'Uitwerpen';

  @override
  String ejectRunningJobs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overdrachten nog bezig',
      one: '1 overdracht nog bezig',
    );
    return '$_temp0';
  }

  @override
  String get ejectRunningJobsBody =>
      'Pauzeren stopt na het huidige bestand. Gepauzeerde overdrachten kun je later hervatten.';

  @override
  String get ejectWait => 'Wachten';

  @override
  String get ejectPauseAndEject => 'Pauzeren en uitwerpen';

  @override
  String ejectWaiting(String label) {
    return 'Werk op $label afronden…';
  }

  @override
  String ejectHintTitle(String label) {
    return '$label uitwerpen';
  }

  @override
  String get ejectHint =>
      'Android laat alleen zijn eigen instellingen opslag uitwerpen. Tik op de schijf en dan op Uitwerpen (op sommige telefoons: ⋮ → Ontkoppelen).';

  @override
  String get ejectOpenSettings => 'Instellingen openen';

  @override
  String ejectSafe(String label) {
    return '$label kan veilig worden verwijderd';
  }

  @override
  String get ejectNotYet => 'Nog niet uitgeworpen';

  @override
  String get ejectOpenAgain => 'Instellingen opnieuw openen';

  @override
  String get ejectCameraSafe => 'Camera kan worden losgekoppeld';

  @override
  String get ejectRefused => 'Deze opslag wordt uitgeworpen';

  @override
  String get ejectFailed => 'Kan de opslaginstellingen niet openen';

  @override
  String get sendTo => 'Versturen naar…';

  @override
  String sendSheetTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden versturen naar…',
      one: '1 bestand versturen naar…',
    );
    return '$_temp0';
  }

  @override
  String get sendSheetConnected => 'Verbonden';

  @override
  String get sendSheetConnectedToYou => 'Met jou verbonden';

  @override
  String get sendSheetRemembered => 'Onthouden';

  @override
  String get sendSheetNearby => 'In de buurt';

  @override
  String get sendSheetOnline => 'Nu in de buurt';

  @override
  String sendAskReceive(String device) {
    return 'Vraag $device om Bestanden ontvangen te openen';
  }

  @override
  String sendSwitchDevice(String from, String to) {
    return 'Verbinding met $from verbreken om naar $to te versturen?';
  }

  @override
  String get sendSwitchAction => 'Verbinding verbreken';

  @override
  String sendConnecting(String device) {
    return 'Verbinden met $device…';
  }

  @override
  String sendConfirmTitle(int count, String size, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden ($size) naar $device versturen?',
      one: '1 bestand ($size) naar $device versturen?',
    );
    return '$_temp0';
  }

  @override
  String sendConfirmHint(String device) {
    return '$device beslist of de bestanden worden aangenomen. Verder wordt er niets gedeeld.';
  }

  @override
  String sendSharedFolderInstead(String device) {
    return 'In een gedeelde map op $device zetten…';
  }

  @override
  String get sendAction => 'Versturen';

  @override
  String sendWaiting(String device) {
    return 'Wachten tot $device accepteert…';
  }

  @override
  String sendDeclined(String device) {
    return '$device heeft geweigerd';
  }

  @override
  String sendNoAnswer(String device) {
    return 'Geen antwoord van $device';
  }

  @override
  String sendNoSpace(String device) {
    return 'Onvoldoende ruimte op $device';
  }

  @override
  String sendStopped(String device) {
    return 'Gestopt door $device';
  }

  @override
  String sendSending(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden worden verstuurd naar $device',
      one: '1 bestand wordt verstuurd naar $device',
    );
    return '$_temp0';
  }

  @override
  String get sendPairToSend => 'Verbind om bestanden te versturen';

  @override
  String sendConfirmPanelTitle(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden naar $device versturen',
      one: '1 bestand naar $device versturen',
    );
    return '$_temp0';
  }

  @override
  String get receiveFiles => 'Bestanden ontvangen';

  @override
  String get receiveFilesHint => 'Laat een ander apparaat je bestanden sturen';

  @override
  String get receiveReadyTitle => 'Klaar om bestanden te ontvangen';

  @override
  String receiveReadyHint(String device) {
    return 'Op het andere apparaat: Versturen naar… → $device, of scan deze code';
  }

  @override
  String offerTitle(String device, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$device wil je $count bestanden sturen',
      one: '$device wil je 1 bestand sturen',
    );
    return '$_temp0';
  }

  @override
  String offerSize(String size) {
    return 'Totaal $size';
  }

  @override
  String offerMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'en nog $count',
      one: 'en nog 1',
    );
    return '$_temp0';
  }

  @override
  String offerSaveTo(String folder) {
    return 'Opslaan in $folder';
  }

  @override
  String get offerChangeFolder => 'Wijzigen';

  @override
  String get offerFolderExcluded =>
      'Bestanden kunnen daar niet worden opgeslagen';

  @override
  String offerRemember(String device) {
    return '$device onthouden';
  }

  @override
  String offerAlwaysAccept(String device) {
    return 'Altijd bestanden van $device accepteren';
  }

  @override
  String get offerAccept => 'Accepteren';

  @override
  String get offerDecline => 'Weigeren';

  @override
  String offerAutoDecline(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Wordt over $seconds seconden geweigerd',
      one: 'Wordt over 1 seconde geweigerd',
    );
    return '$_temp0';
  }

  @override
  String get offerNotificationChannel => 'Inkomende bestanden';

  @override
  String offerNotificationTitle(String device) {
    return '$device wil je bestanden sturen';
  }

  @override
  String offerNotificationBody(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden · $size · Tik om te antwoorden',
      one: '1 bestand · $size · Tik om te antwoorden',
    );
    return '$_temp0';
  }

  @override
  String offerReceiving(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden worden ontvangen van $device',
      one: '1 bestand wordt ontvangen van $device',
    );
    return '$_temp0';
  }

  @override
  String offerReceived(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden ontvangen van $device',
      one: '1 bestand ontvangen van $device',
    );
    return '$_temp0';
  }

  @override
  String get offerOpenFolder => 'Openen';

  @override
  String get rememberedAcceptFiles => 'Bestanden accepteren zonder te vragen';

  @override
  String get rememberedAcceptFilesHint =>
      'Bestanden van dit apparaat gaan zonder vraag naar je map Downloads';

  @override
  String connectSendOnly(String device) {
    return 'Verbonden met $device om bestanden te versturen';
  }

  @override
  String shareSessionSending(String device) {
    return '$device · bestanden versturen';
  }

  @override
  String get transferReceivedSection => 'Ontvangen';

  @override
  String get transferOfferedSection => 'Aangeboden';

  @override
  String get transferWaitingForYou => 'Wacht op jou';

  @override
  String get transferPreparing => 'Voorbereiden…';

  @override
  String transferFromDeviceOffer(String device, int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Van $device · $count bestanden · $size',
      one: 'Van $device · 1 bestand · $size',
    );
    return '$_temp0';
  }

  @override
  String transferToDeviceOffer(String device, int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Naar $device · $count bestanden · $size',
      one: 'Naar $device · 1 bestand · $size',
    );
    return '$_temp0';
  }

  @override
  String transferOfferReceiving(int done, int count) {
    return '$done van $count ontvangen';
  }

  @override
  String get transferOfferDone => 'Klaar';

  @override
  String get transferOfferCancelled => 'Gestopt';

  @override
  String get transferOfferDeclined => 'Geweigerd';

  @override
  String get transferOfferExpired => 'Geen antwoord';

  @override
  String get transferOfferStop => 'Stoppen';

  @override
  String get transferOfferAnswer => 'Antwoorden';

  @override
  String get transferOfferOpenFolder => 'Map openen';

  @override
  String get transferOfferAccepted => 'Geaccepteerd';

  @override
  String get transfersEmptyReceived =>
      'Bestanden die andere apparaten je sturen, verschijnen hier';

  @override
  String shareInTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gedeelde bestanden',
      one: '1 gedeeld bestand',
    );
    return '$_temp0';
  }

  @override
  String get shareInSwipe => 'Erdoorheen swipen';

  @override
  String get shareInMoveTo => 'Verplaatsen naar…';

  @override
  String get shareInCopyTo => 'Kopiëren naar…';

  @override
  String get shareInSendToDevice => 'Versturen naar…';

  @override
  String shareInCopiedSubtitle(String size) {
    return '$size · Gekopieerd uit een andere app';
  }

  @override
  String get shareInCopyDeleteNote =>
      'Bestanden die uit een andere app zijn gekopieerd, worden uit KFM verwijderd als je ze verwijdert. Het origineel blijft in die app.';

  @override
  String get shareInOnlyFiles =>
      'Alleen bestanden kunnen met KFM worden gedeeld';

  @override
  String get shareInPreparing => 'Gedeelde bestanden ophalen…';

  @override
  String shareInCopying(String done, String total) {
    return '$done van $total kopiëren';
  }

  @override
  String get shareInCancel => 'Annuleren';

  @override
  String shareInFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden kunnen niet worden gelezen',
      one: '1 bestand kan niet worden gelezen',
    );
    return '$_temp0';
  }

  @override
  String get shareInFailedAll =>
      'De gedeelde bestanden kunnen niet worden gelezen. Probeer ze opnieuw te delen.';

  @override
  String get shareInNoSpace =>
      'Niet genoeg vrije ruimte om de gedeelde bestanden te kopiëren';

  @override
  String get shareInEmpty => 'Geen gedeelde bestanden meer hier';

  @override
  String get shareInDone => 'Klaar';

  @override
  String get backupSectionTitle => 'Back-up';

  @override
  String get backupExport => 'Back-up exporteren';

  @override
  String get backupExportHelp =>
      'Tags, voorinstellingen, favorieten, Bekeken-markeringen en instellingen in één bestand. Je foto\'s blijven waar ze zijn.';

  @override
  String get backupImport => 'Back-up importeren';

  @override
  String get backupImportHelp =>
      'Voegt de gegevens van een back-up toe aan deze telefoon. Hier wordt niets verwijderd.';

  @override
  String get backupUndoImport => 'Laatste import ongedaan maken';

  @override
  String get backupUndoImportHelp =>
      'Terug naar hoe alles was vóór de laatste import';

  @override
  String get backupExported => 'Back-up opgeslagen';

  @override
  String backupExportFailed(String error) {
    return 'Kan de back-up niet opslaan: $error';
  }

  @override
  String backupImportFailed(String error) {
    return 'Kan de back-up niet importeren: $error';
  }

  @override
  String get backupNotKfm => 'Dit is geen KFM-back-up.';

  @override
  String get backupTooNew =>
      'Deze back-up is gemaakt met een nieuwere versie van KFM. Update eerst de app.';

  @override
  String get backupPreviewTitle => 'Back-up importeren';

  @override
  String get backupScanning => 'Scannen…';

  @override
  String backupPreviewNewTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nieuwe tags',
      one: '1 nieuwe tag',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewReusedTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags staan al op deze telefoon',
      one: '1 tag staat al op deze telefoon',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewNewPresets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nieuwe voorinstellingen',
      one: '1 nieuwe voorinstelling',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewSkippedPresets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voorinstellingen staan al op deze telefoon',
      one: '1 voorinstelling staat al op deze telefoon',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewMatched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden gevonden op deze telefoon',
      one: '1 bestand gevonden op deze telefoon',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewFileTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags toegevoegd aan bestanden',
      one: '1 tag toegevoegd aan een bestand',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewFavorites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nieuwe favorieten',
      one: '1 nieuwe favoriet',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewReviewed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bekeken-markeringen',
      one: '1 Bekeken-markering',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewUnmatched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden niet gevonden op deze telefoon',
      one: '1 bestand niet gevonden op deze telefoon',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewUnmatchedMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'en nog $count',
      one: 'en nog 1',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewFilePath(String folder, String name) {
    return '$folder/$name';
  }

  @override
  String get backupApplySettings => 'Ook instellingen toepassen';

  @override
  String backupPreviewSettings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count instellingen wijzigen',
      one: '1 instelling wijzigt',
      zero: 'Geen instellingen gewijzigd',
    );
    return '$_temp0';
  }

  @override
  String get backupPreviewNothing => 'Niets nieuws om te importeren.';

  @override
  String get backupImportedSuffix => 'geïmporteerd';

  @override
  String get backupImportButton => 'Importeren';

  @override
  String get backupImported => 'Back-up geïmporteerd';

  @override
  String get backupUndoConfirmTitle => 'Laatste import ongedaan maken?';

  @override
  String get backupUndoConfirmBody =>
      'Tags, voorinstellingen, favorieten, Bekeken-markeringen en instellingen gaan terug naar hoe ze waren vóór de import. Wijzigingen die je daarna hebt gemaakt, gaan ook verloren.';

  @override
  String get backupUndoConfirm => 'Import ongedaan maken';

  @override
  String get backupUndone => 'Import ongedaan gemaakt';

  @override
  String backupUndoFailed(String error) {
    return 'Kan de import niet ongedaan maken: $error';
  }

  @override
  String get backupSettingThemeMode => 'Thema';

  @override
  String get backupSettingThemeAccent => 'Kleurthema';

  @override
  String get backupSettingLeftHanded => 'Linkshandige modus';

  @override
  String get backupSettingTextSize => 'Tekstgrootte';

  @override
  String get backupSettingLanguage => 'Taal';

  @override
  String get backupSettingBigFileThreshold => 'Grootte van grote bestanden';

  @override
  String get backupSettingPendingRetention =>
      'Verwijderde bestanden bewaren voor';

  @override
  String get backupSettingSameTimeWindow => 'Tijdvenster voor zelfde tijd';

  @override
  String get backupSettingBrowseSort => 'Bestanden sorteren op';

  @override
  String get backupSettingBrowseSortDescending => 'Sorteerrichting';

  @override
  String get backupSettingBrowseShowSizes => 'Bestandsgroottes tonen';

  @override
  String get backupSettingBrowseHighlightBig => 'Grote bestanden markeren';

  @override
  String get backupSettingSearchSecondLanguage => 'Tweede zoektaal';

  @override
  String get backupSettingSwipeLayout => 'Basis-swiperichtingen';

  @override
  String get backupSettingDeleteMode => 'Verwijdermodus';

  @override
  String get backupSettingHaptics => 'Trilfeedback';

  @override
  String get backupSettingSwipeButtons => 'Swipeknoppen';

  @override
  String get backupSettingSessionSummary => 'Sessieoverzicht';

  @override
  String get backupSettingBasicIncludeReviewed =>
      'Bekeken bestanden tonen in Basis';

  @override
  String get backupSettingReviewedBadge => 'Bekeken-badge';

  @override
  String get backupSettingActivePreset => 'Actieve voorinstelling';

  @override
  String get backupSettingActionBar => 'Actiebalk';

  @override
  String get backupSettingFoldersDropAction => 'Neerzetten op een map';

  @override
  String get backupSettingSimilarEnabled => 'Vergelijkbare foto\'s';

  @override
  String get backupSettingSimilarStrictness =>
      'Strengheid vergelijkbare foto\'s';

  @override
  String get backupSettingSimilarBlur => 'Drempel voor wazige foto\'s';

  @override
  String get backupSettingSimilarScreenshots =>
      'Screenshots meenemen in vergelijkbare foto\'s';

  @override
  String get backupSettingAiWifiOnly => 'Modellen alleen via Wi-Fi downloaden';

  @override
  String get backupSettingStripLocation => 'Locatie verwijderen bij delen';

  @override
  String get backupSettingOther => 'Andere instelling';

  @override
  String get apkInstall => 'Installeren';

  @override
  String get apkNewApp => 'Nieuwe app';

  @override
  String apkUpdateFromTo(String from, String to) {
    return 'Update van $from naar $to';
  }

  @override
  String get apkSameVersion => 'Deze versie is al geïnstalleerd';

  @override
  String apkDowngrade(String installed) {
    return 'Ouder dan de geïnstalleerde versie ($installed)';
  }

  @override
  String get apkUnknownInstalled =>
      'Android laat zien of dit een nieuwe app of een update is';

  @override
  String get apkSignerMismatch =>
      'Ondertekend door een andere ontwikkelaar. Android weigert deze update. Verwijder eerst de oude app (de gegevens ervan gaan verloren).';

  @override
  String get apkSignerUnknown =>
      'Updates moeten door dezelfde ontwikkelaar zijn ondertekend.';

  @override
  String get apkTrustNote =>
      'Installeer alleen apps uit bronnen die je vertrouwt.';

  @override
  String get apkInvalid => 'Dit bestand is geen geldig app-pakket.';

  @override
  String get apkNoSpace => 'Niet genoeg ruimte om dit bestand te bekijken.';

  @override
  String apkReadFailed(String error) {
    return 'Kan dit bestand niet lezen: $error';
  }

  @override
  String apkInstallFailed(String error) {
    return 'Kan het installatieprogramma niet starten: $error';
  }

  @override
  String get apkNoInstaller =>
      'Geen app op dit apparaat kan pakketten installeren.';

  @override
  String get apkPermissionWhy =>
      'Om apps te installeren, vraagt Android je KFM toe te staan bij \"Onbekende apps installeren\". KFM installeert nooit iets zonder de eigen bevestiging van Android.';

  @override
  String get apkOpenSettings => 'Instellingen openen';

  @override
  String get apkPermissionDenied => 'Toestemming niet gegeven.';

  @override
  String apkPackageLine(String package, String version) {
    return '$package · versie $version';
  }

  @override
  String get updatesSectionTitle => 'Updates';

  @override
  String get updatesCheckSetting => 'Controleren op updates';

  @override
  String get updatesCheckSettingHelp =>
      'Eén keer per dag vraagt KFM aan GitHub of er een nieuwere versie is. Er wordt niets over jou of je bestanden verstuurd; GitHub ziet je IP-adres, net als elke website.';

  @override
  String get updatesCheckNow => 'Nu controleren';

  @override
  String updatesCurrentVersion(String version) {
    return 'Geïnstalleerde versie $version';
  }

  @override
  String get updatesChecking => 'Controleren…';

  @override
  String get updatesUpToDate => 'Je bent up-to-date';

  @override
  String get updatesNoReleases => 'Geen releases gevonden';

  @override
  String updatesAvailable(String version) {
    return 'KFM $version is beschikbaar';
  }

  @override
  String get updatesLastCheckFailed => 'Laatste controle mislukt';

  @override
  String get updatesFailedOffline =>
      'Kan GitHub niet bereiken. Controleer je verbinding.';

  @override
  String get updatesFailedBusy => 'GitHub is druk. Probeer het later opnieuw.';

  @override
  String updatesFailed(String error) {
    return 'Updatecontrole mislukt: $error';
  }

  @override
  String get updatesWhatsNew => 'Wat is er nieuw';

  @override
  String get updatesDownload => 'Downloaden';

  @override
  String get updatesDismiss => 'Verbergen tot de volgende versie';

  @override
  String get updatesNoNotes => 'Geen release-opmerkingen.';

  @override
  String get updatesNoBrowser => 'Geen browser-app gevonden';

  @override
  String updatesOpenFailed(String error) {
    return 'Kan de pagina niet openen: $error';
  }

  @override
  String get cloudSettingsTitle => 'Cloud';

  @override
  String get cloudDestinations => 'Cloudbestemmingen';

  @override
  String get cloudDestinationsNone =>
      'Bestanden opslaan in een map van je cloud-app';

  @override
  String cloudDestinationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mappen',
      one: '1 map',
    );
    return '$_temp0';
  }

  @override
  String get cloudHowItWorks =>
      'KFM slaat bestanden op in een map van je cloud-app (Google Drive, OneDrive, Dropbox…). De cloud-app uploadt ze; KFM logt nergens in.';

  @override
  String get cloudEmpty => 'Nog geen cloudmappen';

  @override
  String get cloudAdd => 'Cloudmap toevoegen';

  @override
  String cloudAdded(String name) {
    return '$name toegevoegd';
  }

  @override
  String get cloudAddFailed => 'Kan de toegang tot die map niet behouden';

  @override
  String get cloudRename => 'Naam wijzigen';

  @override
  String get cloudRemove => 'Verwijderen';

  @override
  String cloudRemoveTitle(String name) {
    return '$name verwijderen?';
  }

  @override
  String get cloudRemoveConfirm =>
      'KFM slaat hier geen bestanden meer op. Bestanden die al in de cloud staan, blijven daar.';

  @override
  String get cloudForgetUploads =>
      'Ook vergeten welke bestanden hier zijn geüpload';

  @override
  String get cloudNeedsReconnecting => 'Opnieuw verbinden nodig';

  @override
  String get cloudReconnect => 'Opnieuw verbinden';

  @override
  String get cloudNoFolderPicking =>
      'Staat je cloud-app niet in de mapkiezer, dan laat die andere apps niet in zijn mappen opslaan.';

  @override
  String cloudSavedToFolder(String name) {
    return 'Opgeslagen in $name';
  }

  @override
  String cloudVerified(String name) {
    return 'Gecontroleerd in $name';
  }

  @override
  String cloudFailed(String reason) {
    return 'Mislukt: $reason';
  }

  @override
  String get cloudWaiting => 'Wachten';

  @override
  String cloudUploading(String name) {
    return 'Opslaan in $name…';
  }

  @override
  String get cloudVerifyFailed =>
      'Kan de kopie niet controleren — origineel bewaard';

  @override
  String get cloudVerifyUnavailable =>
      'Kan de kopie niet teruglezen — origineel bewaard';

  @override
  String get cloudCancelled => 'Geannuleerd';

  @override
  String get cloudDestinationRemovedError => 'Bestemming verwijderd';

  @override
  String get cloudSourceGone => 'Het bestand is weg';

  @override
  String get cloudSourceChanged =>
      'Het bestand is gewijzigd tijdens het kopiëren';

  @override
  String get cloudUnsupported =>
      'Dit bestand kan niet in de cloud worden opgeslagen';

  @override
  String get cloudLocationNotRemoved =>
      'Locatie kon niet worden verwijderd, dus het is niet geüpload';

  @override
  String get cloudCopyMissing =>
      'De kopie in de cloud ontbreekt — origineel bewaard';

  @override
  String get cloudNoSpace => 'De cloud-app heeft geen ruimte meer';

  @override
  String get cloudWriteError =>
      'De cloud-app heeft het bestand niet geaccepteerd';

  @override
  String cloudCopyLeftOver(String reason) {
    return '$reason. Er is een kopie in de cloudmap achtergebleven';
  }

  @override
  String get cloudOriginalNotFound =>
      'Origineel niet gevonden, niets verwijderd';

  @override
  String get cloudGpsNote =>
      'Foto\'s worden zonder locatie geüpload omdat KFM die niet kan lezen.';

  @override
  String get cloudGpsAllow => 'Toestaan';

  @override
  String get cloudGpsMoveTitle => 'Verplaatsen zonder locatie?';

  @override
  String get cloudGpsMoveWarning =>
      'Locatiegegevens kunnen uit de kopie in de cloud worden verwijderd, en het origineel wordt verwijderd.';

  @override
  String get cloudGpsMoveAnyway => 'Toch verplaatsen';

  @override
  String get cloudTransfersSection => 'Cloud';

  @override
  String get cloudTransfersEmpty =>
      'De afgelopen 7 dagen niets in de cloud opgeslagen';

  @override
  String get cloudPickerGroup => 'Cloud';

  @override
  String cloudStartedCopy(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden opslaan in $name…',
      one: '1 bestand opslaan in $name…',
    );
    return '$_temp0';
  }

  @override
  String cloudStartedMove(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden verplaatsen naar $name…',
      one: '1 bestand verplaatsen naar $name…',
    );
    return '$_temp0';
  }

  @override
  String get cloudNothingToSend =>
      'Deze bestanden kunnen niet in de cloud worden opgeslagen';

  @override
  String cloudOriginalsKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count originelen zijn bewaard',
      one: '1 origineel is bewaard',
    );
    return '$_temp0';
  }

  @override
  String cloudOriginalsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden verplaatst',
      one: '1 bestand verplaatst',
    );
    return '$_temp0';
  }

  @override
  String get cloudDeleteOriginals => 'Originelen verwijderen';

  @override
  String get cloudOriginalNotDeleted => 'Origineel niet verwijderd';

  @override
  String get cloudRetry => 'Opnieuw proberen';

  @override
  String get tutorialStepTrash => 'Swipe naar links om weg te gooien';

  @override
  String get tutorialStepKeep => 'Swipe naar rechts om te bewaren';

  @override
  String get tutorialStepUndo => 'Vergist? Tik op Ongedaan maken';

  @override
  String get tutorialSkip => 'Overslaan';

  @override
  String get tutorialNext => 'Volgende';

  @override
  String get tutorialDone => 'Klaar';

  @override
  String get tutorialDemoCard => 'Voorbeeldfoto';

  @override
  String get tutorialShowAgain => 'Uitleg opnieuw tonen';

  @override
  String get hintPresets =>
      'Een voorinstelling bewaart je swipe-instellingen en filter. Wissel met één tik.';

  @override
  String get hintActionBar =>
      'Hier staan extra acties. Zet ze uit via Instellingen → Swipen.';

  @override
  String get hintDismiss => 'Tip sluiten';

  @override
  String get cloudBadgeOnCloud =>
      'Geüpload door KFM (laatst bekend, geen live controle)';

  @override
  String get cloudBadgeChanged => 'Gewijzigd sinds het uploaden';

  @override
  String get cloudShowBadge => 'Cloudpictogram tonen';

  @override
  String get cloudBadgeHelp =>
      'Het cloudpictogram betekent dat KFM dit bestand aan je cloud-app heeft gegeven. Dit wordt op deze telefoon bewaard, dus het is ook offline zichtbaar. Het is geen live controle: KFM kan niet zien of het uploaden klaar is of dat de kopie later is verwijderd. Verandert het bestand na het uploaden, dan verandert het pictogram ook. Alleen bestanden die met KFM zijn geüpload, krijgen een markering.';

  @override
  String cloudInfoUploaded(String destination, String date) {
    return 'Door KFM geüpload naar $destination · $date';
  }

  @override
  String cloudInfoChanged(String destination) {
    return 'Gewijzigd sinds uploaden naar $destination';
  }

  @override
  String cloudInfoRemoved(String destination) {
    return '$destination (verwijderd)';
  }

  @override
  String get cloudFilterRow => 'Cloud';

  @override
  String get cloudFilterAny => 'Alle';

  @override
  String get cloudFilterOn => 'In de cloud';

  @override
  String get cloudFilterNotOn => 'Niet in de cloud';

  @override
  String get cloudSwipeOnCloud => 'Bestanden swipen die al in de cloud staan';

  @override
  String get cloudSwipeOnCloudTitle => 'In de cloud';

  @override
  String get backupUndoBlocked =>
      'het prullenbakvenster is geweigerd, dus er is niets veranderd';

  @override
  String fileOpInUse(String name) {
    return '$name wordt gebruikt door een ander programma';
  }

  @override
  String get fileOpNoTrash => 'Dit station heeft geen Prullenbak';

  @override
  String deleteNoRecycleBin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deze $count bestanden',
      one: 'Dit bestand',
    );
    return 'Dit station heeft geen Prullenbak. $_temp0 definitief verwijderen?';
  }

  @override
  String get windowsRootsTitle => 'Mappen die KFM doorzoekt';

  @override
  String get windowsRootsHint =>
      'KFM toont de foto\'s, video\'s en bestanden in deze mappen.';

  @override
  String get windowsRootsNotAvailable => 'Niet beschikbaar';

  @override
  String get windowsRootsAdd => 'Map toevoegen';

  @override
  String get windowsRootsAddConfirm => 'Toevoegen';

  @override
  String windowsRootsRemove(String folder) {
    return '$folder verwijderen';
  }

  @override
  String get windowsRootsReset => 'Standaardmappen herstellen';

  @override
  String get shareNotificationOpen => 'KFM openen';

  @override
  String get shareNotificationQuit => 'Afsluiten';

  @override
  String get shareKeepsRunningTray =>
      'Delen gaat door als je het venster sluit. Stop het hier of via het pictogram in het systeemvak.';

  @override
  String get trayNoticeTitle => 'KFM blijft delen';

  @override
  String get trayNoticeBody =>
      'KFM deelt deze pc nog steeds. Stop het via het pictogram in het systeemvak.';

  @override
  String get settingsStopSharingOnClose =>
      'Stoppen met delen als het venster sluit';

  @override
  String get settingsStopSharingOnCloseHint =>
      'Anders blijft KFM delen vanuit het systeemvak.';

  @override
  String get sharePublicNetwork => 'Je wifi staat op Openbaar';

  @override
  String get sharePublicNetworkHint =>
      'Zet het op Privé om te delen. Windows-instellingen → Netwerk en internet → Wifi → je netwerk → Particulier netwerk.';

  @override
  String get shareFirewallTitle => 'Windows vraagt naar de firewall';

  @override
  String get shareFirewallBody =>
      'Zodat je telefoon deze pc kan bereiken, vraagt Windows Firewall om KFM toe te staan. Sta het alleen toe op particuliere netwerken.';

  @override
  String get desktopNavSort => 'Sorteren';

  @override
  String get desktopNavDevices => 'Apparaten';

  @override
  String get desktopSidebarPlaces => 'Locaties';

  @override
  String get desktopSidebarCollections => 'Collecties';

  @override
  String get desktopFavorites => 'Favorieten';

  @override
  String get desktopSidebarCollapse => 'Zijbalk inklappen';

  @override
  String get desktopSidebarExpand => 'Zijbalk uitklappen';

  @override
  String get desktopNoPlaces => 'Nog geen mappen';

  @override
  String get desktopDetailsNothing =>
      'Selecteer een bestand om de details te zien';

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
    return '$count geselecteerd · $size';
  }

  @override
  String get desktopSortHistory => 'Geschiedenis';

  @override
  String get desktopSortHistoryEmpty => 'Nog niets gesorteerd';

  @override
  String get desktopSortUndoToHere => 'Tot hier ongedaan maken';

  @override
  String desktopSortUndoManyTitle(int count) {
    return '$count acties ongedaan maken?';
  }

  @override
  String desktopSortUndoManyBody(int count) {
    return 'De nieuwste $count acties worden een voor een ongedaan gemaakt, tot en met de actie waarop je klikte.';
  }

  @override
  String desktopSortUndoManyConfirm(int count) {
    return '$count ongedaan maken';
  }

  @override
  String get desktopSortSelectHint =>
      'Selecteer bestanden en kies wat ermee moet gebeuren';

  @override
  String desktopSortActed(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden',
      one: '1 bestand',
    );
    return '$label · $_temp0';
  }

  @override
  String get desktopLayoutLargeIcons => 'Grote pictogrammen';

  @override
  String get desktopLayoutGrid => 'Raster';

  @override
  String get desktopLayoutDetails => 'Details';

  @override
  String get desktopQuickLook => 'Snel bekijken';

  @override
  String get desktopClose => 'Sluiten';

  @override
  String get desktopPrevious => 'Vorige';

  @override
  String get desktopNext => 'Volgende';

  @override
  String desktopTypeFile(String ext) {
    return '$ext-bestand';
  }

  @override
  String get desktopTypeUnknown => 'Bestand';

  @override
  String get desktopTypeFolder => 'Map';

  @override
  String desktopQuickLookTitle(String name, String size, String date) {
    return '$name · $size · $date';
  }

  @override
  String desktopSortLeft(int count) {
    return 'Nog $count';
  }

  @override
  String get desktopBrowseBack => 'Terug';

  @override
  String get desktopBrowseForward => 'Vooruit';

  @override
  String get desktopBrowseUp => 'Een niveau omhoog';

  @override
  String get desktopBrowseOpen => 'Openen';

  @override
  String get desktopBrowseEmptyFolder => 'Deze map is leeg';

  @override
  String get desktopBrowseSortThese => 'Deze sorteren';

  @override
  String get desktopBrowseCopy => 'Kopiëren';

  @override
  String get desktopBrowseCut => 'Knippen';

  @override
  String get desktopBrowsePaste => 'Plakken';

  @override
  String get desktopBrowseNothingIndexed =>
      'KFM heeft hier nog geen bestanden gevonden';

  @override
  String desktopDragCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden',
      one: '1 bestand',
    );
    return '$_temp0';
  }

  @override
  String desktopDropMoveTo(String name) {
    return 'Verplaatsen naar $name';
  }

  @override
  String desktopDropCopyTo(String name) {
    return 'Kopiëren naar $name';
  }

  @override
  String desktopDropTag(String name) {
    return 'Tag $name toevoegen';
  }

  @override
  String get desktopDropFavorite => 'Toevoegen aan favorieten';

  @override
  String get desktopDropSend => 'Naar een apparaat sturen';

  @override
  String get desktopDropTrash => 'Naar prullenbak';

  @override
  String get desktopDropCtrlHint => 'Houd Ctrl ingedrukt om te kopiëren';

  @override
  String get desktopDropNothing => 'Niets om hierheen te kopiëren';

  @override
  String desktopDragOffer(String files, String action) {
    return '$files · $action';
  }

  @override
  String desktopTrashAll(int count) {
    return 'Alles ($count)';
  }

  @override
  String desktopTrashGroup(String name, String summary) {
    return '$name · $summary';
  }

  @override
  String get desktopTrashRecycleBin => 'Prullenbak';

  @override
  String get desktopTrashOriginalLocation => 'Oorspronkelijke locatie';

  @override
  String get desktopTrashDeleted => 'Verwijderd op';

  @override
  String get desktopTrashDaysLeft => 'Bewaard voor';

  @override
  String get desktopTrashWhere => 'Waar';

  @override
  String get desktopRefresh => 'Vernieuwen';

  @override
  String get desktopDevicesTitle => 'Een telefoon of andere pc verbinden';

  @override
  String get desktopDevicesHint =>
      'Beide apparaten hebben KFM en hetzelfde wifi-netwerk nodig. Er wordt niets gedeeld tot je hieronder kiest.';

  @override
  String get desktopDevicesShareHint =>
      'Toon een QR-code en een code voor je telefoon';

  @override
  String get desktopDevicesConnectHint =>
      'Verbind met een apparaat dat een code toont';

  @override
  String get desktopCompare => 'Vergelijken';

  @override
  String desktopCompareTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto\'s',
      one: '1 foto',
    );
    return '$_temp0 vergelijken';
  }

  @override
  String get desktopCompareHint =>
      'Cijfertoetsen wisselen Bewaren / Verwijderen · zoomen en schuiven doet alle foto\'s tegelijk';

  @override
  String desktopCompareRemove(int count) {
    return '$count verwijderen';
  }

  @override
  String get desktopCompareKeep => 'Bewaren';

  @override
  String get desktopCompareRemoveOne => 'Verwijderen';

  @override
  String desktopCompareFacts(String size, String resolution, String date) {
    return '$size · $resolution · $date';
  }

  @override
  String get desktopZoomIn => 'Inzoomen';

  @override
  String get desktopZoomOut => 'Uitzoomen';

  @override
  String get desktopZoomFit => 'Passend';

  @override
  String get desktopSortFavorite => 'Favoriet';

  @override
  String get desktopSortTag => 'Tag…';

  @override
  String get backupSettingDesktopBrowseLayout => 'Weergave van Bladeren op pc';

  @override
  String get backupSettingDesktopBrowseSort => 'Sortering van Bladeren op pc';

  @override
  String ejectWindowsInUse(String label) {
    return '$label wordt nog gebruikt door een ander programma. Sluit het en probeer het opnieuw.';
  }

  @override
  String ejectWindowsFailed(String label) {
    return 'Windows kon $label niet uitwerpen';
  }

  @override
  String desktopSystemDrive(String drive) {
    return 'Lokale schijf ($drive)';
  }

  @override
  String driveUsbUnnamed(String drive) {
    return 'USB-stick ($drive)';
  }

  @override
  String driveSdUnnamed(String drive) {
    return 'SD-kaart ($drive)';
  }

  @override
  String driveRemovableUnnamed(String drive) {
    return 'Verwisselbare schijf ($drive)';
  }

  @override
  String driveNetworkUnnamed(String drive) {
    return 'Netwerkschijf ($drive)';
  }

  @override
  String desktopSortPreset(String name) {
    return 'Voorinstelling: $name';
  }

  @override
  String get desktopSortManagePresets => 'Voorinstellingen beheren…';

  @override
  String get desktopSortSetup => 'Sorteerinstellingen…';

  @override
  String get videoPlay => 'Afspelen';

  @override
  String get videoPause => 'Pauzeren';

  @override
  String get videoSoundOn => 'Geluid aan';

  @override
  String get videoSoundOff => 'Geluid uit';

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
      other: '$folders mappen verplaatst',
      one: '1 map verplaatst',
      zero: 'Verplaatst',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files bestanden',
      one: '1 bestand',
    );
    return '$_temp0 ($_temp1)';
  }

  @override
  String opTreeCopied(int folders, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders mappen gekopieerd',
      one: '1 map gekopieerd',
      zero: 'Gekopieerd',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files bestanden',
      one: '1 bestand',
    );
    return '$_temp0 ($_temp1)';
  }

  @override
  String get opFolderIntoItself => 'Een map kan niet in zichzelf';

  @override
  String get jobsChannelProgress => 'Lopende overdrachten';

  @override
  String get jobsChannelProgressDescription =>
      'Voortgang van kopieën en overdrachten terwijl KFM op de achtergrond draait';

  @override
  String get jobsChannelResults => 'Voltooide overdrachten';

  @override
  String get jobsChannelResultsDescription =>
      'Meldt wanneer een kopie of overdracht klaar is';

  @override
  String jobsReceivingFrom(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden ontvangen van $device',
      one: '1 bestand ontvangen van $device',
    );
    return '$_temp0';
  }

  @override
  String jobsCombinedTitle(int count, String percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overdrachten · $percent',
      one: '1 overdracht · $percent',
    );
    return '$_temp0';
  }

  @override
  String jobsProgressLine(String done, String total) {
    return '$done van $total';
  }

  @override
  String jobsSpeedLine(String speed) {
    return '$speed/s';
  }

  @override
  String jobsTimeLeft(String time) {
    return 'nog $time';
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
    return '$hours u $minutes min';
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
    return 'Gepauzeerd · $title';
  }

  @override
  String jobsPausedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overdrachten gepauzeerd',
      one: '1 overdracht gepauzeerd',
    );
    return '$_temp0';
  }

  @override
  String get jobsPausedOpenKfm => 'Gepauzeerd, open KFM om verder te gaan';

  @override
  String get jobsWaiting => 'Wachten';

  @override
  String jobsEndSent(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden verzonden naar $device',
      one: '1 bestand verzonden naar $device',
    );
    return '$_temp0';
  }

  @override
  String jobsEndReceived(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden ontvangen van $device',
      one: '1 bestand ontvangen van $device',
    );
    return '$_temp0';
  }

  @override
  String jobsEndMovedTo(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden verplaatst naar $device',
      one: '1 bestand verplaatst naar $device',
    );
    return '$_temp0';
  }

  @override
  String jobsEndMovedFrom(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden verplaatst van $device',
      one: '1 bestand verplaatst van $device',
    );
    return '$_temp0';
  }

  @override
  String jobsEndCopied(int count, String place) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden gekopieerd naar $place',
      one: '1 bestand gekopieerd naar $place',
    );
    return '$_temp0';
  }

  @override
  String jobsEndMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overdrachten klaar',
      one: '1 overdracht klaar',
    );
    return '$_temp0';
  }

  @override
  String jobsEndFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden mislukt · Tik om te bekijken',
      one: '1 bestand mislukt · Tik om te bekijken',
    );
    return '$_temp0';
  }

  @override
  String get jobsNotificationsOff =>
      'Meldingen staan uit: overdrachten lopen door, maar de voortgang zie je alleen in KFM.';

  @override
  String jobsIndicatorLabel(String title, String percent) {
    return '$title, $percent. Overdrachten openen';
  }

  @override
  String get jobsQuitTitle => 'KFM afsluiten?';

  @override
  String jobsQuitBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Er lopen nog $count overdrachten. Afsluiten stopt ze; je kunt ze de volgende keer verder zetten in Overdrachten.',
      one: 'Er loopt nog 1 overdracht. Afsluiten stopt hem; je kunt hem de volgende keer verder zetten in Overdrachten.',
    );
    return '$_temp0';
  }

  @override
  String get jobsQuitAction => 'Afsluiten';

  @override
  String get jobsQuitKeep => 'Laten doorlopen';

  @override
  String get trayNoticeTransfersTitle => 'KFM gaat door met overdragen';

  @override
  String get trayNoticeTransfersBody =>
      'Overdrachten gaan op de achtergrond door. Open KFM weer via het pictogram in het systeemvak.';

  @override
  String jobsEndFailedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overdrachten mislukt',
      one: 'Overdracht mislukt',
    );
    return '$_temp0';
  }
}
