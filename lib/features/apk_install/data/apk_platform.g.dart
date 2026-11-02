// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apk_platform.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(apkPlatform)
final apkPlatformProvider = ApkPlatformProvider._();

final class ApkPlatformProvider
    extends $FunctionalProvider<ApkPlatform, ApkPlatform, ApkPlatform>
    with $Provider<ApkPlatform> {
  ApkPlatformProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apkPlatformProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apkPlatformHash();

  @$internal
  @override
  $ProviderElement<ApkPlatform> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApkPlatform create(Ref ref) {
    return apkPlatform(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApkPlatform value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApkPlatform>(value),
    );
  }
}

String _$apkPlatformHash() => r'65960891eb0f3ef2526a784806907c6619b8618a';
