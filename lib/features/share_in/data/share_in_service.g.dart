// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_in_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Null off Android (and in tests unless overridden).

@ProviderFor(shareInPlatform)
final shareInPlatformProvider = ShareInPlatformProvider._();

/// Null off Android (and in tests unless overridden).

final class ShareInPlatformProvider
    extends
        $FunctionalProvider<
          ShareInPlatform?,
          ShareInPlatform?,
          ShareInPlatform?
        >
    with $Provider<ShareInPlatform?> {
  /// Null off Android (and in tests unless overridden).
  ShareInPlatformProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareInPlatformProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareInPlatformHash();

  @$internal
  @override
  $ProviderElement<ShareInPlatform?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ShareInPlatform? create(Ref ref) {
    return shareInPlatform(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareInPlatform? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareInPlatform?>(value),
    );
  }
}

String _$shareInPlatformHash() => r'aa8d434eca084d7daefd6afa74e7d91ad1481c01';

/// TASK-X1: the latest share into KFM. Takes Android's pending batch on
/// start (cold start) and whenever one is ready. Errors propagate.

@ProviderFor(PendingSharedBatch)
final pendingSharedBatchProvider = PendingSharedBatchProvider._();

/// TASK-X1: the latest share into KFM. Takes Android's pending batch on
/// start (cold start) and whenever one is ready. Errors propagate.
final class PendingSharedBatchProvider
    extends $NotifierProvider<PendingSharedBatch, ShareInState> {
  /// TASK-X1: the latest share into KFM. Takes Android's pending batch on
  /// start (cold start) and whenever one is ready. Errors propagate.
  PendingSharedBatchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingSharedBatchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingSharedBatchHash();

  @$internal
  @override
  PendingSharedBatch create() => PendingSharedBatch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareInState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareInState>(value),
    );
  }
}

String _$pendingSharedBatchHash() =>
    r'fa73eba8257ed950ad007048df5bc9577055bc0f';

/// TASK-X1: the latest share into KFM. Takes Android's pending batch on
/// start (cold start) and whenever one is ready. Errors propagate.

abstract class _$PendingSharedBatch extends $Notifier<ShareInState> {
  ShareInState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ShareInState, ShareInState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ShareInState, ShareInState>,
              ShareInState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Copy progress of a big item while a batch resolves.

@ProviderFor(ShareInProgressSink)
final shareInProgressSinkProvider = ShareInProgressSinkProvider._();

/// Copy progress of a big item while a batch resolves.
final class ShareInProgressSinkProvider
    extends $NotifierProvider<ShareInProgressSink, ShareInProgress?> {
  /// Copy progress of a big item while a batch resolves.
  ShareInProgressSinkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareInProgressSinkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareInProgressSinkHash();

  @$internal
  @override
  ShareInProgressSink create() => ShareInProgressSink();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareInProgress? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareInProgress?>(value),
    );
  }
}

String _$shareInProgressSinkHash() =>
    r'db14e228b922a4920dfa1b5b8cf211de8ce5c8f3';

/// Copy progress of a big item while a batch resolves.

abstract class _$ShareInProgressSink extends $Notifier<ShareInProgress?> {
  ShareInProgress? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ShareInProgress?, ShareInProgress?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ShareInProgress?, ShareInProgress?>,
              ShareInProgress?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// App start: removes shared-in copies older than 7 days (X1).

@ProviderFor(shareInCleanup)
final shareInCleanupProvider = ShareInCleanupProvider._();

/// App start: removes shared-in copies older than 7 days (X1).

final class ShareInCleanupProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// App start: removes shared-in copies older than 7 days (X1).
  ShareInCleanupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareInCleanupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareInCleanupHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return shareInCleanup(ref);
  }
}

String _$shareInCleanupHash() => r'd27c574b2e121651c9cbde206b583f2b6641ea23';
