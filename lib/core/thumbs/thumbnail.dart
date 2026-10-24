import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';

/// A file's thumbnail: neutral placeholder (no spinner, no layout shift),
/// fades in over 120 ms, cancels its request when disposed.
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
    return ColoredBox(
      color: widget.background ?? scheme.surfaceContainerHighest,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Icon(_iconFor(widget.file.kind), color: scheme.outline),
          ),
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

  static IconData _iconFor(FileKind kind) => switch (kind) {
    FileKind.image => Icons.image_outlined,
    FileKind.video => Icons.movie_outlined,
    FileKind.audio => Icons.audiotrack_outlined,
    FileKind.document => Icons.description_outlined,
    FileKind.archive => Icons.folder_zip_outlined,
    FileKind.other => Icons.insert_drive_file_outlined,
  };
}
