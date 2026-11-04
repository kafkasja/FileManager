import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/media_damage.dart';
import 'package:kfm/features/connect/data/loopback_media_proxy.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart' show VideoPlayerValue;

/// Windows video (TASK-PL1): media_kit (libmpv) behind S5's [VideoHandle],
/// so the pool and the surface stay the same as on Android (`video_player`
/// has no Windows backend). The player's streams are folded into a
/// [VideoPlayerValue] for [state]. A connected device's video streams
/// through N5's loopback proxy like [PlayerHandle].
///
/// A file that can't play ([DamagedFileException]): its first 64 KiB are
/// zero bytes (checked before libmpv opens it), libmpv reports an error,
/// or no duration arrives within [openTimeout].
class MediaKitHandle implements VideoHandle {
  new(this._file, {this._mediaProxy, this.openTimeout = _defaultTimeout});

  static const _defaultTimeout = Duration(seconds: 8);

  final FileRef _file;
  final Future<LoopbackMediaProxy> Function()? _mediaProxy;

  /// How long [initialize] waits for the duration before giving up.
  final Duration openTimeout;

  Player? _player;
  VideoController? _controller;
  final List<StreamSubscription<Object?>> _subs = [];
  bool _disposed = false;

  final ValueNotifier<VideoPlayerValue> _value = ValueNotifier(
    const VideoPlayerValue.uninitialized(),
  );

  @override
  ValueListenable<VideoPlayerValue> get state => _value;

  void _update(VideoPlayerValue Function(VideoPlayerValue v) change) {
    if (_disposed) return;
    _value.value = change(_value.value);
  }

  Future<String> _location() async {
    if (_file.origin != FileOrigin.remote) return _file.path;
    final mediaProxy =
        _mediaProxy ??
        (throw const FileOpException(
          FileOpFailure.unavailable,
          'no media proxy',
        ));
    final proxy = await mediaProxy();
    return proxy.urlFor(_file).toString();
  }

  @override
  Future<void> initialize() async {
    final location = await _location();
    if (_disposed) throw StateError('disposed');
    if (_file.origin != FileOrigin.remote && await looksDamaged(location)) {
      throw DamagedFileException(location, 'only zero bytes');
    }
    final player = _player = Player();
    _controller = VideoController(player);
    // The controller creates its texture after the next frame, and
    // `open` waits for it: make sure a frame comes even when the app idles.
    SchedulerBinding.instance.ensureVisualUpdate();
    final s = player.stream;
    final ready = Completer<void>();
    _subs.addAll([
      s.duration.listen((d) {
        _update((v) => v.copyWith(duration: d));
        if (d > Duration.zero && !ready.isCompleted) ready.complete();
      }),
      s.position.listen((p) => _update((v) => v.copyWith(position: p))),
      s.playing.listen((p) => _update((v) => v.copyWith(isPlaying: p))),
      s.buffering.listen((b) => _update((v) => v.copyWith(isBuffering: b))),
      s.width.listen((_) => _updateSize(player)),
      s.height.listen((_) => _updateSize(player)),
      s.error.listen((e) {
        _update((v) => v.copyWith(errorDescription: e));
        if (!ready.isCompleted) {
          ready.completeError(DamagedFileException(location, 'media_kit: $e'));
        }
      }),
    ]);
    await player.open(Media(location), play: false);
    try {
      await ready.future.timeout(openTimeout);
    } on TimeoutException {
      throw DamagedFileException(location, 'media_kit: no duration in time');
    }
    if (_disposed) throw StateError('disposed');
    _updateSize(player);
    _update((v) => v.copyWith(isInitialized: true));
  }

  void _updateSize(Player player) {
    final w = player.state.width;
    final h = player.state.height;
    if (w == null || h == null || w <= 0 || h <= 0) return;
    _update((v) => v.copyWith(size: Size(w.toDouble(), h.toDouble())));
  }

  @override
  Future<void> play() async => await _player?.play();

  @override
  Future<void> pause() async => await _player?.pause();

  /// [volume] is 0..1 like video_player; media_kit uses 0..100.
  @override
  Future<void> setVolume(double volume) async {
    await _player?.setVolume(volume.clamp(0, 1) * 100);
    _update((v) => v.copyWith(volume: volume));
  }

  @override
  Future<void> setLooping({required bool looping}) async {
    await _player?.setPlaylistMode(
      looping ? PlaylistMode.single : PlaylistMode.none,
    );
    _update((v) => v.copyWith(isLooping: looping));
  }

  @override
  Future<void> seekTo(Duration position) async => await _player?.seek(position);

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final s in _subs) {
      await s.cancel();
    }
    _value.dispose();
    await _player?.dispose();
  }

  @override
  Widget view({Size? fallbackSize}) {
    final c = _controller;
    if (c == null) return const SizedBox.shrink();
    final reported = _value.value.size;
    final size = reported.width > 0 && reported.height > 0
        ? reported
        : (fallbackSize ?? const Size(16, 9));
    return AspectRatio(
      aspectRatio: size.width / size.height,
      child: Video(
        controller: c,
        controls: null, // the deck has its own scrub bar
        // The deck decides what plays; the app keeps the screen awake itself.
        wakelock: false,
        pauseUponEnteringBackgroundMode: false,
        fill: const Color(0x00000000),
      ),
    );
  }
}

/// The Windows [VideoHandleFactory] (`main.dart` overrides
/// `videoHandleFactoryProvider` with it).
VideoHandleFactory mediaKitHandleFactory(
  Future<LoopbackMediaProxy> Function() mediaProxy,
) =>
    (file) => MediaKitHandle(file, mediaProxy: mediaProxy);
