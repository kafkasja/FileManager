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
void fileSourceContract(
  String name,
  Future<ContractHarness> Function() create,
) {
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

    test('openRead returns the bytes', () async {
      final f = await h.addFile('${h.root}/a.bin', [7, 8, 9]);
      expect(await _read(s, f), [7, 8, 9]);
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
