import 'dart:async';
import 'dart:io';

import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/io/fs_walker.dart';
import 'package:kfm/core/files/io_errors.dart';
import 'package:kfm/core/files/temp_file_ledger.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';

/// Windows [FileSource] (TASK-PL1): everything through dart:io, the Recycle
/// Bin through the `com.kaf.kfm/windows` channel ([WindowsChannel]).
///
/// Paths are '/'-separated like everywhere else in KFM (`C:/Users/me/a.jpg`;
/// dart:io takes them as they are); ids are `path:<path>`. NTFS is
/// case-insensitive, so paths are compared with [sameWindowsPath] inside
/// this class. A drive root folder is `C:` (a file in it is `C:/a.txt`).
class WindowsFileSource implements FileSource {
  new({
    required this._channel,
    required this._indexRoots,
    this._walker = walkFiles,
    this._tempLedger,
    this._removableRoots,
  });

  final WindowsChannel _channel;

  /// What a scan without `rootPath` walks (`WindowsIndexRoots.current`).
  final Future<List<String>> Function() _indexRoots;

  /// U1 on Windows: roots of mounted removable drives. Full scans walk them
  /// next to the index roots (like Android's SD cards), so their rows stay.
  final Future<List<String>> Function()? _removableRoots;

  Future<List<String>> _scanRoots() async => outermostRoots([
    ...await _indexRoots(),
    ...?await _removableRoots?.call(),
  ]);
  final Stream<List<FileRef>> Function(WalkOptions options) _walker;
  final Future<TempFileLedger?>? _tempLedger;

  final StreamController<FileIdChange> _idChanges =
      StreamController<FileIdChange>.broadcast();

  @override
  Stream<FileIdChange> get idChanges => _idChanges.stream;

  Future<void> dispose() => _idChanges.close();

  @override
  bool supports(FileOp op, FileRef f) => f.id.startsWith('path:');

  // ---- read ----

  @override
  Stream<List<FileRef>> scan({FileQuery query = FileQuery.all}) async* {
    final roots = query.rootPath == null
        ? await _scanRoots()
        : [normalizeWindowsPath(query.rootPath!)];
    for (final root in roots) {
      // An unplugged drive or a removed folder: skipped, not an error, when
      // it's one of several index roots.
      if (query.rootPath == null && !await Directory(_io(root)).exists()) {
        continue;
      }
      yield* _walker(
        WalkOptions(
          root: root,
          recursive: query.recursive,
          includeHidden: query.includeHidden,
          kinds: query.kinds,
          modifiedAfter: query.modifiedAfter,
          minSizeBytes: query.minSizeBytes,
          pageSize: query.pageSize,
          readExif: true,
        ),
      );
    }
  }

  @override
  Future<FileRef?> stat(String id) async {
    if (!id.startsWith('path:')) {
      throw FileOpException(FileOpFailure.unsupported, 'unknown id: $id');
    }
    return await _statPath(normalizeWindowsPath(id.substring(5)));
  }

  @override
  Future<FileRef?> statPath(String path) =>
      _statPath(normalizeWindowsPath(path));

  @override
  Stream<List<int>> openRead(FileRef f, {int start = 0, int? end}) =>
      File(f.path)
          .openRead(start, end)
          .handleError(
            (Object e) =>
                throw _ioError(e as FileSystemException, f.path, fileId: f.id),
            test: (e) => e is FileSystemException,
          );

  @override
  Future<int?> freeBytes(String folderPath) async => null;

  @override
  Future<List<FileRef>> registerCreated(List<String> paths) async => [
    for (final p in paths) ?await _statPath(normalizeWindowsPath(p)),
  ];

  @override
  Future<bool> requestWriteAccess(List<FileRef> files) async => true;

  // ---- write ----

  @override
  Future<String> createFolder(String parentPath, String name) async {
    validateWindowsName(name);
    final parent = normalizeWindowsPath(parentPath);
    final path = '$parent/$name';
    try {
      if (!await Directory(_io(parent)).exists()) {
        throw FileOpException(FileOpFailure.notFound, 'no folder: $parent');
      }
      if (await _exists(path)) {
        throw FileOpException(FileOpFailure.targetExists, path);
      }
      await Directory(path).create();
      return path;
    } on FileSystemException catch (e) {
      throw _ioError(e, path);
    }
  }

