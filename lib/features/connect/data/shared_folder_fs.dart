import 'dart:io';

import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/features/connect/data/path_guard.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shared_folder_fs.g.dart';

/// What the shared-folder picker and chooser read from disk (TASK-N4);
/// faked in widget tests.
abstract interface class SharedFolderFs {
  /// Root of the primary volume (`/storage/emulated/0`).
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
  Future<bool> exists(String path) => Directory(path).exists();

  @override
  Future<List<String>> listSubfolders(String path) async {
    final out = <String>[];
    await for (final e in Directory(path).list(followLinks: false)) {
      if (e is! Directory) continue;
      final child = e.path.replaceAll(r'\', '/');
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
SharedFolderFs sharedFolderFs(Ref ref) => const DiskSharedFolderFs();
