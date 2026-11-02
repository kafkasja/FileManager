// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saf_grants.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Null off Android.

@ProviderFor(safTreePlatform)
final safTreePlatformProvider = SafTreePlatformProvider._();

/// Null off Android.

final class SafTreePlatformProvider
    extends
        $FunctionalProvider<
          SafTreePlatform?,
          SafTreePlatform?,
          SafTreePlatform?
        >
    with $Provider<SafTreePlatform?> {
  /// Null off Android.
  SafTreePlatformProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'safTreePlatformProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$safTreePlatformHash();

  @$internal
  @override
  $ProviderElement<SafTreePlatform?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SafTreePlatform? create(Ref ref) {
    return safTreePlatform(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SafTreePlatform? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SafTreePlatform?>(value),
    );
  }
}

String _$safTreePlatformHash() => r'61f4991d2b1454aea24063d211d88fd9d89cd5b5';

/// Null off Android.

@ProviderFor(safGrants)
final safGrantsProvider = SafGrantsProvider._();

/// Null off Android.

final class SafGrantsProvider
    extends $FunctionalProvider<SafGrants?, SafGrants?, SafGrants?>
    with $Provider<SafGrants?> {
  /// Null off Android.
  SafGrantsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'safGrantsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$safGrantsHash();

  @$internal
  @override
  $ProviderElement<SafGrants?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SafGrants? create(Ref ref) {
    return safGrants(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SafGrants? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SafGrants?>(value),
    );
  }
}

String _$safGrantsHash() => r'93999aebad6af585b1380bd19b45e3997d8882b3';
