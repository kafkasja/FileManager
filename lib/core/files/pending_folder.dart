import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/io_errors.dart';

/// Retention in days is clamped to this range (corrupt values → default).
const ({int fallback, int max, int min}) kPendingRetentionRange = (
  min: 1,
  max: 90,
  fallback: 7,
);

int clampRetentionDays(int days) =>
    days < kPendingRetentionRange.min || days > kPendingRetentionRange.max
    ? kPendingRetentionRange.fallback
    : days;

/// The hidden pending-delete folder (TASK-D4): one `.KFMTrash` per storage
/// volume, so moving in is an instant rename even for 4 GB videos. Holds
/// `.nomedia` (galleries skip it) and `.index.jsonl` (rebuilds the table if
/// app data is cleared). Never copies + deletes as a fallback.
class PendingFolder {
  new({
    required this._db,
    required this._volumeRootOf,
    required this._retentionDays,
    this._clock = DateTime.now,
    Random? random,
    @visibleForTesting
    Future<void> Function(String from, String to)? renameOverride,
  }) : _random = random ?? Random.secure(),
       _rename = renameOverride ?? _renameFile;

  static const folderName = '.KFMTrash';
  static const indexFileName = '.index.jsonl';

  /// errno for a rename across mount points.
  static const _exdev = 18;

  final AppDatabase _db;
  final String Function(String path) _volumeRootOf;
  final Future<int> Function() _retentionDays;
  final DateTime Function() _clock;
  final Random _random;
  final Future<void> Function(String from, String to) _rename;

  static Future<void> _renameFile(String from, String to) =>
      File(from).rename(to);

  String folderFor(String volumeRoot) => '$volumeRoot/$folderName';

