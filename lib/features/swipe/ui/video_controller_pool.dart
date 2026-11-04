import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/connect/data/loopback_media_proxy.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';

part 'video_controller_pool.g.dart';

/// What the pool and VideoSurface need from a player (fakeable in tests).
abstract interface class VideoHandle {
  ValueListenable<VideoPlayerValue> get state;
  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> setVolume(double volume);
  Future<void> setLooping({required bool looping});
  Future<void> seekTo(Duration position);
  Future<void> dispose();

  /// True once [dispose] ran: a surface still showing it must obtain a new
  /// player (the pool evicted it), never draw it.
  bool get isDisposed;

  /// The video picture, letterboxed. [fallbackSize] (MediaStore width ×
  /// height) is used while the player reports no size (seen on a device).
  Widget view({Size? fallbackSize});
}

typedef VideoHandleFactory = VideoHandle Function(FileRef file);

/// video_player (ExoPlayer on Android). Muted playback doesn't take audio
/// focus from the user's music (`mixWithOthers`). A connected device's
/// video (N7) streams through N5's loopback proxy (`mediaProxy`), so its
/// player is only created in [initialize].
class PlayerHandle implements VideoHandle {
  new(this._file, {this._mediaProxy})
    : _c = _file.origin == FileOrigin.remote ? null : _local(_file);

  static VideoPlayerController _local(FileRef file) =>
      file.uri.startsWith('content://')
      ? VideoPlayerController.contentUri(
          Uri.parse(file.uri),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        )
      : VideoPlayerController.file(
          File(file.path),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );

  final FileRef _file;
  final Future<LoopbackMediaProxy> Function()? _mediaProxy;
  VideoPlayerController? _c;
  bool _disposed = false;

  /// What [state] is before a remote player exists.
  final ValueNotifier<VideoPlayerValue> _idle = ValueNotifier(
    const VideoPlayerValue.uninitialized(),
  );

  @override
  ValueListenable<VideoPlayerValue> get state => _c ?? _idle;

  @override
  Future<void> initialize() async {
    var c = _c;
    if (c == null) {
      final mediaProxy =
          _mediaProxy ??
          (throw const FileOpException(
            FileOpFailure.unavailable,
            'no media proxy',
          ));
      final proxy = await mediaProxy();
      if (_disposed) throw StateError('disposed');
      c = _c = VideoPlayerController.networkUrl(
        proxy.urlFor(_file),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    }
    await c.initialize();
  }

  @override
  Future<void> play() async => await _c?.play();
  @override
  Future<void> pause() async => await _c?.pause();
  @override
  Future<void> setVolume(double volume) async => await _c?.setVolume(volume);
  @override
  Future<void> setLooping({required bool looping}) async =>
      await _c?.setLooping(looping);
  @override
  Future<void> seekTo(Duration position) async => await _c?.seekTo(position);
  @override
  bool get isDisposed => _disposed;

  @override
  Future<void> dispose() async {
    _disposed = true;
    _idle.dispose();
    await _c?.dispose();
  }

  @override
  Widget view({Size? fallbackSize}) {
    final c = _c;
    if (c == null || _disposed) return const SizedBox.shrink();
    final reported = c.value.size;
    final size = reported.width > 0 && reported.height > 0
        ? reported
        : (fallbackSize ?? const Size(16, 9));
    return FittedBox(
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(c),
      ),
    );
  }
}

/// At most [maxAlive] initialised players (current + next): some phones
/// have few hardware decoders, and fast swiping must not pile them up (S5).
class VideoControllerPool {
  new({required this._factory, this.maxAlive = 2})
    : assert(maxAlive >= 2, 'current + next');

  final int maxAlive;
  final VideoHandleFactory _factory;

  /// Insertion order = least recently obtained first.
  final Map<String, Future<VideoHandle>> _handles = {};
  final Map<String, FileRef> _files = {};

  /// Players a surface is playing right now: never evicted (evicting the
  /// viewer's player when the deck behind it obtained its own showed "A
  /// VideoPlayerController was used after being disposed", S22).
  final Set<String> _playing = {};

  int get aliveCount => _handles.length;

