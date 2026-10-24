import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';
import 'package:video_player/video_player.dart';

/// Player stand-in: records calls, can fail to initialise.
class FakeVideoHandle implements VideoHandle {
  new(this.file, {this.fail = false});

  final FileRef file;
  final bool fail;
  final List<String> calls = [];
  final ValueNotifier<VideoPlayerValue> _state = ValueNotifier(
    const VideoPlayerValue.uninitialized(),
  );

  @override
  ValueListenable<VideoPlayerValue> get state => _state;

  @override
  Future<void> initialize() async {
    calls.add('initialize');
    if (fail) throw StateError('codec not supported');
    _state.value = const VideoPlayerValue(
      duration: Duration(seconds: 10),
      isInitialized: true,
      size: Size(1920, 1080),
    );
  }

  @override
  Future<void> play() async => calls.add('play');
  @override
  Future<void> pause() async => calls.add('pause');
  @override
  Future<void> setVolume(double volume) async => calls.add('volume $volume');
  @override
  Future<void> setLooping({required bool looping}) async =>
      calls.add('looping $looping');
  @override
  Future<void> seekTo(Duration position) async =>
      calls.add('seek ${position.inMilliseconds}');
  @override
  Future<void> dispose() async => calls.add('dispose');
  @override
  Widget view({Size? fallbackSize}) =>
      const ColoredBox(color: Color(0xFF000000));
}

/// Creates fakes and remembers them.
class FakeVideoFactory {
  final List<FakeVideoHandle> created = [];
  final Set<String> failing = {};

  VideoHandle call(FileRef f) {
    final h = FakeVideoHandle(f, fail: failing.contains(f.id));
    created.add(h);
    return h;
  }
}
