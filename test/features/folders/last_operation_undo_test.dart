import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/cancel_token.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/folders/data/folder_ops.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';
import 'package:kfm/features/folders/ui/last_operation_undo.dart';

import '../../core/files/fake_file_source.dart';
import 'folders_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFileSource files;
  late List<FileRef> photos;

  setUp(() {
    files = FakeFileSource();
    photos = [
      for (final n in ['a', 'b', 'c'])
        files.addFile('/s/DCIM/Cam/$n.jpg', bytes: List.filled(5, 1)),
    ];
    files.addFolder('/s/DCIM/Holiday');
  });

  LastOperationUndo undoOf(FoldersHarness h) =>
      h.c.read(lastOperationUndoProvider.notifier);

  Future<void> record(FoldersHarness h, CompletedOperation done) async {
    undoOf(h).record(done);
    expect(h.c.read(lastOperationUndoProvider), isA<FileOpDone>());
  }

  List<String> pathsIn(String folder) => [
    for (final f in files.files)
      if (f.folderPath == folder) f.name,
  ]..sort();

  test('undo of a move brings files back with their original names', () async {
    // A name taken in the target makes F3 keep both: "a (1).jpg".
    files.addFile('/s/DCIM/Holiday/a.jpg');
    final h = await launchFolders(files);
    final done = await h.run(
      MoveOp(photos, '/s/DCIM/Holiday'),
      resolve: (_, _) async => (CollisionChoice.keepBoth, false),
    );
    expect(done.results.first.after!.name, 'a (1).jpg');
    await record(h, done);

    final out = await undoOf(h).undo();
    await h.settle();

    expect(out!.undone, 3);
    expect(out.missing, 0);
    expect(pathsIn('/s/DCIM/Cam'), ['a.jpg', 'b.jpg', 'c.jpg']);
    expect(pathsIn('/s/DCIM/Holiday'), ['a.jpg']);
    expect(await h.indexedIds(), containsAll([for (final p in photos) p.id]));
    expect(h.c.read(lastOperationUndoProvider), isNull);
  });

  test('a file changed elsewhere since is reported, the rest undone', () async {
    final h = await launchFolders(files);
    final done = await h.run(MoveOp(photos, '/s/DCIM/Holiday'));
    await record(h, done);
    files.removeExternally(done.results[1].after!.id);

    final out = await undoOf(h).undo();
    expect(out!.undone, 2);
    expect(out.missing, 1);
    expect(pathsIn('/s/DCIM/Cam'), ['a.jpg', 'c.jpg']);
  });

  test('undo of a copy trashes the copies', () async {
    final h = await launchFolders(files);
    final done = await h.run(CopyOp(photos, '/s/DCIM/Holiday'));
    await record(h, done);

    final out = await undoOf(h).undo();
    await h.settle();
    expect(out!.undone, 3);
    expect(pathsIn('/s/DCIM/Holiday'), isEmpty);
    expect(pathsIn('/s/DCIM/Cam'), ['a.jpg', 'b.jpg', 'c.jpg']);
    final ids = await h.indexedIds();
    expect(ids.where((id) => id.contains('Holiday')), isEmpty);
  });

  // A Move: the fake keys its trash by path id, so a trashed copy at the
  // replaced file's path would overwrite that trash entry.
  test('undo of a Replace move restores the replaced file', () async {
    final old = files.addFile('/s/DCIM/Holiday/a.jpg', bytes: [7]);
    final h = await launchFolders(files);
    final done = await h.run(
      MoveOp([photos[0]], '/s/DCIM/Holiday'),
      resolve: (_, _) async => (CollisionChoice.replace, false),
    );
    expect(files.trash, hasLength(1));
    await record(h, done);

    final out = await undoOf(h).undo();
    await h.settle();
    expect(out!.undone, 1);
    final back = files.files.singleWhere(
      (f) => f.folderPath == '/s/DCIM/Holiday',
    );
    expect(back.path, old.path);
    expect(back.sizeBytes, 1);
    expect(pathsIn('/s/DCIM/Cam'), ['a.jpg', 'b.jpg', 'c.jpg']);
    expect(await h.indexedIds(), containsAll([old.id, photos[0].id]));
  });

  test('undo of a duplicate removes the (1) copy', () async {
    final h = await launchFolders(files);
    await record(h, await h.run(DuplicateOp([photos[0]])));
    final out = await undoOf(h).undo();
    expect(out!.undone, 1);
    expect(pathsIn('/s/DCIM/Cam'), ['a.jpg', 'b.jpg', 'c.jpg']);
  });

  test('undo of a rename renames back', () async {
    final h = await launchFolders(files);
    final done = await h.run(RenameOp(photos[0], 'beach.jpg'));
    expect(done.results.single.after!.name, 'beach.jpg');
    await record(h, done);

    final out = await undoOf(h).undo();
    expect(out!.undone, 1);
    expect(pathsIn('/s/DCIM/Cam'), ['a.jpg', 'b.jpg', 'c.jpg']);
  });

  test(
    'undo of a trash delete restores into the folder and the index',
    () async {
      final h = await launchFolders(files);
      final done = await h.run(await h.runner.deleteOp(photos));
      await record(h, done);
      expect(await h.indexedIds(), isEmpty);

      final out = await undoOf(h).undo();
      await h.settle();
      expect(out!.undone, 3);
      expect(files.trash, isEmpty);
      expect(pathsIn('/s/DCIM/Cam'), ['a.jpg', 'b.jpg', 'c.jpg']);
      expect(await h.indexedIds(), containsAll([for (final p in photos) p.id]));
    },
  );

  test('a declined restore dialog is reported', () async {
    final h = await launchFolders(files);
    await record(h, await h.run(await h.runner.deleteOp(photos)));
    files.declineDialogs = true;
    final out = await undoOf(h).undo();
    expect(out!.declined, isTrue);
    expect(out.undone, 0);
    // Nothing changed: the undo is still there to try again.
    expect(h.c.read(lastOperationUndoProvider), isA<FileOpDone>());

    files.declineDialogs = false;
    final again = await undoOf(h).undo();
    expect(again!.undone, 3);
    expect(h.c.read(lastOperationUndoProvider), isNull);
  });

  test('an undo cancelled before it started is kept', () async {
    final h = await launchFolders(files);
    await record(h, await h.run(MoveOp(photos, '/s/DCIM/Holiday')));
    final out = await undoOf(h).undo(cancel: CancelToken()..cancel());
    expect(out!.cancelled, isTrue);
    expect(out.undone, 0);
    expect(h.c.read(lastOperationUndoProvider), isA<FileOpDone>());
  });

  test('follows id changes of the stored files', () async {
    final h = await launchFolders(files);
    final done = await h.run(CopyOp([photos[0]], '/s/DCIM/Holiday'));
    await record(h, done);
    // Re-keyed elsewhere since (F3 emits an idChange).
    await files.rename(done.results.single.after!, 'z.jpg');
    await pumpEventQueue();

    final out = await undoOf(h).undo();
    expect(out!.undone, 1);
    expect(out.missing, 0);
    expect(pathsIn('/s/DCIM/Holiday'), isEmpty);
  });

  test('permanent delete and all-skipped ops clear the stored undo', () async {
    final h = await launchFolders(files);
    await record(h, await h.run(DuplicateOp([photos[0]])));
    undoOf(h).record(await h.run(DeleteOp([photos[1]], permanent: true)));
    expect(h.c.read(lastOperationUndoProvider), isNull);
    expect(await undoOf(h).undo(), isNull);
  });

  test('cancel stops the undo between files', () async {
    final h = await launchFolders(files);
    await record(h, await h.run(MoveOp(photos, '/s/DCIM/Holiday')));
    final cancel = CancelToken();
    final out = await undoOf(h).undo(
      cancel: cancel,
      onProgress: (p) {
        if (p.done == 1) cancel.cancel();
      },
    );
    expect(out!.cancelled, isTrue);
    expect(out.undone, 1);
    expect(pathsIn('/s/DCIM/Cam'), ['a.jpg']);
  });

  group('folder rename', () {
    test('renames, re-indexes, and undo renames back', () async {
      final h = await launchFolders(files);
      final ops = h.c.read(folderOpsProvider);
      final renamed = await ops.renameFolder('/s/DCIM/Cam', 'Camera');
      await h.settle();
      expect(renamed.newPath, '/s/DCIM/Camera');
      expect(renamed.files, hasLength(3));
      expect(pathsIn('/s/DCIM/Camera'), ['a.jpg', 'b.jpg', 'c.jpg']);
      final row = await h.indexed('path:/s/DCIM/Camera/a.jpg');
      expect(row!.folderPath, '/s/DCIM/Camera');

      undoOf(h).recordFolderRename(renamed);
      expect(h.c.read(lastOperationUndoProvider), isA<FolderRenameDone>());
      final out = await undoOf(h).undo();
      await h.settle();
      expect(out!.undone, 1);
      expect(pathsIn('/s/DCIM/Cam'), ['a.jpg', 'b.jpg', 'c.jpg']);
      expect(await h.indexedIds(), containsAll([for (final p in photos) p.id]));
    });

    test('undo when the renamed folder is gone counts it missing', () async {
      final h = await launchFolders(files);
      undoOf(h).recordFolderRename((
        oldPath: '/s/DCIM/Old',
        newPath: '/s/DCIM/Nope',
        files: const [],
      ));
      final out = await undoOf(h).undo();
      expect(out!.missing, 1);
    });
  });
}
