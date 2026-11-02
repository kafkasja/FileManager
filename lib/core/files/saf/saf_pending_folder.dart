import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_ids.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/pending_folder.dart';
import 'package:kfm/core/files/saf/saf_channel.dart';
import 'package:kfm/core/files/saf/saf_file_source.dart';
import 'package:kfm/core/utils/random_id.dart';

/// D4's pending-delete folder on SAF volumes (TASK-U2): `<root>/.KFMTrash`
/// created with `createDocument`, files moved in with `moveDocument` (same
/// tree, instant), `.nomedia` + `.index.jsonl` written through the
/// channel. Rows share `pending_folder_items` with [PendingFolder]:
/// `volumeId` = the volume root path, `storedPath` = the stored file's
/// `saf:` id (the prefix tells the two kinds apart; [PendingFolder] skips
/// them). Never copies + deletes as a fallback.
class SafPendingFolder {
  new({
    required this._db,
    required this._channel,
    required this._locator,
    required this._retentionDays,
    this._clock = DateTime.now,
    Random? random,
  }) : _random = random ?? Random.secure();

  final AppDatabase _db;
  final SafPlatform _channel;
  final SafLocator _locator;
  final Future<int> Function() _retentionDays;
  final DateTime Function() _clock;
  final Random _random;

  static bool isSafRow(PendingFolderItemRow r) =>
      r.storedPath.startsWith('saf:');

  Future<String> _trashDoc(SafTree tree) async {
    for (final d in await _channel.list(tree.treeUri, tree.rootDoc)) {
      if (d.isDir && d.name == PendingFolder.folderName) return d.id;
    }
    final created = await _channel.createDir(
      tree.treeUri,
      tree.rootDoc,
      PendingFolder.folderName,
    );
    await _channel.writeText(tree.treeUri, created.id, '.nomedia', '');
    return created.id;
  }

  /// Moves [f] (a `saf:` file) into its volume's folder. Throws
  /// `pendingFolderUnavailable` when the folder can't be made or the
  /// provider can't move; the file stays put.
  Future<PendingFolderItemRow> moveIn(FileRef f) async {
    final at = _locator.locate(f.id);
    final parent = _locator.locate(f.folderPath);
    if (at == null || parent == null) {
      throw FileOpException(
        FileOpFailure.unavailable,
        'no SAF grant for ${f.path}',
        fileId: f.id,
      );
    }
    final tree = at.tree;
    final String trash;
    try {
      trash = await _trashDoc(tree);
    } on FileOpException catch (e) {
      throw FileOpException(
        FileOpFailure.pendingFolderUnavailable,
        'cannot create ${PendingFolder.folderName}: ${e.message}',
        fileId: f.id,
      );
    }
    final id = randomHexId(_random);
    final storedName = '${id}__${f.name}';
    final now = _clock().toUtc();
    final days = clampRetentionDays(await _retentionDays());
    // The row (and its index line) goes first, at the expected stored id,
    // so a kill between the move and the insert never leaves an
    // untracked file in the folder (D4/H2).
    var row = PendingFolderItemRow(
      id: id,
      originalPath: f.path,
      storedPath: safId(tree.treeUri, '$trash/$storedName'),
      volumeId: tree.root,
      name: f.name,
      mimeType: f.mimeType,
      sizeBytes: f.sizeBytes,
      originalFileId: f.id,
      originalModifiedAt: f.modifiedAt,
      deletedAt: now,
      expiresAt: now.add(Duration(days: days)),
    );
    await _db.into(_db.pendingFolderItems).insert(row);
    await _writeIndex(tree, trash);
    Future<void> undoRow() async {
      await (_db.delete(
        _db.pendingFolderItems,
      )..where((p) => p.id.equals(id))).go();
      await _writeIndex(tree, trash);
    }

    final SafDoc renamed;
    try {
      renamed = await _channel.rename(tree.treeUri, at.doc, storedName);
    } on FileOpException {
      await undoRow();
      rethrow;
    }
    SafDoc? moved;
    Object? failure;
    try {
      moved = await _channel.move(tree.treeUri, renamed.id, parent.doc, trash);
    } on FileOpException catch (e) {
      failure = e;
    }
    if (moved == null) {
      // Put the name back: the file stays where it was, untracked.
      await _channel.rename(tree.treeUri, renamed.id, f.name);
      await undoRow();
      throw FileOpException(
        FileOpFailure.pendingFolderUnavailable,
        'provider cannot move into ${PendingFolder.folderName}: $failure',
        fileId: f.id,
      );
    }
    final stored = safId(tree.treeUri, moved.id);
    if (stored != row.storedPath) {
      row = row.copyWith(storedPath: stored);
      await (_db.update(_db.pendingFolderItems)..where((p) => p.id.equals(id)))
          .write(PendingFolderItemsCompanion(storedPath: Value(stored)));
      await _writeIndex(tree, trash);
    }
    return row;
  }

