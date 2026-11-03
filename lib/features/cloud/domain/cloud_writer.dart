import 'package:meta/meta.dart';

/// Bytes handed to a cloud app's folder (TASK-X3).
@immutable
class CloudWriteResult {
  const new({required this.sha256, required this.bytes});

  /// SHA-256 of the source bytes as they were written.
  final String sha256;
  final int bytes;
}

/// Why a cloud write or read failed.
enum CloudWriteFailure { notFound, permission, noSpace, cancelled, io }

@immutable
class CloudWriteException implements Exception {
  const new(this.failure, [this.message = '']);

  final CloudWriteFailure failure;
  final String message;

  @override
  String toString() => 'CloudWriteException(${failure.name}): $message';
}

/// Writes into a cloud destination (Android: the provider's SAF tree).
/// Throws [CloudWriteException].
///
/// Deviation from the plan's single `write`: [create] returns the
/// document URI first, so the runner records it before any byte is
/// written (a restart can then delete the partial document).
abstract interface class CloudDestinationWriter {
  /// A new empty document named [name] (the provider may rename it).
  Future<String> create(String location, String name, String? mime);

  /// Copies [source] (content URI or absolute path) into [remoteUri]. The
  /// writer deletes the document itself when this fails or is cancelled.
  Future<CloudWriteResult> write({
    required String source,
    required String remoteUri,
    required String jobKey,
  });

  /// SHA-256 and length of [remoteUri] read back through the provider.
  Future<CloudWriteResult> readBack(String remoteUri);

  /// The document's size; null when it is gone.
  Future<int?> sizeOf(String remoteUri);

  /// Gone already counts as deleted.
  Future<void> deleteDocument(String remoteUri);

  /// Stops [jobKey]'s copy at its next chunk.
  Future<void> cancel(String jobKey);

  /// `(jobKey, bytes written)` of running copies.
  Stream<({String jobKey, int bytes})> get progress;
}
