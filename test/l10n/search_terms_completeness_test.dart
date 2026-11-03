import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/search/data/search_vocabulary.dart';
import 'package:kfm/features/search/domain/normalize.dart';

/// Prefixes of every keyword family (B8 type/source/attr, X4 cloud, C4 label).
const _knownPrefixes = {'type', 'source', 'attr', 'cloud', 'label'};

Map<String, String> _terms(String lang) =>
    parseTermsFile(File(searchTermsAsset(lang)).readAsStringSync());

/// TASK-L2: every concept English knows has words in nl and tr, and no
/// language knows ids the others don't.
void main() {
  final english = _terms('en');
  final englishIds = english.values.toSet();

  test('terms_en.json ids all use a known prefix', () {
    for (final id in englishIds) {
      expect(_knownPrefixes, contains(id.split(':').first), reason: id);
    }
  });

  for (final lang in ['nl', 'tr']) {
    group('terms_$lang.json', () {
      final terms = _terms(lang);

      test('has at least one word for every id of terms_en.json', () {
        final missing = englishIds.difference(terms.values.toSet());
        expect(missing, isEmpty, reason: 'no $lang word for $missing');
      });

      test('uses only known prefixes and ids terms_en.json has', () {
        for (final MapEntry(key: word, value: id) in terms.entries) {
          expect(
            _knownPrefixes,
            contains(id.split(':').first),
            reason: '$word → $id',
          );
          expect(englishIds, contains(id), reason: '$word → $id');
        }
      });

      test('no word maps to two ids (after normalizing)', () {
        final seen = <String, String>{};
        for (final MapEntry(key: word, value: id) in terms.entries) {
          final w = normalizeSearchWord(word);
          expect(seen[w] ?? id, id, reason: '$word → $id and ${seen[w]}');
          seen[w] = id;
        }
      });
    });
  }

  test('Dutch says cloud, never wolk (a weather cloud)', () {
    final nl = _terms('nl').keys.map(normalizeSearchWord).toSet();
    expect(nl.where((w) => w.split(' ').contains('wolk')), isEmpty);
    expect(_terms('nl')['cloud'], 'cloud:on');
    expect(_terms('nl')['in de cloud'], 'cloud:on');
    expect(_terms('tr')['bulut'], 'cloud:on');
    expect(_terms('tr')['kedi'], 'label:cat');
    expect(_terms('nl')['kat'], 'label:cat');
  });
}
