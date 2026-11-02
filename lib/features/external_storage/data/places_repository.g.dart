// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'places_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The device's volumes and cameras, live. Empty off Android.

@ProviderFor(deviceStorage)
final deviceStorageProvider = DeviceStorageProvider._();

/// The device's volumes and cameras, live. Empty off Android.

final class DeviceStorageProvider
    extends
        $FunctionalProvider<
          AsyncValue<DeviceStorage>,
          DeviceStorage,
          Stream<DeviceStorage>
        >
    with $FutureModifier<DeviceStorage>, $StreamProvider<DeviceStorage> {
  /// The device's volumes and cameras, live. Empty off Android.
  DeviceStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceStorageHash();

  @$internal
  @override
  $StreamProviderElement<DeviceStorage> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DeviceStorage> create(Ref ref) {
    return deviceStorage(ref);
  }
}

String _$deviceStorageHash() => r'5e03c986af170989fedb51a384b707f74fbf5f13';

/// U1: SAF grants (volume uuid → tree URI).

@ProviderFor(externalSafGrants)
final externalSafGrantsProvider = ExternalSafGrantsProvider._();

/// U1: SAF grants (volume uuid → tree URI).

final class ExternalSafGrantsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          Stream<Map<String, String>>
        >
    with
        $FutureModifier<Map<String, String>>,
        $StreamProvider<Map<String, String>> {
  /// U1: SAF grants (volume uuid → tree URI).
  ExternalSafGrantsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'externalSafGrantsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$externalSafGrantsHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, String>> create(Ref ref) {
    return externalSafGrants(ref);
  }
}

String _$externalSafGrantsHash() => r'da81590b57ce176d32de0c36b9d782d5e85d4cda';

/// Every storage place, internal storage first. Recomputed when a volume
/// or camera changes, a grant is saved, or All files access flips (the
/// access method follows it; re-checked on resume). Errors surface as
/// `AsyncError` (rule 8).

@ProviderFor(places)
final placesProvider = PlacesProvider._();

/// Every storage place, internal storage first. Recomputed when a volume
/// or camera changes, a grant is saved, or All files access flips (the
/// access method follows it; re-checked on resume). Errors surface as
/// `AsyncError` (rule 8).

final class PlacesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StoragePlace>>,
          List<StoragePlace>,
          FutureOr<List<StoragePlace>>
        >
    with
        $FutureModifier<List<StoragePlace>>,
        $FutureProvider<List<StoragePlace>> {
  /// Every storage place, internal storage first. Recomputed when a volume
  /// or camera changes, a grant is saved, or All files access flips (the
  /// access method follows it; re-checked on resume). Errors surface as
  /// `AsyncError` (rule 8).
  PlacesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placesHash();

  @$internal
  @override
  $FutureProviderElement<List<StoragePlace>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StoragePlace>> create(Ref ref) {
    return places(ref);
  }
}

String _$placesHash() => r'27ca2ea609f5e7db701941ca42dc6effe36fb058';

/// U1: indexed roots of volumes that aren't mounted now. Their rows are
/// hidden from every view (`MediaIndexDao.excludedRoots`), never deleted.

@ProviderFor(unmountedRoots)
final unmountedRootsProvider = UnmountedRootsProvider._();

/// U1: indexed roots of volumes that aren't mounted now. Their rows are
/// hidden from every view (`MediaIndexDao.excludedRoots`), never deleted.

final class UnmountedRootsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          FutureOr<Set<String>>
        >
    with $FutureModifier<Set<String>>, $FutureProvider<Set<String>> {
  /// U1: indexed roots of volumes that aren't mounted now. Their rows are
  /// hidden from every view (`MediaIndexDao.excludedRoots`), never deleted.
  UnmountedRootsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unmountedRootsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unmountedRootsHash();

  @$internal
  @override
  $FutureProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Set<String>> create(Ref ref) {
    return unmountedRoots(ref);
  }
}

String _$unmountedRootsHash() => r'96d9f405da3613353feacacaf9c273f077f41252';
