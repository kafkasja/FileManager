// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_drops.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's one drag & drop controller (TASK-PL3 step 4).

@ProviderFor(desktopDragController)
final desktopDragControllerProvider = DesktopDragControllerProvider._();

/// The app's one drag & drop controller (TASK-PL3 step 4).

final class DesktopDragControllerProvider
    extends
        $FunctionalProvider<
          DesktopDragController,
          DesktopDragController,
          DesktopDragController
        >
    with $Provider<DesktopDragController> {
  /// The app's one drag & drop controller (TASK-PL3 step 4).
  DesktopDragControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopDragControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopDragControllerHash();

  @$internal
  @override
  $ProviderElement<DesktopDragController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DesktopDragController create(Ref ref) {
    return desktopDragController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DesktopDragController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DesktopDragController>(value),
    );
  }
}

String _$desktopDragControllerHash() =>
    r'd5322f6249f8f7cfa302cd5ce4259daee5b4528e';
