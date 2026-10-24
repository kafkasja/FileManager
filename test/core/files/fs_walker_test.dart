import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/android/fs_walker.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';

void main() {
  late Directory dir;
  late String root;

  Future<void> touch(String rel, [List<int> bytes = const [1]]) async {
    final f = File('$root/$rel');
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes);
  }

  Future<List<String>> names(WalkOptions o) async => [
    for (final page in await walkFiles(o).toList())
      for (final f in page) f.path.substring(root.length + 1),
  ]..sort();

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kfm_walk');
    root = dir.path.replaceAll(r'\', '/');
    await touch('a.pdf', [1, 2, 3]);
    await touch('sub/b.zip');
    await touch('sub/deep/c.txt');
    await touch('.dot.txt');
    await touch('.hiddendir/d.pdf');
    await touch('nomedia/.nomedia');
    await touch('nomedia/e.pdf');
    await touch('nomedia/pic.jpg');
    await touch('Android/data/x.pdf');
    await touch('photo.jpg');
  });

  tearDown(() => dir.delete(recursive: true));

  test(
    'lists files recursively, skipping hidden, .nomedia and Android/data',
    () async {
      expect(await names(WalkOptions(root: root)), [
        'a.pdf',
        'photo.jpg',
        'sub/b.zip',
        'sub/deep/c.txt',
      ]);
    },
  );

  test('includeHidden lists dot entries and .nomedia folders', () async {
    expect(await names(WalkOptions(root: root, includeHidden: true)), [
      '.dot.txt',
      '.hiddendir/d.pdf',
      'a.pdf',
      'nomedia/.nomedia',
      'nomedia/e.pdf',
      'nomedia/pic.jpg',
      'photo.jpg',
      'sub/b.zip',
      'sub/deep/c.txt',
    ]);
  });

  test('skipIndexedKinds drops media except in hidden folders', () async {
    final o = WalkOptions(
      root: root,
      includeHidden: true,
      skipIndexedKinds: const {FileKind.image},
    );
    final found = await names(o);
    expect(found, isNot(contains('photo.jpg')));
    expect(found, contains('nomedia/pic.jpg'));
  });

  test('non-recursive, kinds and min size filters', () async {
    expect(await names(WalkOptions(root: root, recursive: false)), [
      'a.pdf',
      'photo.jpg',
    ]);
    expect(
      await names(WalkOptions(root: root, kinds: const {FileKind.archive})),
      ['sub/b.zip'],
    );
    expect(await names(WalkOptions(root: root, minSizeBytes: 2)), ['a.pdf']);
  });

  test('fills FileRef fields', () async {
    final all = await walkFiles(WalkOptions(root: root, recursive: false))
        .expand((p) => p)
        .toList();
    final pdf = all.singleWhere((f) => f.name == 'a.pdf');
    expect(pdf.id, 'path:$root/a.pdf');
    expect(pdf.sizeBytes, 3);
    expect(pdf.kind, FileKind.document);
    expect(pdf.folderPath, root);
    expect(pdf.modifiedAt.isUtc, isTrue);
  });

  test('pages respect pageSize', () async {
    final pages = await walkFiles(WalkOptions(root: root, pageSize: 2))
        .toList();
    expect(pages.every((p) => p.length <= 2), isTrue);
    expect(pages.expand((p) => p), hasLength(4));
  });

  test('missing root errors with notFound', () async {
    await expectLater(
      walkFiles(WalkOptions(root: '$root/nope')).toList(),
      throwsA(
        isA<FileOpException>().having(
          (e) => e.failure,
          'failure',
          FileOpFailure.notFound,
        ),
      ),
    );
  });

  test('cancelling the subscription stops the walk', () async {
    for (var i = 0; i < 50; i++) {
      await touch('many/f$i.txt');
    }
    final first = await walkFiles(WalkOptions(root: root, pageSize: 1)).first;
    expect(first, hasLength(1));
  });
}
