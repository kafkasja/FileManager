import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/browse/domain/time_clusters.dart';

const _w5 = Duration(seconds: 5);

List<List<String>> _ids(List<TimeCluster> clusters) => [
  for (final c in clusters) c.fileIds,
];

void main() {
  test('empty input gives no clusters', () {
    expect(clusterByTime(const [], _w5), isEmpty);
  });

  test('all singles are dropped', () {
    expect(
      clusterByTime(const [('a', 0), ('b', 10000), ('c', 20000)], _w5),
      isEmpty,
    );
  });

  test('a gap equal to the window joins', () {
    expect(_ids(clusterByTime(const [('a', 0), ('b', 5000)], _w5)), [
      ['a', 'b'],
    ]);
  });

  test('a gap greater than the window splits', () {
    expect(clusterByTime(const [('a', 0), ('b', 5001)], _w5), isEmpty);
  });

  test('chaining: A–B 4 s, B–C 4 s is one group of 3', () {
    final clusters = clusterByTime(const [
      ('a', 0),
      ('b', 4000),
      ('c', 8000),
    ], _w5);
    expect(_ids(clusters), [
      ['a', 'b', 'c'],
    ]);
    expect(clusters.single.size, 3);
  });

  test('singles around groups are dropped; start/end are set', () {
    final clusters = clusterByTime(const [
      ('s1', 0),
      ('a', 100000),
      ('b', 102000),
      ('c', 104000),
      ('s2', 200000),
      ('d', 300000),
      ('e', 300000),
      ('s3', 400000),
    ], _w5);
    expect(_ids(clusters), [
      ['a', 'b', 'c'],
      ['d', 'e'],
    ]);
    expect(clusters[0].startMs, 100000);
    expect(clusters[0].endMs, 104000);
    expect(clusters[1].startMs, 300000);
    expect(clusters[1].endMs, 300000);
  });

  test('result and file ids are unmodifiable', () {
    final clusters = clusterByTime(const [('a', 0), ('b', 1)], _w5);
    expect(() => clusters.add(clusters.first), throwsUnsupportedError);
    expect(() => clusters.first.fileIds.add('x'), throwsUnsupportedError);
  });

  test('clampWindow keeps 1 s … 24 h', () {
    expect(clampWindow(0), 1);
    expect(clampWindow(-3), 1);
    expect(clampWindow(5), 5);
    expect(clampWindow(600), 600);
    expect(clampWindow(3600), 3600);
    expect(clampWindow(99999), 86400);
  });

  test('50,000 items cluster in under 50 ms', () {
    // Pairs 1 s apart, pairs 60 s apart: 25,000 groups of 2.
    final items = [
      for (var i = 0; i < 50000; i++)
        ('id$i', (i ~/ 2) * 60000 + (i.isOdd ? 1000 : 0)),
    ];
    clusterByTime(items, _w5); // warm up
    final sw = Stopwatch()..start();
    final clusters = clusterByTime(items, _w5);
    sw.stop();
    // ignore: avoid_print, reports the timing for the task log.
    print('clusterByTime(50,000): ${sw.elapsedMicroseconds} µs');
    expect(clusters, hasLength(25000));
    expect(sw.elapsedMilliseconds, lessThan(50));
  });
}
