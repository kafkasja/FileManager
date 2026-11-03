import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/features/search/data/builtin_keywords.dart';
import 'package:kfm/features/search/data/search_keywords.dart';
import 'package:kfm/features/search/data/search_vocabulary.dart';
import 'package:kfm/features/search/domain/normalize.dart';

/// Prefixes of every family, built or planned (X4 cloud, C4 label).
const _knownPrefixes = {'type', 'source', 'attr', 'cloud', 'label'};

/// Prefixes whose family isn't registered yet, or (C4 label) needs C3's
/// vocabulary: `label_keywords_test` checks those ids.
const _laterPrefixes = {'cloud', 'label'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final files = Directory('assets/search')
      .listSync()
      .whereType<File>()
      .where((f) => f.uri.pathSegments.last.startsWith('terms_'))
      .toList();

  test('B8 + L2 ship terms_en, terms_nl and terms_tr', () {
    expect(files.map((f) => f.uri.pathSegments.last).toList()..sort(), [
      'terms_en.json',
      'terms_nl.json',
      'terms_tr.json',
    ]);
  });

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    test('$name parses, ids have a known prefix and resolve', () {
      final terms = parseTermsFile(file.readAsStringSync());
      expect(terms, isNotEmpty);
      final normalized = <String, String>{};
      for (final MapEntry(key: word, value: id) in terms.entries) {
        final prefix = id.split(':').first;
        expect(_knownPrefixes, contains(prefix), reason: '$word → $id');
        if (!_laterPrefixes.contains(prefix)) {
          expect(
            resolveKeywordId(id, const [
              typeKeywords,
              sourceKeywords,
              attributeKeywords,
            ]),
            isNotNull,
            reason: '$word → $id',
          );
        }
        final w = normalizeSearchWord(word);
        expect(w.split(' ').length, lessThanOrEqualTo(3), reason: word);
        // Two spellings that normalize the same must agree.
        expect(normalized[w] ?? id, id, reason: word);
        normalized[w] = id;
        // A bare known extension is always an extension token (parser
        // rule), so such a term could never match.
        expect(kKnownExtensions, isNot(contains(w)), reason: word);
      }
    });
  }

  test('bundled files are in the asset manifest', () async {
    final langs = await listSearchLanguages(rootBundle);
    expect(langs, ['en', 'nl', 'tr']);
  });

  test('terms_en.json has the plan words', () async {
    final vocab = await loadSearchVocabulary(
      rootBundle,
      main: 'en',
      secondary: '',
      families: const [typeKeywords, sourceKeywords, attributeKeywords],
    );
    expect(vocab.loadErrors, isEmpty);
    for (final (w, id) in [
      ('video', 'type:video'),
      ('photos', 'type:image'),
      ('document', 'type:document'),
      ('screenshot', 'source:screenshots'),
      ('downloads', 'source:downloads'),
      ('whatsapp', 'source:whatsapp'),
      ('expert raw', 'source:expertraw'),
      ('collage', 'source:collages'),
      ('collages', 'source:collages'),
      ('gif maker', 'source:gifs'),
      ('hidden', 'attr:hidden'),
      ('tiny', 'attr:tiny'),
    ]) {
      expect(vocab.phrases[w]?.id, id, reason: w);
    }
    // Bare `gif` stays an extension; `cloud` waits for X4.
    expect(vocab.phrases['gif'], isNull);
    expect(vocab.phrases['cloud'], isNull);
  });
}
