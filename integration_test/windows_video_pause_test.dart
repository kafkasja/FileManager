// Windows-only (desktop fixes): the desktop video bar pauses a real
// media_kit player. Run with
//   flutter test integration_test/windows_video_pause_test.dart -d windows
@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/platform/windows/media_kit_handle.dart';
import 'package:kfm/desktop/widgets/quick_look.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';
import 'package:kfm/features/swipe/ui/video_surface.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:media_kit/media_kit.dart';

import 'windows_media_kit_test.dart' show mjpegAvi;

FileRef _ref(File f) => FileRef(
  id: 'path:${f.path.replaceAll(r'\', '/')}',
  uri: f.uri.toString(),
  name: f.uri.pathSegments.last,
  kind: FileKind.video,
  sizeBytes: f.lengthSync(),
  modifiedAt: DateTime.now(),
  folderPath: f.parent.path.replaceAll(r'\', '/'),
  origin: FileOrigin.local,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  MediaKit.ensureInitialized();

  late Directory dir;
  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('kfm_pause_test_');
  });
  tearDownAll(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  testWidgets('the desktop bar pauses and plays a real player', (
    tester,
  ) async {
    final file = File('${dir.path}/clip.avi')
      ..writeAsBytesSync(mjpegAvi(frames: 50));
    final f = _ref(file);
    final container = ProviderContainer(
      overrides: [
        videoHandleFactoryProvider.overrideWithValue(MediaKitHandle.new),
      ],
    );
    addTearDown(container.dispose);
    final pool = container.read(videoControllerPoolProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 640,
              height: 400,
              child: VideoSurface(file: f, active: true, desktopControls: true),
            ),
          ),
        ),
      ),
    );
    final handle = (await tester.runAsync(() => pool.obtain(f)))!;
    Future<void> settle([int ms = 600]) async {
      await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: ms)),
      );
      await tester.pump();
    }

    await settle(1200);
    expect(handle.state.value.isPlaying, isTrue, reason: 'plays when shown');

    await tester.tap(find.byKey(const ValueKey('desktop-video-play')));
    await settle();
    expect(handle.state.value.isPlaying, isFalse, reason: 'bar pauses');
    final at = handle.state.value.position;
    await settle(800);
    expect(handle.state.value.position, at, reason: 'stays paused');

    await tester.tap(find.byKey(const ValueKey('desktop-video-play')));
    await settle(800);
    expect(handle.state.value.isPlaying, isTrue, reason: 'bar plays again');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(pool.disposeAll);
  });

  testWidgets('Quick look: the bar pauses a real player', (tester) async {
    final file = File('${dir.path}/clip2.avi')
      ..writeAsBytesSync(mjpegAvi(frames: 50));
    final f = _ref(file);
    final container = ProviderContainer(
      overrides: [
        videoHandleFactoryProvider.overrideWithValue(MediaKitHandle.new),
      ],
    );
    addTearDown(container.dispose);
    final pool = container.read(videoControllerPoolProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showQuickLook(
                  context,
                  watchFiles: (ref) => [f],
                  startId: f.id,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    final handle = (await tester.runAsync(() => pool.obtain(f)))!;
    Future<void> settle([int ms = 600]) async {
      await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: ms)),
      );
      await tester.pump();
    }

    await settle(1200);
    expect(handle.state.value.isPlaying, isTrue, reason: 'plays when shown');
    await tester.tap(find.byKey(const ValueKey('desktop-video-play')));
    await settle();
    expect(handle.state.value.isPlaying, isFalse, reason: 'bar pauses');
    final at = handle.state.value.position;
    await settle(800);
    expect(handle.state.value.position, at, reason: 'stays paused');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(pool.disposeAll);
  });
}
