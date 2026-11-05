// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_access.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The default pins: Desktop, Downloads, Documents, Pictures, Videos,
/// Music (Windows' known folders); elsewhere the index's top folders.

@ProviderFor(quickAccessDefaults)
final quickAccessDefaultsProvider = QuickAccessDefaultsProvider._();

/// The default pins: Desktop, Downloads, Documents, Pictures, Videos,
/// Music (Windows' known folders); elsewhere the index's top folders.

final class QuickAccessDefaultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  /// The default pins: Desktop, Downloads, Documents, Pictures, Videos,
  /// Music (Windows' known folders); elsewhere the index's top folders.
  QuickAccessDefaultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAccessDefaultsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickAccessDefaultsHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return quickAccessDefaults(ref);
  }
}

String _$quickAccessDefaultsHash() =>
    r'69e2a026a3a7eb563f00f2bee8d8e91ee2cf1c79';

/// Quick access pins (TASK-E3, `desktop.quickAccess`): pinned folder paths
/// in order; until the user changes them, the defaults.

@ProviderFor(DesktopQuickAccess)
final desktopQuickAccessProvider = DesktopQuickAccessProvider._();

/// Quick access pins (TASK-E3, `desktop.quickAccess`): pinned folder paths
/// in order; until the user changes them, the defaults.
final class DesktopQuickAccessProvider
    extends $AsyncNotifierProvider<DesktopQuickAccess, List<String>> {
  /// Quick access pins (TASK-E3, `desktop.quickAccess`): pinned folder paths
  /// in order; until the user changes them, the defaults.
  DesktopQuickAccessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopQuickAccessProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopQuickAccessHash();

  @$internal
  @override
  DesktopQuickAccess create() => DesktopQuickAccess();
}

String _$desktopQuickAccessHash() =>
    r'2898403f8f2b5763843d828008eaf58ce50ec038';

/// Quick access pins (TASK-E3, `desktop.quickAccess`): pinned folder paths
/// in order; until the user changes them, the defaults.

abstract class _$DesktopQuickAccess extends $AsyncNotifier<List<String>> {
  FutureOr<List<String>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
