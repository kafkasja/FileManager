import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/features/browse/ui/widgets/file_tile.dart';
import 'package:kfm/features/folders/ui/last_operation_undo.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';

import '../../../core/files/fake_file_source.dart';
import '../../../helpers/pump_app.dart';

const _root = '/storage/emulated/0';

FakeFileSource _library() {
  final files = FakeFileSource();
  final t = DateTime.utc(2025);
  var i = 0;
  void add(String path) =>
      files.addFile('$_root/$path', modifiedAt: t.add(Duration(minutes: i++)));
  add('DCIM/Camera/c1.jpg');
  add('DCIM/Camera/c2.jpg');
  add('DCIM/Holiday/h1.jpg');
  add('DCIM/d1.jpg');
  return files;
}

Future<void> _openBrowse(WidgetTester tester) async {
  await tester.tap(find.text('Browse'));
  await tester.pumpAndSettle();
}

Finder _menuOf(String name) => find.descendant(
  of: find.byWidgetPredicate((w) => w is FileGridTile && w.file.name == name),
  matching: find.byTooltip('File actions'),
);

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) =>
    _tap(tester, find.text(text).last);

Future<void> _menu(WidgetTester tester, String file, String item) async {
  await _tap(tester, _menuOf(file));
  await _tapText(tester, item);
}

/// In the open picker: All folders → Internal storage → DCIM → Holiday →
/// "[button]".
Future<void> _pickHoliday(WidgetTester tester, String button) async {
  await _tapText(tester, 'Internal storage');
  await _tapText(tester, 'DCIM');
  await _tapText(tester, 'Holiday');
  await _tapText(tester, button);
}

/// Lets the paging debounce and the snackbar timers run out.
Future<void> _finish(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpAndSettle();
}

String? _pathOf(FakeFileSource files, String name) =>
    files.files.where((f) => f.name == name).firstOrNull?.path;

void hideSnackBars(WidgetTester tester) => tester
    .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
    .removeCurrentSnackBar();

