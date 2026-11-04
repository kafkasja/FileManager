import 'dart:io';

import 'package:kfm/core/files/io/fs_walker.dart' show isWin32AddressableName;
import 'package:kfm/core/files/system_files.dart';
import 'package:kfm/core/files/windows/win_attributes.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'disk_folders.g.dart';

/// A folder on disk directly inside the folder desktop Browse shows
/// (desktop fixes): the index only knows folders that hold indexed files,
/// so empty folders came from here.
@immutable
class DiskFolder {
  const new(this.path, {this.hidden = false});

  /// '/'-separated, like the index.
  final String path;

  /// A dot-folder or (Windows) one with the hidden attribute.
  final bool hidden;

  @override
  bool operator ==(Object other) =>
      other is DiskFolder && other.path == path && other.hidden == hidden;

  @override
  int get hashCode => Object.hash(path, hidden);
}

/// The subfolders of a folder (tests: the fake file source has no disk).
typedef DiskFolderLister = Future<List<DiskFolder>> Function(String folder);

final _driveRoot = RegExp(r'^[A-Za-z]:$');
final _drivePath = RegExp('^[A-Za-z]:/');

/// [DiskFolderLister] on the real file system: one level, links not
/// followed, KFM's own and system temp folders left out. An unreadable or
/// missing folder lists nothing (Browse still shows the index's folders).
Future<List<DiskFolder>> listDiskFolders(String folder) async {
  var io = _driveRoot.hasMatch(folder) ? '$folder/' : folder;
  if (Platform.isWindows && io.length >= 240 && _drivePath.hasMatch(io)) {
    io = '\\\\?\\${io.replaceAll('/', r'\')}';
  }
  final out = <DiskFolder>[];
  try {
    await for (final e in Directory(io).list(followLinks: false)) {
      if (e is! Directory) continue;
      final raw = e.path.replaceAll(r'\', '/');
      final name = raw.substring(raw.lastIndexOf('/') + 1);
      if (name.isEmpty || isSystemTempName(name)) continue;
      if (Platform.isWindows && !isWin32AddressableName(name)) continue;
      final path = folder == '/' ? '/$name' : '$folder/$name';
      if (isExcludedFolderPath(path)) continue;
      out.add(
        DiskFolder(
          path,
          hidden: name.startsWith('.') || hasHiddenAttribute(path),
        ),
      );
    }
  } on FileSystemException {
    return const [];
  }
  return out;
}

@riverpod
DiskFolderLister diskFolderLister(Ref ref) => listDiskFolders;

/// [folder]'s subfolders on disk; listed again when the index changes and
/// whenever the folder is opened again.
@riverpod
Future<List<DiskFolder>> desktopDiskFolders(Ref ref, String folder) async {
  ref.watch(mediaIndexChangesProvider);
  return await ref.watch(diskFolderListerProvider)(folder);
}