  @override
  Future<FileRef> move(FileRef f, String targetFolder) async {
    final target = normalizeWindowsPath(targetFolder);
    if (sameWindowsPath(target, f.folderPath)) return f;
    await _requireFolder(target);
    final name = await uniqueName(f.name, (c) => _exists('$target/$c'));
    final moved = await _movePath(f, '$target/$name');
    return _emitIfChanged(f, moved);
  }

  @override
  Future<FileRef> copy(FileRef f, String targetFolder) async {
    final target = normalizeWindowsPath(targetFolder);
    await _requireFolder(target);
    final from = File(f.path);
    if (!await from.exists()) {
      throw FileOpException(FileOpFailure.notFound, f.path, fileId: f.id);
    }
    final name = await uniqueName(f.name, (c) => _exists('$target/$c'));
    final newPath = '$target/$name';
    try {
      await _copyVerified(from, newPath);
    } on FileSystemException catch (e) {
      throw _ioError(e, f.path, fileId: f.id);
    }
    return await _statOrThrow(newPath, 'gone after copy');
  }

  @override
  Future<FileRef> rename(FileRef f, String newName) async {
    validateWindowsName(newName);
    if (newName == f.name) return f;
    // NTFS is case-insensitive: "a.jpg" -> "A.jpg" is no clash, and goes
    // through a temp name so the new casing sticks.
    final caseOnly = newName.toLowerCase() == f.name.toLowerCase();
    final name = caseOnly
        ? newName
        : await uniqueName(newName, (c) => _exists('${f.folderPath}/$c'));
    final renamed = await _movePath(
      f,
      '${f.folderPath}/$name',
      caseOnly: caseOnly,
    );
    return _emitIfChanged(f, renamed);
  }

  @override
  Future<({String path, List<FileRef> files})> renameFolder(
    String folderPath,
    String newName,
  ) async {
    validateWindowsName(newName);
    final from = normalizeWindowsPath(folderPath);
    if (_driveRoot.hasMatch(from)) {
      throw FileOpException(FileOpFailure.unsupported, 'drive root: $from');
    }
    if (!await Directory(from).exists()) {
      throw FileOpException(FileOpFailure.notFound, 'no folder: $from');
    }
    final to = '${parentOf(from)}/$newName';
    final caseOnly = to != from && sameWindowsPath(to, from);
    if (to != from && !caseOnly && await _exists(to)) {
      throw FileOpException(FileOpFailure.targetExists, to);
    }
    if (to != from) {
      try {
        if (caseOnly) {
          final temp = tempPathIn(parentOf(from));
          await Directory(from).rename(temp);
          await Directory(temp).rename(to);
        } else {
          await Directory(from).rename(to);
        }
      } on FileSystemException catch (e) {
        throw _ioError(e, from);
      }
    }
    final files = <FileRef>[
      await for (final page in _walker(
        WalkOptions(root: to, includeHidden: true),
      ))
        ...page,
    ];
    if (to != from) {
      for (final now in files) {
        final oldPath = '$from${now.path.substring(to.length)}';
        _idChanges.add(FileIdChange('path:$oldPath', now));
      }
    }
    return (path: to, files: List<FileRef>.unmodifiable(files));
  }

  @override
  Future<FileRef> importFile(
    File staged, {
    required String targetFolder,
    required String name,
    String? mimeType,
  }) async {
    validateFileName(name);
    validateWindowsName(name);
    final target = normalizeWindowsPath(targetFolder);
    final String path;
    try {
      await Directory(_io(target)).create(recursive: true);
      path = '$target/${await uniqueName(name, (c) => _exists('$target/$c'))}';
      try {
        await staged.rename(path);
      } on FileSystemException {
        // Another volume than the staging folder.
        await _copyVerified(staged, path);
        await staged.delete();
      }
    } on FileSystemException catch (e) {
      throw _ioError(e, target);
    }
    return await _statOrThrow(path, 'gone after import');
  }

  // ---- delete / Recycle Bin ----

