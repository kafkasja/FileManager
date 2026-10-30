import 'package:meta/meta.dart';

/// A run of photos/videos taken close together (TASK-B3): each gap between
/// neighbours is at most the window. Always 2+ files.
@immutable
class TimeCluster {
  const new({
    required this.fileIds,
    required this.startMs,
    required this.endMs,
  });

  /// Capture time ascending, then id.
  final List<String> fileIds;

  /// Capture time (UTC epoch ms) of the first file.
  final int startMs;

  /// Capture time (UTC epoch ms) of the last file.
  final int endMs;

  int get size => fileIds.length;

  @override
  bool operator ==(Object other) =>
      other is TimeCluster &&
      other.startMs == startMs &&
      other.endMs == endMs &&
      _listEquals(other.fileIds, fileIds);

  @override
  int get hashCode => Object.hash(startMs, endMs, Object.hashAll(fileIds));

  @override
  String toString() => 'TimeCluster($startMs-$endMs, $fileIds)';
}

/// The stored window setting clamped to 1..600 seconds.
int clampWindow(int seconds) => seconds.clamp(1, 600);

/// Groups [items] `(id, captureMs)` into clusters: a new cluster starts when
/// the gap to the previous item is greater than [window] (a gap equal to the
/// window joins). Chains: A–B and B–C within the window put A, B, C in one
/// cluster even if A–C isn't. Clusters of one file are dropped.
///
/// [items] must be sorted by captureMs ascending, then id.
List<TimeCluster> clusterByTime(List<(String, int)> items, Duration window) {
  final windowMs = window.inMilliseconds;
  final out = <TimeCluster>[];
  var runStart = 0;

  void flush(int end) {
    if (end - runStart > 1) {
      out.add(
        TimeCluster(
          fileIds: List.unmodifiable([
            for (var i = runStart; i < end; i++) items[i].$1,
          ]),
          startMs: items[runStart].$2,
          endMs: items[end - 1].$2,
        ),
      );
    }
    runStart = end;
  }

  for (var i = 1; i < items.length; i++) {
    if (items[i].$2 - items[i - 1].$2 > windowMs) flush(i);
  }
  if (items.isNotEmpty) flush(items.length);
  return List.unmodifiable(out);
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
