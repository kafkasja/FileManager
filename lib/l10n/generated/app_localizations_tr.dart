// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Kaf\'s File Manager';

  @override
  String get appTitleShort => 'KFM';

  @override
  String get tabSwipe => 'Kaydır';

  @override
  String get tabBrowse => 'Göz at';

  @override
  String get tabTrash => 'Çöp kutusu';

  @override
  String get tabSettings => 'Ayarlar';

  @override
  String get dbWriteError => 'Son değişikliğin kaydedilemedi.';

  @override
  String dbResetNotice(String name) {
    return 'KFM verileri bozulmuştu, bu yüzden KFM sıfırdan başladı. Fotoğraflarına ve dosyalarına dokunulmadı; oturumlar, etiketler ve ayarlar sıfırlandı. Bozuk kopya $name olarak saklandı.';
  }

  @override
  String get dbUnavailableNotice =>
      'KFM şu anda verilerini açamıyor. Başka bir program kullanıyor olabilir. Onu kapatıp KFM\'yi yeniden başlat. Dosyalarına dokunulmadı.';

  @override
  String get dismiss => 'Kapat';

  @override
  String get retry => 'Tekrar dene';

  @override
  String indexingCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dosya dizine ekleniyor…',
      one: '1 dosya dizine ekleniyor…',
    );
    return '$_temp0';
  }

  @override
  String get indexingPaused => 'Dizine ekleme duraklatıldı';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsAppearance => 'Görünüm';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get languageLabel => 'Dil';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get settingsAbout => 'Hakkında';

  @override
  String aboutVersion(String version) {
    return 'Sürüm $version';
  }

  @override
  String get aboutPromise =>
      'Reklam yok, hesap yok, takip yok. Her şey cihazında kalır.';

  @override
  String get permGateTitle =>
      'KFM\'nin fotoğraf ve videolarını görmesine izin ver';

  @override
  String get permGateWhy =>
      'Her şey telefonunda kalır. Hesap yok, yükleme yok.';

  @override
  String get permAllow => 'İzin ver';

  @override
  String get permOpenSettings => 'Ayarları aç';

  @override
  String get permPermanentlyDeniedHelp =>
      'Fotoğraf erişimi kapalı. Ayarlarda İzinler\'i aç ve Fotoğraflar ve videolar\'a izin ver.';

  @override
  String get permCheckFailed => 'İzinler kontrol edilemedi.';

  @override
  String get limitedBanner => 'KFM yalnızca bazı fotoğrafları görebiliyor.';

  @override
  String get limitedAllowAll => 'Tümüne izin ver';

  @override
  String get allFilesSheetText =>
      'Belgeleri ve indirilenleri de göstermek için Tüm dosyalara erişim\'i aç.';

  @override
  String get allFilesTurnOn => 'Aç';

  @override
  String get notNow => 'Şimdi değil';

  @override
  String get settingsPermissions => 'İzinler';

  @override
  String get permRowMedia => 'Fotoğraflar ve videolar';

  @override
  String get permRowAllFiles => 'Tüm dosyalara erişim';

  @override
  String get permRowMediaManagement => 'Onay pencerelerini atla';

  @override
  String get permRowMediaManagementHelp =>
      'İsteğe bağlı. KFM\'nin fotoğrafları her seferinde sormadan taşımasını ve silmesini sağlar (Medya yönetimi).';

  @override
  String get permStatusGranted => 'İzin verildi';

  @override
  String get permStatusLimited => 'Yalnızca bazı fotoğraflar';

  @override
  String get permStatusDenied => 'İzin verilmedi';

  @override
  String get permStatusNotAsked => 'Henüz sorulmadı';

  @override
  String get permStatusNotRequired => 'Bu telefonda gerekmiyor';

  @override
  String get permChange => 'Değiştir';

  @override
  String get settingsStorage => 'Depolama';

  @override
  String get thumbCacheTitle => 'Küçük resim önbelleği';

  @override
  String get thumbCacheSizeUnknown => 'Boyut bilinmiyor';

  @override
  String get thumbCacheClear => 'Temizle';

  @override
  String get settingsDeveloper => 'Geliştirici';

  @override
  String devIndexedFiles(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dizinde $countString dosya',
      one: 'Dizinde 1 dosya',
    );
    return '$_temp0';
  }

  @override
  String get devRescan => 'Baştan tara';

  @override
  String get devIndexList => 'Dizindeki dosyaları göster';

  @override
  String get swipeAllDone => 'Hepsi bitti! Tüm fotoğraf ve videolara baktın.';

  @override
  String get swipeEmptyLibrary => 'Fotoğraf veya video bulunamadı.';

  @override
  String get swipeLookingForPhotos => 'Fotoğraflar aranıyor…';

  @override
  String get swipeErrorGeneric => 'Fotoğrafların yüklenemedi.';

  @override
  String get swipeDone => 'Bitti';

  @override
  String get swipeFinishTitle => 'Bu oturum bitirilsin mi?';

  @override
  String get swipeFinishConfirm => 'Bitir';

  @override
  String get cancel => 'İptal';

  @override
  String get undo => 'Geri al';

  @override
  String get undoHistoryTitle => 'Son işlemler';

  @override
  String get undoRestored => 'Çöp kutusundan geri yüklendi';

  @override
  String get undoPermanentlyDeleted =>
      'Bu dosya kalıcı olarak silindi ve geri getirilemez.';

  @override
  String get undoFailed => 'Bu adım geri alınamadı.';

  @override
  String get undoNotPossibleYet => 'Bu işlem henüz geri alınamıyor.';

  @override
  String get deleteBatchRetry => 'Tekrar dene';

  @override
  String get deleteCommitFailed =>
      'Dosyalar şu anda silinemedi. Sırada bekliyorlar, hiçbir şey kaybolmadı.';

  @override
  String swipeProgress(int swiped, int remaining) {
    final intl.NumberFormat swipedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String swipedString = swipedNumberFormat.format(swiped);
    final intl.NumberFormat remainingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String remainingString = remainingNumberFormat.format(remaining);

    return '$swipedString bitti · $remainingString kaldı';
  }

  @override
  String swipeFinishTrash(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dosya çöp kutusuna taşınacak.',
      one: '1 dosya çöp kutusuna taşınacak.',
      zero: 'Silinmeyi bekleyen bir şey yok.',
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
      other: '$countString dosya kalıcı olarak silinecek.',
      one: '1 dosya kalıcı olarak silinecek.',
      zero: 'Silinmeyi bekleyen bir şey yok.',
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
      other: 'Oturum bitti: $countString dosya silindi ($size).',
      one: 'Oturum bitti: 1 dosya silindi ($size).',
      zero: 'Oturum bitti.',
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
      other: 'Oturum bitti: $countString dosya çöp kutusuna taşındı ($size).',
      one: 'Oturum bitti: 1 dosya çöp kutusuna taşındı ($size).',
      zero: 'Oturum bitti.',
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
      other: '$countString dosya silinmeyi bekliyor',
      one: '1 dosya silinmeyi bekliyor',
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
      other: '$countString dosya silinemedi',
      one: '1 dosya silinemedi',
    );
    return '$_temp0';
  }

  @override
  String get settingsDeleting => 'Silme';

  @override
  String get deleteModeTrash => 'Çöp kutusuna taşı (önerilen)';

  @override
  String get deleteModePermanent => 'Kalıcı olarak sil';

  @override
  String get deleteModePermanentHelp =>
      'Kaydırılan dosyalar tamamen silinir. Kurtarma yok.';

  @override
  String get deleteModePermanentWarning =>
      'Bu şekilde silinen dosyalar geri yüklenemez, geri al ile bile.';

  @override
  String get deleteModeNextSession => 'Sonraki oturumundan itibaren geçerli.';

  @override
  String get pendingRetentionLabel => 'Bekleyen dosyaları saklama süresi';

  @override
  String get pendingRetentionHelp =>
      'Belgeler ve diğer dosyalar (ve Android 10 ve öncesinde fotoğraflar) tamamen silinmeden önce gizli bir klasörde bekler.';

  @override
  String get pendingEmptyNow => 'Bekleme klasörünü şimdi boşalt';

  @override
  String get pendingEmptyTitle => 'Bekleme klasöründeki her şey silinsin mi?';

  @override
  String get pendingEmptyBody => 'Bu dosyalar sonradan geri yüklenemez.';

  @override
  String get pendingEmptyConfirm => 'Sil';

  @override
  String get permanentConfirmTitle => 'Bu oturumda kalıcı olarak silinsin mi?';

  @override
  String get permanentConfirmBody =>
      'Çöp kutusuna kaydırdığın dosyalar tamamen silinecek. Geri yüklenemezler.';

  @override
  String get permanentConfirmYes => 'Kalıcı olarak sil';

  @override
  String get permanentConfirmUseTrash => 'Çöp kutusunu kullan';

  @override
  String pendingRetentionDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString gün',
      one: '1 gün',
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
      other: '$countString dosya silindi.',
      one: '1 dosya silindi.',
      zero: 'Bekleme klasörü boş.',
    );
    return '$_temp0';
  }

  @override
  String get trashSystem => 'Sistem çöp kutusu';

  @override
  String get trashPending => 'Silinmeyi bekleyenler';

  @override
  String get trashNothingHere => 'Burada bir şey yok';

  @override
  String get trashExpiresToday => 'Bugün sona eriyor';

  @override
  String get trashSelect => 'Seç';

  @override
  String get trashRestore => 'Geri yükle';

  @override
  String get trashDeleteForever => 'Tamamen sil';

  @override
  String get trashDeleteForeverBody => 'Bu işlem geri alınamaz.';

  @override
  String get trashEmptySection => 'Bu bölümü boşalt';

  @override
  String get trashCancelled => 'İptal edildi';

  @override
  String get trashAlreadyRemoved => 'Bazı öğeler zaten kaldırılmıştı.';

  @override
  String get trashSystemHelp =>
      'Fotoğraf ve videolar Android tarafından 30 gün saklanır. Galeri uygulamanın da kendi çöp kutusu olabilir.';

  @override
  String get trashLoadFailed => 'Çöp kutusu yüklenemedi.';

  @override
  String get trashNeedsPermission =>
      'Çöp kutusunu görmek için fotoğraf ve videolara erişime izin ver.';

  @override
  String trashDaysLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString gün kaldı',
      one: '1 gün kaldı',
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
      other: '$countString öğe tamamen silinsin mi?',
      one: '1 öğe tamamen silinsin mi?',
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
      other: '$countString öğe geri yüklendi',
      one: '1 öğe geri yüklendi',
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
      other: '$countString seçili',
      one: '1 seçili',
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
      other: '$countString öğe',
      one: '1 öğe',
    );
    return '$_temp0 · $size';
  }

  @override
  String get labelTrash => '→ Çöp kutusu';

  @override
  String get labelDelete => '→ Sil';

  @override
  String get labelKept => '→ Saklandı';

  @override
  String get labelFavorite => '★ Favori';

  @override
  String get labelRenameBatch => '→ Toplu yeniden adlandırma';

  @override
  String get settingsSwipe => 'Kaydırma';

  @override
  String get settingsHaptics => 'Titreşim';

  @override
  String get settingsHapticsHelp => 'Kaydırma tamamlanınca kısa bir titreşim.';

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
  String get restoredSnack => 'Kaldığın yerden devam edildi';

  @override
  String get restoredStartFresh => 'Baştan başla';

  @override
  String get clearMenu => 'Temizle…';

  @override
  String get clearResetLayout => 'İşlem düğmelerini sıfırla';

  @override
  String get clearResetLayoutHelp =>
      'Varsayılana dön: sol = çöp kutusu, sağ = sakla';

  @override
  String get clearNewSession => 'Yeni oturum başlat';

  @override
  String get clearNewSessionHelp =>
      'Bu oturumun ilerlemesini ve geri alma geçmişini sonlandırır.';

  @override
  String get clearConfirm => 'Temizle';

  @override
  String get layoutResetDone => 'İşlem düğmeleri sıfırlandı';

  @override
  String get undoAction => 'Geri al';

  @override
  String get newSessionFailed =>
      'Silme işlemleri tamamlanamadı, bu yüzden oturum devam ediyor. Tekrar dene.';

  @override
  String get settingsFreshStart => 'Temizle / baştan başla…';

  @override
  String newFilesChip(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString yeni fotoğraf · Göster',
      one: '1 yeni fotoğraf · Göster',
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
      other: 'Bekleyen $countString silme işlemi yapılacak.',
      one: 'Bekleyen 1 silme işlemi yapılacak.',
      zero: 'Silinmeyi bekleyen bir şey yok.',
    );
    return '$_temp0';
  }

  @override
  String get viewerClose => 'Kapat';

  @override
  String get videoCantPlay => 'Bu video oynatılamıyor';

  @override
  String get videoDamaged => 'Bu dosya oynatılamıyor — hasarlı olabilir';

  @override
  String get imageDamaged => 'Bu dosya gösterilemiyor — hasarlı olabilir';

  @override
  String get videoTapForSound => 'Ses için dokun';

  @override
  String get videoOpenFullscreen => 'Tam ekran aç';

  @override
  String get customizeSwipes => 'Kaydırmaları özelleştir';

  @override
  String get customizeSwipesHelp => 'Her kaydırma yönünün ne yapacağını seç';

  @override
  String get customizeSwipesIntro =>
      'O yöne kaydırmanın ne yapacağını değiştirmek için bir oka dokun.';

  @override
  String get swipeDirectionLeft => 'Sola kaydır';

  @override
  String get swipeDirectionRight => 'Sağa kaydır';

  @override
  String get swipeDirectionUp => 'Yukarı kaydır';

  @override
  String get swipeDirectionDown => 'Aşağı kaydır';

  @override
  String get swipeActionNothing => 'Hiçbir şey';

  @override
  String get swipeActionTrash => 'Çöp kutusuna taşı';

  @override
  String get swipeActionDelete => 'Kalıcı olarak sil';

  @override
  String get swipeActionKeep => 'Sakla';

  @override
  String get swipeActionNeedOne => 'En az bir yöne bir işlem atanmalı';

  @override
  String get swipeLayoutReset => 'Temel ayarlara sıfırla';

  @override
  String get swipeLayoutResetTitle => 'Kaydırmalar sıfırlansın mı?';

  @override
  String get swipeLayoutResetBody =>
      'Sol tekrar çöp kutusu, sağ sakla olur. Yukarı ve aşağı hiçbir şey yapmaz.';

  @override
  String get reset => 'Sıfırla';

  @override
  String get swipeActionMoveTo => 'Klasöre taşı…';

  @override
  String get swipeActionCopyTo => 'Klasöre kopyala…';

  @override
  String get swipeActionAddTag => 'Etiket ekle…';

  @override
  String get swipeActionFavorite => 'Favorilere ekle';

  @override
  String swipeActionMoveToNamed(String folder) {
    return 'Taşı: $folder';
  }

  @override
  String swipeActionCopyToNamed(String folder) {
    return 'Kopyala: $folder';
  }

  @override
  String swipeActionTagNamed(String tag) {
    return 'Etiket: $tag';
  }

  @override
  String get swipeActionTagMissing => 'Etiket artık yok';

  @override
  String get moveConsentNotice => 'Android her taşımadan önce sorabilir';

  @override
  String get turnOn => 'Aç';

  @override
  String get folderPickerTitle => 'Klasör seç';

  @override
  String get folderPickerRecent => 'Son kullanılanlar';

  @override
  String get folderPickerWithPhotos => 'Fotoğraf içeren klasörler';

  @override
  String get folderPickerNew => 'Yeni klasör…';

  @override
  String get folderPickerNewTitle => 'Yeni klasör';

  @override
  String folderPickerNewIn(String folder) {
    return 'Konum: $folder';
  }

  @override
  String get folderNameHint => 'Klasör adı';

  @override
  String get folderNameInvalid => 'Bu ad kullanılamaz';

  @override
  String get folderNeedsAllFiles => 'Tüm dosyalara erişim gerekli';

  @override
  String folderFileCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dosya',
      one: '1 dosya',
    );
    return '$_temp0';
  }

  @override
  String get create => 'Oluştur';

  @override
  String get tagPickerTitle => 'Etiket seç';

  @override
  String get tagPickerNew => 'Yeni etiket…';

  @override
  String get tagNewTitle => 'Yeni etiket';

  @override
  String get tagNameHint => 'Etiket adı';

  @override
  String get tagNameTaken => 'Bu adda bir etiket zaten var';

  @override
  String get tagNameInvalid => '1 ile 40 karakter arası kullan';

  @override
  String get tagsEmpty => 'Henüz etiket yok';

  @override
  String get swipeProblemTagMissing =>
      'Etiket artık yok. Kaydırmaları özelleştir\'den değiştir.';

  @override
  String get swipeProblemUnsupported => 'Bu kaydırma henüz kullanılamıyor';

  @override
  String get fileOpFolderMissing =>
      'Klasör bulunamadı. Kaydırmaları özelleştir\'den yeniden seç.';

  @override
  String get fileOpDeclined => 'Taşınmadı: izin reddedildi';

  @override
  String get fileOpNoSpace => 'Yeterli alan yok';

  @override
  String get fileOpNeedsAllFiles =>
      'Bu klasör için Tüm dosyalara erişim gerekli';

  @override
  String fileOpMoveFailed(String name) {
    return 'Taşınamadı: $name';
  }

  @override
  String fileOpCopyFailed(String name) {
    return 'Kopyalanamadı: $name';
  }

  @override
  String get undoneLabel => '↩ Geri alındı';

  @override
  String get swipeActionRenameBatch => 'Toplu yeniden adlandırmaya ekle';

  @override
  String renamePill(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '✎ $countString';
  }

  @override
  String get renameTitle => 'Toplu yeniden adlandırma';

  @override
  String get renamePatternLabel => 'Ad kalıbı';

  @override
  String renamePatternHint(String n) {
    return 'tatil_$n';
  }

  @override
  String get renameStart => 'Başlangıç';

  @override
  String get renamePadding => 'Basamak';

  @override
  String renameTokensHelp(String n, String date, String orig) {
    return '$n = numara · $date = tarih · $orig = orijinal ad';
  }

  @override
  String get renameMissing => 'Eksik veya değişmiş: atlandı';

  @override
  String renameCollision(String name) {
    return 'Ad kullanımdaydı: bunun yerine \"$name\" kullanıldı';
  }

  @override
  String get renameApply => 'Yeniden adlandır';

  @override
  String get renameDiscard => 'Toplu işlemi sil';

  @override
  String get renameDiscardTitle => 'Bu toplu yeniden adlandırma silinsin mi?';

  @override
  String get renameDiscardBody =>
      'Dosyalar olduğu gibi kalır; yalnızca toplu işlem kaldırılır.';

  @override
  String get renameErrorEmpty => 'Bir ad kalıbı yaz';

  @override
  String get renameErrorInvalid =>
      'Bu karakterler kullanılamaz: / \\ : * ? \" < > |';

  @override
  String renameErrorNeedsCounter(String n) {
    return 'Her dosyanın kendi numarası olması için $n ekle';
  }

  @override
  String get renameErrorTooLong => 'Adlar çok uzun olur';

  @override
  String get renameRunning => 'Yeniden adlandırılıyor…';

  @override
  String renameDone(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dosya yeniden adlandırıldı',
      one: '1 dosya yeniden adlandırıldı',
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

    return 'Yeniden adlandırılan: $renamedString · atlanan: $skippedString';
  }

  @override
  String get renameDeclined =>
      'Hiçbir şey yeniden adlandırılmadı: izin reddedildi';

  @override
  String get renameNoUndoAfterDone =>
      'Bitti\'ye dokunana kadar bunu geri alabilirsin.';

  @override
  String renameBeforeFinishTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Önce $countString dosya yeniden adlandırılsın mı?',
      one: 'Önce 1 dosya yeniden adlandırılsın mı?',
    );
    return '$_temp0';
  }

  @override
  String get renameBeforeFinishBody =>
      'Toplu yeniden adlandırma henüz uygulanmadı. Atarsan mevcut adlar korunur.';

  @override
  String get renameOpen => 'Yeniden adlandır…';

  @override
  String get labelRenameApplied => '✎ Toplu adlandırıldı';

  @override
  String clearRenameDropped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Toplu yeniden adlandırmadaki $countString dosya çıkarılacak',
      one: 'Toplu yeniden adlandırmadaki 1 dosya çıkarılacak',
    );
    return '$_temp0';
  }

  @override
  String get barTrash => 'Çöp kutusu';

  @override
  String get barDelete => 'Sil';

  @override
  String get barKeep => 'Sakla';

  @override
  String get barFavorite => 'Favori';

  @override
  String get barRename => 'Yeniden adlandır';

  @override
  String get actionBarTitle => 'İşlem çubuğu';

  @override
  String get actionBarHelp => 'Kartın altında ek düğmeler';

  @override
  String get actionBarAdd => 'İşlem ekle';

  @override
  String get actionBarEmpty => 'Henüz düğme yok';

  @override
  String get actionBarRemove => 'Kaldır';

  @override
  String get actionBarFull => 'En fazla 8 düğme';

  @override
  String get filterTitle => 'Filtre';

  @override
  String get filterButton => 'Filtre';

  @override
  String get filterKinds => 'Göster';

  @override
  String get filterPhotos => 'Fotoğraflar';

  @override
  String get filterVideos => 'Videolar';

  @override
  String get filterScreenshotsOnly => 'Yalnızca ekran görüntüleri';

  @override
  String get filterDate => 'Tarih';

  @override
  String get filterAny => 'Tümü';

  @override
  String get filterThisMonth => 'Bu ay';

  @override
  String get filterLast30Days => 'Son 30 gün';

  @override
  String get filterCustomRange => 'Tarih seç…';

  @override
  String filterRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get filterSize => 'Boyut';

  @override
  String filterOverMb(int mb) {
    final intl.NumberFormat mbNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String mbString = mbNumberFormat.format(mb);

    return '$mbString MB üzeri';
  }

  @override
  String get filterFolders => 'Klasörler';

  @override
  String filterFolderCount(String folder, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$folder ($countString)';
  }

  @override
  String filterFolderMissing(String folder) {
    return '$folder (bulunamadı)';
  }

  @override
  String get filterTags => 'Etiketler';

  @override
  String get filterTagged => 'Etiketli';

  @override
  String get filterUntagged => 'Etiketsiz';

  @override
  String get filterSpecificTags => 'Belirli…';

  @override
  String get filterFavoritesOnly => 'Yalnızca favoriler';

  @override
  String filterMatches(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dosya eşleşiyor',
      one: '1 dosya eşleşiyor',
      zero: 'Eşleşen dosya yok',
    );
    return '$_temp0';
  }

  @override
  String get filterApply => 'Uygula';

  @override
  String get filterProblemSize => 'En küçük boyut en büyük boyuttan fazla';

  @override
  String get filterProblemTags => 'En az bir etiket seç';

  @override
  String get filterProblemDate => 'Başlangıç tarihi bitiş tarihinden sonra';

  @override
  String get filterNoMatches => 'Bu filtreyle eşleşen dosya yok';

  @override
  String get filterAllDone => 'Eşleşen tüm dosyalar bitti';

  @override
  String get filterChange => 'Filtreyi değiştir';

  @override
  String get presetBasic => 'Temel';

  @override
  String get presetChipTooltip => 'Hazır ayarı değiştir';

  @override
  String get presetSheetTitle => 'Hazır ayarlar';

  @override
  String get presetManage => 'Hazır ayarları yönet';

  @override
  String get presetSaveAs => 'Hazır ayar olarak kaydet…';

  @override
  String get presetNameLabel => 'Hazır ayar adı';

  @override
  String get presetIncludeFilter => 'Geçerli filtreyi de ekle';

  @override
  String presetSaved(String name) {
    return '“$name” kaydedildi';
  }

  @override
  String get presetNameTaken => 'Bu adda bir hazır ayar zaten var';

  @override
  String get presetNameInvalid => '1 ile 40 karakter arası kullan';

  @override
  String get presetRename => 'Yeniden adlandır';

  @override
  String get presetEdit => 'Düzenle';

  @override
  String get presetDuplicate => 'Çoğalt';

  @override
  String get presetDelete => 'Sil';

  @override
  String presetDeleteConfirm(String name) {
    return '“$name” silinsin mi?';
  }

  @override
  String get presetDeleteBody =>
      'Yarım kalan oturumu sona erer. Dosyalarına dokunulmaz.';

  @override
  String get presetLoadError => 'Yüklenemedi: düzenle veya sil';

  @override
  String presetNoSessionHint(String name) {
    return 'O oturumun düğmelerini değiştirmek için $name ile kaydırmaya başla ya da hazır ayarı Hazır ayarları yönet bölümünden düzenle.';
  }

  @override
  String get presetEditorTitle => 'Hazır ayarı düzenle';

  @override
  String get presetDirections => 'Kaydırma düğmeleri';

  @override
  String get presetFilter => 'Filtre';

  @override
  String get presetEditorFilterNone => 'Filtre yok';

  @override
  String get presetEditorFilterOn => 'Filtre ayarlı';

  @override
  String get presetEditorSave => 'Kaydet';

  @override
  String get presetEditorReplacesSession =>
      'Bu hazır ayarın yarım kalan oturumunun ayarlarını da değiştirir';

  @override
  String get presetEditorDiscard => 'Değişiklikler silinsin mi?';

  @override
  String get presetDiscard => 'Sil';

  @override
  String presetSwitchBlocked(String name) {
    return 'Silme işlemleri tamamlanamadı, bu yüzden hâlâ $name etkin. Tekrar dene.';
  }

  @override
  String get presetEmptyTitle => 'Henüz hazır ayar yok';

  @override
  String get presetEmptyBody =>
      'Hazır ayar, kaydırma düğmelerini ve istersen bir filtreyi kaydeder. Aralarında tek dokunuşla geçiş yap.';

  @override
  String get presetEmptyQuickCleanup => 'Hızlı temizlik';

  @override
  String get presetEmptyQuickCleanupHelp =>
      'Sol = çöp kutusu, sağ = sakla, yalnızca ekran görüntüleri';

  @override
  String get presetEmptySortHoliday => 'Tatili düzenle';

  @override
  String get presetEmptySortHolidayHelp =>
      'Sol = çöp kutusu, sağ = klasöre taşı, yukarı = favori';

  @override
  String get presetCreate => 'Oluştur';

  @override
  String get presetNew => 'Yeni hazır ayar';

  @override
  String get settingsPresets => 'Hazır ayarlar';

  @override
  String get settingsPresetsHelp => 'Kayıtlı kaydırma ayarları';

  @override
  String get reviewedBadge => 'İncelendi';

  @override
  String get settingsShowReviewedBadge => 'İncelendi işaretini göster';

  @override
  String get settingsShowReviewedBadgeHelp =>
      'Daha önce kaydırdığın dosyalarda küçük bir işaret';

  @override
  String get reviewedIncludeToggle =>
      'Burada zaten incelenen dosyaları da dahil et';

  @override
  String get filterReviewed => 'İncelendi';

  @override
  String get filterReviewedOnly => 'İncelendi';

  @override
  String get filterNotReviewed => 'İncelenmedi';

  @override
  String reviewedInfoLine(String preset, String action, String date) {
    return 'İncelendiği yer: $preset · $action · $date';
  }

  @override
  String get reviewedReset => 'İncelendi işaretlerini sıfırla…';

  @override
  String get reviewedResetAll => 'Tüm hazır ayarlar';

  @override
  String reviewedResetConfirm(String name) {
    return '$name için incelendi işaretleri sıfırlansın mı? Bu işlem geri alınamaz.';
  }

  @override
  String reviewedResetCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dosya',
      one: '1 dosya',
      zero: 'Dosya yok',
    );
    return '$_temp0';
  }

  @override
  String get reviewedResetDone => 'İncelendi işaretleri sıfırlandı';

  @override
  String get presetIncludeReviewed =>
      'Bu hazır ayarda zaten incelenen dosyaları da dahil et';

  @override
  String get settingsStats => 'Kaydırma istatistikleri';

  @override
  String get settingsStatsHelp => 'İncelenen dosyalar ve boşaltılan alan';

  @override
  String get settingsShowSessionSummary => 'Bitti\'den sonra özet göster';

  @override
  String get statsTitle => 'Kaydırma istatistikleri';

  @override
  String statsInTrashFreed(String inTrash, String freed) {
    return 'Çöp kutusunda $inTrash · $freed boşaltıldı';
  }

  @override
  String get statsGoToTrash => 'Çöp kutusuna git';

  @override
  String get statsThisWeek => 'Bu hafta';

  @override
  String get statsThisMonth => 'Bu ay';

  @override
  String get statsAllTime => 'Tüm zamanlar';

  @override
  String statsReviewed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dosya incelendi',
      one: '1 dosya incelendi',
    );
    return '$_temp0';
  }

  @override
  String statsFreed(String size) {
    return '$size boşaltıldı';
  }

  @override
  String statsRowLine(String reviewed, String freed) {
    return '$reviewed · $freed';
  }

  @override
  String get statsByPreset => 'Hazır ayara göre';

  @override
  String get statsDeletedPresets => 'Silinen hazır ayarlar';

  @override
  String get statsWeekly => 'Son 8 hafta';

  @override
  String get statsReset => 'İstatistikleri sıfırla';

  @override
  String get statsResetConfirm =>
      'İncelenen ve boşaltılan sayaçları sıfırlansın mı? Çöp kutusundaki dosyalar sayılmaya devam eder.';

  @override
  String get summaryTitle => 'Oturum bitti';

  @override
  String summaryReviewed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dosya inceledin',
      one: '1 dosya inceledin',
    );
    return '$_temp0';
  }

  @override
  String summaryToTrash(String size) {
    return '$size çöp kutusuna taşındı';
  }

  @override
  String summaryFreed(String size) {
    return '$size boşaltıldı';
  }

  @override
  String get ok => 'Tamam';

  @override
  String get settingsSwipeButtons => 'Kaydırmak yerine düğmeleri kullan';

  @override
  String get settingsSwipeButtonsHelp =>
      'Her kaydırmanın yaptığını düğmelere dokunarak yap';

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
  String get fileKindPhoto => 'Fotoğraf';

  @override
  String get fileKindVideo => 'Video';

  @override
  String swipeButtonSemantics(String action, String direction) {
    return '$action, $direction';
  }

  @override
  String get pendingRetentionCustom => 'Özel…';

  @override
  String get pendingRetentionCustomTitle => 'Bekleyen dosyaları saklama süresi';

  @override
  String get pendingRetentionCustomHelper => '1–90 gün';

  @override
  String get pendingRetentionCustomError => '1 ile 90 arasında bir sayı gir';

  @override
  String get pendingRetentionCustomSave => 'Kaydet';

  @override
  String get pendingPurgeFailedPermission =>
      'Otomatik temizlik çalışamadı: izin gerekiyor';

  @override
  String get pendingPurgeFailed => 'Otomatik temizlik çalışamadı';

  @override
  String pendingUnavailableSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya bekleme klasörüne taşınamadı. Hâlâ cihazında.',
      one: '1 dosya bekleme klasörüne taşınamadı. Hâlâ cihazında.',
    );
    return '$_temp0';
  }

  @override
  String pendingUnavailableBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya silinmedi: bekleme klasörü kullanılamıyor',
      one: '1 dosya silinmedi: bekleme klasörü kullanılamıyor',
    );
    return '$_temp0';
  }

  @override
  String get pendingUnavailableOptions => 'Seçenekler';

  @override
  String pendingUnavailableAfterDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya silinmedi. Çöp kutusunda bulabilirsin.',
      one: '1 dosya silinmedi. Çöp kutusunda bulabilirsin.',
    );
    return '$_temp0';
  }

  @override
  String get pendingUnavailableTitle => 'Bekleme klasörüne taşınamadı';

  @override
  String get pendingUnavailableBody =>
      'KFM bu dosyaları bekleme klasörüne koyamadığı için dosyalar silinmedi.';

  @override
  String get pendingUnavailableGrantAccess =>
      'KFM\'nin klasörü kullanabilmesi için Tüm dosyalara erişim izni ver';

  @override
  String get pendingUnavailableWarning =>
      'Kalıcı olarak silme geri alınamaz. Bu dosyalar çöp kutusuna gitmez ve geri yüklenemez.';

  @override
  String get pendingUnavailableKeep => 'Sakla';

  @override
  String get pendingUnavailableDeleteOne => 'Kalıcı olarak sil';

  @override
  String pendingUnavailableDeleteAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosyanın tümünü kalıcı olarak sil',
      one: '1 dosyayı kalıcı olarak sil',
    );
    return '$_temp0';
  }

  @override
  String pendingUnavailableConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya kalıcı olarak silinsin mi?',
      one: 'Bu dosya kalıcı olarak silinsin mi?',
    );
    return '$_temp0 Bu işlem geri alınamaz.';
  }

  @override
  String get pendingUnavailableConfirmButton => 'Kalıcı olarak sil';

  @override
  String pendingUnavailableDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya kalıcı olarak silindi',
      one: '1 dosya kalıcı olarak silindi',
    );
    return '$_temp0';
  }

  @override
  String get pendingUnavailableSection => 'Bekleme klasörüne taşınamadı';

  @override
  String get trashSort => 'Sırala';

  @override
  String get trashSortExpiry => 'Süresi en yakın dolan';

  @override
  String get trashSortNewest => 'En son silinen';

  @override
  String get swipeEmptyLibraryHint =>
      'Telefonunda fotoğraf varsa KFM\'nin bunları görme izni olmayabilir. Telefonunun ayarlarından KFM\'nin izinlerini kontrol et.';

  @override
  String get browseKindAll => 'Tümü';

  @override
  String get browseKindImages => 'Görseller';

  @override
  String get browseKindVideos => 'Videolar';

  @override
  String get browseKindAudio => 'Ses';

  @override
  String get browseKindDocuments => 'Belgeler';

  @override
  String get browseKindArchives => 'Arşivler';

  @override
  String get browseKindOther => 'Diğer';

  @override
  String get browseSourceCamera => 'Kamera';

  @override
  String get browseSourceScreenshots => 'Ekran görüntüleri';

  @override
  String get browseSourceWhatsapp => 'WhatsApp';

  @override
  String get browseSourceSnapchat => 'Snapchat';

  @override
  String get browseSourceDownloads => 'İndirilenler';

  @override
  String get browseSourceVideos => 'Videolar';

  @override
  String get browseSourcePanoramas => 'Panoramalar';

  @override
  String get browseSourceScreenRecordings => 'Ekran kayıtları';

  @override
  String get browseSourceExpertRaw => 'Expert RAW';

  @override
  String get browseSourceGifs => 'GIF\'ler';

  @override
  String get browseSourceCollages => 'Kolajlar';

  @override
  String get browseSourceClippedImages => 'Kırpılmış görseller';

  @override
  String get browseSourceLiveMessages => 'Canlı mesajlar';

  @override
  String get browseSourceVideoCaptures => 'Video kareleri';

  @override
  String get browseSourceTelegram => 'Telegram';

  @override
  String get browseSourceInstagram => 'Instagram';

  @override
  String get browseSourceOther => 'Diğer uygulamalar';

  @override
  String get browseSourceHidden => 'Gizli';

  @override
  String get browsePanoramaHint =>
      'Tahmini: geniş fotoğraflar ve PANO dosyaları';

  @override
  String get browseModeAll => 'Tüm dosyalar';

  @override
  String get browseModeFolders => 'Klasörler';

  @override
  String get browseShowHidden => 'Gizli dosyaları göster';

  @override
  String get browseSwipeThese => 'Bunları kaydır';

  @override
  String get browseNeedsAllFiles =>
      'Belgeleri, indirilenleri ve gizli dosyaları görmek için erişim izni ver';

  @override
  String get browseGrantAccess => 'Erişim izni ver';

  @override
  String get browseEmpty => 'Burada dosya yok';

  @override
  String searchKwType(String name) {
    return 'Tür: $name';
  }

  @override
  String searchKwSource(String name) {
    return 'Kaynak: $name';
  }

  @override
  String get searchKwHidden => 'Gizli dosyalar';

  @override
  String get searchKwTiny => 'Çok küçük (< 10 KB)';

  @override
  String get searchKwLarge => 'Büyük (> 100 MB)';

  @override
  String get searchKwToday => 'Bugün';

  @override
  String get searchKwWeek => 'Son 7 gün';

  @override
  String searchTermsLoadError(String language) {
    return 'Arama sözcükleri yüklenemedi: $language';
  }

  @override
  String get searchSettingsTitle => 'Arama';

  @override
  String get searchSettingsAlsoSearchIn => 'Şu dilde de ara';

  @override
  String get searchSettingsAlsoSearchInHelp =>
      '\'video\' veya \'bulut\' gibi akıllı sözcükler bu dilde de çalışır.';

  @override
  String get searchSettingsNone => 'Hiçbiri';

  @override
  String searchSettingsAlreadyIncluded(String language) {
    return '$language (zaten dahil)';
  }

  @override
  String get searchSettingsTip =>
      'Filtrelemek için \'video\', \'pdf\', \'whatsapp\', \'gizli\' veya \'büyük\' gibi sözcükler yaz. Bunun yerine adda aramak için çipteki ✕ simgesine dokun.';

  @override
  String get searchOpen => 'Ara';

  @override
  String get searchHint => 'Dosya ara';

  @override
  String get searchClearText => 'Aramayı temizle';

  @override
  String get searchChipType => 'Tür';

  @override
  String searchChipTypes(int count) {
    return '$count tür';
  }

  @override
  String get searchChipSource => 'Kaynak';

  @override
  String get searchChipDate => 'Tarih';

  @override
  String get searchDateToday => 'Bugün';

  @override
  String get searchDateWeek => 'Son 7 gün';

  @override
  String get searchDateMonth => 'Bu ay';

  @override
  String get searchDateYear => 'Bu yıl';

  @override
  String get searchDateCustom => 'Özel…';

  @override
  String searchDateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String searchDateSince(String from) {
    return 'Başlangıç: $from';
  }

  @override
  String get searchChipSize => 'Boyut';

  @override
  String searchSizeOver(String size) {
    return '> $size';
  }

  @override
  String searchSizeUnder(String size) {
    return '< $size';
  }

  @override
  String get searchSizeTiny => 'Çok küçük (< 10 KB)';

  @override
  String searchSizeBetween(String min, String max) {
    return '$min – $max';
  }

  @override
  String get searchSizeCustom => 'Özel…';

  @override
  String get searchSizeCustomTitle => 'Dosya boyutu';

  @override
  String get searchSizeMinLabel => 'En az (MB)';

  @override
  String get searchSizeMaxLabel => 'En fazla (MB)';

  @override
  String get searchSizeInvalid =>
      'En küçük değer en büyük değerden fazla olamaz';

  @override
  String get searchChipHidden => 'Gizli dosyalar';

  @override
  String get searchHiddenInclude => 'Gizli dosyaları dahil et';

  @override
  String get searchHiddenOnly => 'Yalnızca gizli dosyalar';

  @override
  String searchOnlyIn(String folder) {
    return 'Yalnızca şurada: $folder';
  }

  @override
  String searchTokenExtension(String ext) {
    return 'Tür: .$ext';
  }

  @override
  String searchTokenAsName(String word) {
    return 'Bunun yerine adlarda “$word” ara';
  }

  @override
  String get searchRecent => 'Son aramalar';

  @override
  String get searchSuggestions => 'Dene';

  @override
  String get searchSuggestLarge => 'Büyük dosyalar';

  @override
  String get searchSuggestDownloads => 'İndirilenler';

  @override
  String get searchSuggestPdfs => 'PDF\'ler';

  @override
  String get searchSuggestHidden => 'Gizli dosyalar';

  @override
  String get searchSuggestWeek => 'Bu hafta';

  @override
  String get searchNoMatch => 'Eşleşen dosya yok';

  @override
  String get searchClearFilters => 'Filtreleri temizle';

  @override
  String searchWordsLoadError(String languages) {
    return 'Arama kelimeleri yüklenemedi ($languages)';
  }

  @override
  String get searchDone => 'Bitti';

  @override
  String get browseLoadError => 'Dosyalar yüklenemedi.';

  @override
  String get browseOtherHint =>
      'Diğer uygulama ve klasörlerdeki dosyalar, klasöre göre gruplanmış';

  @override
  String get browseInternalStorage => 'Dahili depolama';

  @override
  String browseExternalVolume(String name) {
    return 'SD kart veya USB ($name)';
  }

  @override
  String browseFileCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dosya',
      one: '1 dosya',
    );
    return '$_temp0';
  }

  @override
  String get browseStorageRoot => 'Depolama';

  @override
  String get browseFolderMenu => 'Klasör seçenekleri';

  @override
  String get openWith => 'Birlikte aç';

  @override
  String get openWithNone => 'Bu dosyayı açabilecek uygulama yok';

  @override
  String get openWithFailed => 'Bu dosya açılamadı.';

  @override
  String get textViewerTruncated => 'İlk 1 MB gösteriliyor';

  @override
  String get textViewerLatin1 => 'Latin-1 olarak gösteriliyor (UTF-8 değil)';

  @override
  String get textViewerBinary => 'Bu bir metin dosyasına benzemiyor';

  @override
  String get textViewerError => 'Bu dosya okunamadı.';

  @override
  String get browseSortTitle => 'Sıralama ölçütü';

  @override
  String get browseSortDate => 'Tarih';

  @override
  String get browseSortSize => 'Boyut';

  @override
  String get browseSortName => 'Ad';

  @override
  String get browseSortNewestFirst => 'Önce en yeni';

  @override
  String get browseSortOldestFirst => 'Önce en eski';

  @override
  String get browseSortLargestFirst => 'Önce en büyük';

  @override
  String get browseSortSmallestFirst => 'Önce en küçük';

  @override
  String get browseSortNameAsc => 'A–Z';

  @override
  String get browseSortNameDesc => 'Z–A';

  @override
  String get browseRecent => 'Son arama';

  @override
  String get settingsBrowse => 'Göz at';

  @override
  String get settingsShowSizes => 'Dosya boyutlarını göster';

  @override
  String get settingsShowSizesHelp =>
      'Her fotoğraf ve videoda bir boyut etiketi';

  @override
  String get settingsHighlightBig => 'Büyük dosyaları vurgula';

  @override
  String selectionCount(int count, String size) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString seçili · $size',
      one: '1 seçili · $size',
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
      other: 'Seçim temizlendi ($countString dosya)',
      one: 'Seçim temizlendi (1 dosya)',
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
      other: 'Seçimi temizle ($countString dosya)',
      one: 'Seçimi temizle (1 dosya)',
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
      other: '$countString dosya eklendi',
      one: '1 dosya eklendi',
      zero: 'Eklenecek yeni bir şey yok',
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
      other: '$countString seçili',
      one: '1 seçili',
    );
    return '$_temp0';
  }

  @override
  String get selectionEnter => 'Seç';

  @override
  String get selectionExit => 'Seçim modundan çık';

  @override
  String get selectionEditTitle => 'Seçimi düzenle';

  @override
  String get selectionHint =>
      'Eklemek için dokun · Çok sayıda eklemek için basılı tut ve sürükle';

  @override
  String get selectionEditHint =>
      'Seçimden çıkarmak için seçili dosyalara dokun';

  @override
  String get selectionSelectAll => 'Tümünü seç';

  @override
  String get selectionClearAll => 'Tümünü temizle';

  @override
  String get selectionView => 'Seçilenleri görüntüle';

  @override
  String get selectionRestore => 'Son seçimi geri yükle';

  @override
  String get selectionDone => 'Bitti';

  @override
  String get selectionRemoved => 'Seçimden çıkarıldı';

  @override
  String get selectionTip =>
      'Zaten seçili. Dosyaları çıkarmak için Seçimi düzenle\'yi kullan.';

  @override
  String get selectionMore => 'Diğer';

  @override
  String get selectionPreview => 'Seçilenleri önizle';

  @override
  String get previewOpen => 'Önizle';

  @override
  String get previewSelect => 'Seç';

  @override
  String get previewSelected => 'Seçili';

  @override
  String get previewRemove => 'Seçimden çıkar';

  @override
  String get previewPlay => 'Oynat';

  @override
  String get previewDetails => 'Ayrıntılar';

  @override
  String get previewFileGone => 'Bu dosya artık yok';

  @override
  String get previewHeicUnsupported =>
      'Bu Android sürümünde HEIC önizlenemiyor';

  @override
  String previewDimensions(int width, int height) {
    return '$width × $height';
  }

  @override
  String previewTaken(String date) {
    return 'Çekilme: $date';
  }

  @override
  String previewModified(String date) {
    return 'Değiştirilme: $date';
  }

  @override
  String get browseModeSameTime => 'Aynı an';

  @override
  String get sameTimeEmpty => 'Aynı anda çekilmiş fotoğraf yok';

  @override
  String sameTimeDayHeader(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grup',
      one: '1 grup',
    );
    return '$date · $_temp0';
  }

  @override
  String sameTimeGroupTitle(int count, String start, String end) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya',
      one: '1 dosya',
    );
    return '$_temp0 · $start–$end';
  }

  @override
  String sameTimeMore(int count) {
    return '+$count daha';
  }

  @override
  String get sameTimeSelectGroup => 'Grubu seç';

  @override
  String get settingsSameTimeWindow => 'Aynı an aralığı';

  @override
  String get fileMenuTooltip => 'Dosya işlemleri';

  @override
  String get fileMenuRename => 'Yeniden adlandır';

  @override
  String get fileMenuDuplicate => 'Çoğalt';

  @override
  String get fileMenuCopyTo => 'Şuraya kopyala…';

  @override
  String get fileMenuMoveTo => 'Şuraya taşı…';

  @override
  String get fileMenuDelete => 'Sil';

  @override
  String get selectionActionMove => 'Şuraya taşı…';

  @override
  String get selectionActionCopy => 'Şuraya kopyala…';

  @override
  String get selectionActionDuplicate => 'Çoğalt';

  @override
  String get selectionActionDelete => 'Sil';

  @override
  String get renameFolderTitle => 'Klasörü yeniden adlandır';

  @override
  String get renameAction => 'Yeniden adlandır';

  @override
  String get nameLabel => 'Ad';

  @override
  String get nameInvalid =>
      'Adlar boş olamaz, / \\ : * ? \" < > | içeremez ve 255 bayttan uzun olamaz';

  @override
  String get nameExists => 'Burada bu adla zaten bir öğe var';

  @override
  String opMovedSummary(int done, String folder) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '$done dosya $folder klasörüne taşındı',
      one: '1 dosya $folder klasörüne taşındı',
    );
    return '$_temp0';
  }

  @override
  String opCopiedSummary(int done, String folder) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '$done dosya $folder klasörüne kopyalandı',
      one: '1 dosya $folder klasörüne kopyalandı',
    );
    return '$_temp0';
  }

  @override
  String opDuplicatedSummary(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '$done dosya çoğaltıldı',
      one: '1 dosya çoğaltıldı',
    );
    return '$_temp0';
  }

  @override
  String opRenamedSummary(String name) {
    return 'Yeni ad: $name';
  }

  @override
  String opTrashedSummary(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '$done dosya çöp kutusuna taşındı',
      one: '1 dosya çöp kutusuna taşındı',
    );
    return '$_temp0';
  }

  @override
  String opDeletedSummary(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '$done dosya kalıcı olarak silindi',
      one: '1 dosya kalıcı olarak silindi',
    );
    return '$_temp0';
  }

  @override
  String opFailedSummary(int failed) {
    String _temp0 = intl.Intl.pluralLogic(
      failed,
      locale: localeName,
      other: '$failed başarısız',
      one: '1 başarısız',
    );
    return '$_temp0';
  }

  @override
  String opSkippedSummary(int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped atlandı',
      one: '1 atlandı',
    );
    return '$_temp0';
  }

  @override
  String opCancelledSummary(int done, int total) {
    return 'Durduruldu: $done/$total tamamlandı';
  }

  @override
  String opSkippedNeedAccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya atlandı (Tüm dosyalara erişim gerekli)',
      one: '1 dosya atlandı (Tüm dosyalara erişim gerekli)',
    );
    return '$_temp0';
  }

  @override
  String get opUndone => 'Geri alındı';

  @override
  String opUndoStopped(int done, int total) {
    return 'Geri alma durduruldu: $done/$total geri alındı';
  }

  @override
  String get opUndoLast => 'Son dosya işlemini geri al';

  @override
  String opUndoMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya artık yok ve geri alınamadı',
      one: '1 dosya artık yok ve geri alınamadı',
    );
    return '$_temp0';
  }

  @override
  String opSpaceRefused(String needed, String free) {
    return 'Yeterli alan yok ($needed gerekli, $free boş)';
  }

  @override
  String opFolderRenamed(String name) {
    return 'Klasörün yeni adı: $name';
  }

  @override
  String get collisionTitle => 'Ad zaten kullanılıyor';

  @override
  String collisionBody(String name, String folder) {
    return '$name, $folder klasöründe zaten var';
  }

  @override
  String get collisionReplace => 'Değiştir';

  @override
  String get collisionKeepBoth => 'İkisini de sakla';

  @override
  String get collisionSkip => 'Atla';

  @override
  String get collisionApplyAll => 'Kalan tümü için bunu yap';

  @override
  String progressMoving(int done, int total) {
    return 'Taşınıyor: $done/$total';
  }

  @override
  String progressCopying(int done, int total) {
    return 'Kopyalanıyor: $done/$total';
  }

  @override
  String progressDeleting(int done, int total) {
    return 'Siliniyor: $done/$total';
  }

  @override
  String progressUndoing(int done, int total) {
    return 'Geri alınıyor: $done/$total';
  }

  @override
  String get progressWorking => 'İşleniyor…';

  @override
  String get permanentConfirmAction => 'Sil';

  @override
  String get opPermanentConfirmTitle => 'Kalıcı olarak silinsin mi?';

  @override
  String opPermanentConfirmBody(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count dosya ($size) kalıcı olarak silinsin mi? Bu işlem geri alınamaz.',
      one: '1 dosya ($size) kalıcı olarak silinsin mi? Bu işlem geri alınamaz.',
    );
    return '$_temp0';
  }

  @override
  String get pendingFallbackTitle => 'Çöp kutusu klasörü kullanılamadı';

  @override
  String pendingFallbackBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count dosya çöp kutusu klasörüne taşınamadı. Bunun yerine kalıcı olarak silinsin mi?',
      one: '1 dosya çöp kutusu klasörüne taşınamadı. Bunun yerine kalıcı olarak silinsin mi?',
    );
    return '$_temp0';
  }

  @override
  String get pendingFallbackAction => 'Kalıcı olarak sil';

  @override
  String get pickerMoveTitle => 'Şuraya taşı';

  @override
  String get pickerCopyTitle => 'Şuraya kopyala';

  @override
  String get pickerAllFolders => 'Tüm klasörler';

  @override
  String get pickerMoveHere => 'Buraya taşı';

  @override
  String get pickerCopyHere => 'Buraya kopyala';

  @override
  String get pickerChooseHere => 'Bu klasörü kullan';

  @override
  String get pickerCurrentFolder => 'Geçerli klasör';

  @override
  String get browseNewFolder => 'Yeni klasör';

  @override
  String browseFolderCreated(String name) {
    return 'Oluşturuldu: $name';
  }

  @override
  String get settingsFiles => 'Dosyalar';

  @override
  String get settingsDropAction => 'Dosyaları bir klasöre bırakınca';

  @override
  String get dropActionMove => 'Taşınır';

  @override
  String get dropActionCopy => 'Kopyalanır';

  @override
  String fileOpRenameFailed(String name) {
    return 'Yeniden adlandırılamadı: $name';
  }

  @override
  String fileOpFailedGeneric(String name) {
    return 'Tamamlanamadı: $name';
  }

  @override
  String fileOpNotFound(String name) {
    return '$name artık yok';
  }

  @override
  String fileOpPermission(String name) {
    return 'Değiştirme izni yok: $name';
  }

  @override
  String progressCompressing(String done, String total) {
    return 'Sıkıştırılıyor: $done/$total';
  }

  @override
  String progressExtracting(String done, String total) {
    return 'Ayıklanıyor: $done/$total';
  }

  @override
  String progressEtaMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Yaklaşık $minutes dakika kaldı',
      one: 'Yaklaşık 1 dakika kaldı',
    );
    return '$_temp0';
  }

  @override
  String get archiveCompress => 'Sıkıştır';

  @override
  String get archiveViewContents => 'İçeriği görüntüle';

  @override
  String get archiveExtractHere => 'Buraya ayıkla';

  @override
  String get archiveExtractTo => 'Şuraya ayıkla…';

  @override
  String get archiveExtractThis => 'Bunu ayıkla';

  @override
  String get archiveExtractToTitle => 'Şuraya ayıkla';

  @override
  String get archiveCompressTitle => 'ZIP olarak sıkıştır';

  @override
  String get archiveCompressAction => 'Sıkıştır';

  @override
  String archiveSaveIn(String folder) {
    return '$folder klasörüne kaydedildi';
  }

  @override
  String get archiveSaveTo => 'Şuraya kaydet…';

  @override
  String get archiveSaveToTitle => 'ZIP\'i şuraya kaydet';

  @override
  String get archiveWrongPlace => 'Bu yerdeki dosyalar henüz sıkıştırılamıyor';

  @override
  String archiveCreated(String name) {
    return 'Oluşturuldu: $name';
  }

  @override
  String archiveExtracted(int count, String folder) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya $folder klasörüne ayıklandı',
      one: '1 dosya $folder klasörüne ayıklandı',
      zero: 'Ayıklanacak bir şey yok',
    );
    return '$_temp0';
  }

  @override
  String get archiveBombTitle => 'Çok büyük arşiv';

  @override
  String archiveBombBody(String size) {
    return 'Bu arşiv açıldığında $size tutuyor. Yine de ayıklansın mı?';
  }

  @override
  String get archiveBombAction => 'Yine de ayıkla';

  @override
  String get archiveUnsafePaths =>
      'Bu arşiv güvenli olmayan yollar içerdiği için ayıklanmadı';

  @override
  String get archiveCorrupt => 'Bu ZIP bozuk veya bir ZIP dosyası değil';

  @override
  String get archiveCancelled => 'Durduruldu. Hiçbir şey kaydedilmedi';

  @override
  String archiveIoError(String name) {
    return 'Okunamadı veya yazılamadı: $name';
  }

  @override
  String get archivePasswordTitle => 'Parola gerekli';

  @override
  String archivePasswordBody(String name) {
    return '$name parola ile korunuyor';
  }

  @override
  String get archivePasswordLabel => 'Parola';

  @override
  String get archivePasswordAction => 'Ayıkla';

  @override
  String get archiveWrongPassword => 'Yanlış parola, tekrar dene';

  @override
  String get archivePasswordShow => 'Parolayı göster';

  @override
  String get archivePasswordHide => 'Parolayı gizle';

  @override
  String archiveSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count öğe · $size',
      one: '1 öğe · $size',
    );
    return '$_temp0';
  }

  @override
  String get archiveEmpty => 'Bu ZIP boş';

  @override
  String get archiveWrongDestination =>
      'Bu yere henüz kaydedilemiyor. Dahili depolamada bir klasör seç';

  @override
  String archiveReplaceFailed(String name) {
    return 'Eski ZIP saklandı. Yenisi şu adla kaydedildi: $name';
  }

  @override
  String get collectionsOpen => 'Etiketler ve favoriler';

  @override
  String get collectionsTitle => 'Etiketler ve favoriler';

  @override
  String get collectionsFavorites => 'Favoriler';

  @override
  String get collectionsTags => 'Etiketler';

  @override
  String get collectionsEmpty =>
      'Henüz etiket yok. Göz at\'tan dosyaları etiketle veya kaydırma ayarlarında bir yönü “Etiket ekle” olarak ayarla.';

  @override
  String collectionsFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya',
      one: '1 dosya',
      zero: 'Dosya yok',
    );
    return '$_temp0';
  }

  @override
  String get collectionsTagMenu => 'Etiket seçenekleri';

  @override
  String get tagMenuEdit => 'Yeniden adlandır veya rengi değiştir';

  @override
  String get tagMenuDelete => 'Etiketi sil';

  @override
  String get tagEditTitle => 'Etiketi düzenle';

  @override
  String get tagSave => 'Kaydet';

  @override
  String tagDeleteTitle(String name) {
    return '“$name” etiketi silinsin mi?';
  }

  @override
  String tagDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya kalır; yalnızca etiket kaldırılır.',
      one: 'Dosya kalır; yalnızca etiket kaldırılır.',
      zero: 'Bu etikete sahip dosya yok.',
    );
    return '$_temp0';
  }

  @override
  String tagDeleteUsedIn(String places) {
    return 'Kullanıldığı yer: $places. Başka bir tane seçene kadar o yön “Etiket artık yok” gösterecek.';
  }

  @override
  String get tagUsedCurrentSetup => 'geçerli kaydırma ayarı';

  @override
  String get tagDeleteConfirm => 'Sil';

  @override
  String tagDeleted(String name) {
    return '“$name” etiketi silindi';
  }

  @override
  String get tagGone => 'Bu etiket silindi';

  @override
  String get fileMenuFavoriteAdd => 'Favorilere ekle';

  @override
  String get fileMenuFavoriteRemove => 'Favorilerden kaldır';

  @override
  String get fileMenuTags => 'Etiketler…';

  @override
  String get selectionTagsMenu => 'Etiketler ve favoriler…';

  @override
  String get selectionTagAdd => 'Etiket ekle…';

  @override
  String get selectionTagRemove => 'Etiketi kaldır…';

  @override
  String get tagRemoveTitle => 'Etiket kaldır';

  @override
  String get tagRemoveNone => 'Bu dosyaların hiçbirinde etiket yok';

  @override
  String get fileTagsTitle => 'Etiketler';

  @override
  String tagAddedSummary(int count, String tag) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya “$tag” olarak etiketlendi',
      one: '1 dosya “$tag” olarak etiketlendi',
      zero: 'Tüm dosyalarda zaten “$tag” vardı',
    );
    return '$_temp0';
  }

  @override
  String tagRemovedSummary(int count, String tag) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '“$tag” $count dosyadan kaldırıldı',
      one: '“$tag” 1 dosyadan kaldırıldı',
      zero: 'Hiçbir dosyada “$tag” yoktu',
    );
    return '$_temp0';
  }

  @override
  String favoriteAddedSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya favorilere eklendi',
      one: '1 dosya favorilere eklendi',
      zero: 'Zaten favorilerde',
    );
    return '$_temp0';
  }

  @override
  String favoriteRemovedSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya favorilerden kaldırıldı',
      one: '1 dosya favorilerden kaldırıldı',
      zero: 'Favorilerde değil',
    );
    return '$_temp0';
  }

  @override
  String get tagWriteError => 'Değişiklik kaydedilemedi. Tekrar dene';

  @override
  String get swipeSourceSelectionTitle => 'Seçili dosyalar';

  @override
  String get sameTimeSwipeGroup => 'Bu grubu kaydır';

  @override
  String get swipeSourceClose => 'Tüm dosyalara dön';

  @override
  String swipeSourceGroupPosition(
    int group,
    int groupCount,
    int index,
    int groupSize,
  ) {
    return 'Grup $group/$groupCount · $index/$groupSize';
  }

  @override
  String swipeSourceDone(String title) {
    return 'Tümü bitti: $title';
  }

  @override
  String get swipeSourceBackToMain => 'Kaydırmaya dön';

  @override
  String swipeSourceBackToOrigin(String origin) {
    return 'Geri dön: $origin';
  }

  @override
  String swipeSourceRestored(String title) {
    return 'Devam ediliyor: $title';
  }

  @override
  String swipeSourcePendingLine(String title) {
    return 'Açılacak: $title';
  }

  @override
  String swipeSourceSkipped(int files, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files dosya kaydırılıyor',
      one: '1 dosya kaydırılıyor',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped dosya burada kaydırılamaz',
      one: '1 dosya burada kaydırılamaz',
    );
    return '$_temp0 · $_temp1 (yalnızca fotoğraf ve videolar)';
  }

  @override
  String get swipeSourceTruncated => 'İlk 10.000 dosya gösteriliyor';

  @override
  String get swipeSourceEmpty => 'Burada kaydırılacak bir şey yok';

  @override
  String get swipeSourceNoMedia =>
      'Yalnızca fotoğraf ve videolar kaydırılabilir';

  @override
  String get swipeSourceInvalidFilter => 'Bu filtre kullanılamıyor';

  @override
  String get swipeSourceNoMatches => 'Eşleşen fotoğraf veya video yok';

  @override
  String get swipeSourceOriginStorage => 'Depolama özeti';

  @override
  String get swipeSourceOriginSimilar => 'Benzer fotoğraflar';

  @override
  String get swipeSourceOriginSearch => 'Ara';

  @override
  String get swipeSourceOriginGroups => 'Gruplar';

  @override
  String get swipeSourceOriginSameTime => 'Aynı an';

  @override
  String get swipeSourceOriginBrowse => 'Göz at';

  @override
  String get swipeSourceOriginSharedIn => 'Paylaşılan dosyalar';

  @override
  String get swipeSourceOriginCloud => 'Bulut';

  @override
  String get swipeSourceOriginExternal => 'Harici depolama';

  @override
  String get swipeSourceOriginOther => 'Önceki ekran';

  @override
  String get storageOverviewTitle => 'Depolama özeti';

  @override
  String storageUsedFree(String used, String free) {
    return '$used kullanılan · $free boş';
  }

  @override
  String get storageSpaceUnknown => 'Boş alan bilinmiyor';

  @override
  String get storageScanning => 'Tarama sürüyor… sayılar artmaya devam ediyor';

  @override
  String get storageCatVideos => 'Videolar';

  @override
  String get storageCatScreenshots => 'Ekran görüntüleri';

  @override
  String storageCatBigFiles(String size) {
    return 'Büyük dosyalar ($size üzeri)';
  }

  @override
  String get storageCatWhatsapp => 'WhatsApp';

  @override
  String get storageCatDownloads => 'İndirilenler';

  @override
  String storageCategorySummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya · $size',
      one: '1 dosya · $size',
      zero: 'Dosya yok',
    );
    return '$_temp0';
  }

  @override
  String get storageCleanUp => 'Temizle';

  @override
  String get storageCleanUpMediaOnly =>
      'Temizle yalnızca fotoğrafları ve videoları gösterir';

  @override
  String get storageNeedsAccess =>
      'Bu dosyaları görmek için Tüm dosyalara erişim\'i aç';

  @override
  String get storageOverlapNote =>
      'Bir dosya birden fazla kategoride olabilir.';

  @override
  String get storageBiggestFiles => 'En büyük dosyalar';

  @override
  String get storageWhatsappHint =>
      'WhatsApp\'ın gizli Sent ve Status klasörleri dahil';

  @override
  String get storageBigFileThreshold => 'Büyük dosya sınırı';

  @override
  String get similarTitle => 'Benzer fotoğraflar';

  @override
  String get similarSourceTitle => 'Benzer fotoğraflar';

  @override
  String get similarStorageHint => 'Birbirine benzeyen ve bulanık fotoğraflar';

  @override
  String get similarTabSimilar => 'Benzer';

  @override
  String get similarTabBlurry => 'Bulanık';

  @override
  String get similarStartTitle => 'Benzer ve bulanık fotoğrafları bul';

  @override
  String get similarStart => 'Başlat';

  @override
  String similarChecking(int done, int total) {
    return 'Fotoğraflar kontrol ediliyor… $done / $total';
  }

  @override
  String get similarGrouping => 'Benzer fotoğraflar gruplanıyor…';

  @override
  String get similarNoGroups => 'Henüz benzer fotoğraf bulunamadı';

  @override
  String get similarNoBlurry => 'Bulanık fotoğraf bulunamadı';

  @override
  String similarGroupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotoğraf',
      one: '1 fotoğraf',
    );
    return '$_temp0';
  }

  @override
  String get similarBest => 'En iyi';

  @override
  String get similarKeepBest => 'En iyiyi sakla, diğerlerini kaldır';

  @override
  String get similarSwipeGroup => 'Bu grubu kaydır';

  @override
  String get similarSwipeAll => 'Tüm grupları kaydır';

  @override
  String get similarCleanDuplicates => 'Kopyaları temizle';

  @override
  String similarRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotoğraf kaldırıldı',
      one: '1 fotoğraf kaldırıldı',
    );
    return '$_temp0';
  }

  @override
  String get similarKeptAll => 'Tüm fotoğraflar saklandı';

  @override
  String get similarBlurryHint =>
      'Seçmek için dokun, görüntülemek için basılı tut';

  @override
  String similarRemoveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tanesini kaldır',
      zero: 'Kaldır',
    );
    return '$_temp0';
  }

  @override
  String similarCleanProgress(int group, int total, int keep) {
    return 'Grup $group / $total · saklanacak: $keep';
  }

  @override
  String get similarCleanDone => 'Tüm gruplar bitti';

  @override
  String get similarSkip => 'Atla';

  @override
  String get similarNextGroup => 'Sonraki grup';

  @override
  String get similarKeep => 'Sakla';

  @override
  String get similarRemove => 'Kaldır';

  @override
  String get similarSettingEnabled => 'Benzer ve bulanık fotoğrafları bul';

  @override
  String get similarSettingEnabledHint =>
      'KFM açıkken fotoğrafları arka planda kontrol eder';

  @override
  String get similarSettingStrictness => 'Benzerlik derecesi';

  @override
  String get similarStrictnessLoose => 'Biraz benzer';

  @override
  String get similarStrictnessNormal => 'Normal';

  @override
  String get similarStrictnessStrict => 'Neredeyse aynı';

  @override
  String get similarSettingScreenshots => 'Ekran görüntülerini dahil et';

  @override
  String get groupsTitle => 'Gruplar';

  @override
  String get groupsScreenshots => 'Ekran görüntüleri';

  @override
  String get groupsSelfies => 'Özçekimler (otomatik)';

  @override
  String get groupsDocuments => 'Belgeler';

  @override
  String get groupsTrips => 'Geziler';

  @override
  String get groupsPlaces => 'Mekânlar';

  @override
  String smartGroupPlace(int n) {
    return 'Mekân $n';
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
      other: '$count dosya',
      one: '1 dosya',
    );
    return '$_temp0';
  }

  @override
  String groupsProgress(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Geziler ve mekânlar bulunuyor… $done / $total fotoğraf',
      one: 'Geziler ve mekânlar bulunuyor… $done / 1 fotoğraf',
    );
    return '$_temp0';
  }

  @override
  String get groupsGrouping => 'Geziler ve mekânlar gruplanıyor…';

  @override
  String get groupsEmpty =>
      'Henüz grup yok. KFM geziler ve mekânlar buldukça burada görünür.';

  @override
  String get groupsRename => 'Yeniden adlandır';

  @override
  String get groupsRenameHint => 'Otomatik ad için boş bırak';

  @override
  String get groupsRenameSave => 'Kaydet';

  @override
  String get groupsRenameCancel => 'İptal';

  @override
  String get groupsChanged => 'Bu grup değişti';

  @override
  String get groupsChangedBody =>
      'Fotoğraf eklendikçe veya kaldırıldıkça geziler ve mekânlar yeniden hesaplanır.';

  @override
  String get groupsBack => 'Gruplara dön';

  @override
  String get groupsSwipe => 'Bu grubu kaydır';

  @override
  String get groupsLocationRow =>
      'Fotoğrafları mekâna göre gruplamak için konum erişimine izin ver';

  @override
  String get groupsOnlineNames => 'Mekân adlarını çevrimiçi bul';

  @override
  String get groupsOnlineNamesHelp =>
      '\'Paris\' gibi adlar almak için her mekân grubunun yaklaşık merkezini telefonunun konum adı hizmetine gönderir';

  @override
  String get groupsJobError =>
      'Gruplar güncellenemedi. Daha sonra tekrar denenecek.';

  @override
  String groupsFailedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotoğraf okunamadı',
      one: '1 fotoğraf okunamadı',
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
  String get aiLabelsTitle => 'Fotoğraf otomatik etiketleri (yapay zekâ)';

  @override
  String get aiLabelsEnableHint =>
      'Fotoğrafları içeriklerine göre bul: kedi, plaj veya yemek gibi';

  @override
  String get aiLabelsEnableNeedsModels => 'Önce yapay zekâ modellerini indir';

  @override
  String get aiLabelsPause => 'Otomatik etiketlemeyi duraklat';

  @override
  String get aiLabelsResume => 'Otomatik etiketlemeyi sürdür';

  @override
  String get aiLabelsPausedLine => 'Otomatik etiketleme duraklatıldı';

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
      other: '$processedString / $totalString fotoğraf etiketlendi',
      one: '$processedString / 1 fotoğraf etiketlendi',
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
      other: '$countString fotoğraf etiketlenemedi',
      one: '1 fotoğraf etiketlenemedi',
    );
    return '$_temp0';
  }

  @override
  String get aiLabelsReset => 'Otomatik etiketleri sıfırla';

  @override
  String get aiLabelsResetConfirm =>
      'Tüm fotoğraf otomatik etiketleri sıfırlansın mı?';

  @override
  String get aiLabelsResetConfirmBody =>
      'Her fotoğraf baştan yeniden etiketlenecek.';

  @override
  String get aiLabelsResetAction => 'Sıfırla';

  @override
  String get aiLabelsJobError =>
      'Yapay zekâ modelleri eksik veya değişmiş, bu yüzden otomatik etiketleme durdu. Modelleri yeniden indir.';

  @override
  String get aiLabelsCrashError =>
      'Otomatik etiketleme bir hatadan sonra durdu. Daha sonra tekrar denenecek.';

  @override
  String get aiLabelsNeedsAndroid8 => 'Android 8 veya üstü gerekir';

  @override
  String get aiLabelsUnsupported => 'Bu cihazda henüz kullanılamıyor';

  @override
  String get aiLabelsCardTitle =>
      'Fotoğrafları içeriklerine göre bul (kedi, plaj, yemek…)';

  @override
  String get aiLabelsCardTurnOn => 'Aç';

  @override
  String get aiLabelsCardNotNow => 'Şimdi değil';

  @override
  String get aiLabelsTurnedOn => 'Fotoğraf otomatik etiketleme açık';

  @override
  String get aiCancel => 'İptal';

  @override
  String get aiModelsTitle => 'Yapay zekâ modelleri';

  @override
  String get aiModelsNotDownloaded => 'Yapay zekâ modelleri indirilmedi';

  @override
  String get aiModelsAbout => 'Yapay zekâ modelleri hakkında / İndir…';

  @override
  String get aiModelsChecking => 'Yapay zekâ modelleri kontrol ediliyor…';

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

    return 'İndiriliyor: $doneString / $totalString MB';
  }

  @override
  String get aiModelsWaitingWifi => 'Wi-Fi bekleniyor';

  @override
  String get aiModelsVerifying => 'İndirme kontrol ediliyor…';

  @override
  String aiModelsInstalled(double size) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String sizeString = sizeNumberFormat.format(size);

    return 'Yüklendi, $sizeString MB';
  }

  @override
  String get aiModelsNeedUpdate =>
      'Yapay zekâ modellerinin güncellenmesi gerekiyor — yeniden indir';

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

    return 'İndirme duraklatıldı: $doneString / $totalString MB';
  }

  @override
  String get aiModelsErrorNetwork => 'İndirme başarısız: bağlantı yok.';

  @override
  String aiModelsErrorHttp(String code) {
    return 'İndirme başarısız (sunucu hatası $code).';
  }

  @override
  String get aiModelsErrorChecksum =>
      'İndirilen dosya beklenenle eşleşmedi. Dosya silindi ve hiçbir şey yüklenmedi.';

  @override
  String get aiModelsErrorDiskFull =>
      'İndirme başarısız: yeterli boş alan yok.';

  @override
  String get aiModelsErrorOther => 'İndirme başarısız.';

  @override
  String get aiModelsRetry => 'Tekrar dene';

  @override
  String get aiModelsCancel => 'İndirmeyi iptal et';

  @override
  String get aiModelsWifiOnly => 'Yalnızca Wi-Fi ile indir';

  @override
  String get aiModelsUseMobileData => 'Bu sefer mobil veri kullan';

  @override
  String get aiModelsWillUseWifi => 'Wi-Fi ile indirilecek';

  @override
  String get aiModelsRemove => 'Yapay zekâ modellerini kaldır';

  @override
  String aiModelsRemoveTitle(double size) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String sizeString = sizeNumberFormat.format(size);

    return 'Yapay zekâ modelleri kaldırılsın mı ($sizeString MB)?';
  }

  @override
  String get aiModelsRemoveBody =>
      'Yeni fotoğraflar artık etiketlenmeyecek. Modelleri daha sonra yeniden indirebilirsin.';

  @override
  String get aiModelsRemoveAlsoLabels =>
      'Fotoğraf otomatik etiketlerini de sil';

  @override
  String get aiModelsRemoveConfirm => 'Kaldır';

  @override
  String get aiModelsDetailsIntro =>
      'KFM fotoğraflarını otomatik etiketleyebilir (kedi, plaj, yemek, kişi…), böylece onları içeriklerine göre bulabilirsin. Bunun için uygulamaya dahil olmayan iki küçük yapay zekâ modeli gerekir. Modeller yalnızca İndir\'e dokunursan indirilir.';

  @override
  String get aiModelsHowTitle => 'Nasıl çalışır';

  @override
  String get aiModelsPrivacyTitle => 'Gizlilik';

  @override
  String get aiModelsBatteryBody =>
      'Otomatik etiketleme KFM açıkken çalışır ve pil %20\'nin altındayken şarj olmuyorsa duraklar.';

  @override
  String get aiModelsRemovableBody =>
      'Modelleri istediğin zaman Ayarlar\'dan kaldırabilirsin.';

  @override
  String aiModelsDownloadButton(double size) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String sizeString = sizeNumberFormat.format(size);

    return 'İndir ($sizeString MB)';
  }

  @override
  String get aiModelsInstalledDone =>
      'Yapay zekâ modelleri yüklendi. Otomatik etiketleme açık.';

  @override
  String get aiModelClassifierWhat =>
      'Görüntü sınıflandırıcı: yaklaşık 1.000 tür nesne, hayvan, yemek ve sahneyi tanır.';

  @override
  String get aiModelClassifierUse =>
      'KFM bunu kedi, köpek, kuş, yemek, plaj, dağ, araba ve belge gibi otomatik etiketler için kullanır.';

  @override
  String get aiModelDetectorWhat =>
      'Nesne algılayıcı: insanları bulur (ve sayar), evcil hayvanları, araçları ve yiyecekleri bulur.';

  @override
  String get aiModelDetectorUse =>
      'KFM bunu kişi, kalabalık, kedi, köpek, araba ve yemek gibi otomatik etiketler için kullanır.';

  @override
  String aiModelSize(double size) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String sizeString = sizeNumberFormat.format(size);

    return 'İndirme boyutu: $sizeString MB';
  }

  @override
  String aiModelPublisher(String publisher) {
    return 'Yayıncı: $publisher';
  }

  @override
  String aiModelLicence(String licence) {
    return 'Lisans: $licence';
  }

  @override
  String aiModelSource(String url) {
    return 'İndirildiği yer: $url';
  }

  @override
  String aiModelOriginal(String url) {
    return 'Orijinal sürüm: $url';
  }

  @override
  String get aiModelsLicences => 'Lisansları görüntüle';

  @override
  String get aboutLicences => 'Açık kaynak lisansları';

  @override
  String searchChipLabel(String label) {
    return 'İçerik: $label';
  }

  @override
  String get searchChipBlurry => 'Bulanık fotoğraflar';

  @override
  String searchStillLabeling(double percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.percentPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return 'Fotoğraflar hâlâ etiketleniyor ($percentString) — sonuçlar eksik olabilir';
  }

  @override
  String get searchLabelingOff =>
      'İçeriğe göre aramak için fotoğraf otomatik etiketlemeyi aç';

  @override
  String get searchLabelingOffTurnOn => 'Aç';

  @override
  String get searchContentWordsLoadError =>
      'İçerik arama sözcükleri yüklenemedi';

  @override
  String get fileMenuDetails => 'Ayrıntılar';

  @override
  String get selectionActionDetails => 'Ayrıntılar';

  @override
  String get detailsSheetLabel => 'Dosya ayrıntıları';

  @override
  String get detailsLoading => 'Ayrıntılar yükleniyor';

  @override
  String get detailsPartial => 'Bazı ayrıntılar okunamadı';

  @override
  String get detailsGone => 'Bu dosya artık yok';

  @override
  String get detailsWhatIsThis => 'Bu nedir?';

  @override
  String get detailsHintUsually =>
      'Genelde gerekmez, ama silmeden önce kontrol et';

  @override
  String get detailsHintCareful => 'Dikkat: silmek veri kaybına yol açabilir';

  @override
  String get detailsCameFrom => 'Kaynak';

  @override
  String detailsSavedBy(String app) {
    return 'Kaydeden: $app';
  }

  @override
  String detailsInSourceFolder(String source) {
    return '$source klasöründe';
  }

  @override
  String detailsNotInstalled(String package) {
    return '$package (yüklü değil)';
  }

  @override
  String detailsDownloadedFrom(String host) {
    return 'İndirildiği yer: $host';
  }

  @override
  String detailsLinkedFrom(String host) {
    return 'Bağlantının olduğu yer: $host';
  }

  @override
  String get detailsShowFullAddress => 'Tam adresi göstermek için dokun';

  @override
  String detailsTakenWith(String camera) {
    return 'Çeken cihaz: $camera';
  }

  @override
  String detailsEditedWith(String app) {
    return 'Oluşturan veya düzenleyen: $app';
  }

  @override
  String get detailsWhere => 'Konum';

  @override
  String get detailsPath => 'Yol';

  @override
  String get detailsCopyPath => 'Yolu kopyala';

  @override
  String get detailsPathCopied => 'Yol kopyalandı';

  @override
  String get detailsStorage => 'Depolama';

  @override
  String get detailsStorageInternal => 'Dahili depolama';

  @override
  String get detailsStorageRemovable => 'SD kart veya USB bellek';

  @override
  String get detailsHidden => 'Gizli';

  @override
  String get detailsOpenFolder => 'Klasörü aç';

  @override
  String get detailsFileSection => 'Dosya';

  @override
  String get detailsType => 'Tür';

  @override
  String detailsTypeValue(String mime, String ext) {
    return '$mime (.$ext)';
  }

  @override
  String detailsTypeUnknown(String ext) {
    return 'Bilinmeyen dosya türü (.$ext)';
  }

  @override
  String get detailsTypeUnknownNoExt => 'Bilinmeyen dosya türü';

  @override
  String get detailsSize => 'Boyut';

  @override
  String detailsBytes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bayt',
      one: '1 bayt',
    );
    return '$_temp0';
  }

  @override
  String get detailsModified => 'Değiştirilme';

  @override
  String get detailsTaken => 'Çekilme';

  @override
  String get detailsDimensions => 'Boyutlar';

  @override
  String get detailsDuration => 'Süre';

  @override
  String get detailsCameraSettings => 'Kamera ayarları';

  @override
  String get detailsLens => 'Lens';

  @override
  String get detailsDescription => 'Açıklama';

  @override
  String detailsIso(int value) {
    return 'ISO $value';
  }

  @override
  String detailsExposure(String value) {
    return '$value sn';
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
  String get detailsLocation => 'Konum';

  @override
  String detailsLatLng(String lat, String lng) {
    return '$lat, $lng';
  }

  @override
  String get detailsInKfm => 'KFM\'de';

  @override
  String get detailsTags => 'Etiketler';

  @override
  String get detailsFavorite => 'Favori';

  @override
  String detailsReviewed(String date) {
    return 'İncelendi: $date';
  }

  @override
  String get detailsAppInfo => 'Uygulama bilgileri';

  @override
  String get detailsAppInfoFailed => 'Uygulama bilgileri açılamadı';

  @override
  String detailsSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya',
      one: '1 dosya',
    );
    return '$_temp0';
  }

  @override
  String get detailsSummaryTotal => 'Toplam boyut';

  @override
  String get detailsSummaryKinds => 'Türler';

  @override
  String detailsSummaryKindCount(String kind, int count) {
    return '$kind: $count';
  }

  @override
  String get detailsSummaryOldest => 'En eski';

  @override
  String get detailsSummaryNewest => 'En yeni';

  @override
  String get detailsSummaryFolders => 'Klasörler';

  @override
  String detailsSummaryFolderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count klasörde',
      one: '1 klasörde',
    );
    return '$_temp0';
  }

  @override
  String detailsSummaryMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Seçili $count dosya artık dizinde değil',
      one: 'Seçili 1 dosya artık dizinde değil',
    );
    return '$_temp0';
  }

  @override
  String get connectSettingsTitle => 'Cihaz bağla';

  @override
  String get connectShareThisDevice => 'Bu cihazı paylaş';

  @override
  String get connectShareThisDeviceHint =>
      'Aynı Wi-Fi ağındaki bir telefon veya bilgisayar bu cihaza bağlanabilsin';

  @override
  String get connectToDevice => 'Bir cihaza bağlan';

  @override
  String get connectToDeviceHint => 'QR kodu tara veya kod yaz';

  @override
  String get connectChooseHint =>
      'Diğer cihazda Ayarlar → Cihaz bağla → Bu cihazı paylaş\'ı aç.';

  @override
  String get connectScanQr => 'QR kodu tara';

  @override
  String get connectScanQrHint => 'Kamerayı diğer cihazdaki koda doğrult';

  @override
  String get connectTypeCode => 'Kod yaz';

  @override
  String get connectTypeCodeHint => 'PC için ya da kamera yoksa';

  @override
  String get connectCameraDenied =>
      'KFM\'nin kodu taramak için kameraya ihtiyacı var. Bunun yerine kodu yazabilirsin.';

  @override
  String get connectOpenSettings => 'Ayarları aç';

  @override
  String get connectAllowCamera => 'Kameraya izin ver';

  @override
  String get connectNotKfmCode => 'Bu bir KFM kodu değil';

  @override
  String get connectUpdateKfm => 'KFM\'yi iki cihazda da güncelle';

  @override
  String get connectDebugPasteLabel =>
      'Eşleştirme bağlantısı (yalnızca hata ayıklama sürümleri)';

  @override
  String get connectDebugPasteGo => 'Bağlantıyı kullan';

  @override
  String get connectNearbyTitle => 'Yakındaki cihazlar';

  @override
  String get connectNearbySearching =>
      'Bu Wi-Fi\'da paylaşım yapan cihazlar aranıyor…';

  @override
  String get connectNearbyFailed =>
      'Bu Wi-Fi\'da arama yapılamıyor. Bunun yerine diğer cihazda görünen adresi gir.';

  @override
  String get connectEnterAddress => 'Adres gir';

  @override
  String get connectAddressLabel => 'Diğer cihazda görünen adres';

  @override
  String get connectAddressInvalid => 'Şu şekilde gir: 192.168.1.23:48211';

  @override
  String connectHostPort(String host, int port) {
    return '$host:$port';
  }

  @override
  String get connectNext => 'İleri';

  @override
  String connectCodeFor(String name) {
    return '$name cihazında görünen kodu yaz';
  }

  @override
  String get connectCodeForAddress => 'Diğer cihazda görünen kodu yaz';

  @override
  String get connectCodeLabel => 'Kod';

  @override
  String get connectCodeInvalidChar => 'Yalnızca harf ve rakam';

  @override
  String get connectConnect => 'Bağlan';

  @override
  String get connectCancel => 'İptal';

  @override
  String get connectConnecting => 'Bağlanıyor…';

  @override
  String connectWaiting(String name) {
    return '$name cihazının kabul etmesi bekleniyor…';
  }

  @override
  String connectConnected(String name) {
    return 'Bağlandı: $name';
  }

  @override
  String get connectDisconnect => 'Bağlantıyı kes';

  @override
  String get connectTryAgain => 'Tekrar dene';

  @override
  String get connectBack => 'Geri';

  @override
  String get connectOtherDevice => 'diğer cihaz';

  @override
  String get connectErrorUnreachable =>
      'Cihazlar bu Wi-Fi\'da birbirine ulaşamıyor. Bir hotspot dene.';

  @override
  String connectErrorWrongDevice(String name) {
    return 'Bu cihaz $name değil.';
  }

  @override
  String connectErrorWrongCode(String name) {
    return 'Kod yanlış ya da bu cihaz $name değil. Kodu kontrol edip tekrar dene.';
  }

  @override
  String get connectErrorSecretUsed => 'Kod zaten kullanıldı';

  @override
  String get connectErrorExpired => 'Bu kodun süresi doldu. Yenisini tara.';

  @override
  String get connectErrorTooMany =>
      'Çok fazla deneme. Biraz bekleyip tekrar dene.';

  @override
  String connectErrorBusy(String name) {
    return '$name başka bir istekle meşgul. Birazdan tekrar dene.';
  }

  @override
  String connectErrorDeclined(String name) {
    return '$name bağlantıyı reddetti.';
  }

  @override
  String connectErrorTimedOut(String name) {
    return '$name yanıt vermedi.';
  }

  @override
  String get connectErrorCancelled => 'İstek iptal edildi';

  @override
  String get connectErrorFailed => 'Eşleştirme başarısız oldu. Tekrar dene.';

  @override
  String connectErrorNetwork(String name) {
    return '$name ile bağlantı koptu.';
  }

  @override
  String connectErrorBadResponse(String name) {
    return '$name KFM gibi yanıt vermedi. KFM\'yi iki cihazda da güncelle.';
  }

  @override
  String get shareTitle => 'Bu cihazı paylaş';

  @override
  String get sharePreparing => 'Hazırlanıyor…';

  @override
  String get shareSharing => 'Paylaşılıyor';

  @override
  String shareSharingAs(String name) {
    return 'Aynı Wi-Fi\'daki cihazlar “$name” cihazına bağlanabilir.';
  }

  @override
  String get shareKeepOpen =>
      'Bu ekrandan ya da uygulamadan çıkınca paylaşım durur.';

  @override
  String get shareStop => 'Paylaşımı durdur';

  @override
  String get shareStopped => 'Paylaşım durduruldu';

  @override
  String get shareStartAgain => 'Tekrar paylaş';

  @override
  String get shareNoNetwork => 'Wi-Fi\'a bağlan ya da hotspot\'u aç';

  @override
  String get shareNoNetworkHint =>
      'İki cihaz da aynı Wi-Fi\'da olmalı ya da biri diğerinin hotspot\'unu kullanmalı.';

  @override
  String get shareFailed => 'Paylaşım başlatılamadı';

  @override
  String get shareRetry => 'Tekrar dene';

  @override
  String shareDebugAddress(String address, int port) {
    return '$address:$port';
  }

  @override
  String shareDebugFingerprint(String fingerprint) {
    return 'Parmak izi: $fingerprint';
  }

  @override
  String get shareQrHint => 'Bunu diğer cihazda KFM ile tara';

  @override
  String get shareQrSemantics => 'Eşleştirme için QR kodu';

  @override
  String shareExpiresIn(String time) {
    return 'Yeni kod: $time içinde';
  }

  @override
  String get shareTypeCodeTitle => 'Kamera yok mu? Bu kodu yaz';

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
          'Çok fazla yanlış deneme. Yazılan kodlar $seconds saniye sonra yeniden çalışır.',
      one: 'Çok fazla yanlış deneme. Yazılan kodlar 1 saniye sonra yeniden çalışır.',
    );
    return '$_temp0';
  }

  @override
  String get shareTypedCodesOff =>
      'Yazılan kodlar şimdilik kapalı. QR kodu tara ya da paylaşımı durdurup yeniden başlat.';

  @override
  String get shareRotatedLocked =>
      'Çok fazla yanlış deneme. Yeni kod oluşturuldu';

  @override
  String get sharePrivacyNote =>
      'Paylaşım sırasında bu Wi-Fi\'daki cihazlar bu cihazın adını görebilir.';

  @override
  String get shareDiscoveryFailed =>
      'Yakındaki cihazlar bu cihazı listeleyemiyor. Bunun yerine adresi girebilirler.';

  @override
  String get devResetIdentity => 'Cihaz kimliğini sıfırla';

  @override
  String get devResetIdentityDone => 'Yeni cihaz kimliği oluşturuldu';

  @override
  String get pairCompareWords =>
      'İki cihazın da bu kelimeleri gösterdiğini kontrol et';

  @override
  String connectNoFoldersYet(String name) {
    return '$name henüz klasör paylaşmadı';
  }

  @override
  String connectFoldersShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paylaşılan klasör',
      one: '1 paylaşılan klasör',
    );
    return '$_temp0';
  }

  @override
  String connectDisconnected(String name) {
    return 'Bağlantı kesildi: $name';
  }

  @override
  String acceptTitle(String name) {
    return '$name bağlanmak istiyor';
  }

  @override
  String acceptTitleRemembered(String name) {
    return '$name (hatırlanan) bağlanmak istiyor';
  }

  @override
  String acceptPlatform(String platform) {
    return 'Cihaz türü: $platform';
  }

  @override
  String acceptAutoDecline(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds saniye içinde kendiliğinden reddedilir',
      one: '1 saniye içinde kendiliğinden reddedilir',
    );
    return '$_temp0';
  }

  @override
  String get acceptDecline => 'Reddet';

  @override
  String get acceptAccept => 'Kabul et';

  @override
  String get acceptRequestCancelled => 'İstek iptal edildi';

  @override
  String get acceptTimedOut => 'Zamanında yanıt verilmedi. İstek reddedildi.';

  @override
  String shareConnectedTo(String name) {
    return 'Bağlı: $name';
  }

  @override
  String get shareDisconnectClient => 'Bağlantıyı kes';

  @override
  String get sharedFoldersTitle => 'Paylaşılan klasörler';

  @override
  String sharedFoldersFor(String name) {
    return '$name cihazının görebildiği klasörler';
  }

  @override
  String get sharedFoldersHint =>
      'Bir klasör seçene kadar hiçbir şey paylaşılmaz. Değişikliklere izin vermedikçe paylaşılan klasörler salt okunurdur.';

  @override
  String get sharedFoldersMediaOnly =>
      'Tüm dosyalara erişim olmadan yalnızca fotoğraf klasörleri paylaşılabilir.';

  @override
  String get sharedFolderCamera => 'Kamera';

  @override
  String get sharedFolderPictures => 'Resimler';

  @override
  String get sharedFolderScreenshots => 'Ekran görüntüleri';

  @override
  String get sharedFolderDownloads => 'İndirilenler';

  @override
  String get sharedFolderDocuments => 'Belgeler';

  @override
  String get sharedFolderAllStorage => 'Tüm depolama';

  @override
  String get sharedFolderAllowChanges =>
      'Değişikliklere izin ver (taşıma, yeniden adlandırma, silme, yükleme)';

  @override
  String get sharedFoldersChoose => 'Klasör seç…';

  @override
  String get sharedFoldersDone => 'Bitti';

  @override
  String get sharedFoldersWholeStorageTitle => 'Tüm dosyaların paylaşılsın mı?';

  @override
  String get sharedFoldersWholeStorageBody =>
      'Diğer cihaz tüm dosyalarını görecek.';

  @override
  String get sharedFoldersWholeStorageConfirm => 'Her şeyi paylaş';

  @override
  String get folderChooserTitle => 'Klasör seç';

  @override
  String get folderChooserShareThis => 'Bu klasörü paylaş';

  @override
  String get folderChooserEmpty => 'Alt klasör yok';

  @override
  String get folderChooserError => 'Bu klasör açılamıyor';

  @override
  String shareClientFolders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paylaşılan klasör',
      one: '1 paylaşılan klasör',
      zero: 'Paylaşılan klasör yok',
    );
    return '$_temp0';
  }

  @override
  String connectDisconnectedStopped(String name) {
    return '$name paylaşımı durdurdu.';
  }

  @override
  String connectDisconnectedNetwork(String name) {
    return '$name ile bağlantı koptu. İki cihazın da aynı Wi-Fi\'da olduğunu kontrol et.';
  }

  @override
  String get shareKeepOpenDesktop => 'Bu ekrandan çıkınca paylaşım durur.';

  @override
  String get shareKeepsRunning =>
      'Uygulamadan çıksan da paylaşım devam eder. Buradan ya da bildirimden durdur.';

  @override
  String get transferChecking => 'Kontrol ediliyor…';

  @override
  String shareClientGone(String name) {
    return 'Bağlantı kesildi: $name';
  }

  @override
  String get shareKeepsRunningNoNotification =>
      'Uygulamadan çıksan da paylaşım devam eder. KFM için bildirimler kapalı; durdurmak için buraya geri dön.';

  @override
  String get shareStopConfirmTitle => 'Paylaşım durdurulsun mu?';

  @override
  String get shareStopConfirmBody =>
      'Hâlâ dosya gönderiliyor veya alınıyor. Şimdi durdurursan aktarımlar kesilir; tekrar paylaştığında devam ederler.';

  @override
  String get shareKeepSharing => 'Paylaşmaya devam et';

  @override
  String get shareNotificationChannel => 'Cihaz paylaşımı';

  @override
  String get shareNotificationWaiting => 'Bu cihaz paylaşılıyor';

  @override
  String shareNotificationWith(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: 'Paylaşılıyor: $name ve $others cihaz daha',
      zero: 'Paylaşılıyor: $name',
    );
    return '$_temp0';
  }

  @override
  String get shareNotificationText =>
      'Aynı Wi-Fi\'daki cihazlar bağlanabilir. KFM\'yi açmak için dokun.';

  @override
  String get shareNotificationStop => 'Durdur';

  @override
  String get remoteNotConnected => 'Diğer cihaz bağlı değil';

  @override
  String remoteBrowseAction(String device) {
    return 'Göz at: $device';
  }

  @override
  String get remoteBrowseRoots => 'Paylaşılan klasörler';

  @override
  String get remoteReadOnly => 'Salt okunur';

  @override
  String remoteDeviceNotConnected(String device) {
    return '$device bağlı değil';
  }

  @override
  String get remoteReconnect => 'Yeniden bağlan';

  @override
  String get remoteFileGone => 'Bu dosya artık kullanılamıyor';

  @override
  String remoteNotAllowed(String device) {
    return '$device cihazında izin verilmiyor';
  }

  @override
  String remoteDeclined(String device) {
    return '$device reddetti';
  }

  @override
  String remoteDeleteDeclined(String device) {
    return '$device silmeyi reddetti';
  }

  @override
  String get remoteEmptyFolder => 'Burada dosya yok';

  @override
  String remoteShowingFirst(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'İlk $count dosya gösteriliyor',
      one: 'İlk dosya gösteriliyor',
    );
    return '$_temp0';
  }

  @override
  String remoteTrashConfirm(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya $device cihazındaki çöp kutusuna taşınsın mı?',
      one: '1 dosya $device cihazındaki çöp kutusuna taşınsın mı?',
    );
    return '$_temp0';
  }

  @override
  String remoteTrashConfirmHint(String device) {
    return '$device onay isteyebilir.';
  }

  @override
  String remoteTrashed(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya $device cihazındaki çöp kutusuna taşındı',
      one: '1 dosya $device cihazındaki çöp kutusuna taşındı',
    );
    return '$_temp0';
  }

  @override
  String remoteMoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya taşındı',
      one: '1 dosya taşındı',
    );
    return '$_temp0';
  }

  @override
  String remoteCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya kopyalandı',
      one: '1 dosya kopyalandı',
    );
    return '$_temp0';
  }

  @override
  String remoteSomeFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya değiştirilemedi',
      one: '1 dosya değiştirilemedi',
    );
    return '$_temp0';
  }

  @override
  String remotePickFolderTitle(String device) {
    return '$device cihazında bir klasör seç';
  }

  @override
  String get remotePickHere => 'Bu klasörü seç';

  @override
  String get remoteConnectedDevice => 'Bağlı cihaz';

  @override
  String remoteTrashRequest(String device, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosyayı',
      one: '1 dosyayı',
    );
    return '$device, $_temp0 çöp kutusuna taşımak istiyor';
  }

  @override
  String remoteTrashDone(String device, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosyayı',
      one: '1 dosyayı',
    );
    return '$device, $_temp0 çöp kutusuna taşıdı';
  }

  @override
  String remoteTrashDeclinedByYou(String device) {
    return '$device cihazının isteğini reddettin';
  }

  @override
  String remoteWriteRequest(String device, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosyayı',
      one: '1 dosyayı',
    );
    return '$device, $_temp0 değiştirmek istiyor';
  }

  @override
  String get shareMediaOnlyHint =>
      'Tüm dosyalara erişim olmadan diğer cihazlar yalnızca fotoğrafları, videoları ve sesleri görür.';

  @override
  String get rememberThisDevice => 'Bu cihazı hatırla';

  @override
  String get acceptAlwaysAllow => 'Bu cihaza her zaman izin ver';

  @override
  String get acceptAlwaysAllowHint => 'Bir dahaki sefere sormadan bağlanır';

  @override
  String shareAutoAccepted(String name) {
    return '$name bağlandı';
  }

  @override
  String shareRememberedFolders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count klasör',
      one: '1 klasör',
    );
    return '$_temp0 paylaşılıyor';
  }

  @override
  String get shareFoldersMissing => 'Bazı paylaşılan klasörler artık yok';

  @override
  String get shareFoldersChange => 'Değiştir';

  @override
  String connectErrorKeyChanged(String name) {
    return '$name değişti. QR kodu yeniden tara.';
  }

  @override
  String get connectErrorNotAllowed => 'İzin verilmiyor. QR kodu yeniden tara.';

  @override
  String connectErrorOffline(String name) {
    return '$name cihazına ulaşılamıyor. $name cihazında “Bu cihazı paylaş” ekranını aç.';
  }

  @override
  String get rememberedDevicesTitle => 'Hatırlanan cihazlar';

  @override
  String get rememberedDevicesHint =>
      'Taramadan yeniden bağlan ya da bir cihazı unut';

  @override
  String get rememberedEmpty =>
      'Henüz hatırlanan cihaz yok. “Bu cihazı hatırla” açıkken eşleştirdiğin cihazlar burada görünür.';

  @override
  String get rememberedLoadFailed => 'Hatırlanan cihazlar yüklenemedi';

  @override
  String get rememberedOnline => 'Şu an paylaşıyor';

  @override
  String get rememberedOffline => 'Şu an paylaşmıyor';

  @override
  String get rememberedConnected => 'Bağlı';

  @override
  String get rememberedConnectsToUs => 'Bu cihaza bağlanır';

  @override
  String rememberedStatusWords(String status, String words) {
    return '$status · $words';
  }

  @override
  String get rememberedReconnect => 'Yeniden bağlan';

  @override
  String get rememberedShareFromHere => 'Bu cihazdan paylaş';

  @override
  String get rememberedAlwaysAllow => 'Her zaman izin ver';

  @override
  String get rememberedAlwaysAllowHint => 'Bu cihaza bağlandığında sorma';

  @override
  String get rememberedRemove => 'Kaldır';

  @override
  String rememberedRemoveTitle(String name) {
    return '$name kaldırılsın mı?';
  }

  @override
  String get rememberedRemoveBody =>
      'Cihazın bağlantısı şimdi kesilir ve yeniden bağlanmak için QR kodu taraması gerekir. Kaybolan ya da çalınan hatırlanmış bir cihaz için yine de bu cihazın paylaşım yapıyor olması ve birinin Kabul et\'e dokunması gerekir; kaldırmak bunu bile imkânsız hale getirir.';

  @override
  String get rememberedRemoveAll => 'Tümünü kaldır';

  @override
  String get rememberedRemoveAllTitle =>
      'Tüm hatırlanan cihazlar kaldırılsın mı?';

  @override
  String get rememberedRemoveAllBody =>
      'Bağlanmak için her cihazın QR kodu yeniden taraması gerekir.';

  @override
  String get rememberedRemoveFailed => 'Cihaz kaldırılamadı. Tekrar dene.';

  @override
  String get resetIdentityTitle => 'Bu cihazın kimliğini sıfırla';

  @override
  String get resetIdentityHint =>
      'Tüm cihazları unut ve her cihazın yeniden taramasını sağla';

  @override
  String get resetIdentityConfirmTitle => 'Bu cihazın kimliği sıfırlansın mı?';

  @override
  String get resetIdentityConfirmBody =>
      'Paylaşım durur, bu cihaz yeni bir anahtar alır ve hatırlanan tüm cihazlar unutulur. Diğer cihazların QR kodu yeniden taraması gerekir. Bir cihazın güvenliği tehlikeye girmiş olabilirse ya da bu cihazı başkasına vermeden önce bunu kullan.';

  @override
  String get resetIdentityConfirm => 'Sıfırla';

  @override
  String get resetIdentityDone =>
      'Yeni kimlik oluşturuldu. Diğer cihazların yeniden taraması gerekir.';

  @override
  String get resetIdentityFailed => 'Kimlik sıfırlanamadı. Tekrar dene.';

  @override
  String swipeProblemFolderNotOnSource(String device) {
    return '$device cihazında bir klasör seç';
  }

  @override
  String swipeProblemReadOnly(String device) {
    return '$device cihazında salt okunur';
  }

  @override
  String swipeProblemNotOnDevice(String device) {
    return '$device cihazındaki dosyalar için kullanılamaz';
  }

  @override
  String remoteSwipeWaiting(String device) {
    return '$device bekleniyor…';
  }

  @override
  String remoteSwipeContinue(String device) {
    return '$device cihazında kaydırmaya devam et';
  }

  @override
  String remoteSwipeSwiped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kaydırıldı',
      one: '1 kaydırıldı',
      zero: 'Henüz kaydırma yok',
    );
    return '$_temp0';
  }

  @override
  String remoteSwipePaused(String device) {
    return 'Duraklatıldı · $device bağlı değil';
  }

  @override
  String remoteSwipeOrphaned(String device) {
    return '$device artık hatırlanmıyor';
  }

  @override
  String remoteSwipeFinishNeedsConnection(String device) {
    return 'Bitirmek için $device cihazına bağlan';
  }

  @override
  String remoteSwipeFinishBody(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya $device cihazındaki çöp kutusuna taşınacak.',
      one: '1 dosya $device cihazındaki çöp kutusuna taşınacak.',
      zero: 'Silinmeyi bekleyen bir şey yok.',
    );
    return '$_temp0';
  }

  @override
  String remoteSwipeRestoreOnDevice(String device) {
    return '$device cihazındaki çöp kutusundan geri yükle';
  }

  @override
  String remoteSwipeDeclined(String device) {
    return '$device silmeyi reddetti';
  }

  @override
  String get remoteSwipeAllDone => 'Bu klasörde her şey bitti.';

  @override
  String get remoteSwipeDiscard => 'Oturumu sil';

  @override
  String remoteSwipeDiscardTitle(String device) {
    return '$device cihazındaki kaydırma oturumu silinsin mi?';
  }

  @override
  String get remoteSwipeDiscardBody =>
      'Oradaki kaydırmaların unutulur. O cihazda hiçbir şey silinmez.';

  @override
  String get remoteSwipeUnknownDevice => 'diğer cihaz';

  @override
  String get transfersTitle => 'Aktarımlar';

  @override
  String get transfersDownloads => 'İndirmeler';

  @override
  String get transfersUploads => 'Yüklemeler';

  @override
  String get transfersEmptyDownloads =>
      'Henüz indirme yok. Bağlı bir cihazda dosya seç ve İndir\'e dokun.';

  @override
  String get transfersEmptyUploads =>
      'Henüz yükleme yok. Dosya seç ve Cihaza gönder\'e dokun.';

  @override
  String transferFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya',
      one: '1 dosya',
    );
    return '$_temp0';
  }

  @override
  String transferFromDevice(String device) {
    return 'Kaynak: $device';
  }

  @override
  String transferToDevice(String device) {
    return 'Hedef: $device';
  }

  @override
  String transferSpeedEta(String speed, String eta) {
    return '$speed/sn · $eta kaldı';
  }

  @override
  String transferProgress(String done, String total) {
    return '$done / $total';
  }

  @override
  String get transferStatusQueued => 'Bekliyor';

  @override
  String transferStatusWaitingFor(String device) {
    return '$device bekleniyor';
  }

  @override
  String get transferStatusRunning => 'Aktarılıyor';

  @override
  String get transferStatusDone => 'Bitti';

  @override
  String transferStatusFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya başarısız oldu',
      one: '1 dosya başarısız oldu',
    );
    return '$_temp0';
  }

  @override
  String get transferStatusCancelled => 'İptal edildi';

  @override
  String get transferCancel => 'İptal';

  @override
  String get transferRetry => 'Tekrar dene';

  @override
  String get transferClearFinished => 'Bitenleri temizle';

  @override
  String transferNoSpaceOn(String device) {
    return '$device cihazında yeterli alan yok';
  }

  @override
  String get transferNoSpaceHere => 'Bu cihazda yeterli alan yok';

  @override
  String transferNotAllowedOn(String device) {
    return '$device cihazında izin verilmiyor';
  }

  @override
  String transferNoWritableFolder(String device) {
    return '$device yazılabilir bir klasör paylaşmıyor';
  }

  @override
  String get transferInvalidName => 'Bu dosya adı burada kullanılamaz';

  @override
  String get transferNoLocation => 'Konum bilgisi eklenmedi';

  @override
  String get transferAlreadySent => 'Zaten gönderildi';

  @override
  String transferConnectToPick(String device) {
    return 'Klasör seçmek için $device cihazına bağlan';
  }

  @override
  String transfersRunning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktarım sürüyor',
      one: '1 aktarım sürüyor',
      zero: 'Çalışan aktarım yok',
    );
    return '$_temp0';
  }

  @override
  String transferLostConnection(String device) {
    return '$device ile bağlantı koptu';
  }

  @override
  String get transferInterrupted => 'KFM kapanınca durdu';

  @override
  String get transferSourceGone => 'Dosya artık yok';

  @override
  String get transferIncomplete => 'Aktarım yarıda kesildi';

  @override
  String get transferFailedGeneric => 'Bu dosya aktarılamadı';

  @override
  String get transferPause => 'Duraklat';

  @override
  String get transferResume => 'Devam et';

  @override
  String get transferReconnect => 'Yeniden bağlan';

  @override
  String get transferPausedByYou => 'Duraklatıldı';

  @override
  String get transferRetrying => 'Birazdan tekrar denenecek';

  @override
  String get transferSourceChanged => 'Dosya gönderilirken değişti';

  @override
  String get transferModeCopy => 'Kopyala';

  @override
  String get transferModeMove => 'Taşı';

  @override
  String transferMoveDownloadNote(String device) {
    return 'Her dosya geldikten sonra doğrulanır; ancak o zaman orijinali $device cihazında çöp kutusuna taşınır.';
  }

  @override
  String get transferMoveToDevice => 'Cihaza taşı';

  @override
  String transferMoveFromDevice(String device) {
    return '$device cihazından taşınıyor';
  }

  @override
  String transferMoveToDeviceTitle(String device) {
    return '$device cihazına taşınıyor';
  }

  @override
  String transferMoveQueued(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya $device cihazına taşınıyor',
      one: '1 dosya $device cihazına taşınıyor',
    );
    return '$_temp0';
  }

  @override
  String transferMoveDownloadQueued(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya $device cihazından taşınıyor',
      one: '1 dosya $device cihazından taşınıyor',
    );
    return '$_temp0';
  }

  @override
  String get transferVerifying => 'Doğrulanıyor…';

  @override
  String get transferVerified => 'Doğrulandı';

  @override
  String get transferVerifyFailed => 'Doğrulama başarısız. Orijinal saklandı.';

  @override
  String get transferAlreadyMoved => 'Zaten taşındı';

  @override
  String get transferOriginalPending => 'Doğrulandı · orijinal henüz silinmedi';

  @override
  String get transferOriginalTrashed =>
      'Doğrulandı · orijinal çöp kutusuna taşındı';

  @override
  String transferOriginalTrashedOn(String device) {
    return 'Doğrulandı · orijinal $device cihazında çöp kutusuna taşındı';
  }

  @override
  String get transferOriginalDeleted => 'Doğrulandı · orijinal silindi';

  @override
  String get transferOriginalGone => 'Doğrulandı · orijinal zaten yoktu';

  @override
  String get transferOriginalKeptDeclined =>
      'Doğrulandı · orijinal saklandı (sen reddettin)';

  @override
  String transferOriginalKeptDeclinedOn(String device) {
    return 'Doğrulandı · orijinal saklandı ($device cihazında reddedildi)';
  }

  @override
  String get transferOriginalKeptCancelled =>
      'Doğrulandı · orijinal saklandı (iptal edildi)';

  @override
  String get transferOriginalKeptChanged => 'Orijinal saklandı (değişmiş)';

  @override
  String get transferOriginalKeptFailed =>
      'Doğrulandı · orijinal saklandı (silinemedi)';

  @override
  String get transferDeleteOriginals => 'Orijinalleri sil';

  @override
  String get transferDeletingOriginals => 'Orijinaller siliniyor…';

  @override
  String get permanentMoveTitle => 'Orijinaller kalıcı olarak silinsin mi?';

  @override
  String permanentMoveBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Silme ayarın \'Kalıcı olarak sil\': kopyaları doğrulanınca $count orijinal tamamen silinir.',
      one: 'Silme ayarın \'Kalıcı olarak sil\': kopyası doğrulanınca orijinal tamamen silinir.',
    );
    return '$_temp0';
  }

  @override
  String get permanentMoveUseTrash => 'Çöp kutusunu kullan';

  @override
  String get permanentMoveConfirm => 'Kalıcı olarak sil';

  @override
  String get transferDownloadAction => 'İndir';

  @override
  String transferDownloadQueued(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya $device cihazından indiriliyor',
      one: '1 dosya $device cihazından indiriliyor',
    );
    return '$_temp0';
  }

  @override
  String transferUploadQueued(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya $device cihazına gönderiliyor',
      one: '1 dosya $device cihazına gönderiliyor',
    );
    return '$_temp0';
  }

  @override
  String get transferShow => 'Göster';

  @override
  String get transferSendToDevice => 'Cihaza gönder';

  @override
  String get transferConnectFirst => 'Önce bir cihaza bağlan';

  @override
  String transferDownloadTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya indirilsin mi?',
      one: '1 dosya indirilsin mi?',
    );
    return '$_temp0';
  }

  @override
  String transferDownloadTo(String folder) {
    return 'Kayıt yeri: $folder';
  }

  @override
  String get transferChangeFolder => 'Klasörü değiştir';

  @override
  String get transferPickDeviceTitle => 'Hangi cihaza gönderilsin?';

  @override
  String get transferNoRememberedDevices =>
      'Henüz hatırlanan cihaz yok. \'Bu cihazı hatırla\' açıkken bir cihaza bağlan.';

  @override
  String get swipeProblemDeviceMissing => 'Bu cihaz artık hatırlanmıyor';

  @override
  String get swipeActionSendToDevice => 'Cihaza gönder…';

  @override
  String swipeActionSendToNamed(String device) {
    return '$device cihazına gönder';
  }

  @override
  String rememberedRemoveTransfers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cihazın $count aktarımı da kaldırılır.',
      one: 'Cihazın 1 aktarımı da kaldırılır.',
    );
    return '$_temp0';
  }

  @override
  String get errorLogShare => 'Hata kaydını paylaş';

  @override
  String get errorLogEmpty => 'Kaydedilmiş hata yok';

  @override
  String get errorLogShareSubject => 'KFM hata kaydı';

  @override
  String get errorLogShareFailed => 'Hata kaydı paylaşılamadı';

  @override
  String get errorLogClear => 'Hata kaydını temizle';

  @override
  String get errorLogClearConfirm =>
      'Hata kaydı temizlensin mi? Bu işlem geri alınamaz.';

  @override
  String get errorLogCleared => 'Hata kaydı temizlendi';

  @override
  String get errorLogClearFailed => 'Hata kaydı temizlenemedi';

  @override
  String get devThrowTestError => 'Test hatası oluştur';

  @override
  String get themeColorLabel => 'Renk';

  @override
  String get accentBlue => 'Mavi';

  @override
  String get accentGreen => 'Yeşil';

  @override
  String get accentPurple => 'Mor';

  @override
  String get accentOrange => 'Turuncu';

  @override
  String get accentMono => 'Siyah beyaz';

  @override
  String get accentSystem => 'Sistem renkleri';

  @override
  String get settingsAccessibility => 'Erişilebilirlik';

  @override
  String get leftHandedTitle => 'Solak';

  @override
  String get textSizeLabel => 'Metin boyutu';

  @override
  String get textSizeSystem => 'Sistem';

  @override
  String get textSizeLarge => 'Büyük';

  @override
  String get textSizeExtraLarge => 'Çok büyük';

  @override
  String get textSizePreview => 'Metin böyle görünecek.';

  @override
  String get externalPlacesTitle => 'Yerler';

  @override
  String get externalInternal => 'Dahili depolama';

  @override
  String get externalGeneric => 'Harici depolama';

  @override
  String get externalSdCard => 'SD kart';

  @override
  String get externalUsbDrive => 'USB bellek';

  @override
  String externalFreeOf(String free, String total) {
    return '$free boş / $total';
  }

  @override
  String externalAttached(String label) {
    return '$label bağlandı';
  }

  @override
  String get externalOpen => 'Aç';

  @override
  String get externalRemoved => 'Depolama çıkarıldı';

  @override
  String externalGrantTitle(String label) {
    return '$label için erişime izin ver';
  }

  @override
  String get externalGrantExplain =>
      'Android, KFM\'nin hangi sürücüyü kullanabileceğini bir kez sorar. Sonraki ekranda sürücünün kendisini seç (içindeki bir klasörü değil) ve \'Bu klasörü kullan\'a dokun.';

  @override
  String get externalGrantContinue => 'Devam';

  @override
  String get externalPickRootTitle => 'Sürücünün kendisini seç';

  @override
  String get externalPickRootHint =>
      'Bu, sürücünün içindeki bir klasördü. KFM\'nin her şeyi görebilmesi için sürücünün en üst düzeyini seç.';

  @override
  String get externalRetry => 'Tekrar seç';

  @override
  String get externalGrantFailed => 'Android erişimi saklamadı. Tekrar dene.';

  @override
  String externalAllFilesTitle(String label) {
    return '$label için erişim';
  }

  @override
  String externalAllFilesExplain(String label) {
    return '$label için KFM\'nin Tüm dosyalara erişim iznine ihtiyacı var. Android, uygulamaların bir SD kartı veya USB belleği başka bir yolla seçmesine izin vermiyor. Sonraki ekranda KFM için erişimi aç, sonra geri dön.';
  }

  @override
  String externalAllFilesStillOff(String label) {
    return 'Tüm dosyalara erişim hâlâ kapalı, bu yüzden şu açılamıyor: $label.';
  }

  @override
  String get externalFormatHelp =>
      'USB bellek açılmadı. Android FAT32 ve exFAT sürücüleri okur; NTFS sürücüler çoğu zaman çalışmaz. Belleği bir bilgisayarda yeniden biçimlendir veya başka bir sürücü dene.';

  @override
  String externalCameraLabel(String model) {
    return 'Kamera · $model';
  }

  @override
  String get externalCameraUnsupported =>
      'Bu kamera burada açılamıyor. Diğer kamera uygulamalarını kapat veya kamerayı USB yığın depolama moduna al.';

  @override
  String get externalPermissionNeeded =>
      'İzin gerekli · İzin vermek için dokun';

  @override
  String get externalCameraReadOnly => 'Bağlı · salt okunur';

  @override
  String get externalCameraNotYet => 'Kameraları açmak henüz mümkün değil.';

  @override
  String get externalLoadError => 'Depolama listesi okunamadı.';

  @override
  String get privacySectionTitle => 'Gizlilik';

  @override
  String get privacyStripLocation => 'Paylaşırken konumu kaldır';

  @override
  String get privacyStripLocationHelp =>
      'Paylaştığın veya başka bir cihaza gönderdiğin fotoğraf ve videolar konum bilgisi olmadan gider. Orijinallerinde konum kalır.';

  @override
  String get privacyAllowAccess => 'Fotoğraf konumlarına erişime izin ver';

  @override
  String get privacyAllowAccessHelp =>
      'Bu izin olmadan gönderdiğin fotoğraflar konumsuz ulaşır.';

  @override
  String get privacyNoOriginalNote =>
      'KFM fotoğraflarının orijinal konumunu okuyamıyor; zaten konumsuz gönderilirler.';

  @override
  String get privacyShareAction => 'Paylaş';

  @override
  String privacyShareTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosyayı paylaş',
      one: '1 dosyayı paylaş',
    );
    return '$_temp0';
  }

  @override
  String get privacyShareRemoveLocation => 'Konumu kaldır';

  @override
  String get privacyShareRemoveLocationHelp =>
      'Fotoğraf ve videolardan. Orijinallerinde konum kalır.';

  @override
  String privacyRemovingLocation(int done, int total) {
    return 'Konum kaldırılıyor… $done/$total';
  }

  @override
  String get privacyShareNoApp => 'Bu dosyaları alabilecek uygulama yok';

  @override
  String privacyCouldNotStrip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosyadan konum kaldırılamadığı için paylaşılmadılar',
      one: '1 dosyadan konum kaldırılamadığı için paylaşılmadı',
    );
    return '$_temp0';
  }

  @override
  String privacyFailedLine(String name, String reason) {
    return '$name: $reason';
  }

  @override
  String get privacyFailStillHasLocation =>
      'kaldırıldıktan sonra hâlâ konum bilgisi bulundu';

  @override
  String get privacyFailUnsupported => 'bu videonun bilgileri düzenlenemiyor';

  @override
  String get privacyFailReadFailed => 'dosya okunamadı';

  @override
  String get privacyTransferNotRemoved =>
      'Konum kaldırılamadığı için gönderilmedi';

  @override
  String get privacyMoveWarningTitle => 'Konum olmadan taşınsın mı?';

  @override
  String get privacyMoveWarningBody =>
      'Kopyalarda konum olmayacak ve konumlu orijinaller bu cihazdan silinecek.';

  @override
  String get privacyMoveAnyway => 'Yine de taşı';

  @override
  String get privacyCopyInstead => 'Bunun yerine kopyala';

  @override
  String externalJobTitleCopy(int count, String place) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya $place hedefine kopyalanıyor',
      one: '1 dosya $place hedefine kopyalanıyor',
    );
    return '$_temp0';
  }

  @override
  String externalJobTitleMove(int count, String place) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya $place hedefine taşınıyor',
      one: '1 dosya $place hedefine taşınıyor',
    );
    return '$_temp0';
  }

  @override
  String externalJobProgress(int done, int total, String size) {
    return '$done / $total · $size';
  }

  @override
  String get externalJobQueued => 'Bekliyor';

  @override
  String get externalJobRunning => 'Sürüyor';

  @override
  String get externalJobPaused => 'Duraklatıldı';

  @override
  String get externalJobPausedUnplugged =>
      'Duraklatıldı · devam etmek için depolamayı yeniden bağla';

  @override
  String get externalJobDone => 'Bitti';

  @override
  String get externalJobCancelled => 'İptal edildi';

  @override
  String externalJobFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya başarısız',
      one: '1 dosya başarısız',
    );
    return '$_temp0';
  }

  @override
  String get externalJobStoppedNoSpace => 'Durdu: yeterli alan yok';

  @override
  String get externalJobResume => 'Devam et';

  @override
  String get externalJobPause => 'Duraklat';

  @override
  String get externalJobDetails => 'Ayrıntılar';

  @override
  String externalJobStartedCopy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya kopyalanıyor…',
      one: '1 dosya kopyalanıyor…',
    );
    return '$_temp0';
  }

  @override
  String externalJobStartedMove(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya taşınıyor…',
      one: '1 dosya taşınıyor…',
    );
    return '$_temp0';
  }

  @override
  String get externalJobView => 'Görüntüle';

  @override
  String externalNotEnoughSpace(String place) {
    return 'Yeterli alan yok: $place';
  }

  @override
  String get externalStagingNoSpace =>
      'Bu telefonda, kopyalamanın üzerinden geçeceği kadar boş alan yok';

  @override
  String externalFat32TooLarge(String name) {
    return '$name: 4 GB veya daha büyük, bu sürücü için çok büyük (FAT32)';
  }

  @override
  String externalRenamedForDrive(String from, String to) {
    return '$from, $to olarak kaydedildi';
  }

  @override
  String externalCollisionTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya zaten orada',
      one: '1 dosya zaten orada',
    );
    return '$_temp0';
  }

  @override
  String get externalCollisionKeepBoth => 'İkisini de sakla';

  @override
  String get externalCollisionSkip => 'Atla';

  @override
  String get externalCollisionReplace => 'Değiştir';

  @override
  String get externalApplyToAll =>
      'Seçimin bu işteki tüm dosyalar için geçerli.';

  @override
  String get externalCameraDeleteWarning =>
      'Kamera fotoğraflarının çöp kutusu yok: burada silersen tamamen silinirler.';

  @override
  String externalOriginalNotRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orijinal kaldırılmadı',
      one: '1 orijinal kaldırılmadı',
    );
    return '$_temp0';
  }

  @override
  String get externalDeleteOriginals => 'Orijinalleri sil';

  @override
  String get externalSwipeFolder => 'Bu klasörü kaydır';

  @override
  String get externalSwipeFolderEmpty => 'Bu klasörde fotoğraf veya video yok';

  @override
  String get externalNoJobs =>
      'Son 7 günde depolama yerleri arasında kopyalama veya taşıma yok';

  @override
  String get externalClearFinished => 'Bitenleri temizle';

  @override
  String get externalVerifyFailed => 'Doğrulama başarısız. Orijinal saklandı.';

  @override
  String get externalSourceGone => 'Dosya artık yok';

  @override
  String get externalAlreadyMoved => 'Zaten taşındı';

  @override
  String get externalSkippedExists => 'Atlandı: zaten orada';

  @override
  String get externalFileFailed => 'Kopyalanamadı';

  @override
  String externalLogLine(String name, String reason) {
    return '$name: $reason';
  }

  @override
  String get externalFolderEmpty => 'Bu klasör boş';

  @override
  String get externalFolderError => 'Bu klasör açılamadı';

  @override
  String get externalSortByName => 'Ad';

  @override
  String get externalSortByDate => 'Tarih';

  @override
  String get externalSortBySize => 'Boyut';

  @override
  String get externalShowAll => 'Tüm dosyalar';

  @override
  String get externalShowMedia => 'Fotoğraflar ve videolar';

  @override
  String get externalCopyTo => 'Şuraya kopyala…';

  @override
  String get externalMoveTo => 'Şuraya taşı…';

  @override
  String get externalDelete => 'Sil';

  @override
  String get externalReadOnly => 'Salt okunur';

  @override
  String externalDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya silindi',
      one: '1 dosya silindi',
    );
    return '$_temp0';
  }

  @override
  String get externalDeleteFailed => 'Silinemedi';

  @override
  String get swipeSetupTitle => 'Kaydırma ayarları';

  @override
  String get swipeSetupTuneTooltip => 'Kaydırma ayarları';

  @override
  String get swipeSetupPresets => 'Hazır ayarlar';

  @override
  String get swipeSetupDirections => 'Kaydırma yönleri';

  @override
  String get swipeSetupFilter => 'Filtre';

  @override
  String get swipeSetupEditFilter => 'Filtreyi düzenle';

  @override
  String get swipeSetupExtras => 'Ekstralar';

  @override
  String swipeSetupModified(String name) {
    return 'Değişiklikler $name hazır ayarına kaydedilmedi';
  }

  @override
  String get swipeSetupSave => 'Kaydet';

  @override
  String get swipeSetupSaveAsNew => 'Yeni olarak kaydet…';

  @override
  String get swipeSetupRevert => 'Geri döndür';

  @override
  String swipeSetupSavedTo(String name) {
    return '\'$name\' hazır ayarına kaydedildi';
  }

  @override
  String swipeSetupRemoteTitle(String device) {
    return '$device cihazında kaydırma ayarları';
  }

  @override
  String swipeSetupPresetSemantics(String name) {
    return 'Hazır ayar $name';
  }

  @override
  String swipeSetupPresetModifiedSemantics(String name) {
    return 'Hazır ayar $name, değiştirildi';
  }

  @override
  String swipeSetupDirectionSemantics(String direction, String action) {
    return '$direction: $action';
  }

  @override
  String get swipeSetupFilterOn => 'Filtre açık';

  @override
  String get swipeSetupPresetBroken => 'Yüklenemiyor';

  @override
  String get ejectAction => 'Çıkar';

  @override
  String ejectRunningJobs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktarım hâlâ sürüyor',
      one: '1 aktarım hâlâ sürüyor',
    );
    return '$_temp0';
  }

  @override
  String get ejectRunningJobsBody =>
      'Duraklatma, geçerli dosyadan sonra durur. Duraklatılan aktarımlara daha sonra devam edilebilir.';

  @override
  String get ejectWait => 'Bekle';

  @override
  String get ejectPauseAndEject => 'Duraklat ve çıkar';

  @override
  String ejectWaiting(String label) {
    return '$label üzerindeki işlemler bitiriliyor…';
  }

  @override
  String ejectHintTitle(String label) {
    return 'Çıkar: $label';
  }

  @override
  String get ejectHint =>
      'Android, depolamanın yalnızca kendi ayarlarından çıkarılmasına izin verir. Sürücüye, ardından Çıkar\'a dokun (bazı telefonlarda: ⋮ → Bağlantıyı kes).';

  @override
  String get ejectOpenSettings => 'Ayarları aç';

  @override
  String ejectSafe(String label) {
    return '$label güvenle çıkarılabilir';
  }

  @override
  String get ejectNotYet => 'Henüz çıkarılmadı';

  @override
  String get ejectOpenAgain => 'Ayarları tekrar aç';

  @override
  String get ejectCameraSafe => 'Kameranın bağlantısı kesilebilir';

  @override
  String get ejectRefused => 'Bu depolama çıkarılıyor';

  @override
  String get ejectFailed => 'Depolama ayarları açılamıyor';

  @override
  String get sendTo => 'Şuraya gönder…';

  @override
  String sendSheetTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosyayı şuraya gönder…',
      one: '1 dosyayı şuraya gönder…',
    );
    return '$_temp0';
  }

  @override
  String get sendSheetConnected => 'Bağlı';

  @override
  String get sendSheetConnectedToYou => 'Sana bağlı';

  @override
  String get sendSheetRemembered => 'Hatırlanan';

  @override
  String get sendSheetNearby => 'Yakındakiler';

  @override
  String get sendSheetOnline => 'Şu an yakında';

  @override
  String sendAskReceive(String device) {
    return '$device cihazında \'Dosya al\' ekranının açılmasını iste';
  }

  @override
  String sendSwitchDevice(String from, String to) {
    return '$to cihazına göndermek için $from bağlantısı kesilsin mi?';
  }

  @override
  String get sendSwitchAction => 'Bağlantıyı kes';

  @override
  String sendConnecting(String device) {
    return '$device cihazına bağlanılıyor…';
  }

  @override
  String sendConfirmTitle(int count, String size, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya ($size) $device cihazına gönderilsin mi?',
      one: '1 dosya ($size) $device cihazına gönderilsin mi?',
    );
    return '$_temp0';
  }

  @override
  String sendConfirmHint(String device) {
    return 'Dosyaları alıp almamaya $device karar verir. Başka hiçbir şey paylaşılmaz.';
  }

  @override
  String sendSharedFolderInstead(String device) {
    return '$device cihazında paylaşılan bir klasöre koy…';
  }

  @override
  String get sendAction => 'Gönder';

  @override
  String sendWaiting(String device) {
    return '$device cihazının kabul etmesi bekleniyor…';
  }

  @override
  String sendDeclined(String device) {
    return '$device reddetti';
  }

  @override
  String sendNoAnswer(String device) {
    return '$device yanıt vermedi';
  }

  @override
  String sendNoSpace(String device) {
    return 'Yeterli alan yok: $device';
  }

  @override
  String sendStopped(String device) {
    return '$device tarafından durduruldu';
  }

  @override
  String sendSending(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$device cihazına $count dosya gönderiliyor',
      one: '$device cihazına 1 dosya gönderiliyor',
    );
    return '$_temp0';
  }

  @override
  String get sendPairToSend => 'Dosya göndermek için bağlan';

  @override
  String sendConfirmPanelTitle(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$device cihazına $count dosya gönder',
      one: '$device cihazına 1 dosya gönder',
    );
    return '$_temp0';
  }

  @override
  String get receiveFiles => 'Dosya al';

  @override
  String get receiveFilesHint =>
      'Başka bir cihazın sana dosya göndermesine izin ver';

  @override
  String get receiveReadyTitle => 'Dosya almaya hazır';

  @override
  String receiveReadyHint(String device) {
    return 'Diğer cihazda: Gönder… → $device seç veya bu kodu tara';
  }

  @override
  String offerTitle(String device, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$device sana $count dosya göndermek istiyor',
      one: '$device sana 1 dosya göndermek istiyor',
    );
    return '$_temp0';
  }

  @override
  String offerSize(String size) {
    return 'Toplam $size';
  }

  @override
  String offerMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 've $count tane daha',
      one: 've 1 tane daha',
    );
    return '$_temp0';
  }

  @override
  String offerSaveTo(String folder) {
    return 'Kaydedilecek yer: $folder';
  }

  @override
  String get offerChangeFolder => 'Değiştir';

  @override
  String get offerFolderExcluded => 'Dosyalar buraya kaydedilemez';

  @override
  String offerRemember(String device) {
    return '$device cihazını hatırla';
  }

  @override
  String offerAlwaysAccept(String device) {
    return '$device cihazından gelen dosyaları her zaman kabul et';
  }

  @override
  String get offerAccept => 'Kabul et';

  @override
  String get offerDecline => 'Reddet';

  @override
  String offerAutoDecline(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds saniye içinde reddedilecek',
      one: '1 saniye içinde reddedilecek',
    );
    return '$_temp0';
  }

  @override
  String get offerNotificationChannel => 'Gelen dosyalar';

  @override
  String offerNotificationTitle(String device) {
    return '$device sana dosya göndermek istiyor';
  }

  @override
  String offerNotificationBody(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya · $size · Yanıtlamak için dokun',
      one: '1 dosya · $size · Yanıtlamak için dokun',
    );
    return '$_temp0';
  }

  @override
  String offerReceiving(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$device cihazından $count dosya alınıyor',
      one: '$device cihazından 1 dosya alınıyor',
    );
    return '$_temp0';
  }

  @override
  String offerReceived(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$device cihazından $count dosya alındı',
      one: '$device cihazından 1 dosya alındı',
    );
    return '$_temp0';
  }

  @override
  String get offerOpenFolder => 'Aç';

  @override
  String get rememberedAcceptFiles => 'Dosyaları sormadan kabul et';

  @override
  String get rememberedAcceptFilesHint =>
      'Bu cihazın gönderdiği dosyalar sorulmadan İndirilenler klasörüne gider';

  @override
  String connectSendOnly(String device) {
    return 'Dosya göndermek için $device cihazına bağlanıldı';
  }

  @override
  String shareSessionSending(String device) {
    return '$device · dosya gönderiyor';
  }

  @override
  String get transferReceivedSection => 'Alınanlar';

  @override
  String get transferOfferedSection => 'Teklif edilenler';

  @override
  String get transferWaitingForYou => 'Seni bekliyor';

  @override
  String get transferPreparing => 'Hazırlanıyor…';

  @override
  String transferFromDeviceOffer(String device, int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gönderen: $device · $count dosya · $size',
      one: 'Gönderen: $device · 1 dosya · $size',
    );
    return '$_temp0';
  }

  @override
  String transferToDeviceOffer(String device, int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alıcı: $device · $count dosya · $size',
      one: 'Alıcı: $device · 1 dosya · $size',
    );
    return '$_temp0';
  }

  @override
  String transferOfferReceiving(int done, int count) {
    return '$count dosyadan $done tanesi alındı';
  }

  @override
  String get transferOfferDone => 'Bitti';

  @override
  String get transferOfferCancelled => 'Durduruldu';

  @override
  String get transferOfferDeclined => 'Reddedildi';

  @override
  String get transferOfferExpired => 'Yanıt yok';

  @override
  String get transferOfferStop => 'Durdur';

  @override
  String get transferOfferAnswer => 'Yanıtla';

  @override
  String get transferOfferOpenFolder => 'Klasörü aç';

  @override
  String get transferOfferAccepted => 'Kabul edildi';

  @override
  String get transfersEmptyReceived =>
      'Diğer cihazların sana gönderdiği dosyalar burada görünür';

  @override
  String shareInTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paylaşılan dosya',
      one: '1 paylaşılan dosya',
    );
    return '$_temp0';
  }

  @override
  String get shareInSwipe => 'Kaydırarak gözden geçir';

  @override
  String get shareInMoveTo => 'Şuraya taşı…';

  @override
  String get shareInCopyTo => 'Şuraya kopyala…';

  @override
  String get shareInSendToDevice => 'Şuraya gönder…';

  @override
  String shareInCopiedSubtitle(String size) {
    return '$size · Başka bir uygulamadan kopyalandı';
  }

  @override
  String get shareInCopyDeleteNote =>
      'Başka bir uygulamadan kopyalanan dosyalar, sildiğinde KFM\'den kaldırılır. Orijinal o uygulamada kalır.';

  @override
  String get shareInOnlyFiles => 'KFM\'ye yalnızca dosya paylaşılabilir';

  @override
  String get shareInPreparing => 'Paylaşılan dosyalar alınıyor…';

  @override
  String shareInCopying(String done, String total) {
    return 'Kopyalanıyor: $done / $total';
  }

  @override
  String get shareInCancel => 'İptal';

  @override
  String shareInFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya okunamadı',
      one: '1 dosya okunamadı',
    );
    return '$_temp0';
  }

  @override
  String get shareInFailedAll =>
      'Paylaşılan dosyalar okunamadı. Tekrar paylaşmayı dene.';

  @override
  String get shareInNoSpace =>
      'Paylaşılan dosyaları kopyalamak için yeterli boş alan yok';

  @override
  String get shareInEmpty => 'Burada paylaşılan dosya kalmadı';

  @override
  String get shareInDone => 'Bitti';

  @override
  String get backupSectionTitle => 'Yedek';

  @override
  String get backupExport => 'Yedeği dışa aktar';

  @override
  String get backupExportHelp =>
      'Etiketler, hazır ayarlar, favoriler, incelendi işaretleri ve ayarlar tek dosyada. Fotoğrafların olduğu yerde kalır.';

  @override
  String get backupImport => 'Yedeği içe aktar';

  @override
  String get backupImportHelp =>
      'Bir yedeğin verilerini bu telefona ekler. Buradaki hiçbir şey silinmez.';

  @override
  String get backupUndoImport => 'Son içe aktarmayı geri al';

  @override
  String get backupUndoImportHelp =>
      'Her şeyi son içe aktarmadan önceki hâline döndür';

  @override
  String get backupExported => 'Yedek kaydedildi';

  @override
  String backupExportFailed(String error) {
    return 'Yedek kaydedilemedi: $error';
  }

  @override
  String backupImportFailed(String error) {
    return 'Yedek içe aktarılamadı: $error';
  }

  @override
  String get backupNotKfm => 'Bu bir KFM yedeği değil.';

  @override
  String get backupTooNew =>
      'Bu yedek, KFM\'nin daha yeni bir sürümüyle oluşturuldu. Önce uygulamayı güncelle.';

  @override
  String get backupPreviewTitle => 'Yedeği içe aktar';

  @override
  String get backupScanning => 'Taranıyor…';

  @override
  String backupPreviewNewTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yeni etiket',
      one: '1 yeni etiket',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewReusedTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count etiket bu telefonda zaten var',
      one: '1 etiket bu telefonda zaten var',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewNewPresets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yeni hazır ayar',
      one: '1 yeni hazır ayar',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewSkippedPresets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hazır ayar bu telefonda zaten var',
      one: '1 hazır ayar bu telefonda zaten var',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewMatched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bu telefonda $count dosya bulundu',
      one: 'Bu telefonda 1 dosya bulundu',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewFileTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dosyalara $count etiket eklendi',
      one: 'Bir dosyaya 1 etiket eklendi',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewFavorites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yeni favori',
      one: '1 yeni favori',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewReviewed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count incelendi işareti',
      one: '1 incelendi işareti',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewUnmatched(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya bu telefonda bulunamadı',
      one: '1 dosya bu telefonda bulunamadı',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewUnmatchedMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 've $count tane daha',
      one: 've 1 tane daha',
    );
    return '$_temp0';
  }

  @override
  String backupPreviewFilePath(String folder, String name) {
    return '$folder/$name';
  }

  @override
  String get backupApplySettings => 'Ayarları da uygula';

  @override
  String backupPreviewSettings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayar değişiyor',
      one: '1 ayar değişiyor',
      zero: 'Hiçbir ayar değişmiyor',
    );
    return '$_temp0';
  }

  @override
  String get backupPreviewNothing => 'İçe aktarılacak yeni bir şey yok.';

  @override
  String get backupImportedSuffix => 'içe aktarıldı';

  @override
  String get backupImportButton => 'İçe aktar';

  @override
  String get backupImported => 'Yedek içe aktarıldı';

  @override
  String get backupUndoConfirmTitle => 'Son içe aktarma geri alınsın mı?';

  @override
  String get backupUndoConfirmBody =>
      'Etiketler, hazır ayarlar, favoriler, incelendi işaretleri ve ayarlar içe aktarmadan önceki hâline döner. Sonrasında yaptığın değişiklikler de kaybolur.';

  @override
  String get backupUndoConfirm => 'İçe aktarmayı geri al';

  @override
  String get backupUndone => 'İçe aktarma geri alındı';

  @override
  String backupUndoFailed(String error) {
    return 'İçe aktarma geri alınamadı: $error';
  }

  @override
  String get backupSettingThemeMode => 'Tema';

  @override
  String get backupSettingThemeAccent => 'Renk teması';

  @override
  String get backupSettingLeftHanded => 'Solak modu';

  @override
  String get backupSettingTextSize => 'Metin boyutu';

  @override
  String get backupSettingLanguage => 'Dil';

  @override
  String get backupSettingBigFileThreshold => 'Büyük dosya boyutu';

  @override
  String get backupSettingPendingRetention =>
      'Silinen dosyaların saklanma süresi';

  @override
  String get backupSettingSameTimeWindow => 'Aynı zaman aralığı';

  @override
  String get backupSettingBrowseSort => 'Dosyaları sıralama ölçütü';

  @override
  String get backupSettingBrowseSortDescending => 'Sıralama yönü';

  @override
  String get backupSettingBrowseShowSizes => 'Dosya boyutlarını göster';

  @override
  String get backupSettingBrowseHighlightBig => 'Büyük dosyaları vurgula';

  @override
  String get backupSettingSearchSecondLanguage => 'İkinci arama dili';

  @override
  String get backupSettingSwipeLayout => 'Temel kaydırma yönleri';

  @override
  String get backupSettingDeleteMode => 'Silme modu';

  @override
  String get backupSettingHaptics => 'Titreşimli geri bildirim';

  @override
  String get backupSettingSwipeButtons => 'Kaydırma düğmeleri';

  @override
  String get backupSettingSessionSummary => 'Oturum özeti';

  @override
  String get backupSettingBasicIncludeReviewed =>
      'İncelenen dosyaları Temel\'de göster';

  @override
  String get backupSettingReviewedBadge => 'İncelendi rozeti';

  @override
  String get backupSettingActivePreset => 'Etkin hazır ayar';

  @override
  String get backupSettingActionBar => 'İşlem çubuğu';

  @override
  String get backupSettingFoldersDropAction => 'Klasöre bırakma';

  @override
  String get backupSettingSimilarEnabled => 'Benzer fotoğraflar';

  @override
  String get backupSettingSimilarStrictness => 'Benzer fotoğraf hassasiyeti';

  @override
  String get backupSettingSimilarBlur => 'Bulanık fotoğraf eşiği';

  @override
  String get backupSettingSimilarScreenshots =>
      'Ekran görüntülerini benzer fotoğraflara dahil et';

  @override
  String get backupSettingAiWifiOnly => 'Modelleri yalnızca Wi-Fi ile indir';

  @override
  String get backupSettingStripLocation => 'Paylaşırken konumu kaldır';

  @override
  String get backupSettingOther => 'Diğer ayar';

  @override
  String get apkInstall => 'Yükle';

  @override
  String get apkNewApp => 'Yeni uygulama';

  @override
  String apkUpdateFromTo(String from, String to) {
    return 'Güncelleme: $from → $to';
  }

  @override
  String get apkSameVersion => 'Bu sürüm zaten yüklü';

  @override
  String apkDowngrade(String installed) {
    return 'Yüklü sürümden daha eski ($installed)';
  }

  @override
  String get apkUnknownInstalled =>
      'Bunun yeni bir uygulama mı yoksa güncelleme mi olduğunu Android gösterecek';

  @override
  String get apkSignerMismatch =>
      'Farklı bir geliştirici tarafından imzalanmış. Android bu güncellemeyi reddedecek. Önce eski uygulamayı kaldır (verileri kaybolur).';

  @override
  String get apkSignerUnknown =>
      'Güncellemeler aynı geliştirici tarafından imzalanmalıdır.';

  @override
  String get apkTrustNote => 'Yalnızca güvendiğin kaynaklardan uygulama yükle.';

  @override
  String get apkInvalid => 'Bu dosya geçerli bir uygulama paketi değil.';

  @override
  String get apkNoSpace => 'Bu dosyayı incelemek için yeterli alan yok.';

  @override
  String apkReadFailed(String error) {
    return 'Bu dosya okunamadı: $error';
  }

  @override
  String apkInstallFailed(String error) {
    return 'Yükleyici başlatılamadı: $error';
  }

  @override
  String get apkNoInstaller =>
      'Bu cihazda paket yükleyebilen bir uygulama yok.';

  @override
  String get apkPermissionWhy =>
      'Uygulama yüklemek için Android, \"Bilinmeyen uygulamaları yükle\" bölümünde KFM\'ye izin vermeni ister. KFM, Android\'in kendi onayı olmadan hiçbir şey yüklemez.';

  @override
  String get apkOpenSettings => 'Ayarları aç';

  @override
  String get apkPermissionDenied => 'İzin verilmedi.';

  @override
  String apkPackageLine(String package, String version) {
    return '$package · sürüm $version';
  }

  @override
  String get updatesSectionTitle => 'Güncellemeler';

  @override
  String get updatesCheckSetting => 'Güncellemeleri denetle';

  @override
  String get updatesCheckSettingHelp =>
      'KFM günde bir kez GitHub\'a daha yeni bir sürüm olup olmadığını sorar. Sen veya dosyaların hakkında hiçbir şey gönderilmez; GitHub, her web sitesi gibi IP adresini görür.';

  @override
  String get updatesCheckNow => 'Şimdi denetle';

  @override
  String updatesCurrentVersion(String version) {
    return 'Yüklü sürüm $version';
  }

  @override
  String get updatesChecking => 'Denetleniyor…';

  @override
  String get updatesUpToDate => 'Güncelsin';

  @override
  String get updatesNoReleases => 'Sürüm bulunamadı';

  @override
  String updatesAvailable(String version) {
    return 'KFM $version kullanıma sunuldu';
  }

  @override
  String get updatesLastCheckFailed => 'Son denetim başarısız oldu';

  @override
  String get updatesFailedOffline =>
      'GitHub\'a ulaşılamadı. Bağlantını kontrol et.';

  @override
  String get updatesFailedBusy =>
      'GitHub şu an meşgul. Daha sonra tekrar dene.';

  @override
  String updatesFailed(String error) {
    return 'Güncelleme denetimi başarısız oldu: $error';
  }

  @override
  String get updatesWhatsNew => 'Yenilikler';

  @override
  String get updatesDownload => 'İndir';

  @override
  String get updatesDismiss => 'Bir sonraki sürüme kadar gizle';

  @override
  String get updatesNoNotes => 'Sürüm notu yok.';

  @override
  String get updatesNoBrowser => 'Tarayıcı uygulaması bulunamadı';

  @override
  String updatesOpenFailed(String error) {
    return 'Sayfa açılamadı: $error';
  }

  @override
  String get cloudSettingsTitle => 'Bulut';

  @override
  String get cloudDestinations => 'Bulut hedefleri';

  @override
  String get cloudDestinationsNone =>
      'Dosyaları bulut uygulamanın bir klasörüne kaydet';

  @override
  String cloudDestinationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count klasör',
      one: '1 klasör',
    );
    return '$_temp0';
  }

  @override
  String get cloudHowItWorks =>
      'KFM dosyaları bulut uygulamanın bir klasörüne kaydeder (Google Drive, OneDrive, Dropbox…). Bulut uygulaması onları yükler; KFM hiçbir yerde oturum açmaz.';

  @override
  String get cloudEmpty => 'Henüz bulut klasörü yok';

  @override
  String get cloudAdd => 'Bulut klasörü ekle';

  @override
  String cloudAdded(String name) {
    return 'Eklendi: $name';
  }

  @override
  String get cloudAddFailed => 'Bu klasöre erişim korunamadı';

  @override
  String get cloudRename => 'Yeniden adlandır';

  @override
  String get cloudRemove => 'Kaldır';

  @override
  String cloudRemoveTitle(String name) {
    return '$name kaldırılsın mı?';
  }

  @override
  String get cloudRemoveConfirm =>
      'KFM artık buraya dosya kaydetmeyecek. Bulutta olan dosyalar orada kalır.';

  @override
  String get cloudForgetUploads =>
      'Buraya hangi dosyaların yüklendiğini de unut';

  @override
  String get cloudNeedsReconnecting => 'Yeniden bağlanmalı';

  @override
  String get cloudReconnect => 'Yeniden bağlan';

  @override
  String get cloudNoFolderPicking =>
      'Bulut uygulaman klasör seçicide görünmüyorsa, diğer uygulamaların kendi klasörlerine kaydetmesine izin vermiyordur.';

  @override
  String cloudSavedToFolder(String name) {
    return 'Kaydedildi: $name';
  }

  @override
  String cloudVerified(String name) {
    return 'Doğrulandı: $name';
  }

  @override
  String cloudFailed(String reason) {
    return 'Başarısız: $reason';
  }

  @override
  String get cloudWaiting => 'Bekliyor';

  @override
  String cloudUploading(String name) {
    return 'Kaydediliyor: $name…';
  }

  @override
  String get cloudVerifyFailed => 'Kopya doğrulanamadı — orijinal saklandı';

  @override
  String get cloudVerifyUnavailable =>
      'Kopya geri okunamadı — orijinal saklandı';

  @override
  String get cloudCancelled => 'İptal edildi';

  @override
  String get cloudDestinationRemovedError => 'Hedef kaldırıldı';

  @override
  String get cloudSourceGone => 'Dosya artık yok';

  @override
  String get cloudSourceChanged => 'Dosya kopyalanırken değişti';

  @override
  String get cloudUnsupported => 'Bu dosya buluta kaydedilemez';

  @override
  String get cloudLocationNotRemoved => 'Konum kaldırılamadığı için yüklenmedi';

  @override
  String get cloudCopyMissing => 'Buluttaki kopya eksik — orijinal saklandı';

  @override
  String get cloudNoSpace => 'Bulut uygulamasında yer kalmadı';

  @override
  String get cloudWriteError => 'Bulut uygulaması dosyayı kabul etmedi';

  @override
  String cloudCopyLeftOver(String reason) {
    return '$reason. Bulut klasöründe bir kopya kaldı';
  }

  @override
  String get cloudOriginalNotFound =>
      'Orijinal bulunamadı, hiçbir şey silinmedi';

  @override
  String get cloudGpsNote =>
      'KFM konumu okuyamadığı için fotoğraflar konumsuz yükleniyor.';

  @override
  String get cloudGpsAllow => 'İzin ver';

  @override
  String get cloudGpsMoveTitle => 'Konum olmadan taşınsın mı?';

  @override
  String get cloudGpsMoveWarning =>
      'Konum verileri buluttaki kopyadan kaldırılabilir ve orijinal silinecek.';

  @override
  String get cloudGpsMoveAnyway => 'Yine de taşı';

  @override
  String get cloudTransfersSection => 'Bulut';

  @override
  String get cloudTransfersEmpty =>
      'Son 7 günde buluta hiçbir şey kaydedilmedi';

  @override
  String get cloudPickerGroup => 'Bulut';

  @override
  String cloudStartedCopy(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya kaydediliyor: $name…',
      one: '1 dosya kaydediliyor: $name…',
    );
    return '$_temp0';
  }

  @override
  String cloudStartedMove(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya taşınıyor: $name…',
      one: '1 dosya taşınıyor: $name…',
    );
    return '$_temp0';
  }

  @override
  String get cloudNothingToSend => 'Bu dosyalar buluta kaydedilemez';

  @override
  String cloudOriginalsKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orijinal saklandı',
      one: '1 orijinal saklandı',
    );
    return '$_temp0';
  }

  @override
  String cloudOriginalsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya taşındı',
      one: '1 dosya taşındı',
    );
    return '$_temp0';
  }

  @override
  String get cloudDeleteOriginals => 'Orijinalleri sil';

  @override
  String get cloudOriginalNotDeleted => 'Orijinal silinmedi';

  @override
  String get cloudRetry => 'Tekrar dene';

  @override
  String get tutorialStepTrash => 'Atmak için sola kaydır';

  @override
  String get tutorialStepKeep => 'Saklamak için sağa kaydır';

  @override
  String get tutorialStepUndo => 'Hata mı yaptın? Geri al\'a dokun';

  @override
  String get tutorialSkip => 'Atla';

  @override
  String get tutorialNext => 'İleri';

  @override
  String get tutorialDone => 'Bitti';

  @override
  String get tutorialDemoCard => 'Örnek fotoğraf';

  @override
  String get tutorialShowAgain => 'Öğreticiyi tekrar göster';

  @override
  String get hintPresets =>
      'Hazır ayar, kaydırma düzenini ve filtreni kaydeder. Tek dokunuşla geçiş yap.';

  @override
  String get hintActionBar =>
      'Ek işlemler burada. Ayarlar → Kaydırma bölümünden kapatabilirsin.';

  @override
  String get hintDismiss => 'İpucunu kapat';

  @override
  String get cloudBadgeOnCloud =>
      'KFM tarafından yüklendi (son bilinen durum, anlık kontrol değil)';

  @override
  String get cloudBadgeChanged => 'Yüklendikten sonra değişti';

  @override
  String get cloudShowBadge => 'Bulut simgesini göster';

  @override
  String cloudInfoUploaded(String destination, String date) {
    return 'KFM tarafından yüklendi: $destination · $date';
  }

  @override
  String cloudInfoChanged(String destination) {
    return 'Yüklendikten sonra değişti: $destination';
  }

  @override
  String cloudInfoRemoved(String destination) {
    return '$destination (kaldırıldı)';
  }

  @override
  String get cloudFilterRow => 'Bulut';

  @override
  String get cloudFilterAny => 'Tümü';

  @override
  String get cloudFilterOn => 'Bulutta';

  @override
  String get cloudFilterNotOn => 'Bulutta değil';

  @override
  String get cloudSwipeOnCloud => 'Zaten bulutta olan dosyaları kaydır';

  @override
  String get cloudSwipeOnCloudTitle => 'Bulutta';

  @override
  String get backupUndoBlocked =>
      'çöp kutusu penceresi reddedildi, hiçbir şey değişmedi';

  @override
  String fileOpInUse(String name) {
    return '$name başka bir program tarafından kullanılıyor';
  }

  @override
  String get fileOpNoTrash => 'Bu sürücüde Geri Dönüşüm Kutusu yok';

  @override
  String deleteNoRecycleBin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bu $count dosya',
      one: 'Bu dosya',
    );
    return 'Bu sürücüde Geri Dönüşüm Kutusu yok. $_temp0 kalıcı olarak silinsin mi?';
  }

  @override
  String get windowsRootsHint =>
      'KFM bu klasörlerdeki fotoğrafları, videoları ve dosyaları gösterir.';

  @override
  String get windowsRootsNotAvailable => 'Kullanılamıyor';

  @override
  String get windowsRootsAdd => 'Klasör ekle';

  @override
  String get windowsRootsAddConfirm => 'Ekle';

  @override
  String windowsRootsRemove(String folder) {
    return '$folder kaldır';
  }

  @override
  String get windowsRootsReset => 'Varsayılanlara dön';

  @override
  String get shareNotificationOpen => 'KFM\'yi aç';

  @override
  String get shareNotificationQuit => 'Çık';

  @override
  String get shareKeepsRunningTray =>
      'Pencereyi kapattığınızda paylaşım devam eder. Buradan veya sistem tepsisindeki simgeden durdurun.';

  @override
  String get trayNoticeTitle => 'KFM paylaşmaya devam ediyor';

  @override
  String get trayNoticeBody =>
      'KFM bu bilgisayarı paylaşmaya devam ediyor. Sistem tepsisindeki simgeden durdurun.';

  @override
  String get settingsStopSharingOnClose => 'Pencere kapanınca paylaşımı durdur';

  @override
  String get settingsStopSharingOnCloseHint =>
      'Aksi halde KFM sistem tepsisinden paylaşmaya devam eder.';

  @override
  String get sharePublicNetwork => 'Wi-Fi ağınız Ortak olarak ayarlı';

  @override
  String get sharePublicNetworkHint =>
      'Paylaşmak için Özel olarak ayarlayın. Windows Ayarları → Ağ ve internet → Wi-Fi → ağınız → Özel ağ.';

  @override
  String get shareFirewallTitle => 'Windows güvenlik duvarını soracak';

  @override
  String get shareFirewallBody =>
      'Telefonunuzun bu bilgisayara ulaşabilmesi için Windows Güvenlik Duvarı KFM\'ye izin vermenizi isteyecek. Yalnızca özel ağlarda izin verin.';

  @override
  String get desktopNavSort => 'Ayıkla';

  @override
  String get desktopNavDevices => 'Cihazlar';

  @override
  String get desktopSidebarPlaces => 'Konumlar';

  @override
  String get desktopSidebarCollections => 'Koleksiyonlar';

  @override
  String get desktopFavorites => 'Favoriler';

  @override
  String get desktopSidebarCollapse => 'Kenar çubuğunu daralt';

  @override
  String get desktopSidebarExpand => 'Kenar çubuğunu genişlet';

  @override
  String get desktopNoPlaces => 'Henüz klasör yok';

  @override
  String get desktopDetailsNothing =>
      'Ayrıntılarını görmek için bir dosya seçin';

  @override
  String desktopShortcutHint(String label, String keys) {
    return '$label ($keys)';
  }

  @override
  String desktopStatusItems(int count) {
    return '$count öğe';
  }

  @override
  String desktopStatusSelected(int count, String size) {
    return '$count seçili · $size';
  }

  @override
  String get desktopSortHistory => 'Geçmiş';

  @override
  String get desktopSortHistoryEmpty => 'Henüz bir şey ayıklanmadı';

  @override
  String get desktopSortUndoToHere => 'Buraya kadar geri al';

  @override
  String desktopSortUndoManyTitle(int count) {
    return '$count işlem geri alınsın mı?';
  }

  @override
  String desktopSortUndoManyBody(int count) {
    return 'En yeni $count işlem, tıkladığınıza kadar tek tek geri alınır.';
  }

  @override
  String desktopSortUndoManyConfirm(int count) {
    return '$count geri al';
  }

  @override
  String get desktopSortSelectHint =>
      'Dosyaları seçin, sonra ne yapılacağını seçin';

  @override
  String desktopSortActed(String label, int count) {
    return '$label · $count dosya';
  }

  @override
  String get desktopLayoutLargeIcons => 'Büyük simgeler';

  @override
  String get desktopLayoutGrid => 'Izgara';

  @override
  String get desktopLayoutDetails => 'Ayrıntılar';

  @override
  String get desktopQuickLook => 'Hızlı bakış';

  @override
  String get desktopClose => 'Kapat';

  @override
  String get desktopPrevious => 'Önceki';

  @override
  String get desktopNext => 'Sonraki';

  @override
  String desktopTypeFile(String ext) {
    return '$ext dosyası';
  }

  @override
  String get desktopTypeUnknown => 'Dosya';

  @override
  String get desktopTypeFolder => 'Klasör';

  @override
  String desktopQuickLookTitle(String name, String size, String date) {
    return '$name · $size · $date';
  }

  @override
  String desktopSortLeft(int count) {
    return '$count kaldı';
  }

  @override
  String get desktopBrowseBack => 'Geri';

  @override
  String get desktopBrowseForward => 'İleri';

  @override
  String get desktopBrowseUp => 'Bir üst düzey';

  @override
  String get desktopBrowseOpen => 'Aç';

  @override
  String get desktopBrowseEmptyFolder => 'Bu klasör boş';

  @override
  String get desktopBrowseSortThese => 'Bunları ayıkla';

  @override
  String get desktopBrowseCopy => 'Kopyala';

  @override
  String get desktopBrowseCut => 'Kes';

  @override
  String get desktopBrowsePaste => 'Yapıştır';

  @override
  String get desktopBrowseNothingIndexed => 'KFM burada henüz dosya bulmadı';

  @override
  String desktopDragCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya',
      one: '1 dosya',
    );
    return '$_temp0';
  }

  @override
  String desktopDropMoveTo(String name) {
    return '$name konumuna taşı';
  }

  @override
  String desktopDropCopyTo(String name) {
    return '$name konumuna kopyala';
  }

  @override
  String desktopDropTag(String name) {
    return '$name etiketini ekle';
  }

  @override
  String get desktopDropFavorite => 'Favorilere ekle';

  @override
  String get desktopDropSend => 'Bir cihaza gönder';

  @override
  String get desktopDropTrash => 'Çöpe taşı';

  @override
  String get desktopDropCtrlHint => 'Kopyalamak için Ctrl tuşunu basılı tutun';

  @override
  String get desktopDropNothing => 'Buraya kopyalanacak bir şey yok';

  @override
  String desktopDragOffer(String files, String action) {
    return '$files · $action';
  }

  @override
  String desktopTrashAll(int count) {
    return 'Tümü ($count)';
  }

  @override
  String desktopTrashGroup(String name, String summary) {
    return '$name · $summary';
  }

  @override
  String get desktopTrashRecycleBin => 'Geri Dönüşüm Kutusu';

  @override
  String get desktopTrashOriginalLocation => 'Özgün konum';

  @override
  String get desktopTrashDeleted => 'Silinme tarihi';

  @override
  String get desktopTrashDaysLeft => 'Saklama süresi';

  @override
  String get desktopTrashWhere => 'Nerede';

  @override
  String get desktopRefresh => 'Yenile';

  @override
  String get desktopDevicesTitle => 'Bir telefon veya başka bir PC bağlayın';

  @override
  String get desktopDevicesHint =>
      'İki cihazda da KFM ve aynı Wi-Fi gerekir. Aşağıdan seçene kadar hiçbir şey paylaşılmaz.';

  @override
  String get desktopDevicesShareHint =>
      'Telefonunuz için bir QR kod ve kod gösterin';

  @override
  String get desktopDevicesConnectHint => 'Kod gösteren bir cihaza bağlanın';

  @override
  String get desktopCompare => 'Karşılaştır';

  @override
  String desktopCompareTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotoğrafı',
      one: '1 fotoğrafı',
    );
    return '$_temp0 karşılaştır';
  }

  @override
  String get desktopCompareHint =>
      'Rakam tuşları Sakla / Kaldır arasında geçiş yapar · yakınlaştırma ve kaydırma tüm fotoğraflara birlikte uygulanır';

  @override
  String desktopCompareRemove(int count) {
    return '$count tanesini kaldır';
  }

  @override
  String get desktopCompareKeep => 'Sakla';

  @override
  String get desktopCompareRemoveOne => 'Kaldır';

  @override
  String desktopCompareFacts(String size, String resolution, String date) {
    return '$size · $resolution · $date';
  }

  @override
  String get desktopZoomIn => 'Yakınlaştır';

  @override
  String get desktopZoomOut => 'Uzaklaştır';

  @override
  String get desktopZoomFit => 'Sığdır';

  @override
  String get desktopSortFavorite => 'Favori';

  @override
  String get desktopSortTag => 'Etiket…';

  @override
  String get backupSettingDesktopBrowseLayout => 'PC\'de Gözat görünümü';

  @override
  String get backupSettingDesktopBrowseSort => 'PC\'de Gözat sıralaması';

  @override
  String ejectWindowsInUse(String label) {
    return '$label hâlâ başka bir program tarafından kullanılıyor. Programı kapatıp tekrar deneyin.';
  }

  @override
  String ejectWindowsFailed(String label) {
    return 'Windows $label sürücüsünü çıkaramadı';
  }

  @override
  String desktopSystemDrive(String drive) {
    return 'Yerel disk ($drive)';
  }

  @override
  String driveUsbUnnamed(String drive) {
    return 'USB bellek ($drive)';
  }

  @override
  String driveSdUnnamed(String drive) {
    return 'SD kart ($drive)';
  }

  @override
  String driveRemovableUnnamed(String drive) {
    return 'Çıkarılabilir disk ($drive)';
  }

  @override
  String driveNetworkUnnamed(String drive) {
    return 'Ağ sürücüsü ($drive)';
  }

  @override
  String desktopSortPreset(String name) {
    return 'Hazır ayar: $name';
  }

  @override
  String get desktopSortManagePresets => 'Hazır ayarları yönet…';

  @override
  String get desktopSortSetup => 'Sıralama ayarları…';

  @override
  String get videoPlay => 'Oynat';

  @override
  String get videoPause => 'Duraklat';

  @override
  String get videoSoundOn => 'Sesi aç';

  @override
  String get videoSoundOff => 'Sesi kapat';

  @override
  String desktopDragItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count öğe',
      one: '1 öğe',
    );
    return '$_temp0';
  }

  @override
  String opTreeMoved(int folders, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders klasör taşındı',
      one: '1 klasör taşındı',
      zero: 'Taşındı',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files dosya',
      one: '1 dosya',
    );
    return '$_temp0 ($_temp1)';
  }

  @override
  String opTreeCopied(int folders, int files) {
    String _temp0 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders klasör kopyalandı',
      one: '1 klasör kopyalandı',
      zero: 'Kopyalandı',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files dosya',
      one: '1 dosya',
    );
    return '$_temp0 ($_temp1)';
  }

  @override
  String get opFolderIntoItself => 'Bir klasör kendi içine taşınamaz';

  @override
  String get jobsChannelProgress => 'Süren aktarımlar';

  @override
  String get jobsChannelProgressDescription =>
      'KFM arka plandayken kopyalama ve aktarımların ilerlemesi';

  @override
  String get jobsChannelResults => 'Biten aktarımlar';

  @override
  String get jobsChannelResultsDescription =>
      'Bir kopyalama veya aktarım bittiğinde gösterilir';

  @override
  String jobsReceivingFrom(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$device cihazından $count dosya alınıyor',
      one: '$device cihazından 1 dosya alınıyor',
    );
    return '$_temp0';
  }

  @override
  String jobsCombinedTitle(int count, String percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktarım · $percent',
      one: '1 aktarım · $percent',
    );
    return '$_temp0';
  }

  @override
  String jobsProgressLine(String done, String total) {
    return '$done / $total';
  }

  @override
  String jobsSpeedLine(String speed) {
    return '$speed/sn';
  }

  @override
  String jobsTimeLeft(String time) {
    return '$time kaldı';
  }

  @override
  String jobsMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dk',
      one: '1 dk',
    );
    return '$_temp0';
  }

  @override
  String jobsHoursMinutes(int hours, int minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String jobsSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sn',
      one: '1 sn',
    );
    return '$_temp0';
  }

  @override
  String jobsPausedOne(String title) {
    return 'Duraklatıldı · $title';
  }

  @override
  String jobsPausedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktarım duraklatıldı',
      one: '1 aktarım duraklatıldı',
    );
    return '$_temp0';
  }

  @override
  String get jobsPausedOpenKfm => 'Duraklatıldı, devam etmek için KFM\'yi açın';

  @override
  String get jobsWaiting => 'Bekliyor';

  @override
  String jobsEndSent(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$device cihazına $count dosya gönderildi',
      one: '$device cihazına 1 dosya gönderildi',
    );
    return '$_temp0';
  }

  @override
  String jobsEndReceived(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$device cihazından $count dosya alındı',
      one: '$device cihazından 1 dosya alındı',
    );
    return '$_temp0';
  }

  @override
  String jobsEndMovedTo(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$device cihazına $count dosya taşındı',
      one: '$device cihazına 1 dosya taşındı',
    );
    return '$_temp0';
  }

  @override
  String jobsEndMovedFrom(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$device cihazından $count dosya taşındı',
      one: '$device cihazından 1 dosya taşındı',
    );
    return '$_temp0';
  }

  @override
  String jobsEndCopied(int count, String place) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$place konumuna $count dosya kopyalandı',
      one: '$place konumuna 1 dosya kopyalandı',
    );
    return '$_temp0';
  }

  @override
  String jobsEndMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktarım bitti',
      one: '1 aktarım bitti',
    );
    return '$_temp0';
  }

  @override
  String jobsEndFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya başarısız · Görmek için dokunun',
      one: '1 dosya başarısız · Görmek için dokunun',
    );
    return '$_temp0';
  }

  @override
  String get jobsNotificationsOff =>
      'Bildirimler kapalı: aktarımlar devam eder ama ilerleme yalnızca KFM içinde görünür.';

  @override
  String jobsIndicatorLabel(String title, String percent) {
    return '$title, $percent. Aktarımları aç';
  }

  @override
  String get jobsQuitTitle => 'KFM\'den çıkılsın mı?';

  @override
  String jobsQuitBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count aktarım hâlâ sürüyor. Çıkmak onları durdurur; bir dahaki sefere Aktarımlar bölümünden devam edebilirsiniz.',
      one: '1 aktarım hâlâ sürüyor. Çıkmak onu durdurur; bir dahaki sefere Aktarımlar bölümünden devam edebilirsiniz.',
    );
    return '$_temp0';
  }

  @override
  String get jobsQuitAction => 'Çık';

  @override
  String get jobsQuitKeep => 'Çalışmaya devam et';

  @override
  String get trayNoticeTransfersTitle => 'KFM aktarmaya devam ediyor';

  @override
  String get trayNoticeTransfersBody =>
      'Aktarımlar arka planda sürer. KFM\'yi sistem tepsisindeki simgeden yeniden açın.';

  @override
  String jobsEndFailedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktarım başarısız',
      one: 'Aktarım başarısız',
    );
    return '$_temp0';
  }

  @override
  String get settingsGeneral => 'Genel';

  @override
  String get settingsSorting => 'Sıralama';

  @override
  String get settingsFilesDisplay => 'Dosyalar ve görünüm';

  @override
  String get settingsSmart => 'Akıllı özellikler';

  @override
  String get settingsStorageCleanup => 'Depolama ve temizlik';

  @override
  String get settingsConnectSharing => 'Bağlanma ve paylaşma';

  @override
  String get settingsPrivacyAccess => 'Gizlilik ve erişim';

  @override
  String get settingsAboutAdvanced => 'Hakkında ve gelişmiş';

  @override
  String get thumbCacheHelp =>
      'KFM\'nin klasörler hızlı açılsın diye kaydettiği küçük önizlemeler. Temizle yeri boşaltır; dosyalarına dokunulmaz ve önizlemeler gerektiğinde geri gelir.';

  @override
  String get errorLogHelp =>
      'KFM\'nin karşılaştığı hatalar; dosya adları ve yollar olmadan. Bir sorunu bildirmek için paylaş.';

  @override
  String get devSettingsHelp =>
      'KFM\'yi bir cihazda denetlemek için dizin araçları (yalnızca hata ayıklama sürümleri).';

  @override
  String get settingsShowSessionSummaryHelp =>
      'Bitti\'den sonra neyi tuttuğunun, sildiğinin ve taşıdığının kısa bir özeti.';

  @override
  String get reviewedResetHelp =>
      'Daha önce sıraladığın dosyalar yeniden yeni olarak görünür. Hiçbir şey silinmez.';

  @override
  String get settingsFreshStartHelp =>
      'Neyin temizleneceğini seç: geçerli oturum, geçmiş, etiketler veya hepsi.';

  @override
  String get tutorialShowAgainHelp =>
      'Kısa kaydırma öğreticisi ve tek seferlik ipuçları bir kez daha.';

  @override
  String get settingsDropActionHelp =>
      'Dosyaları bir klasörün üstüne sürüklediğinde ne olacağı.';

  @override
  String get storageBigFileThresholdHelp =>
      'Büyük dosya vurgusu ve Depolama → Büyük dosyalar bunu kullanır.';

  @override
  String get settingsDeleteMode => 'Silerken';

  @override
  String get settingsDeleteModeHelp =>
      'Silinen dosyaları çöp kutusuna taşı ya da kalıcı olarak sil.';

  @override
  String get settingsPermissionsHelp =>
      'KFM\'nin bu telefonda neleri okuyabileceği ve bunu değiştirme düğmesi.';

  @override
  String get backupRestoreTitle => 'Yedekle ve geri yükle';

  @override
  String get backupRestoreHelp =>
      'Etiketlerini, favorilerini, ön ayarlarını ve ayarlarını başka bir cihaza taşır. Dosyalar kopyalanmaz.';

  @override
  String get cloudDestinationsHelp =>
      'KFM\'nin dosya gönderebileceği, bu cihazdaki bulut uygulamaları.';

  @override
  String get connectADevice => 'Bir cihaz bağla';

  @override
  String get connectADeviceHelp =>
      'Telefonun ile bilgisayarın arasında Wi-Fi üzerinden dosyaları gör ve gönder.';

  @override
  String get transfersSettingHelp => 'Süren ve biten tüm Wi-Fi aktarımları.';

  @override
  String get privacyDevicesTitle => 'Dosyalarını görebilen cihazlar';

  @override
  String get privacyDevicesHelp =>
      'Hatırlanan cihazlar ve neler yapabilecekleri. Engellemek için birini unut.';

  @override
  String get privacyNeverTitle => 'KFM\'nin asla yapmadıkları';

  @override
  String get privacyNeverBody =>
      'Reklam yok, hesap yok, izleme yok. KFM dosyalarını asla yüklemez: onları yalnızca bağladığın cihazlar ve seçtiğin bulut uygulamaları alır.';

  @override
  String get a11yScreenReaderTitle => 'Ekran okuyucular';

  @override
  String get a11yScreenReaderBody =>
      'Dosya kutucukları adlarını, türlerini, boyutlarını ve tarihlerini okur. Kaydırma kartları eylemlerini eylemler menüsünde sunar.';

  @override
  String get settingsKeywordsTheme => 'koyu,açık,gece,mod,görünüm';

  @override
  String get settingsKeywordsAccent => 'renk,vurgu';

  @override
  String get settingsKeywordsTextSize =>
      'yazı tipi,büyük yazı,yakınlaştır,daha büyük';

  @override
  String get settingsKeywordsThumbCache => 'önbellek,önizleme,alan,boşalt';

  @override
  String get settingsKeywordsVersion => 'sürüm,hakkında,uygulama';

  @override
  String get settingsKeywordsPermissions => 'izin,erişim,izin ver,depolama';

  @override
  String get settingsKeywordsSimilar => 'kopya,bulanık,benzer';

  @override
  String get settingsKeywordsAiLabels => 'yapay zeka,etiket,tanıma,model,indir';

  @override
  String get settingsKeywordsLocation => 'konum,gps,yer,exif';

  @override
  String get settingsKeywordsBackup => 'dışa aktar,içe aktar,geri yükle,yedek';

  @override
  String get settingsKeywordsCloud => 'bulut,drive,onedrive,yükle';

  @override
  String get settingsKeywordsConnect =>
      'paylaş,wifi,bilgisayar,telefon,qr,gönder';

  @override
  String get settingsKeywordsPrivacy => 'gizlilik,izleme,reklam,yükleme';

  @override
  String get settingsKeywordsScreenReader =>
      'talkback,ekran okuyucu,anlatıcı,görme engelli';

  @override
  String get settingsKeywordsBigFiles => 'büyük,boyut,sınır,eşik';

  @override
  String get settingsSearchHint => 'Ayarlarda ara';

  @override
  String get settingsSearchClear => 'Aramayı temizle';

  @override
  String get settingsSearchEmpty => 'Eşleşen ayar yok. Başka bir kelime dene.';

  @override
  String get privacyTransferNote =>
      'Konum bilgisi kaldırılır (Ayarlar → Gizlilik ve erişim)';

  @override
  String durationShortSeconds(int count) {
    return '$count sn';
  }

  @override
  String durationShortMinutes(int count) {
    return '$count dk';
  }

  @override
  String durationShortMinutesSeconds(int minutes, int seconds) {
    return '$minutes dk $seconds sn';
  }

  @override
  String durationShortHours(int count) {
    return '$count sa';
  }

  @override
  String durationShortHoursMinutes(int hours, int minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String get unitSecondsShort => 'sn';

  @override
  String get unitMinutesShort => 'dk';

  @override
  String get unitHoursShort => 'sa';

  @override
  String get unitMegabytesShort => 'MB';

  @override
  String get unitGigabytesShort => 'GB';

  @override
  String get unitInputAmount => 'Miktar';

  @override
  String unitInputRange(String min, String max) {
    return '$min ile $max arasında bir değer gir';
  }

  @override
  String get unitInputSave => 'Kaydet';

  @override
  String bigFileThresholdLine(String size) {
    return '$size ve üzeri dosyalar büyük sayılır';
  }

  @override
  String get settingsHighlightBigLine =>
      'Büyük dosyalar, boyutlar kapalı olsa bile kırmızı boyut etiketi alır';

  @override
  String get settingsSameTimeWindowAbout =>
      'Göz at → Aynı an, bu kadar kısa arayla çekilen fotoğraf ve videoları gruplar';

  @override
  String sameTimeWindowLine(String time) {
    return 'Birbirinden en fazla $time arayla çekilen fotoğraf ve videolar gruplanır';
  }

  @override
  String get deleteModeTrashHelpDevice =>
      'Silinen dosyalar çöp kutusuna gider ve geri yüklenebilir.';

  @override
  String similarStartBodyOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'KFM bu telefondaki fotoğraflarını kontrol eder, benzerlerini gruplar ve saklaman için en net olanı önerir. Hiçbir şey telefondan çıkmaz ve sen seçmedikçe hiçbir şey kaldırılmaz.',
      'pc': 'KFM bu bilgisayardaki fotoğraflarını kontrol eder, benzerlerini gruplar ve saklaman için en net olanı önerir. Hiçbir şey bilgisayardan çıkmaz ve sen seçmedikçe hiçbir şey kaldırılmaz.',
      'other': 'KFM bu cihazdaki fotoğraflarını kontrol eder, benzerlerini gruplar ve saklaman için en net olanı önerir. Hiçbir şey cihazdan çıkmaz ve sen seçmedikçe hiçbir şey kaldırılmaz.',
    });
    return '$_temp0';
  }

  @override
  String aiLabelsEnableOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'Fotoğrafları bu telefonda otomatik etiketle',
      'pc': 'Fotoğrafları bu bilgisayarda otomatik etiketle',
      'other': 'Fotoğrafları bu cihazda otomatik etiketle',
    });
    return '$_temp0';
  }

  @override
  String aiLabelsHelpOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'Yalnızca bu telefonda çalışır. Hiçbir fotoğraf veya sonuç telefondan çıkmaz.',
      'pc': 'Yalnızca bu bilgisayarda çalışır. Hiçbir fotoğraf veya sonuç bilgisayardan çıkmaz.',
      'other': 'Yalnızca bu cihazda çalışır. Hiçbir fotoğraf veya sonuç cihazdan çıkmaz.',
    });
    return '$_temp0';
  }

  @override
  String aiLabelsWorkerErrorOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'Otomatik etiketleme bu telefonda başlatılamadı.',
      'pc': 'Otomatik etiketleme bu bilgisayarda başlatılamadı.',
      'other': 'Otomatik etiketleme bu cihazda başlatılamadı.',
    });
    return '$_temp0';
  }

  @override
  String aiLabelsCardBodyOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'KFM fotoğraflarını bu telefonda otomatik etiketleyebilir. Hiçbir şey yüklenmez.',
      'pc': 'KFM fotoğraflarını bu bilgisayarda otomatik etiketleyebilir. Hiçbir şey yüklenmez.',
      'other': 'KFM fotoğraflarını bu cihazda otomatik etiketleyebilir. Hiçbir şey yüklenmez.',
    });
    return '$_temp0';
  }

  @override
  String aiModelsHowBodyOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'Her fotoğrafın küçük resmi bu telefonda, arka planda, bir kez analiz edilir. KFM\'nin veritabanında yalnızca \"kedi\" gibi etiket sözcükleri saklanır.',
      'pc': 'Her fotoğrafın küçük resmi bu bilgisayarda, arka planda, bir kez analiz edilir. KFM\'nin veritabanında yalnızca \"kedi\" gibi etiket sözcükleri saklanır.',
      'other': 'Her fotoğrafın küçük resmi bu cihazda, arka planda, bir kez analiz edilir. KFM\'nin veritabanında yalnızca \"kedi\" gibi etiket sözcükleri saklanır.',
    });
    return '$_temp0';
  }

  @override
  String aiModelsPrivacyBodyOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'Tamamen bu telefonda çalışır. Hiçbir fotoğraf, küçük resim veya sonuç telefondan çıkmaz. Hesap yok, izleme yok. Ağ yalnızca bu tek indirme için kullanılır.',
      'pc': 'Tamamen bu bilgisayarda çalışır. Hiçbir fotoğraf, küçük resim veya sonuç bilgisayardan çıkmaz. Hesap yok, izleme yok. Ağ yalnızca bu tek indirme için kullanılır.',
      'other': 'Tamamen bu cihazda çalışır. Hiçbir fotoğraf, küçük resim veya sonuç cihazdan çıkmaz. Hesap yok, izleme yok. Ağ yalnızca bu tek indirme için kullanılır.',
    });
    return '$_temp0';
  }

  @override
  String detailsAddedOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'Telefona eklenme',
      'pc': 'Bilgisayara eklenme',
      'other': 'Cihaza eklenme',
    });
    return '$_temp0';
  }

  @override
  String errorLogShareSubtitleOn(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hata',
      one: '1 hata',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hata',
      one: '1 hata',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hata',
      one: '1 hata',
    );
    String _temp3 = intl.Intl.selectLogic(device, {
      'phone':
          '$_temp0. Sen paylaşana kadar bu telefonda kalır. Klasör ve dosya adları gizlenir.',
      'pc':
          '$_temp1. Sen paylaşana kadar bu bilgisayarda kalır. Klasör ve dosya adları gizlenir.',
      'other':
          '$_temp2. Sen paylaşana kadar bu cihazda kalır. Klasör ve dosya adları gizlenir.',
    });
    return '$_temp3';
  }

  @override
  String transfersLocalSectionOn(String device) {
    String _temp0 = intl.Intl.selectLogic(device, {
      'phone': 'Bu telefonda',
      'pc': 'Bu bilgisayarda',
      'other': 'Bu cihazda',
    });
    return '$_temp0';
  }

  @override
  String get cloudBadgeHelpDevice =>
      'Bulut simgesi, KFM\'nin bu dosyayı bulut uygulamana verdiği anlamına gelir. KFM bunu burada hatırlar, bu yüzden çevrimdışıyken de görünür. Anlık bir kontrol değildir: KFM yüklemenin bitip bitmediğini veya kopyanın sonradan silinip silinmediğini göremez. Dosya yüklemeden sonra değişirse simge de değişir. Yalnızca KFM ile yüklenen dosyalar işaretlenir.';

  @override
  String get aiLabelsUnsupportedWindows =>
      'Windows\'ta henüz kullanılamıyor. Android\'de KFM fotoğrafları içlerindekilere göre bulabilir.';

  @override
  String get aiModelsDownloadInline => 'İndir';

  @override
  String get aiModelsHowItWorks => 'Nasıl çalışır';

  @override
  String get whereKfmLooksTitle => 'KFM\'nin baktığı yerler';

  @override
  String get whereKfmLooksHelp =>
      'Arama, Sıralama ve Depolama\'nın kullandığı, dosyalarının özel listesi. Bu cihazdan asla çıkmaz.';

  @override
  String get whereKfmLooksPhoneBody =>
      'KFM, Android\'in ona gösterdiği fotoğrafların, videoların ve dosyaların özel bir listesini tutar; böylece Arama, Kaydırma ve Depolama tüm telefonunu kapsar. Liste bu telefonda kalır ve asla yüklenmez. KFM bakarak hiçbir şeyi değiştirmez veya taşımaz.';

  @override
  String get lookEverywhereTitle => 'Her yere bak';

  @override
  String get lookEverywhereOnHelp =>
      'KFM bu bilgisayardaki fotoğraflarının, videolarının ve dosyalarının özel bir listesini tutar; böylece Arama, Sıralama, Depolama ve Benzer fotoğraflar her şeyi kapsar. Liste bu bilgisayarda kalır. KFM bakarak hiçbir şeyi yüklemez, değiştirmez veya taşımaz; Windows ve program klasörlerini atlar.';

  @override
  String get lookEverywhereOffHelp =>
      'KFM yalnızca açık olan klasöre bakar. Arama ve Sıralama o klasörü kapsar.';

  @override
  String get lookEverywhereChosenHelp =>
      'KFM yalnızca aşağıdaki klasörlere bakar. Tüm dosyalarını kapsamak için bunu aç.';

  @override
  String get lookEverywhereChoose => 'Bunun yerine klasör seç…';

  @override
  String get lookEverywhereOffConfirmTitle =>
      'Yalnızca bulunduğun yere mi bakılsın?';

  @override
  String get lookEverywhereOffConfirmBody =>
      'Arama ve Sıralama yalnızca açtığın klasörleri kapsar. Etiketler, favoriler ve incelendi işaretleri korunur.';

  @override
  String get lookEverywhereOffConfirm => 'Yalnızca açık klasörler';

  @override
  String get settingsKeywordsIndex => 'dizin,tara,klasörler,her yere bak,ara';

  @override
  String get languageStepTitle => 'Dilini seç';

  @override
  String get languageStepBody =>
      'Bunu daha sonra Ayarlar → Genel\'den değiştirebilirsin.';

  @override
  String languageSystemNamed(String language) {
    return 'Sistem ($language)';
  }

  @override
  String get languageStepContinue => 'Devam';

  @override
  String get leftHandedThumbHelp =>
      'Geri al\'ı, ana düğmeleri ve seçim çubuğunu başparmağının olduğu sola koyar. Kaydırma yönleri değişmez.';

  @override
  String get reduceMotionTitle => 'Hareketi azalt';

  @override
  String get reduceMotionHelp =>
      'Kaydırılan kartlar uçup gitmek yerine kaybolur, ekranlar kaymadan değişir. Sistem ayarını da izler.';

  @override
  String get highContrastTitle => 'Yüksek karşıtlık';

  @override
  String get highContrastHelp =>
      'Metin, düğme ve kenarlıklar için daha güçlü renkler. Sistem ayarını da izler.';

  @override
  String get backupSettingReduceMotion => 'Hareketi azalt';

  @override
  String get backupSettingHighContrast => 'Yüksek karşıtlık';

  @override
  String get settingsKeywordsMotion => 'animasyon,hareket,solma';

  @override
  String get settingsKeywordsContrast => 'karşıtlık,kontrast,renkler,az gören';

  @override
  String a11yFileLabel(String name, String kind, String size, String date) {
    return '$name, $kind, $size, $date';
  }

  @override
  String get a11yKindAudio => 'Ses';

  @override
  String get a11yKindDocument => 'Belge';

  @override
  String a11yKindDocumentExt(String ext) {
    return '$ext belgesi';
  }

  @override
  String get a11yKindArchive => 'Arşiv';

  @override
  String get a11yKindFile => 'Dosya';

  @override
  String a11yKindFileExt(String ext) {
    return '$ext dosyası';
  }
}
