// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'label_keywords.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `label:<vocabulary label>` → an AI label term (with its expansions, OR'ed),
/// `label:blurry` → C2's blurry photos. Typed words come from the term files
/// like every family (B8).

@ProviderFor(labelKeywordFamily)
final labelKeywordFamilyProvider = LabelKeywordFamilyProvider._();

/// `label:<vocabulary label>` → an AI label term (with its expansions, OR'ed),
/// `label:blurry` → C2's blurry photos. Typed words come from the term files
/// like every family (B8).

final class LabelKeywordFamilyProvider
    extends
        $FunctionalProvider<
          SearchKeywordFamily,
          SearchKeywordFamily,
          SearchKeywordFamily
        >
    with $Provider<SearchKeywordFamily> {
  /// `label:<vocabulary label>` → an AI label term (with its expansions, OR'ed),
  /// `label:blurry` → C2's blurry photos. Typed words come from the term files
  /// like every family (B8).
  LabelKeywordFamilyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labelKeywordFamilyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labelKeywordFamilyHash();

  @$internal
  @override
  $ProviderElement<SearchKeywordFamily> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SearchKeywordFamily create(Ref ref) {
    return labelKeywordFamily(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchKeywordFamily value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchKeywordFamily>(value),
    );
  }
}

String _$labelKeywordFamilyHash() =>
    r'4e46adda9db9f7bbd2ccdd43d742353145c140b0';

/// `assets/search/label_expansions.json`, loaded once. A parse error is an
/// AsyncError (rule 8); the family then works without expansions.

@ProviderFor(labelExpansions)
final labelExpansionsProvider = LabelExpansionsProvider._();

/// `assets/search/label_expansions.json`, loaded once. A parse error is an
/// AsyncError (rule 8); the family then works without expansions.

final class LabelExpansionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, Set<String>>>,
          Map<String, Set<String>>,
          FutureOr<Map<String, Set<String>>>
        >
    with
        $FutureModifier<Map<String, Set<String>>>,
        $FutureProvider<Map<String, Set<String>>> {
  /// `assets/search/label_expansions.json`, loaded once. A parse error is an
  /// AsyncError (rule 8); the family then works without expansions.
  LabelExpansionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labelExpansionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labelExpansionsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, Set<String>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, Set<String>>> create(Ref ref) {
    return labelExpansions(ref);
  }
}

String _$labelExpansionsHash() => r'1f52a2dafa8d65fba96792e6151c9fec1b9a261f';
