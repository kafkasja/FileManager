// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volumes_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// U1: the volume list. Null off Android (and in tests unless overridden):
/// then there are no places and nothing is treated as detached.

@ProviderFor(volumesPlatform)
final volumesPlatformProvider = VolumesPlatformProvider._();

/// U1: the volume list. Null off Android (and in tests unless overridden):
/// then there are no places and nothing is treated as detached.

final class VolumesPlatformProvider
    extends
        $FunctionalProvider<
          VolumesPlatform?,
          VolumesPlatform?,
          VolumesPlatform?
        >
    with $Provider<VolumesPlatform?> {
  /// U1: the volume list. Null off Android (and in tests unless overridden):
  /// then there are no places and nothing is treated as detached.
  VolumesPlatformProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'volumesPlatformProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$volumesPlatformHash();

  @$internal
  @override
  $ProviderElement<VolumesPlatform?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VolumesPlatform? create(Ref ref) {
    return volumesPlatform(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VolumesPlatform? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VolumesPlatform?>(value),
    );
  }
}

String _$volumesPlatformHash() => r'84a77ba59f8dc7d2e0720130357a85ee5a8f4bab';

/// U1: cameras over USB. Null off Android.

@ProviderFor(mtpPlatform)
final mtpPlatformProvider = MtpPlatformProvider._();

/// U1: cameras over USB. Null off Android.

final class MtpPlatformProvider
    extends $FunctionalProvider<MtpPlatform?, MtpPlatform?, MtpPlatform?>
    with $Provider<MtpPlatform?> {
  /// U1: cameras over USB. Null off Android.
  MtpPlatformProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mtpPlatformProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mtpPlatformHash();

  @$internal
  @override
  $ProviderElement<MtpPlatform?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MtpPlatform? create(Ref ref) {
    return mtpPlatform(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MtpPlatform? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MtpPlatform?>(value),
    );
  }
}

String _$mtpPlatformHash() => r'6680cd1fe185ba267bec46fb331c648103b2a071';
