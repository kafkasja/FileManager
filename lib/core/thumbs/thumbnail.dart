import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';
import 'package:kfm/features/connect/ui/remote_image_provider.dart';

/// A file's thumbnail: neutral placeholder (no spinner, no layout shift),
/// fades in over 120 ms (a memory-cache hit shows at once, E4), cancels its
/// request when disposed. Files of a
/// connected device (N7) load over its pinned client into N5's memory LRU,
/// never the disk cache.
class Thumbnail extends ConsumerStatefulWidget {
  const new({
    required this.file,
    this.fit = BoxFit.cover,
    this.background,
    super.key,
  });

  final FileRef file;
  final BoxFit fit;

  /// Placeholder colour (default: the theme's surface; the viewer uses black).
  final Color? background;

  @override
  ConsumerState<Thumbnail> createState() => _ThumbnailState();
}

class _ThumbnailState extends ConsumerState<Thumbnail> {
  Uint8List? _bytes;
  ThumbnailCache? _cache;

  /// No thumbnail could be made (damaged or unsupported file).
  bool _failed = false;

  /// E4 (H2): the bytes were in the memory cache when the tile was built:
  /// shown in its first frame, no fade (every tile scrolling back into
  /// view used to flash).
  bool _instant = false;

  @override
  void initState() {
    super.initState();
    if (!_peek()) unawaited(_load());
  }

  /// A synchronous memory-cache hit; true = [_bytes] is set.
  bool _peek() {
    final file = widget.file;
    if (file.origin == FileOrigin.remote) return false;
    if (!DiskThumbnailCache.hasThumbnail(file)) return false;
    final cache = _cache ??= ref.read(thumbnailCacheProvider).value;
    final bytes = cache?.peek(file);
    if (bytes == null) return false;
    _bytes = bytes;
    _instant = true;
    return true;
  }

  @override
  void didUpdateWidget(Thumbnail old) {
    super.didUpdateWidget(old);
    if (old.file.id != widget.file.id ||
        old.file.modifiedAt != widget.file.modifiedAt) {
      _cache?.cancel(old.file.id);
      _bytes = null;
      _failed = false;
      _instant = false;
      if (!_peek()) unawaited(_load());
    }
  }

  @override
  void dispose() {
    _cache?.cancel(widget.file.id);
    super.dispose();
  }

  Future<ThumbnailCache> _cacheOnce() async {
    if (_cache case final cache?) return cache;
    final cache = await ref.read(thumbnailCacheProvider.future);
    _cache = cache;
    return cache;
  }

  Future<void> _load() async {
    final file = widget.file;
    if (file.origin == FileOrigin.remote) return;
    if (!DiskThumbnailCache.hasThumbnail(file)) return;
    final cache = await _cacheOnce();
    final bytes = await cache.get(file);
    if (!mounted || widget.file.id != file.id) return;
    if (bytes != null) {
      setState(() => _bytes = bytes);
    } else if (file.kind != FileKind.audio && cache.hasFailed(file)) {
      // Audio without cover art keeps its note icon.
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bytes = _bytes;
    final remote = widget.file.origin == FileOrigin.remote
        ? remoteThumbnailOf(ref.watch(remoteMediaAccessProvider), widget.file)
        : null;
    return ColoredBox(
      color: widget.background ?? scheme.surfaceContainerHighest,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: _failed
                ? Icon(
                    Icons.broken_image_outlined,
                    key: const ValueKey('thumbnail-failed'),
                    color: scheme.outline,
                  )
                : Icon(fileKindIcon(widget.file.kind), color: scheme.outline),
          ),
          if (remote != null)
            Image(
              image: remote,
              fit: widget.fit,
              gaplessPlayback: true,
              frameBuilder: (context, child, frame, wasSync) => AnimatedOpacity(
                opacity: wasSync || frame != null ? 1 : 0,
                duration: const Duration(milliseconds: 120),
                child: child,
              ),
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            )
          else
            AnimatedOpacity(
              opacity: bytes == null ? 0 : 1,
              duration: _instant
                  ? Duration.zero
                  : const Duration(milliseconds: 120),
              child: bytes == null
                  ? const SizedBox.shrink()
                  : Image.memory(
                      bytes,
                      fit: widget.fit,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
            ),
        ],
      ),
    );
  }
}

/// The type icon shown when there is no thumbnail.
IconData fileKindIcon(FileKind kind) => switch (kind) {
  FileKind.image => Icons.image_outlined,
  FileKind.video => Icons.movie_outlined,
  FileKind.audio => Icons.audiotrack_outlined,
  FileKind.document => Icons.description_outlined,
  FileKind.archive => Icons.folder_zip_outlined,
  FileKind.other => Icons.insert_drive_file_outlined,
};
