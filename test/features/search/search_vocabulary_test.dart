import 'dart:ui' show Locale;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/search/data/builtin_keywords.dart';
import 'package:kfm/features/search/data/search_vocabulary.dart';
import 'package:kfm/features/search/domain/search_keyword.dart';
import 'package:kfm/features/search/domain/search_parser.dart';

import 'fixture_bundle.dart';

const List<SearchKeywordFamily> _families = [
  typeKeywords,
  sourceKeywords,
  attributeKeywords,
];

/// Every fixture language bundled (plus the real English file).
FixtureTermsBundle _bundle() => FixtureTermsBundle.langs({
  'en': 'assets/search/terms_en.json',
  'xx': fixture('xx'),
  'yy': fixture('yy'),
  'zz': fixture('zz'),
});

Map<String, String> _ids(SearchVocabulary v) => {
  for (final MapEntry(:key, :value) in v.phrases.entries) key: value.id,
};

void main() {
  group('loadSearchVocabulary (fixture term files)', () {
    test('main xx + secondary yy: words of both, nothing else', () async {
      final bundle = _bundle();
      final v = await loadSearchVocabulary(
        bundle,
        main: 'xx',
        secondary: 'yy',
        families: _families,
      );
      expect(v.loadErrors, isEmpty);
      expect(_ids(v), {
        'vidxx': 'type:video',
        'kopek': 'attr:hidden',
        'screen grab': 'source:screenshots',
        'docyy': 'type:document',
        // Main beats secondary on a conflict.
        'both': 'type:video',
        // Keys are normalized at load.
        'kopekyy': 'attr:tiny',
      });
      // Only the two chosen files were read (not zz, not en).
      expect(bundle.loaded, [
        'assets/search/terms_xx.json',
        'assets/search/terms_yy.json',
      ]);
    });

    test('a word only in zz or only in English is a name search', () async {
      final v = await loadSearchVocabulary(
        _bundle(),
        main: 'xx',
        secondary: 'yy',
        families: _families,
      );
      final tokens = parseSearch('onlyzz video vidxx docyy Köpek', v);
      expect(tokens.map((t) => t.runtimeType), [
        NameToken,
        NameToken,
        KeywordToken,
        KeywordToken,
        KeywordToken,
      ]);
    });

    test('clearing the secondary turns yy words into names', () async {
      final v = await loadSearchVocabulary(
        _bundle(),
        main: 'xx',
        secondary: '',
        families: _families,
      );
      expect(parseSearch('docyy', v).single, isA<NameToken>());
      expect(_ids(v)['both'], 'type:video');
    });

    test('secondary wins where main has no entry; main = secondary is '
        'loaded once', () async {
      final v = await loadSearchVocabulary(
        _bundle(),
        main: 'yy',
        secondary: 'xx',
        families: _families,
      );
      expect(_ids(v)['both'], 'type:audio');
      expect(_ids(v)['vidxx'], 'type:video');
      final bundle = _bundle();
      await loadSearchVocabulary(
        bundle,
        main: 'yy',
        secondary: 'yy',
        families: _families,
      );
      expect(bundle.loaded, ['assets/search/terms_yy.json']);
    });

    test('unregistered family ids are ignored', () async {
      final v = await loadSearchVocabulary(
        _bundle(),
        main: 'xx',
        secondary: '',
        families: _families,
      );
      expect(v.phrases.containsKey('futurexx'), isFalse);
    });

    test('main without a term file falls back to English, no error', () async {
      final bundle = _bundle();
      final v = await loadSearchVocabulary(
        bundle,
        main: 'nl',
        secondary: '',
        families: _families,
      );
      expect(v.loadErrors, isEmpty);
      expect(_ids(v)['video'], 'type:video');
      expect(bundle.loaded, ['assets/search/terms_en.json']);
    });

    test('a corrupt secondary is reported; main still works', () async {
      final bundle = FixtureTermsBundle.langs({
        'xx': fixture('xx'),
        'yy': '$fixtureDir/terms_broken.json',
      });
      final v = await loadSearchVocabulary(
        bundle,
        main: 'xx',
        secondary: 'yy',
        families: _families,
      );
      expect(v.loadErrors, ['yy']);
      expect(_ids(v)['vidxx'], 'type:video');
    });

    test('a missing secondary is reported', () async {
      final v = await loadSearchVocabulary(
        _bundle(),
        main: 'xx',
        secondary: 'qq',
        families: _families,
      );
      expect(v.loadErrors, ['qq']);
    });

    test('a corrupt main is reported and English is used', () async {
      final v = await loadSearchVocabulary(
        FixtureTermsBundle.langs({
          'en': 'assets/search/terms_en.json',
          'xx': '$fixtureDir/terms_broken.json',
        }),
        main: 'xx',
        secondary: '',
        families: _families,
      );
      expect(v.loadErrors, ['xx']);
      expect(_ids(v)['video'], 'type:video');
    });
  });

  test('parseTermsFile rejects bad shapes', () {
    expect(() => parseTermsFile('[]'), throwsFormatException);
    expect(() => parseTermsFile('{"lang":"en"}'), throwsFormatException);
    expect(
      () => parseTermsFile('{"keywords": {"a": 1}}'),
      throwsFormatException,
    );
    expect(() => parseTermsFile('{'), throwsFormatException);
    expect(parseTermsFile('{"keywords": {"a": "type:video"}}'), {
      'a': 'type:video',
    });
  });

  test('effectiveSearchLanguage: setting, then system, then English', () {
    expect(
      effectiveSearchLanguage(const Locale('en'), const Locale('de')),
      'en',
    );
    expect(effectiveSearchLanguage(null, const Locale('en', 'GB')), 'en');
    // Unsupported app languages fall back to English (until L2).
    expect(effectiveSearchLanguage(null, const Locale('de')), 'en');
    expect(
      effectiveSearchLanguage(const Locale('xx'), const Locale('en')),
      'en',
    );
  });

  group('providers', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          searchAssetBundleProvider.overrideWithValue(_bundle()),
          searchMainLanguageProvider.overrideWith((ref) async => 'xx'),
        ],
      );
    });
    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<SearchVocabulary> settle(
      bool Function(SearchVocabulary v) done,
    ) async {
      for (var i = 0; i < 100; i++) {
        final v = await container.read(searchVocabularyProvider.future);
        if (done(v)) return v;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail('vocabulary never settled');
    }

    test('secondary language setting switches the loaded words', () async {
      final sub = container.listen(searchVocabularyProvider, (_, _) {});
      addTearDown(sub.close);
      var v = await settle((v) => v.phrases.containsKey('vidxx'));
      expect(v.phrases.containsKey('docyy'), isFalse);

      final settings = container.read(settingsRepositoryProvider);
      await settings.write(AppSettings.searchSecondaryLanguage, 'yy');
      v = await settle((v) => v.phrases.containsKey('docyy'));
      expect(v.phrases['both']?.id, 'type:video');

      await settings.write(AppSettings.searchSecondaryLanguage, '');
      v = await settle((v) => !v.phrases.containsKey('docyy'));
      expect(v.phrases.containsKey('vidxx'), isTrue);
    });

    test('availableSearchLanguages lists the bundled term files', () async {
      final sub = container.listen(availableSearchLanguagesProvider, (_, _) {});
      addTearDown(sub.close);
      expect(await container.read(availableSearchLanguagesProvider.future), [
        'en',
        'xx',
        'yy',
        'zz',
      ]);
    });
  });
}
