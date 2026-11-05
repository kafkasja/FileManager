import 'dart:io';

import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/windows/windows_file_source.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/features/connect/data/path_guard.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shared_folder_fs.g.dart';

/// What the shared-folder picker and chooser read from disk (TASK-N4);
/// faked in widget tests.
abstract interface class SharedFolderFs {
  /// Root of the primary volume (`/storage/emulated/0`); on Windows the
  /// user's folder (`C:/Users/<name>`; E1: the Android root doesn't exist
  /// there, so the chooser showed an empty "All storage").
  String get primaryRoot;

  Future<bool> exists(String path);

  /// Subfolders of [path], sorted by name, without dot-folders,
  /// `Android/data` and `Android/obb`. Throws `FileSystemException`.
  Future<List<String>> listSubfolders(String path);
}

class DiskSharedFolderFs implements SharedFolderFs {
  const new({this.primaryRoot = androidPrimaryRoot});

  @override
  final String primaryRoot;

  @override
  Future<bool> exists(String path) => Directory(windowsIoPath(path)).exists();

  @override
  Future<List<String>> listSubfolders(String path) async {
    final out = <String>[];
    final dir = Directory(windowsIoPath(path));
    await for (final e in dir.list(followLinks: false)) {
      if (e is! Directory) continue;
      final child = normalizeWindowsPath(e.path);
      if (PathGuard.isExcluded(child)) continue;
      out.add(child);
    }
    out.sort(
      (a, b) => p.posix
          .basename(a)
          .toLowerCase()
          .compareTo(p.posix.basename(b).toLowerCase()),
    );
    return out;
  }
}

@Riverpod(keepAlive: true)
SharedFolderFs sharedFolderFs(Ref ref) => isWindowsHost
    ? DiskSharedFolderFs(primaryRoot: windowsSharedRoot(Platform.environment))
    : const DiskSharedFolderFs();

/// The Windows chooser's root: `%USERPROFILE%` in KFM's '/' form (the
/// system drive when it is unset).
String windowsSharedRoot(Map<String, String> env) =>
    normalizeWindowsPath(env['USERPROFILE'] ?? env['SystemDrive'] ?? 'C:');