  /// One Recycle Bin operation for the whole batch. Files on a drive
  /// without a bin fail with `noTrash` (D2 then asks before deleting them
  /// permanently); a file in use fails alone with `inUse`.
  @override
  Future<TrashResult> trashBatch(List<FileRef> files) async {
    final failed = <String, FileOpException>{};
    final trashed = <TrashedItem>[];
    if (files.isEmpty) return TrashResult(trashed: trashed, failed: failed);
    final byPath = {for (final f in files) f.path: f};
    try {
      final available = await _channel.binAvailable(byPath.keys.toList());
      final binnable = <String>[];
      for (final MapEntry(key: path, value: f) in byPath.entries) {
        if (available[path] ?? false) {
          binnable.add(path);
        } else {
          failed[f.id] = FileOpException(
            FileOpFailure.noTrash,
            'no Recycle Bin for $path',
            fileId: f.id,
          );
        }
      }
      if (binnable.isEmpty) {
        return TrashResult(trashed: trashed, failed: failed);
      }
      final now = DateTime.now().toUtc();
      final results = await _channel.recycle(binnable);
      final answered = <String>{};
      for (final r in results) {
        final f = byPath[r.path] ?? _byPathIgnoringCase(byPath, r.path);
        if (f == null) continue;
        answered.add(f.path);
        if (r.trashId case final id? when r.error == null) {
          trashed.add(
            TrashedItem(
              trashId: id,
              original: f,
              location: TrashLocation.systemTrash,
              trashedAt: now,
            ),
          );
        } else {
          failed[f.id] = FileOpException(
            _binFailure(r.error),
            r.message ?? 'recycle failed: ${r.path}',
            fileId: f.id,
          );
        }
      }
      for (final path in binnable) {
        if (answered.contains(path)) continue;
        final f = byPath[path]!;
        failed[f.id] = FileOpException(
          FileOpFailure.ioError,
          'no answer for $path',
          fileId: f.id,
        );
      }
    } on WindowsChannelException catch (e) {
      for (final f in files) {
        failed.putIfAbsent(f.id, () => _channelFailure(e, fileId: f.id));
      }
    }
    return TrashResult(trashed: trashed, failed: failed);
  }

  /// dart:io delete per file; a file already gone counts as deleted. Every
  /// file is tried; the first failure is thrown afterwards.
  @override
  Future<void> deletePermanentlyBatch(List<FileRef> files) async {
    FileOpException? first;
    for (final f in files) {
      try {
        await File(f.path).delete();
      } on PathNotFoundException {
        // Already gone: the goal is reached.
      } on FileSystemException catch (e) {
        first ??= _ioError(e, f.path, fileId: f.id);
      }
    }
    if (first != null) throw first;
  }

  @override
  Future<FileRef> restore(TrashedItem item) async {
    final result = await restoreBatch([item]);
    if (result.restored[item.trashId] case final ref?) return ref;
    throw result.failed[item.trashId] ??
        FileOpException(
          FileOpFailure.notFound,
          'not restored: ${item.trashId}',
          fileId: item.original.id,
        );
  }

  /// One bin operation for all items. A file whose original name was taken
  /// meanwhile comes back under a new name (id change announced).
  @override
  Future<RestoreResult> restoreBatch(List<TrashedItem> items) async {
    final restored = <String, FileRef>{};
    final failed = <String, FileOpException>{};
    if (items.isEmpty) return RestoreResult(restored: restored, failed: failed);
    final byId = {for (final i in items) i.trashId: i};
    try {
      final results = await _channel.restoreFromBin(byId.keys.toList());
      for (final r in results) {
        final item = byId[r.trashId];
        if (item == null) continue;
        final path = r.path;
        final ref = path == null || r.error != null
            ? null
            : await _statPath(normalizeWindowsPath(path));
        if (ref == null) {
          failed[r.trashId] = FileOpException(
            r.error == null ? FileOpFailure.notFound : _binFailure(r.error),
            r.message ?? 'not restored: ${r.trashId}',
            fileId: item.original.id,
          );
        } else {
          restored[r.trashId] = _emitIfChanged(item.original, ref);
        }
      }
      for (final i in items) {
        if (restored.containsKey(i.trashId) || failed.containsKey(i.trashId)) {
          continue;
        }
        failed[i.trashId] = FileOpException(
          FileOpFailure.notFound,
          'no answer for ${i.trashId}',
          fileId: i.original.id,
        );
      }
    } on WindowsChannelException catch (e) {
      for (final i in items) {
        failed[i.trashId] = _channelFailure(e, fileId: i.original.id);
      }
    }
    return RestoreResult(restored: restored, failed: failed);
  }

  /// Recycle Bin items KFM cares about: those whose original path lies
  /// under an index root (the bin also holds other apps' deletes).
  @override
  Future<List<TrashedItem>> listTrashed() async {
    final roots = await _scanRoots();
    final List<BinItem> bin;
    try {
      bin = await _channel.listBin();
    } on WindowsChannelException catch (e) {
      throw _channelFailure(e);
    }
    return [
      for (final b in bin)
        if (isUnderAnyRoot(b.originalPath, roots))
          TrashedItem(
            trashId: b.trashId,
            original: _ref(
              normalizeWindowsPath(b.originalPath),
              size: b.sizeBytes,
              modified: b.modifiedAt,
            ),
            location: TrashLocation.systemTrash,
            trashedAt: b.deletedAt,
          ),
    ];
  }

