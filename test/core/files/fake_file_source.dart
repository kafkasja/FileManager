import 'dart:async';
import 'dart:io';

import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/trash_types.dart';

/// In-memory [FileSource] shared by all feature tests. Ids are
/// `path:<path>`, so move/rename change the id and emit [idChanges] like the
/// worst case on a real device.
class FakeFileSource implements FileSource {
  new({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, FileRef> _files = {};
  final Map<String, List<int>> _bytes = {};
  final Set<String> _folders = {'/'};
  final Map<String, TrashedItem> _trash = {};
  final StreamController<FileIdChange> _idChanges =
      StreamController<FileIdChange>.broadcast();

  /// Every call to a mutating method, in order (for assertions).
  final List<String> calls = [];

  /// Files currently in the fake trash, by trashId.
  Map<String, TrashedItem> get trash => Map.unmodifiable(_trash);

  /// All live files.
  List<FileRef> get files => List.unmodifiable(_files.values);

  /// Adds a file (and its folders) and returns it.
  FileRef addFile(
    String path, {
    List<int> bytes = const [1, 2, 3],
    DateTime? modifiedAt,
    DateTime? takenAt,
    String? mimeType,
  }) {
    final folder = parentOf(path);
    _addFolders(folder);
    final name = nameOf(path);
    final ref = FileRef(
      id: 'path:$path',
      uri: path,
      name: name,
      mimeType: mimeType,
      kind: kindFor(mimeType, name),
      sizeBytes: bytes.length,
      modifiedAt: (modifiedAt ?? _clock()).toUtc(),
      takenAt: takenAt?.toUtc(),
      folderPath: folder,
      origin: FileOrigin.local,
      hidden: name.startsWith('.') || isInHiddenFolder(path),
    );
    _files[ref.id] = ref;
    _bytes[ref.id] = List.unmodifiable(bytes);
    return ref;
  }

  /// The bytes stored for [id] (N10 tests), or null.
  List<int>? bytesOf(String id) => _bytes[id];

  /// Adds an empty folder (and its parents).
  void addFolder(String path) => _addFolders(path);

  /// P3: make [requestWriteAccess] answer "declined".
  bool declineWriteAccess = false;

  @override
  Future<bool> requestWriteAccess(List<FileRef> files) async {
    calls.add('requestWriteAccess ${files.length}');
    return !declineWriteAccess;
  }

  void _requireFolder(String path) {
    if (!_folders.contains(path)) {
      throw FileOpException(FileOpFailure.notFound, 'no folder $path');
    }
  }

  /// Simulates another app deleting a file.
  void removeExternally(String id) {
    _files.remove(id);
    _bytes.remove(id);
  }

  /// H2: files [trashBatch] can't put in the pending-delete folder.
  final Set<String> folderUnavailable = {};

  /// Moves a file into the trash as if the system did it (H1: a dialog
  /// whose result was lost), without a [trashBatch] call.
  void trashExternally(String id) {
    final f = _files.remove(id)!;
    _trash[id] = TrashedItem(
      trashId: id,
      original: f,
      location: TrashLocation.systemTrash,
      trashedAt: _clock().toUtc(),
      expiresAt: _clock().toUtc().add(const Duration(days: 30)),
    );
  }

  Future<void> dispose() => _idChanges.close();

  @override
  Stream<FileIdChange> get idChanges => _idChanges.stream;

  @override
  Stream<List<FileRef>> scan({FileQuery query = FileQuery.all}) async* {
    final root = query.rootPath;
    final matches = _files.values.where((f) {
      if (!query.wants(f.kind)) return false;
      if (root != null) {
        final inside = query.recursive
            ? f.path.startsWith('$root/')
            : f.folderPath == root;
        if (!inside) return false;
      }
      if (!query.includeHidden &&
          (f.name.startsWith('.') ||
              isInHiddenFolder(f.path, root: root ?? ''))) {
        return false;
      }
      if (query.modifiedAfter case final after?
          when !f.modifiedAt.isAfter(after)) {
        return false;
      }
      if (query.minSizeBytes case final min? when f.sizeBytes < min) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => b.sortDate.compareTo(a.sortDate));
    for (var i = 0; i < matches.length; i += query.pageSize) {
      final end = i + query.pageSize;
      yield List.unmodifiable(
        matches.sublist(i, end > matches.length ? matches.length : end),
      );
    }
  }

  @override
  Future<FileRef?> stat(String id) async => _files[id];

  @override
  Stream<List<int>> openRead(FileRef f, {int start = 0, int? end}) {
    final bytes = _bytes[f.id];
    if (bytes == null) {
      return Stream.error(
        FileOpException(FileOpFailure.notFound, f.path, fileId: f.id),
      );
    }
    final to = (end ?? bytes.length).clamp(0, bytes.length);
    return Stream.value(bytes.sublist(start.clamp(0, to), to));
  }

  @override
  Future<String> createFolder(String parentPath, String name) async {
    validateFileName(name);
    calls.add('createFolder $parentPath $name');
    if (!_folders.contains(parentPath)) {
      throw FileOpException(FileOpFailure.notFound, parentPath);
    }
    final path = '$parentPath/$name';
    // Shared storage is case-insensitive: "camera" clashes with "Camera".
    final lower = path.toLowerCase();
    if (_folders.any((p) => p.toLowerCase() == lower) ||
        _files.values.any((f) => f.path.toLowerCase() == lower)) {
      throw FileOpException(FileOpFailure.targetExists, path);
    }
    _folders.add(path);
    return path;
  }

  @override
  Future<FileRef> move(FileRef f, String targetFolder) async {
    calls.add('move ${f.id} $targetFolder');
    final current = _require(f);
    if (targetFolder == current.folderPath) return current;
    _requireFolder(targetFolder);
    final name = await uniqueName(
      current.name,
      (c) async => _taken('$targetFolder/$c'),
    );
    return _relocate(current, targetFolder, name);
  }

  @override
  Future<FileRef> copy(FileRef f, String targetFolder) async {
    calls.add('copy ${f.id} $targetFolder');
    final current = _require(f);
    _requireFolder(targetFolder);
    final name = await uniqueName(
      current.name,
      (c) async => _taken('$targetFolder/$c'),
    );
    _addFolders(targetFolder);
    final path = '$targetFolder/$name';
    final copy = current.copyWith(
      id: 'path:$path',
      uri: path,
      name: name,
      folderPath: targetFolder,
    );
    _files[copy.id] = copy;
    _bytes[copy.id] = _bytes[current.id]!;
    return copy;
  }

  @override
  Future<FileRef> rename(FileRef f, String newName) async {
    checkPathSegment(newName);
    calls.add('rename ${f.id} $newName');
    final current = _require(f);
    if (newName == current.name) return current;
    final name = await uniqueName(
      newName,
      (c) async => _taken('${current.folderPath}/$c'),
    );
    return _relocate(current, current.folderPath, name);
  }

  @override
  Future<TrashResult> trashBatch(List<FileRef> files) async {
    calls.add('trashBatch ${files.map((f) => f.id).join(',')}');
    final trashed = <TrashedItem>[];
    final failed = <String, FileOpException>{};
    for (final f in files) {
      if (folderUnavailable.contains(f.id)) {
        failed[f.id] = FileOpException(
          FileOpFailure.pendingFolderUnavailable,
          f.path,
          fileId: f.id,
        );
        continue;
      }
      final current = _files.remove(f.id);
      if (current == null) {
        failed[f.id] = FileOpException(
          FileOpFailure.notFound,
          f.path,
          fileId: f.id,
        );
        continue;
      }
      final item = TrashedItem(
        trashId: 'trash:${f.id}',
        original: current,
        location: TrashLocation.systemTrash,
        trashedAt: _clock().toUtc(),
      );
      _trash[item.trashId] = item;
      trashed.add(item);
    }
    return TrashResult(trashed: trashed, failed: failed);
  }

  @override
  Future<void> deletePermanentlyBatch(List<FileRef> files) async {
    calls.add('deletePermanentlyBatch ${files.map((f) => f.id).join(',')}');
    for (final f in files) {
      _files.remove(f.id);
      _bytes.remove(f.id);
    }
  }

  @override
  Future<FileRef> restore(TrashedItem item) async {
    calls.add('restore ${item.trashId}');
    final trashed = _trash.remove(item.trashId);
    if (trashed == null) {
      throw FileOpException(FileOpFailure.notFound, item.trashId);
    }
    final original = trashed.original;
    if (_taken(original.path)) {
      final name = await uniqueName(
        original.name,
        (c) async => _taken('${original.folderPath}/$c'),
      );
      final path = '${original.folderPath}/$name';
      final restored = original.copyWith(
        id: 'path:$path',
        uri: path,
        name: name,
      );
      _files[restored.id] = restored;
      _idChanges.add(FileIdChange(original.id, restored));
      return restored;
    }
    _files[original.id] = original;
    return original;
  }

  @override
  Future<List<TrashedItem>> listTrashed() async => _trash.values.toList();

  /// When true, restoreBatch/deleteFromTrash act like a declined dialog.
  bool declineDialogs = false;

  @override
  Future<RestoreResult> restoreBatch(List<TrashedItem> items) async {
    calls.add('restoreBatch ${items.map((i) => i.trashId).join(',')}');
    if (declineDialogs) {
      return const RestoreResult(restored: {}, failed: {}, userCancelled: true);
    }
    final restored = <String, FileRef>{};
    final failed = <String, FileOpException>{};
    for (final item in items) {
      try {
        restored[item.trashId] = await restore(item);
      } on FileOpException catch (e) {
        failed[item.trashId] = e;
      }
    }
    return RestoreResult(restored: restored, failed: failed);
  }

  @override
  Future<void> deleteFromTrash(List<TrashedItem> items) async {
    calls.add('deleteFromTrash ${items.map((i) => i.trashId).join(',')}');
    if (declineDialogs) {
      throw const FileOpException(FileOpFailure.userCancelled, 'declined');
    }
    for (final item in items) {
      _trash.remove(item.trashId);
    }
  }

  FileRef _require(FileRef f) =>
      _files[f.id] ??
      (throw FileOpException(FileOpFailure.notFound, f.path, fileId: f.id));

  bool _taken(String path) =>
      _files.containsKey('path:$path') || _folders.contains(path);

  /// B4: what [freeBytes] reports (null = unknown).
  int? freeBytesValue;

  @override
  Future<FileRef?> statPath(String path) async => _files['path:$path'];

  @override
  Future<({String path, List<FileRef> files})> renameFolder(
    String folderPath,
    String newName,
  ) async {
    checkPathSegment(newName);
    calls.add('renameFolder $folderPath $newName');
    _requireFolder(folderPath);
    final newPath = '${parentOf(folderPath)}/$newName';
    if (_folders.contains(newPath) || _files.containsKey('path:$newPath')) {
      throw FileOpException(FileOpFailure.targetExists, newPath);
    }
    String moved(String p) => p == folderPath
        ? newPath
        : p.startsWith('$folderPath/')
        ? '$newPath${p.substring(folderPath.length)}'
        : p;
    final folders = _folders.map(moved).toSet();
    _folders
      ..clear()
      ..addAll(folders);
    final inside = [
      for (final f in _files.values)
        if (f.folderPath == folderPath ||
            f.folderPath.startsWith('$folderPath/'))
          f,
    ];
    final now = <FileRef>[];
    for (final f in inside) {
      now.add(_relocate(f, moved(f.folderPath), f.name));
    }
    return (path: newPath, files: now);
  }

  @override
  Future<int?> freeBytes(String folderPath) async => freeBytesValue;

  /// N9: when set, [importFile] throws it.
  FileOpException? importFailure;

  @override
  Future<FileRef> importFile(
    File staged, {
    required String targetFolder,
    required String name,
    String? mimeType,
  }) async {
    validateFileName(name);
    calls.add('importFile $targetFolder $name');
    final failure = importFailure;
    if (failure != null) throw failure;
    final bytes = await staged.readAsBytes();
    _addFolders(targetFolder);
    final unique = await uniqueName(
      name,
      (c) async => _taken('$targetFolder/$c'),
    );
    final ref = addFile(
      '$targetFolder/$unique',
      bytes: bytes,
      mimeType: mimeType,
    );
    await staged.delete();
    return ref;
  }

  /// B5: refs of the given paths from the in-memory map (tests add the
  /// files first with [addFile]); unknown paths are skipped.
  @override
  Future<List<FileRef>> registerCreated(List<String> paths) async {
    calls.add('registerCreated ${paths.length}');
    return [for (final p in paths) ?_files['path:$p']];
  }

  FileRef _relocate(FileRef current, String folder, String name) {
    _addFolders(folder);
    final path = '$folder/$name';
    final moved = current.copyWith(
      id: 'path:$path',
      uri: path,
      name: name,
      folderPath: folder,
    );
    _files.remove(current.id);
    _files[moved.id] = moved;
    _bytes[moved.id] = _bytes.remove(current.id)!;
    _idChanges.add(FileIdChange(current.id, moved));
    return moved;
  }

  void _addFolders(String folder) {
    var path = folder;
    while (path.isNotEmpty && path != '/') {
      _folders.add(path);
      path = parentOf(path);
    }
  }
}
