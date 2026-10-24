import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/files/android/fs_walker.dart';
import 'package:kfm/core/files/android/media_mapper.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/io_errors.dart';
import 'package:kfm/core/files/pending_folder.dart';
import 'package:kfm/core/files/trash_types.dart';

const Set<FileKind> _mediaKinds = {
  FileKind.image,
  FileKind.video,
  FileKind.audio,
};

/// Android [FileSource]: images/videos/audio through MediaStore
/// (FilesChannel.kt), everything else through dart:io. See
/// docs/ARCHITECTURE.md → File access for the API-level matrix.
class AndroidFileSource implements FileSource {
  new({
    required this._channel,
    this.primaryRoot = '/storage/emulated/0',
    this._walker = walkFiles,
    this._canSeeAllFiles = _always,
    this._pendingFolder,
    this._folderExists = _dirExists,
  });

  static bool _always() => true;
  static Future<bool> _dirExists(String path) => Directory(path).exists();

  /// Tests with device paths (MediaStore mocks) replace the disk check.
  final Future<bool> Function(String path) _folderExists;

  final FilesChannel _channel;
  final Stream<List<FileRef>> Function(WalkOptions options) _walker;

  /// F4: without All files access the walk would only find this app's own
  /// files, so scans return media only.
  final bool Function() _canSeeAllFiles;

  /// D4: where non-media (and media on API ≤29) goes when trashed.
  final PendingFolder? _pendingFolder;

  /// Root of the storage volume holding [path] (`/storage/emulated/0`,
  /// `/storage/1234-ABCD`).
  String volumeRootOf(String path) =>
      _volumeRoot.firstMatch(path)?.group(0) ?? primaryRoot;

  static final _volumeRoot = RegExp(r'^/storage/(emulated/\d+|[^/]+)');

  /// Root of the primary shared storage volume.
  final String primaryRoot;

  final StreamController<FileIdChange> _idChanges =
      StreamController<FileIdChange>.broadcast();

  @override
  Stream<FileIdChange> get idChanges => _idChanges.stream;

  Future<void> dispose() => _idChanges.close();

  // ---- read ----

  @override
  Stream<List<FileRef>> scan({FileQuery query = FileQuery.all}) async* {
    final root = query.rootPath == null ? null : _trimSlash(query.rootPath!);
    final mediaKinds = _mediaKinds.where(query.wants).toSet();

    if (mediaKinds.isNotEmpty) {
      int? afterModified;
      int? afterId;
      while (true) {
        final rows = await _guard(
          null,
          () => _channel.queryMedia(
            kinds: {for (final k in mediaKinds) k.name},
            limit: query.pageSize,
            root: root,
            modifiedAfterSeconds: query.modifiedAfter == null
                ? null
                : query.modifiedAfter!.millisecondsSinceEpoch ~/ 1000,
            minSize: query.minSizeBytes,
            afterModified: afterModified,
            afterId: afterId,
          ),
        );
        if (rows.isEmpty) break;
        afterModified = rows.last['modified']! as int;
        afterId = rows.last['id']! as int;

        final page = [
          for (final row in rows)
            if (_mediaRef(row) case final f
                when (query.recursive ||
                        root == null ||
                        f.folderPath == root) &&
                    (query.includeHidden ||
                        !isInHiddenFolder(f.path, root: root ?? primaryRoot)))
              f,
        ];
        if (page.isNotEmpty) yield List.unmodifiable(page);
        if (rows.length < query.pageSize) break;
      }
    }

    // Other kinds come from the file system. With includeHidden, the walker
    // also finds media in hidden/.nomedia folders, which MediaStore skips.
    final wantsOther = FileKind.values.any(
      (k) => !_mediaKinds.contains(k) && query.wants(k),
    );
    if ((wantsOther || query.includeHidden) && _canSeeAllFiles()) {
      yield* _walker(
        WalkOptions(
          root: root ?? primaryRoot,
          recursive: query.recursive,
          includeHidden: query.includeHidden,
          kinds: query.kinds,
          skipIndexedKinds: _mediaKinds,
          modifiedAfter: query.modifiedAfter,
          minSizeBytes: query.minSizeBytes,
          pageSize: query.pageSize,
          origin: _originOf(root ?? primaryRoot),
        ),
      );
    }
  }