  /// Moves [f] into its volume's folder. Throws [FileOpException]; the file
  /// stays put. `pendingFolderUnavailable` (H2) when the folder can't be
  /// created there or the rename crosses mounts; `permissionDenied` when the
  /// file itself can't be moved.
  Future<PendingFolderItemRow> moveIn(FileRef f) async {
    final root = _volumeRootOf(f.path);
    final folder = folderFor(root);
    final id = _newId();
    final stored = '$folder/${id}__${f.name}';
    final now = _clock().toUtc();
    final days = clampRetentionDays(await _retentionDays());
    try {
      await Directory(folder).create(recursive: true);
      final noMedia = File('$folder/.nomedia');
      if (!await noMedia.exists()) await noMedia.create();
    } on FileSystemException catch (e) {
      throw FileOpException(
        FileOpFailure.pendingFolderUnavailable,
        'cannot create $folder: ${e.osError?.message ?? e.message}',
        fileId: f.id,
      );
    }
    try {
      await _rename(f.path, stored);
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == _exdev) {
        throw FileOpException(
          FileOpFailure.pendingFolderUnavailable,
          'rename crosses mounts: ${f.path}',
          fileId: f.id,
        );
      }
      throw fileOpExceptionFromIo(e, f.path, fileId: f.id);
    }
    final row = PendingFolderItemRow(
      id: id,
      originalPath: f.path,
      storedPath: stored,
      volumeId: root,
      name: f.name,
      mimeType: f.mimeType,
      sizeBytes: f.sizeBytes,
      originalFileId: f.id,
      originalModifiedAt: f.modifiedAt,
      deletedAt: now,
      expiresAt: now.add(Duration(days: days)),
    );
    await _db.into(_db.pendingFolderItems).insert(row);
    await _appendIndex(folder, row);
    return row;
  }

  /// Moves an item back. If its original name is taken, it becomes
  /// `name (restored).ext` (then ` (1)`…); never overwrites. A deleted
  /// original folder is recreated. Returns the new path.
  Future<String> restore(String itemId) async {
    final row = await _byId(itemId);
    final folder = parentOf(row.originalPath);
    final (base, ext) = splitExtension(row.name);
    var target = row.originalPath;
    if (await _exists(target)) {
      final name = await uniqueName(
        '$base (restored)$ext',
        (c) => _exists('$folder/$c'),
      );
      target = '$folder/$name';
    }
    try {
      await Directory(folder).create(recursive: true);
      await File(row.storedPath).rename(target);
    } on FileSystemException catch (e) {
      throw fileOpExceptionFromIo(
        e,
        row.storedPath,
        fileId: row.originalFileId,
      );
    }
    await _remove(row);
    return target;
  }

  /// "Delete forever" (D5).
  Future<void> deleteNow(List<String> itemIds) async {
    for (final id in itemIds) {
      await _deleteItem(await _byId(id));
    }
  }

  /// Deletes expired items (file, then row). Items on a volume that isn't
  /// mounted are skipped. Returns the number purged.
  Future<int> purgeExpired({DateTime? now}) async {
    final cutoff = (now ?? _clock()).toUtc();
    final expired = await (_db.select(
      _db.pendingFolderItems,
    )..where((p) => p.expiresAt.isSmallerOrEqualValue(cutoff))).get();
    var purged = 0;
    for (final row in expired) {
      if (!await Directory(row.volumeId).exists()) continue;
      await _deleteItem(row);
      purged++;
    }
    return purged;
  }

  Future<List<PendingFolderItemRow>> all() => (_db.select(
    _db.pendingFolderItems,
  )..orderBy([(p) => OrderingTerm.desc(p.deletedAt)])).get();

  Stream<List<PendingFolderItemRow>> watchAll() => (_db.select(
    _db.pendingFolderItems,
  )..orderBy([(p) => OrderingTerm.desc(p.deletedAt)])).watch();

  /// Adds rows for files in the folders that have none (app data cleared,
  /// or a kill between rename and insert), using `.index.jsonl`. Unknown
  /// files go to `<volume>/Download/Restored/` with a fresh retention. Known
  /// rows are untouched (H2). Returns rows added.
  Future<int> reconcile(List<String> volumeRoots) async {
    final stored = {for (final r in await all()) r.storedPath};
    var added = 0;
    final days = clampRetentionDays(await _retentionDays());
    for (final root in volumeRoots) {
      final folder = Directory(folderFor(root));
      if (!await folder.exists()) continue;
      final known = <String, Map<String, Object?>>{};
      final index = File('${folder.path}/$indexFileName');
      if (await index.exists()) {
        for (final line in await index.readAsLines()) {
          final entry = _parseLine(line);
          if (entry != null) known[entry['storedPath']! as String] = entry;
        }
      }
      await for (final e in folder.list(followLinks: false)) {
        if (e is! File) continue;
        final path = e.path.replaceAll(r'\', '/');
        final fileName = nameOf(path);
        if (fileName.startsWith('.') || stored.contains(path)) continue;
        final sep = fileName.indexOf('__');
        final name = sep < 0 ? fileName : fileName.substring(sep + 2);
        final entry = known[path];
        final stat = await e.stat();
        final now = _clock().toUtc();
        await _db
            .into(_db.pendingFolderItems)
            .insert(
              PendingFolderItemRow(
                id: sep < 0 ? _newId() : fileName.substring(0, sep),
                originalPath:
                    entry?['originalPath'] as String? ??
                    '$root/Download/Restored/$name',
                storedPath: path,
                volumeId: root,
                name: name,
                sizeBytes: stat.size,
                originalFileId: 'path:${entry?['originalPath'] ?? path}',
                originalModifiedAt: stat.modified.toUtc(),
                deletedAt: _date(entry?['deletedAt']) ?? now,
                expiresAt:
                    _date(entry?['expiresAt']) ?? now.add(Duration(days: days)),
              ),
            );
        added++;
      }
    }
    return added;
  }

  // ---- helpers ----

  Future<void> _deleteItem(PendingFolderItemRow row) async {
    try {
      await File(row.storedPath).delete();
    } on PathNotFoundException {
      // Already gone: just drop the row.
    } on FileSystemException catch (e) {
      throw fileOpExceptionFromIo(
        e,
        row.storedPath,
        fileId: row.originalFileId,
      );
    }
    await _remove(row);
  }

  Future<void> _remove(PendingFolderItemRow row) async {
    await (_db.delete(
      _db.pendingFolderItems,
    )..where((p) => p.id.equals(row.id))).go();
    await _rewriteIndex(row.volumeId);
  }

  Future<PendingFolderItemRow> _byId(String id) async =>
      await (_db.select(
        _db.pendingFolderItems,
      )..where((p) => p.id.equals(id))).getSingleOrNull() ??
      (throw FileOpException(FileOpFailure.notFound, 'pending item $id'));

  Future<void> _appendIndex(String folder, PendingFolderItemRow row) =>
      File('$folder/$indexFileName').writeAsString(
        '${jsonEncode(_entry(row))}\n',
        mode: FileMode.append,
        flush: true,
      );

  Future<void> _rewriteIndex(String volumeRoot) async {
    final folder = folderFor(volumeRoot);
    if (!await Directory(folder).exists()) return;
    final rows = await (_db.select(
      _db.pendingFolderItems,
    )..where((p) => p.volumeId.equals(volumeRoot))).get();
    await File('$folder/$indexFileName').writeAsString(
      rows.map((r) => '${jsonEncode(_entry(r))}\n').join(),
      flush: true,
    );
  }

  static Map<String, Object?> _entry(PendingFolderItemRow r) => {
    'id': r.id,
    'originalPath': r.originalPath,
    'storedPath': r.storedPath,
    'deletedAt': r.deletedAt.toUtc().toIso8601String(),
    'expiresAt': r.expiresAt.toUtc().toIso8601String(),
  };

  /// Null for a corrupt line (skipped, never fatal).
  static Map<String, Object?>? _parseLine(String line) {
    if (line.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(line);
      if (decoded is Map && decoded['storedPath'] is String) {
        return decoded.cast<String, Object?>();
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  static DateTime? _date(Object? iso) =>
      iso is String ? DateTime.tryParse(iso) : null;

  static Future<bool> _exists(String path) async =>
      await FileSystemEntity.type(path) != FileSystemEntityType.notFound;

  String _newId() => List.generate(
    16,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
