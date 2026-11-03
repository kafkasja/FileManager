// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_sort_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Sort view's layout (Large icons by default: photos are judged by
/// their thumbnails). Kept while the app runs.

@ProviderFor(DesktopSortLayout)
final desktopSortLayoutProvider = DesktopSortLayoutProvider._();

/// The Sort view's layout (Large icons by default: photos are judged by
/// their thumbnails). Kept while the app runs.
final class DesktopSortLayoutProvider
    extends $NotifierProvider<DesktopSortLayout, ExplorerLayout> {
  /// The Sort view's layout (Large icons by default: photos are judged by
  /// their thumbnails). Kept while the app runs.
  DesktopSortLayoutProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopSortLayoutProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopSortLayoutHash();

  @$internal
  @override
  DesktopSortLayout create() => DesktopSortLayout();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExplorerLayout value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExplorerLayout>(value),
    );
  }
}

String _$desktopSortLayoutHash() => r'7a0237ffd77423217fc78a0802b38d2e549d08d9';

/// The Sort view's layout (Large icons by default: photos are judged by
/// their thumbnails). Kept while the app runs.

abstract class _$DesktopSortLayout extends $Notifier<ExplorerLayout> {
  ExplorerLayout build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ExplorerLayout, ExplorerLayout>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExplorerLayout, ExplorerLayout>,
              ExplorerLayout,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
