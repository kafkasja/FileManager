// Windows-only (TASK-PL1): window_manager + tray_manager in the real
// runner. Run with
//   flutter test integration_test/windows_desktop_shell_test.dart -d windows
@TestOn('windows')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kfm/core/platform/windows/desktop_shell.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('close is intercepted; tray shows, updates and goes', (
    tester,
  ) async {
    final shell = WindowsDesktopShell();
    await tester.runAsync(() async {
      await shell.init();
      expect(await windowManager.isPreventClose(), isTrue);
      await shell.showTray(
        tooltip: 'Waiting for devices',
        menu: const [
          TrayMenuEntry(trayStopSharingKey, 'Stop sharing'),
          TrayMenuEntry(trayOpenKey, 'Open KFM'),
          TrayMenuEntry(trayQuitKey, 'Quit'),
        ],
      );
      await shell.showTray(
        tooltip: 'Sharing with Phone',
        menu: const [TrayMenuEntry(trayStopSharingKey, 'Stop sharing')],
      );
      // ShowWindow/HideWindow may apply asynchronously.
      Future<bool> visibleBecomes({required bool want}) async {
        for (var i = 0; i < 20; i++) {
          if (await windowManager.isVisible() == want) return true;
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        return false;
      }

      await shell.hide();
      expect(await visibleBecomes(want: false), isTrue);
      await shell.showAndFocus();
      expect(await visibleBecomes(want: true), isTrue);
      await shell.removeTray();
      await shell.removeTray(); // twice is fine
      await windowManager.setPreventClose(false);
    });
  });
}
