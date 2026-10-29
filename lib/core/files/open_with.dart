import 'dart:io';

import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'open_with.g.dart';

/// Hands a file to another app (TASK-B1): everything KFM doesn't open itself.
// Windows (PL1) and iOS (PL2) add implementations.
abstract interface class OpenWithService {
  /// Throws [FileOpException] with [FileOpFailure.unsupported] when no app
  /// can open [f].
  Future<void> openWith(FileRef f);
}

/// Android "Open with" chooser (`ACTION_VIEW`): MediaStore items by their
/// `content://` uri, plain files through KFM's FileProvider.
class AndroidOpenWithService implements OpenWithService {
  new(this._channel);

  final FilesChannel _channel;

  @override
  Future<void> openWith(FileRef f) async {
    final bool opened;
    try {
      opened = await _channel.openWith(
        contentUri: f.uri.startsWith('content://') ? f.uri : null,
        path: f.uri.startsWith('content://') ? null : f.path,
        mime: f.mimeType,
      );
    } on FilesChannelException catch (e) {
      throw FileOpException(
        FileOpFailure.ioError,
        '${e.code}: ${e.message}',
        fileId: f.id,
      );
    }
    if (!opened) {
      throw FileOpException(
        FileOpFailure.unsupported,
        'no app opens ${f.name}',
        fileId: f.id,
      );
    }
  }
}

@Riverpod(keepAlive: true)
OpenWithService openWithService(Ref ref) {
  if (Platform.isAndroid) return AndroidOpenWithService(FilesChannel());
  throw UnsupportedError(
    'Open with is not implemented for ${Platform.operatingSystem} yet',
  );
}
