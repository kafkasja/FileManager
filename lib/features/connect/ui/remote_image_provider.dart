import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/domain/remote_file_id.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/connect/ui/remote_thumbnail_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_image_provider.g.dart';

/// Largest preview (`/preview`) the client accepts.
const int kMaxRemotePreviewBytes = 8 << 20;

/// Largest original image (`/content`) the client decodes.
const int kMaxRemoteOriginalBytes = 64 << 20;

/// The server clamps `/preview?max=` to this range (N7 route table).
const int kMinRemotePreviewPx = 256;
const int kMaxRemotePreviewPx = 2048;

/// What the media widgets need to show a remote file (TASK-N7): the live
/// connection's client, N5's memory LRU and the connection epoch. While no
/// device is connected [http] is null and remote images fail (their
/// placeholders stay).
@immutable
class RemoteMediaAccess {
  const new({
    required this.cache,
    required this.epoch,
    this.peerFingerprint,
    this.http,
    this.onUnauthorized,
  });

  /// No device: remote images fail to load (placeholders stay).
  static final RemoteMediaAccess none = RemoteMediaAccess(
    cache: RemoteThumbnailCache(maxEntries: 1, maxBytes: 0),
    epoch: -1,
  );

  /// The connected device; null when none is.
  final String? peerFingerprint;
  final RemoteHttp? http;
  final RemoteThumbnailCache cache;
  final int epoch;
  final void Function()? onUnauthorized;

  /// The other device's id of [f] when the connected device holds it.
  String? serverIdOf(FileRef f) {
    if (f.origin != FileOrigin.remote || http == null) return null;
    try {
      final p = parseRemoteFileId(f.id);
      return p.peerFingerprint == peerFingerprint ? p.serverId : null;
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is RemoteMediaAccess &&
      other.peerFingerprint == peerFingerprint &&
      identical(other.http, http) &&
      identical(other.cache, cache) &&
      other.epoch == epoch;

  @override
  int get hashCode =>
      Object.hash(peerFingerprint, identityHashCode(http), epoch);
}

/// The live [RemoteMediaAccess] (changes on connect / disconnect).
@Riverpod(keepAlive: true)
RemoteMediaAccess remoteMediaAccess(Ref ref) {
  final state = ref.watch(remoteConnectionControllerProvider);
  final controller = ref.read(remoteConnectionControllerProvider.notifier);
  final cache = ref.watch(remoteThumbnailCacheProvider);
  return switch (state) {
    RemoteConnected(:final peerFingerprint) => RemoteMediaAccess(
      peerFingerprint: peerFingerprint,
      http: controller.http,
      cache: cache,
      epoch: controller.epoch,
      onUnauthorized: controller.reportUnauthorized,
    ),
    _ => RemoteMediaAccess(cache: cache, epoch: controller.epoch),
  };
}

/// The thumbnail of remote [f] (`/thumb`), or null when its device isn't
/// connected or the kind has none.
RemoteThumbnailProvider? remoteThumbnailOf(
  RemoteMediaAccess access,
  FileRef f,
) {
  final serverId = access.serverIdOf(f);
  final http = access.http;
  if (serverId == null || http == null) return null;
  if (f.kind != FileKind.image &&
      f.kind != FileKind.video &&
      f.kind != FileKind.audio) {
    return null;
  }
  return RemoteThumbnailProvider(
    http: http,
    cache: access.cache,
    peerFingerprint: access.peerFingerprint!,
    serverId: serverId,
    epoch: access.epoch,
    modifiedAtMs: f.modifiedAt.millisecondsSinceEpoch,
  );
}

/// Remote [f] at display width ([widthPx]): `/preview`, falling back to
/// `/content` when the other device has no preview for it.
RemoteImageProvider remoteDisplayImage(
  RemoteMediaAccess access,
  FileRef f,
  int widthPx,
) => RemoteImageProvider._of(access, f, maxPx: widthPx, original: false);

/// Remote [f]'s original bytes (`/content`), decoded at most [maxPx] on the
/// long side.
RemoteImageProvider remoteOriginalImage(
  RemoteMediaAccess access,
  FileRef f, {
  required int maxPx,
}) => RemoteImageProvider._of(access, f, maxPx: maxPx, original: true);

/// An image of a file on the connected device over the pinned client (never
/// `NetworkImage`). Previews join N5's memory LRU; originals stay only in
/// Flutter's decoded-image cache. Keyed by device, file, modified time,
/// size and connection epoch.
@immutable
class RemoteImageProvider extends ImageProvider<RemoteImageProvider> {
  const new({
    required this.http,
    required this.cache,
    required this.peerFingerprint,
    required this.serverId,
    required this.epoch,
    required this.modifiedAtMs,
    required this.maxPx,
    this.original = false,
    this.onUnauthorized,
  });

  factory _of(
    RemoteMediaAccess access,
    FileRef f, {
    required int maxPx,
    required bool original,
  }) {
    final serverId = access.serverIdOf(f);
    return RemoteImageProvider(
      // Not connected (or another device's file): loading fails.
      http: serverId == null ? null : access.http,
      cache: access.cache,
      peerFingerprint: access.peerFingerprint ?? '',
      serverId: serverId ?? f.id,
      epoch: access.epoch,
      modifiedAtMs: f.modifiedAt.millisecondsSinceEpoch,
      maxPx: maxPx,
      original: original,
      onUnauthorized: access.onUnauthorized,
    );
  }

  /// Null = not connected: loading fails with `unavailable`.
  final RemoteHttp? http;
  final RemoteThumbnailCache cache;
  final String peerFingerprint;
  final String serverId;
  final int epoch;
  final int modifiedAtMs;

  /// Preview: the display width asked for; original: the decode cap.
  final int maxPx;

  /// `/content` instead of `/preview`.
  final bool original;
  final void Function()? onUnauthorized;

  /// Key in [cache] (previews only).
  String get cacheKey =>
      'preview$maxPx:$epoch:$peerFingerprint:$serverId:$modifiedAtMs';

  @override
  Future<RemoteImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    RemoteImageProvider key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: key._load(decode),
    scale: 1,
    debugLabel: 'RemoteImageProvider',
  );

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final http = this.http;
    if (http == null) {
      throw const FileOpException(
        FileOpFailure.unavailable,
        'device not connected',
      );
    }
    final bytes = await _bytes(http);
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return await decode(buffer, getTargetSize: _fit);
  }

