// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_browse_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Desktop Browse's folder, layout and sort. Kept while the app runs.

@ProviderFor(DesktopBrowseController)
final desktopBrowseControllerProvider = DesktopBrowseControllerProvider._();

/// Desktop Browse's folder, layout and sort. Kept while the app runs.
final class DesktopBrowseControllerProvider
    extends $NotifierProvider<DesktopBrowseController, DesktopBrowseState> {
  /// Desktop Browse's folder, layout and sort. Kept while the app runs.
  DesktopBrowseControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopBrowseControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopBrowseControllerHash();

  @$internal
  @override
  DesktopBrowseController create() => DesktopBrowseController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DesktopBrowseState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DesktopBrowseState>(value),
    );
  }
}

String _$desktopBrowseControllerHash() =>
    r'404566c352365c6de3cbae6143cae432d3b0a275';

/// Desktop Browse's folder, layout and sort. Kept while the app runs.

abstract class _$DesktopBrowseController extends $Notifier<DesktopBrowseState> {
  DesktopBrowseState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DesktopBrowseState, DesktopBrowseState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DesktopBrowseState, DesktopBrowseState>,
              DesktopBrowseState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
