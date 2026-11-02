import 'package:kfm/core/db/tables/transfers_table.dart' show SourceOutcome;
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:meta/meta.dart';

export 'package:kfm/core/db/tables/transfers_table.dart' show SourceOutcome;

/// What comparing a copy with its source gave (TASK-N11).
@immutable
sealed class VerifyResult {
  const new();
}

/// Same bytes: the original may follow the delete setting.
final class Verified extends VerifyResult {
  const new({required this.sha256, required this.sizeBytes});

  final String sha256;
  final int sizeBytes;
}

/// Different bytes: the copy is bad, the original stays.
final class Mismatch extends VerifyResult {
  const new({required this.expected, required this.actual});

  final String expected;
  final String actual;
}

/// One side's hash is missing (an older peer, an unreadable file): nothing
/// can be proven, the original stays.
final class VerifyUnavailable extends VerifyResult {
  const new(this.cause);

  final Object cause;
}

/// Compares a copy with its source by SHA-256 and size. Pure: never
/// deletes anything.
VerifyResult compareCopy({
  required String? sourceSha256,
  required int sourceSize,
  required String? copySha256,
  required int copySize,
}) {
  if (sourceSha256 == null || copySha256 == null) {
    return VerifyUnavailable(
      StateError(sourceSha256 == null ? 'no source hash' : 'no copy hash'),
    );
  }
  if (sourceSha256 != copySha256 || sourceSize != copySize) {
    return Mismatch(expected: sourceSha256, actual: copySha256);
  }
  return Verified(sha256: copySha256, sizeBytes: copySize);
}

/// An original whose copy was verified. Only constructible from a
/// [Verified] result: the type proves verification happened.
@immutable
class VerifiedOriginal {
  const new({
    required this.original,
    required this.proof,
    required this.modifiedAtMsAtCopy,
  });

  /// The original as it was when the copy started (id, size).
  final FileRef original;
  final Verified proof;

  /// The source's modified time when it was copied.
  final int modifiedAtMsAtCopy;
}

/// Per-original outcomes of one [VerifiedMove.deleteOriginals] call.
@immutable
class FinalizeResult {
  const new({required this.outcomes, this.errors = const {}});

  /// By original `FileRef.id`.
  final Map<String, SourceOutcome> outcomes;

  /// Why an original was kept (`keptFailed`), by `FileRef.id`.
  final Map<String, String> errors;
}

/// Deletes the originals of verified copies (rule 10). Reused by U2
/// (local copy/move jobs) and X3 (cloud moves).
abstract interface class VerifiedMove {
  /// Deletes [originals] in as few batches as possible (one system dialog
  /// per batch on Android 11+): each is re-checked first (gone →
  /// `alreadyGone`; size or modified time changed since the copy →
  /// `keptChanged`), then [mode] trash → `trashBatch`, permanent →
  /// `deletePermanentlyBatch`. Never throws for per-file problems.
  Future<FinalizeResult> deleteOriginals(
    List<VerifiedOriginal> originals, {
    required DeleteMode mode,
  });
}
