// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_change_tracker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The live-sync tracker of the sharing runs (keepAlive: its token cache
/// and observers outlive any one screen). The share screen calls
/// [ShareChangeTracker.start] when the server runs and
/// [ShareChangeTracker.stop] when it stops.

@ProviderFor(shareChangeTracker)
final shareChangeTrackerProvider = ShareChangeTrackerProvider._();

/// The live-sync tracker of the sharing runs (keepAlive: its token cache
/// and observers outlive any one screen). The share screen calls
/// [ShareChangeTracker.start] when the server runs and
/// [ShareChangeTracker.stop] when it stops.

final class ShareChangeTrackerProvider
    extends
        $FunctionalProvider<
          ShareChangeTracker,
          ShareChangeTracker,
          ShareChangeTracker
        >
    with $Provider<ShareChangeTracker> {
  /// The live-sync tracker of the sharing runs (keepAlive: its token cache
  /// and observers outlive any one screen). The share screen calls
  /// [ShareChangeTracker.start] when the server runs and
  /// [ShareChangeTracker.stop] when it stops.
  ShareChangeTrackerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareChangeTrackerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareChangeTrackerHash();

  @$internal
  @override
  $ProviderElement<ShareChangeTracker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShareChangeTracker create(Ref ref) {
    return shareChangeTracker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareChangeTracker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareChangeTracker>(value),
    );
  }
}

String _$shareChangeTrackerHash() =>
    r'ae066113e14b938c92e265c842c010d0d1663e0e';
