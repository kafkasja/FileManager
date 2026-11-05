// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_nav_pane.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// E1 hook: the device rows of the nav pane's Devices group (linked and
/// remembered devices: status dot, "Send to <name>" drop, click = remote
/// browse). Empty until E1c fills it.

@ProviderFor(desktopNavDeviceRows)
final desktopNavDeviceRowsProvider = DesktopNavDeviceRowsProvider._();

/// E1 hook: the device rows of the nav pane's Devices group (linked and
/// remembered devices: status dot, "Send to <name>" drop, click = remote
/// browse). Empty until E1c fills it.

final class DesktopNavDeviceRowsProvider
    extends $FunctionalProvider<List<Widget>, List<Widget>, List<Widget>>
    with $Provider<List<Widget>> {
  /// E1 hook: the device rows of the nav pane's Devices group (linked and
  /// remembered devices: status dot, "Send to <name>" drop, click = remote
  /// browse). Empty until E1c fills it.
  DesktopNavDeviceRowsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopNavDeviceRowsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopNavDeviceRowsHash();

  @$internal
  @override
  $ProviderElement<List<Widget>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Widget> create(Ref ref) {
    return desktopNavDeviceRows(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Widget> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Widget>>(value),
    );
  }
}

String _$desktopNavDeviceRowsHash() =>
    r'6e2ea881b1ce19b7ac5d3f586f130bc789e93334';

/// Nav pane width (`desktop.navWidth`, 160–360 px).

@ProviderFor(DesktopNavWidth)
final desktopNavWidthProvider = DesktopNavWidthProvider._();

/// Nav pane width (`desktop.navWidth`, 160–360 px).
final class DesktopNavWidthProvider
    extends $NotifierProvider<DesktopNavWidth, double> {
  /// Nav pane width (`desktop.navWidth`, 160–360 px).
  DesktopNavWidthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopNavWidthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopNavWidthHash();

  @$internal
  @override
  DesktopNavWidth create() => DesktopNavWidth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$desktopNavWidthHash() => r'4e939a0f497b1c7593321d4eb69dbdec72406bb6';

/// Nav pane width (`desktop.navWidth`, 160–360 px).

abstract class _$DesktopNavWidth extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// View → Navigation pane.

@ProviderFor(DesktopNavPaneShown)
final desktopNavPaneShownProvider = DesktopNavPaneShownProvider._();

/// View → Navigation pane.
final class DesktopNavPaneShownProvider
    extends $NotifierProvider<DesktopNavPaneShown, bool> {
  /// View → Navigation pane.
  DesktopNavPaneShownProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopNavPaneShownProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopNavPaneShownHash();

  @$internal
  @override
  DesktopNavPaneShown create() => DesktopNavPaneShown();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$desktopNavPaneShownHash() =>
    r'd580df13335472c34d644823f43482d1f9c9de92';

/// View → Navigation pane.

abstract class _$DesktopNavPaneShown extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
