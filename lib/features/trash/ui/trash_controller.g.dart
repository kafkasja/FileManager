// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trash_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Trash page (TASK-D5): system trash and pending folder on one page.

@ProviderFor(TrashController)
final trashControllerProvider = TrashControllerProvider._();

/// Trash page (TASK-D5): system trash and pending folder on one page.
final class TrashControllerProvider
    extends $AsyncNotifierProvider<TrashController, TrashViewState> {
  /// Trash page (TASK-D5): system trash and pending folder on one page.
  TrashControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trashControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trashControllerHash();

  @$internal
  @override
  TrashController create() => TrashController();
}

String _$trashControllerHash() => r'e4b78a18d8618742dba703ed11a649c7bc17eb89';

/// Trash page (TASK-D5): system trash and pending folder on one page.

abstract class _$TrashController extends $AsyncNotifier<TrashViewState> {
  FutureOr<TrashViewState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TrashViewState>, TrashViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TrashViewState>, TrashViewState>,
              AsyncValue<TrashViewState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
