// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selection_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sorted by [SelectionAction.order] (the bar sorts too). B4: move,
/// delete, copy, duplicate.

@ProviderFor(selectionActions)
final selectionActionsProvider = SelectionActionsProvider._();

/// Sorted by [SelectionAction.order] (the bar sorts too). B4: move,
/// delete, copy, duplicate.

final class SelectionActionsProvider
    extends
        $FunctionalProvider<
          List<SelectionAction>,
          List<SelectionAction>,
          List<SelectionAction>
        >
    with $Provider<List<SelectionAction>> {
  /// Sorted by [SelectionAction.order] (the bar sorts too). B4: move,
  /// delete, copy, duplicate.
  SelectionActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectionActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectionActionsHash();

  @$internal
  @override
  $ProviderElement<List<SelectionAction>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<SelectionAction> create(Ref ref) {
    return selectionActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SelectionAction> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SelectionAction>>(value),
    );
  }
}

String _$selectionActionsHash() => r'1b18f44a9485e6f6b0ba26acc94d0691654fab34';
