import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';

/// What the contract suite needs from an implementation under test.
abstract interface class ContractHarness {
  FileSource get source;

  /// A writable folder that exists and is empty.
  String get root;

  /// Creates a file at [path] and returns how [source] sees it.
  Future<FileRef> addFile(String path, List<int> bytes);

  /// Deletes [f] behind the source's back.
  Future<void> removeExternally(FileRef f);

  Future<void> dispose();
}

Matcher _fails(FileOpFailure failure) => throwsA(
  isA<FileOpException>().having((e) => e.failure, 'failure', failure),
);

Future<List<int>> _read(FileSource s, FileRef f) async => [
  for (final chunk in await s.openRead(f).toList()) ...chunk,
];

/// Behaviour every [FileSource] must have. Run against each implementation.
///
/// [diskRefusesWindowsChars]: the implementation writes to the host disk
/// and the host is Windows (NTFS refuses `? : *`…), so tests that need such
/// names are skipped.
void fileSourceContract(
  String name,
  Future<ContractHarness> Function() create, {
  bool diskRefusesWindowsChars = false,
}) {
  group('FileSource contract: $name', () {
    late ContractHarness h;
    late FileSource s;

    setUp(() async {
      h = await create();
      s = h.source;
    });
    tearDown(() => h.dispose());

    test('scan finds added files with name, size and kind', () async {
      await h.addFile('${h.root}/docs/report.pdf', [1, 2, 3, 4]);
      await h.addFile('${h.root}/docs/notes.txt', [1]);
      final pages = await s.scan().toList();
      final all = [for (final p in pages) ...p];
      final pdf = all.singleWhere((f) => f.name == 'report.pdf');
      expect(pdf.sizeBytes, 4);
      expect(pdf.kind, FileKind.document);
      expect(pdf.folderPath, '${h.root}/docs');
      expect(all.map((f) => f.name), contains('notes.txt'));
    });

    test('stat returns fresh metadata, null when gone', () async {
      final f = await h.addFile('${h.root}/a.pdf', [1, 2]);
      expect((await s.stat(f.id))?.sizeBytes, 2);
      await h.removeExternally(f);
      expect(await s.stat(f.id), isNull);
    });

    test('registerCreated returns the files, skipping missing paths', () async {
      await h.addFile('${h.root}/out/a.zip', [1, 2, 3]);
      await h.addFile('${h.root}/out/b/notes.txt', [1]);
      final refs = await s.registerCreated([
        '${h.root}/out/a.zip',
        '${h.root}/out/missing.txt',
        '${h.root}/out/b/notes.txt',
      ]);
      expect(refs.map((f) => f.name), ['a.zip', 'notes.txt']);
      expect(refs.first.sizeBytes, 3);
      expect(refs.first.folderPath, '${h.root}/out');
      expect(await s.registerCreated(const []), isEmpty);
    });

    test('openRead returns the bytes', () async {
      final f = await h.addFile('${h.root}/a.bin', [7, 8, 9]);
      expect(await _read(s, f), [7, 8, 9]);
    });

    test('openRead with start/end serves bytes [start, end)', () async {
      final f = await h.addFile('${h.root}/r.bin', [0, 1, 2, 3, 4, 5]);
      Future<List<int>> range(int start, [int? end]) async => [
        for (final c in await s.openRead(f, start: start, end: end).toList())
          ...c,
      ];
      expect(await range(2, 4), [2, 3]);
      expect(await range(4), [4, 5]);
      expect(await range(0, 1), [0]);
      expect(await range(6), isEmpty);
    });

    test(
      'copy into a folder with the same name creates "name (1).ext"',
      () async {
        final original = await h.addFile('${h.root}/src/doc.pdf', [1, 2, 3]);
        await h.addFile('${h.root}/dst/doc.pdf', [9]);
        final copy = await s.copy(original, '${h.root}/dst');
        expect(copy.name, 'doc (1).pdf');
        expect(copy.folderPath, '${h.root}/dst');
        expect(await _read(s, copy), [1, 2, 3]);
        // Original untouched.
        expect((await s.stat(original.id))?.sizeBytes, 3);
      },
    );

    test('move relocates the file and reports an id change', () async {
      final f = await h.addFile('${h.root}/a/doc.pdf', [1, 2]);
      await s.createFolder(h.root, 'b');
      final changes = <FileIdChange>[];
      final sub = s.idChanges.listen(changes.add);
      addTearDown(sub.cancel);

      final moved = await s.move(f, '${h.root}/b');
      expect(moved.folderPath, '${h.root}/b');
      expect(moved.name, 'doc.pdf');
      expect(await _read(s, moved), [1, 2]);
      expect(await s.stat(moved.id), isNotNull);
      await Future<void>.delayed(Duration.zero);
      if (moved.id != f.id) {
        expect(await s.stat(f.id), isNull);
        expect(changes.single.oldId, f.id);
        expect(changes.single.newRef.id, moved.id);
      }
    });

    test('move never overwrites', () async {
      final f = await h.addFile('${h.root}/a/doc.pdf', [1]);
      await h.addFile('${h.root}/b/doc.pdf', [2, 2]);
      final moved = await s.move(f, '${h.root}/b');
      expect(moved.name, 'doc (1).pdf');
    });

    test('move to its own folder is a no-op', () async {
      final f = await h.addFile('${h.root}/a/doc.pdf', [1]);
      final same = await s.move(f, '${h.root}/a');
      expect(same.id, f.id);
    });

    test(
      'move/copy into a missing folder throw notFound, file untouched',
      () async {
        final f = await h.addFile('${h.root}/a/doc.pdf', [1]);
        await expectLater(
          s.move(f, '${h.root}/gone'),
          _fails(FileOpFailure.notFound),
        );
        await expectLater(
          s.copy(f, '${h.root}/gone'),
          _fails(FileOpFailure.notFound),
        );
        expect((await s.stat(f.id))?.folderPath, '${h.root}/a');
      },
    );

    test('requestWriteAccess for nothing is granted', () async {
      expect(await s.requestWriteAccess(const []), isTrue);
    });

    test('move of a file deleted meanwhile throws notFound', () async {
      final f = await h.addFile('${h.root}/a/doc.pdf', [1]);
      await s.createFolder(h.root, 'b');
      await h.removeExternally(f);
      await expectLater(
        s.move(f, '${h.root}/b'),
        _fails(FileOpFailure.notFound),
      );
    });

    test('rename changes the name and avoids collisions', () async {
      final f = await h.addFile('${h.root}/x.pdf', [1]);
      await h.addFile('${h.root}/y.pdf', [2]);
      final renamed = await s.rename(f, 'y.pdf');
      expect(renamed.name, 'y (1).pdf');
      expect(renamed.folderPath, h.root);
    });

    test('rename rejects invalid names', () async {
      final f = await h.addFile('${h.root}/x.pdf', [1]);
      await expectLater(s.rename(f, 'a/b'), _fails(FileOpFailure.invalidName));
      await expectLater(s.rename(f, ' '), _fails(FileOpFailure.invalidName));
    });

    test('rename keeps a name only user input may not use (B4 undo)', () async {
      final f = await h.addFile('${h.root}/x.pdf', [1]);
      // Undo restores names that already exist on disk: only the dialogs
      // apply the strict validateFileName.
      final renamed = await s.rename(f, 'What?.pdf');
      expect(renamed.name, 'What?.pdf');
      expect(await s.statPath('${h.root}/What?.pdf'), isNotNull);
    }, skip: diskRefusesWindowsChars ? 'the host disk refuses "?"' : null);

    test('rename still rejects names that are no path segment', () async {
      final f = await h.addFile('${h.root}/x.pdf', [1]);
      for (final bad in ['', '.', '..', 'a\u0000b', '${'é' * 128}.pdf']) {
        await expectLater(
          s.rename(f, bad),
          _fails(FileOpFailure.invalidName),
          reason: bad,
        );
      }
      expect((await s.stat(f.id))?.name, 'x.pdf');
    });

    test('statPath finds a file, null for nothing or a folder', () async {
      final f = await h.addFile('${h.root}/a/doc.pdf', [1, 2]);
      final hit = await s.statPath('${h.root}/a/doc.pdf');
      expect(hit?.id, f.id);
      expect(hit?.sizeBytes, 2);
      expect(await s.statPath('${h.root}/a/none.pdf'), isNull);
      expect(await s.statPath('${h.root}/a'), isNull);
    });

    test('renameFolder moves the children and reports id changes', () async {
      final a = await h.addFile('${h.root}/old/a.pdf', [1]);
      final b = await h.addFile('${h.root}/old/sub/b.txt', [2, 2]);
      final changes = <FileIdChange>[];
      final sub = s.idChanges.listen(changes.add);
      addTearDown(sub.cancel);

      final result = await s.renameFolder('${h.root}/old', 'new');
      expect(result.path, '${h.root}/new');
      expect(
        {for (final f in result.files) f.path},
        {'${h.root}/new/a.pdf', '${h.root}/new/sub/b.txt'},
      );
      expect(await s.stat(a.id), isNull);
      expect(await s.statPath('${h.root}/new/sub/b.txt'), isNotNull);
      await Future<void>.delayed(Duration.zero);
      final byOld = {for (final c in changes) c.oldId: c.newRef.path};
      expect(byOld[a.id], '${h.root}/new/a.pdf');
      expect(byOld[b.id], '${h.root}/new/sub/b.txt');
    });

    test('renameFolder refuses an existing name and a bad name', () async {
      await h.addFile('${h.root}/one/a.pdf', [1]);
      await h.addFile('${h.root}/two/b.pdf', [1]);
      await expectLater(
        s.renameFolder('${h.root}/one', 'two'),
        _fails(FileOpFailure.targetExists),
      );
      await expectLater(
        s.renameFolder('${h.root}/one', 'a/b'),
        _fails(FileOpFailure.invalidName),
      );
      expect(await s.statPath('${h.root}/one/a.pdf'), isNotNull);
    });

    test('freeBytes is null or not negative', () async {
      final free = await s.freeBytes(h.root);
      expect(free == null || free >= 0, isTrue);
    });

    group('importFile (N9)', () {
      late Directory staging;

      setUp(() async {
        staging = await Directory.systemTemp.createTemp('kfm_staging');
      });
      tearDown(() async {
        if (await staging.exists()) await staging.delete(recursive: true);
      });

      Future<File> stage(String name, List<int> bytes) async {
        final f = File('${staging.path}/$name');
        await f.writeAsBytes(bytes);
        return f;
      }

      test('publishes the staged bytes in a new folder; staged gone', () async {
        final part = await stage('dl-1.part', [5, 6, 7]);
        final f = await s.importFile(
          part,
          targetFolder: '${h.root}/in',
          name: 'photo.jpg',
        );
        expect(f.name, 'photo.jpg');
        expect(f.folderPath, '${h.root}/in');
        expect(f.sizeBytes, 3);
        expect(await _read(s, f), [5, 6, 7]);
        expect(await part.exists(), isFalse);
      });

      test('a name clash gets (1), nothing is overwritten', () async {
        await h.addFile('${h.root}/in/a.pdf', [1]);
        final f = await s.importFile(
          await stage('dl-2.part', [2, 2]),
          targetFolder: '${h.root}/in',
          name: 'a.pdf',
        );
        expect(f.name, 'a (1).pdf');
        expect((await s.statPath('${h.root}/in/a.pdf'))?.sizeBytes, 1);
      });

      test('a bad name is refused before anything is written', () async {
        final part = await stage('dl-3.part', [1]);
        for (final bad in ['a/b.jpg', '..', '', 'x' * 300]) {
          await expectLater(
            s.importFile(part, targetFolder: '${h.root}/in', name: bad),
            _fails(FileOpFailure.invalidName),
          );
        }
        expect(await part.exists(), isTrue);
      });
    });

    test('createFolder creates, then refuses a duplicate', () async {
      final path = await s.createFolder(h.root, 'New');
      expect(path, '${h.root}/New');
      await expectLater(
        s.createFolder(h.root, 'New'),
        _fails(FileOpFailure.targetExists),
      );
    });
  });
}