  @override
  Future<void> deleteFromTrash(List<TrashedItem> items) async {
    if (items.isEmpty) return;
    try {
      await _channel.deleteFromBin([for (final i in items) i.trashId]);
    } on WindowsChannelException catch (e) {
      throw _channelFailure(e);
    }
  }

  // ---- helpers ----

  static String _io(String folder) => windowsIoPath(folder);

  static FileRef? _byPathIgnoringCase(Map<String, FileRef> byPath, String p) {
    for (final e in byPath.entries) {
      if (sameWindowsPath(e.key, p)) return e.value;
    }
    return null;
  }

  Future<void> _requireFolder(String path) async {
    if (!await Directory(_io(path)).exists()) {
      throw FileOpException(
        FileOpFailure.notFound,
        'target folder missing: $path',
      );
    }
  }

  Future<FileRef?> _statPath(String path) async {
    final stat = await FileStat.stat(path);
    if (stat.type != FileSystemEntityType.file) return null;
    return _ref(path, size: stat.size, modified: stat.modified.toUtc());
  }

  Future<FileRef> _statOrThrow(String path, String why) async =>
      (await _statPath(path)) ??
      (throw FileOpException(FileOpFailure.ioError, '$why: $path'));

  FileRef _ref(String path, {required int size, required DateTime modified}) {
    final name = nameOf(path);
    final folder = parentOf(path);
    return FileRef(
      id: 'path:$path',
      uri: path,
      name: name,
      kind: kindFor(null, name),
      sizeBytes: size,
      modifiedAt: modified,
      folderPath: folder,
      origin: FileOrigin.local,
      hidden: name.startsWith('.') || isInHiddenFolder(path),
    );
  }

  /// Same volume: rename. Another volume: copy → size check → delete.
  Future<FileRef> _movePath(
    FileRef f,
    String newPath, {
    bool caseOnly = false,
  }) async {
    final from = File(f.path);
    if (!await from.exists()) {
      throw FileOpException(FileOpFailure.notFound, f.path, fileId: f.id);
    }
    try {
      if (caseOnly) {
        final temp = tempPathIn(f.folderPath);
        await from.rename(temp);
        try {
          await File(temp).rename(newPath);
        } on FileSystemException {
          await File(temp).rename(f.path);
          rethrow;
        }
      } else {
        try {
          await from.rename(newPath);
        } on FileSystemException catch (e) {
          if (e.osError?.errorCode != _notSameDevice) rethrow;
          await _copyVerified(from, newPath);
          await from.delete();
        }
      }
    } on FileSystemException catch (e) {
      throw _ioError(e, f.path, fileId: f.id);
    }
    return await _statOrThrow(newPath, 'gone after move');
  }

  /// Copies to a hidden temp name in the target folder, keeps the modified
  /// time, checks the size, then renames it to [newPath] (never overwrites).
  Future<void> _copyVerified(File from, String newPath) async {
    final ledger = await _tempLedger;
    final tempPath = tempPathIn(
      parentOf(newPath),
      extension: splitExtension(nameOf(newPath)).$2,
    );
    final temp = File(tempPath);
    await ledger?.add(tempPath);
    try {
      final stat = await from.stat();
      await from.copy(tempPath);
      await temp.setLastModified(stat.modified);
      final copied = await temp.length();
      if (copied != stat.size) {
        throw FileOpException(
          FileOpFailure.ioError,
          'size mismatch after copy: $copied != ${stat.size}',
        );
      }
      // rename() replaces an existing file on Windows.
      if (await _exists(newPath)) {
        throw FileOpException(FileOpFailure.targetExists, newPath);
      }
      await temp.rename(newPath);
    } on Object {
      if (await temp.exists()) await temp.delete();
      rethrow;
    } finally {
      await ledger?.remove(tempPath);
    }
  }

  FileRef _emitIfChanged(FileRef old, FileRef updated) {
    if (updated.id != old.id) _idChanges.add(FileIdChange(old.id, updated));
    return updated;
  }

  Future<bool> _exists(String path) async =>
      await FileSystemEntity.type(path) != FileSystemEntityType.notFound;

