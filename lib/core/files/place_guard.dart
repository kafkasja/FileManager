/// Runs [op] while the place [placeId] counts as busy, or throws when the
/// place is being ejected (TASK-U3: `VolumeActivityTracker.run`). Lets
/// core code be tracked without depending on the feature.
typedef PlaceGuard = Future<T> Function<T>(
  String placeId,
  Future<T> Function() op,
);

/// No tracking (tests, the H2 worker isolate).
Future<T> unguarded<T>(String placeId, Future<T> Function() op) => op();

/// [PlaceGuard] for several places at once (`VolumeActivityTracker.runAll`).
typedef PlacesGuard = Future<T> Function<T>(
  Iterable<String> placeIds,
  Future<T> Function() op,
);

/// No tracking.
Future<T> unguardedAll<T>(Iterable<String> placeIds, Future<T> Function() op) =>
    op();
