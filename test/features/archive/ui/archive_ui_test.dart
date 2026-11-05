import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/cancel_token.dart';
import 'package:kfm/features/archive/data/archive_service.dart';
import 'package:kfm/features/archive/domain/archive_job.dart';
import 'package:kfm/features/archive/ui/archive_flow.dart';
import 'package:kfm/features/archive/ui/compress_dialog.dart';
import 'package:kfm/features/folders/data/file_operation_runner.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';
import 'package:kfm/features/folders/ui/last_operation_undo.dart';

import '../../../core/files/fake_file_source.dart';
import '../../../helpers/pump_app.dart';
import 'fake_archive_service.dart';

const _root = '/storage/emulated/0';

/// Records undo calls instead of touching files.
class _FakeUndo extends LastOperationUndo {
  int undos = 0;

  @override
  LastOperation? build() => null;

  void arm() => state = const FolderRenameDone('/a', '/b');

  @override
  Future<UndoOutcome?> undo({
    CancelToken? cancel,
    void Function(OperationProgress)? onProgress,
  }) async {
    if (state == null) return null;
    state = null;
    undos++;
    return const UndoOutcome(undone: 1);
  }
}

FakeFileSource _library() {
  final files = FakeFileSource();
  final t = DateTime.utc(2025);
  var i = 0;
  void add(String path) =>
      files.addFile('$_root/$path', modifiedAt: t.add(Duration(minutes: i++)));
  add('DCIM/Camera/c1.jpg');
  add('DCIM/Camera/c2.jpg');
  add('Download/photos.zip');
  add('Download/backup.7z');
  add('Download/manual.pdf');
  return files;
}

class _Setup {
  new _(this.app, this.archive, this.undo);
  final TestApp app;
  final FakeArchiveService archive;
  final _FakeUndo undo;
}

Future<_Setup> _pump(WidgetTester tester, {FakeFileSource? files}) async {
  final source = files ?? _library();
  final archive = FakeArchiveService(source);
  final undo = _FakeUndo();
  final app = await pumpApp(
    tester,
    files: source,
    overrides: [
      archiveServiceProvider.overrideWithValue(archive),
      lastOperationUndoProvider.overrideWith(() => undo),
    ],
  );
  archive.onSuccess = undo.arm;
  return _Setup._(app, archive, undo);
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) =>
    _tap(tester, find.text(text).last);

Future<void> _openArchives(WidgetTester tester) async {
  await tester.tap(find.text('Browse'));
  await tester.pumpAndSettle();
  await _tapText(tester, 'Archives');
}

Finder _menuOf(String name) => find.descendant(
  of: find.ancestor(of: find.text(name), matching: find.byType(ListTile)),
  matching: find.byTooltip('File actions'),
);

Future<void> _zipMenu(WidgetTester tester, String item) async {
  await _tap(tester, _menuOf('photos.zip').first);
  await _tapText(tester, item);
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpAndSettle();
}