  @override
  Future<FileRef?> stat(String id) async {
    if (id.startsWith('ms:')) {
      final row = await _guard(id, () => _channel.statMedia(_parseMsId(id)));
      return row == null ? null : _mediaRef(row);
    }
    if (id.startsWith('path:')) return await _statPath(id.substring(5));
    throw FileOpException(FileOpFailure.unsupported, 'unknown id: $id');
  }

  @override
  Stream<List<int>> openRead(FileRef f) => File(f.path).openRead().handleError(
    (Object e) => throw fileOpExceptionFromIo(
      e as FileSystemException,
      f.path,
      fileId: f.id,
    ),
    test: (e) => e is FileSystemException,
  );

  // ---- write ----

  @override
  Future<String> createFolder(String parentPath, String name) async {
    validateFileName(name);
    final parent = _trimSlash(parentPath);
    final path = '$parent/$name';
    try {
      if (!await Directory(parent).exists()) {
        throw FileOpException(FileOpFailure.notFound, 'no folder: $parent');
      }
      if (await FileSystemEntity.type(path) != FileSystemEntityType.notFound) {
        throw FileOpException(FileOpFailure.targetExists, path);
      }
      await Directory(path).create();
      return path;
    } on FileSystemException catch (e) {
      throw fileOpExceptionFromIo(e, path);
    }
  }

  @override
  Future<FileRef> move(FileRef f, String targetFolder) async {
    final target = _trimSlash(targetFolder);
    if (target == f.folderPath) return f;
    await _requireFolder(target);
    final name = await uniqueName(f.name, (c) => _exists('$target/$c'));
    if (_isMs(f)) {
      final row = await _withConsent(
        f,
        () => _channel.moveMedia(_parseMsId(f.id), target, name),
      );
      return _emitIfChanged(f, _mediaRef(row));
    }
    final moved = await _movePath(f, '$target/$name');
    return _emitIfChanged(f, moved);
  }

  @override
  Future<FileRef> copy(FileRef f, String targetFolder) async {
    final target = _trimSlash(targetFolder);
    await _requireFolder(target);
    final name = await uniqueName(f.name, (c) => _exists('$target/$c'));
    if (_isMs(f)) {
      final row = await _guard(
        f.id,
        () => _channel.copyMedia(_parseMsId(f.id), target, name),
      );
      return _mediaRef(row);
    }
    return await _copyPath(f, '$target/$name');
  }

  @override
  Future<bool> requestWriteAccess(List<FileRef> files) async {
    final media = files.where(_isMs).toList();
    if (media.isEmpty || await _sdkInt() < 30 || _canSeeAllFiles()) {
      return true;
    }
    if (await _guard(null, _channel.canManageMedia)) return true;
    for (final chunk in _chunks(media)) {
      final granted = await _guard(
        null,
        () => _channel.requestWriteConsent([for (final f in chunk) f.uri]),
      );
      if (!granted) return false;
    }
    return true;
  }

  /// MediaStore would silently re-create a missing RELATIVE_PATH: a swipe
  /// action whose folder was deleted must fail instead (TASK-P2).
  Future<void> _requireFolder(String path) async {
    if (!await _folderExists(path)) {
      throw FileOpException(
        FileOpFailure.notFound,
        'target folder missing: $path',
      );
    }
  }

  @override
  Future<FileRef> rename(FileRef f, String newName) async {
    validateFileName(newName);
    if (newName == f.name) return f;
    // Shared storage is case-insensitive: "a.jpg" -> "A.jpg" is not a clash.
    final name = newName.toLowerCase() == f.name.toLowerCase()
        ? newName
        : await uniqueName(newName, (c) => _exists('${f.folderPath}/$c'));
    if (_isMs(f)) {
      final row = await _withConsent(
        f,
        () => _channel.renameMedia(_parseMsId(f.id), name),
      );
      return _emitIfChanged(f, _mediaRef(row));
    }
    final renamed = await _movePath(f, '${f.folderPath}/$name');
    return _emitIfChanged(f, renamed);
  }

