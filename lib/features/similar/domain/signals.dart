import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:kfm/features/similar/domain/blur.dart';
import 'package:kfm/features/similar/domain/dhash.dart';

/// Bump when dHash or the blur score changes: forces a recompute.
const kSignalsAlgoVersion = 1;

@immutable
class ComputedSignal {
  const new({required this.fileId, this.dHash, this.blurScore});

  final String fileId;
  final int? dHash;
  final double? blurScore;

  /// False = the bytes couldn't be decoded (stored as `failed`).
  bool get ok => dHash != null && blurScore != null;
}

/// Isolate-safe (top-level, no plugins). A decode error gives a
/// [ComputedSignal] with nulls (failed); the batch continues.
List<ComputedSignal> computeSignals(
  List<(String fileId, Uint8List jpeg)> batch,
) => [for (final (id, bytes) in batch) _one(id, bytes)];

ComputedSignal _one(String fileId, Uint8List bytes) {
  try {
    final image = img.decodeImage(bytes);
    if (image == null || image.width < 3 || image.height < 3) {
      return ComputedSignal(fileId: fileId);
    }
    return ComputedSignal(
      fileId: fileId,
      dHash: dHashOf(image),
      blurScore: blurScoreOf(image),
    );
    // A corrupt file can make the decoder throw anything (RangeError, ...).
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    return ComputedSignal(fileId: fileId);
  }
}
