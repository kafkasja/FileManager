// Windows-only (desktop fixes): the real runner's Open (ShellExecuteEx) on
// a missing file, and a zero-filled video failing fast as damaged.
// Run with
//   flutter test integration_test/windows_desktop_fixes_test.dart -d windows
@TestOn('windows')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/media_damage.dart';
import 'package:kfm/core/platform/windows/media_kit_handle.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  late Directory dir;
  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('kfm_fixes_test_');
  });
  tearDownAll(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  // An unknown type is not tested: Windows answers it with its own app
  // picker (OpenWith.exe), like Explorer.
  testWidgets('Open: a missing file is notFound (no window opens)', (
    tester,
  ) async {
    final channel = WindowsChannel();
    final missing = await tester.runAsync(
      () => channel.openFile('${dir.path.replaceAll(r'\', '/')}/gone.txt'),
    );
    expect(missing, ShellOpenResult.notFound);
  });

  testWidgets('a zero-filled video fails at once as damaged', (tester) async {
    final file = File('${dir.path}/broken.mp4')
      ..writeAsBytesSync(Uint8List(300000));
    final ref = FileRef(
      id: 'path:${file.path.replaceAll(r'\', '/')}',
      uri: file.path.replaceAll(r'\', '/'),
      name: 'broken.mp4',
      kind: FileKind.video,
      sizeBytes: 300000,
      modifiedAt: DateTime.now(),
      folderPath: dir.path.replaceAll(r'\', '/'),
      origin: FileOrigin.local,
    );
    final handle = MediaKitHandle(ref);
    final watch = Stopwatch()..start();
    Object? error;
    await tester.runAsync(() async {
      try {
        await handle.initialize();
      } on Object catch (e) {
        error = e;
      }
      await handle.dispose();
    });
    expect(error, isA<DamagedFileException>());
    expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
  });
}
