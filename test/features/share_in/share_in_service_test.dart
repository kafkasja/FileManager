import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_ids.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/routing_file_source.dart';
import 'package:kfm/features/share_in/data/share_in_channel.dart';
import 'package:kfm/features/share_in/data/share_in_service.dart';

import '../../core/files/fake_file_source.dart';

class FakeShareInPlatform implements ShareInPlatform {
  Map<Object?, Object?>? pending;
  Exception? takeError;
  final copies = <String, Map<Object?, Object?>>{};
  final copyCalls = <String>[];
  final cancelled = <String>[];
  final controller = StreamController<ShareInEvent>.broadcast();

  @override
  Future<Map<Object?, Object?>?> takePending() async {
    if (takeError case final e?) throw e;
    final p = pending;
    pending = null;
    return p;
  }

  @override
  Future<Map<Object?, Object?>> copyItem({
    required String batchId,
    required int receivedAtMs,
    required String uri,
  }) async {
    copyCalls.add(uri);
    return copies[uri] ?? const {'kind': 'failed', 'error': 'noAccess'};
  }

  @override
  Future<void> cancel(String batchId) async => cancelled.add(batchId);

  @override
  Future<String> root() async => '/nope';

  @override
  Stream<ShareInEvent> events() => controller.stream;
}

const _copyRoot = '/data/user/0/com.kaf.kfm/files/shared_in/1000';