  /// Moves an item back (`name (restored).ext` when the name is taken; a
  /// deleted folder is recreated). Returns the restored file's `saf:` id.
  Future<String> restore(String itemId) async {
    final row = await _byId(itemId);
    final stored = _locator.locate(row.storedPath);
    if (stored == null) {
      throw FileOpException(
        FileOpFailure.unavailable,
        'volume not mounted: ${row.volumeId}',
        fileId: row.originalFileId,
      );
    }
    final tree = stored.tree;
    final folderPath = parentOf(row.originalPath);
    final folder = await _ensureFolder(folderPath);
    final names = {
      for (final d in await _channel.list(tree.treeUri, folder)) d.name,
    };
    var name = row.name;
    if (names.contains(name)) {
      final (base, ext) = splitExtension(name);
      name = await uniqueName(
        '$base (restored)$ext',
        (c) async => names.contains(c),
      );
    }
    final trash = await _trashDoc(tree);
    final renamed = await _channel.rename(tree.treeUri, stored.doc, name);
    SafDoc? moved;
    try {
      moved = await _channel.move(tree.treeUri, renamed.id, trash, folder);
    } on FileOpException {
      moved = null;
    }
    if (moved == null) {
      // Back to its stored name: the row still points at it.
      await _channel.rename(tree.treeUri, renamed.id, nameOf(stored.doc));
      throw FileOpException(
        FileOpFailure.unsupported,
        'provider cannot move back',
        fileId: row.originalFileId,
      );
    }
    await _remove(row, tree, trash);
    return safId(tree.treeUri, moved.id);
  }

  Future<String> _ensureFolder(String path) async {
    final at = _locator.locate(path);
    if (at == null) {
      throw FileOpException(FileOpFailure.unavailable, 'no grant: $path');
    }
    if (await _channel.stat(at.tree.treeUri, at.doc) != null) return at.doc;
    final parent = await _ensureFolder(parentOf(path));
    return (await _channel.createDir(at.tree.treeUri, parent, nameOf(path))).id;
  }

  /// "Delete forever" (D5).
  Future<void> deleteNow(List<String> itemIds) async {
    for (final id in itemIds) {
      await _deleteItem(await _byId(id));
    }
  }

  /// Deletes expired SAF items on mounted volumes (app start). Returns the
  /// number purged.
  Future<int> purgeExpired({DateTime? now}) async {
    final cutoff = (now ?? _clock()).toUtc();
    final expired =
        await (_db.select(_db.pendingFolderItems)..where(
              (p) =>
                  p.expiresAt.isSmallerOrEqualValue(cutoff) &
                  p.storedPath.like('saf:%'),
            ))
            .get();
    var purged = 0;
    for (final row in expired) {
      if (_locator.locate(row.storedPath) == null) continue;
      await _deleteItem(row);
      purged++;
    }
    return purged;
  }

  Future<void> _deleteItem(PendingFolderItemRow row) async {
    final at = _locator.locate(row.storedPath);
    if (at == null) {
      throw FileOpException(
        FileOpFailure.unavailable,
        'volume not mounted: ${row.volumeId}',
        fileId: row.originalFileId,
      );
    }
    await _channel.delete(at.tree.treeUri, at.doc);
    await _remove(row, at.tree, null);
  }

  Future<void> _remove(
    PendingFolderItemRow row,
    SafTree tree,
    String? trash,
  ) async {
    await (_db.delete(
      _db.pendingFolderItems,
    )..where((p) => p.id.equals(row.id))).go();
    await _writeIndex(tree, trash ?? await _trashDoc(tree));
  }

  Future<PendingFolderItemRow> _byId(String id) async =>
      await (_db.select(
        _db.pendingFolderItems,
      )..where((p) => p.id.equals(id))).getSingleOrNull() ??
      (throw FileOpException(FileOpFailure.notFound, 'pending item $id'));

  Future<void> _writeIndex(SafTree tree, String trash) async {
    final rows = await (_db.select(
      _db.pendingFolderItems,
    )..where((p) => p.volumeId.equals(tree.root))).get();
    await _channel.writeText(
      tree.treeUri,
      trash,
      PendingFolder.indexFileName,
      rows
          .map(
            (r) =>
                '${jsonEncode({'id': r.id, 'originalPath': r.originalPath, 'storedPath': r.storedPath, 'deletedAt': r.deletedAt.toUtc().toIso8601String(), 'expiresAt': r.expiresAt.toUtc().toIso8601String()})}\n',
          )
          .join(),
    );
  }
}
