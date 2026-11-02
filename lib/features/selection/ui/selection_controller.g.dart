// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selection_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The one global selection (TASK-B6), used by Browse, collections and
/// search. State changes at once; writes follow through the write queue.
/// Nothing here removes a file except [remove] (Edit mode), [clearAll],
/// [dropAll] (files a move job moved away) and pruning files that left the
/// index.

@ProviderFor(SelectionController)
final selectionControllerProvider = SelectionControllerProvider._();

/// The one global selection (TASK-B6), used by Browse, collections and
/// search. State changes at once; writes follow through the write queue.
/// Nothing here removes a file except [remove] (Edit mode), [clearAll],
/// [dropAll] (files a move job moved away) and pruning files that left the
/// index.
final class SelectionControllerProvider
    extends $AsyncNotifierProvider<SelectionController, SelectionState> {
  /// The one global selection (TASK-B6), used by Browse, collections and
  /// search. State changes at once; writes follow through the write queue.
  /// Nothing here removes a file except [remove] (Edit mode), [clearAll],
  /// [dropAll] (files a move job moved away) and pruning files that left the
  /// index.
  SelectionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectionControllerHash();

  @$internal
  @override
  SelectionController create() => SelectionController();
}

String _$selectionControllerHash() =>
    r'925b2de0c5dcc308327fa6c041010870575f0932';

/// The one global selection (TASK-B6), used by Browse, collections and
/// search. State changes at once; writes follow through the write queue.
/// Nothing here removes a file except [remove] (Edit mode), [clearAll],
/// [dropAll] (files a move job moved away) and pruning files that left the
/// index.

abstract class _$SelectionController extends $AsyncNotifier<SelectionState> {
  FutureOr<SelectionState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SelectionState>, SelectionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SelectionState>, SelectionState>,
              AsyncValue<SelectionState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
