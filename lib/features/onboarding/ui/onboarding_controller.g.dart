// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The first-time tutorial and one-time hints (TASK-L3), over two settings.
/// Writes go through the settings write queue (latest value wins); failures
/// surface on `dbWriteErrorsProvider`.

@ProviderFor(OnboardingController)
final onboardingControllerProvider = OnboardingControllerProvider._();

/// The first-time tutorial and one-time hints (TASK-L3), over two settings.
/// Writes go through the settings write queue (latest value wins); failures
/// surface on `dbWriteErrorsProvider`.
final class OnboardingControllerProvider
    extends $AsyncNotifierProvider<OnboardingController, OnboardingState> {
  /// The first-time tutorial and one-time hints (TASK-L3), over two settings.
  /// Writes go through the settings write queue (latest value wins); failures
  /// surface on `dbWriteErrorsProvider`.
  OnboardingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingControllerHash();

  @$internal
  @override
  OnboardingController create() => OnboardingController();
}

String _$onboardingControllerHash() =>
    r'6ae5e0a3814adce1a855654f85bd958c8d953958';

/// The first-time tutorial and one-time hints (TASK-L3), over two settings.
/// Writes go through the settings write queue (latest value wins); failures
/// surface on `dbWriteErrorsProvider`.

abstract class _$OnboardingController extends $AsyncNotifier<OnboardingState> {
  FutureOr<OnboardingState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<OnboardingState>, OnboardingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OnboardingState>, OnboardingState>,
              AsyncValue<OnboardingState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
