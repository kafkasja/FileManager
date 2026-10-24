// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe_layout_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The layout edited on "Customize swipes" (TASK-P1): the active session's
/// layout, or the saved default when no session is active.

@ProviderFor(SwipeLayoutController)
final swipeLayoutControllerProvider = SwipeLayoutControllerProvider._();

/// The layout edited on "Customize swipes" (TASK-P1): the active session's
/// layout, or the saved default when no session is active.
final class SwipeLayoutControllerProvider
    extends $AsyncNotifierProvider<SwipeLayoutController, SwipeLayout> {
  /// The layout edited on "Customize swipes" (TASK-P1): the active session's
  /// layout, or the saved default when no session is active.
  SwipeLayoutControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'swipeLayoutControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$swipeLayoutControllerHash();

  @$internal
  @override
  SwipeLayoutController create() => SwipeLayoutController();
}

String _$swipeLayoutControllerHash() =>
    r'd4a78e9097993a7e465ea794143ada83b2694b58';

/// The layout edited on "Customize swipes" (TASK-P1): the active session's
/// layout, or the saved default when no session is active.

abstract class _$SwipeLayoutController extends $AsyncNotifier<SwipeLayout> {
  FutureOr<SwipeLayout> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SwipeLayout>, SwipeLayout>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SwipeLayout>, SwipeLayout>,
              AsyncValue<SwipeLayout>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
