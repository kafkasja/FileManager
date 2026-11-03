import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/cloud/data/cloud_items_repository.dart';
import 'package:kfm/features/cloud/domain/cloud_state.dart';
import 'package:kfm/features/tags/data/file_id_rekeyer.dart';

import 'cloud_test_seed.dart';

FileRef _f(String id, {int size = 100, int ms = 5000}) => FileRef(
  id: id,
  uri: 'content://$id',
  name: 'a.jpg',
  kind: FileKind.image,
  sizeBytes: size,
  modifiedAt: DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
  folderPath: '/storage/emulated/0/DCIM',
  origin: FileOrigin.local,
);

void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late FileIdRekeyer rekeyer;
  late CloudItemsRepository items;
  late int drive;
  late int box;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    rekeyer = FileIdRekeyer(db, queue);
    items = CloudItemsRepository(db, queue);
    drive = await seedDestination(db, 'Drive');
    box = await seedDestination(db, 'Box');
  });
  tearDown(() async {
    await queue.flush();
    await db.close();
  });

  Future<List<CloudItemRow>> rows() => db.select(db.cloudItems).get();

  test('plain move: rows follow the new id', () async {
    await seedUpload(db, _f('old'), drive);
    await seedUpload(db, _f('old'), box);
    await rekeyer.rekey('old', 'new', newModifiedMs: 5000, newSizeBytes: 100);
    expect((await rows()).map((r) => r.fileId), ['new', 'new']);
  });

  test('collision: the older upload goes (old row newer)', () async {
    final oldRow = await seedUpload(db, _f('old'), drive, uploadedAtMs: 20);
    await seedUpload(db, _f('new'), drive, uploadedAtMs: 10);
    await rekeyer.rekey('old', 'new');
    final all = await rows();
    expect(all.single.id, oldRow);
    expect(all.single.fileId, 'new');
  });

  test('collision: the older upload goes (new row newer)', () async {
    await seedUpload(db, _f('old'), drive, uploadedAtMs: 10);
    final newRow = await seedUpload(db, _f('new'), drive, uploadedAtMs: 20);
    await seedUpload(db, _f('old'), box, uploadedAtMs: 5);
    await rekeyer.rekey('old', 'new');
    final all = await rows();
    expect(all.map((r) => (r.destinationId, r.fileId)), [
      (drive, 'new'),
      (box, 'new'),
    ]);
    expect(all.first.id, newRow);
  });

  test('a move that changes the modified time keeps onCloud', () async {
    await seedUpload(db, _f('old'), drive);
    // A changed file (other size) stays "changed since upload".
    await seedUpload(db, _f('old', size: 50), box);
    await rekeyer.rekey('old', 'new', newModifiedMs: 7777, newSizeBytes: 100);
    final facts = (await items.uploadFactsFor(['new']))['new']!;
    expect(
      cloudBadgeFor(
        uploads: facts,
        localSizeBytes: 100,
        localModifiedAtMs: 7777,
      ),
      CloudBadge.onCloud,
    );
    final byDest = {for (final r in await rows()) r.destinationId: r};
    expect(byDest[drive]!.sourceModifiedAtMs, 7777);
    expect(byDest[box]!.sourceModifiedAtMs, 5000);
  });

  test('the X3 runner and P2 rekeyer both re-keying is harmless', () async {
    await seedUpload(db, _f('old'), drive);
    await Future.wait([
      rekeyer.rekey('old', 'new', newModifiedMs: 6000, newSizeBytes: 100),
      items.rekey('old', 'new', newModifiedMs: 6000, newSizeBytes: 100),
    ]);
    final r = (await rows()).single;
    expect((r.fileId, r.sourceModifiedAtMs), ('new', 6000));
  });
}
