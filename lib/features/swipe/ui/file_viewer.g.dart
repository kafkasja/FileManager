// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_viewer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// True while the fullscreen viewer is open (the deck hides undo then).

@ProviderFor(ViewerOpen)
final viewerOpenProvider = ViewerOpenProvider._();

/// True while the fullscreen viewer is open (the deck hides undo then).
final class ViewerOpenProvider extends $NotifierProvider<ViewerOpen, bool> {
  /// True while the fullscreen viewer is open (the deck hides undo then).
  ViewerOpenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'viewerOpenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$viewerOpenHash();

  @$internal
  @override
  ViewerOpen create() => ViewerOpen();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$viewerOpenHash() => r'638378898d5199ce1df8cdc81798156da472aaa6';

/// True while the fullscreen viewer is open (the deck hides undo then).

abstract class _$ViewerOpen extends $Notifier<bool> {
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
