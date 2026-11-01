import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/protocol.dart';

/// Largest thumbnail the client accepts from a remote device.
const int kMaxRemoteThumbBytes = 2 << 20;

/// In-memory LRU of remote thumbnail bytes (TASK-N5): at most [maxEntries]
/// entries and [maxBytes] bytes, whichever is hit first. No disk cache (the
/// data belongs to the other device); cleared on disconnect.
class RemoteThumbnailCache {
  new({this.maxEntries = 300, this.maxBytes = 30 << 20});

  final int maxEntries;
  final int maxBytes;

  // Insertion order = recency order (oldest first).
  final LinkedHashMap<String, Uint8List> _entries = LinkedHashMap();
  int _bytes = 0;

  int get length => _entries.length;

  /// Total bytes held.
  int get bytes => _bytes;

  /// The bytes for [key] (marks it most recently used), or null.
  Uint8List? get(String key) {
    final v = _entries.remove(key);
    if (v == null) return null;
    _entries[key] = v;
    return v;
  }

  /// Stores [value] as the most recently used entry, evicting the least
  /// recently used ones over the limits. A value larger than [maxBytes] is
  /// not stored.
  void put(String key, Uint8List value) {
    final old = _entries.remove(key);
    if (old != null) _bytes -= old.length;
    if (value.length > maxBytes) return;
    _entries[key] = value;
    _bytes += value.length;
    while (_entries.length > maxEntries || _bytes > maxBytes) {
      final oldest = _entries.keys.first;
      _bytes -= _entries.remove(oldest)!.length;
    }
  }

  void clear() {
    _entries.clear();
    _bytes = 0;
  }
}

/// Thumbnail of a file on a connected device, fetched over the pinned
/// [RemoteHttp] (never `NetworkImage`). The image-cache key is
/// ([peerFingerprint], [serverId], [modifiedAtMs], [epoch]): bumping [epoch]
/// on disconnect makes old images unreachable, and a file changed in place
/// (N7 live sync) gets a new thumbnail.
@immutable
class RemoteThumbnailProvider extends ImageProvider<RemoteThumbnailProvider> {
  const new({
    required this.http,
    required this.cache,
    required this.peerFingerprint,
    required this.serverId,
    required this.epoch,
    this.modifiedAtMs = 0,
  });

  final RemoteHttp http;
  final RemoteThumbnailCache cache;
  final String peerFingerprint;

  /// The other device's own file id.
  final String serverId;

  /// The connection generation (N5 controller).
  final int epoch;

  /// The file's modified time (epoch ms UTC, N7).
  final int modifiedAtMs;

  /// Key in [cache].
  String get cacheKey => '$epoch:$peerFingerprint:$serverId:$modifiedAtMs';

  @override
  Future<RemoteThumbnailProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    RemoteThumbnailProvider key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: key._load(decode),
    scale: 1,
    debugLabel: 'RemoteThumbnailProvider',
  );

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    var bytes = cache.get(cacheKey);
    if (bytes == null) {
      final res = await http.getStream(ApiRoutes.fileThumb(serverId));
      bytes = await readCappedBytes(res, kMaxRemoteThumbBytes);
      cache.put(cacheKey, bytes);
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return await decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      other is RemoteThumbnailProvider &&
      other.peerFingerprint == peerFingerprint &&
      other.serverId == serverId &&
      other.modifiedAtMs == modifiedAtMs &&
      other.epoch == epoch;

  @override
  int get hashCode =>
      Object.hash(peerFingerprint, serverId, modifiedAtMs, epoch);

  @override
  String toString() => 'RemoteThumbnailProvider($serverId, epoch $epoch)';
}

/// Reads [res] fully, failing with [RemoteUnavailableException]
/// (`badResponse`) once it is larger than [max] bytes (the rest isn't read).
Future<Uint8List> readCappedBytes(HttpClientResponse res, int max) async {
  if (res.contentLength > max) {
    await res.listen(null).cancel();
    throw const RemoteUnavailableException(RemoteUnavailableReason.badResponse);
  }
  final out = BytesBuilder(copy: false);
  await for (final chunk in res) {
    out.add(chunk);
    if (out.length > max) {
      throw const RemoteUnavailableException(
        RemoteUnavailableReason.badResponse,
      );
    }
  }
  return out.takeBytes();
}
