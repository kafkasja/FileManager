import 'dart:io';

import 'package:kfm/core/files/file_op_exception.dart';

/// Maps a dart:io failure to a [FileOpException].
FileOpException fileOpExceptionFromIo(
  FileSystemException e,
  String path, {
  String? fileId,
}) {
  final code = e.osError?.errorCode;
  final failure = switch (e) {
    PathNotFoundException() => FileOpFailure.notFound,
    PathAccessException() => FileOpFailure.permissionDenied,
    PathExistsException() => FileOpFailure.targetExists,
    _ when code == 28 || code == 112 => FileOpFailure.noSpace, // ENOSPC, Win
    _ => FileOpFailure.ioError,
  };
  return FileOpException(failure, '${e.message}: $path', fileId: fileId);
}
