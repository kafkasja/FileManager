import 'dart:math' as math;

import 'package:kfm/features/smart_groups/domain/geo.dart';
import 'package:meta/meta.dart';

/// DBSCAN radius.
const double kPlaceEpsKm = 1;

/// DBSCAN minimum points (photos) for a core point.
const int kPlaceMinPoints = 10;

/// The largest cluster is "home": not shown in Places, used for trips.
const bool kHideLargestPlace = true;

/// Grid cell in degrees for the neighbour search.
const double _cellDeg = 0.01;

/// Photos closer than this (~11 m, 1e-4°) are merged into one weighted
/// point before clustering, so 30k photos taken at home don't make the
/// neighbour search quadratic. Far below [kPlaceEpsKm], so results match.
const double _snapDeg = 1e-4;

/// One photo with GPS.
@immutable
class PlacePoint {
  const new(this.id, this.lat, this.lng);

  final String id;
  final double lat;
  final double lng;
}

@immutable
class PlaceCluster {
  const new({required this.memberIds, required this.center});

  final List<String> memberIds;

  /// Mean of the members' coordinates.
  final GeoPoint center;

  int get size => memberIds.length;
}

class _Snap {
  new(this.lat, this.lng);

  double lat;
  double lng;
  final List<String> ids = [];
  int label = -2; // -2 unvisited, -1 noise, >= 0 cluster
}

/// DBSCAN (haversine, [kPlaceEpsKm], [kPlaceMinPoints]) over [points].
/// Returns every cluster, largest first (ties: earliest member id), noise
/// left out. Callers hide the first one when [kHideLargestPlace].
List<PlaceCluster> clusterPlaces(
  List<PlacePoint> points, {
  double epsKm = kPlaceEpsKm,
  int minPoints = kPlaceMinPoints,
}) {
  if (points.isEmpty) return const [];
  // 1. Snap near-identical coordinates into weighted points.
  final snaps = <(int, int), _Snap>{};
  for (final p in points) {
    final key = ((p.lat / _snapDeg).round(), (p.lng / _snapDeg).round());
    final s = snaps.putIfAbsent(key, () => _Snap(0, 0));
    final n = s.ids.length;
    s
      ..lat = (s.lat * n + p.lat) / (n + 1)
      ..lng = (s.lng * n + p.lng) / (n + 1)
      ..ids.add(p.id);
  }
  final nodes = snaps.values.toList();
  // 2. Grid for neighbour search.
  final grid = <(int, int), List<int>>{};
  (int, int) cellOf(_Snap s) =>
      ((s.lat / _cellDeg).floor(), (s.lng / _cellDeg).floor());
  for (final (i, s) in nodes.indexed) {
    (grid[cellOf(s)] ??= []).add(i);
  }
  final latCells = (epsKm / 111.0 / _cellDeg).ceil();
  List<int> neighbours(int i) {
    final s = nodes[i];
    final (cy, cx) = cellOf(s);
    // Longitude degrees shrink towards the poles.
    final cosLat = math.cos(
      math.min(89, s.lat.abs() + latCells * _cellDeg) * math.pi / 180,
    );
    final lngCells = (epsKm / (111.0 * cosLat) / _cellDeg).ceil();
    final here = GeoPoint(s.lat, s.lng);
    return [
      for (var dy = -latCells; dy <= latCells; dy++)
        for (var dx = -lngCells; dx <= lngCells; dx++)
          for (final j in grid[(cy + dy, cx + dx)] ?? const <int>[])
            if (haversineKm(here, GeoPoint(nodes[j].lat, nodes[j].lng)) <=
                epsKm)
              j,
    ];
  }

  int weight(List<int> ids) =>
      ids.fold(0, (sum, j) => sum + nodes[j].ids.length);

  // 3. DBSCAN over the weighted points.
  var clusterCount = 0;
  for (var i = 0; i < nodes.length; i++) {
    if (nodes[i].label != -2) continue;
    final seeds = neighbours(i);
    if (weight(seeds) < minPoints) {
      nodes[i].label = -1;
      continue;
    }
    final c = clusterCount++;
    nodes[i].label = c;
    final queue = [...seeds];
    for (var q = 0; q < queue.length; q++) {
      final j = queue[q];
      if (nodes[j].label == -1) nodes[j].label = c; // border point
      if (nodes[j].label != -2) continue;
      nodes[j].label = c;
      final more = neighbours(j);
      if (weight(more) >= minPoints) queue.addAll(more);
    }
  }
  // 4. Collect.
  final members = List.generate(clusterCount, (_) => <_Snap>[]);
  for (final s in nodes) {
    if (s.label >= 0) members[s.label].add(s);
  }
  final clusters =
      [
        for (final m in members)
          if (m.isNotEmpty) _toCluster(m),
      ]..sort((a, b) {
        final bySize = b.size.compareTo(a.size);
        return bySize != 0
            ? bySize
            : a.memberIds.first.compareTo(b.memberIds.first);
      });
  return clusters;
}

PlaceCluster _toCluster(List<_Snap> snaps) {
  var lat = 0.0;
  var lng = 0.0;
  final ids = <String>[];
  for (final s in snaps) {
    lat += s.lat * s.ids.length;
    lng += s.lng * s.ids.length;
    ids.addAll(s.ids);
  }
  ids.sort();
  return PlaceCluster(
    memberIds: ids,
    center: GeoPoint(lat / ids.length, lng / ids.length),
  );
}

/// The home reference without places: centre of the most common 0.1° cell.
GeoPoint? mostCommonCell(Iterable<GeoPoint> points) {
  final counts = <(int, int), int>{};
  for (final p in points) {
    final key = ((p.lat * 10).floor(), (p.lng * 10).floor());
    counts[key] = (counts[key] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  final best = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
  return GeoPoint((best.key.$1 + 0.5) / 10, (best.key.$2 + 0.5) / 10);
}
