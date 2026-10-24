import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:photo_manager/photo_manager.dart';

enum ThumbPriority { visible, prefetch }

/// Makes a JPEG thumbnail (longest side [size] px) or null if the file has
/// none.
typedef ThumbGenerator = Future<Uint8List?> Function(FileRef file, int size);

/// Thumbnails for images and videos: memory → disk → generate (TASK-F5).
abstract interface class ThumbnailCache {
  /// Null for kinds without thumbnails, cancelled requests and files that
  /// failed to decode (remembered for the session: no retry loop).
  Future<Uint8List?> get(
    FileRef f, {
    ThumbPriority priority = ThumbPriority.visible,
  });

  /// Warm the cache for what the user will see next.
  void prefetch(Iterable<FileRef> files);

  /// Drops a waiting request (scrolled away). Running ones finish.
  void cancel(String fileId);

  Future<void> clear();

  Future<int> diskSizeBytes();
}

/// Android generator: MediaStore's own thumbnail through photo_manager (fast
/// on API 29+). Only `ms:` files have one.
Future<Uint8List?> photoManagerThumbnail(FileRef file, int size) async {
  if (!file.id.startsWith('ms:')) return null;
  final asset = await AssetEntity.fromId(file.id.substring(3));
  if (asset == null) return null;
  return await asset.thumbnailDataWithSize(
    ThumbnailSize.square(size),
    quality: 80,
  );
}

class _Request {
  new(this.file, this.key);

  final FileRef file;
  final String key;
  final Completer<Uint8List?> completer = Completer<Uint8List?>();
}

/// Disk files: `<dir>/<sha1[0:2]>/<sha1(id)>_<modifiedAtMs>.jpg`, so an
/// edited file gets a new thumbnail automatically. The disk cap is enforced
/// every [trimEvery] writes by deleting least-recently-used files down to
/// 80% of the cap.
class DiskThumbnailCache implements ThumbnailCache {
  new({
    required this._dir,
    required this._generator,
    required this._maxDiskBytes,
    this._maxMemoryBytes = 64 * 1024 * 1024,
    this._maxConcurrent = 4,
  });

  static const size = 256;
  static const trimEvery = 100;

  final Directory _dir;
  final ThumbGenerator _generator;
  final Future<int> Function() _maxDiskBytes;
  final int _maxMemoryBytes;
  final int _maxConcurrent;

  // LinkedHashMap keeps insertion order: first = least recently used.
  final LinkedHashMap<String, Uint8List> _memory =
      LinkedHashMap<String, Uint8List>();
  int _memoryBytes = 0;
  final Set<String> _failed = {};
  final Map<String, _Request> _inFlight = {};

  /// Waiting requests; served from the end (LIFO: what the user just
  /// scrolled to wins). Prefetches go to the front.
  final List<_Request> _waiting = [];
  int _running = 0;
  int _writesSinceTrim = 0;
  final Map<String, DateTime> _lastAccess = {};

  static bool hasThumbnail(FileRef f) =>
      f.kind == FileKind.image || f.kind == FileKind.video;

  @override
  Future<Uint8List?> get(
    FileRef f, {
    ThumbPriority priority = ThumbPriority.visible,
  }) {
    if (!hasThumbnail(f)) return Future.value();
    final key = _key(f);
    final cached = _memory.remove(key);
    if (cached != null) {
      _memory[key] = cached; // most recently used
      return Future.value(cached);
    }
    if (_failed.contains(key)) return Future.value();
    final existing = _inFlight[key];
    if (existing != null) {
      if (priority == ThumbPriority.visible && _waiting.remove(existing)) {
        _waiting.add(existing); // promote
      }
      return existing.completer.future;
    }
    final request = _Request(f, key);
    _inFlight[key] = request;
    if (priority == ThumbPriority.visible) {
      _waiting.add(request);
    } else {
      _waiting.insert(0, request);
    }
    _pump();
    return request.completer.future;
  }

