import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/media_damage.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';
import 'package:video_player/video_player.dart';

/// A video in the deck or the viewer (S5): thumbnail until the first frame,
/// plays looped when [active] (muted unless sound was turned on), duration
/// badge, scrub bar along the bottom (drags there seek, never swipe). The
/// viewer gets the same pooled player, so playback continues where it was.
class VideoSurface extends ConsumerStatefulWidget {
  const new({
    required this.file,
    required this.active,
    this.fullscreen = false,
    this.desktopControls = false,
    super.key,
  });

  final FileRef file;

  /// PL3 Quick look: a desktop control bar (play/pause, a scrub slider you
  /// can click or drag, times, sound) instead of the thin phone bar. The
  /// desktop app always gets it (the viewer too), and a click on the video
  /// plays / pauses it ([VideoPaused]).
  final bool desktopControls;

  /// Only the current card plays; others are prepared but paused.
  final bool active;

  /// In a fullscreen viewer the sound/duration pill sits bottom-start, clear
  /// of the status bar and the ✕ (B7, seen on the S22).
  final bool fullscreen;

  @override
  ConsumerState<VideoSurface> createState() => _VideoSurfaceState();
}

class _VideoSurfaceState extends ConsumerState<VideoSurface> {
  VideoHandle? _handle;
  Object? _error;

  /// Opening takes a while (a big or broken file): a spinner after a
  /// moment instead of a silent black picture.
  bool _slow = false;
  Timer? _slowTimer;

  /// False while the tab is hidden (go_router turns tickers off there): a
  /// hidden deck doesn't play, and plays again when shown (B7).
  bool? _visible;

  bool get _desktop =>
      widget.desktopControls || ref.read(formFactorProvider).isDesktop;

  bool get _pausedByUser =>
      _desktop && ref.read(videoPausedProvider).contains(widget.file.id);

  bool get _shouldPlay => widget.active && (_visible ?? true) && !_pausedByUser;

