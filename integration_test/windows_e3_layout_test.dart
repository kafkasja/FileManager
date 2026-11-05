// Windows-only (TASK-E3): the File Explorer layout in the real runner (real
// fonts, shell icons, drives), with screenshots for a person to compare
// with File Explorer. Run with
//   flutter test integration_test/windows_e3_layout_test.dart -d windows
// Screenshots go to KFM_E3_SHOTS (a folder) when it is set.
@TestOn('windows')
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/desktop/shell/desktop_location.dart';
import 'package:kfm/desktop/tabs/desktop_tabs_controller.dart';

import '../test/desktop/desktop_helpers.dart';

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['KFM_E3_SHOTS'];
  if (dir == null) return;
  await tester.runAsync(() async {
    final view = tester.binding.renderViews.first;
    final layer = view.debugLayer! as OffsetLayer;
    final image = await layer.toImage(
      Offset.zero & view.size,
      pixelRatio: tester.view.devicePixelRatio,
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E3 layout: Sort, Home, a folder with shell icons', (
    tester,
  ) async {
    final demo = Directory.systemTemp.createTempSync('kfm_e3_demo_');
    addTearDown(() => demo.deleteSync(recursive: true));
    for (final n in [
      'Report.pdf',
      'Notes.txt',
      'Archive.zip',
      'Budget.xlsx',
      'Letter.docx',
      'song.mp3',
    ]) {
      File('${demo.path}/$n').writeAsStringSync('kfm e3 $n');
    }
    Directory('${demo.path}/Holiday').createSync();
    Directory('${demo.path}/Work').createSync();
    final folder = demo.path.replaceAll(r'\', '/');

    final app = await pumpDesktopApp(tester, files: desktopLibrary(12));
    // The first-run icon question.
    await tester.pumpAndSettle();
    await _shot(tester, '0-first-run');
    if (find.byKey(const ValueKey('icon-choice-done')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('icon-choice-done')));
      await tester.pumpAndSettle();
    }
    await _shot(tester, '1-sort');

    final tabs = app.container.read(desktopTabsControllerProvider.notifier)
      ..openInNewTab(const HomeLocation());
    await tester.pumpAndSettle();
    await _shot(tester, '2-home');

    tabs.openInNewTab(FolderLocation(folder));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pumpAndSettle();
    await _shot(tester, '3-folder');
    expect(find.text('Report.pdf'), findsOneWidget);
    expect(
      await app.container
          .read(settingsRepositoryProvider)
          .read(AppSettings.desktopIconStyle),
      'windows',
    );
  });
}
