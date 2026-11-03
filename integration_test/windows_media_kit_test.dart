// Windows-only (TASK-PL1): S5's video handle on media_kit (libmpv) in the
// real runner. Run with
//   flutter test integration_test/windows_media_kit_test.dart -d windows
// Plays a small generated MJPEG AVI from a fresh temp folder.
@TestOn('windows')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/platform/windows/media_kit_handle.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';
import 'package:media_kit/media_kit.dart';

/// A [frames]-frame MJPEG AVI, [w]x[h] at [fps] (no audio).
Uint8List mjpegAvi({int w = 160, int h = 120, int fps = 10, int frames = 20}) {
  final jpgs = [
    for (var i = 0; i < frames; i++)
      img.encodeJpg(
        img.Image(width: w, height: h)
          ..clear(img.ColorRgb8((i * 12) % 256, 80, 255 - (i * 12) % 256)),
        quality: 80,
      ),
  ];
  final out = BytesBuilder();
  void fourcc(String s) => out.add(s.codeUnits);
  void u32(int v) => out.add(
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List(),
  );
  void u16(int v) => out.add(
    (ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List(),
  );

  final maxFrame = jpgs.map((j) => j.length).reduce((a, b) => a > b ? a : b);
  var moviSize = 4;
  for (final j in jpgs) {
    moviSize += 8 + j.length + (j.length.isOdd ? 1 : 0);
  }
  const strhSize = 56;
  const strfSize = 40;
  const strlSize = 4 + 8 + strhSize + 8 + strfSize;
  const hdrlSize = 4 + 8 + 56 + 8 + strlSize;
  final idxSize = 16 * frames;
  final riffSize = 4 + 8 + hdrlSize + 8 + moviSize + 8 + idxSize;

  fourcc('RIFF');
  u32(riffSize);
  fourcc('AVI ');
  fourcc('LIST');
  u32(hdrlSize);
  fourcc('hdrl');
  fourcc('avih');
  u32(56);
  u32(1000000 ~/ fps);
  u32(maxFrame * fps);
  u32(0);
  u32(0x10); // AVIF_HASINDEX
  u32(frames);
  u32(0);
  u32(1);
  u32(maxFrame);
  u32(w);
  u32(h);
  for (var i = 0; i < 4; i++) {
    u32(0);
  }
  fourcc('LIST');
  u32(strlSize);
  fourcc('strl');
  fourcc('strh');
  u32(strhSize);
  fourcc('vids');
  fourcc('MJPG');
  u32(0);
  u16(0);
  u16(0);
  u32(0);
  u32(1); // scale
  u32(fps); // rate
  u32(0);
  u32(frames);
  u32(maxFrame);
  u32(0xFFFFFFFF);
  u32(0);
  u16(0);
  u16(0);
  u16(w);
  u16(h);
  fourcc('strf');
  u32(strfSize);
  u32(40);
  u32(w);
  u32(h);
  u16(1);
  u16(24);
  fourcc('MJPG');
  u32(w * h * 3);
  for (var i = 0; i < 4; i++) {
    u32(0);
  }
  fourcc('LIST');
  u32(moviSize);
  fourcc('movi');
  final offsets = <int>[];
  var offset = 4;
  for (final j in jpgs) {
    offsets.add(offset);
    fourcc('00dc');
    u32(j.length);
    out.add(j);
    if (j.length.isOdd) out.addByte(0);
    offset += 8 + j.length + (j.length.isOdd ? 1 : 0);
  }
  fourcc('idx1');
  u32(idxSize);
  for (var i = 0; i < frames; i++) {
    fourcc('00dc');
    u32(0x10); // AVIIF_KEYFRAME
    u32(offsets[i]);
    u32(jpgs[i].length);
  }
  return out.toBytes();
}

FileRef _ref(File f, FileKind kind) => FileRef(
  id: 'path:${f.path.replaceAll(r'\', '/')}',
  uri: f.uri.toString(),
  name: f.uri.pathSegments.last,
  kind: kind,
  sizeBytes: f.lengthSync(),
  modifiedAt: DateTime.now(),
  folderPath: f.parent.path.replaceAll(r'\', '/'),
  origin: FileOrigin.local,
);

void main() {
  // Real frames: media_kit's VideoController waits for one.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  MediaKit.ensureInitialized();

  late Directory dir;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('kfm_video_test_');
  });
  tearDownAll(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  testWidgets('a generated AVI plays through the pool', (tester) async {
    final file = File('${dir.path}/clip.avi')..writeAsBytesSync(mjpegAvi());
    final pool = VideoControllerPool(factory: MediaKitHandle.new);
    final handle = await tester.runAsync(
      () => pool.obtain(_ref(file, FileKind.video)),
    );
    expect(handle, isNotNull);
    final value = handle!.state.value;
    expect(value.isInitialized, isTrue);
    expect(value.isLooping, isTrue);
    expect(value.volume, 0);
    expect(value.duration.inMilliseconds, inInclusiveRange(1800, 2200));
    expect(value.size, const Size(160, 120));

    await tester.pumpWidget(MaterialApp(home: Center(child: handle.view())));
    await tester.runAsync(() async {
      await handle.play();
      await Future<void>.delayed(const Duration(milliseconds: 800));
    });
    await tester.pump();
    expect(handle.state.value.isPlaying, isTrue);
    expect(handle.state.value.position, greaterThan(Duration.zero));

    await tester.runAsync(() async {
      await handle.seekTo(const Duration(milliseconds: 500));
      await handle.pause();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    expect(handle.state.value.isPlaying, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(pool.disposeAll);
    expect(pool.aliveCount, 0);
  });

  testWidgets('a file that is no video fails initialize', (tester) async {
    final file = File('${dir.path}/fake.mp4')
      ..writeAsBytesSync(List<int>.generate(4096, (i) => i % 7));
    final pool = VideoControllerPool(
      factory: (f) =>
          MediaKitHandle(f, openTimeout: const Duration(seconds: 5)),
    );
    Object? error;
    await tester.runAsync(() async {
      try {
        await pool.obtain(_ref(file, FileKind.video));
      } on Object catch (e) {
        error = e;
      }
    });
    expect(error, isNotNull);
    expect(pool.aliveCount, 0);
  });
}
