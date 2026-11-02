import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/tables/pending_deletes_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/connect/data/remote_file_source.dart';
import 'package:kfm/features/connect/data/remote_source_provider.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/session/domain/remote_deck_root.dart';
import 'package:kfm/features/session/domain/session_source.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';
import 'fake_remote_http.dart';

final String _fp = 'cd' * 32;

class _Online extends Notifier<bool> {
  @override
  bool build() => false;

  void goOnline() => state = true;
}

final _online = NotifierProvider<_Online, bool>(_Online.new);

RemoteFileDto _f(int i) => RemoteFileDto(
  id: 'ms:$i',
  name: 'p$i.jpg',
  kind: FileKind.image,
  sizeBytes: 10,
  modifiedAtMs: 1000 + i,
  rootId: 'R1',
  relativeFolder: 'DCIM',
);

void main() {
  late AppDatabase db;
  late FakeFileSource files;
  late FakeRemoteHttp http;
  late ProviderContainer c;
  final served = [for (var i = 0; i < 30; i++) _f(i)];
  final sourceId = remoteSourceId(_fp);

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    files = FakeFileSource()..addFile('/s/DCIM/mine.jpg');
    http = FakeRemoteHttp()
      ..on('GET', ApiRoutes.files, (call) {
        final start = int.parse(call.query['cursor'] ?? '0');
        final end = (start + 10).clamp(0, served.length);
        return FilePageDto(
          items: served.sublist(start, end),
          nextCursor: end < served.length ? '$end' : null,
          total: call.query['cursor'] == null ? served.length : null,
        ).toJson();
      });
    c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        fileSourceProvider.overrideWithValue(files),
        permissionServiceProvider.overrideWithValue(FakePermissionService()),
        mediaChangesProvider.overrideWithValue(const Stream.empty()),
        remoteSourceProvider(_fp).overrideWith(
          (ref) => RemoteFileSource(
            peerFingerprint: _fp,
            http: () => ref.read(_online) ? http : null,
          ),
        ),
        remotePeerConnectedProvider(_fp)
            .overrideWith((ref) => ref.watch(_online)),
      ],
    );
    await c.read(mediaIndexerProvider).start();
    await c
        .read(sessionRepositoryProvider)
        .startRemote(
          _fp,
          const RemoteDeckRoot(rootId: 'R1', path: 'DCIM', device: 'Phone'),
        );
  });

  tearDown(() async {
    c.dispose();
    await db.close();
  });

  test('offline: the deck waits (no error); online: it fills and swipes '
      'queue remote deletes next to the local session', () async {
    final provider = swipeDeckForSourceProvider(sourceId);
    c.listen(provider, (_, _) {});
    final local = await c.read(swipeDeckControllerProvider.future);
    final waiting = await c.read(provider.future);
    expect(waiting.waiting, isTrue);
    expect(waiting.current, isNull);
    expect(waiting.session.sourceId, sourceId);
    expect(waiting.session.id, isNot(local.session.id));

    c.read(_online.notifier).goOnline();
    for (var i = 0; i < 20 && c.read(provider).value!.waiting; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final deck = c.read(provider).value!;
    expect(deck.waiting, isFalse);
    expect(deck.current!.id, 'remote:$_fp:ms:0');
    expect(deck.current!.folderPath, 'R1/DCIM');
    expect(deck.upcoming, hasLength(30));

    final ctl = c.read(provider.notifier);
    expect(ctl.apply(SwipeAction.trash), isTrue);
    expect(ctl.apply(SwipeAction.keep), isTrue);
    // P3 renames aren't offered for another device's files.
    expect(
      ctl.problemForAction(const SwipeAction(SwipeActionType.renameBatch)),
      isNotNull,
    );
    await c.read(dbWriteQueueProvider).flush();
    final rows = await db.select(db.pendingDeletes).get();
    expect(rows.single.fileId, 'remote:$_fp:ms:0');
    expect(rows.single.mode, 'trash');
    expect(rows.single.status, PendingDeleteStatus.queued);
    // The local deck is untouched.
    expect(
      c.read(swipeDeckControllerProvider).value!.session.id,
      local.session.id,
    );
    expect(c.read(swipeDeckControllerProvider).value!.swiped, 0);

    // Undo brings the remote file back; nothing reached the device.
    await ctl.undo();
    expect(c.read(provider).value!.current!.id, 'remote:$_fp:ms:1');
    await ctl.undo();
    expect(c.read(provider).value!.current!.id, 'remote:$_fp:ms:0');
    expect(await db.select(db.pendingDeletes).get(), isEmpty);
    expect(http.calls.where((call) => call.method == 'POST'), isEmpty);
  });

  test('a rebuilt deck skips files already swiped', () async {
    c.read(_online.notifier).goOnline();
    final provider = swipeDeckForSourceProvider(sourceId);
    c.listen(provider, (_, _) {});
    await c.read(provider.future);
    final ctl = c.read(provider.notifier);
    for (var i = 0; i < 3; i++) {
      ctl.apply(SwipeAction.keep);
    }
    await c.read(dbWriteQueueProvider).flush();
    c.invalidate(provider);
    final again = await c.read(provider.future);
    expect(again.current!.id, 'remote:$_fp:ms:3');
    expect(again.swiped, 3);
    expect(again.remaining, 27);
  });
}