  /// API 30+ media → system trash (one dialog per ≤500 files). Non-media
  /// and API ≤29 go to the pending-delete folder (D4), per file.
  @override
  Future<TrashResult> trashBatch(List<FileRef> files) async {
    final sdk = await _sdkInt();
    final trashed = <TrashedItem>[];
    final failed = <String, FileOpException>{};
    final media = <FileRef>[];
    final scanOld = <String>[];
    for (final f in files) {
      if (_isMs(f) && sdk >= 30) {
        media.add(f);
        continue;
      }
      final folder = _pendingFolder;
      if (folder == null) {
        failed[f.id] = FileOpException(
          FileOpFailure.unsupported,
          'no pending-delete folder',
          fileId: f.id,
        );
        continue;
      }
      try {
        final row = await folder.moveIn(f);
        trashed.add(
          TrashedItem(
            trashId: 'pending:${row.id}',
            original: f,
            location: TrashLocation.pendingFolder,
            trashedAt: row.deletedAt,
            expiresAt: row.expiresAt,
          ),
        );
        scanOld.add(f.path); // MediaStore drops the old entry
      } on FileOpException catch (e) {
        failed[f.id] = e;
      }
    }
    if (scanOld.isNotEmpty) _rescan(scanOld);
    for (final chunk in _chunks(media)) {
      final ok = await _guard(
        null,
        () => _channel.trashMedia([for (final f in chunk) f.uri], value: true),
      );
      if (!ok) {
        return TrashResult(
          trashed: trashed,
          failed: failed,
          userCancelled: true,
        );
      }
      final now = DateTime.now().toUtc();
      trashed.addAll([
        for (final f in chunk)
          TrashedItem(
            trashId: f.id,
            original: f,
            location: TrashLocation.systemTrash,
            trashedAt: now,
            expiresAt: now.add(systemTrashRetention),
          ),
      ]);
    }
    return TrashResult(trashed: trashed, failed: failed);
  }

  /// Media: one system dialog per ≤500 files (API 30+). Other files: dart:io.
  /// Declining throws `userCancelled`.
  @override
  Future<void> deletePermanentlyBatch(List<FileRef> files) async {
    final media = [
      for (final f in files)
        if (_isMs(f)) f,
    ];
    for (final chunk in _chunks(media)) {
      final ok = await _guard(
        null,
        () => _channel.deleteMedia([for (final f in chunk) f.uri]),
      );
      if (!ok) {
        throw const FileOpException(
          FileOpFailure.userCancelled,
          'delete request declined',
        );
      }
    }
    final paths = <String>[];
    for (final f in files.where((f) => !_isMs(f))) {
      try {
        await File(f.path).delete();
        paths.add(f.path);
      } on PathNotFoundException {
        // Already gone: the goal is reached.
      } on FileSystemException catch (e) {
        throw fileOpExceptionFromIo(e, f.path, fileId: f.id);
      }
    }
    if (paths.isNotEmpty) _rescan(paths);
  }

  /// System trash → back where it was (one dialog). Pending folder →
  /// original path (or `name (restored).ext`); its id may change.
  @override
  Future<FileRef> restore(TrashedItem item) async {
    if (item.location == TrashLocation.pendingFolder) {
      return await _restoreFromPendingFolder(item);
    }
    if (!_isMs(item.original)) {
      throw FileOpException(
        FileOpFailure.unsupported,
        'not in the system trash',
        fileId: item.original.id,
      );
    }
    final id = _parseMsId(item.original.id);
    // H1: already out of the trash (an earlier restore whose dialog result
    // was lost). Normal queries exclude trashed rows, so a hit means the
    // file is back: no second dialog.
    final existing = await _guard(
      item.original.id,
      () => _channel.statMedia(id),
    );
    if (existing != null) return _mediaRef(existing);
    final ok = await _guard(
      item.original.id,
      () => _channel.trashMedia([item.original.uri], value: false),
    );
    if (!ok) {
      throw FileOpException(
        FileOpFailure.userCancelled,
        'restore declined',
        fileId: item.original.id,
      );
    }
    final row = await _guard(item.original.id, () => _channel.statMedia(id));
    if (row == null) {
      throw FileOpException(
        FileOpFailure.notFound,
        'not in MediaStore after restore (expired?)',
        fileId: item.original.id,
      );
    }
    return _mediaRef(row);
  }