void main() {
  test('commonFolderOf and defaultZipName', () {
    expect(commonFolderOf(['/a/b/c', '/a/b/d', '/a/b/c/e']), '/a/b');
    expect(commonFolderOf(['/a/b']), '/a/b');
    expect(commonFolderOf(['/a', '/b']), '/');
    expect(defaultZipName('photo.jpg'), 'photo.zip');
    expect(defaultZipName('Holiday.2024', isFolder: true), 'Holiday.2024.zip');
    expect(defaultZipName('.hidden'), '.hidden.zip');
  });

  testWidgets('selection → More → Compress: name prompt, clash → Keep both, '
      'snackbar with Undo', (tester) async {
    final files = _library()..addFile('$_root/DCIM/Camera/c1.zip');
    final s = await _pump(tester, files: files);
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.longPress(find.bySemanticsLabel(RegExp(r'^c1\.jpg, ')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp(r'^c2\.jpg, ')));
    await tester.pumpAndSettle();

    await _tap(tester, find.byTooltip('More'));
    await _tapText(tester, 'Compress');
    expect(find.text('Compress to zip'), findsOneWidget);
    expect(find.text('Saved in Camera'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'c1.zip');
    await _tap(tester, find.widgetWithText(FilledButton, 'Compress'));

    expect(find.text('Name already used'), findsOneWidget);
    await _tapText(tester, 'Keep both');
    final job = s.archive.jobs.single as CompressJob;
    expect(job.outputPath, '$_root/DCIM/Camera/c1 (1).zip');
    expect(job.rootFolder, '$_root/DCIM/Camera');
    expect(job.sourcePaths, hasLength(2));
    expect(find.text('Created c1 (1).zip'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(s.undo.undos, 1);
    expect(find.text('Undone'), findsOneWidget);
    await _finish(tester);
  });

  Future<void> compressC1(WidgetTester tester) async {
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.longPress(find.bySemanticsLabel(RegExp(r'^c1\.jpg, ')));
    await tester.pumpAndSettle();
    await _tap(tester, find.byTooltip('More'));
    await _tapText(tester, 'Compress');
    await _tap(tester, find.widgetWithText(FilledButton, 'Compress'));
  }

  testWidgets('compress clash → Replace: the job trashes the old zip', (
    tester,
  ) async {
    final files = _library()..addFile('$_root/DCIM/Camera/c1.zip');
    final s = await _pump(tester, files: files);
    await compressC1(tester);
    await _tapText(tester, 'Replace');
    // Not trashed up front: handed to the job, which trashes it once the
    // new zip is written.
    expect(s.archive.replacing.single?.name, 'c1.zip');
    expect(s.archive.trashedForReplace.single.name, 'c1.zip');
    expect(
      (s.archive.jobs.single as CompressJob).outputPath,
      '$_root/DCIM/Camera/c1.zip',
    );
    expect(find.text('Created c1.zip'), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('Replace declined: says the old zip was kept', (tester) async {
    final files = _library()..addFile('$_root/DCIM/Camera/c1.zip');
    final s = await _pump(tester, files: files);
    s.archive.declineReplace = true;
    await compressC1(tester);
    await _tapText(tester, 'Replace');
    expect(
      find.text('The old zip was kept. The new one is saved as c1 (1).zip'),
      findsOneWidget,
    );
    expect(s.archive.trashedForReplace, isEmpty);
    await _finish(tester);
  });

  testWidgets('a zip among the sources is never replaced: Keep both naming', (
    tester,
  ) async {
    final files = _library()..addFile('$_root/DCIM/Camera/a.zip');
    final s = await _pump(tester, files: files);
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.longPress(find.bySemanticsLabel(RegExp(r'^a\.zip, ')));
    await tester.pumpAndSettle();
    await _tap(tester, find.byTooltip('More'));
    await _tapText(tester, 'Compress');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'a.zip',
    );
    await _tap(tester, find.widgetWithText(FilledButton, 'Compress'));
    expect(find.text('Name already used'), findsNothing);
    final job = s.archive.jobs.single as CompressJob;
    expect(job.outputPath, '$_root/DCIM/Camera/a (1).zip');
    expect(job.sourcePaths, ['$_root/DCIM/Camera/a.zip']);
    expect(s.archive.replacing.single, isNull);
    await _finish(tester);
  });

  testWidgets('no Undo on the snackbar when none was recorded', (tester) async {
    final s = await _pump(tester);
    s.archive.recordsUndo = false;
    await compressC1(tester);
    expect(find.text('Created c1.zip'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
    await _finish(tester);
  });

  testWidgets('a destination off internal storage is refused', (tester) async {
    final s = await _pump(tester);
    s.archive.destinationReason = ArchiveService.notLocalReason;
    await compressC1(tester);
    expect(
      find.text(
        "Can't save to this place yet. Pick a folder on internal storage",
      ),
      findsOneWidget,
    );
    expect(s.archive.jobs, isEmpty);
    await _finish(tester);
  });

  testWidgets('a blocked place says why and opens no dialog', (tester) async {
    final s = await _pump(tester);
    s.archive.blockReason = 'remote';
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.longPress(find.bySemanticsLabel(RegExp(r'^c1\.jpg, ')));
    await tester.pumpAndSettle();
    await _tap(tester, find.byTooltip('More'));
    await _tapText(tester, 'Compress');
    expect(find.text("Can't zip files from this place yet"), findsOneWidget);
    expect(find.text('Compress to zip'), findsNothing);
    expect(s.archive.jobs, isEmpty);
    await _finish(tester);
  });

  testWidgets('zip items only on .zip files', (tester) async {
    await _pump(tester);
    await _openArchives(tester);
    await _tap(tester, _menuOf('backup.7z').first);
    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('View contents'), findsNothing);
    expect(find.text('Extract here'), findsNothing);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    await _tap(tester, _menuOf('photos.zip').first);
    expect(find.text('View contents'), findsOneWidget);
    expect(find.text('Extract here'), findsOneWidget);
    expect(find.text('Extract to…'), findsOneWidget);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    await _finish(tester);
  });

  testWidgets('⋮ Extract here → new folder, snackbar, Undo', (tester) async {
    final s = await _pump(tester);
    await _openArchives(tester);
    await _zipMenu(tester, 'Extract here');
    final job = s.archive.jobs.single as ExtractJob;
    expect(job.targetFolder, '$_root/Download/photos');
    expect(job.entryNames, isNull);
    expect(job.password, isNull);
    expect(find.text('Extracted 2 files to photos'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(s.undo.undos, 1);
    await _finish(tester);
  });

  testWidgets('password needed → wrong (dialog stays) → right', (tester) async {
    final s = await _pump(tester);
    s.archive.password = 'secret';
    await _openArchives(tester);
    await _zipMenu(tester, 'Extract here');
    expect(find.text('Password needed'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nope');
    await _tap(tester, find.widgetWithText(FilledButton, 'Extract'));
    expect(find.text('Password needed'), findsOneWidget);
    expect(find.text('Wrong password, try again'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'secret');
    await _tap(tester, find.widgetWithText(FilledButton, 'Extract'));
    expect(find.text('Password needed'), findsNothing);
    expect(
      [for (final j in s.archive.jobs) (j as ExtractJob).password],
      [null, 'nope', 'secret'],
    );
    expect(find.text('Extracted 2 files to photos'), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('zip bomb asks first; Cancel extracts nothing', (tester) async {
    final s = await _pump(tester);
    s.archive.listing = const ArchiveListing(
      entries: [ArchiveEntry(name: 'big.bin', size: 1, isDirectory: false)],
      zipSize: 1000,
      uncompressedTotal: 20 * 1024 * 1024 * 1024,
    );
    await _openArchives(tester);
    await _zipMenu(tester, 'Extract here');
    expect(find.text('Very large archive'), findsOneWidget);
    expect(find.textContaining('This archive expands to 20'), findsOneWidget);
    await _tapText(tester, 'Cancel');
    expect(s.archive.jobs, isEmpty);

    await _zipMenu(tester, 'Extract here');
    await _tapText(tester, 'Extract anyway');
    expect(s.archive.jobs, hasLength(1));
    await _finish(tester);
  });

  testWidgets('"Extract this" on a huge folder asks first', (tester) async {
    final s = await _pump(tester);
    s.archive.listing = const ArchiveListing(
      entries: [
        ArchiveEntry(name: 'big/', size: 0, isDirectory: true),
        ArchiveEntry(
          name: 'big/x.bin',
          size: 20 * 1024 * 1024 * 1024,
          isDirectory: false,
        ),
        ArchiveEntry(name: 'small.txt', size: 1, isDirectory: false),
      ],
      zipSize: 1000,
      uncompressedTotal: 20 * 1024 * 1024 * 1024 + 1,
    );
    await _openArchives(tester);
    await _zipMenu(tester, 'View contents');
    await tester.longPress(find.text('big/'));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Extract this');
    expect(find.text('Very large archive'), findsOneWidget);
    await _tapText(tester, 'Cancel');
    expect(s.archive.jobs, isEmpty);

    await tester.longPress(find.text('small.txt'));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Extract this');
    expect(find.text('Very large archive'), findsNothing);
    expect((s.archive.jobs.single as ExtractJob).entryNames, {'small.txt'});
    await _finish(tester);
  });

  testWidgets('errors become messages: unsafe paths, corrupt, no space', (
    tester,
  ) async {
    final s = await _pump(tester);
    await _openArchives(tester);

    s.archive.runError = const UnsafeEntryPath('../evil.txt');
    await _zipMenu(tester, 'Extract here');
    expect(
      find.text('This archive contains unsafe paths and was not extracted'),
      findsOneWidget,
    );

    s.archive.runError = null;
    s.archive.listError = const CorruptArchive('bad header');
    await _zipMenu(tester, 'Extract here');
    expect(find.text('This zip is damaged or not a zip file'), findsOneWidget);

    s.archive.listError = null;
    s.archive.runError = const NotEnoughSpace(3 << 30, 1 << 30);
    await _zipMenu(tester, 'Extract here');
    expect(find.textContaining('Not enough space'), findsOneWidget);
    expect(s.undo.undos, 0);
    await _finish(tester);
  });

  testWidgets('View contents lists entries; Extract to… uses the picker; '
      'long-press → Extract this', (tester) async {
    final s = await _pump(tester);
    await _openArchives(tester);
    await _zipMenu(tester, 'View contents');
    expect(find.text('photos.zip'), findsWidgets);
    expect(find.text('a.jpg'), findsOneWidget);
    expect(find.text('sub/'), findsOneWidget);
    expect(find.text('sub/b.txt'), findsOneWidget);
    expect(find.text('3 items · 1,020 B'), findsOneWidget);

    await tester.longPress(find.text('sub/'));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Extract this');
    final job = s.archive.jobs.single as ExtractJob;
    expect(job.targetFolder, '$_root/Download');
    expect(job.entryNames, {'sub/'});
    expect(find.text('Extracted 1 file to Download'), findsOneWidget);

    await _tap(tester, find.widgetWithText(OutlinedButton, 'Extract to…'));
    expect(find.text('Extract to'), findsOneWidget);
    await _tapText(tester, 'Internal storage');
    await _tapText(tester, 'DCIM');
    await _tapText(tester, 'Use this folder');
    final to = s.archive.jobs.last as ExtractJob;
    expect(to.targetFolder, '$_root/DCIM');
    expect(to.entryNames, isNull);
    await _finish(tester);
  });

  testWidgets('folder ⋮ Compress zips the folder next to it', (tester) async {
    final s = await _pump(tester);
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Folders');
    await _tapText(tester, 'Internal storage');
    await _tapText(tester, 'DCIM');
    final camera = find.ancestor(
      of: find.text('Camera'),
      matching: find.byType(ListTile),
    );
    await _tap(
      tester,
      find.descendant(of: camera, matching: find.byTooltip('Folder options')),
    );
    await _tapText(tester, 'Compress');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Camera.zip',
    );
    await _tap(tester, find.widgetWithText(FilledButton, 'Compress'));
    final job = s.archive.jobs.single as CompressJob;
    expect(job.sourcePaths, ['$_root/DCIM/Camera']);
    expect(job.rootFolder, '$_root/DCIM');
    expect(job.outputPath, '$_root/DCIM/Camera.zip');
    expect(find.text('Created Camera.zip'), findsOneWidget);
    await _finish(tester);
  });
}
