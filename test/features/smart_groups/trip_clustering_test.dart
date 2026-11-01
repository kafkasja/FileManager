import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/smart_groups/domain/geo.dart';
import 'package:kfm/features/smart_groups/domain/trip_clustering.dart';

const home = GeoPoint(52.37, 4.90);

/// [perDay] photos per day for [days] days from [start] (local), 9:00–21:00.
List<TimedPoint> days(
  String prefix,
  DateTime start,
  int days, {
  int perDay = 10,
  GeoPoint? at,
}) => [
  for (var d = 0; d < days; d++)
    for (var i = 0; i < perDay; i++)
      TimedPoint(
        '$prefix-$d-${i.toString().padLeft(2, '0')}',
        start
            .add(Duration(days: d, hours: 9 + i * 12 ~/ perDay))
            .millisecondsSinceEpoch,
        lat: at?.lat,
        lng: at?.lng,
      ),
];

void main() {
  test('constants', () {
    expect(kTripGap, const Duration(hours: 18));
    expect(kTripMinPhotos, 15);
    expect(kTripMinDistanceKm, 50);
    expect(kTripMinDays, 2);
  });

  test('3-day holiday 200 km from home = one trip with its date range', () {
    // ~200 km south-east of Amsterdam.
    const away = GeoPoint(51, 6.5);
    expect(haversineKm(home, away), closeTo(180, 30));
    final atHome = days('h', DateTime(2026, 6), 1, perDay: 20, at: home);
    final trip = days('t', DateTime(2026, 7, 10), 3, at: away);
    final after = days('a', DateTime(2026, 8), 1, perDay: 20, at: home);
    final result = clusterTrips([...after, ...trip, ...atHome], home: home);
    expect(result, hasLength(1));
    final t = result.single;
    expect(t.memberIds, hasLength(30));
    expect(DateTime.fromMillisecondsSinceEpoch(t.startAtMs).day, 10);
    expect(DateTime.fromMillisecondsSinceEpoch(t.endAtMs).day, 12);
    expect(t.newestId, 't-2-09');
    expect(t.center, away);
  });

  test('a cluster near home is no trip even when it spans days', () {
    final weekend = days('w', DateTime(2026, 7, 4), 2, at: home);
    expect(clusterTrips(weekend, home: home), isEmpty);
  });

  test('without GPS the days rule applies', () {
    final twoDays = days('d', DateTime(2026, 5), 2);
    expect(clusterTrips(twoDays), hasLength(1));
    final oneDay = days('o', DateTime(2026, 5), 1, perDay: 30);
    expect(clusterTrips(oneDay), isEmpty);
  });

  test('fewer than 15 photos is no trip', () {
    final small = days('s', DateTime(2026, 5), 2, perDay: 7);
    expect(clusterTrips(small), isEmpty);
  });

  test('a gap over 18 h splits clusters', () {
    final a = days('a', DateTime(2026, 5), 2);
    final b = days('b', DateTime(2026, 5, 5), 2);
    expect(clusterTrips([...a, ...b]), hasLength(2));
  });

  test('months of daily photos without GPS are not one trip', () {
    final daily = days('x', DateTime(2026), 60);
    expect(clusterTrips(daily), isEmpty);
  });

  test('calendarDays counts local dates', () {
    final a = DateTime(2026, 3, 1, 23).millisecondsSinceEpoch;
    final b = DateTime(2026, 3, 2, 1).millisecondsSinceEpoch;
    expect(calendarDays(a, a), 1);
    expect(calendarDays(a, b), 2);
  });
}
