import 'dart:developer' as developer;

import 'package:kfm/core/platform/windows/windows_channel.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';

/// Windows thumbnails (TASK-PL1): the Shell's own (`IShellItemImageFactory`,
/// Windows' thumbnail cache, HEIC/RAW when the codecs are installed) through
/// the channel's `thumbnail`. Null → F5's fallback icon; also while the
/// native side isn't built.
ThumbGenerator shellThumbnailGenerator(WindowsChannel channel) =>
    (f, size) async {
      if (!f.id.startsWith('path:') || !DiskThumbnailCache.hasThumbnail(f)) {
        return null;
      }
      try {
        return await channel.thumbnail(f.path, size);
      } on WindowsChannelException catch (e) {
        if (e.code != 'MISSING') {
          developer.log('shell thumb failed ${f.id}: $e', name: 'kfm.thumbs');
        }
        return null;
      }
    };
