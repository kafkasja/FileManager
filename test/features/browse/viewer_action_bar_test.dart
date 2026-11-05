import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/layout/text_scale.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/desktop/browse/desktop_browse_controller.dart';
import 'package:kfm/features/swipe/ui/file_viewer.dart';

import '../../core/files/fake_file_source.dart';
import '../../desktop/desktop_helpers.dart';
import '../../helpers/pump_app.dart';

const _camera = '/storage/emulated/0/DCIM/Camera';

/// p0 … p{n-1}; newest first in Browse, so p{n-1} is the first tile.
FakeFileSource _photos(int n) {
  final files = FakeFileSource();
  for (var i = 0; i < n; i++) {
    files.addFile(
      '$_camera/p$i.jpg',
      modifiedAt: DateTime.utc(2025).add(Duration(minutes: i)),
    );
  }
  return files;
}

Finder _tile(String name) =>
    find.bySemanticsLabel(RegExp('^${RegExp.escape(name)}, '));

Future<void> _openViewer(WidgetTester tester, String name) async {
  await tester.tap(find.text('Browse'));
  await tester.pumpAndSettle();
  await tester.tap(_tile(name));
  await tester.pumpAndSettle();
  expect(find.byType(PagedFileViewer), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// The info bar shows "name · size · date".
Finder _shown(String name) => find.textContaining('$name  ·');

void _phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1080, 1920)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('phone viewer: the action bar offers Share, Move to, Delete '
      'and More; Delete shows the next file, then closes after the last', (
    tester,
  ) async {
    _phone(tester);
    final app = await pumpApp(tester, files: _photos(3));
    await _openViewer(tester, 'p2.jpg');
    expect(_shown('p2.jpg'), findsOneWidget);
    for (final k in ['x2.share', 'b4.moveTo', 'b4.delete']) {
      expect(find.byKey(ValueKey('viewer-$k')), findsOneWidget, reason: k);
    }
    // Not linked: no Send to <device>.
    expect(find.byKey(const ValueKey('viewer-e1.sendLinked')), findsNothing);
    // Select stays where it was.
    expect(find.widgetWithText(FilledButton, 'Select'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('viewer-more')));
    for (final label in [
      'Open with',
      'Rename',
      'Copy to…',
      'Duplicate',
      'Details',
    ]) {
      expect(find.widgetWithText(ListTile, label), findsOneWidget);
    }
    // Delete and Move are on the bar, not repeated under More.
    expect(find.widgetWithText(ListTile, 'Delete'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const ValueKey('viewer-b4.delete')));
    expect(app.files.trash, hasLength(1));
    expect(find.byType(PagedFileViewer), findsOneWidget);
    expect(_shown('p1.jpg'), findsOneWidget);
    // The B4 snackbar with Undo still shows.
    expect(find.text('Moved 1 file to trash'), findsWidgets);

    await _tap(tester, find.byKey(const ValueKey('viewer-b4.delete')));
    expect(_shown('p0.jpg'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('viewer-b4.delete')));
    expect(app.files.trash, hasLength(3));
    expect(find.byType(PagedFileViewer), findsNothing);
  });

  testWidgets('360 dp at text size 2.0: the bar fits; left-handed puts More '
      'at the left', (tester) async {
    _phone(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 1.25;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final app = await pumpApp(tester, files: _photos(2));
    final settings = app.container.read(settingsRepositoryProvider);
    await settings.write(AppSettings.textSize, AppTextSize.extraLarge);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await _openViewer(tester, 'p1.jpg');
    expect(tester.takeException(), isNull);
    final more = find.byKey(const ValueKey('viewer-more'));
    final delete = find.byKey(const ValueKey('viewer-b4.delete'));
    expect(tester.getSize(more).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(more).width, greaterThanOrEqualTo(48));
    expect(tester.getCenter(more).dx, greaterThan(tester.getCenter(delete).dx));

    await settings.write(AppSettings.leftHanded, true);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getCenter(more).dx, lessThan(tester.getCenter(delete).dx));
  });

  testWidgets('desktop Browse Quick look: Open, Open file location, Copy as '
      'path, Delete and Properties with keys; Del shows the next file', (
    tester,
  ) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(2));
    await tester.tap(find.byKey(const ValueKey('desktop-nav-browse')));
    await tester.pumpAndSettle();
    app.container
        .read(desktopBrowseControllerProvider.notifier)
        .open('/s/DCIM');
    await tester.pumpAndSettle();
    await tester.tap(find.text('p0.jpg'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quick-look-close')), findsOneWidget);
    for (final (k, text) in [
      ('open', 'Open (Enter)'),
      ('location', 'Open file location'),
      ('copy-path', 'Copy as path (Ctrl+Shift+C)'),
      ('delete', 'Delete (Del)'),
      ('properties', 'Properties (Alt+Enter)'),
    ]) {
      final button = find.byKey(ValueKey('quick-look-$k'));
      expect(button, findsOneWidget, reason: k);
      expect(
        find.descendant(of: button, matching: find.text(text)),
        findsOneWidget,
        reason: k,
      );
    }
    // Not linked: no Send to <device>.
    expect(find.byKey(const ValueKey('quick-look-send')), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(app.files.trash, hasLength(1));
    // Still open, on the other photo.
    expect(find.byKey(const ValueKey('quick-look-close')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('quick-look-delete')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(app.files.trash, hasLength(2));
    expect(find.byKey(const ValueKey('quick-look-close')), findsNothing);
  });
}
