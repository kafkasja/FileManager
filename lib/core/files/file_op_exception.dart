enum FileOpFailure {
  notFound,
  permissionDenied,
  targetExists,
  noSpace,
  userCancelled,
  unsupported,
  invalidName,
  ioError,

  /// H2: the volume's pending-delete folder can't be used (root not
  /// writable, or the rename crosses mounts). The file is untouched.
  pendingFolderUnavailable,

  /// N7: the device holding the file isn't connected (remote files).
  unavailable,

  /// U3: the volume is being ejected; new work on it is refused.
  volumeEjecting,

  /// PL1: another program has the file open (Windows sharing violation).
  inUse,

  /// PL1: the drive has no Recycle Bin (off, too small, network drive).
  noTrash,
}

/// Every FileSource failure. The UI maps [failure] to a localized message;
/// [message] is for developers only.
class FileOpException implements Exception {
  const new(this.failure, this.message, {this.fileId});

  final FileOpFailure failure;
  final String message;
  final String? fileId;

  @override
  String toString() => 'FileOpException($failure, $fileId): $message';
}
