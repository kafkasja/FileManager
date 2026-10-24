import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/features/swipe/ui/video_surface.dart';

/// The image decoded at display width (never full resolution). S3 reuses it
/// so fullscreen opens from the same cache entry.
ImageProvider<Object> displayImageProvider(FileRef file, int widthPx) =>
    ResizeImage(
      FileImage(File(file.path)),
      width: widthPx,
      policy: ResizeImagePolicy.fit,
    );

/// A photo or video shown large: the thumbnail first, the display-size
/// image fading in over it. Undecodable files keep the placeholder and can
/// still be swiped. Videos show their frame + a play icon (S5 plays them).
class MediaView extends StatelessWidget {
  const new({required this.file, this.active = true, super.key});

  final FileRef file;

  /// Videos play only on the current card (S5); others are just prepared.
  final bool active;

  @override
  Widget build(BuildContext context) {
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
                image: displayImageProvider(file, widthPx),
                fit: BoxFit.contain,
                gaplessPlayback: true,
                frameBuilder: (context, child, frame, wasSync) =>
                    wasSync || frame != null ? child : const SizedBox.shrink(),
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            if (file.kind == FileKind.video)
              VideoSurface(file: file, active: active),
          ],
        );
      },
    );
  }
}
