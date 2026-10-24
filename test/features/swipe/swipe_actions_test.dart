import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/domain/swipe_deck_state.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/undo/domain/undo_service.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeFileSource files;
  late ProviderContainer c;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    files = FakeFileSource()
      ..addFolder('/s/Holiday')
      ..addFolder('/s/Copies');
    for (var i = 0; i < 4; i++) {
      files.addFile(
        '/s/DCIM/p$i.jpg',
        modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
      );
    }
    SwipeDeckController.debugResetRestoreNotice();
    c =
        ProviderContainer(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              fileSourceProvider.overrideWithValue(files),
              permissionServiceProvider.overrideWithValue(
                FakePermissionService(),
              ),
              mediaChangesProvider.overrideWithValue(const Stream.empty()),
            ],
          )
          // Watched like the app/screen do (unwatched providers are paused).
          ..listen(swipeDeckControllerProvider, (_, _) {})
          ..listen(fileIdRekeyerProvider, (_, _) {})
          ..listen(tagsByIdProvider, (_, _) {});
    await c.read(mediaIndexerProvider).start();
    await c.read(swipeDeckControllerProvider.future);
  });

  tearDown(() async {
    await c.read(sessionRepositoryProvider).flush();
    c.dispose();
    await db.close();
  });

  SwipeDeckState deck() => c.read(swipeDeckControllerProvider).value!;
  SwipeDeckController notifier() =>
      c.read(swipeDeckControllerProvider.notifier);

  Future<void> useRight(SwipeAction action) async {
    final layout = SwipeLayout.basic.withDirection(
      SwipeDirection.right,
      action,
    );
    await c
        .read(sessionRepositoryProvider)
        .saveLayout(deck().session.id, layout);
    await notifier().reloadSession();
  }

  /// Background move/copy and queued writes are done.
  Future<void> settle() async {
    await c.read(historyLockProvider).run(() async {});
    await c.read(dbWriteQueueProvider).flush();
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  Future<List<SessionActionRow>> actions() async {
    await c.read(dbWriteQueueProvider).flush();
    return await db.select(db.sessionActions).get();
  }

  test('move to a folder, then undo puts it back', () async {
    await useRight(
      const SwipeAction(SwipeActionType.moveTo, targetFolder: '/s/Holiday'),
    );
    final swiped = deck().current!;
    expect(notifier().swipe(SwipeDirection.right), isTrue);
    await settle();

    expect(await files.stat(swiped.id), isNull);
    final moved = await files.stat('path:/s/Holiday/${swiped.name}');
    expect(moved, isNotNull);
    expect(
      (await c.read(mediaIndexDaoProvider).byId(moved!.id))?.folderPath,
      '/s/Holiday',
    );
    final rows = await actions();
    expect(rows.single.fileId, moved.id);
    expect(deck().current!.id, isNot(swiped.id));

    final outcome = await notifier().undo();
    expect(outcome, isA<Undone>());
    final back = await files.stat(swiped.id);
    expect(back?.folderPath, '/s/DCIM');
    expect(deck().current!.id, swiped.id);
  });

  test('an undo pressed while the move runs undoes that move', () async {
    await useRight(
      const SwipeAction(SwipeActionType.moveTo, targetFolder: '/s/Holiday'),
    );
    final swiped = deck().current!;
    notifier().swipe(SwipeDirection.right);
    // No settle(): the undo waits for the move on the shared lock.
    final outcome = await notifier().undo();
    expect(outcome, isA<Undone>());
    expect((await files.stat(swiped.id))?.folderPath, '/s/DCIM');
  });

  test(
    'a missing target folder: nothing recorded, file back in front',
    () async {
      await useRight(
        const SwipeAction(SwipeActionType.moveTo, targetFolder: '/s/Gone'),
      );
      final swiped = deck().current!;
      final before = deck().swiped;
      notifier().swipe(SwipeDirection.right);
      await settle();
      expect(await actions(), isEmpty);
      expect(deck().current!.id, swiped.id);
      expect(deck().swiped, before);
      expect((await files.stat(swiped.id))?.folderPath, '/s/DCIM');
    },
  );

  test('copy makes a second file that never shows in the deck; undo '
      'removes only the copy', () async {
    await useRight(
      const SwipeAction(SwipeActionType.copyTo, targetFolder: '/s/Copies'),
    );
    final swiped = deck().current!;
    notifier().swipe(SwipeDirection.right);
    await settle();
    final copyId = 'path:/s/Copies/${swiped.name}';
    expect(await files.stat(copyId), isNotNull);
    expect(await files.stat(swiped.id), isNotNull);
    final acted = await c
        .read(undoRepositoryProvider)
        .actedFileIds(deck().session.id);
    expect(acted, containsAll([swiped.id, copyId]));
    expect(deck().upcoming.map((f) => f.id), isNot(contains(copyId)));

    await notifier().undo();
    expect(await files.stat(copyId), isNull);
    expect(await files.stat(swiped.id), isNotNull);
    expect(await c.read(mediaIndexDaoProvider).byId(copyId), isNull);
  });

  test('add tag, undo removes it; a tag the file already had stays', () async {
    final tags = c.read(tagRepositoryProvider);
    final tag = await tags.create('Cats', 0xFF43A047);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await useRight(SwipeAction(SwipeActionType.addTag, tagId: tag.id));

    final first = deck().current!;
    expect(notifier().swipe(SwipeDirection.right), isTrue);
    await settle();
    expect(await tags.tagIdsOf(first.id), {tag.id});
    await notifier().undo();
    expect(await tags.tagIdsOf(first.id), isEmpty);

    // Already tagged before the swipe: undo leaves the tag.
    await db.transaction(() => tags.addInTransaction(first.id, tag.id));
    notifier().swipe(SwipeDirection.right);
    await settle();
    await notifier().undo();
    expect(await tags.tagIdsOf(first.id), {tag.id});
  });

  test('favorite, undo removes it', () async {
    final favorites = c.read(favoritesRepositoryProvider);
    await useRight(const SwipeAction(SwipeActionType.favorite));
    final file = deck().current!;
    notifier().swipe(SwipeDirection.right);
    await settle();
    expect(await favorites.isFavorite(file.id), isTrue);
    await notifier().undo();
    expect(await favorites.isFavorite(file.id), isFalse);
  });

  test('a deleted tag: the swipe is refused and nothing is recorded', () async {
    await useRight(const SwipeAction(SwipeActionType.addTag, tagId: 999));
    expect(
      notifier().problemFor(SwipeDirection.right),
      SwipeActionProblem.tagMissing,
    );
    expect(notifier().swipe(SwipeDirection.right), isFalse);
    expect(await actions(), isEmpty);
  });

  test('a stored layout with an unassignable type springs back', () async {
    await useRight(const SwipeAction(SwipeActionType.sendToDevice));
    expect(
      notifier().problemFor(SwipeDirection.right),
      SwipeActionProblem.unsupported,
    );
    expect(notifier().swipe(SwipeDirection.right), isFalse);
  });

  test('tags and favorites follow a file whose id changes', () async {
    final tags = c.read(tagRepositoryProvider);
    final favorites = c.read(favoritesRepositoryProvider);
    final tag = await tags.create('Trip', 0xFF1E88E5);
    final file = deck().current!;
    await db.transaction(() async {
      await tags.addInTransaction(file.id, tag.id);
      await favorites.addInTransaction(file.id);
    });
    final moved = await files.move(file, '/s/Holiday');
    expect(moved.id, isNot(file.id));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await c.read(dbWriteQueueProvider).flush();
    expect(await tags.tagIdsOf(moved.id), {tag.id});
    expect(await tags.tagIdsOf(file.id), isEmpty);
    expect(await favorites.isFavorite(moved.id), isTrue);
    expect(await favorites.isFavorite(file.id), isFalse);
  });

  test('tag names are unique ignoring case', () async {
    final tags = c.read(tagRepositoryProvider);
    await tags.create('Cats', 0xFF43A047);
    await expectLater(tags.create(' cats ', 0xFF43A047), throwsA(anything));
  });
}
