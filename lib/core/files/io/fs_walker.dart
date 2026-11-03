import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:kfm/core/diagnostics/spawn_logged.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/io_errors.dart';
import 'package:kfm/core/files/system_files.dart';
import 'package:meta/meta.dart';

/// What [walkFiles] lists. Sent to the walker isolate, so plain data only.
@immutable
class WalkOptions {
  const new({
    required this.root,
    this.recursive = true,
    this.includeHidden = false,
    this.kinds = const {},
    this.skipIndexedKinds = const {},
    this.modifiedAfter,
    this.minSizeBytes,
    this.pageSize = 500,
    this.origin = FileOrigin.local,
  });

  final String root;
  final bool recursive;

  /// Also list dot-files/folders and folders containing `.nomedia`.
  final bool includeHidden;

  /// Empty = all kinds.
  final Set<FileKind> kinds;

  /// Kinds another index (MediaStore) already returns. Skipped, except inside
  /// hidden/.nomedia folders, which that index doesn't see.
  final Set<FileKind> skipIndexedKinds;
  final DateTime? modifiedAfter;
  final int? minSizeBytes;
  final int pageSize;
  final FileOrigin origin;
}

/// Lists files under [WalkOptions.root] in a background isolate, in pages.
/// Cancelling the subscription kills the isolate. Unreadable subfolders
/// (e.g. Android/data on API 30+) are skipped; an unreadable root is an error.
Stream<List<FileRef>> walkFiles(WalkOptions options) {
  Isolate? isolate;
  ReceivePort? port;
  late final StreamController<List<FileRef>> controller;

  void shutDown() {
    isolate?.kill(priority: Isolate.immediate);
    isolate = null;
    port?.close();
    port = null;
  }

  controller = StreamController<List<FileRef>>(
    onListen: () async {
      final receive = port = ReceivePort()
        ..listen((message) {
          switch (message) {
            case final List<FileRef> page:
              controller.add(page);
            case (final int failure, final String text):
              controller.addError(
                FileOpException(FileOpFailure.values[failure], text),
              );
            case null:
              shutDown();
              unawaited(controller.close());
          }
        });
      try {
        // H5: errors escaping _walkEntry's own reporting go to the log.
        isolate = await spawnLogged(_walkEntry, (
          receive.sendPort,
          options,
        ), debugName: 'kfm-walker');
      } on Object catch (e, st) {
        controller.addError(e, st);
        shutDown();
        await controller.close();
      }
    },
    onCancel: shutDown,
  );
  return controller.stream;
}

/// Isolate entry: sends `List<FileRef>` pages, `(failureIndex, message)` on
/// error, then `null` when finished.
void _walkEntry((SendPort, WalkOptions) args) {
  final (out, options) = args;
  try {
    _walk(options, out.send);
  } on FileOpException catch (e) {
    out.send((e.failure.index, e.message));
  } on Object catch (e) {
    out.send((FileOpFailure.ioError.index, e.toString()));
  }
  out.send(null);
}

void _walk(WalkOptions o, void Function(Object?) send) {
  final root = o.root.endsWith('/') && o.root.length > 1
      ? o.root.substring(0, o.root.length - 1)
      : o.root;
  final modifiedAfter = o.modifiedAfter?.toUtc();
  final page = <FileRef>[];
  // (folder path, inside a hidden or .nomedia folder)
  final stack = <(String, bool)>[(root, false)];

  while (stack.isNotEmpty) {
    final (dir, parentHidden) = stack.removeLast();
    final isRoot = dir == root;
    // Windows drive root `C:` (PL1): dart:io needs `C:/` for the root.
    final ioDir = _driveRoot.hasMatch(dir) ? '$dir/' : dir;
    final noMedia = File('$dir/.nomedia').existsSync();
    if (noMedia && !o.includeHidden) continue;
    final hidden = parentHidden || noMedia;

    final List<FileSystemEntity> entries;
    try {
      entries = Directory(ioDir).listSync(followLinks: false);
    } on FileSystemException catch (e) {
      if (isRoot) throw fileOpExceptionFromIo(e, dir);
      continue; // unreadable subfolder (Android/data, lost+found…)
    }

    for (final entity in entries) {
      final name = _nameOf(entity.path);
      final path = dir == '/' ? '/$name' : '$dir/$name';
      final dotted = name.startsWith('.');
      if (dotted && !o.includeHidden) continue;
      if (isSystemTempName(name)) continue;

      if (entity is Directory) {
        if (o.recursive && !isExcludedFolderPath(path)) {
          stack.add((path, hidden || dotted));
        }
        continue;
      }
      if (entity is! File) continue;

      final kind = kindFor(null, name);
      if (o.kinds.isNotEmpty && !o.kinds.contains(kind)) continue;
      if (o.skipIndexedKinds.contains(kind) && !hidden && !dotted) continue;

      final FileStat stat;
      try {
        stat = entity.statSync();
      } on FileSystemException {
        continue; // vanished or unreadable between list and stat
      }
      if (stat.type != FileSystemEntityType.file) continue;
      final modified = stat.modified.toUtc();
      // `changed` (inode change time) moves when a file is copied or moved
      // in, even if it keeps an old modified time.
      if (modifiedAfter != null &&
          !modified.isAfter(modifiedAfter) &&
          !stat.changed.toUtc().isAfter(modifiedAfter)) {
        continue;
      }
      if (o.minSizeBytes != null && stat.size < o.minSizeBytes!) continue;

      page.add(
        FileRef(
          id: 'path:$path',
          uri: path,
          name: name,
          kind: kind,
          sizeBytes: stat.size,
          modifiedAt: modified,
          folderPath: dir,
          origin: o.origin,
          hidden: hidden || dotted,
        ),
      );
      if (page.length >= o.pageSize) {
        send(List<FileRef>.unmodifiable(page));
        page.clear();
      }
    }
  }
  if (page.isNotEmpty) send(List<FileRef>.unmodifiable(page));
}

final _driveRoot = RegExp(r'^[A-Za-z]:$');

String _nameOf(String path) {
  final p = path.replaceAll(r'\', '/');
  return p.substring(p.lastIndexOf('/') + 1);
}