  static FileOpFailure _binFailure(BinError? e) => switch (e) {
    BinError.inUse => FileOpFailure.inUse,
    BinError.notFound => FileOpFailure.notFound,
    BinError.permissionDenied => FileOpFailure.permissionDenied,
    BinError.noTrash => FileOpFailure.noTrash,
    BinError.ioError || null => FileOpFailure.ioError,
  };

  static FileOpException _channelFailure(
    WindowsChannelException e, {
    String? fileId,
  }) => FileOpException(
    e.code == 'MISSING' ? FileOpFailure.unsupported : FileOpFailure.ioError,
    'windows channel: $e',
    fileId: fileId,
  );

  /// Windows `ERROR_NOT_SAME_DEVICE`: rename across volumes.
  static const _notSameDevice = 17;
}

/// [FileSystemException] → [FileOpException], with Windows' "used by another
/// program" codes as `inUse`.
FileOpException _ioError(FileSystemException e, String path, {String? fileId}) {
  final code = e.osError?.errorCode;
  if (code == _sharingViolation || code == _lockViolation) {
    return FileOpException(
      FileOpFailure.inUse,
      '${e.message}: $path',
      fileId: fileId,
    );
  }
  return fileOpExceptionFromIo(e, path, fileId: fileId);
}

const _sharingViolation = 32;
const _lockViolation = 33;

final _driveRoot = RegExp(r'^[A-Za-z]:$');

/// [folder] for dart:io: `C:` (KFM's drive root folder) is "the current
/// folder on C:" to Windows; `C:/` is the root.
String windowsIoPath(String folder) =>
    _driveRoot.hasMatch(folder) ? '$folder/' : folder;

/// KFM's form of a Windows path: '/'-separated, no trailing '/', a drive
/// root as `C:`.
String normalizeWindowsPath(String path) {
  var p = path.replaceAll(r'\', '/');
  while (p.length > 1 && p.endsWith('/')) {
    p = p.substring(0, p.length - 1);
  }
  return p;
}

/// NTFS compares names without case.
bool sameWindowsPath(String a, String b) =>
    normalizeWindowsPath(a).toLowerCase() ==
    normalizeWindowsPath(b).toLowerCase();

/// [path] is [root] or lies below it (case-insensitive).
bool isUnderWindowsRoot(String path, String root) {
  final p = normalizeWindowsPath(path).toLowerCase();
  final r = normalizeWindowsPath(root).toLowerCase();
  return p == r || p.startsWith('$r/');
}

bool isUnderAnyRoot(String path, List<String> roots) =>
    roots.any((r) => isUnderWindowsRoot(path, r));

/// [roots] normalized, duplicates and roots inside another root dropped
/// (so a scan sees every file once). Order kept.
List<String> outermostRoots(List<String> roots) {
  final normalized = [for (final r in roots) normalizeWindowsPath(r)];
  final out = <String>[];
  for (var i = 0; i < normalized.length; i++) {
    final r = normalized[i];
    var covered = false;
    for (var j = 0; j < normalized.length; j++) {
      if (i == j) continue;
      final other = normalized[j];
      if (sameWindowsPath(r, other) ? j < i : isUnderWindowsRoot(r, other)) {
        covered = true;
        break;
      }
    }
    if (!covered) out.add(r);
  }
  return out;
}

const _reservedNames = {
  'con', 'prn', 'aux', 'nul', //
  'com1', 'com2', 'com3', 'com4', 'com5', 'com6', 'com7', 'com8', 'com9',
  'lpt1', 'lpt2', 'lpt3', 'lpt4', 'lpt5', 'lpt6', 'lpt7', 'lpt8', 'lpt9',
};

final _windowsForbidden = RegExp(r'[<>:"/\\|?*\x00-\x1F]');

/// Names NTFS/Windows refuse (TASK-PL1): the path-segment rules of
/// [checkPathSegment], any of `< > : " / \ | ? *` or control characters, a
/// trailing space or dot, and reserved device names (`CON`, `NUL.txt`…).
/// Throws `invalidName`.
void validateWindowsName(String name) {
  checkPathSegment(name);
  // "CON.txt" and "nul.tar.gz" are reserved too.
  final stem = name.split('.').first.toLowerCase().trimRight();
  if (_windowsForbidden.hasMatch(name) ||
      name.endsWith(' ') ||
      name.endsWith('.') ||
      _reservedNames.contains(stem)) {
    throw FileOpException(FileOpFailure.invalidName, 'invalid name: "$name"');
  }
}