  /// A video surface starts or stops playing [fileId]'s player.
  /// A playing player doesn't count toward [maxAlive]; when it stops, the
  /// pool shrinks back to the cap.
  void setPlaying(String fileId, {required bool playing}) {
    if (playing) {
      _playing.add(fileId);
    } else if (_playing.remove(fileId)) {
      _evictBeyond();
    }
  }

  /// The player for [file], initialised, looping and muted. Initialisation
  /// errors propagate (the surface shows "Can't play this video").
  Future<VideoHandle> obtain(FileRef file) {
    final existing = _handles.remove(file.id);
    if (existing != null) {
      _handles[file.id] = existing; // most recently used
      return existing;
    }
    final created = _create(file);
    _handles[file.id] = created;
    _files[file.id] = file;
    _evictBeyond();
    return created;
  }

  Future<VideoHandle> _create(FileRef file) async {
    final handle = _factory(file);
    try {
      await handle.initialize();
      await handle.setLooping(looping: true);
      await handle.setVolume(0);
      return handle;
    } on Object {
      // The caller holds this same future and sees the error.
      _handles.remove(file.id)?.ignore();
      _files.remove(file.id);
      await handle.dispose();
      rethrow;
    }
  }

  void _evictBeyond() {
    // Playing players never go and don't count (a swiped-away card still
    // plays for a frame or two; the viewer plays over a hidden deck).
    // Least recently obtained first; the newest, just obtained, stays.
    while (true) {
      final idle = [
        for (final id in _handles.keys)
          if (!_playing.contains(id)) id,
      ];
      if (idle.length <= maxAlive) return;
      final newest = _handles.keys.last;
      final oldest = idle.firstWhere((id) => id != newest);
      final handle = _handles.remove(oldest)!;
      _files.remove(oldest);
      unawaited(
        handle.then<void>(
          (h) => h.dispose(),
          onError: (Object _) {}, // a failed init was already disposed
        ),
      );
    }
  }

  /// App in background: nothing plays.
  Future<void> pauseAll() async {
    for (final h in _handles.values) {
      try {
        await (await h).pause();
      } on Object {
        // Not initialised (failed): nothing to pause.
      }
    }
  }

  Future<void> disposeAll() => disposeWhere((_) => true);

  /// U3: disposes the players of files matching [test] (a volume is being
  /// ejected: no open handle may stay on it).
  Future<void> disposeWhere(bool Function(FileRef f) test) async {
    final ids = [
      for (final e in _files.entries)
        if (test(e.value)) e.key,
    ];
    final all = [for (final id in ids) ?_handles.remove(id)];
    ids.forEach(_files.remove);
    for (final h in all) {
      try {
        await (await h).dispose();
      } on Object {
        // A failed init was already disposed.
      }
    }
  }
}

@Riverpod(keepAlive: true)
VideoHandleFactory videoHandleFactory(Ref ref) =>
    (file) => PlayerHandle(
      file,
      mediaProxy: ref
          .read(remoteConnectionControllerProvider.notifier)
          .mediaProxy,
    );

@Riverpod(keepAlive: true)
VideoControllerPool videoControllerPool(Ref ref) {
  final pool = VideoControllerPool(
    factory: ref.watch(videoHandleFactoryProvider),
  );
  final lifecycle = AppLifecycleListener(
    onPause: () => pool.pauseAll().ignore(),
  );
  ref.onDispose(() {
    lifecycle.dispose();
    pool.disposeAll().ignore();
  });
  return pool;
}

/// Sound is per session, not per video. On by default: the phone's own
/// volume decides (user, 2026-11-04); the pill's speaker icon mutes until
/// it is tapped again.
@Riverpod(keepAlive: true)
class VideoMuted extends _$VideoMuted {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

/// Desktop: the videos the user paused (click on the video, the bar's
/// play/pause button, Space) and the phone (a tap on the video, user
/// 2026-11-04). A pause sticks until they play it again, whatever shows the
/// video next (deck, Quick look, the viewer).
@Riverpod(keepAlive: true)
class VideoPaused extends _$VideoPaused {
  @override
  Set<String> build() => const {};

  void toggle(String fileId) => state = state.contains(fileId)
      ? ({...state}..remove(fileId))
      : {...state, fileId};
}
