import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/features/ai_labels/data/ai_labels_providers.dart';
import 'package:kfm/features/ai_labels/domain/label_map.dart';
import 'package:kfm/features/search/data/builtin_keywords.dart';
import 'package:kfm/features/search/data/label_keywords.dart';
import 'package:kfm/features/search/data/search_keywords.dart';
import 'package:kfm/features/search/data/search_vocabulary.dart';
import 'package:kfm/features/search/domain/normalize.dart';
import 'package:kfm/features/search/domain/search_keyword.dart';
import 'package:kfm/features/search/domain/search_parser.dart';
import 'package:kfm/features/similar/ui/similar_providers.dart';
import 'package:kfm/l10n/generated/app_localizations_en.dart';

import 'fixture_bundle.dart';

/// C3's shipped vocabulary (the real label map).
final Set<String> _vocabulary = LabelMap.parse(
  File(LabelMap.assetPath).readAsStringSync(),
).vocabulary;

final Map<String, Set<String>> _expansions = parseLabelExpansions(
  File(kLabelExpansionsAsset).readAsStringSync(),
);

/// TASK-C4: the `label` keyword family, its English words and expansions.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late SearchKeywordFamily family;
  late List<SearchKeywordFamily> families;

  setUp(() async {
    container = ProviderContainer(
      overrides: [
        labelVocabularyProvider.overrideWithValue(_vocabulary),
        labelExpansionsProvider.overrideWith((ref) async => _expansions),
        similarBlurThresholdProvider.overrideWith((ref) => Stream.value(120)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(labelExpansionsProvider.future);
    // The threshold stream's first value.
    container.listen(similarBlurThresholdProvider, (_, _) {});
    await container.read(similarBlurThresholdProvider.future);
    family = container.read(labelKeywordFamilyProvider);
    families = container.read(searchKeywordFamiliesProvider);
  });

  group('vocabulary checks', () {
    final terms = parseTermsFile(
      File(searchTermsAsset('en')).readAsStringSync(),
    );
    final labelIds = {
      for (final id in terms.values)
        if (id.startsWith('label:')) id.substring('label:'.length),
    };

    test('every label id in terms_en.json is in C3 vocabulary (or blurry)', () {
      expect(labelIds, isNotEmpty);
      for (final id in labelIds) {
        expect(
          id == kBlurryArg || _vocabulary.contains(id),
          isTrue,
          reason: id,
        );
      }
    });

    test('every vocabulary label has at least one English word', () {
      expect(_vocabulary.difference(labelIds), isEmpty);
    });

    test('every expansion id is in C3 vocabulary and expands to itself', () {
      expect(_expansions, isNotEmpty);
      for (final MapEntry(:key, :value) in _expansions.entries) {
        expect(_vocabulary, contains(key));
        expect(value, contains(key));
        for (final l in value) {
          expect(_vocabulary, contains(l), reason: '$key → $l');
        }
      }
    });

    test('no automatic plural stripping: glass/bus stay what they are', () {
      expect(terms['bus'], 'label:bus');
      expect(terms['buses'], 'label:bus');
      expect(terms.containsKey('bu'), isFalse);
    });

    test('a broken expansions file is a FormatException', () {
      expect(() => parseLabelExpansions('[]'), throwsFormatException);
      expect(
        () => parseLabelExpansions('{"expansions": {"a": "b"}}'),
        throwsFormatException,
      );
      expect(
        () => parseLabelExpansions('{"expansions": {"a": [1]}}'),
        throwsFormatException,
      );
    });
  });

  group('family', () {
    test('label:<vocabulary> → one term; unknown → null', () {
      final cat = family.resolve('cat')!;
      expect(cat.id, 'label:cat');
      expect(cat.apply(IndexQuery.all).labelTerms, [
        {'cat'},
      ]);
      expect(family.resolve('unicorn'), isNull);
      expect(family.resolve(''), isNull);
    });

    test('expansions OR inside the term: animal also finds dogs', () {
      final terms = family.resolve('animal')!.apply(IndexQuery.all).labelTerms;
      expect(terms, hasLength(1));
      expect(terms.single, containsAll(['animal', 'cat', 'dog']));
    });

    test('two words AND: blue beach', () {
      final q = family
          .resolve('beach')!
          .apply(family.resolve('color:blue')!.apply(IndexQuery.all));
      expect(q.labelTerms, [
        {'color:blue'},
        {'beach'},
      ]);
    });

    test("blurry → blurryOnly with C2's threshold", () {
      final q = family.resolve(kBlurryArg)!.apply(IndexQuery.all);
      expect(q.blurryOnly, isTrue);
      expect(q.blurThreshold, 120);
      expect(q.labelTerms, isEmpty);
      expect(isAiLabelKeyword(family.resolve(kBlurryArg)!), isFalse);
      expect(isAiLabelKeyword(family.resolve('cat')!), isTrue);
    });

    test('chip labels', () {
      final l10n = AppLocalizationsEn();
      expect(family.resolve('cat')!.chipLabel(l10n), 'Content: cat');
      expect(family.resolve('color:blue')!.chipLabel(l10n), 'Content: blue');
      expect(family.resolve(kBlurryArg)!.chipLabel(l10n), isNotEmpty);
    });

    test('registered in B8 registry', () {
      expect(resolveKeywordId('label:cat', families)?.id, 'label:cat');
    });
  });

  group('English words (terms_en.json)', () {
    late SearchVocabulary vocab;

    setUp(() async {
      vocab = await loadSearchVocabulary(
        FixtureTermsBundle.langs({'en': searchTermsAsset('en')}),
        main: 'en',
        secondary: '',
        families: families,
      );
    });

    String? idOf(String word) => vocab.phrases[normalizeSearchWord(word)]?.id;

    test('cat, cats, kitten → label:cat; plurals and synonyms', () {
      for (final (w, id) in [
        ('cat', 'label:cat'),
        ('cats', 'label:cat'),
        ('kitten', 'label:cat'),
        ('dogs', 'label:dog'),
        ('puppy', 'label:dog'),
        ('people', 'label:person'),
        ('blue', 'label:color:blue'),
        ('grey', 'label:color:gray'),
        ('blurry', 'label:blurry'),
        ('out of focus', 'label:blurry'),
      ]) {
        expect(idOf(w), id, reason: w);
      }
    });

    test('B8 words are unchanged', () {
      expect(idOf('document'), 'type:document');
      expect(idOf('video'), 'type:video');
      expect(idOf('whatsapp'), 'source:whatsapp');
    });

    test('invoice is a name search; cat whatsapp = label + source', () {
      final tokens = parseSearch('cat whatsapp invoice', vocab);
      expect(tokens[0], isA<KeywordToken>());
      expect(tokens[1], isA<KeywordToken>());
      expect(tokens[2], isA<NameToken>());
      final q = applyTokens(IndexQuery.all, tokens);
      expect(q.labelTerms, [
        {'cat'},
      ]);
      expect(q.sources, isNotEmpty);
      expect(q.nameContains, 'invoice');
    });

    test('gibberish is a name search, no content terms', () {
      final q = applyTokens(IndexQuery.all, parseSearch('xqzzv', vocab));
      expect(q.hasContentTerms, isFalse);
      expect(q.nameContains, 'xqzzv');
    });
  });

  test('fixture languages: a label word in the secondary file is a content '
      'word; the same word in an unchosen file is a name', () async {
    final bundle = FixtureTermsBundle.langs({
      'xx': fixture('xx'),
      'yy': fixture('yy'),
      'zz': fixture('zz'),
    });
    final vocab = await loadSearchVocabulary(
      bundle,
      main: 'xx',
      secondary: 'yy',
      families: families,
    );
    final tokens = parseSearch('kediyy kedizz', vocab);
    expect((tokens[0] as KeywordToken).keyword.id, 'label:cat');
    expect(tokens[1], isA<NameToken>());
    // Now with the label family registered, xx's future word resolves.
    expect(vocab.phrases['futurexx']?.id, 'label:dog');
    expect(applyTokens(IndexQuery.all, tokens).labelTerms, [
      {'cat'},
    ]);
  });

  test('without the label family (B8 only), label ids are ignored', () async {
    final vocab = await loadSearchVocabulary(
      FixtureTermsBundle.langs({'en': searchTermsAsset('en')}),
      main: 'en',
      secondary: '',
      families: const [typeKeywords, sourceKeywords, attributeKeywords],
    );
    expect(vocab.phrases['cat'], isNull);
  });
}
