// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'similar_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(similarRepository)
final similarRepositoryProvider = SimilarRepositoryProvider._();

final class SimilarRepositoryProvider
    extends
        $FunctionalProvider<
          SimilarRepository,
          SimilarRepository,
          SimilarRepository
        >
    with $Provider<SimilarRepository> {
  SimilarRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'similarRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$similarRepositoryHash();

  @$internal
  @override
  $ProviderElement<SimilarRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SimilarRepository create(Ref ref) {
    return similarRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SimilarRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SimilarRepository>(value),
    );
  }
}

String _$similarRepositoryHash() => r'5a00cb92b3837199412f6280dcb516df10f0a170';