void main() {
  late FakeFileSource files;
  late FakeShareInPlatform platform;

  setUp(() {
    files = FakeFileSource();
    platform = FakeShareInPlatform();
  });
  tearDown(() async {
    await platform.controller.close();
    await files.dispose();
  });

  FileRef media(int id, String name) {
    final f = files.addFile('/storage/emulated/0/DCIM/$name', bytes: [1, 2]);
    // The fake keys files by `path:`; a share resolves by MediaStore id.
    final ms = f.copyWith(id: 'ms:$id');
    files
      ..removeExternally(f.id)
      ..putRef(ms);
    return ms;
  }

  Map<Object?, Object?> batch(List<Map<Object?, Object?>> items) => {
    'id': 'share-1000',
    'receivedAtMs': 1000,
    'items': items,
    'notFiles': items.isEmpty,
  };

  group('ShareInResolver', () {
    test(
      'media items resolve by id (same name + size stay separate)',
      () async {
        final a = media(11, 'a.jpg');
        final b = media(12, 'a.jpg');
        final r = await ShareInResolver(platform, files).resolve(
          batch([
            {'kind': 'media', 'id': 11, 'uri': 'content://media/x/11'},
            {'kind': 'media', 'id': 12, 'uri': 'content://media/x/12'},
          ]),
        );
        expect(r.files.map((f) => f.id), [a.id, b.id]);
        expect(r.copiedIds, isEmpty);
        expect(platform.copyCalls, isEmpty);
      },
    );

    test('a media id KFM cannot see falls back to a copy', () async {
      final copy = files.addFile('$_copyRoot/c.jpg', bytes: [1]);
      platform.copies['content://media/x/99'] = {
        'kind': 'copy',
        'path': copy.path,
      };
      final r = await ShareInResolver(platform, files).resolve(
        batch([
          {'kind': 'media', 'id': 99, 'uri': 'content://media/x/99'},
        ]),
      );
      expect(platform.copyCalls, ['content://media/x/99']);
      expect(r.files.single.id, copy.id);
      expect(r.isCopy(r.files.single), isTrue);
    });

    test('failed items are counted; all failed is an error', () async {
      final copy = files.addFile('$_copyRoot/d.pdf', bytes: [1]);
      final r = await ShareInResolver(platform, files).resolve(
        batch([
          {'kind': 'copy', 'path': copy.path},
          {'kind': 'failed', 'error': 'noAccess'},
        ]),
      );
      expect(r.files, hasLength(1));
      expect(r.failedCount, 1);
      await expectLater(
        ShareInResolver(platform, files).resolve(
          batch([
            {'kind': 'failed', 'error': 'noSpace'},
          ]),
        ),
        throwsA(
          isA<ShareInFailedException>().having(
            (e) => e.noSpace,
            'noSpace',
            true,
          ),
        ),
      );
    });

    test('text only → notFiles, no files', () async {
      final r = await ShareInResolver(platform, files).resolve(batch([]));
      expect(r.files, isEmpty);
      expect(r.skippedNotFiles, isTrue);
    });
  });

  group('pendingSharedBatchProvider', () {
    ProviderContainer container() {
      final c = ProviderContainer(
        overrides: [
          shareInPlatformProvider.overrideWithValue(platform),
          fileSourceProvider.overrideWithValue(files),
        ],
      );
      addTearDown(c.dispose);
      c.listen(pendingSharedBatchProvider, (_, _) {});
      return c;
    }

    test('takes the cold-start batch', () async {
      final f = media(5, 'x.jpg');
      platform.pending = batch([
        {'kind': 'media', 'id': 5, 'uri': 'u'},
      ]);
      final c = container();
      await pumpEventQueue();
      final s = c.read(pendingSharedBatchProvider);
      expect(s.batchId, 'share-1000');
      expect(s.batch.value!.files.single, f);
    });

    test('started → loading; ready → resolved; ids follow moves', () async {
      final c = container();
      await pumpEventQueue();
      platform.controller.add(const ShareInStarted('share-1000', count: 1));
      await pumpEventQueue();
      expect(c.read(pendingSharedBatchProvider).batch.isLoading, isTrue);

      final f = media(5, 'x.jpg');
      platform.pending = batch([
        {'kind': 'media', 'id': 5, 'uri': 'u'},
      ]);
      platform.controller.add(const ShareInReady('share-1000'));
      await pumpEventQueue();
      expect(c.read(pendingSharedBatchProvider).batch.value!.files, [f]);

      final moved = f.copyWith(id: 'ms:6', folderPath: '/storage/emulated/0/P');
      files.emitIdChange(FileIdChange(f.id, moved));
      await pumpEventQueue();
      expect(c.read(pendingSharedBatchProvider).batch.value!.files, [moved]);

      c.read(pendingSharedBatchProvider.notifier).dismiss();
      expect(c.read(pendingSharedBatchProvider).batchId, isNull);
    });

    test('a platform error propagates to the state', () async {
      platform.takeError = Exception('boom');
      final c = container();
      await pumpEventQueue();
      expect(c.read(pendingSharedBatchProvider).batch.hasError, isTrue);
    });
  });

  test('shared-in copies count as the primary place', () {
    expect(isSharedInCopyPath('$_copyRoot/a.jpg'), isTrue);
    expect(
      isSharedInCopyPath('/data/data/com.kaf.kfm/files/shared_in/1/a'),
      isTrue,
    );
    expect(isSharedInCopyPath('/storage/emulated/0/shared_in/1/a'), isFalse);
    expect(placeIdOfPath('$_copyRoot/a.jpg'), 'primary');
    expect(placeIdOfPath('/data/user/0/com.kaf.kfm/files/other'), '/data');
  });

  test('cleanup deletes batch folders older than 7 days', () async {
    final root = Directory.systemTemp.createTempSync('kfm_shared_in');
    addTearDown(() => root.deleteSync(recursive: true));
    final now = DateTime.utc(2026, 11, 2);
    final old = now.subtract(const Duration(days: 8)).millisecondsSinceEpoch;
    final fresh = now.subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    File('${root.path}/$old/a.jpg').createSync(recursive: true);
    File('${root.path}/$fresh/b.jpg').createSync(recursive: true);
    Directory('${root.path}/notanumber').createSync();
    expect(await purgeSharedInCopies(root, now: now), 1);
    expect(Directory('${root.path}/$old').existsSync(), isFalse);
    expect(Directory('${root.path}/$fresh').existsSync(), isTrue);
    expect(Directory('${root.path}/notanumber').existsSync(), isTrue);
  });
}
