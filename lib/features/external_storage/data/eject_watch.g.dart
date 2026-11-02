// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eject_watch.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ejectWatch)
final ejectWatchProvider = EjectWatchProvider._();

final class EjectWatchProvider
    extends $FunctionalProvider<EjectWatch, EjectWatch, EjectWatch>
    with $Provider<EjectWatch> {
  EjectWatchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ejectWatchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ejectWatchHash();

  @$internal
  @override
  $ProviderElement<EjectWatch> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EjectWatch create(Ref ref) {
    return ejectWatch(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EjectWatch value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EjectWatch>(value),
    );
  }
}

String _$ejectWatchHash() => r'22a88836cdf1978a5080926dc88c57303fb2e331';
