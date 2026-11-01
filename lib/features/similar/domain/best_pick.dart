import 'package:flutter/foundation.dart';
import 'package:kfm/core/files/file_ref.dart';

@immutable
class ScoredImage {
  const new({required this.file, required this.dHash, required this.blurScore});

  final FileRef file;
  final int dHash;
  final double blurScore;
}

/// Sharpest first; resolution, size, newest only break ties (Q1).
int compareBest(ScoredImage a, ScoredImage b) => compareBestValues(
  blurA: a.blurScore,
  blurB: b.blurScore,
  pixelsA: (a.file.width ?? 0) * (a.file.height ?? 0),
  pixelsB: (b.file.width ?? 0) * (b.file.height ?? 0),
  sizeA: a.file.sizeBytes,
  sizeB: b.file.sizeBytes,
  dateMsA: a.file.sortDate.millisecondsSinceEpoch,
  dateMsB: b.file.sortDate.millisecondsSinceEpoch,
);

/// [compareBest] on plain values (grouping runs on `SignalPoint`s in an
/// isolate, without FileRefs). Negative = a is better.
int compareBestValues({
  required double blurA,
  required double blurB,
  required int pixelsA,
  required int pixelsB,
  required int sizeA,
  required int sizeB,
  required int dateMsA,
  required int dateMsB,
}) {
  final blur = blurB.compareTo(blurA);
  if (blur != 0) return blur;
  final res = pixelsB.compareTo(pixelsA);
  if (res != 0) return res;
  final size = sizeB.compareTo(sizeA);
  if (size != 0) return size;
  return dateMsB.compareTo(dateMsA);
}
