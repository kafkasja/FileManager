import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:kfm/core/files/file_ref.dart';
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

  /// The video picture, letterboxed. [fallbackSize] (MediaStore width ×
  /// height) is used while the player reports no size (seen on a device).
  Widget view({Size? fallbackSize});
}

typedef VideoHandleFactory = VideoHandle Function(FileRef file);

/// video_player (ExoPlayer on Android). Muted playback doesn't take audio
/// focus from the user's music (`mixWithOthers`).
class PlayerHandle implements VideoHandle {
  new(FileRef file)
    : _c = file.uri.startsWith('content://')
          ? VideoPlayerController.contentUri(
              Uri.parse(file.uri),
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
            )
          : VideoPlayerController.file(
              File(file.path),
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
            );

  final VideoPlayerController _c;

  @override
  ValueListenable<VideoPlayerValue> get state => _c;
  @override
  Future<void> initialize() => _c.initialize();
  @override
  Future<void> play() => _c.play();
  @override
  Future<void> pause() => _c.pause();
  @override
  Future<void> setVolume(double volume) => _c.setVolume(volume);
  @override
  Future<void> setLooping({required bool looping}) => _c.setLooping(looping);
  @override
  Future<void> seekTo(Duration position) => _c.seekTo(position);
  @override
  Future<void> dispose() => _c.dispose();
  @override
  Widget view({Size? fallbackSize}) {
    final reported = _c.value.size;
    final size = reported.width > 0 && reported.height > 0
        ? reported
        : (fallbackSize ?? const Size(16, 9));
    return FittedBox(
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(_c),
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

  int get aliveCount => _handles.length;

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
      await handle.dispose();
      rethrow;
    }
  }

  void _evictBeyond() {
    while (_handles.length > maxAlive) {
      final oldest = _handles.keys.first;
      final handle = _handles.remove(oldest)!;
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

  Future<void> disposeAll() async {
    final all = _handles.values.toList();
    _handles.clear();
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
VideoHandleFactory videoHandleFactory(Ref ref) => PlayerHandle.new;

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

/// Sound is per session, not per video: once on, following videos play
/// with sound until it's turned off (S5).
@Riverpod(keepAlive: true)
class VideoMuted extends _$VideoMuted {
  @override
  bool build() => true;

  void toggle() => state = !state;
}
