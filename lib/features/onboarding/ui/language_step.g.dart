// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_step.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// TASK-E2: whether the first-launch language question still has to be
/// asked. Existing installs (tutorial seen or anything swiped) are marked
/// asked silently, like L3's existing-install check. Null while loading.

@ProviderFor(LanguageStepController)
final languageStepControllerProvider = LanguageStepControllerProvider._();

/// TASK-E2: whether the first-launch language question still has to be
/// asked. Existing installs (tutorial seen or anything swiped) are marked
/// asked silently, like L3's existing-install check. Null while loading.
final class LanguageStepControllerProvider
    extends $AsyncNotifierProvider<LanguageStepController, bool> {
  /// TASK-E2: whether the first-launch language question still has to be
  /// asked. Existing installs (tutorial seen or anything swiped) are marked
  /// asked silently, like L3's existing-install check. Null while loading.
  LanguageStepControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'languageStepControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$languageStepControllerHash();

  @$internal
  @override
  LanguageStepController create() => LanguageStepController();
}

String _$languageStepControllerHash() =>
    r'e45f5b7b592db937c907e2434c49c79b45262bb7';

/// TASK-E2: whether the first-launch language question still has to be
/// asked. Existing installs (tutorial seen or anything swiped) are marked
/// asked silently, like L3's existing-install check. Null while loading.

abstract class _$LanguageStepController extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
