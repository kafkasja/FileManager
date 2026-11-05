import 'dart:io';
import 'dart:isolate';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/io/fs_walker.dart' show isWin32AddressableName;
import 'package:kfm/core/files/system_files.dart';
import 'package:kfm/core/files/windows/win_attributes.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/desktop/tabs/desktop_tabs_controller.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_disk_files.g.dart';

/// Files listed from disk for a folder the index doesn't cover (TASK-E3).
@immutable
class DiskFiles {
  const new(this.files, {this.capped = false});

  final List<FileRef> files;

  /// More than [diskFilesCap]: only the first ones are listed.
  final bool capped;

  static const empty = DiskFiles([]);
}

/// Lists one folder's files from disk (replaced in tests).
typedef DiskFileLister = Future<DiskFiles> Function(String folder);

const diskFilesCap = 20000;

/// One level of [folder] in a worker isolate: hidden/system files left
/// out, at most [diskFilesCap]. Not written to the index.
Future<DiskFiles> listDiskFiles(String folder) =>
    Isolate.run(() => _listSync(folder, isWindows: Platform.isWindows));

DiskFiles _listSync(String folder, {required bool isWindows}) {
  var io = RegExp(r'^[A-Za-z]:$').hasMatch(folder) ? '$folder/' : folder;
  if (isWindows && io.length >= 240 && RegExp('^[A-Za-z]:/').hasMatch(io)) {
    io = '\\\\?\\${io.replaceAll('/', r'\')}';
  }
  final out = <FileRef>[];
  var capped = false;
  try {
    for (final e in Directory(io).listSync(followLinks: false)) {
      if (e is! File) continue;
      final raw = e.path.replaceAll(r'\', '/');
      final name = raw.substring(raw.lastIndexOf('/') + 1);
      if (name.isEmpty || name.startsWith('.') || isSystemTempName(name)) {
        continue;
      }
      if (isWindows && !isWin32AddressableName(name)) continue;
      final path = folder == '/' ? '/$name' : '$folder/$name';
      if (isWindows && hasHiddenAttribute(path)) continue;
      if (out.length >= diskFilesCap) {
        capped = true;
        break;
      }
      final FileStat stat;
      try {
        stat = e.statSync();
      } on FileSystemException {
        continue;
      }
      out.add(
        FileRef(
          id: 'path:$path',
          uri: path,
          name: name,
          kind: kindFor(null, name),
          sizeBytes: stat.size,
          modifiedAt: stat.modified.toUtc(),
          folderPath: folder,
          origin: FileOrigin.local,
        ),
      );
    }
  } on FileSystemException {
    return DiskFiles.empty;
  }
  return DiskFiles(List.unmodifiable(out), capped: capped);
}

@Riverpod(keepAlive: true)
DiskFileLister diskFileLister(Ref ref) => listDiskFiles;

/// [folder] exists on disk (re-checked when the index or drives change).
@riverpod
Future<bool> desktopFolderPresent(Ref ref, String folder) async {
  ref.watch(mediaIndexChangesProvider);
  return await ref.watch(desktopFolderExistsProvider)(folder);
}

/// The index covers [folder]: under an index root, and the first full scan
/// is done. Else Browse lists its files from disk too.
@riverpod
Future<bool> desktopFolderIndexed(Ref ref, String folder) async {
  final scanned = await ref
      .watch(settingsRepositoryProvider)
      .read(AppSettings.indexLastFullScanAt);
  if (scanned.isEmpty) return false;
  if (!isWindowsHost) return true;
  final roots = await ref.watch(windowsIndexRootStatusProvider.future);
  final lower = folder.toLowerCase();
  String? root;
  for (final r in roots) {
    final p = r.path.replaceAll(r'\', '/');
    final l = p.toLowerCase();
    if (lower == l || lower.startsWith('$l/')) root = p;
  }
  if (root == null) return false;
  // The walker skips hidden and excluded folders (AppData, .git…), also
  // under "Look everywhere" roots: those still list from disk.
  for (var p = folder; p.length > root.length;) {
    final name = p.substring(p.lastIndexOf('/') + 1);
    if (name.startsWith('.') || isExcludedFolderPath(p)) return false;
    if (hasHiddenAttribute(p)) return false;
    final slash = p.lastIndexOf('/');
    if (slash <= 0) break;
    p = p.substring(0, slash);
  }
  return true;
}

/// [folder]'s files from disk when the index doesn't cover it; empty
/// otherwise.
@riverpod
Future<DiskFiles> desktopDiskFiles(Ref ref, String folder) async {
  if (await ref.watch(desktopFolderIndexedProvider(folder).future)) {
    return DiskFiles.empty;
  }
  ref.watch(mediaIndexChangesProvider);
  return await ref.watch(diskFileListerProvider)(folder);
}
