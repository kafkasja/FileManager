import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/swipe/ui/file_viewer.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';
import 'fake_video.dart';

FileRef _video(String id) => FileRef(
  id: id,
  uri: '/s/$id.mp4',
  name: '$id.mp4',
  kind: FileKind.video,
  sizeBytes: 1,
  modifiedAt: DateTime.utc(2025),
  folderPath: '/s',
  origin: FileOrigin.local,
);

void main() {
  group('VideoControllerPool', () {
    test('keeps at most 2 alive, disposing the oldest', () async {
      final factory = FakeVideoFactory();
      final pool = VideoControllerPool(factory: factory.call);
      for (final id in ['a', 'b', 'c', 'd']) {
        await pool.obtain(_video(id));
      }
      await Future<void>.delayed(Duration.zero);
      expect(pool.aliveCount, 2);
      expect(factory.created[0].calls, contains('dispose'));
      expect(factory.created[1].calls, contains('dispose'));
      expect(factory.created[3].calls, isNot(contains('dispose')));
      expect(factory.created[3].calls, [
        'initialize',
        'looping true',
        'volume 0.0',
      ]);
    });

    test('the same file gets the same player', () async {
      final pool = VideoControllerPool(factory: FakeVideoFactory().call);
      final a = await pool.obtain(_video('a'));
      expect(await pool.obtain(_video('a')), same(a));
    });

    test('a failed init errors, disposes, and is not kept', () async {
      final factory = FakeVideoFactory()..failing.add('bad');
      final pool = VideoControllerPool(factory: factory.call);
      await expectLater(pool.obtain(_video('bad')), throwsStateError);
      expect(pool.aliveCount, 0);
      expect(factory.created.single.calls, contains('dispose'));
    });
  });

  Future<(TestApp, FakeVideoFactory)> pumpVideos(
    WidgetTester tester, {
    Set<String> failing = const {},
  }) async {
    final files = FakeFileSource();
    for (var i = 0; i < 3; i++) {
      files.addFile(
        '/s/DCIM/v$i.mp4',
        modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
        mimeType: 'video/mp4',
      );
    }
    final videos = FakeVideoFactory()..failing.addAll(failing);
    final app = await pumpApp(tester, files: files, videos: videos);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    return (app, videos);
  }

  testWidgets('the current video plays muted; the next is only prepared', (
    tester,
  ) async {
    final (_, videos) = await pumpVideos(tester);
    final current = videos.created.firstWhere((h) => h.file.name == 'v2.mp4');
    final next = videos.created.firstWhere((h) => h.file.name == 'v1.mp4');
    expect(current.calls, containsAllInOrder(['volume 0.0', 'play']));
    expect(next.calls, isNot(contains('play')));
  });

  testWidgets('tap toggles sound instead of opening the viewer', (
    tester,
  ) async {
    final (app, videos) = await pumpVideos(tester);
    await tester.tap(find.byType(SwipeCard));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byType(FileViewer), findsNothing);
    expect(app.container.read(videoMutedProvider), isFalse);
    final current = videos.created.firstWhere((h) => h.file.name == 'v2.mp4');
    expect(current.calls, contains('volume 1.0'));
  });

  testWidgets('the expand button opens the viewer', (tester) async {
    await pumpVideos(tester);
    await tester.tap(find.byTooltip('Open fullscreen'));
    // The card's double-tap window has to pass before the button's tap wins.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byType(FileViewer), findsOneWidget);
  });

  testWidgets("a video that can't play says so and can still be swiped", (
    tester,
  ) async {
    final (app, _) = await pumpVideos(tester, failing: {'path:/s/DCIM/v2.mp4'});
    expect(find.text("Can't play this video"), findsOneWidget);
    await tester.drag(find.byType(SwipeCard), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.text("Can't play this video"), findsNothing);
    expect(app.files.files, hasLength(3));
  });
}
