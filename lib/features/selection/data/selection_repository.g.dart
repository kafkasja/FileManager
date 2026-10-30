// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selection_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(selectionRepository)
final selectionRepositoryProvider = SelectionRepositoryProvider._();

final class SelectionRepositoryProvider
    extends
        $FunctionalProvider<
          SelectionRepository,
          SelectionRepository,
          SelectionRepository
        >
    with $Provider<SelectionRepository> {
  SelectionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectionRepositoryHash();

  @$internal
  @override
  $ProviderElement<SelectionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SelectionRepository create(Ref ref) {
    return selectionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SelectionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SelectionRepository>(value),
    );
  }
}

String _$selectionRepositoryHash() =>
    r'8c76614bfa13d20e7fa40c2706cb5800fb9c9ca6';
