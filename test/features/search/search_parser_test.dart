import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:kfm/features/search/data/builtin_keywords.dart';
import 'package:kfm/features/search/data/search_keywords.dart';
import 'package:kfm/features/search/domain/search_keyword.dart';
import 'package:kfm/features/search/domain/search_parser.dart';

const List<SearchKeywordFamily> _families = [
  typeKeywords,
  sourceKeywords,
  attributeKeywords,
];

SearchVocabulary _vocab(Map<String, String> words) => SearchVocabulary(
  phrases: {
    for (final MapEntry(:key, :value) in words.entries)
      key: resolveKeywordId(value, _families)!,
  },
);

final SearchVocabulary vocab = _vocab({
  'video': 'type:video',
  'videos': 'type:video',
  'screenshot': 'source:screenshots',
  'whatsapp': 'source:whatsapp',
  'hidden': 'attr:hidden',
  'tiny': 'attr:tiny',
  'screen recording': 'source:screenrecordings',
  'gif maker': 'source:gifs',
  'in the cloud': 'attr:large', // any 3-word phrase
  'kopek': 'type:image',
});

String describe(SearchToken t) => switch (t) {
  ExtensionToken(:final ext) => 'ext:$ext',
  KeywordToken(:final keyword) => 'kw:${keyword.id}',
  NameToken(:final raw) => 'name:$raw',
};

List<String> parse(String s) => parseSearch(s, vocab).map(describe).toList();

void main() {
  group('parseSearch', () {
    test('empty and whitespace give no tokens', () {
      expect(parse(''), isEmpty);
      expect(parse('   \t '), isEmpty);
    });

    test('dot extension: any extension, known or not', () {
      expect(parse('.jpg'), ['ext:jpg']);
      expect(parse('.XYZ'), ['ext:xyz']);
      expect(parse('.abcdefghij'), ['ext:abcdefghij']);
      // Too long or with other characters: a name.
      expect(parse('.abcdefghijk'), ['name:.abcdefghijk']);
      expect(parse('.a-b'), ['name:.a-b']);
      expect(parse('.'), ['name:.']);
    });

    test('bare known extensions', () {
      expect(parse('pdf png JPG'), ['ext:pdf', 'ext:png', 'ext:jpg']);
      expect(parse('gif'), ['ext:gif']);
      expect(parse('log'), ['ext:log']);
      expect(parse('torrent iso'), ['ext:torrent', 'ext:iso']);
    });

    test('keywords, case and accents normalized', () {
      expect(parse('Video'), ['kw:type:video']);
      expect(parse('VIDEOS'), ['kw:type:video']);
      expect(parse('köpek'), ['kw:type:image']);
      expect(parse('KÖPEK'), ['kw:type:image']);
    });

    test('longest phrase first', () {
      expect(parse('screen recording'), ['kw:source:screenrecordings']);
      expect(parse('Screen   Recording 2024'), [
        'kw:source:screenrecordings',
        'name:2024',
      ]);
      expect(parse('in the cloud'), ['kw:attr:large']);
      expect(parse('in the'), ['name:in', 'name:the']);
      // The phrase beats the bare extension.
      expect(parse('gif maker'), ['kw:source:gifs']);
      expect(parse('gif'), ['ext:gif']);
    });

    test('everything else is a name, raw text kept', () {
      expect(parse('Invoice'), ['name:Invoice']);
      expect(parse('report 2024'), ['name:report', 'name:2024']);
      expect(parse('100%'), ['name:100%']);
      expect(parse('whatsapp pdf Q3'), [
        'kw:source:whatsapp',
        'ext:pdf',
        'name:Q3',
      ]);
    });

    test('keyword raw keeps the typed spelling', () {
      final t = parseSearch('Screen  Recording', vocab).single;
      expect(t.raw, 'Screen Recording');
    });
  });

  group('applyTokens', () {
    IndexQuery apply(String s, [IndexQuery base = IndexQuery.all]) =>
        applyTokens(base, parseSearch(s, vocab));

    test("extensions OR'ed with aliases", () {
      expect(apply('jpg').extensions, {'jpg', 'jpeg'});
      expect(apply('.jpeg').extensions, {'jpg', 'jpeg'});
      expect(apply('pdf png').extensions, {'pdf', 'png'});
      expect(apply('tif').extensions, {'tif', 'tiff'});
      expect(apply('htm').extensions, {'htm', 'html'});
      expect(apply('mpeg').extensions, {'mpeg', 'mpg'});
      expect(apply('yml').extensions, {'yml', 'yaml'});
      expect(apply('.xyz').extensions, {'xyz'});
    });

    test('names joined into nameContains', () {
      expect(apply('report 2024').nameContains, 'report 2024');
      expect(apply('video').nameContains, isNull);
    });

    test('base name is kept and extended', () {
      const base = IndexQuery(nameContains: 'trip');
      expect(apply('video', base).nameContains, 'trip');
      expect(apply('beach', base).nameContains, 'trip beach');
    });

    test('keywords applied in order', () {
      final q = apply('whatsapp pdf video tiny');
      expect(q.sources, {SourceBucket.whatsapp});
      expect(q.extensions, {'pdf'});
      expect(q.kinds, {FileKind.video});
      expect(q.maxSizeBytes, 10 * 1024);
      expect(apply('hidden').hidden, HiddenFilter.only);
    });

    test('base fields survive', () {
      const base = IndexQuery(
        folderPath: '/s/Download',
        extensions: {'txt'},
        kinds: {FileKind.image},
      );
      final q = apply('pdf video', base);
      expect(q.folderPath, '/s/Download');
      expect(q.extensions, {'txt', 'pdf'});
      expect(q.kinds, {FileKind.image, FileKind.video});
    });

    test('a keyword turned back into a NameToken searches the name', () {
      final tokens = parseSearch('video txt', vocab);
      final asName = [NameToken(tokens.first.raw), ...tokens.skip(1)];
      final q = applyTokens(IndexQuery.all, asName);
      expect(q.kinds, isEmpty);
      expect(q.nameContains, 'video');
      expect(q.extensions, {'txt'});
    });
  });

  test('very long input: at most 16 name words of 100 characters', () {
    final long = List.generate(20, (i) => 'w$i${'x' * 150}').join(' ');
    final q = applyTokens(IndexQuery.all, parseSearch(long, vocab));
    final words = q.nameContains!.split(' ');
    expect(words, hasLength(kMaxNameWords));
    expect(words.first, startsWith('w0x'));
    expect(words.last, startsWith('w15x'));
    expect(words.every((w) => w.length == kMaxNameWordLength), isTrue);
    // Code points, not UTF-16 units: an emoji is never cut in half.
    final emoji = applyTokens(
      IndexQuery.all,
      parseSearch('\u{1F600}' * 120, vocab),
    );
    expect(emoji.nameContains, '\u{1F600}' * kMaxNameWordLength);
  });

  test('tokensToText rebuilds the text', () {
    expect(
      tokensToText(parseSearch('  Screen  Recording  report.PDF ', vocab)),
      'Screen Recording report.PDF',
    );
    expect(tokensToText(const []), '');
  });

  test('kKnownExtensions has the kind sets and the extras', () {
    for (final e in [
      'jpg', 'mp4', 'mp3', 'zip', 'pdf', 'apk', 'html', 'htm', 'json', //
      'xml', 'log', 'csv', 'txt', 'svg', 'ics', 'vcf', 'srt', 'torrent',
      'exe', 'iso',
    ]) {
      expect(kKnownExtensions, contains(e));
    }
    expect(kKnownExtensions, isNot(contains('xyz')));
  });
}
