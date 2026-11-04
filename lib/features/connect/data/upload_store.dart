import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/upload_protocol.dart';

/// Partials untouched this long are deleted (TASK-N10).
const Duration kStalePartialAge = Duration(days: 7);

/// One upload on the sharing device (TASK-N9; N10 makes it durable).
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
    required this.createdAtMs,
    this.received = 0,
  });

  final String uploadId;

  /// Only this client may see, append, complete or cancel it (others get
  /// 404). The identity fingerprint, stable across reconnects.
  final String ownerFingerprint;
  final String rootId;
  final String path;
  final String name;
  final int size;
  final int createdAtMs;

  /// `<staging>/up-<uploadId>.part`.
  final File part;

  /// `<staging>/up-<uploadId>.json`: the durable truth (never claims bytes
  /// that aren't flushed to [part]).
  final File meta;
  int received;

  /// The chunk being written, if any.
  Future<void>? writing;

  /// Aborts [writing] (a newer chunk of the same owner takes over).
  void Function()? abortWrite;

  /// The `complete` running for this upload (Q8): a repeated complete
  /// (the client lost the link and asks again) waits for this one's
  /// outcome instead of publishing a second time.
  Future<CompleteOutcome>? completing;

  /// Its owner was removed (or the store cleared) meanwhile: a running
  /// complete's answer is not remembered.
  bool forgotten = false;

  /// Same upload as a repeated create (idempotent `POST /v1/uploads`).
  bool sameAs({
    required String rootId,
    required String path,
    required String name,
    required int size,
  }) =>
      this.rootId == rootId &&
      this.path == path &&
      this.name == name &&
      this.size == size;

  Map<String, Object?> toJson(int nowMs) => {
    'ownerFingerprint': ownerFingerprint,
    'rootId': rootId,
    'path': path,
    'name': name,
    'size': size,
    'received': received,
    'createdAtMs': createdAtMs,
    'updatedAtMs': nowMs,
  };
}

/// What one `complete` ended with (Q8): the published file, or the error
/// every caller waiting for it gets.
class CompleteOutcome {
  const new({this.finalId, this.sha256, this.error});

  final String? finalId;
  final String? sha256;
  final ApiErrorCode? error;
}

/// X8: what happened to an upload on this device (receiving side), for the
/// progress notification and the in-app indicator.
enum UploadPhase { progressed, completed, removed }

/// X8: one upload's state when [phase] happened.
class UploadActivity {
  const new({
    required this.uploadId,
    required this.ownerFingerprint,
    required this.name,
    required this.size,
    required this.received,
    required this.phase,
  });

  final String uploadId;
  final String ownerFingerprint;
  final String name;
  final int size;
  final int received;
  final UploadPhase phase;
}

/// Completions remembered for a repeated `complete` (N11).
const int kRememberedCompletions = 200;

/// A finished upload's answer (N11), kept in memory.
class CompletedUpload {
  const new({required this.state, required this.finalId, this.sha256});

  final UploadState state;
  final String finalId;
  final String? sha256;
}

