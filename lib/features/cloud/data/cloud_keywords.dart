import 'package:kfm/features/search/domain/search_keyword.dart';

/// X4: `cloud:on` / `cloud:off` → the "On cloud" / "Not on cloud" filter
/// (same `IndexQuery.onCloud` as the filter sheet). Words come from the
/// term files (English here; other languages: L2).
const cloudKeywords = SearchKeywordFamily(prefix: 'cloud', resolve: _resolve);

SearchKeyword? _resolve(String arg) => switch (arg) {
  'on' => SearchKeyword(
    id: 'cloud:on',
    chipLabel: (l10n) => l10n.cloudFilterOn,
    apply: (q) => q.copyWith(onCloud: () => true),
  ),
  'off' => SearchKeyword(
    id: 'cloud:off',
    chipLabel: (l10n) => l10n.cloudFilterNotOn,
    apply: (q) => q.copyWith(onCloud: () => false),
  ),
  _ => null,
};
