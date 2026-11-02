// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Removes location before files leave the device (TASK-X2).

@ProviderFor(locationStripper)
final locationStripperProvider = LocationStripperProvider._();

/// Removes location before files leave the device (TASK-X2).

final class LocationStripperProvider
    extends
        $FunctionalProvider<
          CopyingLocationStripper,
          CopyingLocationStripper,
          CopyingLocationStripper
        >
    with $Provider<CopyingLocationStripper> {
  /// Removes location before files leave the device (TASK-X2).
  LocationStripperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationStripperProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationStripperHash();

  @$internal
  @override
  $ProviderElement<CopyingLocationStripper> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CopyingLocationStripper create(Ref ref) {
    return locationStripper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CopyingLocationStripper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CopyingLocationStripper>(value),
    );
  }
}

String _$locationStripperHash() => r'5a44b7f9aa261b7321aafda9b26f82400f434dc0';

/// Settings → Privacy → "Remove location when sharing".

@ProviderFor(privacyStripLocation)
final privacyStripLocationProvider = PrivacyStripLocationProvider._();

/// Settings → Privacy → "Remove location when sharing".

final class PrivacyStripLocationProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Settings → Privacy → "Remove location when sharing".
  PrivacyStripLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'privacyStripLocationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$privacyStripLocationHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return privacyStripLocation(ref);
  }
}

String _$privacyStripLocationHash() =>
    r'54b2c6bf221c1a47e1c59cbd02040d15d7cb87a8';

/// App start: deletes stripped copies of earlier runs (shares stay until
/// then: the receiving app may read them late).

@ProviderFor(privacyStartupCleanup)
final privacyStartupCleanupProvider = PrivacyStartupCleanupProvider._();

/// App start: deletes stripped copies of earlier runs (shares stay until
/// then: the receiving app may read them late).

final class PrivacyStartupCleanupProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// App start: deletes stripped copies of earlier runs (shares stay until
  /// then: the receiving app may read them late).
  PrivacyStartupCleanupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'privacyStartupCleanupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$privacyStartupCleanupHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return privacyStartupCleanup(ref);
  }
}

String _$privacyStartupCleanupHash() =>
    r'e5fd4f8ddbb2ade88f4ec1288aa656e4a25cd44e';