/// Uploads in progress (TASK-N9/N10). Partials live in the app's private
/// staging folder, never inside a shared folder, and are only published by
/// `FileSource.importFile` once complete. The `.json` next to each partial
/// is the truth after a restart: it is loaded on first use. Partials
/// survive stop sharing (the same client resumes later); they are deleted
/// on cancel, on complete, when their owner is removed ([removeOwner]) and
/// after [kStalePartialAge] without a chunk.
class UploadStore {
  new({required this._staging, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Future<Directory> Function() _staging;
  final DateTime Function() _clock;
  final Map<String, UploadState> _uploads = {};
  final Map<String, CompletedUpload> _done = {};
  Future<void>? _loaded;

  final StreamController<UploadActivity> _activity = StreamController.broadcast(
    sync: true,
  );

  /// X8: chunks stored, uploads completed or removed (no replay).
  Stream<UploadActivity> get activity => _activity.stream;

  void _emit(UploadState u, UploadPhase phase) {
    if (!_activity.hasListener) return;
    _activity.add(
      UploadActivity(
        uploadId: u.uploadId,
        ownerFingerprint: u.ownerFingerprint,
        name: u.name,
        size: u.size,
        received: phase == UploadPhase.completed ? u.size : u.received,
        phase: phase,
      ),
    );
  }

  /// When a chunk was last stored (Q8: "transfers running" between chunks).
  DateTime? _lastChunkAt;

  /// Q8: a chunk or a complete runs right now, or a chunk was stored within
  /// [window] (the client is between two chunks).
  bool activeWithin(Duration window) {
    final last = _lastChunkAt;
    return _uploads.values.any(
          (u) => u.writing != null || u.completing != null,
        ) ||
        (last != null && _clock().difference(last) < window);
  }

  /// Loads the partials on disk once (and deletes broken or stale ones).
  Future<void> _ensureLoaded() => _loaded ??= _load();

  /// [uploadId] if [fingerprint] owns it; null otherwise (unknown or
  /// another client's: the caller answers 404 either way).
  Future<UploadState?> lookup(String uploadId, String fingerprint) async {
    await _ensureLoaded();
    final u = _uploads[uploadId];
    return u != null && u.ownerFingerprint == fingerprint ? u : null;
  }

  /// The upload [uploadId] whoever owns it (create checks the owner).
  Future<UploadState?> any(String uploadId) async {
    await _ensureLoaded();
    return _uploads[uploadId];
  }

  /// Creates the empty partial and its `.json`.
  Future<UploadState> create({
    required String uploadId,
    required String ownerFingerprint,
    required String rootId,
    required String path,
    required String name,
    required int size,
  }) async {
    await _ensureLoaded();
    final dir = await _staging();
    await dir.create(recursive: true);
    final state = UploadState(
      uploadId: uploadId,
      ownerFingerprint: ownerFingerprint,
      rootId: rootId,
      path: path,
      name: name,
      size: size,
      part: File('${dir.path}/up-$uploadId.part'),
      meta: File('${dir.path}/up-$uploadId.json'),
      createdAtMs: _clock().millisecondsSinceEpoch,
    );
    _uploads[uploadId] = state;
    try {
      await state.part.writeAsBytes(const [], flush: true);
      await saveMeta(state);
    } on Object {
      await remove(uploadId);
      rethrow;
    }
    return state;
  }

  /// Rewrites [u]'s `.json` atomically (temp file, flush, rename). Call
  /// only after the bytes it claims are flushed.
  Future<void> saveMeta(UploadState u) async {
    _lastChunkAt = _clock();
    final tmp = File('${u.meta.path}.tmp');
    await tmp.writeAsString(
      jsonEncode(u.toJson(_clock().millisecondsSinceEpoch)),
      flush: true,
    );
    await tmp.rename(u.meta.path);
    if (identical(_uploads[u.uploadId], u)) _emit(u, UploadPhase.progressed);
  }

  /// Forgets [uploadId] and deletes its partial and `.json`.
  Future<void> remove(String uploadId) => _remove(uploadId);

  Future<void> _remove(String uploadId, {bool emit = true}) async {
    final u = _uploads.remove(uploadId);
    if (u == null) return;
    if (emit) _emit(u, UploadPhase.removed);
    u.abortWrite?.call();
    await _delete(u.part);
    await _delete(u.meta);
  }

  /// Forgets the upload [u] after a successful import (the partial was
  /// moved) and remembers the answer (N11): the owner's repeated `complete`
  /// after a lost answer gets the same result instead of a 404 (which would
  /// send the file again). Recorded from [u] itself, so it holds even when
  /// the live entry went meanwhile (Q8), unless its owner was removed. In
  /// memory only, the last [kRememberedCompletions].
  Future<void> completed(
    UploadState u, {
    required String finalId,
    String? sha256,
  }) async {
    if (!u.forgotten) {
      _done
        ..remove(u.uploadId)
        ..[u.uploadId] = CompletedUpload(
          state: u,
          finalId: finalId,
          sha256: sha256,
        );
      while (_done.length > kRememberedCompletions) {
        _done.remove(_done.keys.first);
      }
    }
    if (identical(_uploads[u.uploadId], u)) {
      _emit(u, UploadPhase.completed);
      await _remove(u.uploadId, emit: false);
    }
  }

  /// [uploadId]'s remembered completion if [fingerprint] owns it.
  CompletedUpload? lookupCompleted(String uploadId, String fingerprint) {
    final d = _done[uploadId];
    return d != null && d.state.ownerFingerprint == fingerprint ? d : null;
  }

  /// Every partial of [fingerprint] (N6: that device was removed here).
  Future<void> removeOwner(String fingerprint) async {
    await _ensureLoaded();
    _done.removeWhere((_, d) => d.state.ownerFingerprint == fingerprint);
    for (final u in _uploads.values.toList()) {
      if (u.ownerFingerprint == fingerprint) {
        u.forgotten = true;
        await remove(u.uploadId);
      }
    }
  }

  /// Stop sharing: in-flight chunks end (the session store cancels their
  /// streams); the partials stay for a later resume.
  void stop() {
    for (final u in _uploads.values) {
      u.abortWrite?.call();
    }
  }

  /// Forgets every upload and deletes every partial (tests, and a full
  /// reset of this device's identity).
  Future<void> clear() async {
    await _ensureLoaded();
    _done.clear();
    for (final u in _uploads.values.toList()) {
      u.forgotten = true;
      await remove(u.uploadId);
    }
    await _sweep(keep: const {});
  }

  /// Sharing starts: partials untouched for [kStalePartialAge] go.
  Future<void> purgeStale() async {
    await _ensureLoaded();
    await _purgeStale();
  }

  Future<void> _purgeStale() async {
    final now = _clock();
    for (final u in _uploads.values.toList()) {
      if (u.writing != null || u.completing != null) continue;
      DateTime touched;
      try {
        touched = await u.meta.lastModified();
      } on FileSystemException {
        touched = DateTime.fromMillisecondsSinceEpoch(u.createdAtMs);
      }
      if (now.difference(touched) > kStalePartialAge) {
        await remove(u.uploadId);
      }
    }
  }

  Future<void> _load() async {
    try {
      final dir = await _staging();
      if (!await dir.exists()) return;
      await for (final e in dir.list()) {
        final name = e.uri.pathSegments.last;
        if (e is! File || !name.startsWith('up-') || !name.endsWith('.json')) {
          continue;
        }
        final id = name.substring(3, name.length - 5);
        final u = await _read(dir, id, e);
        if (u != null) _uploads[id] = u;
      }
      await _sweep(keep: _uploads.keys.toSet());
      await _purgeStale();
    } on Object catch (e) {
      developer.log('upload partials not loaded: $e', name: 'kfm.connect');
    }
  }

  /// One `.json` + `.part` pair; null (and both deleted) when broken. A
  /// `.part` longer than the `.json`'s `received` (a chunk not confirmed
  /// before a crash) is cut back.
  Future<UploadState?> _read(Directory dir, String id, File meta) async {
    final part = File('${dir.path}/up-$id.part');
    try {
      if (!kUploadIdPattern.hasMatch(id) || !await part.exists()) {
        throw const FormatException('no partial');
      }
      final json = jsonDecode(await meta.readAsString());
      if (json is! Map<String, Object?>) throw const FormatException('json');
      final owner = json['ownerFingerprint'];
      final rootId = json['rootId'];
      final path = json['path'];
      final name = json['name'];
      final size = json['size'];
      final received = json['received'];
      final created = json['createdAtMs'];
      if (owner is! String ||
          rootId is! String ||
          path is! String ||
          name is! String ||
          size is! int ||
          received is! int ||
          received < 0 ||
          received > size) {
        throw const FormatException('fields');
      }
      // The folder is app-private, but a name is checked again before it
      // can be published.
      validateFileName(name);
      if (name.startsWith('.')) throw const FormatException('dot name');
      var length = await part.length();
      if (length > received) {
        final raf = await part.open(mode: FileMode.append);
        try {
          await raf.truncate(received);
          await raf.flush();
        } finally {
          await raf.close();
        }
        length = received;
      }
      return UploadState(
        uploadId: id,
        ownerFingerprint: owner,
        rootId: rootId,
        path: path,
        name: name,
        size: size,
        part: part,
        meta: meta,
        createdAtMs: created is int ? created : 0,
        received: length,
      );
    } on Object catch (e) {
      if (e is! FormatException && e is! FileOpException) {
        developer.log('upload partial unreadable: $e', name: 'kfm.connect');
      }
      await _delete(part);
      await _delete(meta);
      return null;
    }
  }

  /// Deletes `up-*` files no known upload uses.
  Future<void> _sweep({required Set<String> keep}) async {
    try {
      final dir = await _staging();
      if (!await dir.exists()) return;
      await for (final e in dir.list()) {
        final name = e.uri.pathSegments.last;
        if (e is! File || !name.startsWith('up-')) continue;
        final dot = name.indexOf('.');
        final id = dot > 3 ? name.substring(3, dot) : '';
        if (!keep.contains(id) || name.endsWith('.tmp')) await _delete(e);
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