void main() {
  testWidgets('⋮ Move to → picker → moved, summary, Undo moves it back', (
    tester,
  ) async {
    final app = await pumpApp(tester, files: _library());
    await _openBrowse(tester);
    await _menu(tester, 'c1.jpg', 'Move to…');
    expect(find.text('Move to'), findsOneWidget);
    await _pickHoliday(tester, 'Move here');
    expect(_pathOf(app.files, 'c1.jpg'), '$_root/DCIM/Holiday/c1.jpg');
    expect(find.text('Moved 1 file to Holiday'), findsOneWidget);
    expect(app.container.read(lastOperationUndoProvider), isNotNull);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(_pathOf(app.files, 'c1.jpg'), '$_root/DCIM/Camera/c1.jpg');
    expect(find.text('Undone'), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('⋮ Duplicate, Rename (invalid name rejected) and Delete to '
      'trash with Undo', (tester) async {
    final app = await pumpApp(tester, files: _library());
    await _openBrowse(tester);

    await _menu(tester, 'd1.jpg', 'Duplicate');
    expect(_pathOf(app.files, 'd1 (1).jpg'), '$_root/DCIM/d1 (1).jpg');
    expect(find.text('Duplicated 1 file'), findsOneWidget);
    hideSnackBars(tester);

    await _menu(tester, 'c2.jpg', 'Rename');
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'bad:name.jpg');
    await _tapText(tester, 'Rename');
    expect(find.textContaining("Names can't be empty"), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'renamed.jpg');
    await _tap(tester, find.widgetWithText(FilledButton, 'Rename'));
    expect(_pathOf(app.files, 'renamed.jpg'), '$_root/DCIM/Camera/renamed.jpg');
    expect(find.text('Renamed to renamed.jpg'), findsOneWidget);
    hideSnackBars(tester);

    await _menu(tester, 'h1.jpg', 'Delete');
    expect(_pathOf(app.files, 'h1.jpg'), isNull);
    expect(app.files.trash, hasLength(1));
    expect(find.text('Moved 1 file to trash'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(_pathOf(app.files, 'h1.jpg'), '$_root/DCIM/Holiday/h1.jpg');
    await _finish(tester);
  });

  testWidgets('permanent delete mode asks every time with count and size', (
    tester,
  ) async {
    final app = await pumpApp(tester, files: _library());
    await app.container
        .read(settingsRepositoryProvider)
        .write(AppSettings.deleteMode, 'permanent');
    await _openBrowse(tester);

    await _menu(tester, 'd1.jpg', 'Delete');
    expect(find.text('Delete permanently?'), findsOneWidget);
    expect(find.textContaining('Permanently delete 1 file ('), findsOneWidget);
    await _tapText(tester, 'Cancel');
    expect(_pathOf(app.files, 'd1.jpg'), isNotNull);

    await _menu(tester, 'd1.jpg', 'Delete');
    await _tap(tester, find.widgetWithText(FilledButton, 'Delete'));
    expect(_pathOf(app.files, 'd1.jpg'), isNull);
    expect(app.files.trash, isEmpty);
    expect(find.text('Deleted 1 file permanently'), findsOneWidget);
    // Nothing to undo.
    expect(find.text('Undo'), findsNothing);
    await _finish(tester);
  });

  testWidgets('trash folder unusable → "Delete permanently instead?"', (
    tester,
  ) async {
    final files = _library()..addFile('$_root/Download/manual.pdf');
    final app = await pumpApp(tester, files: files);
    files.folderUnavailable.add('path:$_root/Download/manual.pdf');
    await _openBrowse(tester);
    await _tapText(tester, 'Documents');
    await _tap(tester, find.byTooltip('File actions'));
    await _tapText(tester, 'Delete');
    expect(find.text("Couldn't use the trash folder"), findsOneWidget);
    await _tap(tester, find.widgetWithText(FilledButton, 'Delete permanently'));
    expect(_pathOf(app.files, 'manual.pdf'), isNull);
    expect(app.files.trash, isEmpty);
    await _finish(tester);
  });

  testWidgets('selection bar Move to / Copy to act on every selected file '
      'and keep the selection', (tester) async {
    final app = await pumpApp(tester, files: _library());
    await _openBrowse(tester);
    await tester.longPress(find.bySemanticsLabel('c1.jpg'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('c2.jpg'));
    await tester.pumpAndSettle();
    hideSnackBars(tester);

    // Copy to is under More; Move to is a bar button.
    await _tap(tester, find.byTooltip('More'));
    await _tapText(tester, 'Copy to…');
    await _pickHoliday(tester, 'Copy here');
    expect(_pathOf(app.files, 'c1.jpg'), '$_root/DCIM/Camera/c1.jpg');
    expect(
      app.files.files.where((f) => f.folderPath == '$_root/DCIM/Holiday'),
      hasLength(3),
    );
    expect(find.text('Copied 2 files to Holiday'), findsOneWidget);
    hideSnackBars(tester);

    // The copies collide: Keep both, for all remaining.
    await _tap(tester, find.byTooltip('Move to…'));
    await _pickHoliday(tester, 'Move here');
    expect(find.text('Name already used'), findsOneWidget);
    await _tapText(tester, 'Do this for all remaining');
    await _tapText(tester, 'Keep both');
    expect(find.text('Name already used'), findsNothing);
    expect(
      app.files.files.where((f) => f.folderPath == '$_root/DCIM/Camera'),
      isEmpty,
    );
    expect(_pathOf(app.files, 'c1 (1).jpg'), '$_root/DCIM/Holiday/c1 (1).jpg');
    expect(find.text('Moved 2 files to Holiday'), findsOneWidget);
    // B6: the selection stays (ids re-keyed by the move).
    final selected = app.container.read(selectionControllerProvider).value!;
    expect(selected.count, 2);
    await _finish(tester);
  });

  testWidgets('folder ⋮ Rename renames it; Undo renames it back', (
    tester,
  ) async {
    final app = await pumpApp(tester, files: _library());
    await _openBrowse(tester);
    await _tapText(tester, 'Folders');
    await _tapText(tester, 'Internal storage');
    await _tapText(tester, 'DCIM');
    final holiday = find.ancestor(
      of: find.text('Holiday'),
      matching: find.byType(ListTile),
    );
    await _tap(
      tester,
      find.descendant(of: holiday, matching: find.byTooltip('Folder options')),
    );
    await _tapText(tester, 'Rename');
    expect(find.text('Rename folder'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Trip');
    await _tap(tester, find.widgetWithText(FilledButton, 'Rename'));
    expect(_pathOf(app.files, 'h1.jpg'), '$_root/DCIM/Trip/h1.jpg');
    expect(find.text('Folder renamed to Trip'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(_pathOf(app.files, 'h1.jpg'), '$_root/DCIM/Holiday/h1.jpg');
    await _finish(tester);
  });

  testWidgets('overflow New folder creates it in the open folder', (
    tester,
  ) async {
    final app = await pumpApp(tester, files: _library());
    await _openBrowse(tester);
    await _tapText(tester, 'Folders');
    await _tapText(tester, 'Internal storage');
    await _tapText(tester, 'DCIM');
    await _tap(tester, find.byTooltip('Show menu'));
    await _tapText(tester, 'New folder');
    await tester.enterText(find.byType(TextField), 'Fresh');
    await _tap(tester, find.widgetWithText(FilledButton, 'Create'));
    expect(find.text('Created Fresh'), findsOneWidget);
    await expectLater(
      app.files.createFolder('$_root/DCIM', 'Fresh'),
      throwsA(isA<FileOpException>()),
    );
    await _finish(tester);
  });

  testWidgets('Settings → Files: drop action', (tester) async {
    final app = await pumpApp(tester);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    final drop = find.text('Dropping files on a folder');
    await tester.scrollUntilVisible(drop, 200);
    await tester.pumpAndSettle();
    expect(find.text('Moves them'), findsOneWidget);
    await _tapText(tester, 'Moves them');
    await _tapText(tester, 'Copies them');
    expect(
      await app.container
          .read(settingsRepositoryProvider)
          .read(AppSettings.foldersDropAction),
      DropAction.copy,
    );
    await _finish(tester);
  });

  testWidgets('drag a selection onto a folder row moves it; long-press on '
      'an unselected tile still selects (B6)', (tester) async {
    final app = await pumpApp(tester, files: _library());
    await _openBrowse(tester);
    await _tapText(tester, 'Folders');
    await _tapText(tester, 'Internal storage');
    await _tapText(tester, 'DCIM');
    // DCIM shows the Camera / Holiday rows and d1.jpg.
    await tester.longPress(find.bySemanticsLabel('d1.jpg'));
    await tester.pumpAndSettle();
    expect(app.container.read(selectionControllerProvider).value!.count, 1);
    hideSnackBars(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel('d1.jpg')),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveTo(tester.getCenter(find.text('Holiday')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_pathOf(app.files, 'd1.jpg'), '$_root/DCIM/Holiday/d1.jpg');
    expect(find.text('Moved 1 file to Holiday'), findsOneWidget);
    expect(app.container.read(selectionControllerProvider).value!.count, 1);
    await _finish(tester);
  });
}
