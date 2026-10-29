// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_with.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(openWithService)
final openWithServiceProvider = OpenWithServiceProvider._();

final class OpenWithServiceProvider
    extends
        $FunctionalProvider<OpenWithService, OpenWithService, OpenWithService>
    with $Provider<OpenWithService> {
  OpenWithServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openWithServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openWithServiceHash();

  @$internal
  @override
  $ProviderElement<OpenWithService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OpenWithService create(Ref ref) {
    return openWithService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OpenWithService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OpenWithService>(value),
    );
  }
}

String _$openWithServiceHash() => r'f4b6e99fd77161655368d43766917809a5bf5c43';
