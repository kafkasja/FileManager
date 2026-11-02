import 'dart:async';
import 'dart:io';

import 'package:kfm/core/background/file_hasher.dart';
import 'package:kfm/core/files/file_ids.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/folder_listing.dart';
import 'package:kfm/core/files/saf/saf_channel.dart';
import 'package:kfm/core/files/saf/saf_pending_folder.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:meta/meta.dart';

/// A persisted SAF grant on a mounted volume (U1): [root] is the volume
/// path (`/storage/1234-ABCD`), [rootDoc] the tree's document id
/// (`1234-ABCD:`).
@immutable
class SafTree {
  const new({required this.root, required this.treeUri, required this.rootDoc});

  final String root;
  final String treeUri;
  final String rootDoc;

  @override
  bool operator ==(Object other) =>
      other is SafTree &&
      other.root == root &&
      other.treeUri == treeUri &&
      other.rootDoc == rootDoc;

  @override
  int get hashCode => Object.hash(root, treeUri, rootDoc);
}

/// A document inside a [SafTree].
typedef SafLocation = ({SafTree tree, String doc});

/// Maps paths and `saf:` ids to tree documents. Only externalstorage-style
/// document ids (`<rootDoc><relative path>`) are supported: every U1 grant
/// is a volume root of that provider.
class SafLocator {
  new(this._trees);

  final List<SafTree> Function() _trees;

  List<SafTree> get trees => _trees();

  SafTree? treeOfPath(String path) {
    for (final t in _trees()) {
      if (path == t.root || path.startsWith('${t.root}/')) return t;
    }
    return null;
  }

  SafTree? treeOfUri(String treeUri) {
    for (final t in _trees()) {
      if (t.treeUri == treeUri) return t;
    }
    return null;
  }

  /// A path under a granted root, or a `saf:` id of a granted tree.
  SafLocation? locate(String pathOrId) {
    if (parseSafId(pathOrId) case final id?) {
      final tree = treeOfUri(id.treeUri);
      return tree == null ? null : (tree: tree, doc: id.documentId);
    }
    final path = _trimSlash(pathOrId);
    final tree = treeOfPath(path);
    if (tree == null) return null;
    final rel = path == tree.root ? '' : path.substring(tree.root.length + 1);
    return (tree: tree, doc: '${tree.rootDoc}$rel');
  }

  bool owns(String pathOrId) => locate(pathOrId) != null;

  /// The path of [doc], or null for a document id of another form.
  String? pathOf(SafTree tree, String doc) {
    if (!doc.startsWith(tree.rootDoc)) return null;
    final rel = doc.substring(tree.rootDoc.length);
    return rel.isEmpty ? tree.root : '${tree.root}/$rel';
  }

  static String _trimSlash(String p) =>
      p.length > 1 && p.endsWith('/') ? p.substring(0, p.length - 1) : p;
}

