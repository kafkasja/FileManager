// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The big-file threshold, live (the section writes it).

@ProviderFor(storageBigFileThreshold)
final storageBigFileThresholdProvider = StorageBigFileThresholdProvider._();

/// The big-file threshold, live (the section writes it).

final class StorageBigFileThresholdProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// The big-file threshold, live (the section writes it).
  StorageBigFileThresholdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageBigFileThresholdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageBigFileThresholdHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return storageBigFileThreshold(ref);
  }
}

String _$storageBigFileThresholdHash() =>
    r'fde402990ac7bc0e9e789ec96d000a4bea2a2a69';

/// Everything the Storage overview shows (TASK-C1). Auto-dispose: nothing
/// runs while the screen is closed. Re-runs on index changes (debounced).

@ProviderFor(storageOverview)
final storageOverviewProvider = StorageOverviewProvider._();

/// Everything the Storage overview shows (TASK-C1). Auto-dispose: nothing
/// runs while the screen is closed. Re-runs on index changes (debounced).

final class StorageOverviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<StorageOverview>,
          StorageOverview,
          FutureOr<StorageOverview>
        >
    with $FutureModifier<StorageOverview>, $FutureProvider<StorageOverview> {
  /// Everything the Storage overview shows (TASK-C1). Auto-dispose: nothing
  /// runs while the screen is closed. Re-runs on index changes (debounced).
  StorageOverviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageOverviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageOverviewHash();

  @$internal
  @override
  $FutureProviderElement<StorageOverview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StorageOverview> create(Ref ref) {
    return storageOverview(ref);
  }
}

String _$storageOverviewHash() => r'4eedefa6913c4545200555aedf513ef56e3492bc';