  Future<FileRef> _restoreFromPendingFolder(TrashedItem item) async {
    final folder = _pendingFolder;
    if (folder == null || !item.trashId.startsWith('pending:')) {
      throw FileOpException(
        FileOpFailure.notFound,
        'pending item ${item.trashId}',
        fileId: item.original.id,
      );
    }
    final path = await folder.restore(item.trashId.substring(8));
    FileRef? restored;
    if (_isMs(item.original)) {
      final ids = await _guard(null, () => _channel.scanPaths([path]));
      if (ids[path] case final id?) {
        final row = await _guard(null, () => _channel.statMedia(id));
        if (row != null) restored = _mediaRef(row);
      }
    } else {
      _rescan([path]);
    }
    restored ??= await _statPath(path);
    if (restored == null) {
      throw FileOpException(FileOpFailure.ioError, 'gone after restore: $path');
    }
    return _emitIfChanged(item.original, restored);
  }

  /// System-trash items: one dialog for all of them; pending items one by one
  /// (no dialog). Ids that changed are announced on [idChanges].
  @override
  Future<RestoreResult> restoreBatch(List<TrashedItem> items) async {
    final restored = <String, FileRef>{};
    final failed = <String, FileOpException>{};
    final system = [
      for (final i in items)
        if (i.location == TrashLocation.systemTrash && _isMs(i.original)) i,
    ];
    // H1: items already back (a lost dialog result) skip the dialog.
    final stillTrashed = <TrashedItem>[];
    for (final i in system) {
      final row = await _guard(
        i.original.id,
        () => _channel.statMedia(_parseMsId(i.original.id)),
      );
      if (row != null) {
        restored[i.trashId] = _mediaRef(row);
      } else {
        stillTrashed.add(i);
      }
    }
    for (final chunk in _chunkItems(stillTrashed)) {
      final ok = await _guard(
        null,
        () => _channel.trashMedia([
          for (final i in chunk) i.original.uri,
        ], value: false),
      );
      if (!ok) {
        return RestoreResult(
          restored: restored,
          failed: failed,
          userCancelled: true,
        );
      }
      for (final i in chunk) {
        final row = await _guard(
          i.original.id,
          () => _channel.statMedia(_parseMsId(i.original.id)),
        );
        if (row == null) {
          failed[i.trashId] = FileOpException(
            FileOpFailure.notFound,
            'already removed from the trash',
            fileId: i.original.id,
          );
        } else {
          restored[i.trashId] = _mediaRef(row);
        }
      }
    }
    for (final i in items.where((i) => !system.contains(i))) {
      try {
        restored[i.trashId] = await restore(i);
      } on FileOpException catch (e) {
        failed[i.trashId] = e;
      }
    }
    return RestoreResult(restored: restored, failed: failed);
  }

  @override
  Future<void> deleteFromTrash(List<TrashedItem> items) async {
    final system = [
      for (final i in items)
        if (i.location == TrashLocation.systemTrash && _isMs(i.original))
          i.original,
    ];
    if (system.isNotEmpty) await deletePermanentlyBatch(system);
    final pending = [
      for (final i in items)
        if (i.location == TrashLocation.pendingFolder &&
            i.trashId.startsWith('pending:'))
          i.trashId.substring(8),
    ];
    if (pending.isNotEmpty) await _pendingFolder?.deleteNow(pending);
  }

  static Iterable<List<TrashedItem>> _chunkItems(
    List<TrashedItem> items,
  ) sync* {
    for (var i = 0; i < items.length; i += maxUrisPerRequest) {
      yield items.sublist(
        i,
        i + maxUrisPerRequest > items.length
            ? items.length
            : i + maxUrisPerRequest,
      );
    }
  }