  Future<Uint8List> _bytes(RemoteHttp http) async {
    try {
      if (original) return await _content(http);
      final cached = cache.get(cacheKey);
      if (cached != null) return cached;
      final Uint8List bytes;
      try {
        final res = await http.getStream(
          ApiRoutes.filePreview(serverId),
          query: {
            'max': '${maxPx.clamp(kMinRemotePreviewPx, kMaxRemotePreviewPx)}',
          },
        );
        bytes = await readCappedBytes(res, kMaxRemotePreviewBytes);
      } on RemoteApiException catch (e) {
        // No preview for this file (not an `ms:` image): the bytes.
        if (e.code != ApiErrorCode.notFound) rethrow;
        // Not put in the LRU: originals are too big for it.
        return await _content(http);
      }
      cache.put(cacheKey, bytes);
      return bytes;
    } on RemoteApiException catch (e) {
      if (e.code == ApiErrorCode.unauthorized) onUnauthorized?.call();
      rethrow;
    }
  }

  Future<Uint8List> _content(RemoteHttp http) async {
    final res = await http.getStream(ApiRoutes.fileContent(serverId));
    return await readCappedBytes(res, kMaxRemoteOriginalBytes);
  }

  /// Never decodes beyond [maxPx] on the long side.
  ui.TargetImageSize _fit(int width, int height) {
    final long = math.max(width, height);
    if (long <= maxPx || long == 0) return const ui.TargetImageSize();
    final scale = maxPx / long;
    return ui.TargetImageSize(
      width: math.max(1, (width * scale).round()),
      height: math.max(1, (height * scale).round()),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RemoteImageProvider &&
      other.peerFingerprint == peerFingerprint &&
      other.serverId == serverId &&
      other.epoch == epoch &&
      other.modifiedAtMs == modifiedAtMs &&
      other.maxPx == maxPx &&
      other.original == original &&
      (other.http == null) == (http == null);

  @override
  int get hashCode => Object.hash(
    peerFingerprint,
    serverId,
    epoch,
    modifiedAtMs,
    maxPx,
    original,
    http == null,
  );

  @override
  String toString() =>
      'RemoteImageProvider($serverId, ${original ? 'original' : 'preview'} '
      '$maxPx, epoch $epoch)';
}
