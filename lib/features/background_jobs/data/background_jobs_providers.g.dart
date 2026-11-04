// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_jobs_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every job source merged (TASK-X8): Wi-Fi transfers, U2 local jobs and
/// uploads other devices make into this one. Lives with the app.

@ProviderFor(jobProgressAggregator)
final jobProgressAggregatorProvider = JobProgressAggregatorProvider._();

/// Every job source merged (TASK-X8): Wi-Fi transfers, U2 local jobs and
/// uploads other devices make into this one. Lives with the app.

final class JobProgressAggregatorProvider
    extends
        $FunctionalProvider<
          JobProgressAggregator,
          JobProgressAggregator,
          JobProgressAggregator
        >
    with $Provider<JobProgressAggregator> {
  /// Every job source merged (TASK-X8): Wi-Fi transfers, U2 local jobs and
  /// uploads other devices make into this one. Lives with the app.
  JobProgressAggregatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jobProgressAggregatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jobProgressAggregatorHash();

  @$internal
  @override
  $ProviderElement<JobProgressAggregator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  JobProgressAggregator create(Ref ref) {
    return jobProgressAggregator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JobProgressAggregator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JobProgressAggregator>(value),
    );
  }
}

String _$jobProgressAggregatorHash() =>
    r'6f370d55a74773eb87e3c759c2da631bed82d2cd';

/// Running and paused jobs (in-app indicator, desktop status bar).

@ProviderFor(jobsSnapshot)
final jobsSnapshotProvider = JobsSnapshotProvider._();

/// Running and paused jobs (in-app indicator, desktop status bar).

final class JobsSnapshotProvider
    extends
        $FunctionalProvider<
          AsyncValue<JobsSnapshot>,
          JobsSnapshot,
          Stream<JobsSnapshot>
        >
    with $FutureModifier<JobsSnapshot>, $StreamProvider<JobsSnapshot> {
  /// Running and paused jobs (in-app indicator, desktop status bar).
  JobsSnapshotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jobsSnapshotProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jobsSnapshotHash();

  @$internal
  @override
  $StreamProviderElement<JobsSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<JobsSnapshot> create(Ref ref) {
    return jobsSnapshot(ref);
  }
}

String _$jobsSnapshotHash() => r'd235e9786ab93037ea41378a084a2c869a1b4a94';

/// [jobsSnapshot] as a value (empty while loading).

@ProviderFor(currentJobs)
final currentJobsProvider = CurrentJobsProvider._();

/// [jobsSnapshot] as a value (empty while loading).

final class CurrentJobsProvider
    extends $FunctionalProvider<JobsSnapshot, JobsSnapshot, JobsSnapshot>
    with $Provider<JobsSnapshot> {
  /// [jobsSnapshot] as a value (empty while loading).
  CurrentJobsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentJobsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentJobsHash();

  @$internal
  @override
  $ProviderElement<JobsSnapshot> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  JobsSnapshot create(Ref ref) {
    return currentJobs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JobsSnapshot value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JobsSnapshot>(value),
    );
  }
}

String _$currentJobsHash() => r'0e7f8f42a85d3d34b3fe7d526d00d04f1d9af879';

/// Language-dependent formatting for notices: KFM's language, place names
/// from U1.

@ProviderFor(noticeFormat)
final noticeFormatProvider = NoticeFormatProvider._();

/// Language-dependent formatting for notices: KFM's language, place names
/// from U1.

final class NoticeFormatProvider
    extends $FunctionalProvider<NoticeFormat, NoticeFormat, NoticeFormat>
    with $Provider<NoticeFormat> {
  /// Language-dependent formatting for notices: KFM's language, place names
  /// from U1.
  NoticeFormatProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noticeFormatProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noticeFormatHash();

  @$internal
  @override
  $ProviderElement<NoticeFormat> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NoticeFormat create(Ref ref) {
    return noticeFormat(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoticeFormat value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoticeFormat>(value),
    );
  }
}

String _$noticeFormatHash() => r'cd32b280764df5c29db39522ce49d05ade31f3ef';

/// The platform side of [backgroundPresence].

@ProviderFor(presencePort)
final presencePortProvider = PresencePortProvider._();

/// The platform side of [backgroundPresence].

final class PresencePortProvider
    extends $FunctionalProvider<PresencePort, PresencePort, PresencePort>
    with $Provider<PresencePort> {
  /// The platform side of [backgroundPresence].
  PresencePortProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'presencePortProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$presencePortHash();

  @$internal
  @override
  $ProviderElement<PresencePort> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PresencePort create(Ref ref) {
    return presencePort(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PresencePort value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PresencePort>(value),
    );
  }
}

String _$presencePortHash() => r'f9ff33e3001aee1faa55451c1c737b418c1b972d';

/// TASK-X8: what keeps KFM alive in the background and the notification /
/// tray / taskbar that shows it. Watched by `App`; re-renders when KFM's
/// language changes; jobs paused by Android's time limit continue when KFM
/// is back in front.

@ProviderFor(backgroundPresence)
final backgroundPresenceProvider = BackgroundPresenceProvider._();

/// TASK-X8: what keeps KFM alive in the background and the notification /
/// tray / taskbar that shows it. Watched by `App`; re-renders when KFM's
/// language changes; jobs paused by Android's time limit continue when KFM
/// is back in front.

final class BackgroundPresenceProvider
    extends
        $FunctionalProvider<
          BackgroundPresence,
          BackgroundPresence,
          BackgroundPresence
        >
    with $Provider<BackgroundPresence> {
  /// TASK-X8: what keeps KFM alive in the background and the notification /
  /// tray / taskbar that shows it. Watched by `App`; re-renders when KFM's
  /// language changes; jobs paused by Android's time limit continue when KFM
  /// is back in front.
  BackgroundPresenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundPresenceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundPresenceHash();

  @$internal
  @override
  $ProviderElement<BackgroundPresence> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackgroundPresence create(Ref ref) {
    return backgroundPresence(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundPresence value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundPresence>(value),
    );
  }
}

String _$backgroundPresenceHash() =>
    r'ad47743aac47f118c3eb11070552d5fbe7177a95';
