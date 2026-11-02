import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

/// One upload in progress on the sharing device (TASK-N9).
class UploadState {
  new({
    required this.uploadId,
    required this.ownerFingerprint,
    required this.rootId,
    required this.path,
    required this.name,
    required this.size,
    required this.part,
    required this.meta,
  });

  final String uploadId;

  /// Only this client may append, complete or cancel (others get 404).
  final String ownerFingerprint;
  final String rootId;
  final String path;
  final String name;
  final int size;

  /// `<staging>/up-<uploadId>.part`.
  final File part;

  /// `<staging>/up-<uploadId>.json` (N10 resumes from it).
  final File meta;
  int received = 0;

  /// A chunk is being written (a second one at once gets 409 busy).
  bool writing = false;
}

/// Uploads of the current sharing run (TASK-N9). Partials live in the app's
/// private staging folder, never inside a shared folder, and are only
/// published by `FileSource.importFile` once complete. Memory only: N9 has
/// no resume, so [clear] (stop sharing) and [purgeLeftovers] (startup)
/// delete every partial.
class UploadStore {
  new({required this._staging});

  final Future<Directory> Function() _staging;
  final Map<String, UploadState> _uploads = {};

  /// [uploadId] if [fingerprint] owns it; null otherwise (unknown or
  /// another client's: the caller answers 404 either way).
  UploadState? lookup(String uploadId, String fingerprint) {
    final u = _uploads[uploadId];
    return u != null && u.ownerFingerprint == fingerprint ? u : null;
  }

  /// Whether any client uses [uploadId] (a reused id gets 409).
  bool exists(String uploadId) => _uploads.containsKey(uploadId);

  /// Creates the empty partial and its `.json`.
  Future<UploadState> create({
    required String uploadId,
    required String ownerFingerprint,
    required String rootId,
    required String path,
    required String name,
    required int size,
  }) async {
    final dir = await _staging();
    final state = UploadState(
      uploadId: uploadId,
      ownerFingerprint: ownerFingerprint,
      rootId: rootId,
      path: path,
      name: name,
      size: size,
      part: File('${dir.path}/up-$uploadId.part'),
      meta: File('${dir.path}/up-$uploadId.json'),
    );
    _uploads[uploadId] = state;
    try {
      await state.part.writeAsBytes(const [], flush: true);
      await state.meta.writeAsString(
        jsonEncode({
          'ownerFingerprint': ownerFingerprint,
          'rootId': rootId,
          'path': path,
          'name': name,
          'size': size,
          'received': 0,
        }),
      );
    } on Object {
      await remove(uploadId);
      rethrow;
    }
    return state;
  }

  /// Forgets [uploadId] and deletes its partial and `.json`.
  Future<void> remove(String uploadId) async {
    final u = _uploads.remove(uploadId);
    if (u == null) return;
    await _delete(u.part);
    await _delete(u.meta);
  }

  /// Forgets the upload after a successful import (the partial was moved).
  Future<void> completed(String uploadId) async {
    final u = _uploads.remove(uploadId);
    if (u == null) return;
    await _delete(u.part);
    await _delete(u.meta);
  }

  /// Stop sharing: every upload ends and its partial is deleted.
  Future<void> clear() async {
    for (final id in _uploads.keys.toList()) {
      await remove(id);
    }
    await purgeLeftovers();
  }

  /// Deletes `up-*` files no upload of this run uses (a crash mid-upload).
  Future<void> purgeLeftovers() async {
    try {
      final dir = await _staging();
      if (!await dir.exists()) return;
      await for (final e in dir.list()) {
        final name = e.uri.pathSegments.last;
        if (e is! File || !name.startsWith('up-')) continue;
        final dot = name.lastIndexOf('.');
        final id = dot > 3 ? name.substring(3, dot) : '';
        if (!_uploads.containsKey(id)) await _delete(e);
      }
    } on Object catch (e) {
      developer.log('upload leftovers not purged: $e', name: 'kfm.connect');
    }
  }

  static Future<void> _delete(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } on FileSystemException catch (e) {
      developer.log('partial not deleted: $e', name: 'kfm.connect');
    }
  }
}
