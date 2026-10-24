import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/trash_types.dart';

import 'fake_file_source.dart';
import 'file_source_contract.dart';

class _FakeHarness implements ContractHarness {
  final FakeFileSource fake = FakeFileSource();

  @override
  FileSource get source => fake;

  @override
  String get root => '/storage/emulated/0/test';

  @override
  Future<FileRef> addFile(String path, List<int> bytes) async =>
      fake.addFile(path, bytes: bytes);

  @override
  Future<void> removeExternally(FileRef f) async => fake.removeExternally(f.id);

  @override
  Future<void> dispose() => fake.dispose();
}

void main() {
  fileSourceContract('FakeFileSource', () async {
    final h = _FakeHarness();
    h.fake.addFolder(h.root);
    return h;
  });

  test('trash and restore round-trip', () async {
    final fake = FakeFileSource();
    addTearDown(fake.dispose);
    final f = fake.addFile('/p/a.jpg');
    final result = await fake.trashBatch([f]);
    expect(result.allSucceeded, isTrue);
    expect(await fake.stat(f.id), isNull);
    final restored = await fake.restore(result.trashed.single);
    expect(restored.id, f.id);
    expect(result.trashed.single.location, TrashLocation.systemTrash);
  });
}
