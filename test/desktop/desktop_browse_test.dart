import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/desktop/browse/desktop_browse_controller.dart';
import 'package:kfm/desktop/browse/desktop_browse_screen.dart';
import 'package:kfm/desktop/widgets/explorer_view.dart';

import '../core/files/fake_file_source.dart';
import '../helpers/pump_app.dart';
import 'desktop_helpers.dart';

FakeFileSource _library() {
  final files = FakeFileSource();
  for (final (i, name) in ['b.jpg', 'a.jpg', 'c.jpg'].indexed) {
    files.addFile(
      '/s/DCIM/$name',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
      bytes: List.filled(10 + i * 10, 1),
    );
  }
  files
    ..addFile('/s/DCIM/Trip/t.jpg', modifiedAt: DateTime.utc(2025))
    ..addFile('/s/Other/o.jpg', modifiedAt: DateTime.utc(2025));
  return files;
}

Future<TestApp> _openBrowse(WidgetTester tester, {String? folder}) async {
  final app = await pumpDesktopApp(tester, files: _library());
  await tester.tap(find.byKey(const ValueKey('desktop-nav-browse')));
  await tester.pumpAndSettle();
  if (folder != null) {
    app.container.read(desktopBrowseControllerProvider.notifier).open(folder);
    await tester.pumpAndSettle();
  }
  return app;
}

/// Names in the order the Details list shows them.
List<String> _rows(WidgetTester tester) {
  final view = tester.widget<ExplorerView<BrowseEntry>>(
    find.byType(ExplorerView<BrowseEntry>),
  );
  return [for (final e in view.items) e.name];
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

Future<void> _withKey(
  WidgetTester tester,
  LogicalKeyboardKey modifier,
  Future<void> Function() body,
) async {
  await tester.sendKeyDownEvent(modifier);
  await body();
  await tester.sendKeyUpEvent(modifier);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Browse starts at Places; double-click opens a folder; the '
      'breadcrumb goes back up', (tester) async {
    await _openBrowse(tester);
    expect(find.byType(DesktopBrowseScreen), findsOneWidget);
    expect(_rows(tester), ['s']);
    await tester.tap(find.text('s').last);
    await tester.tap(find.text('s').last);
    await tester.pumpAndSettle();
    expect(_rows(tester), ['DCIM', 'Other']);
    await tester.tap(find.text('DCIM').last);
    await _key(tester, LogicalKeyboardKey.enter);
    // Folders first, then files by name.
    expect(_rows(tester), ['Trip', 'a.jpg', 'b.jpg', 'c.jpg']);
    await tester.tap(find.byKey(const ValueKey('crumb-/s')));
    await tester.pumpAndSettle();
    expect(_rows(tester), ['DCIM', 'Other']);
    await tester.tap(find.byKey(const ValueKey('browse-back')));
    await tester.pumpAndSettle();
    expect(_rows(tester), ['Trip', 'a.jpg', 'b.jpg', 'c.jpg']);
    await _key(tester, LogicalKeyboardKey.backspace);
    expect(_rows(tester), ['DCIM', 'Other']);
  });

  testWidgets('Details columns sort by name, size and date', (tester) async {
    await _openBrowse(tester, folder: '/s/DCIM');
    await tester.tap(find.byKey(const ValueKey('explorer-column-name')));
    await tester.pumpAndSettle();
    expect(_rows(tester), ['Trip', 'c.jpg', 'b.jpg', 'a.jpg']);
    await tester.tap(find.byKey(const ValueKey('explorer-column-size')));
    await tester.pumpAndSettle();
    // Largest first: c (30 B) > a (20 B) > b (10 B).
    expect(_rows(tester), ['Trip', 'c.jpg', 'a.jpg', 'b.jpg']);
    await tester.tap(find.byKey(const ValueKey('explorer-column-date')));
    await tester.pumpAndSettle();
    expect(_rows(tester), ['Trip', 'c.jpg', 'a.jpg', 'b.jpg']);
    await tester.tap(find.byKey(const ValueKey('explorer-column-date')));
    await tester.pumpAndSettle();
    expect(_rows(tester), ['Trip', 'b.jpg', 'a.jpg', 'c.jpg']);
  });

  testWidgets('keyboard: arrows, Shift+arrows, type-to-find, status bar', (
    tester,
  ) async {
    await _openBrowse(tester, folder: '/s/DCIM');
    await tester.tap(find.text('a.jpg'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected · 20 B'), findsOneWidget);
    await _withKey(
      tester,
      LogicalKeyboardKey.shiftLeft,
      () => tester.sendKeyEvent(LogicalKeyboardKey.arrowDown),
    );
    expect(find.text('2 selected · 30 B'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.keyC);
    expect(find.text('1 selected · 30 B'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.home);
    expect(find.text('1 selected · 0 B'), findsOneWidget);
    expect(find.text('4 items'), findsOneWidget);
  });

  testWidgets('Del trashes the selection (B4), the Undo button brings it '
      'back', (tester) async {
    final app = await _openBrowse(tester, folder: '/s/DCIM');
    await tester.tap(find.text('a.jpg'));
    await _withKey(
      tester,
      LogicalKeyboardKey.controlLeft,
      () => tester.tap(find.text('c.jpg')),
    );
    await _key(tester, LogicalKeyboardKey.delete);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(app.files.trash, hasLength(2));
    expect(_rows(tester), ['Trip', 'b.jpg']);
    await tester.tap(find.byKey(const ValueKey('cmd-undo')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(app.files.trash, isEmpty);
    expect(_rows(tester), ['Trip', 'a.jpg', 'b.jpg', 'c.jpg']);
  });

  testWidgets('right-click shows the file menu; F2 renames', (tester) async {
    await _openBrowse(tester, folder: '/s/DCIM');
    await tester.tap(find.text('b.jpg'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    // The menu entry and the command bar's Copy.
    expect(find.text('Copy'), findsNWidgets(2));
    expect(find.text('Delete permanently'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await _key(tester, LogicalKeyboardKey.f2);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'renamed.jpg');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(_rows(tester), contains('renamed.jpg'));
  });

  testWidgets('Ctrl+C in one folder, Ctrl+V in another copies', (tester) async {
    final app = await _openBrowse(tester, folder: '/s/DCIM');
    await tester.tap(find.text('a.jpg'));
    await tester.pumpAndSettle();
    await _withKey(
      tester,
      LogicalKeyboardKey.controlLeft,
      () => tester.sendKeyEvent(LogicalKeyboardKey.keyC),
    );
    app.container
        .read(desktopBrowseControllerProvider.notifier)
        .open('/s/Other');
    await tester.pumpAndSettle();
    await tester.tap(find.text('o.jpg'));
    await tester.pumpAndSettle();
    await _withKey(
      tester,
      LogicalKeyboardKey.controlLeft,
      () => tester.sendKeyEvent(LogicalKeyboardKey.keyV),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      app.files.files.where((f) => f.name == 'a.jpg').map((f) => f.folderPath),
      unorderedEquals(['/s/DCIM', '/s/Other']),
    );
    expect(_rows(tester), ['a.jpg', 'o.jpg']);
  });
}
