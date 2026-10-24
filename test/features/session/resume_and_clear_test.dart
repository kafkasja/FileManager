import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/tables/pending_deletes_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/session/domain/clear_session.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/domain/swipe_deck_state.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';

class _Declining extends FakeFileSource {
  bool decline = false;

  @override
  Future<TrashResult> trashBatch(List<FileRef> files) async => decline
      ? const TrashResult(trashed: [], failed: {}, userCancelled: true)
      : await super.trashBatch(files);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _Declining files;
  late DateTime t0;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    files = _Declining();
    t0 = DateTime.now().toUtc().subtract(const Duration(days: 1));
    for (var i = 0; i < 6; i++) {
      files.addFile(
        '/s/DCIM/p$i.jpg',
        modifiedAt: t0.subtract(Duration(minutes: 10 - i)),
      );
    }
  });

  tearDown(() => db.close());

  /// One "app process": its own providers over the shared DB + files.
  Future<ProviderContainer> launch() async {
    SwipeDeckController.debugResetRestoreNotice();
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        fileSourceProvider.overrideWithValue(files),
        permissionServiceProvider.overrideWithValue(FakePermissionService()),
        mediaChangesProvider.overrideWithValue(const Stream.empty()),
      ],
    );
    await c.read(mediaIndexerProvider).start();
    await c.read(swipeDeckControllerProvider.future);
    return c;
  }

  Future<void> close(ProviderContainer c) async {
    await c.read(sessionRepositoryProvider).flush();
    c.dispose();
  }

  SwipeDeckState deck(ProviderContainer c) =>
      c.read(swipeDeckControllerProvider).value!;

  test('a restart resumes right after the last swiped file', () async {
    final first = await launch();
    expect(deck(first).current!.name, 'p5.jpg');
    first.read(swipeDeckControllerProvider.notifier)
      ..swipe(SwipeDirection.right)
      ..swipe(SwipeDirection.left);
    await close(first);

    final second = await launch();
    addTearDown(second.dispose);
    expect(deck(second).current!.name, 'p3.jpg');
    expect(deck(second).swiped, 2);
    expect(deck(second).restored, isTrue);
    // Undo still walks back through the old history.
    await second.read(swipeDeckControllerProvider.notifier).undo();
    expect(deck(second).current!.name, 'p4.jpg');
  });

  test(
    'new photos are offered with a chip, not forced into the deck',
    () async {
      final first = await launch();
      first
          .read(swipeDeckControllerProvider.notifier)
          .swipe(SwipeDirection.right);
      await close(first);

      files.addFile('/s/DCIM/new.jpg', modifiedAt: DateTime.now().toUtc());
      final second = await launch();
      addTearDown(second.dispose);
      expect(deck(second).current!.name, 'p4.jpg');
      expect(deck(second).newFiles, 1);

      await second.read(swipeDeckControllerProvider.notifier).showNewFiles();
      expect(deck(second).current!.name, 'new.jpg');
      expect(deck(second).newFiles, 0);
    },
  );

  test('a photo added while a fresh deck is open shows the chip and '
      'updates the count (device bug 2026-10-24)', () async {
    final c = await launch();
    addTearDown(c.dispose);
    // Watched like the swipe screen does (unwatched providers are paused).
    c.listen(swipeDeckControllerProvider, (_, _) {});
    expect(deck(c).newFiles, 0);
    expect(deck(c).remaining, 6);

    files.addFile('/s/DCIM/live.jpg', modifiedAt: DateTime.now().toUtc());
    await c.read(mediaIndexerProvider).incremental();
    await Future<void>.delayed(const Duration(seconds: 2));

    expect(deck(c).current!.name, 'p5.jpg');
    expect(deck(c).newFiles, 1);
    expect(deck(c).remaining, 7);
    // Small library (window below the refill size): still not appended.
    expect(deck(c).upcoming.map((f) => f.name), isNot(contains('live.jpg')));

    // A second change must arrive too (equal `void` events were dropped).
    files.addFile(
      '/s/DCIM/live2.jpg',
      modifiedAt: DateTime.now().toUtc().add(const Duration(seconds: 1)),
    );
    await c.read(mediaIndexerProvider).incremental();
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(deck(c).newFiles, 2);
    expect(deck(c).remaining, 8);

    await c.read(swipeDeckControllerProvider.notifier).showNewFiles();
    expect(deck(c).current!.name, 'live2.jpg');
    expect(deck(c).newFiles, 0);
  });

  test('no active session: a fresh one starts from the top', () async {
    final c = await launch();
    addTearDown(c.dispose);
    expect(deck(c).current!.name, 'p5.jpg');
    expect(deck(c).restored, isFalse);
  });

  group('Clear… (SE3)', () {
    test('reset action buttons, then undo', () async {
      final c = await launch();
      addTearDown(c.dispose);
      const custom = SwipeLayout(
        directions: {SwipeDirection.up: SwipeAction.keep},
      );
      await c
          .read(sessionRepositoryProvider)
          .saveLayout(deck(c).session.id, custom);
      c.invalidate(swipeDeckControllerProvider);
      await c.read(swipeDeckControllerProvider.future);

      final controller = c.read(swipeDeckControllerProvider.notifier);
      final result = await controller.clear(
        const ClearRequest(resetLayout: true),
      );
      expect(result.layoutBefore, custom);
      expect(deck(c).session.layout, SwipeLayout.basic);
      await controller.undoLayoutReset(result.layoutBefore!);
      expect(deck(c).session.layout, custom);
    });

    test('new session commits pending deletes without asking', () async {
      final c = await launch();
      addTearDown(c.dispose);
      final controller = c.read(swipeDeckControllerProvider.notifier);
      final oldId = deck(c).session.id;
      controller
        ..swipe(SwipeDirection.left)
        ..swipe(SwipeDirection.left);
      final result = await controller.clear(
        const ClearRequest(newSession: true),
      );
      expect(result.sessionEnded, isTrue);
      expect(result.commit.committed, 2);
      expect(files.trash, hasLength(2));
      await c.read(swipeDeckControllerProvider.future);
      expect(deck(c).session.id, isNot(oldId));
      expect(deck(c).swiped, 0);
    });

    test(
      'a declined delete dialog keeps the session and its deletes',
      () async {
        final c = await launch();
        addTearDown(c.dispose);
        final controller = c.read(swipeDeckControllerProvider.notifier);
        final id = deck(c).session.id;
        controller.swipe(SwipeDirection.left);
        files.decline = true;
        final result = await controller.clear(
          const ClearRequest(newSession: true),
        );
        expect(result.sessionEnded, isFalse);
        expect((await c.read(sessionRepositoryProvider).active())!.id, id);
        final rows = await db.select(db.pendingDeletes).get();
        expect(rows.single.status, PendingDeleteStatus.queued);
      },
    );
  });
}
