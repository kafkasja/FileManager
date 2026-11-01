import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';
import 'package:kfm/features/connect/ui/remote_image_provider.dart';

/// A file's thumbnail: neutral placeholder (no spinner, no layout shift),
/// fades in over 120 ms, cancels its request when disposed. Files of a
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

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(Thumbnail old) {
    super.didUpdateWidget(old);
    if (old.file.id != widget.file.id ||
        old.file.modifiedAt != widget.file.modifiedAt) {
      _cache?.cancel(old.file.id);
      _bytes = null;
      unawaited(_load());
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
    if (mounted && widget.file.id == file.id && bytes != null) {
      setState(() => _bytes = bytes);
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
            child: Icon(fileKindIcon(widget.file.kind), color: scheme.outline),
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
              duration: const Duration(milliseconds: 120),
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
