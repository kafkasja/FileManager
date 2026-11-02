// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apk_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// On Android `getTemporaryDirectory` is `Context.getCacheDir`, the
/// folder `ApkSupport.kt` copies into.

@ProviderFor(apkCache)
final apkCacheProvider = ApkCacheProvider._();

/// On Android `getTemporaryDirectory` is `Context.getCacheDir`, the
/// folder `ApkSupport.kt` copies into.

final class ApkCacheProvider
    extends $FunctionalProvider<ApkCache, ApkCache, ApkCache>
    with $Provider<ApkCache> {
  /// On Android `getTemporaryDirectory` is `Context.getCacheDir`, the
  /// folder `ApkSupport.kt` copies into.
  ApkCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apkCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apkCacheHash();

  @$internal
  @override
  $ProviderElement<ApkCache> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApkCache create(Ref ref) {
    return apkCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApkCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApkCache>(value),
    );
  }
}

String _$apkCacheHash() => r'a701dafaa589d8758123322e52c348bea52889c2';
