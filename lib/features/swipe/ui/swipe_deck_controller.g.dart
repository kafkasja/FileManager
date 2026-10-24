// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe_deck_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(swipeQueueRepository)
final swipeQueueRepositoryProvider = SwipeQueueRepositoryProvider._();

final class SwipeQueueRepositoryProvider
    extends
        $FunctionalProvider<
          SwipeQueueRepository,
          SwipeQueueRepository,
          SwipeQueueRepository
        >
    with $Provider<SwipeQueueRepository> {
  SwipeQueueRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'swipeQueueRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$swipeQueueRepositoryHash();

  @$internal
  @override
  $ProviderElement<SwipeQueueRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SwipeQueueRepository create(Ref ref) {
    return swipeQueueRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SwipeQueueRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SwipeQueueRepository>(value),
    );
  }
}

String _$swipeQueueRepositoryHash() =>
    r'efdd2693458122650f1ce0d695d08ef800becd97';

@ProviderFor(clearSessionUseCase)
final clearSessionUseCaseProvider = ClearSessionUseCaseProvider._();

final class ClearSessionUseCaseProvider
    extends
        $FunctionalProvider<
          ClearSessionUseCase,
          ClearSessionUseCase,
          ClearSessionUseCase
        >
    with $Provider<ClearSessionUseCase> {
  ClearSessionUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clearSessionUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clearSessionUseCaseHash();

  @$internal
  @override
  $ProviderElement<ClearSessionUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ClearSessionUseCase create(Ref ref) {
    return clearSessionUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClearSessionUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClearSessionUseCase>(value),
    );
  }
}

String _$clearSessionUseCaseHash() =>
    r'bc9bb2946b866b79e987dd0c07ba88bfe68af88e';

@ProviderFor(swipeFileOps)
final swipeFileOpsProvider = SwipeFileOpsProvider._();

final class SwipeFileOpsProvider
    extends $FunctionalProvider<SwipeFileOps, SwipeFileOps, SwipeFileOps>
    with $Provider<SwipeFileOps> {
  SwipeFileOpsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'swipeFileOpsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$swipeFileOpsHash();

  @$internal
  @override
  $ProviderElement<SwipeFileOps> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SwipeFileOps create(Ref ref) {
    return swipeFileOps(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SwipeFileOps value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SwipeFileOps>(value),
    );
  }
}

String _$swipeFileOpsHash() => r'5eef643081d32e1efc0d7b7777b29009e05e8c46';

/// Move/copy results for the swipe screen's snackbars (P2).

@ProviderFor(swipeFileOpEvents)
final swipeFileOpEventsProvider = SwipeFileOpEventsProvider._();

/// Move/copy results for the swipe screen's snackbars (P2).

final class SwipeFileOpEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<SwipeFileOpEvent>,
          SwipeFileOpEvent,
          Stream<SwipeFileOpEvent>
        >
    with $FutureModifier<SwipeFileOpEvent>, $StreamProvider<SwipeFileOpEvent> {
  /// Move/copy results for the swipe screen's snackbars (P2).
  SwipeFileOpEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'swipeFileOpEventsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$swipeFileOpEventsHash();

  @$internal
  @override
  $StreamProviderElement<SwipeFileOpEvent> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SwipeFileOpEvent> create(Ref ref) {
    return swipeFileOpEvents(ref);
  }
}

String _$swipeFileOpEventsHash() => r'0e58284501316605de926e0e918255e4a56bad86';

@ProviderFor(swipeActionDispatcher)
final swipeActionDispatcherProvider = SwipeActionDispatcherProvider._();

final class SwipeActionDispatcherProvider
    extends
        $FunctionalProvider<
          SwipeActionDispatcher,
          SwipeActionDispatcher,
          SwipeActionDispatcher
        >
    with $Provider<SwipeActionDispatcher> {
  SwipeActionDispatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'swipeActionDispatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$swipeActionDispatcherHash();

  @$internal
  @override
  $ProviderElement<SwipeActionDispatcher> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SwipeActionDispatcher create(Ref ref) {
    return swipeActionDispatcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SwipeActionDispatcher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SwipeActionDispatcher>(value),
    );
  }
}

String _$swipeActionDispatcherHash() =>
    r'23eb8f11bcf3027e34ef408db90c2fb07277395b';

/// D1: no active session and the setting is "delete permanently" → the
/// user confirms once before the session starts (resumed sessions never ask).

@ProviderFor(needsDeleteModeChoice)
final needsDeleteModeChoiceProvider = NeedsDeleteModeChoiceProvider._();

/// D1: no active session and the setting is "delete permanently" → the
/// user confirms once before the session starts (resumed sessions never ask).

final class NeedsDeleteModeChoiceProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// D1: no active session and the setting is "delete permanently" → the
  /// user confirms once before the session starts (resumed sessions never ask).
  NeedsDeleteModeChoiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'needsDeleteModeChoiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$needsDeleteModeChoiceHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return needsDeleteModeChoice(ref);
  }
}

String _$needsDeleteModeChoiceHash() =>
    r'8e8da76c113e4302925b1b58470053ccd0d36884';

/// The swipe deck (TASK-S1). Swipes advance the state immediately; all
/// saving happens in the background through the write queue.

@ProviderFor(SwipeDeckController)
final swipeDeckControllerProvider = SwipeDeckControllerProvider._();

/// The swipe deck (TASK-S1). Swipes advance the state immediately; all
/// saving happens in the background through the write queue.
final class SwipeDeckControllerProvider
    extends $AsyncNotifierProvider<SwipeDeckController, SwipeDeckState> {
  /// The swipe deck (TASK-S1). Swipes advance the state immediately; all
  /// saving happens in the background through the write queue.
  SwipeDeckControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'swipeDeckControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$swipeDeckControllerHash();

  @$internal
  @override
  SwipeDeckController create() => SwipeDeckController();
}

String _$swipeDeckControllerHash() =>
    r'856c28777709980c843503d0573c7d4b26908a81';

/// The swipe deck (TASK-S1). Swipes advance the state immediately; all
/// saving happens in the background through the write queue.

abstract class _$SwipeDeckController extends $AsyncNotifier<SwipeDeckState> {
  FutureOr<SwipeDeckState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SwipeDeckState>, SwipeDeckState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SwipeDeckState>, SwipeDeckState>,
              AsyncValue<SwipeDeckState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
