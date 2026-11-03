// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'index_roots.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(windowsChannel)
final windowsChannelProvider = WindowsChannelProvider._();

final class WindowsChannelProvider
    extends $FunctionalProvider<WindowsChannel, WindowsChannel, WindowsChannel>
    with $Provider<WindowsChannel> {
  WindowsChannelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'windowsChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$windowsChannelHash();

  @$internal
  @override
  $ProviderElement<WindowsChannel> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WindowsChannel create(Ref ref) {
    return windowsChannel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WindowsChannel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WindowsChannel>(value),
    );
  }
}

String _$windowsChannelHash() => r'441d7216adc249bc0c9460cfb93b64485810a542';

/// The drives whose directory watchers are paused (PL1 eject).

@ProviderFor(watchPauses)
final watchPausesProvider = WatchPausesProvider._();

/// The drives whose directory watchers are paused (PL1 eject).

final class WatchPausesProvider
    extends $FunctionalProvider<WatchPauses, WatchPauses, WatchPauses>
    with $Provider<WatchPauses> {
  /// The drives whose directory watchers are paused (PL1 eject).
  WatchPausesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchPausesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchPausesHash();

  @$internal
  @override
  $ProviderElement<WatchPauses> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchPauses create(Ref ref) {
    return watchPauses(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchPauses value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchPauses>(value),
    );
  }
}

String _$watchPausesHash() => r'6728ac9e058048c1e8d1d67e5da6237b489f0eb8';

@ProviderFor(windowsIndexRoots)
final windowsIndexRootsProvider = WindowsIndexRootsProvider._();

final class WindowsIndexRootsProvider
    extends
        $FunctionalProvider<
          WindowsIndexRoots,
          WindowsIndexRoots,
          WindowsIndexRoots
        >
    with $Provider<WindowsIndexRoots> {
  WindowsIndexRootsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'windowsIndexRootsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$windowsIndexRootsHash();

  @$internal
  @override
  $ProviderElement<WindowsIndexRoots> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WindowsIndexRoots create(Ref ref) {
    return windowsIndexRoots(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WindowsIndexRoots value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WindowsIndexRoots>(value),
    );
  }
}

String _$windowsIndexRootsHash() => r'9bdd1b295ed87f388d3b214bf1b9eddbaddb1afb';

/// The roots for the "Folders KFM scans" section, with availability.

@ProviderFor(windowsIndexRootStatus)
final windowsIndexRootStatusProvider = WindowsIndexRootStatusProvider._();

/// The roots for the "Folders KFM scans" section, with availability.

final class WindowsIndexRootStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<IndexRootStatus>>,
          List<IndexRootStatus>,
          Stream<List<IndexRootStatus>>
        >
    with
        $FutureModifier<List<IndexRootStatus>>,
        $StreamProvider<List<IndexRootStatus>> {
  /// The roots for the "Folders KFM scans" section, with availability.
  WindowsIndexRootStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'windowsIndexRootStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$windowsIndexRootStatusHash();

  @$internal
  @override
  $StreamProviderElement<List<IndexRootStatus>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<IndexRootStatus>> create(Ref ref) {
    return windowsIndexRootStatus(ref);
  }
}

String _$windowsIndexRootStatusHash() =>
    r'8e074295bcf66efea8e2558667e31d3ef5b8275f';
