// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_vocabulary.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where term files are read from (tests override it with fixture files).

@ProviderFor(searchAssetBundle)
final searchAssetBundleProvider = SearchAssetBundleProvider._();

/// Where term files are read from (tests override it with fixture files).

final class SearchAssetBundleProvider
    extends $FunctionalProvider<AssetBundle, AssetBundle, AssetBundle>
    with $Provider<AssetBundle> {
  /// Where term files are read from (tests override it with fixture files).
  SearchAssetBundleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchAssetBundleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchAssetBundleHash();

  @$internal
  @override
  $ProviderElement<AssetBundle> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AssetBundle create(Ref ref) {
    return searchAssetBundle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AssetBundle value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AssetBundle>(value),
    );
  }
}

String _$searchAssetBundleHash() => r'aa9c92cab7d6961e5418b31366f3f4c5caf6ca1c';

/// The main search language: the effective app language.

@ProviderFor(searchMainLanguage)
final searchMainLanguageProvider = SearchMainLanguageProvider._();

/// The main search language: the effective app language.

final class SearchMainLanguageProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The main search language: the effective app language.
  SearchMainLanguageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchMainLanguageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchMainLanguageHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return searchMainLanguage(ref);
  }
}

String _$searchMainLanguageHash() =>
    r'6d7d3ade5e47737bce2076c89681515b6ce8aed2';

/// The secondary search language tag; '' = none.

@ProviderFor(searchSecondaryLanguage)
final searchSecondaryLanguageProvider = SearchSecondaryLanguageProvider._();

/// The secondary search language tag; '' = none.

final class SearchSecondaryLanguageProvider
    extends $FunctionalProvider<AsyncValue<String>, String, Stream<String>>
    with $FutureModifier<String>, $StreamProvider<String> {
  /// The secondary search language tag; '' = none.
  SearchSecondaryLanguageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchSecondaryLanguageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchSecondaryLanguageHash();

  @$internal
  @override
  $StreamProviderElement<String> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String> create(Ref ref) {
    return searchSecondaryLanguage(ref);
  }
}

String _$searchSecondaryLanguageHash() =>
    r'39b2562955a109a75e0b5221b7695e4e9557f841';

/// Languages that have a bundled term file, sorted (from the asset
/// manifest, so L2 adds languages without code changes).

@ProviderFor(availableSearchLanguages)
final availableSearchLanguagesProvider = AvailableSearchLanguagesProvider._();

/// Languages that have a bundled term file, sorted (from the asset
/// manifest, so L2 adds languages without code changes).

final class AvailableSearchLanguagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  /// Languages that have a bundled term file, sorted (from the asset
  /// manifest, so L2 adds languages without code changes).
  AvailableSearchLanguagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableSearchLanguagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableSearchLanguagesHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return availableSearchLanguages(ref);
  }
}

String _$availableSearchLanguagesHash() =>
    r'093a92da4655878479c99b63a73d144543ac83b3';

/// The words of the main and (optional) secondary search language only.

@ProviderFor(searchVocabulary)
final searchVocabularyProvider = SearchVocabularyProvider._();

/// The words of the main and (optional) secondary search language only.

final class SearchVocabularyProvider
    extends
        $FunctionalProvider<
          AsyncValue<SearchVocabulary>,
          SearchVocabulary,
          FutureOr<SearchVocabulary>
        >
    with $FutureModifier<SearchVocabulary>, $FutureProvider<SearchVocabulary> {
  /// The words of the main and (optional) secondary search language only.
  SearchVocabularyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchVocabularyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchVocabularyHash();

  @$internal
  @override
  $FutureProviderElement<SearchVocabulary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SearchVocabulary> create(Ref ref) {
    return searchVocabulary(ref);
  }
}

String _$searchVocabularyHash() => r'b0213262227cf1db57a331b9859e493da9cb9b57';
