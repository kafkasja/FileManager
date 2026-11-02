// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volume_activity_tracker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Counts KFM's own work per removable place and refuses new work while a
/// place is being ejected (TASK-U3). Internal storage is never tracked.

@ProviderFor(VolumeActivityTracker)
final volumeActivityTrackerProvider = VolumeActivityTrackerProvider._();

/// Counts KFM's own work per removable place and refuses new work while a
/// place is being ejected (TASK-U3). Internal storage is never tracked.
final class VolumeActivityTrackerProvider
    extends $NotifierProvider<VolumeActivityTracker, VolumeActivity> {
  /// Counts KFM's own work per removable place and refuses new work while a
  /// place is being ejected (TASK-U3). Internal storage is never tracked.
  VolumeActivityTrackerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'volumeActivityTrackerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$volumeActivityTrackerHash();

  @$internal
  @override
  VolumeActivityTracker create() => VolumeActivityTracker();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VolumeActivity value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VolumeActivity>(value),
    );
  }
}

String _$volumeActivityTrackerHash() =>
    r'cc3e775d3ce3c8c279df4253a74ee8edcba69a10';

/// Counts KFM's own work per removable place and refuses new work while a
/// place is being ejected (TASK-U3). Internal storage is never tracked.

abstract class _$VolumeActivityTracker extends $Notifier<VolumeActivity> {
  VolumeActivity build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VolumeActivity, VolumeActivity>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VolumeActivity, VolumeActivity>,
              VolumeActivity,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
