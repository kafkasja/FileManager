import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:meta/meta.dart';

/// A smart search word (TASK-B8). Its stable, language-neutral [id] (a
/// concept id like `type:video`, never shown or matched as a typed word) is
/// what term files map words to.
@immutable
class SearchKeyword {
  const new({required this.id, required this.chipLabel, required this.apply});

  final String id;
  final String Function(AppLocalizations l10n) chipLabel;
  final IndexQuery Function(IndexQuery q) apply;

  @override
  bool operator ==(Object other) => other is SearchKeyword && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// One feature's keywords. [resolve] builds a keyword from the part of an id
/// after this family's [prefix] (`label` + `cat` → `label:cat`), or null if
/// unknown. Families have no built-in words: every typed word, English
/// included, comes from a term file.
@immutable
class SearchKeywordFamily {
  const new({required this.prefix, required this.resolve});

  final String prefix;
  final SearchKeyword? Function(String arg) resolve;
}

/// The loaded words of the chosen search languages (main + optional
/// secondary), already normalized and resolved to keywords.
@immutable
class SearchVocabulary {
  const new({required this.phrases, this.loadErrors = const []});

  static const empty = SearchVocabulary(phrases: {});

  /// Normalized word or phrase (up to 3 words, single spaces) → keyword.
  final Map<String, SearchKeyword> phrases;

  /// Language tags whose term file couldn't be loaded (shown on screen).
  final List<String> loadErrors;
}

/// One parsed piece of the search text.
@immutable
sealed class SearchToken {
  const new(this.raw);

  /// The text as typed (for chips and for turning it back into a name).
  final String raw;
}

/// A file extension without the dot, lowercase (`jpg`).
final class ExtensionToken extends SearchToken {
  const new(super.raw, this.ext);

  final String ext;
}

final class KeywordToken extends SearchToken {
  const new(super.raw, this.keyword);

  final SearchKeyword keyword;
}

/// Plain name substring.
final class NameToken extends SearchToken {
  const new(super.raw);
}
