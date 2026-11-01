// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe_source_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(swipeSourceRepository)
final swipeSourceRepositoryProvider = SwipeSourceRepositoryProvider._();

final class SwipeSourceRepositoryProvider
    extends
        $FunctionalProvider<
          SwipeSourceRepository,
          SwipeSourceRepository,
          SwipeSourceRepository
        >
    with $Provider<SwipeSourceRepository> {
  SwipeSourceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'swipeSourceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$swipeSourceRepositoryHash();

  @$internal
  @override
  $ProviderElement<SwipeSourceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SwipeSourceRepository create(Ref ref) {
    return swipeSourceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SwipeSourceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SwipeSourceRepository>(value),
    );
  }
}

String _$swipeSourceRepositoryHash() =>
    r'fd6159af3bca706a8a2ea008f7ab2e5b97428488';
