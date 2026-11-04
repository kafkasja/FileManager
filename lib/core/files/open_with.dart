import 'dart:io';

import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'open_with.g.dart';

/// Hands a file to another app (TASK-B1): everything KFM doesn't open itself.
// iOS (PL2) adds an implementation.
abstract interface class OpenWithService {
  /// The app chooser ("Open with"). Throws [FileOpException] with
  /// [FileOpFailure.unsupported] when no app can open [f]; a chooser the
  /// user closed is not an error.
  Future<void> openWith(FileRef f);

  /// The file's default app (Windows: Explorer's double-click; no default
  /// app → the chooser). Android has no default-app notion: the chooser.
  Future<void> open(FileRef f);
}

/// Android "Open with" chooser (`ACTION_VIEW`): MediaStore items by their
/// `content://` uri, plain files through KFM's FileProvider.
class AndroidOpenWithService implements OpenWithService {
  new(this._channel);

  final FilesChannel _channel;

  @override
  Future<void> open(FileRef f) => openWith(f);

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

/// Windows (PL1/PL3): the default app through `ShellExecuteEx`, "Open
/// with" through `SHOpenWithDialog` (`com.kaf.kfm/windows`).
class WindowsOpenWithService implements OpenWithService {
  new(this._channel);

  final WindowsChannel _channel;

  /// Only files on this PC have a Windows path.
  String _pathOf(FileRef f) {
    if (f.origin == FileOrigin.remote || !f.id.startsWith('path:')) {
      throw FileOpException(
        FileOpFailure.unsupported,
        'not a file on this PC: ${f.id}',
        fileId: f.id,
      );
    }
    return f.path;
  }

  @override
  Future<void> open(FileRef f) async {
    final path = _pathOf(f);
    final result = await _run(f, () => _channel.openFile(path));
    if (result == ShellOpenResult.noApp) await openWith(f);
  }

  @override
  Future<void> openWith(FileRef f) async {
    final path = _pathOf(f);
    final result = await _run(f, () => _channel.openWith(path));
    if (result == ShellOpenResult.noApp) {
      throw FileOpException(
        FileOpFailure.unsupported,
        'no app opens ${f.name}',
        fileId: f.id,
      );
    }
  }

  Future<ShellOpenResult> _run(
    FileRef f,
    Future<ShellOpenResult> Function() call,
  ) async {
    final ShellOpenResult result;
    try {
      result = await call();
    } on WindowsChannelException catch (e) {
      throw FileOpException(FileOpFailure.ioError, e.toString(), fileId: f.id);
    }
    if (result == ShellOpenResult.notFound) {
      throw FileOpException(
        FileOpFailure.notFound,
        'gone: ${f.name}',
        fileId: f.id,
      );
    }
    return result;
  }
}

/// No app hand-off on this platform: every call fails with
/// [FileOpFailure.unsupported] (the UI says so instead of doing nothing).
class UnsupportedOpenWithService implements OpenWithService {
  const new();

  Never _fail(FileRef f) => throw FileOpException(
    FileOpFailure.unsupported,
    'Open with is not implemented for ${Platform.operatingSystem}',
    fileId: f.id,
  );

  @override
  Future<void> open(FileRef f) async => _fail(f);

  @override
  Future<void> openWith(FileRef f) async => _fail(f);
}

@Riverpod(keepAlive: true)
OpenWithService openWithService(Ref ref) {
  if (Platform.isAndroid) return AndroidOpenWithService(FilesChannel());
  if (isWindowsHost) {
    return WindowsOpenWithService(ref.watch(windowsChannelProvider));
  }
  return const UnsupportedOpenWithService();
}
