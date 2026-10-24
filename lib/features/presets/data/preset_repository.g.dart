// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preset_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(presetRepository)
final presetRepositoryProvider = PresetRepositoryProvider._();

final class PresetRepositoryProvider
    extends
        $FunctionalProvider<
          PresetRepository,
          PresetRepository,
          PresetRepository
        >
    with $Provider<PresetRepository> {
  PresetRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'presetRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$presetRepositoryHash();

  @$internal
  @override
  $ProviderElement<PresetRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PresetRepository create(Ref ref) {
    return presetRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PresetRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PresetRepository>(value),
    );
  }
}

String _$presetRepositoryHash() => r'f3114f3efafccdc06533fae8bc6678168f3101c6';

@ProviderFor(presets)
final presetsProvider = PresetsProvider._();

final class PresetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PresetEntry>>,
          List<PresetEntry>,
          Stream<List<PresetEntry>>
        >
    with
        $FutureModifier<List<PresetEntry>>,
        $StreamProvider<List<PresetEntry>> {
  PresetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'presetsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$presetsHash();

  @$internal
  @override
  $StreamProviderElement<List<PresetEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PresetEntry>> create(Ref ref) {
    return presets(ref);
  }
}

String _$presetsHash() => r'b91d50695c7548c2aaac2118c56b7ae841840aed';

/// The preset the swipe tab uses; 0 = Basic.

@ProviderFor(activePresetId)
final activePresetIdProvider = ActivePresetIdProvider._();

/// The preset the swipe tab uses; 0 = Basic.

final class ActivePresetIdProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// The preset the swipe tab uses; 0 = Basic.
  ActivePresetIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activePresetIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activePresetIdHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return activePresetId(ref);
  }
}

String _$activePresetIdHash() => r'58a30447d03c85f8a7a0df875d0e2d3f093b30d8';