/// Files on SAF-granted volumes (TASK-U2): SD cards and USB drives that
/// can't be reached by path. Ids `saf:<tree>|<docId>`; folders are paths
/// (or `saf:` ids). Moves stay inside one tree (`moveDocument`); other
/// places go through `CrossPlaceOps` (the routing source decides).
class SafFileSource
    implements FileSource, BrowsableSource, CopiesOut, HashesNatively {
  new({
    required this._channel,
    required List<SafTree> Function() trees,
    this._pendingFolder,
    Future<Directory> Function()? tempDir,
  }) : locator = SafLocator(trees),
       _tempDir = tempDir ?? (() => Directory.systemTemp.createTemp('kfm_saf'));

  final SafPlatform _channel;
  final SafLocator locator;
  final SafPendingFolder? _pendingFolder;
  final Future<Directory> Function() _tempDir;
  final StreamController<FileIdChange> _idChanges =
      StreamController<FileIdChange>.broadcast();

  /// Bytes per channel read (openRead).
  static const int readChunk = 512 * 1024;

  Future<void> dispose() => _idChanges.close();

  @override
  Stream<FileIdChange> get idChanges => _idChanges.stream;

  // ---- read ----

  SafLocation _require(String pathOrId, {String? fileId}) =>
      locator.locate(pathOrId) ??
      (throw FileOpException(
        FileOpFailure.unavailable,
        'no SAF grant for $pathOrId',
        fileId: fileId,
      ));

  FileRef _ref(SafTree tree, SafDoc d) {
    final path = locator.pathOf(tree, d.id) ?? '${tree.root}/${d.name}';
    return FileRef(
      id: safId(tree.treeUri, d.id),
      uri: '${tree.treeUri}/document/${Uri.encodeComponent(d.id)}',
      name: d.name,
      mimeType: d.mime,
      kind: kindFor(d.mime, d.name),
      sizeBytes: d.sizeBytes,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(
        d.modifiedMs,
        isUtc: true,
      ),
      folderPath: parentOf(path),
      origin: FileOrigin.external,
      hidden: d.name.startsWith('.') || isInHiddenFolder(path, root: tree.root),
    );
  }

  /// A ref for the file at [path] (no I/O): e.g. an `ms:` SD photo seen
  /// through its SAF grant. Null when no grant covers it.
  String? idForPath(String path) => switch (locator.locate(path)) {
    final l? => safId(l.tree.treeUri, l.doc),
    null => null,
  };

  @override
  Future<FolderListing> listChildren(
    String folder, {
    bool includeHidden = false,
  }) async {
    final at = _require(folder);
    final docs = await _channel.list(at.tree.treeUri, at.doc);
    final folders = <FolderItem>[];
    final files = <FileRef>[];
    for (final d in docs) {
      if (!includeHidden && d.name.startsWith('.')) continue;
      if (d.isDir) {
        final path = locator.pathOf(at.tree, d.id);
        if (path != null) folders.add(FolderItem(id: path, name: d.name));
      } else {
        files.add(_ref(at.tree, d));
      }
    }
    return FolderListing(folders: folders, files: files);
  }

  @override
  Stream<List<FileRef>> scan({FileQuery query = FileQuery.all}) async* {
    final roots = switch (query.rootPath) {
      final r? => [_require(r)],
      null => [for (final t in locator.trees) (tree: t, doc: t.rootDoc)],
    };
    final page = <FileRef>[];
    for (final start in roots) {
      final pending = [start.doc];
      while (pending.isNotEmpty) {
        final doc = pending.removeLast();
        final children = await _channel.list(start.tree.treeUri, doc);
        if (!query.includeHidden &&
            children.any((c) => c.name == '.nomedia' && !c.isDir)) {
          continue;
        }
        for (final c in children) {
          if (!query.includeHidden && c.name.startsWith('.')) continue;
          if (c.isDir) {
            if (query.recursive) pending.add(c.id);
            continue;
          }
          final f = _ref(start.tree, c);
          if (!query.wants(f.kind)) continue;
          if (query.modifiedAfter case final after?
              when !f.modifiedAt.isAfter(after)) {
            continue;
          }
          if (query.minSizeBytes case final min? when f.sizeBytes < min) {
            continue;
          }
          page.add(f);
          if (page.length >= query.pageSize) {
            yield List.of(page);
            page.clear();
          }
        }
      }
    }
    if (page.isNotEmpty) yield page;
  }

  @override
  Future<FileRef?> stat(String id) async {
    // No grant / not mounted: unknown, not gone (jobs pause, D2 retries).
    final at = _require(id, fileId: id);
    final d = await _channel.stat(at.tree.treeUri, at.doc);
    return d == null || d.isDir ? null : _ref(at.tree, d);
  }

  @override
  Stream<List<int>> openRead(FileRef f, {int start = 0, int? end}) async* {
    final at = _require(f.id, fileId: f.id);
    var pos = start;
    while (end == null || pos < end) {
      final want = end == null
          ? readChunk
          : (end - pos < readChunk ? end - pos : readChunk);
      final bytes = await _channel.read(at.tree.treeUri, at.doc, pos, want);
      if (bytes.isEmpty) break;
      yield bytes;
      pos += bytes.length;
      if (bytes.length < want) break;
    }
  }

  @override
  Future<String?> copyOut(FileRef f, String path) async {
    final at = _require(f.id, fileId: f.id);
    final r = await _channel.copyOut(at.tree.treeUri, at.doc, path);
    return r.sha256.isEmpty ? null : r.sha256;
  }

  @override
  Future<String> sha256Of(FileRef f) {
    final at = _require(f.id, fileId: f.id);
    return _channel.sha256(at.tree.treeUri, at.doc);
  }

  @override
  Future<FileRef?> statPath(String path) async {
    final at = locator.locate(path);
    if (at == null) return null;
    final d = await _channel.stat(at.tree.treeUri, at.doc);
    return d == null || d.isDir ? null : _ref(at.tree, d);
  }

  // ---- write ----

  Future<SafDoc> _folderDoc(SafLocation at, String what) async {
    final d = await _channel.stat(at.tree.treeUri, at.doc);
    if (d == null || !d.isDir) {
      throw FileOpException(FileOpFailure.notFound, 'no folder: $what');
    }
    return d;
  }

  Future<Set<String>> _namesIn(SafLocation folder) async => {
    for (final d in await _channel.list(folder.tree.treeUri, folder.doc))
      d.name.toLowerCase(),
  };

  @override
  Future<String> createFolder(String parentPath, String name) async {
    validateFileName(name);
    final at = _require(parentPath);
    await _folderDoc(at, parentPath);
    if ((await _namesIn(at)).contains(name.toLowerCase())) {
      throw FileOpException(FileOpFailure.targetExists, '$parentPath/$name');
    }
    final d = await _channel.createDir(at.tree.treeUri, at.doc, name);
    return locator.pathOf(at.tree, d.id) ?? '${at.tree.root}/$name';
  }

  /// Creates every missing folder of [path] (D5 restore into a deleted
  /// folder). Returns the folder's location.
  Future<SafLocation> ensureFolder(String path) async {
    final at = _require(path);
    if (await _channel.stat(at.tree.treeUri, at.doc) != null) return at;
    final parent = parentOf(path);
    final p = await ensureFolder(parent);
    await _channel.createDir(p.tree.treeUri, p.doc, nameOf(path));
    return at;
  }

  @override
  Future<FileRef> move(FileRef f, String targetFolder) async {
    final from = _require(f.id, fileId: f.id);
    final to = _require(targetFolder);
    if (to.tree != from.tree) {
      throw FileOpException(
        FileOpFailure.unsupported,
        'move across SAF trees',
        fileId: f.id,
      );
    }
    final current = await _channel.stat(from.tree.treeUri, from.doc);
    if (current == null) {
      throw FileOpException(FileOpFailure.notFound, 'gone', fileId: f.id);
    }
    final parent = _require(f.folderPath);
    if (parent.doc == to.doc) return f;
    await _folderDoc(to, targetFolder);
    final names = await _namesIn(to);
    final name = await uniqueName(
      f.name,
      (c) async => names.contains(c.toLowerCase()),
    );
    // moveDocument keeps the name: a clash is renamed first, and renamed
    // back when the move fails (the file never stays under another name).
    var doc = from.doc;
    var renamed = false;
    Future<void> renameBack() async {
      if (!renamed) return;
      doc = (await _channel.rename(from.tree.treeUri, doc, f.name)).id;
      renamed = false;
    }

    final SafDoc? moved;
    try {
      if (name != f.name) {
        doc = (await _channel.rename(from.tree.treeUri, doc, name)).id;
        renamed = true;
      }
      moved = await _channel.move(from.tree.treeUri, doc, parent.doc, to.doc);
    } on FileOpException {
      await renameBack();
      rethrow;
    }
    final FileRef result;
    if (moved != null) {
      result = _ref(from.tree, moved);
    } else {
      // The provider can't move: a verified copy, then the original goes.
      await renameBack();
      result = await _copyInto(f, to, name);
      try {
        await _channel.delete(from.tree.treeUri, doc);
      } on FileOpException {
        // Keep the original (never lose data): drop the copy again.
        final copy = locator.locate(result.id);
        if (copy != null) {
          await _channel.delete(copy.tree.treeUri, copy.doc);
        }
        rethrow;
      }
    }
    _idChanges.add(FileIdChange(f.id, result));
    return result;
  }

  /// Copies [f] into [to] as [name] and verifies the copy by SHA-256
  /// (rule 10); a mismatch deletes the copy and throws `ioError`.
  Future<FileRef> _copyInto(FileRef f, SafLocation to, String name) async {
    final dir = await _tempDir();
    final part = File('${dir.path}/saf-copy.part');
    try {
      final expected =
          await copyOut(f, part.path) ?? await hashFileInIsolate(part.path);
      final d = await _channel.importFile(
        to.tree.treeUri,
        to.doc,
        name,
        f.mimeType,
        part.path,
      );
      String? actual;
      try {
        actual = await _channel.sha256(to.tree.treeUri, d.id);
      } on FileOpException {
        actual = null;
      }
      if (actual != expected) {
        try {
          await _channel.delete(to.tree.treeUri, d.id);
        } on FileOpException {
          // Reported below; the original is untouched either way.
        }
        throw FileOpException(
          FileOpFailure.ioError,
          'verification failed: $expected != $actual',
          fileId: f.id,
        );
      }
      return _ref(to.tree, d);
    } finally {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        // Cache: the OS clears it.
      }
    }
  }

  @override
  Future<FileRef> copy(FileRef f, String targetFolder) async {
    final to = _require(targetFolder);
    await _folderDoc(to, targetFolder);
    if (await stat(f.id) == null) {
      throw FileOpException(FileOpFailure.notFound, 'gone', fileId: f.id);
    }
    final names = await _namesIn(to);
    final name = await uniqueName(
      f.name,
      (c) async => names.contains(c.toLowerCase()),
    );
    return await _copyInto(f, to, name);
  }

  @override
  Future<FileRef> rename(FileRef f, String newName) async {
    checkPathSegment(newName);
    if (newName == f.name) return f;
    final at = _require(f.id, fileId: f.id);
    final parent = _require(f.folderPath);
    final names = await _namesIn(parent)
      ..remove(f.name.toLowerCase());
    final name = newName.toLowerCase() == f.name.toLowerCase()
        ? newName
        : await uniqueName(
            newName,
            (c) async => names.contains(c.toLowerCase()),
          );
    final d = await _channel.rename(at.tree.treeUri, at.doc, name);
    final renamed = _ref(at.tree, d);
    if (renamed.id != f.id) _idChanges.add(FileIdChange(f.id, renamed));
    return renamed;
  }

  @override
  Future<({String path, List<FileRef> files})> renameFolder(
    String folderPath,
    String newName,
  ) async {
    validateFileName(newName);
    final at = _require(folderPath);
    if (at.doc == at.tree.rootDoc) {
      throw const FileOpException(FileOpFailure.unsupported, 'volume root');
    }
    final parent = _require(parentOf(folderPath));
    final before = await scan(
      query: FileQuery(rootPath: folderPath, includeHidden: true),
    ).expand((p) => p).toList();
    if ((await _namesIn(parent)).contains(newName.toLowerCase())) {
      throw FileOpException(FileOpFailure.targetExists, newName);
    }
    final d = await _channel.rename(at.tree.treeUri, at.doc, newName);
    final path = locator.pathOf(at.tree, d.id) ?? folderPath;
    final files = await scan(
      query: FileQuery(rootPath: path, includeHidden: true),
    ).expand((p) => p).toList();
    final byRel = {for (final f in files) f.path.substring(path.length): f};
    for (final old in before) {
      final now = byRel[old.path.substring(folderPath.length)];
      if (now != null && now.id != old.id) {
        _idChanges.add(FileIdChange(old.id, now));
      }
    }
    return (path: path, files: files);
  }

  @override
  Future<TrashResult> trashBatch(List<FileRef> files) async {
    final folder = _pendingFolder;
    final trashed = <TrashedItem>[];
    final failed = <String, FileOpException>{};
    for (final f in files) {
      if (folder == null) {
        failed[f.id] = FileOpException(
          FileOpFailure.pendingFolderUnavailable,
          'no SAF pending folder',
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
            storedPath: row.storedPath,
          ),
        );
      } on FileOpException catch (e) {
        failed[f.id] = e;
      }
    }
    return TrashResult(trashed: trashed, failed: failed);
  }

  @override
  Future<void> deletePermanentlyBatch(List<FileRef> files) async {
    for (final f in files) {
      final at = _require(f.id, fileId: f.id);
      await _channel.delete(at.tree.treeUri, at.doc);
    }
  }

  @override
  Future<FileRef> restore(TrashedItem item) async {
    final folder = _pendingFolder;
    if (folder == null || !item.trashId.startsWith('pending:')) {
      throw FileOpException(
        FileOpFailure.notFound,
        'pending item ${item.trashId}',
        fileId: item.original.id,
      );
    }
    final id = await folder.restore(item.trashId.substring(8));
    final restored = await stat(id);
    if (restored == null) {
      throw FileOpException(FileOpFailure.ioError, 'gone after restore: $id');
    }
    if (restored.id != item.original.id) {
      _idChanges.add(FileIdChange(item.original.id, restored));
    }
    return restored;
  }

  /// SAF pending items are listed by the Android source (one table).
  @override
  Future<List<TrashedItem>> listTrashed() async => const [];

  @override
  Future<RestoreResult> restoreBatch(List<TrashedItem> items) async {
    final restored = <String, FileRef>{};
    final failed = <String, FileOpException>{};
    for (final i in items) {
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
    final ids = [
      for (final i in items)
        if (i.trashId.startsWith('pending:')) i.trashId.substring(8),
    ];
    if (ids.isNotEmpty) await _pendingFolder?.deleteNow(ids);
  }

  @override
  Future<bool> requestWriteAccess(List<FileRef> files) async => true;

  /// Unknown through SAF; U1's volume stats cover the pre-checks.
  @override
  Future<int?> freeBytes(String folderPath) async => null;

  @override
  Future<List<FileRef>> registerCreated(List<String> paths) async => [
    for (final p in paths) ?await statPath(p),
  ];

  @override
  Future<FileRef> importFile(
    File staged, {
    required String targetFolder,
    required String name,
    String? mimeType,
  }) async {
    validateFileName(name);
    final to = await ensureFolder(_trimSlash(targetFolder));
    final names = await _namesIn(to);
    final unique = await uniqueName(
      name,
      (c) async => names.contains(c.toLowerCase()),
    );
    final d = await _channel.importFile(
      to.tree.treeUri,
      to.doc,
      unique,
      mimeType,
      staged.path,
    );
    try {
      await staged.delete();
    } on FileSystemException {
      // App-private: swept at the next start.
    }
    return _ref(to.tree, d);
  }

  @override
  bool supports(FileOp op, FileRef f) => true;

  static String _trimSlash(String p) =>
      p.length > 1 && p.endsWith('/') ? p.substring(0, p.length - 1) : p;
}
