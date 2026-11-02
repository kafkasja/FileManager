// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_release_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(releaseClient)
final releaseClientProvider = ReleaseClientProvider._();

final class ReleaseClientProvider
    extends $FunctionalProvider<ReleaseClient, ReleaseClient, ReleaseClient>
    with $Provider<ReleaseClient> {
  ReleaseClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'releaseClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$releaseClientHash();

  @$internal
  @override
  $ProviderElement<ReleaseClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReleaseClient create(Ref ref) {
    return releaseClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReleaseClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReleaseClient>(value),
    );
  }
}

String _$releaseClientHash() => r'2f8ea73b9b7969929b72c2561696759a5767039d';
