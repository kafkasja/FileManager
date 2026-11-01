import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/smart_groups/domain/geo.dart';
import 'package:kfm/features/smart_groups/domain/place_clustering.dart';

/// [n] points within ~[spreadM] metres of (lat, lng).
List<PlacePoint> blob(
  String prefix,
  double lat,
  double lng,
  int n, {
  double spreadM = 200,
}) => [
  for (var i = 0; i < n; i++)
    PlacePoint(
      '$prefix${i.toString().padLeft(4, '0')}',
      lat + (i % 7 - 3) * spreadM / 3 / 111000,
      lng + (i % 5 - 2) * spreadM / 2 / 111000,
    ),
];

void main() {
  test('constants', () {
    expect(kPlaceEpsKm, 1.0);
    expect(kPlaceMinPoints, 10);
    expect(kHideLargestPlace, isTrue);
  });

  test('haversine: Amsterdam–Paris is about 430 km', () {
    final d = haversineKm(
      const GeoPoint(52.3676, 4.9041),
      const GeoPoint(48.8566, 2.3522),
    );
    expect(d, closeTo(430, 5));
  });

  test('empty input → no clusters', () {
    expect(clusterPlaces(const []), isEmpty);
  });

  test('two places, largest first; noise left out', () {
    final home = blob('h', 52.37, 4.90, 50);
    final paris = blob('p', 48.85, 2.35, 20);
    const lone = [PlacePoint('x', 40, -3)];
    final clusters = clusterPlaces([...paris, ...lone, ...home]);
    expect(clusters, hasLength(2));
    expect(clusters[0].size, 50);
    expect(clusters[1].size, 20);
    expect(clusters[1].center.lat, closeTo(48.85, 0.01));
    expect(clusters.expand((c) => c.memberIds), isNot(contains('x')));
  });

  test('fewer than minPoints → noise', () {
    expect(clusterPlaces(blob('a', 10, 10, 9)), isEmpty);
    expect(clusterPlaces(blob('a', 10, 10, 10)), hasLength(1));
  });

  test('many photos at one spot (weighted snap) form one cluster', () {
    final same = [
      for (var i = 0; i < 2000; i++) PlacePoint('s$i', 51.5, -0.12),
    ];
    final clusters = clusterPlaces(same);
    expect(clusters.single.size, 2000);
  });

  test('points 3 km apart are different places', () {
    final a = blob('a', 45, 7, 15, spreadM: 100);
    final b = blob('b', 45.027, 7, 15, spreadM: 100); // ~3 km north
    expect(clusterPlaces([...a, ...b]), hasLength(2));
  });

  test('a chain of points < 1 km apart joins (density reachable)', () {
    final points = [
      for (var i = 0; i < 30; i++) PlacePoint('c$i', 45 + i * 0.001, 7),
    ];
    // ~111 m steps over ~3.2 km: each point has ≥ 10 within 1 km.
    expect(clusterPlaces(points), hasLength(1));
  });

  test('high latitude: neighbours across longitude cells are found', () {
    final points = [
      for (var i = 0; i < 12; i++) PlacePoint('n$i', 69.65, 18.95 + i * 0.002),
    ];
    // ~77 m per step at 69.65°N, spread over several 0.01° cells.
    expect(clusterPlaces(points).single.size, 12);
  });

  test('mostCommonCell picks the busiest 0.1° cell', () {
    final home = mostCommonCell(const [
      GeoPoint(52.31, 4.91),
      GeoPoint(52.33, 4.95),
      GeoPoint(48.8, 2.3),
    ]);
    expect(home!.lat, closeTo(52.35, 1e-9));
    expect(home.lng, closeTo(4.95, 1e-9));
    expect(mostCommonCell(const []), isNull);
  });

  test('50k points cluster in well under the isolate budget', () {
    final points = <PlacePoint>[];
    for (var c = 0; c < 50; c++) {
      points.addAll(blob('c$c-', 40 + c * 0.1, 10, 1000, spreadM: 500));
    }
    final sw = Stopwatch()..start();
    final clusters = clusterPlaces(points);
    expect(clusters, hasLength(50));
    expect(sw.elapsed, lessThan(const Duration(seconds: 5)));
  });
}