  @override
  Future<List<TrashedItem>> listTrashed() async {
    final pending = await _pendingFolder?.all() ?? const [];
    final rows = await _guard(null, _channel.listTrashed);
    return [
      for (final p in pending)
        TrashedItem(
          trashId: 'pending:${p.id}',
          original: FileRef(
            id: p.originalFileId,
            uri: p.originalPath,
            name: p.name,
            mimeType: p.mimeType,
            kind: kindFor(p.mimeType, p.name),
            sizeBytes: p.sizeBytes,
            modifiedAt: p.originalModifiedAt.toUtc(),
            folderPath: parentOf(p.originalPath),
            origin: _originOf(p.originalPath),
          ),
          location: TrashLocation.pendingFolder,
          trashedAt: p.deletedAt.toUtc(),
          expiresAt: p.expiresAt.toUtc(),
        ),
      for (final row in rows)
        if (_mediaRef(row) case final f)
          TrashedItem(
            trashId: f.id,
            original: f,
            location: TrashLocation.systemTrash,
            // MediaStore has no "trashed at"; the system keeps 30 days.
            trashedAt: _expires(row).subtract(systemTrashRetention),
            expiresAt: _expires(row),
          ),
    ];
  }

  /// How long Android keeps trashed media.
  static const systemTrashRetention = Duration(days: 30);

  /// Binder transactions are ~1 MB: at most this many URIs per request.
  static const maxUrisPerRequest = 500;

  int? _sdk;
  Future<int> _sdkInt() async {
    if (_sdk case final sdk?) return sdk;
    final sdk = await _guard(null, _channel.sdkInt);
    _sdk = sdk;
    return sdk;
  }

  static Iterable<List<FileRef>> _chunks(List<FileRef> files) sync* {
    for (var i = 0; i < files.length; i += maxUrisPerRequest) {
      yield files.sublist(
        i,
        i + maxUrisPerRequest > files.length
            ? files.length
            : i + maxUrisPerRequest,
      );
    }
  }

  static DateTime _expires(MediaRow row) => DateTime.fromMillisecondsSinceEpoch(
    ((row['expires'] as int?) ?? 0) * 1000,
    isUtc: true,
  );

  // ---- helpers ----

  FileRef _mediaRef(MediaRow row) =>
      mediaRefFromRow(row, primaryRoot: primaryRoot);

  Future<FileRef?> _statPath(String path) async {
    final stat = await FileStat.stat(path);
    if (stat.type != FileSystemEntityType.file) return null;
    return _pathRef(path, stat);
  }

  FileRef _pathRef(String path, FileStat stat) {
    final name = nameOf(path);
    return FileRef(
      id: 'path:$path',
      uri: path,
      name: name,
      kind: kindFor(null, name),
      sizeBytes: stat.size,
      modifiedAt: stat.modified.toUtc(),
      folderPath: parentOf(path),
      origin: _originOf(path),
    );
  }

  /// Rename on the same volume; copy → size check → delete across volumes.
  Future<FileRef> _movePath(FileRef f, String newPath) async {
    final from = File(f.path);
    if (!await from.exists()) {
      throw FileOpException(FileOpFailure.notFound, f.path, fileId: f.id);
    }
    try {
      await Directory(parentOf(newPath)).create(recursive: true);
      try {
        await from.rename(newPath);
      } on FileSystemException catch (e) {
        if (e.osError?.errorCode != _exdev) rethrow;
        await _copyVerified(from, newPath);
        await from.delete();
      }
    } on FileSystemException catch (e) {
      throw fileOpExceptionFromIo(e, f.path, fileId: f.id);
    }
    _rescan([f.path, newPath]);
    return (await _statPath(newPath)) ??
        (throw const FileOpException(FileOpFailure.ioError, 'gone after move'));
  }

