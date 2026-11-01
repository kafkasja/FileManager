// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_image_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The live [RemoteMediaAccess] (changes on connect / disconnect).

@ProviderFor(remoteMediaAccess)
final remoteMediaAccessProvider = RemoteMediaAccessProvider._();

/// The live [RemoteMediaAccess] (changes on connect / disconnect).

final class RemoteMediaAccessProvider
    extends
        $FunctionalProvider<
          RemoteMediaAccess,
          RemoteMediaAccess,
          RemoteMediaAccess
        >
    with $Provider<RemoteMediaAccess> {
  /// The live [RemoteMediaAccess] (changes on connect / disconnect).
  RemoteMediaAccessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteMediaAccessProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteMediaAccessHash();

  @$internal
  @override
  $ProviderElement<RemoteMediaAccess> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RemoteMediaAccess create(Ref ref) {
    return remoteMediaAccess(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RemoteMediaAccess value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoteMediaAccess>(value),
    );
  }
}

String _$remoteMediaAccessHash() => r'8df8da02840bca7608eb660f7cf0c270960509bf';
