// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe_source_resolver.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(swipeSourceResolver)
final swipeSourceResolverProvider = SwipeSourceResolverProvider._();

final class SwipeSourceResolverProvider
    extends
        $FunctionalProvider<
          SwipeSourceResolver,
          SwipeSourceResolver,
          SwipeSourceResolver
        >
    with $Provider<SwipeSourceResolver> {
  SwipeSourceResolverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'swipeSourceResolverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$swipeSourceResolverHash();

  @$internal
  @override
  $ProviderElement<SwipeSourceResolver> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SwipeSourceResolver create(Ref ref) {
    return swipeSourceResolver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SwipeSourceResolver value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SwipeSourceResolver>(value),
    );
  }
}

String _$swipeSourceResolverHash() =>
    r'9974494cfa00e47c2516215e15f605d14ef959a5';
