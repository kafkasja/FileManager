// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe_layout_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The layout edited on "Customize swipes" (TASK-P1) and the S6 swipe
/// setup sheet: the active session's layout, or the saved default when no
/// session is active. S6: one per source, like the deck (a remote session
/// edits only its own row).

@ProviderFor(SwipeLayoutController)
final swipeLayoutForSourceProvider = SwipeLayoutControllerFamily._();

/// The layout edited on "Customize swipes" (TASK-P1) and the S6 swipe
/// setup sheet: the active session's layout, or the saved default when no
/// session is active. S6: one per source, like the deck (a remote session
/// edits only its own row).
final class SwipeLayoutControllerProvider
    extends $AsyncNotifierProvider<SwipeLayoutController, SwipeLayout> {
  /// The layout edited on "Customize swipes" (TASK-P1) and the S6 swipe
  /// setup sheet: the active session's layout, or the saved default when no
  /// session is active. S6: one per source, like the deck (a remote session
  /// edits only its own row).
  SwipeLayoutControllerProvider._({
    required SwipeLayoutControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'swipeLayoutForSourceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$swipeLayoutControllerHash();

  @override
  String toString() {
    return r'swipeLayoutForSourceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SwipeLayoutController create() => SwipeLayoutController();

  @override
  bool operator ==(Object other) {
    return other is SwipeLayoutControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$swipeLayoutControllerHash() =>
    r'1df69568ced8428ab78ce3deeca2c2014396f3d9';

/// The layout edited on "Customize swipes" (TASK-P1) and the S6 swipe
/// setup sheet: the active session's layout, or the saved default when no
/// session is active. S6: one per source, like the deck (a remote session
/// edits only its own row).

final class SwipeLayoutControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SwipeLayoutController,
          AsyncValue<SwipeLayout>,
          SwipeLayout,
          FutureOr<SwipeLayout>,
          String
        > {
  SwipeLayoutControllerFamily._()
    : super(
        retry: null,
        name: r'swipeLayoutForSourceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The layout edited on "Customize swipes" (TASK-P1) and the S6 swipe
  /// setup sheet: the active session's layout, or the saved default when no
  /// session is active. S6: one per source, like the deck (a remote session
  /// edits only its own row).

  SwipeLayoutControllerProvider call(String sourceId) =>
      SwipeLayoutControllerProvider._(argument: sourceId, from: this);

  @override
  String toString() => r'swipeLayoutForSourceProvider';
}

/// The layout edited on "Customize swipes" (TASK-P1) and the S6 swipe
/// setup sheet: the active session's layout, or the saved default when no
/// session is active. S6: one per source, like the deck (a remote session
/// edits only its own row).

abstract class _$SwipeLayoutController extends $AsyncNotifier<SwipeLayout> {
  late final _$args = ref.$arg as String;
  String get sourceId => _$args;

  FutureOr<SwipeLayout> build(String sourceId);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}
