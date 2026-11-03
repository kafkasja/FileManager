// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'windows_close_host.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// PL1: the Windows close/tray flow, started by `App` (null off Windows).

@ProviderFor(windowsCloseFlow)
final windowsCloseFlowProvider = WindowsCloseFlowProvider._();

/// PL1: the Windows close/tray flow, started by `App` (null off Windows).

final class WindowsCloseFlowProvider
    extends
        $FunctionalProvider<
          WindowsCloseFlow?,
          WindowsCloseFlow?,
          WindowsCloseFlow?
        >
    with $Provider<WindowsCloseFlow?> {
  /// PL1: the Windows close/tray flow, started by `App` (null off Windows).
  WindowsCloseFlowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'windowsCloseFlowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$windowsCloseFlowHash();

  @$internal
  @override
  $ProviderElement<WindowsCloseFlow?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WindowsCloseFlow? create(Ref ref) {
    return windowsCloseFlow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WindowsCloseFlow? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WindowsCloseFlow?>(value),
    );
  }
}

String _$windowsCloseFlowHash() => r'0e139b8198dec484d6fbb18e58251574df37579e';

/// PL1: Settings → Connect switch "Stop sharing when the window closes".

@ProviderFor(windowsStopSharingOnClose)
final windowsStopSharingOnCloseProvider = WindowsStopSharingOnCloseProvider._();

/// PL1: Settings → Connect switch "Stop sharing when the window closes".

final class WindowsStopSharingOnCloseProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// PL1: Settings → Connect switch "Stop sharing when the window closes".
  WindowsStopSharingOnCloseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'windowsStopSharingOnCloseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$windowsStopSharingOnCloseHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return windowsStopSharingOnClose(ref);
  }
}

String _$windowsStopSharingOnCloseHash() =>
    r'a34935bffc33815c42747c1e8cc41355e251cc82';
