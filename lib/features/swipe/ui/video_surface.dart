import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';
import 'package:video_player/video_player.dart';

/// A video in the deck or the viewer (S5): thumbnail until the first frame,
/// plays looped when [active] (muted unless sound was turned on), duration
/// badge, scrub bar along the bottom (drags there seek, never swipe). The
/// viewer gets the same pooled player, so playback continues where it was.
class VideoSurface extends ConsumerStatefulWidget {
  const new({required this.file, required this.active, super.key});

  final FileRef file;

  /// Only the current card plays; others are prepared but paused.
  final bool active;

  @override
  ConsumerState<VideoSurface> createState() => _VideoSurfaceState();
}

class _VideoSurfaceState extends ConsumerState<VideoSurface> {
  VideoHandle? _handle;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_obtain());
  }

  @override
  void didUpdateWidget(VideoSurface old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) unawaited(_applyPlayback());
  }

  @override
  void dispose() {
    // The pool owns the player; only stop it playing.
    _handle?.pause().ignore();
    super.dispose();
  }

  Size? get _fileSize {
    final w = widget.file.width;
    final h = widget.file.height;
    return w != null && h != null && w > 0 && h > 0
        ? Size(w.toDouble(), h.toDouble())
        : null;
  }

  Future<void> _obtain() async {
    try {
      final handle = await ref
          .read(videoControllerPoolProvider)
          .obtain(widget.file);
      if (!mounted) return;
      setState(() => _handle = handle);
      await _applyPlayback();
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _applyPlayback() async {
    final handle = _handle;
    if (handle == null) return;
    if (widget.active) {
      await handle.setVolume(ref.read(videoMutedProvider) ? 0 : 1);
      await handle.play();
    } else {
      await handle.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(videoMutedProvider, (_, muted) {
      _handle?.setVolume(muted ? 0 : 1).ignore();
    });
    final handle = _handle;
    final muted = ref.watch(videoMutedProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        Thumbnail(file: widget.file, fit: BoxFit.contain),
        if (handle != null)
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: handle.state,
            builder: (context, value, _) => value.isInitialized
                ? Center(child: handle.view(fallbackSize: _fileSize))
                : const SizedBox.shrink(),
          ),
        if (_error != null)
          Center(child: _Pill(text: context.l10n.videoCantPlay)),
        PositionedDirectional(
          start: 8,
          top: 8,
          child: handle == null
              ? _Pill(
                  icon: muted ? Icons.volume_off : Icons.volume_up,
                  text: _formatDuration(
                    Duration(milliseconds: widget.file.durationMs ?? 0),
                  ),
                )
              // MediaStore sometimes reports 0 (seen on a device): prefer
              // the player's duration once it is known.
              : ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: handle.state,
                  builder: (context, value, _) => _Pill(
                    icon: muted ? Icons.volume_off : Icons.volume_up,
                    text: _formatDuration(
                      value.duration > Duration.zero
                          ? value.duration
                          : Duration(milliseconds: widget.file.durationMs ?? 0),
                    ),
                  ),
                ),
        ),
        if (handle != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: _ScrubBar(handle: handle),
          ),
      ],
    );
  }
}

/// Seek bar: horizontal drags seek (throttled to one call per 80 ms) and
/// win over the card's swipe gesture; release resumes playback.
class _ScrubBar extends StatefulWidget {
  const new({required this.handle});

  final VideoHandle handle;

  @override
  State<_ScrubBar> createState() => _ScrubBarState();
}

class _ScrubBarState extends State<_ScrubBar> {
  static const _throttle = Duration(milliseconds: 80);
  DateTime _lastSeek = DateTime.fromMillisecondsSinceEpoch(0);
  double? _dragFraction;

  void _seekTo(double fraction, Duration total) {
    setState(() => _dragFraction = fraction.clamp(0, 1));
    final now = DateTime.now();
    if (now.difference(_lastSeek) < _throttle) return;
    _lastSeek = now;
    widget.handle.seekTo(total * _dragFraction!).ignore();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.handle.state,
      builder: (context, value, _) {
        final total = value.duration;
        final fraction =
            _dragFraction ??
            (total.inMilliseconds == 0
                ? 0.0
                : value.position.inMilliseconds / total.inMilliseconds);
        return LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => widget.handle.pause().ignore(),
            onHorizontalDragUpdate: (d) =>
                _seekTo(d.localPosition.dx / constraints.maxWidth, total),
            onHorizontalDragEnd: (_) {
              final f = _dragFraction;
              if (f != null) widget.handle.seekTo(total * f).ignore();
              setState(() => _dragFraction = null);
              widget.handle.play().ignore();
            },
            child: SizedBox(
              height: 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_dragFraction != null)
                    _Pill(text: _formatDuration(total * _dragFraction!)),
                  LinearProgressIndicator(
                    value: fraction.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const new({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
        ],
        Text(text, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}

/// 1:23 / 1:02:03.
String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}
