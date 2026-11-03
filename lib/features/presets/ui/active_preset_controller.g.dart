// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_preset_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Switching presets (TASK-P6). Loading while a switch runs; an error
/// (e.g. [PresetSwitchBlocked]) leaves the current preset active.

@ProviderFor(ActivePresetController)
final activePresetControllerProvider = ActivePresetControllerProvider._();

/// Switching presets (TASK-P6). Loading while a switch runs; an error
/// (e.g. [PresetSwitchBlocked]) leaves the current preset active.
final class ActivePresetControllerProvider
    extends $AsyncNotifierProvider<ActivePresetController, void> {
  /// Switching presets (TASK-P6). Loading while a switch runs; an error
  /// (e.g. [PresetSwitchBlocked]) leaves the current preset active.
  ActivePresetControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activePresetControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activePresetControllerHash();

  @$internal
  @override
  ActivePresetController create() => ActivePresetController();
}

String _$activePresetControllerHash() =>
    r'00cf4abf60b9fa701243fb190e528206ef75735b';

/// Switching presets (TASK-P6). Loading while a switch runs; an error
/// (e.g. [PresetSwitchBlocked]) leaves the current preset active.

abstract class _$ActivePresetController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
