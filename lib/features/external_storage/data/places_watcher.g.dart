// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'places_watcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Lives as long as the app (the shell watches it): hides the index rows
/// of detached volumes, scans mounted ones, and publishes [ExternalNotice]s.

@ProviderFor(placesWatcher)
final placesWatcherProvider = PlacesWatcherProvider._();

/// Lives as long as the app (the shell watches it): hides the index rows
/// of detached volumes, scans mounted ones, and publishes [ExternalNotice]s.

final class PlacesWatcherProvider
    extends $FunctionalProvider<PlacesWatcher, PlacesWatcher, PlacesWatcher>
    with $Provider<PlacesWatcher> {
  /// Lives as long as the app (the shell watches it): hides the index rows
  /// of detached volumes, scans mounted ones, and publishes [ExternalNotice]s.
  PlacesWatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placesWatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placesWatcherHash();

  @$internal
  @override
  $ProviderElement<PlacesWatcher> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlacesWatcher create(Ref ref) {
    return placesWatcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlacesWatcher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlacesWatcher>(value),
    );
  }
}

String _$placesWatcherHash() => r'df494dd09add2543f67c587f0d114f5af110a161';
