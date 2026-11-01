/// Keeps smart group ids (and user titles) stable across recomputes
/// (TASK-C5 §5).
library;

/// An old group keeps its id when at least this share of its members is in
/// the new cluster…
const double kMatchKeptShare = 0.8;

/// …and at least this share of the new cluster was in it (so a group that
/// grows by a few photos keeps its id, but one swallowed by a much larger
/// cluster doesn't). Plain Jaccard ≥ 0.8 failed "add 10 photos to a renamed
/// 15-photo trip" (Jaccard 0.6).
const double kMatchNewShare = 0.5;

/// Jaccard similarity of two member sets.
double jaccard(Set<String> a, Set<String> b) {
  if (a.isEmpty && b.isEmpty) return 1;
  final inter = _intersection(a, b);
  return inter / (a.length + b.length - inter);
}

int _intersection(Set<String> a, Set<String> b) {
  final (small, large) = a.length <= b.length ? (a, b) : (b, a);
  var n = 0;
  for (final x in small) {
    if (large.contains(x)) n++;
  }
  return n;
}

/// Result of [matchGroups]: new cluster index → old group id.
typedef GroupMatches = Map<int, int>;

/// Greedy one-to-one matching, best Jaccard first: new cluster `i` takes
/// old group `id` when the overlap passes [kMatchKeptShare] and
/// [kMatchNewShare]. Each old group is used at most once. Unmatched new
/// clusters are inserted, unmatched old groups deleted by the caller.
GroupMatches matchGroups(
  Map<int, Set<String>> oldGroups,
  List<Set<String>> newClusters,
) {
  // Only pairs that share a member can match.
  final ownerOf = <String, int>{};
  for (final MapEntry(key: id, value: members) in oldGroups.entries) {
    for (final m in members) {
      ownerOf[m] = id; // groups of one kind don't share members
    }
  }
  final candidates = <(double, int, int)>[];
  for (final (i, cluster) in newClusters.indexed) {
    final shared = <int, int>{};
    for (final m in cluster) {
      final owner = ownerOf[m];
      if (owner != null) shared[owner] = (shared[owner] ?? 0) + 1;
    }
    for (final MapEntry(key: id, value: inter) in shared.entries) {
      final old = oldGroups[id]!;
      if (inter / old.length < kMatchKeptShare) continue;
      if (inter / cluster.length < kMatchNewShare) continue;
      candidates.add((inter / (old.length + cluster.length - inter), i, id));
    }
  }
  candidates.sort((a, b) {
    final byScore = b.$1.compareTo(a.$1);
    if (byScore != 0) return byScore;
    final byNew = a.$2.compareTo(b.$2);
    return byNew != 0 ? byNew : a.$3.compareTo(b.$3);
  });
  final matches = <int, int>{};
  final usedOld = <int>{};
  for (final (_, i, id) in candidates) {
    if (matches.containsKey(i) || usedOld.contains(id)) continue;
    matches[i] = id;
    usedOld.add(id);
  }
  return matches;
}