  @override
  void prefetch(Iterable<FileRef> files) {
    for (final f in files) {
      get(f, priority: ThumbPriority.prefetch).ignore();
    }
  }

  @override
  void cancel(String fileId) {
    final cancelled = _waiting.where((r) => r.file.id == fileId).toList();
    for (final r in cancelled) {
      _waiting.remove(r);
      _inFlight.remove(r.key);
      r.completer.complete();
    }
  }

  @override
  Future<void> clear() async {
    for (final r in _waiting) {
      r.completer.complete();
    }
    _waiting.clear();
    _memory.clear();
    _memoryBytes = 0;
    _failed.clear();
    _lastAccess.clear();
    if (await _dir.exists()) await _dir.delete(recursive: true);
  }

  @override
  Future<int> diskSizeBytes() async {
    var total = 0;
    for (final (_, stat) in await _diskFiles()) {
      total += stat.size;
    }
    return total;
  }

  void _pump() {
    while (_running < _maxConcurrent && _waiting.isNotEmpty) {
      final request = _waiting.removeLast();
      _running++;
      unawaited(
        _load(request).whenComplete(() {
          _running--;
          _inFlight.remove(request.key);
          _pump();
        }),
      );
    }
  }

  Future<void> _load(_Request r) async {
    final file = File(_pathFor(r.key));
    try {
      Uint8List? bytes;
      try {
        bytes = await file.readAsBytes();
      } on FileSystemException {
        bytes = null; // not cached yet, or removed by system cache cleaning
      }
      if (bytes == null) {
        bytes = await _generator(r.file, size);
        if (bytes == null) {
          _failed.add(r.key);
        } else {
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes, flush: true);
          if (++_writesSinceTrim >= trimEvery) {
            _writesSinceTrim = 0;
            await _trim();
          }
        }
      }
      if (bytes != null) {
        _lastAccess[file.path] = DateTime.now();
        _remember(r.key, bytes);
      }
      r.completer.complete(bytes);
    } on Object catch (e) {
      // Undecodable / unreadable file: the widget shows a placeholder and
      // the failure is remembered so it isn't retried in a loop.
      developer.log(
        'thumbnail failed for ${r.file.id}: $e',
        name: 'kfm.thumbs',
      );
      _failed.add(r.key);
      r.completer.complete();
    }
  }

  void _remember(String key, Uint8List bytes) {
    _memory[key] = bytes;
    _memoryBytes += bytes.length;
    while (_memoryBytes > _maxMemoryBytes && _memory.isNotEmpty) {
      final oldest = _memory.keys.first;
      _memoryBytes -= _memory.remove(oldest)!.length;
    }
  }

  Future<void> _trim() async {
    final cap = await _maxDiskBytes();
    final files = await _diskFiles();
    var total = files.fold<int>(0, (sum, f) => sum + f.$2.size);
    if (total <= cap) return;
    DateTime lastUsed((File, FileStat) f) =>
        _lastAccess[f.$1.path] ?? f.$2.modified;
    files.sort((a, b) => lastUsed(a).compareTo(lastUsed(b)));
    final target = cap * 8 ~/ 10;
    for (final (file, stat) in files) {
      if (total <= target) break;
      await file.delete();
      _lastAccess.remove(file.path);
      total -= stat.size;
    }
  }

  Future<List<(File, FileStat)>> _diskFiles() async {
    if (!await _dir.exists()) return [];
    final out = <(File, FileStat)>[];
    await for (final e in _dir.list(recursive: true, followLinks: false)) {
      if (e is File) out.add((e, await e.stat()));
    }
    return out;
  }

  String _pathFor(String key) => '${_dir.path}/${key.substring(0, 2)}/$key.jpg';

  static String _key(FileRef f) =>
      '${sha1.convert(utf8.encode(f.id))}_${f.modifiedAt.millisecondsSinceEpoch}';
}
