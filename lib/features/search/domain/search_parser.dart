import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/features/search/domain/normalize.dart';
import 'package:kfm/features/search/domain/search_keyword.dart';

/// Longest vocabulary phrase tried first ("screen recording", "in the
/// cloud").
const int kMaxPhraseWords = 3;

/// Very long input is cut silently (keeps the per-word LIKE query small):
/// at most [kMaxNameWords] name words, each at most [kMaxNameWordLength]
/// characters (code points). Only the name search is capped.
const int kMaxNameWords = 16;
const int kMaxNameWordLength = 100;

final _whitespace = RegExp(r'\s+');
final _dotExtension = RegExp(r'^\.([a-z0-9]{1,10})$');

/// Both spellings are searched when either is typed.
const Map<String, String> _extensionAliases = {
  'jpeg': 'jpg',
  'jpg': 'jpeg',
  'tif': 'tiff',
  'tiff': 'tif',
  'htm': 'html',
  'html': 'htm',
  'mpeg': 'mpg',
  'mpg': 'mpeg',
  'yml': 'yaml',
  'yaml': 'yml',
};

/// Splits [input] on whitespace and resolves each piece against [vocab].
/// Per position, the longest vocabulary phrase of 2..[kMaxPhraseWords] words
/// wins first; then for a single word: `.xyz` (any extension) →
/// [ExtensionToken], a bare known extension (`pdf`) → [ExtensionToken], a
/// vocabulary word → [KeywordToken], else [NameToken].
List<SearchToken> parseSearch(String input, SearchVocabulary vocab) {
  final words = input.trim().split(_whitespace)..removeWhere((w) => w.isEmpty);
  final normalized = [for (final w in words) normalizeSearchWord(w)];
  final tokens = <SearchToken>[];
  var i = 0;
  while (i < words.length) {
    SearchToken? phrase;
    var used = 1;
    for (var n = kMaxPhraseWords; n >= 2 && phrase == null; n--) {
      if (i + n > words.length) continue;
      final key = normalized.sublist(i, i + n).join(' ');
      if (vocab.phrases[key] case final kw?) {
        phrase = KeywordToken(words.sublist(i, i + n).join(' '), kw);
        used = n;
      }
    }
    tokens.add(phrase ?? _single(words[i], normalized[i], vocab));
    i += used;
  }
  return List.unmodifiable(tokens);
}

SearchToken _single(String raw, String word, SearchVocabulary vocab) {
  if (_dotExtension.firstMatch(word) case final m?) {
    return ExtensionToken(raw, m.group(1)!);
  }
  if (kKnownExtensions.contains(word)) return ExtensionToken(raw, word);
  if (vocab.phrases[word] case final kw?) return KeywordToken(raw, kw);
  return NameToken(raw);
}

/// Applies [tokens] to [base]: extensions (plus their aliases) OR'ed into
/// [IndexQuery.extensions], keywords applied in order, the [NameToken]s
/// joined into [IndexQuery.nameContains] (every word must match; capped at
/// [kMaxNameWords] words of [kMaxNameWordLength] characters). Without name
/// tokens, the base's `nameContains` is kept.
IndexQuery applyTokens(IndexQuery base, List<SearchToken> tokens) {
  var q = base;
  final extensions = <String>{};
  final names = <String>[];
  for (final t in tokens) {
    switch (t) {
      case ExtensionToken(:final ext):
        extensions.add(ext);
        if (_extensionAliases[ext] case final alias?) extensions.add(alias);
      case KeywordToken(:final keyword):
        q = keyword.apply(q);
      case NameToken(:final raw):
        names.add(raw);
    }
  }
  if (extensions.isNotEmpty) {
    q = q.copyWith(extensions: {...q.extensions, ...extensions});
  }
  if (names.isNotEmpty) {
    final words = [
      if (q.nameContains case final n? when n.trim().isNotEmpty) n.trim(),
      ...names,
    ].expand((n) => n.split(_whitespace)).where((w) => w.isNotEmpty);
    final name = words
        .take(kMaxNameWords)
        .map((w) => String.fromCharCodes(w.runes.take(kMaxNameWordLength)))
        .join(' ');
    q = q.copyWith(nameContains: () => name);
  }
  return q;
}

/// The search text the tokens came from (single spaces). Used when a chip's
/// ✕ turns its token back into a [NameToken]: replace the token, then
/// re-parse or apply.
String tokensToText(List<SearchToken> tokens) =>
    tokens.map((t) => t.raw).join(' ');
