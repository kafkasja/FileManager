import 'package:kfm/features/smart_groups/domain/geo.dart';
import 'package:meta/meta.dart';

/// A new cluster starts after a gap longer than this.
const Duration kTripGap = Duration(hours: 18);

/// Fewer photos = not a trip.
const int kTripMinPhotos = 15;

/// With GPS: the cluster's median point is at least this far from home.
const double kTripMinDistanceKm = 50;

/// Without GPS: the cluster spans at least this many calendar days (local).
const int kTripMinDays = 2;

/// Without GPS: longer spans are everyday life photographed daily, not a
/// trip (C5 deviation: the plan has no upper bound).
const int kTripMaxDays = 30;

/// One image on the timeline; [lat]/[lng] null without GPS or access.
@immutable
class TimedPoint {
  const new(this.id, this.sortDateMs, {this.lat, this.lng});

  final String id;
  final int sortDateMs;
  final double? lat;
  final double? lng;
}

@immutable
class TripCluster {
  const new({
    required this.memberIds,
    required this.startAtMs,
    required this.endAtMs,
    required this.newestId,
    this.center,
  });

  /// Sorted by id (matching input).
  final List<String> memberIds;
  final int startAtMs;
  final int endAtMs;
  final String newestId;

  /// Median GPS point of the members that have one.
  final GeoPoint? center;
}

/// Splits the timeline at gaps > [kTripGap]; a cluster is a trip when it
/// has ≥ [kTripMinPhotos] photos and either its median GPS point is
/// ≥ [kTripMinDistanceKm] from [home] (members with GPS and a home known),
/// or (no GPS to judge by) it spans [kTripMinDays]…[kTripMaxDays] local
/// calendar days. Oldest first.
List<TripCluster> clusterTrips(List<TimedPoint> points, {GeoPoint? home}) {
  if (points.isEmpty) return const [];
  final sorted = [...points]
    ..sort((a, b) {
      final byDate = a.sortDateMs.compareTo(b.sortDateMs);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
  final trips = <TripCluster>[];
  var run = <TimedPoint>[sorted.first];
  void close() {
    if (_isTrip(run, home)) trips.add(_toTrip(run));
  }

  for (final p in sorted.skip(1)) {
    if (p.sortDateMs - run.last.sortDateMs > kTripGap.inMilliseconds) {
      close();
      run = [p];
    } else {
      run.add(p);
    }
  }
  close();
  return trips;
}

GeoPoint? _medianPoint(List<TimedPoint> run) {
  final gps = [
    for (final p in run)
      if (p.lat != null && p.lng != null) p,
  ];
  if (gps.isEmpty) return null;
  return GeoPoint(
    median(gps.map((p) => p.lat!)),
    median(gps.map((p) => p.lng!)),
  );
}

bool _isTrip(List<TimedPoint> run, GeoPoint? home) {
  if (run.length < kTripMinPhotos) return false;
  final center = _medianPoint(run);
  if (center != null && home != null) {
    return haversineKm(center, home) >= kTripMinDistanceKm;
  }
  final days = calendarDays(run.first.sortDateMs, run.last.sortDateMs);
  return days >= kTripMinDays && days <= kTripMaxDays;
}

/// Local calendar days covered by [startMs]…[endMs] (same day = 1).
int calendarDays(int startMs, int endMs) {
  final s = DateTime.fromMillisecondsSinceEpoch(startMs);
  final e = DateTime.fromMillisecondsSinceEpoch(endMs);
  // UTC dates so DST changes don't shorten a day.
  final sd = DateTime.utc(s.year, s.month, s.day);
  final ed = DateTime.utc(e.year, e.month, e.day);
  return ed.difference(sd).inDays + 1;
}

TripCluster _toTrip(List<TimedPoint> run) => TripCluster(
  memberIds: [for (final p in run) p.id]..sort(),
  startAtMs: run.first.sortDateMs,
  endAtMs: run.last.sortDateMs,
  newestId: run.last.id,
  center: _medianPoint(run),
);
