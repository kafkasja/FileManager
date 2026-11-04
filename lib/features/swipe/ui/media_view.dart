import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/features/connect/ui/remote_image_provider.dart';
import 'package:kfm/features/swipe/ui/video_surface.dart';

/// The image decoded at display width (never full resolution). S3 reuses it
/// so fullscreen opens from the same cache entry. Files of a connected
/// device (N7) come over its pinned client (`/preview`): pass [remote]
/// (`remoteMediaAccessProvider`); without it they fail to load and keep
/// their placeholder.
ImageProvider<Object> displayImageProvider(
  FileRef file,
  int widthPx, {
  RemoteMediaAccess? remote,
}) => file.origin == FileOrigin.remote
    ? remoteDisplayImage(remote ?? RemoteMediaAccess.none, file, widthPx)
    : ResizeImage(
        FileImage(File(file.path)),
        width: widthPx,
        policy: ResizeImagePolicy.fit,
      );

/// A photo or video shown large: the thumbnail first, the display-size
/// image fading in over it. Undecodable files keep the placeholder and can
/// still be swiped. Videos show their frame + a play icon (S5 plays them).
class MediaView extends ConsumerWidget {
  const new({
    required this.file,
    this.active = true,
    this.desktopVideoControls = false,
    super.key,
  });

  final FileRef file;

  /// PL3 Quick look: videos get the desktop control bar.
  final bool desktopVideoControls;

  /// Videos play only on the current card (S5); others are just prepared.
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remote = file.origin == FileOrigin.remote
        ? ref.watch(remoteMediaAccessProvider)
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthPx =
            (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                .round();
        return Stack(
          fit: StackFit.expand,
          children: [
            Thumbnail(file: file, fit: BoxFit.contain),
            if (file.kind == FileKind.image)
              Image(
                image: displayImageProvider(file, widthPx, remote: remote),
                fit: BoxFit.contain,
                gaplessPlayback: true,
                frameBuilder: (context, child, frame, wasSync) =>
                    wasSync || frame != null ? child : const SizedBox.shrink(),
                // Quick look (desktop) says why; the deck keeps the
                // placeholder.
                errorBuilder: (context, _, _) => desktopVideoControls
                    ? Center(
                        child: Container(
                          key: const ValueKey('image-error'),
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            context.l10n.imageDamaged,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            if (file.kind == FileKind.video)
              VideoSurface(
                file: file,
                active: active,
                desktopControls: desktopVideoControls,
              ),
          ],
        );
      },
    );
  }
}
