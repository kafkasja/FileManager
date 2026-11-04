import 'dart:io';

import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:meta/meta.dart';

/// What an upload actually sends (TASK-N9): the original file, or a
/// temporary copy (X2 strips location into one). [sizeBytes] and every
/// later hash refer to these bytes. N10 resumes an upload by reading from
/// an offset again, so a preprocessor must produce the same bytes every
/// time for the same source version.
@immutable
class PreparedSource {
  const new({
    required this.sizeBytes,
    required this.read,
    this.cleanup = _noop,
    this.path,
  });

  final int sizeBytes;

  /// A dart:io path with exactly these bytes, when there is one (N10
  /// hashes it in a worker isolate; otherwise [read] is streamed there).
  final String? path;

  /// Bytes `[start, end)`.
  final Stream<List<int>> Function(int start, int end) read;

  /// Deletes a temporary file; runs when the file ends (done, failed or
  /// cancelled).
  final Future<void> Function() cleanup;

  static Future<void> _noop() async {}
}

/// Runs before an upload reads a file. N9 ships [IdentityPreprocessor];
/// X2 overrides `transferPreprocessorProvider`.
abstract interface class TransferPreprocessor {
  Future<PreparedSource> prepare(FileRef f, FileSource source);
}

/// Sends the file as it is. The size is the real length on disk when it can
/// be read (MediaStore's SIZE can be stale), else `FileRef.sizeBytes`.
class IdentityPreprocessor implements TransferPreprocessor {
  const new({this.diskLength = _lengthOnDisk});

  final Future<int?> Function(FileRef f) diskLength;

  static Future<int?> _lengthOnDisk(FileRef f) async {
    // `/…` on Android, `C:/…` on Windows (Q8: Windows uploads were hashed
    // through the stream instead of the file).
    if (!f.path.startsWith('/') && !File(f.path).isAbsolute) return null;
    try {
      return await File(f.path).length();
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<PreparedSource> prepare(FileRef f, FileSource source) async {
    final onDisk = await diskLength(f);
    return PreparedSource(
      sizeBytes: onDisk ?? f.sizeBytes,
      read: (start, end) => source.openRead(f, start: start, end: end),
      path: onDisk != null ? f.path : null,
    );
  }
}
