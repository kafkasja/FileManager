// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_searches.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recentSearchesRepository)
final recentSearchesRepositoryProvider = RecentSearchesRepositoryProvider._();

final class RecentSearchesRepositoryProvider
    extends
        $FunctionalProvider<
          RecentSearchesRepository,
          RecentSearchesRepository,
          RecentSearchesRepository
        >
    with $Provider<RecentSearchesRepository> {
  RecentSearchesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentSearchesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentSearchesRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecentSearchesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecentSearchesRepository create(Ref ref) {
    return recentSearchesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecentSearchesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecentSearchesRepository>(value),
    );
  }
}

String _$recentSearchesRepositoryHash() =>
    r'8d701a32ab51032f8591cb33c5603156c91071d2';

@ProviderFor(recentSearches)
final recentSearchesProvider = RecentSearchesProvider._();

final class RecentSearchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RecentSearch>>,
          List<RecentSearch>,
          Stream<List<RecentSearch>>
        >
    with
        $FutureModifier<List<RecentSearch>>,
        $StreamProvider<List<RecentSearch>> {
  RecentSearchesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentSearchesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentSearchesHash();

  @$internal
  @override
  $StreamProviderElement<List<RecentSearch>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<RecentSearch>> create(Ref ref) {
    return recentSearches(ref);
  }
}

String _$recentSearchesHash() => r'6322d4260305f53ab7098cf7b92486d474401daf';
