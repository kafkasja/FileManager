// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_namer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The online namer (used only while the setting is on; the job checks).

@ProviderFor(placeNamer)
final placeNamerProvider = PlaceNamerProvider._();

/// The online namer (used only while the setting is on; the job checks).

final class PlaceNamerProvider
    extends $FunctionalProvider<PlaceNamer, PlaceNamer, PlaceNamer>
    with $Provider<PlaceNamer> {
  /// The online namer (used only while the setting is on; the job checks).
  PlaceNamerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placeNamerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placeNamerHash();

  @$internal
  @override
  $ProviderElement<PlaceNamer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlaceNamer create(Ref ref) {
    return placeNamer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaceNamer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaceNamer>(value),
    );
  }
}

String _$placeNamerHash() => r'970e3c3f2e6795f4f2ccbda7d4b03d229365a24a';
