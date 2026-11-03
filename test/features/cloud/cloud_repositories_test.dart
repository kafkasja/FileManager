import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/cloud/data/cloud_destinations_repository.dart';
import 'package:kfm/features/cloud/data/cloud_items_repository.dart';
import 'package:kfm/features/cloud/domain/cloud_destination.dart';

import 'fake_cloud.dart';

FileRef _file(String id, {int size = 3}) => FileRef(
  id: id,
  uri: '/storage/emulated/0/DCIM/$id.jpg',
  name: '$id.jpg',
  kind: FileKind.image,
  sizeBytes: size,
  modifiedAt: DateTime.utc(2026, 1, 1),
  folderPath: '/storage/emulated/0/DCIM',
  origin: FileOrigin.local,
);

void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late FakeCloudTrees trees;
  late Set<String> protectedTrees;
  late CloudDestinationsRepository dests;
  late CloudItemsRepository items;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    trees = FakeCloudTrees();
    protectedTrees = {};
    dests = CloudDestinationsRepository(
      db,
      queue,
      platform: trees,
      protectedTrees: () async => protectedTrees,
    );
    items = CloudItemsRepository(db, queue);
  });
  tearDown(() async {
    await queue.flush();
    await db.close();
  });

  group('destinations', () {
    test('add from the picker persists the grant and labels it', () async {
      trees.nextPick = 'content://drive/tree/root';
      expect(await dests.addFromPicker(), CloudAddOutcome.added);
      final list = await dests.watchActive().first;
      expect(list.single.label, 'Google Drive › Photos');
      expect(list.single.provider, CloudProviderGuess.googleDrive);
      expect(trees.persisted, {'content://drive/tree/root'});
    });

    test('cancelled or refused picks keep nothing', () async {
      expect(await dests.addFromPicker(), CloudAddOutcome.cancelled);
      trees
        ..nextPick = 'content://x/tree/a'
        ..persistFails = true;
      expect(await dests.addFromPicker(), CloudAddOutcome.failed);
      expect(await dests.watchActive().first, isEmpty);
    });

    test('remove is soft; re-adding re-activates the same row', () async {
      final id = await dests.add(
        location: 'content://t',
        label: 'Drive',
        provider: CloudProviderGuess.googleDrive,
      );
      trees.persisted.add('content://t');
      await items.enqueue([_file('ms:1')], id, CloudItemMode.copy);
      await dests.remove(id, forgetUploads: false);
      expect(await dests.watchActive().first, isEmpty);
      expect(await dests.hasActive(), isFalse);
      final row = await items.byId(1);
      expect(row!.status, CloudItemStatus.failed);
      expect(row.error, CloudItemErrors.destinationRemoved);
      expect(trees.persisted, isEmpty, reason: 'grant released');

      final again = await dests.add(
        location: 'content://t',
        label: 'Drive 2',
        provider: CloudProviderGuess.googleDrive,
      );
      expect(again, id);
      expect((await dests.byId(id))!.isActive, isTrue);
      expect(await items.byId(1), isNotNull, reason: 'history kept');
    });

    test('forget uploads deletes its rows', () async {
      final id = await dests.add(
        location: 'content://t',
        label: 'Drive',
        provider: CloudProviderGuess.googleDrive,
      );
      await items.enqueue([_file('ms:1')], id, CloudItemMode.copy);
      await dests.remove(id, forgetUploads: true);
      expect(await items.byId(1), isNull);
    });

    test('a U1 volume grant is never released', () async {
      final id = await dests.add(
        location: 'content://shared',
        label: 'USB',
        provider: CloudProviderGuess.other,
      );
      trees.persisted.add('content://shared');
      protectedTrees.add('content://shared');
      await dests.remove(id, forgetUploads: false);
      expect(trees.persisted, {'content://shared'});
    });

    test(
      'health: lost grant = needs reconnecting; no call when empty',
      () async {
        expect(await dests.health(const []), isEmpty);
        expect(trees.calls, isEmpty);
        final a = await dests.add(
          location: 'content://a',
          label: 'A',
          provider: CloudProviderGuess.oneDrive,
        );
        final b = await dests.add(
          location: 'content://b',
          label: 'B',
          provider: CloudProviderGuess.oneDrive,
        );
        trees.persisted.add('content://a');
        final h = await dests.health(await dests.watchActive().first);
        expect(h[a], CloudDestinationHealth.ok);
        expect(h[b], CloudDestinationHealth.needsReconnecting);
      },
    );

    test('labels are clamped to 60 characters', () {
      final long = 'x' * 80;
      expect(defaultCloudLabel(CloudProviderGuess.other, long).length, 60);
      expect(defaultCloudLabel(CloudProviderGuess.dropbox, null), 'Dropbox');
      expect(
        guessProvider('com.microsoft.skydrive.content.StorageAccessProvider'),
        CloudProviderGuess.oneDrive,
      );
    });
  });

  group('items', () {
    late int dest;
    setUp(() async {
      dest = await dests.add(
        location: 'content://t',
        label: 'Drive',
        provider: CloudProviderGuess.googleDrive,
      );
    });

    test('enqueue upserts per (file, destination); active rows stay', () async {
      final ids = await items.enqueue(
        [_file('ms:1'), _file('ms:2')],
        dest,
        CloudItemMode.copy,
      );
      expect(ids, hasLength(2));
      expect(
        await items.startUploading(ids[0], sizeBytes: 3, sourceModifiedAtMs: 1),
        isTrue,
      );
      // Again while uploading: left alone.
      final again = await items.enqueue(
        [_file('ms:1')],
        dest,
        CloudItemMode.move,
      );
      expect(again, [ids[0]]);
      expect((await items.byId(ids[0]))!.status, CloudItemStatus.uploading);
      // Finished, then again: back to queued with the new mode.
      await items.markUploading(ids[0], 'content://t/doc/1');
      await items.markHandedToProvider(ids[0], 'ab', 5);
      await items.enqueue([_file('ms:1')], dest, CloudItemMode.move);
      final row = (await items.byId(ids[0]))!;
      expect(row.status, CloudItemStatus.queued);
      expect(row.mode, CloudItemMode.move);
      expect(row.remoteUri, isNull);
      expect(row.sha256, isNull);
    });

    test('resetInterrupted returns partial documents', () async {
      final ids = await items.enqueue(
        [_file('ms:1')],
        dest,
        CloudItemMode.copy,
      );
      await items.startUploading(ids[0], sizeBytes: 3, sourceModifiedAtMs: 1);
      await items.markUploading(ids[0], 'content://t/doc/1');
      expect(await items.hasPending(), isTrue);
      expect(await items.resetInterrupted(), ['content://t/doc/1']);
      final row = (await items.byId(ids[0]))!;
      expect(row.status, CloudItemStatus.queued);
      expect(row.remoteUri, isNull);
    });

    test('nextQueued skips removed destinations', () async {
      await items.enqueue([_file('ms:1')], dest, CloudItemMode.copy);
      expect(await items.nextQueued(), isNotNull);
      await dests.remove(dest, forgetUploads: false);
      expect(await items.nextQueued(), isNull);
    });

    test('mark* only change uploading rows', () async {
      final ids = await items.enqueue(
        [_file('ms:1')],
        dest,
        CloudItemMode.copy,
      );
      expect(await items.markHandedToProvider(ids[0], 'ab', 1), isFalse);
      expect(await items.markFailed(ids[0], 'cancelled'), isTrue);
      expect(await items.markFailed(ids[0], 'again'), isFalse);
      final row = (await items.byId(ids[0]))!;
      expect(row.attempts, 1);
      expect(row.error, 'cancelled');
    });
  });
}
