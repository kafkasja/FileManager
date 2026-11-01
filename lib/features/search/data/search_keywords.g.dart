// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_keywords.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every keyword family, one line per feature (same pattern as
/// `settingsSectionsProvider`). Adding keywords later = one line here +
/// words in `assets/search/terms_en.json` (other languages: L2).

@ProviderFor(searchKeywordFamilies)
final searchKeywordFamiliesProvider = SearchKeywordFamiliesProvider._();

/// Every keyword family, one line per feature (same pattern as
/// `settingsSectionsProvider`). Adding keywords later = one line here +
/// words in `assets/search/terms_en.json` (other languages: L2).

final class SearchKeywordFamiliesProvider
    extends
        $FunctionalProvider<
          List<SearchKeywordFamily>,
          List<SearchKeywordFamily>,
          List<SearchKeywordFamily>
        >
    with $Provider<List<SearchKeywordFamily>> {
  /// Every keyword family, one line per feature (same pattern as
  /// `settingsSectionsProvider`). Adding keywords later = one line here +
  /// words in `assets/search/terms_en.json` (other languages: L2).
  SearchKeywordFamiliesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchKeywordFamiliesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchKeywordFamiliesHash();

  @$internal
  @override
  $ProviderElement<List<SearchKeywordFamily>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<SearchKeywordFamily> create(Ref ref) {
    return searchKeywordFamilies(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SearchKeywordFamily> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SearchKeywordFamily>>(value),
    );
  }
}

String _$searchKeywordFamiliesHash() =>
    r'64f6735505047527b7887424a490fefefd3714d2';
