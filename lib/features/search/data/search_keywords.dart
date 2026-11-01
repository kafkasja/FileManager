import 'package:kfm/features/search/data/builtin_keywords.dart';
import 'package:kfm/features/search/data/label_keywords.dart';
import 'package:kfm/features/search/domain/search_keyword.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_keywords.g.dart';

/// Every keyword family, one line per feature (same pattern as
/// `settingsSectionsProvider`). Adding keywords later = one line here +
/// words in `assets/search/terms_en.json` (other languages: L2).
@Riverpod(keepAlive: true)
List<SearchKeywordFamily> searchKeywordFamilies(Ref ref) => List.unmodifiable([
  typeKeywords,
  sourceKeywords,
  attributeKeywords,
  // X4: cloudKeywords,
  ref.watch(labelKeywordFamilyProvider),
]);

/// Resolves a concept id (`type:video`) through [families], or null when no
/// family has its prefix or the family doesn't know it.
SearchKeyword? resolveKeywordId(String id, List<SearchKeywordFamily> families) {
  final colon = id.indexOf(':');
  if (colon <= 0) return null;
  final prefix = id.substring(0, colon);
  final arg = id.substring(colon + 1);
  for (final f in families) {
    if (f.prefix == prefix) return f.resolve(arg);
  }
  return null;
}
