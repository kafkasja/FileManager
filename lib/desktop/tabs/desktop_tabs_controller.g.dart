// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_tabs_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(desktopFolderExists)
final desktopFolderExistsProvider = DesktopFolderExistsProvider._();

final class DesktopFolderExistsProvider
    extends $FunctionalProvider<FolderExists, FolderExists, FolderExists>
    with $Provider<FolderExists> {
  DesktopFolderExistsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopFolderExistsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopFolderExistsHash();

  @$internal
  @override
  $ProviderElement<FolderExists> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FolderExists create(Ref ref) {
    return desktopFolderExists(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FolderExists value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FolderExists>(value),
    );
  }
}

String _$desktopFolderExistsHash() =>
    r'09818631c1b6275159663c8dd1c03040782fef2c';

/// The desktop window's tabs (TASK-E3): navigation, back/forward per tab,
/// single-instance Sort/Trash/Devices/Settings, reopen closed tabs, and
/// restore after a restart (`desktop.tabs`, debounced 500 ms).

@ProviderFor(DesktopTabsController)
final desktopTabsControllerProvider = DesktopTabsControllerProvider._();

/// The desktop window's tabs (TASK-E3): navigation, back/forward per tab,
/// single-instance Sort/Trash/Devices/Settings, reopen closed tabs, and
/// restore after a restart (`desktop.tabs`, debounced 500 ms).
final class DesktopTabsControllerProvider
    extends $NotifierProvider<DesktopTabsController, DesktopTabsState> {
  /// The desktop window's tabs (TASK-E3): navigation, back/forward per tab,
  /// single-instance Sort/Trash/Devices/Settings, reopen closed tabs, and
  /// restore after a restart (`desktop.tabs`, debounced 500 ms).
  DesktopTabsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopTabsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopTabsControllerHash();

  @$internal
  @override
  DesktopTabsController create() => DesktopTabsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DesktopTabsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DesktopTabsState>(value),
    );
  }
}

String _$desktopTabsControllerHash() =>
    r'279edf1918f2c61a1a3663e65906238b9564da4b';

/// The desktop window's tabs (TASK-E3): navigation, back/forward per tab,
/// single-instance Sort/Trash/Devices/Settings, reopen closed tabs, and
/// restore after a restart (`desktop.tabs`, debounced 500 ms).

abstract class _$DesktopTabsController extends $Notifier<DesktopTabsState> {
  DesktopTabsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DesktopTabsState, DesktopTabsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DesktopTabsState, DesktopTabsState>,
              DesktopTabsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