  void _togglePlay() =>
      ref.read(videoPausedProvider.notifier).toggle(widget.file.id);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    final was = _visible;
    _visible = visible;
    if (was == null || was == visible) return;
    // A preview elsewhere may have paused or evicted the pooled player:
    // obtain it again (same player if still alive).
    unawaited(visible && widget.active ? _obtain() : _applyPlayback());
  }

  @override
  void initState() {
    super.initState();
    _slowTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted && _handle == null && _error == null) {
        setState(() => _slow = true);
      }
    });
    unawaited(_obtain());
  }

  @override
  void didUpdateWidget(VideoSurface old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) unawaited(_applyPlayback());
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
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
    if (_shouldPlay) {
      await handle.setVolume(ref.read(videoMutedProvider) ? 0 : 1);
      await handle.play();
    } else {
      await handle.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(videoMutedProvider, (_, muted) {
        _handle?.setVolume(muted ? 0 : 1).ignore();
      })
      // Desktop: a pause / play from the bar, a click or Space.
      ..listen(
        videoPausedProvider.select((s) => s.contains(widget.file.id)),
        (_, _) => unawaited(_applyPlayback()),
      );
    final handle = _handle;
    final muted = ref.watch(videoMutedProvider);
    final desktop =
        widget.desktopControls || ref.watch(formFactorProvider).isDesktop;
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
        if (_error case final e?)
          Center(
            child: _Pill(
              key: const ValueKey('video-error'),
              icon: e is DamagedFileException
                  ? Icons.broken_image_outlined
                  : null,
              text: e is DamagedFileException
                  ? context.l10n.videoDamaged
                  : context.l10n.videoCantPlay,
            ),
          )
        else if (handle == null && _slow)
          const Center(
            child: SizedBox.square(
              dimension: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
        if (desktop) ...[
          // A click on the picture plays / pauses (only once this surface
          // plays: an inactive one leaves the click to its parent, e.g.
          // B7's ▶).
          if (handle != null && widget.active)
            GestureDetector(
              key: const ValueKey('desktop-video-area'),
              behavior: HitTestBehavior.opaque,
              onTap: _togglePlay,
            ),
          if (handle != null)
            Align(
              alignment: Alignment.bottomCenter,
              // Mouse only: ← → stay Quick look's previous / next. In the
              // fullscreen viewer it sits above the action buttons.
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  bottom: widget.fullscreen ? 72 : 0,
                ),
                child: ExcludeFocus(
                  child: DesktopVideoBar(
                    handle: handle,
                    onTogglePlay: _togglePlay,
                  ),
                ),
              ),
            ),
        ] else ...[
          PositionedDirectional(
            start: widget.fullscreen ? 16 : 8,
            top: widget.fullscreen ? null : 8,
            // Fullscreen viewers put their action row (ⓘ, Share, Delete…)
            // at the bottom: the pill sits above it, never under it.
            bottom: widget.fullscreen
                ? MediaQuery.paddingOf(context).bottom + kVideoPillAboveActions
                : null,
            child: handle == null
                ? _Pill(
                    icon: muted ? Icons.volume_off : Icons.volume_up,
                    text: formatDuration(
                      Duration(milliseconds: widget.file.durationMs ?? 0),
                    ),
                  )
                : ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: handle.state,
                    builder: (context, value, _) => _Pill(
                      key: const ValueKey('video-time-left'),
                      icon: muted ? Icons.volume_off : Icons.volume_up,
                      text: formatDuration(
                        videoTimeLeft(
                          value,
                          fallbackMs: widget.file.durationMs ?? 0,
                        ),
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
      ],
    );
  }
}

/// Bottom offset of the phone video pill in fullscreen viewers: clear of
/// their action row (16 padding + 48 buttons + 16 gap).
const double kVideoPillAboveActions = 80;

/// What the phone video pill shows: the time left, counting down while it
/// plays (the whole length before it starts). MediaStore sometimes reports
/// a 0 duration (seen on a device): the player's duration wins once known.
Duration videoTimeLeft(VideoPlayerValue value, {required int fallbackMs}) {
  final total = value.duration > Duration.zero
      ? value.duration
      : Duration(milliseconds: fallbackMs);
  final left = total - value.position;
  return left.isNegative ? Duration.zero : left;
}

/// PL3 Quick look's video bar: play/pause, position, a slider (click or
/// drag to seek; seeks are throttled to one per 80 ms while dragging),
/// duration and sound.
class DesktopVideoBar extends ConsumerStatefulWidget {
  const new({required this.handle, this.onTogglePlay, super.key});

  final VideoHandle handle;

  /// The play/pause button (VideoSurface keeps the user's pause); without
  /// it the button calls the handle directly.
  final VoidCallback? onTogglePlay;

  @override
  ConsumerState<DesktopVideoBar> createState() => _DesktopVideoBarState();
}

class _DesktopVideoBarState extends ConsumerState<DesktopVideoBar> {
  static const _throttle = Duration(milliseconds: 80);
  DateTime _lastSeek = DateTime.fromMillisecondsSinceEpoch(0);
  double? _dragFraction;
  bool _wasPlaying = false;

  void _seek(double f, Duration total, {bool force = false}) {
    final now = DateTime.now();
    if (!force && now.difference(_lastSeek) < _throttle) return;
    _lastSeek = now;
    widget.handle.seekTo(total * f).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = ref.watch(videoMutedProvider);
    const white = Colors.white;
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.handle.state,
      builder: (context, value, _) {
        final total = value.duration;
        final ms = total.inMilliseconds;
        final fraction =
            (_dragFraction ??
                    (ms == 0 ? 0.0 : value.position.inMilliseconds / ms))
                .clamp(0.0, 1.0);
        final position = _dragFraction == null
            ? value.position
            : total * _dragFraction!;
        return Material(
          key: const ValueKey('desktop-video-bar'),
          color: Colors.black54,
          // A fixed height: the Slider takes all the height it is offered,
          // which made the bar cover the whole video (clicks on the
          // picture hit the bar, the picture was dimmed).
          child: Container(
            height: 48,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('desktop-video-play'),
                  tooltip: value.isPlaying ? l10n.videoPause : l10n.videoPlay,
                  color: white,
                  icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed:
                      widget.onTogglePlay ??
                      () =>
                          (value.isPlaying
                                  ? widget.handle.pause()
                                  : widget.handle.play())
                              .ignore(),
                ),
                Text(
                  formatDuration(position),
                  style: const TextStyle(color: white),
                ),
                Expanded(
                  child: Slider(
                    key: const ValueKey('desktop-video-slider'),
                    value: fraction,
                    onChangeStart: ms == 0
                        ? null
                        : (_) {
                            _wasPlaying = value.isPlaying;
                            widget.handle.pause().ignore();
                          },
                    onChanged: ms == 0
                        ? null
                        : (f) {
                            setState(() => _dragFraction = f);
                            _seek(f, total);
                          },
                    onChangeEnd: ms == 0
                        ? null
                        : (f) {
                            _seek(f, total, force: true);
                            setState(() => _dragFraction = null);
                            if (_wasPlaying) widget.handle.play().ignore();
                          },
                  ),
                ),
                Text(
                  formatDuration(total),
                  style: const TextStyle(color: white),
                ),
                IconButton(
                  key: const ValueKey('desktop-video-sound'),
                  tooltip: muted ? l10n.videoSoundOn : l10n.videoSoundOff,
                  color: white,
                  icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
                  onPressed: () =>
                      ref.read(videoMutedProvider.notifier).toggle(),
                ),
              ],
            ),
          ),
        );
      },
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
                    _Pill(text: formatDuration(total * _dragFraction!)),
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
  const new({required this.text, this.icon, super.key});

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

/// Desktop viewers: Space plays / pauses [file] when it is a video
/// ([VideoPaused]). Takes the keyboard focus when shown.
class DesktopVideoKeys extends ConsumerWidget {
  const new({required this.file, required this.child, super.key});

  final FileRef? file;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Focus(
    autofocus: true,
    onKeyEvent: (_, e) {
      final f = file;
      if (f == null ||
          f.kind != FileKind.video ||
          e.logicalKey != LogicalKeyboardKey.space) {
        return KeyEventResult.ignored;
      }
      if (e is KeyDownEvent) {
        ref.read(videoPausedProvider.notifier).toggle(f.id);
      }
      return KeyEventResult.handled;
    },
    child: child,
  );
}
