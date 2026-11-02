import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/cross_place_ops.dart';
import 'package:kfm/core/files/file_ids.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';

import 'file_source_contract.dart';

import 'routing_setup.dart';

class _RoutingHarness implements ContractHarness {
  final Setup s = Setup();

  @override
  FileSource get source => s.router;

  @override
  String get root => '${Setup.internal}/test';

  @override
  Future<FileRef> addFile(String path, List<int> bytes) async =>
      s.android.addFile(path, bytes: bytes);

  @override
  Future<void> removeExternally(FileRef f) async =>
      s.android.removeExternally(f.id);

  @override
  Future<void> dispose() => s.dispose();
}

void main() {
  fileSourceContract('RoutingFileSource (device storage)', () async {
    final h = _RoutingHarness();
    h.s.android.addFolder(h.root);
    return h;
  });

  group('RoutingFileSource', () {
    late Setup s;
    setUp(() => s = Setup());
    tearDown(() => s.dispose());

    test('single files route by id prefix', () async {
      final local = s.android.addFile('${Setup.internal}/Pictures/a.jpg');
      final usb = await s.safFile('DCIM/b.jpg', [5]);
      expect((await s.router.stat(local.id))?.name, 'a.jpg');
      expect((await s.router.stat(usb.id))?.name, 'b.jpg');
      expect(
        [for (final c in await s.router.openRead(usb).toList()) ...c],
        [5],
      );
      final cam = await s.router.stat(mtpId('/dev/bus/usb/1', 1, 7));
      expect(cam?.name, 'IMG_7.JPG');
      expect(cam?.folderPath, '/mtp/1/DCIM');
    });

    test('folders under a SAF root go to SAF', () async {
      s.safFake.addFolder('${s.usb}/Photos');
      final path = await s.router.createFolder('${s.usb}/Photos', 'New');
      expect(path, '${s.usb}/Photos/New');
      expect(s.safFake.existsPath(path), isTrue);
      expect(s.router.sourceForFolder('${s.usb}/Photos'), same(s.saf));
      expect(
        s.router.sourceForFolder('${Setup.internal}/DCIM'),
        same(s.android),
      );
    });

    test('batches split by source and merge', () async {
      final local = s.android.addFile('${Setup.internal}/Pictures/a.jpg');
      final usb = await s.safFile('DCIM/b.jpg', [5]);
      final r = await s.router.trashBatch([local, usb]);
      expect(r.trashed.map((t) => t.original.id), [local.id]);
      // No SAF pending folder in this setup: refused, file untouched.
      expect(r.failed.keys, [usb.id]);
      expect(await s.router.stat(usb.id), isNotNull);
    });

    test('idChanges merges every source', () async {
      final changes = <FileIdChange>[];
      final sub = s.router.idChanges.listen(changes.add);
      addTearDown(sub.cancel);
      final local = s.android.addFile('${Setup.internal}/Pictures/a.jpg');
      final usb = await s.safFile('DCIM/b.jpg', [5]);
      await s.router.rename(local, 'c.jpg');
      await s.router.rename(usb, 'd.jpg');
      await Future<void>.delayed(Duration.zero);
      expect(changes.map((c) => c.oldId), [local.id, usb.id]);
    });

    test('isCrossPlace: other volume or other source', () async {
      final local = s.android.addFile('${Setup.internal}/Pictures/a.jpg');
      final usb = await s.safFile('DCIM/b.jpg', [5]);
      expect(s.router.isCrossPlace(local, '${Setup.internal}/DCIM'), isFalse);
      expect(s.router.isCrossPlace(local, '${s.usb}/DCIM'), isTrue);
      expect(s.router.isCrossPlace(usb, '${s.usb}/Other'), isFalse);
      expect(s.router.isCrossPlace(usb, '${Setup.internal}/DCIM'), isTrue);
      expect(s.router.placeOfFile(usb), 'ABCD-1234');
      expect(s.router.placeOfFile(local), 'primary');
    });

    test('copy to another place is verified; the original stays', () async {
      final local = s.android.addFile(
        '${Setup.internal}/Pictures/a.jpg',
        bytes: [1, 2, 3],
      );
      s.safFake.addFolder('${s.usb}/Photos');
      final copy = await s.router.copy(local, '${s.usb}/Photos');
      expect(copy.id, startsWith('saf:'));
      expect(s.safFake.bytesAt('${s.usb}/Photos/a.jpg'), [1, 2, 3]);
      expect(await s.router.stat(local.id), isNotNull);
      expect(s.staging.listSync(), isEmpty, reason: 'part deleted');
    });

    test(
      'move from device storage to the stick trashes the original',
      () async {
        final changes = <FileIdChange>[];
        final sub = s.router.idChanges.listen(changes.add);
        addTearDown(sub.cancel);
        final local = s.android.addFile(
          '${Setup.internal}/Pictures/a.jpg',
          bytes: [9, 8],
        );
        s.safFake.addFolder('${s.usb}/Photos');
        final moved = await s.router.move(local, '${s.usb}/Photos');
        expect(s.safFake.bytesAt('${s.usb}/Photos/a.jpg'), [9, 8]);
        expect(await s.router.stat(local.id), isNull);
        expect(s.android.trash, hasLength(1));
        await Future<void>.delayed(Duration.zero);
        expect(changes.single.oldId, local.id);
        expect(changes.single.newRef.id, moved.id);
      },
    );

    test('a checksum mismatch deletes the copy and keeps the source', () async {
      final local = s.android.addFile(
        '${Setup.internal}/Pictures/a.jpg',
        bytes: [1, 2, 3],
      );
      s.safFake
        ..addFolder('${s.usb}/Photos')
        ..corruptNextImport = true;
      await expectLater(
        s.router.move(local, '${s.usb}/Photos'),
        throwsA(
          isA<FileOpException>().having(
            (e) => e.failure,
            'failure',
            FileOpFailure.ioError,
          ),
        ),
      );
      expect(s.safFake.existsPath('${s.usb}/Photos/a.jpg'), isFalse);
      expect(await s.router.stat(local.id), isNotNull);
      expect(s.android.trash, isEmpty);
    });

    test('cameras are read-only: only copy is supported', () async {
      final cam = (await s.router.stat(mtpId('/dev/bus/usb/1', 1, 7)))!;
      expect(s.router.supports(FileOp.copy, cam), isTrue);
      expect(s.router.supports(FileOp.move, cam), isFalse);
      expect(s.router.supports(FileOp.rename, cam), isFalse);
      expect(s.router.supports(FileOp.trash, cam), isFalse);
      final copy = await s.router.copy(cam, '${Setup.internal}/Pictures');
      expect(s.android.bytesOf(copy.id), [7, 7]);
    });
  });

  group('CrossPlaceOps', () {
    test('mismatch on a path target (hash override) throws', () async {
      final s = Setup(hashRef: (f, src) async => 'not-the-hash');
      addTearDown(s.dispose);
      final usb = await s.safFile('DCIM/b.jpg', [4, 4]);
      await expectLater(
        s.router.crossPlace.copyVerified(usb, '${Setup.internal}/Pictures'),
        throwsA(isA<CopyVerificationException>()),
      );
      expect(
        s.android.files.where(
          (f) => f.folderPath == '${Setup.internal}/Pictures',
        ),
        isEmpty,
      );
    });
  });
}
