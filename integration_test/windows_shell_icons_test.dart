// Windows-only (TASK-E3): shell icons, type names and reveal in the real
// runner. Run with
//   flutter test integration_test/windows_shell_icons_test.dart -d windows
// Set KFM_E3_WINDOWS=1 to also open Explorer (reveal) and a Properties
// sheet (both leave a window open for a person to look at).
@TestOn('windows')
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';

typedef _GuiNative = Uint32 Function(IntPtr process, Uint32 flags);
typedef _GuiDart = int Function(int process, int flags);

bool _isPng(Uint8List? b) =>
    b != null &&
    b.length > 8 &&
    b[0] == 0x89 &&
    b[1] == 0x50 &&
    b[2] == 0x4E &&
    b[3] == 0x47;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('icons: PNG for .txt, a folder and the system drive', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final channel = WindowsChannel();
      final system = Platform.environment['SystemDrive'] ?? 'C:';
      final watch = Stopwatch()..start();
      expect(_isPng(await channel.fileIcon(ext: '.txt', px: 16)), isTrue);
      final extMs = watch.elapsedMicroseconds / 1000;
      expect(_isPng(await channel.fileIcon(folder: true, px: 32)), isTrue);
      expect(
        _isPng(await channel.fileIcon(path: system, drive: true, px: 48)),
        isTrue,
      );
      expect(_isPng(await channel.fileIcon(ext: '.pdf', px: 256)), isTrue);
      // Measurements go to the run log for the impl notes.
      // ignore: avoid_print
      print('E3 first ext icon: ${extMs.toStringAsFixed(1)} ms');

      final names = await channel.fileTypeNames(['.jpg', '.txt', 'folder']);
      expect(names['.jpg'], isNotEmpty);
      expect(names['folder'], isNotEmpty);
      // Measurements go to the run log for the impl notes.
      // ignore: avoid_print
      print('E3 type names: $names');
    });
  });

  testWidgets('icons: 2000 calls leave the GDI/USER handle count flat', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final channel = WindowsChannel();
      final user32 = DynamicLibrary.open('user32.dll');
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final gui = user32.lookupFunction<_GuiNative, _GuiDart>(
        'GetGuiResources',
      );
      final current = kernel32
          .lookupFunction<IntPtr Function(), int Function()>(
            'GetCurrentProcess',
          );
      // 0 = GR_GDIOBJECTS, 1 = GR_USEROBJECTS (icons are USER objects).
      int count() => gui(current(), 0) + gui(current(), 1);
      for (var i = 0; i < 20; i++) {
        await channel.fileIcon(ext: '.e3w$i', px: 32);
      }
      final before = count();
      final watch = Stopwatch()..start();
      for (var i = 0; i < 2000; i++) {
        await channel.fileIcon(ext: i.isEven ? '.txt' : '.zip', px: 32);
      }
      final after = count();
      // Measurements go to the run log for the impl notes.
      // ignore: avoid_print
      print(
        'E3 2000 icons: ${watch.elapsedMilliseconds} ms, handles '
        '$before -> $after',
      );
      expect(after - before, lessThan(50));
    });
  });

  testWidgets('reveal: a missing path fails, a real one returns', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final channel = WindowsChannel();
      await expectLater(
        channel.revealInExplorer('C:/kfm-e3-does-not-exist/x.txt'),
        throwsA(isA<WindowsChannelException>()),
      );
      if (Platform.environment['KFM_E3_WINDOWS'] != '1') return;
      final dir = await Directory.systemTemp.createTemp('kfm_e3_');
      final file = File('${dir.path}/cat.txt')..writeAsStringSync('meow');
      final path = file.path.replaceAll(r'\', '/');
      await channel.revealInExplorer(path);
      expect(await channel.showProperties(path), isTrue);
    });
  });
}
