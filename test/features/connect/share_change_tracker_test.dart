import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/index/media_change_source.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/share_change_tracker.dart';
import 'package:kfm/features/connect/data/share_scope_store.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';

import '../../core/files/fake_file_source.dart';

const _root = '/storage/emulated/0';

SharedRoot _r(String id, String rel, {bool readOnly = false}) =>
    SharedRoot(id: id, path: '$_root/$rel', label: rel, readOnly: readOnly);

void main() {
  late AppDatabase db;
  late MediaIndexDao dao;
  late ShareScopeStore scopes;
  late FakeFileSource files;
  late StreamController<int> indexTicks;
  late StreamController<FilesTableChange> filesEvents;
  late List<(FilesTableChange, List<String>)> forwarded;
  late ShareChangeTracker tracker;
  late DateTime now;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = MediaIndexDao(db);
    scopes = ShareScopeStore(sessions: ClientSessionStore());
    files = FakeFileSource();
    indexTicks = StreamController<int>.broadcast();
    filesEvents = StreamController<FilesTableChange>.broadcast();
    forwarded = [];
    now = DateTime.utc(2026, 11);
    tracker = ShareChangeTracker(
      dao: () => dao,
      scopes: scopes,
      canSeeAllFiles: () => true,
      indexChanges: () => indexTicks.stream,
      filesChanges: () => filesEvents.stream,
      onFileChange: (c, roots) => forwarded.add((c, roots)),
    );
    await dao.upsertBatch(
      [files.addFile('$_root/DCIM/a.jpg'), files.addFile('$_root/Music/m.mp3')],
      1,
      now: now,
    );
  });

  tearDown(() async {
    await tracker.stop();
    await indexTicks.close();
    await filesEvents.close();
    await files.dispose();
    await db.close();
  });

  Future<void> index(String path) async {
    now = now.add(const Duration(seconds: 1));
    await dao.upsertBatch([files.addFile(path)], 1, now: now);
    indexTicks.add(0);
    await pumpEventQueue();
  }

  test(
    'a change outside the roots keeps the token; inside changes it',
    () async {
      tracker.start();
      scopes.set('fp', ShareScope([_r('cam', 'DCIM')]));
      await pumpEventQueue();
      final t0 = await tracker.tokenFor('fp');
      expect(t0, isNotNull);
      expect(await tracker.tokenFor('fp'), t0, reason: 'cached, stable');

      await index('$_root/Music/n.mp3');
      expect(await tracker.tokenFor('fp'), t0);

      await index('$_root/DCIM/sub/b.jpg');
      final t1 = await tracker.tokenFor('fp');
      expect(t1, isNot(t0));

      await dao.deleteIds(['path:$_root/DCIM/a.jpg']);
      indexTicks.add(0);
      await pumpEventQueue();
      expect(await tracker.tokenFor('fp'), isNot(t1));
    },
  );

  test('a scope edit changes the token; tokens are per client', () async {
    tracker.start();
    scopes
      ..set('a', ShareScope([_r('cam', 'DCIM')]))
      ..set('b', ShareScope([_r('cam', 'DCIM')]));
    await pumpEventQueue();
    final a0 = await tracker.tokenFor('a');
    final b0 = await tracker.tokenFor('b');
    scopes.set('a', ShareScope([_r('cam', 'DCIM'), _r('mus', 'Music')]));
    await pumpEventQueue();
    expect(await tracker.tokenFor('a'), isNot(a0));
    expect(await tracker.tokenFor('b'), b0);
    // Read-only toggles count too.
    final a1 = await tracker.tokenFor('a');
    scopes.set(
      'a',
      ShareScope([_r('cam', 'DCIM', readOnly: true), _r('mus', 'Music')]),
    );
    await pumpEventQueue();
    expect(await tracker.tokenFor('a'), isNot(a1));
  });

  test('stopped: no observers, tokens computed fresh', () async {
    scopes.set('fp', ShareScope([_r('cam', 'DCIM')]));
    final t0 = await tracker.tokenFor('fp');
    await dao.upsertBatch([files.addFile('$_root/DCIM/c.jpg')], 1);
    expect(await tracker.tokenFor('fp'), isNot(t0));
    expect(filesEvents.hasListener, isFalse);
    expect(indexTicks.hasListener, isFalse);
  });

  test('Files events go to the indexer with the shared folders (never a '
      'whole volume) only while started', () async {
    tracker.start();
    scopes
      ..set('a', ShareScope([_r('cam', 'DCIM'), _r('dl', 'Download')]))
      ..set(
        'b',
        const ShareScope([
          SharedRoot(id: 'all', path: _root, label: 'All', readOnly: false),
        ]),
      );
    await pumpEventQueue();
    filesEvents.add(const FilesTableChange(type: 'delete'));
    await pumpEventQueue();
    expect(forwarded.single.$2.toSet(), {'$_root/DCIM', '$_root/Download'});
    await tracker.stop();
    filesEvents.add(const FilesTableChange(type: 'delete'));
    await pumpEventQueue();
    expect(forwarded, hasLength(1));
    expect(filesEvents.hasListener, isFalse);
  });

  test(
    'stopped: a failing digest gives a null token, never an error',
    () async {
      scopes.set('fp', ShareScope([_r('cam', 'DCIM')]));
      await db.close();
      expect(await tracker.tokenFor('fp'), isNull);
      db = AppDatabase(NativeDatabase.memory());
    },
  );
}
