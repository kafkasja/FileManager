import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/features/folders/ui/folder_picker_sheet.dart';

import '../../../core/files/fake_file_source.dart';
import '../../../core/platform/permissions/fake_permission_service.dart';
import '../../../helpers/pump_app.dart';

const _root = '/storage/emulated/0';

FakeFileSource _library() => FakeFileSource()
  ..addFile('$_root/DCIM/Camera/c1.jpg')
  ..addFile('$_root/DCIM/Camera/c2.jpg')
  ..addFile('$_root/DCIM/Holiday/h1.jpg')
  ..addFile('$_root/Download/manual.pdf');

/// U3: every new folder is refused (the place is being ejected).
class _EjectingFiles extends FakeFileSource {
  @override
  Future<String> createFolder(String parentPath, String name) async =>
      throw FileOpException(FileOpFailure.volumeEjecting, parentPath);
}

/// Opens the picker from inside the app and collects what it returns.
Future<List<String?>> _open(
  WidgetTester tester, {
  String? disabledFolder,
  String? title,
  FolderPickerMode mode = FolderPickerMode.choose,
}) async {
  final picked = <String?>[];
  final context = tester.element(find.byType(Scaffold).first);
  showFolderPicker(
    context,
    disabledFolder: disabledFolder,
    title: title,
    mode: mode,
  ).then(picked.add).ignore();
  await tester.pumpAndSettle();
  return picked;
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final f = find.text(text).last;
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('default: P2 title, folders with photos pick directly', (
    tester,
  ) async {
    await pumpApp(tester, files: _library());
    final picked = await _open(tester);
    expect(find.text('Choose a folder'), findsOneWidget);
    expect(find.text('All folders'), findsOneWidget);
    expect(find.text('Folders with photos'), findsOneWidget);
    await _tapText(tester, 'Holiday');
    expect(picked, ['$_root/DCIM/Holiday']);
    expect(find.text('Choose a folder'), findsNothing);
  });

  testWidgets('All folders navigates with a breadcrumb; Move here picks the '
      'folder shown; back goes up first', (tester) async {
    final app = await pumpApp(tester, files: _library());
    final picked = await _open(tester, mode: FolderPickerMode.move);
    expect(find.text('Move to'), findsOneWidget);

    await _tapText(tester, 'Internal storage');
    expect(find.text('DCIM'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    await _tapText(tester, 'DCIM');
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Holiday'), findsOneWidget);
    // Breadcrumb: All folders › Internal storage › DCIM.
    expect(find.widgetWithText(TextButton, 'Internal storage'), findsOneWidget);

    // System back goes up a level instead of closing.
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('DCIM'), findsOneWidget);
    expect(find.text('Camera'), findsNothing);

    await _tapText(tester, 'DCIM');
    await _tapText(tester, 'Camera');
    await _tapText(tester, 'Move here');
    expect(picked, ['$_root/DCIM/Camera']);

    final recent = await app.container
        .read(settingsRepositoryProvider)
        .read(AppSettings.swipeRecentTargets);
    expect(recent, contains('DCIM/Camera'));
  });

  testWidgets('the disabled folder is greyed out everywhere and its Copy '
      'here button is off', (tester) async {
    await pumpApp(tester, files: _library());
    final picked = await _open(
      tester,
      disabledFolder: '$_root/DCIM/Camera',
      title: 'Custom title',
      mode: FolderPickerMode.copy,
    );
    expect(find.text('Custom title'), findsOneWidget);
    final tile = tester.widget<ListTile>(
      find.ancestor(of: find.text('Camera'), matching: find.byType(ListTile)),
    );
    expect(tile.enabled, isFalse);
    expect(find.text('Current folder'), findsOneWidget);

    await _tapText(tester, 'Internal storage');
    await _tapText(tester, 'DCIM');
    await _tapText(tester, 'Camera');
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Copy here'),
    );
    expect(button.onPressed, isNull);
    expect(picked, isEmpty);
  });

  testWidgets('New folder creates inside the folder being shown', (
    tester,
  ) async {
    final app = await pumpApp(tester, files: _library());
    final picked = await _open(tester, mode: FolderPickerMode.move);
    await _tapText(tester, 'Internal storage');
    await _tapText(tester, 'DCIM');
    await _tapText(tester, 'New folder…');
    expect(find.text('Inside $_root/DCIM'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Trip');
    await _tapText(tester, 'Create');
    expect(app.files.calls, contains('createFolder $_root/DCIM Trip'));
    expect(picked, ['$_root/DCIM/Trip']);
  });

  testWidgets('New folder with an existing name in another case picks the '
      'existing folder with its real spelling', (tester) async {
    final app = await pumpApp(tester, files: _library());
    final picked = await _open(tester, mode: FolderPickerMode.move);
    await _tapText(tester, 'Internal storage');
    await _tapText(tester, 'DCIM');
    await _tapText(tester, 'New folder…');
    await tester.enterText(find.byType(TextField), 'camera');
    await _tapText(tester, 'Create');
    expect(app.files.calls, contains('createFolder $_root/DCIM camera'));
    expect(picked, ['$_root/DCIM/Camera']);
  });

  testWidgets('New folder named like a file asks again with an error', (
    tester,
  ) async {
    await pumpApp(tester, files: _library());
    final picked = await _open(tester, mode: FolderPickerMode.move);
    await _tapText(tester, 'Internal storage');
    await _tapText(tester, 'Download');
    await _tapText(tester, 'New folder…');
    await tester.enterText(find.byType(TextField), 'manual.pdf');
    await _tapText(tester, 'Create');
    expect(picked, isEmpty);
    expect(
      find.text('Something with that name already exists here'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'Manuals');
    await _tapText(tester, 'Create');
    expect(picked, ['$_root/Download/Manuals']);
  });

  testWidgets('New folder refused while ejecting says why and picks '
      'nothing', (tester) async {
    final files = _EjectingFiles()..addFile('$_root/DCIM/Camera/c1.jpg');
    await pumpApp(tester, files: files);
    final picked = await _open(tester, mode: FolderPickerMode.copy);
    await _tapText(tester, 'Internal storage');
    await _tapText(tester, 'DCIM');
    await _tapText(tester, 'New folder…');
    await tester.enterText(find.byType(TextField), 'Trip');
    await _tapText(tester, 'Create');
    expect(find.text('This storage is being ejected'), findsOneWidget);
    await _tapText(tester, 'OK');
    expect(find.text('This storage is being ejected'), findsNothing);
    expect(picked, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('without All files access: media folders pick without the '
      'access prompt', (tester) async {
    final denied = grantedAccess.copyWith(allFiles: AllFilesAccess.notGranted);
    await pumpApp(
      tester,
      files: _library(),
      permissions: FakePermissionService(denied),
    );
    final picked = await _open(tester, mode: FolderPickerMode.move);
    await _tapText(tester, 'Internal storage');
    // Only media is indexed without access, so Download isn't listed.
    expect(find.text('Download'), findsNothing);
    await _tapText(tester, 'DCIM');
    await _tapText(tester, 'Move here');
    expect(picked, ['$_root/DCIM']);
  });
}
