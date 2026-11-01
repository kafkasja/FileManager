import 'dart:convert';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/services.dart';
import 'package:kfm/app/theme/theme_providers.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/search/data/search_keywords.dart';
import 'package:kfm/features/search/domain/normalize.dart';
import 'package:kfm/features/search/domain/search_keyword.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_vocabulary.g.dart';

/// Language of the fallback term file (the app's fallback UI language).
const String kFallbackSearchLanguage = 'en';

/// `assets/search/terms_<lang>.json`.
String searchTermsAsset(String lang) => 'assets/search/terms_$lang.json';

final _termsAsset = RegExp(
  r'^assets/search/terms_([a-z]{2,3}(?:-[A-Za-z0-9]+)?)\.json$',
);

/// Where term files are read from (tests override it with fixture files).
@Riverpod(keepAlive: true)
AssetBundle searchAssetBundle(Ref ref) => rootBundle;

/// The effective app language for search: [appLocale] (the setting) or the
/// [system] locale, reduced to a supported app language; English otherwise.
String effectiveSearchLanguage(Locale? appLocale, Locale system) {
  final code = (appLocale ?? system).languageCode.toLowerCase();
  final supported = {
    for (final l in AppLocalizations.supportedLocales) l.languageCode,
  };
  return supported.contains(code) ? code : kFallbackSearchLanguage;
}

/// The main search language: the effective app language.
@riverpod
Future<String> searchMainLanguage(Ref ref) async {
  final locale = await ref.watch(appLocaleProvider.future);
  return effectiveSearchLanguage(locale, PlatformDispatcher.instance.locale);
}

/// The secondary search language tag; '' = none.
@riverpod
Stream<String> searchSecondaryLanguage(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.searchSecondaryLanguage);

/// Languages that have a bundled term file, sorted (from the asset
/// manifest, so L2 adds languages without code changes).
@riverpod
Future<List<String>> availableSearchLanguages(Ref ref) =>
    listSearchLanguages(ref.watch(searchAssetBundleProvider));

Future<List<String>> listSearchLanguages(AssetBundle bundle) async {
  final manifest = await AssetManifest.loadFromAssetBundle(bundle);
  return List.unmodifiable(
    [
      for (final a in manifest.listAssets())
        if (_termsAsset.firstMatch(a) case final m?) m.group(1)!,
    ]..sort(),
  );
}

/// The words of the main and (optional) secondary search language only.
@riverpod
Future<SearchVocabulary> searchVocabulary(Ref ref) async {
  final bundle = ref.watch(searchAssetBundleProvider);
  final families = ref.watch(searchKeywordFamiliesProvider);
  final main = await ref.watch(searchMainLanguageProvider.future);
  final secondary = await ref.watch(searchSecondaryLanguageProvider.future);
  return await loadSearchVocabulary(
    bundle,
    main: main,
    secondary: secondary,
    families: families,
  );
}

/// Loads [main]'s term file (falling back to English when it has none or
/// it fails) and [secondary]'s ('' = none), merged with main first: on the
/// same word, main wins. Ids of unregistered families are ignored. A file
/// that fails to load or parse is skipped and its language listed in
/// [SearchVocabulary.loadErrors] (a missing main file is not an error: it
/// just falls back).
Future<SearchVocabulary> loadSearchVocabulary(
  AssetBundle bundle, {
  required String main,
  required String secondary,
  required List<SearchKeywordFamily> families,
}) async {
  final phrases = <String, SearchKeyword>{};
  final errors = <String>[];

  /// True when the file was loaded.
  Future<bool> add(String lang, {required bool missingIsError}) async {
    final String text;
    try {
      text = await bundle.loadString(searchTermsAsset(lang), cache: false);
    } on Object {
      if (missingIsError) errors.add(lang);
      return false;
    }
    try {
      for (final MapEntry(:key, :value) in parseTermsFile(text).entries) {
        final word = normalizeSearchWord(key);
        if (word.isEmpty || phrases.containsKey(word)) continue;
        if (resolveKeywordId(value, families) case final kw?) {
          phrases[word] = kw;
        }
      }
      return true;
    } on FormatException {
      errors.add(lang);
      return false;
    }
  }

  var loaded = main;
  if (!await add(main, missingIsError: false) &&
      main != kFallbackSearchLanguage) {
    loaded = kFallbackSearchLanguage;
    await add(kFallbackSearchLanguage, missingIsError: true);
  }
  if (secondary.isNotEmpty && secondary != main && secondary != loaded) {
    await add(secondary, missingIsError: true);
  }
  return SearchVocabulary(
    phrases: Map.unmodifiable(phrases),
    loadErrors: List.unmodifiable(errors),
  );
}

/// Word → concept id of one term file. Throws [FormatException] when it
/// isn't `{"keywords": {"<word>": "<prefix>:<arg>", …}}`.
Map<String, String> parseTermsFile(String text) {
  final json = jsonDecode(text);
  if (json is! Map<String, Object?>) {
    throw const FormatException('term file is not an object');
  }
  final keywords = json['keywords'];
  if (keywords is! Map<String, Object?>) {
    throw const FormatException('missing "keywords" object');
  }
  return {
    for (final MapEntry(:key, :value) in keywords.entries)
      key: value is String
          ? value
          : throw FormatException('id of "$key" is not a string'),
  };
}
