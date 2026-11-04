import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/desktop/widgets/quick_look.dart';
import 'package:kfm/features/swipe/ui/file_viewer.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';
import 'package:video_player/video_player.dart';

import '../core/files/fake_file_source.dart';
import '../features/swipe/fake_video.dart';
import 'desktop_helpers.dart';

/// A fake player whose state follows play / pause like a real one.
class _PlayingVideo extends FakeVideoHandle {
  new(super.file);

  ValueNotifier<VideoPlayerValue> get _value =>
      state as ValueNotifier<VideoPlayerValue>;

  @override
  Future<void> play() async {
    await super.play();
    _value.value = _value.value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    await super.pause();
    _value.value = _value.value.copyWith(isPlaying: false);
  }
}

class _Videos extends FakeVideoFactory {
  final List<_PlayingVideo> handles = [];

  @override
  VideoHandle call(FileRef f) {
    final h = _PlayingVideo(f);
    handles.add(h);
    return h;
  }
}

Future<(FileRef, _Videos, BuildContext)> _setUp(WidgetTester tester) async {
  final files = FakeFileSource();
  final clip = files.addFile('/s/Videos/clip.mp4');
  final videos = _Videos();
  await pumpDesktopApp(tester, files: files, videos: videos);
  final context = tester.element(find.byType(Scaffold).first);
  return (clip, videos, context);
}

bool _playing(_Videos v) => v.handles.single.state.value.isPlaying;

void main() {
  testWidgets('Quick look: the bar, a click on the video and Space pause '
      'and play; Esc closes', (tester) async {
    final (clip, videos, context) = await _setUp(tester);
    showQuickLook(
      context,
      watchFiles: (ref) => [clip],
      startId: clip.id,
    ).ignore();
    await tester.pumpAndSettle();
    expect(_playing(videos), isTrue);

    await tester.tap(find.byKey(const ValueKey('desktop-video-play')));
    await tester.pumpAndSettle();
    expect(_playing(videos), isFalse, reason: 'pause button');

    await tester.tap(find.byKey(const ValueKey('desktop-video-area')));
    await tester.pumpAndSettle();
    expect(_playing(videos), isTrue, reason: 'click on the video plays');

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(_playing(videos), isFalse, reason: 'Space pauses');
    // Space didn't close Quick look on a video.
    expect(find.byKey(const ValueKey('quick-look-close')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(_playing(videos), isTrue, reason: 'Space plays');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quick-look-close')), findsNothing);
  });

  testWidgets('Quick look: Space still closes a photo', (tester) async {
    final files = FakeFileSource();
    final photo = files.addFile('/s/DCIM/p.jpg');
    await pumpDesktopApp(tester, files: files);
    final context = tester.element(find.byType(Scaffold).first);
    showQuickLook(
      context,
      watchFiles: (ref) => [photo],
      startId: photo.id,
    ).ignore();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quick-look-close')), findsNothing);
  });

  testWidgets('desktop viewer: desktop bar, click and Space pause and play', (
    tester,
  ) async {
    final (clip, videos, context) = await _setUp(tester);
    openViewer(context, clip, swipeable: false).ignore();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('desktop-video-bar')), findsOneWidget);
    expect(_playing(videos), isTrue);

    await tester.tap(find.byKey(const ValueKey('desktop-video-area')));
    // The viewer's double-click zoom makes a single click wait a moment.
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(_playing(videos), isFalse, reason: 'click pauses');

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(_playing(videos), isTrue, reason: 'Space plays');

    await tester.tap(find.byKey(const ValueKey('desktop-video-play')));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(_playing(videos), isFalse, reason: 'pause button');
  });
}
