import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/pending_folder.dart';
import 'package:kfm/core/files/saf/saf_channel.dart';
import 'package:kfm/core/files/saf/saf_file_source.dart';
import 'package:kfm/core/files/saf/saf_pending_folder.dart';
import 'package:kfm/core/files/trash_types.dart';

import 'fake_saf_platform.dart';
import 'file_source_contract.dart';

class _SafHarness implements ContractHarness {
  new() {
    fake.addFolder(root);
  }

  final FakeSafPlatform fake = FakeSafPlatform();
  late final SafFileSource saf = SafFileSource(
    channel: fake,
    trees: () => [fake.tree],
  );

  @override
  FileSource get source => saf;

  @override
  String get root => '${fake.root}/work';

  @override
  Future<FileRef> addFile(String path, List<int> bytes) async {
    fake.addFile(path, bytes);
    return (await saf.statPath(path))!;
  }

  @override
  Future<void> removeExternally(FileRef f) async =>
      fake.removeDoc(f.id.substring(f.id.indexOf('|') + 1));

  @override
  Future<void> dispose() => saf.dispose();
}

void main() {
  fileSourceContract('SafFileSource (fake channel)', () async => _SafHarness());

  group('SafFileSource', () {
    late _SafHarness h;
    setUp(() => h = _SafHarness());
    tearDown(() => h.dispose());

    test('folders are real paths; ids are saf: ids', () async {
      final f = await h.addFile('${h.fake.root}/DCIM/a.jpg', [1]);
      expect(f.id, startsWith('saf:${h.fake.treeUri}|'));
      expect(f.folderPath, '${h.fake.root}/DCIM');
      expect(f.origin, FileOrigin.external);
      expect(f.kind, FileKind.image);
    });

    test(
      'listChildren returns folders and files, hidden ones skipped',
      () async {
        h.fake
          ..addFile('${h.fake.root}/DCIM/a.jpg', [1])
          ..addFile('${h.fake.root}/DCIM/.hidden.jpg', [1])
          ..addFolder('${h.fake.root}/DCIM/Sub');
        final l = await h.saf.listChildren('${h.fake.root}/DCIM');
        expect(l.folders.map((f) => f.id), ['${h.fake.root}/DCIM/Sub']);
        expect(l.files.map((f) => f.name), ['a.jpg']);
      },
    );

    test('scan skips .nomedia folders unless includeHidden', () async {
      h.fake
        ..addFile('${h.fake.root}/A/a.jpg', [1])
        ..addFile('${h.fake.root}/B/.nomedia', [])
        ..addFile('${h.fake.root}/B/b.jpg', [1]);
      final names = (await h.saf.scan().toList())
          .expand((p) => p)
          .map((f) => f.name);
      expect(names, ['a.jpg']);
      final all =
          (await h.saf
                  .scan(query: const FileQuery(includeHidden: true))
                  .toList())
              .expand((p) => p)
              .map((f) => f.name);
      expect(all, containsAll(['a.jpg', 'b.jpg', '.nomedia']));
    });

    test('a file without a grant is unavailable, not gone', () async {
      final f = await h.addFile('${h.root}/a.jpg', [1]);
      final gone = SafFileSource(channel: h.fake, trees: () => const []);
      await expectLater(
        gone.stat(f.id),
        throwsA(
          isA<FileOpException>().having(
            (e) => e.failure,
            'failure',
            FileOpFailure.unavailable,
          ),
        ),
      );
    });

    test('the copy+delete move fallback verifies the copy', () async {
      final f = await h.addFile('${h.root}/a/doc.pdf', [4, 5]);
      h.fake
        ..addFolder('${h.root}/b')
        ..refuseMove = true
        ..corruptNextImport = true;
      await expectLater(
        h.saf.move(f, '${h.root}/b'),
        throwsA(
          isA<FileOpException>().having(
            (e) => e.failure,
            'failure',
            FileOpFailure.ioError,
          ),
        ),
      );
      expect(h.fake.bytesAt('${h.root}/a/doc.pdf'), [4, 5]);
      expect(h.fake.existsPath('${h.root}/b/doc.pdf'), isFalse);
    });

    test('a failed move puts the clash rename back', () async {
      final f = await h.addFile('${h.root}/a/doc.pdf', [1]);
      h.fake.addFile('${h.root}/b/doc.pdf', [2]);
      h.fake.failMove = true;
      await expectLater(h.saf.move(f, '${h.root}/b'), throwsA(anything));
      expect(h.fake.existsPath('${h.root}/a/doc.pdf'), isTrue);
    });

    test('a provider that cannot move copies then deletes', () async {
      final f = await h.addFile('${h.root}/a/doc.pdf', [4, 5]);
      h.fake
        ..addFolder('${h.root}/b')
        ..refuseMove = true;
      final moved = await h.saf.move(f, '${h.root}/b');
      expect(moved.folderPath, '${h.root}/b');
      expect(h.fake.bytesAt('${h.root}/b/doc.pdf'), [4, 5]);
      expect(h.fake.existsPath('${h.root}/a/doc.pdf'), isFalse);
    });

    test('a native copy-out returns the SHA-256', () async {
      final f = await h.addFile('${h.root}/a.bin', [1, 2, 3]);
      expect(await h.saf.sha256Of(f), FakeSafPlatform.sha256Hex([1, 2, 3]));
    });
  });

  group('SafPendingFolder (D4 on SAF volumes)', () {
    late FakeSafPlatform fake;
    late AppDatabase db;
    late SafFileSource saf;
    late SafPendingFolder folder;
    var now = DateTime.utc(2026, 11, 2);

    setUp(() {
      fake = FakeSafPlatform();
      db = AppDatabase(NativeDatabase.memory());
      final locator = SafLocator(() => [fake.tree]);
      now = DateTime.utc(2026, 11, 2);
      folder = SafPendingFolder(
        db: db,
        channel: fake,
        locator: locator,
        retentionDays: () async => 7,
        clock: () => now,
      );
      saf = SafFileSource(
        channel: fake,
        trees: () => [fake.tree],
        pendingFolder: folder,
      );
    });
    tearDown(() async {
      await saf.dispose();
      await db.close();
    });

    Future<FileRef> add(String rel, List<int> bytes) async {
      fake.addFile('${fake.root}/$rel', bytes);
      return (await saf.statPath('${fake.root}/$rel'))!;
    }

    test('trash moves into <root>/.KFMTrash with .nomedia and index', () async {
      final f = await add('DCIM/a.jpg', [1, 2]);
      final r = await saf.trashBatch([f]);
      expect(r.failed, isEmpty);
      final item = r.trashed.single;
      expect(item.location, TrashLocation.pendingFolder);
      expect(item.storedPath, startsWith('saf:'));
      expect(fake.existsPath('${fake.root}/DCIM/a.jpg'), isFalse);
      expect(fake.existsPath('${fake.root}/.KFMTrash/.nomedia'), isTrue);
      expect(fake.existsPath('${fake.root}/.KFMTrash/.index.jsonl'), isTrue);
      final row = (await db.select(db.pendingFolderItems).get()).single;
      expect(row.volumeId, fake.root);
      expect(row.originalPath, '${fake.root}/DCIM/a.jpg');
    });

    test('restore puts it back; a taken name gets (restored)', () async {
      final f = await add('DCIM/a.jpg', [1, 2]);
      final item = (await saf.trashBatch([f])).trashed.single;
      fake.addFile('${fake.root}/DCIM/a.jpg', [9]);
      final back = await saf.restore(item);
      expect(back.name, 'a (restored).jpg');
      expect(fake.bytesAt('${fake.root}/DCIM/a (restored).jpg'), [1, 2]);
      expect(await db.select(db.pendingFolderItems).get(), isEmpty);
    });

    test('restore recreates a deleted folder', () async {
      final f = await add('Old/Sub/a.jpg', [3]);
      final item = (await saf.trashBatch([f])).trashed.single;
      fake.removeDoc('${fake.uuid}:Old');
      final back = await saf.restore(item);
      expect(back.path, '${fake.root}/Old/Sub/a.jpg');
    });

    test('a provider that cannot move refuses; the file stays', () async {
      final f = await add('DCIM/a.jpg', [1]);
      fake.refuseMove = true;
      final r = await saf.trashBatch([f]);
      expect(r.failed[f.id]?.failure, FileOpFailure.pendingFolderUnavailable);
      expect(fake.existsPath('${fake.root}/DCIM/a.jpg'), isTrue);
    });

    test('purgeExpired deletes expired SAF items only', () async {
      final f = await add('DCIM/a.jpg', [1]);
      await saf.trashBatch([f]);
      expect(await folder.purgeExpired(), 0);
      now = now.add(const Duration(days: 8));
      expect(await folder.purgeExpired(), 1);
      expect(await db.select(db.pendingFolderItems).get(), isEmpty);
    });

    test('deleteFromTrash deletes now', () async {
      final f = await add('DCIM/a.jpg', [1]);
      final item = (await saf.trashBatch([f])).trashed.single;
      await saf.deleteFromTrash([item]);
      expect(await db.select(db.pendingFolderItems).get(), isEmpty);
      expect(fake.calls.where((c) => c.startsWith('delete')), hasLength(1));
    });

    test('PendingFolder leaves SAF rows alone', () async {
      final f = await add('DCIM/a.jpg', [1]);
      final item = (await saf.trashBatch([f])).trashed.single;
      final plain = PendingFolder(
        db: db,
        volumeRootOf: (_) => fake.root,
        retentionDays: () async => 7,
        clock: () => now.add(const Duration(days: 30)),
      );
      expect(await plain.purgeExpired(), 0);
      await expectLater(
        plain.restore(item.trashId.substring(8)),
        throwsA(
          isA<FileOpException>().having(
            (e) => e.failure,
            'failure',
            FileOpFailure.unsupported,
          ),
        ),
      );
      expect(await db.select(db.pendingFolderItems).get(), hasLength(1));
    });
  });

  group('SafChannel errors (U2 review #7)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel(SafChannel.name);
    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    test('a refused delete and a null rename throw ioError', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async => switch (call.method) {
              'delete' => false,
              _ => null,
            },
          );
      final c = SafChannel();
      final io = throwsA(
        isA<FileOpException>().having(
          (e) => e.failure,
          'failure',
          FileOpFailure.ioError,
        ),
      );
      await expectLater(c.delete('t', 'd'), io);
      await expectLater(c.rename('t', 'd', 'x.jpg'), io);
    });
  });
}