  Future<FileRef> _copyPath(FileRef f, String newPath) async {
    final from = File(f.path);
    if (!await from.exists()) {
      throw FileOpException(FileOpFailure.notFound, f.path, fileId: f.id);
    }
    try {
      await Directory(parentOf(newPath)).create(recursive: true);
      await _copyVerified(from, newPath);
    } on FileSystemException catch (e) {
      throw fileOpExceptionFromIo(e, f.path, fileId: f.id);
    }
    _rescan([newPath]);
    return (await _statPath(newPath)) ??
        (throw const FileOpException(FileOpFailure.ioError, 'gone after copy'));
  }

  /// Copies, keeps the modified time, and checks the size. On any failure the
  /// partial copy is removed and the error rethrown.
  Future<void> _copyVerified(File from, String newPath) async {
    final copy = File(newPath);
    try {
      final stat = await from.stat();
      await from.copy(newPath);
      await copy.setLastModified(stat.modified);
      final copied = await copy.length();
      if (copied != stat.size) {
        throw FileOpException(
          FileOpFailure.ioError,
          'size mismatch after copy: $copied != ${stat.size}',
        );
      }
    } on Object {
      if (await copy.exists()) await copy.delete();
      rethrow;
    }
  }

  /// Lets MediaStore / other apps see the change. A failed scan doesn't undo
  /// a finished move, so it is logged rather than thrown.
  void _rescan(List<String> paths) {
    unawaited(
      _channel
          .scanPaths(paths)
          .then<void>(
            (_) {},
            onError: (Object e) => developer.log(
              'media scan failed for $paths: $e',
              name: 'kfm.files',
            ),
          ),
    );
  }

  /// Runs [op]; if MediaStore needs the user's consent (API 30+, file owned
  /// by another app, no All files access), asks once and retries.
  Future<T> _withConsent<T>(FileRef f, Future<T> Function() op) async {
    try {
      return await op();
    } on FilesChannelException catch (e) {
      if (e.code != 'NEEDS_CONSENT') throw _map(e, f.id);
    }
    final granted = await _guard(
      f.id,
      () => _channel.requestWriteConsent([f.uri]),
    );
    if (!granted) {
      throw FileOpException(
        FileOpFailure.userCancelled,
        'write consent declined',
        fileId: f.id,
      );
    }
    return await _guard(f.id, op);
  }

  Future<T> _guard<T>(String? fileId, Future<T> Function() op) async {
    try {
      return await op();
    } on FilesChannelException catch (e) {
      throw _map(e, fileId);
    }
  }

  FileOpException _map(FilesChannelException e, String? fileId) {
    final failure = switch (e.code) {
      'NOT_FOUND' => FileOpFailure.notFound,
      'TARGET_EXISTS' => FileOpFailure.targetExists,
      'PERMISSION_DENIED' || 'NEEDS_CONSENT' => FileOpFailure.permissionDenied,
      // Media can't be moved there without All files access (e.g. a photo
      // outside DCIM/Pictures), or across volumes (U2 / N11 safe move).
      'NOT_ALLOWED' || 'CROSS_VOLUME' => FileOpFailure.unsupported,
      // H1: the activity died while a system dialog was open. The caller
      // re-queues; the next commit reconciles from the file state.
      'INTERRUPTED' => FileOpFailure.ioError,
      _ => FileOpFailure.ioError,
    };
    return FileOpException(failure, '${e.code}: ${e.message}', fileId: fileId);
  }

  FileRef _emitIfChanged(FileRef old, FileRef updated) {
    if (updated.id != old.id) _idChanges.add(FileIdChange(old.id, updated));
    return updated;
  }

  Future<bool> _exists(String path) async =>
      await FileSystemEntity.type(path) != FileSystemEntityType.notFound;

  FileOrigin _originOf(String path) =>
      path == primaryRoot || path.startsWith('$primaryRoot/')
      ? FileOrigin.local
      : FileOrigin.external;

  static bool _isMs(FileRef f) => f.id.startsWith('ms:');

  static int _parseMsId(String id) =>
      int.tryParse(id.substring(3)) ??
      (throw FileOpException(FileOpFailure.unsupported, 'bad id: $id'));

  static String _trimSlash(String path) => path.length > 1 && path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;

  /// Linux EXDEV: rename across file systems.
  static const _exdev = 18;
}
