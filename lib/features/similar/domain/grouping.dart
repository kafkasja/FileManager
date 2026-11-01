import 'package:flutter/foundation.dart';
import 'package:kfm/features/similar/domain/best_pick.dart';
import 'package:kfm/features/similar/domain/dhash.dart';

/// One `ok` image as the grouping sees it (sendable to an isolate).
@immutable
class SignalPoint {
  const new({
    required this.fileId,
    required this.sortDateMs,
    required this.dHash,
    required this.blurScore,
    required this.sizeBytes,
    this.width,
    this.height,
  });

  final String fileId;

  /// takenAt ?? modifiedAt (media_index.sort_date_ms).
  final int sortDateMs;
  final int dHash;
  final double blurScore;
  final int? width;
  final int? height;
  final int sizeBytes;
}

/// `similar.strictness` → max Hamming distance (unknown = normal).
int maxDistanceFor(String strictness) => switch (strictness) {
  'loose' => 14,
  'strict' => 6,
  _ => 10,
};

/// Near-duplicate groups: pairs within [window] of each other (sortDateMs)
/// with a Hamming distance ≤ [maxDistance] are joined (union-find, so
/// chains join too). Groups of ≥ 2, members best first ([compareBest]
/// semantics), groups ordered newest member first. Pure; runs in an isolate.
List<List<String>> groupSimilar(
  List<SignalPoint> points, {
  required int maxDistance,
  Duration window = const Duration(minutes: 10),
}) {
  final sorted = [...points]
    ..sort((a, b) => a.sortDateMs.compareTo(b.sortDateMs));
  final n = sorted.length;
  final parent = List<int>.generate(n, (i) => i);
  int find(int i) {
    var root = i;
    while (parent[root] != root) {
      root = parent[root];
    }
    var c = i;
    while (parent[c] != root) {
      final next = parent[c];
      parent[c] = root;
      c = next;
    }
    return root;
  }

  final windowMs = window.inMilliseconds;
  for (var i = 0; i < n; i++) {
    final a = sorted[i];
    for (var j = i + 1; j < n; j++) {
      final b = sorted[j];
      if (b.sortDateMs - a.sortDateMs > windowMs) break;
      if (hammingDistance(a.dHash, b.dHash) <= maxDistance) {
        final ra = find(i);
        final rb = find(j);
        if (ra != rb) parent[rb] = ra;
      }
    }
  }

  final byRoot = <int, List<SignalPoint>>{};
  for (var i = 0; i < n; i++) {
    (byRoot[find(i)] ??= []).add(sorted[i]);
  }
  final keyed =
      [
        for (final g in byRoot.values)
          if (g.length >= 2)
            (
              g.map((p) => p.sortDateMs).reduce((a, b) => a > b ? a : b),
              g..sort(_compareBest),
            ),
      ]..sort((a, b) {
        final d = b.$1.compareTo(a.$1);
        return d != 0 ? d : a.$2.first.fileId.compareTo(b.$2.first.fileId);
      });
  return [
    for (final (_, g) in keyed) [for (final p in g) p.fileId],
  ];
}

int _compareBest(SignalPoint a, SignalPoint b) {
  final c = compareBestValues(
    blurA: a.blurScore,
    blurB: b.blurScore,
    pixelsA: (a.width ?? 0) * (a.height ?? 0),
    pixelsB: (b.width ?? 0) * (b.height ?? 0),
    sizeA: a.sizeBytes,
    sizeB: b.sizeBytes,
    dateMsA: a.sortDateMs,
    dateMsB: b.sortDateMs,
  );
  return c != 0 ? c : a.fileId.compareTo(b.fileId);
}
