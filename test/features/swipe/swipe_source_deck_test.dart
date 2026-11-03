import 'dart:math';

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
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/domain/swipe_deck_state.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_source_launcher.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeFileSource files;
  late DateTime t0;

  /// Main deck order (newest first): p39 … p0, then v4 … v0, s4 … s0.
  late List<String> photos;
  late List<String> videos;
  late List<String> screenshots;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    files = FakeFileSource();
    t0 = DateTime.now().toUtc().subtract(const Duration(days: 1));
    photos = [
      for (var i = 0; i < 40; i++)
        files
            .addFile(
              '/s/DCIM/p$i.jpg',
              modifiedAt: t0.subtract(Duration(minutes: 100 - i)),
            )
            .id,
    ];
    videos = [
      for (var i = 0; i < 5; i++)
        files
            .addFile(
              '/s/DCIM/v$i.mp4',
              modifiedAt: t0.subtract(Duration(minutes: 200 - i)),
            )
            .id,
    ];
    screenshots = [
      for (var i = 0; i < 5; i++)
        files
            .addFile(
              '/s/Pictures/Screenshots/s$i.png',
              modifiedAt: t0.subtract(Duration(minutes: 300 - i)),
            )
            .id,
    ];
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

  Future<void> flush(ProviderContainer c) async {
    await c.read(sessionRepositoryProvider).flush();
    await c.read(dbWriteQueueProvider).flush();
  }

  /// Simulated restart: the old process goes, a new one starts.
  Future<ProviderContainer> restart(ProviderContainer c) async {
    await flush(c);
    c.dispose();
    final next = await launch();
    addTearDown(next.dispose);
    return next;
  }

  SwipeDeckState deck(ProviderContainer c) =>
      c.read(swipeDeckControllerProvider).value!;

  SwipeDeckController controller(ProviderContainer c) =>
      c.read(swipeDeckControllerProvider.notifier);

  String? current(ProviderContainer c) => deck(c).current?.id;

  /// Swipes [n] files; waits for background refills when the window is
  /// empty. Returns the swiped ids in order.
  Future<List<String>> swipe(
    ProviderContainer c,
    int n, {
    SwipeDirection direction = SwipeDirection.right,
  }) async {
    final done = <String>[];
    for (var i = 0; i < n; i++) {
      for (var w = 0; deck(c).current == null && deck(c).hasMore; w++) {
        if (w > 500) fail('the deck never refilled');
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
      final id = current(c);
      if (id == null) fail('nothing left after ${done.length} swipes');
      expect(controller(c).swipe(direction), isTrue);
      done.add(id);
    }
    return done;
  }

  Future<SwipeSourceOpenResult> open(
    ProviderContainer c,
    SwipeSourceRequest request,
  ) async {
    final result = await c
        .read(swipeSourceLauncherProvider.notifier)
        .open(request);
    await c.read(swipeDeckControllerProvider.future);
    return result;
  }

  FilesSourceRequest list(List<String> ids, {String title = 'Picked'}) =>
      FilesSourceRequest(
        origin: SwipeSourceOrigin.browse,
        title: title,
        fileIds: ids,
        returnRoute: '/browse',
      );

  Future<List<PendingDeleteRow>> pending() =>
      db.select(db.pendingDeletes).get();

  test('a 30-id list shows exactly those files in order, with the title; '
      'swipes use the session layout', () async {
    final c = await launch();
    addTearDown(c.dispose);
    final layout = deck(c).session.layout;
    final ids = [...videos, ...photos.sublist(5, 30)]..shuffle(Random(7));

    final result = await open(c, list(ids, title: 'Thirty'));
    expect(result, isA<SwipeSourceOpened>());
    expect((result as SwipeSourceOpened).files, 30);
    expect(deck(c).source?.title, 'Thirty');
    expect(deck(c).remaining, 30);
    expect(deck(c).session.layout, layout);
    expect(deck(c).newFiles, 0);
    expect(deck(c).groupPosition, isNull);

    final swiped = await swipe(c, 30);
    expect(swiped, ids);
    expect(deck(c).current, isNull);
    expect(deck(c).isFinished, isTrue);
    expect(deck(c).source, isNotNull, reason: 'finished view, still open');
  });

  test(
    'groups 2/5/3: the 4th file of group 2 is "group 2 of 3 · 4/5"',
    () async {
      final c = await launch();
      addTearDown(c.dispose);
      final groups = [
        photos.sublist(0, 2),
        photos.sublist(2, 7),
        photos.sublist(7, 10),
      ];
      await open(
        c,
        GroupsSourceRequest(
          origin: SwipeSourceOrigin.similar,
          title: 'Similar',
          groups: groups,
        ),
      );
      final first = deck(c).groupPosition!;
      expect(
        (first.group, first.groupCount, first.index, first.groupSize),
        (1, 3, 1, 2),
      );
      await swipe(c, 5);
      expect(current(c), photos[5]);
      final p = deck(c).groupPosition!;
      expect((p.group, p.groupCount, p.index, p.groupSize), (2, 3, 4, 5));
    },
  );

  test(
    'a filter source shows only matches; the session filter is kept',
    () async {
      final c = await launch();
      addTearDown(c.dispose);
      await controller(c)
          .applyFilter(const FileFilter(kinds: {FileKind.image}));
      final mainFilter = deck(c).session.filterJson;
      expect(mainFilter, isNotNull);

      await open(
        c,
        const FilterSourceRequest(
          origin: SwipeSourceOrigin.storage,
          title: 'Screenshots',
          filter: FileFilter(screenshotsOnly: true),
        ),
      );
      expect(deck(c).source?.kind, SwipeSourceKind.filter);
      expect({for (final f in deck(c).upcoming) f.id}, screenshots.toSet());
      expect(deck(c).remaining, 5);
      expect(deck(c).newFiles, 0);
      await swipe(c, 2);
      expect(deck(c).session.filterJson, mainFilter);

      // A kinds filter: only the videos (the main filter is images only).
      await open(
        c,
        const FilterSourceRequest(
          origin: SwipeSourceOrigin.storage,
          title: 'Videos',
          filter: FileFilter(kinds: {FileKind.video}),
        ),
      );
      expect({for (final f in deck(c).upcoming) f.id}, videos.toSet());

      await controller(c).closeSource();
      expect(deck(c).source, isNull);
      expect(deck(c).session.filterJson, mainFilter);
      final saved = await c.read(sessionRepositoryProvider).active();
      expect(saved!.filterJson, mainFilter);
      expect(current(c), photos.last);
    },
  );

  test('swipe 20, a source of 5, close: main shows the 21st, also after a '
      'restart', () async {
    var c = await launch();
    addTearDown(c.dispose);
    final main = photos.reversed.toList();
    expect(await swipe(c, 20), main.sublist(0, 20));

    await open(c, list(photos.sublist(0, 10)));
    expect(await swipe(c, 5), photos.sublist(0, 5));
    await controller(c).closeSource();
    expect(deck(c).source, isNull);
    expect(current(c), main[20]);
    expect(deck(c).swiped, 25);

    c = await restart(c);
    expect(deck(c).source, isNull);
    expect(current(c), main[20]);
  });

  test('after a closed source, main swipes undone again resume at the first '
      'of them after a restart', () async {
    var c = await launch();
    addTearDown(c.dispose);
    final main = photos.reversed.toList();
    await swipe(c, 20);
    await open(c, list(photos.sublist(0, 10)));
    await swipe(c, 5);
    await controller(c).closeSource();
    expect(await swipe(c, 2), main.sublist(20, 22));
    await controller(c).undo();
    await controller(c).undo();
    expect(current(c), main[20]);

    c = await restart(c);
    expect(current(c), main[20]);
  });

  test('undo 6 across the boundary: source files first, then the 20th main '
      'file in front; close shows the 20th', () async {
    var c = await launch();
    addTearDown(c.dispose);
    final main = photos.reversed.toList();
    await swipe(c, 20);
    final sourceIds = photos.sublist(0, 10);
    await open(c, list(sourceIds, title: 'Ten'));
    final swiped = await swipe(c, 5);

    for (final id in swiped.reversed) {
      await controller(c).undo();
      expect(current(c), id);
      expect(deck(c).source?.title, 'Ten');
    }
    await controller(c).undo();
    expect(current(c), main[19]);
    expect(deck(c).source?.title, 'Ten');
    expect(deck(c).groupPosition, isNull);
    // The source's own files follow it.
    expect(deck(c).upcoming[1].id, sourceIds[0]);

    await controller(c).closeSource();
    expect(current(c), main[19]);

    c = await restart(c);
    expect(current(c), main[19]);
  });

  test(
    '300 ids in random date order: all offered, no new-files chip',
    () async {
      final rnd = Random(3);
      final now = DateTime.now().toUtc();
      final refs = [
        for (var i = 0; i < 300; i++)
          files.addFile(
            '/s/DCIM/Big/b$i.jpg',
            // Before and after the session start.
            modifiedAt: now.add(Duration(minutes: rnd.nextInt(6000) - 3000)),
          ),
      ];
      final c = await launch();
      addTearDown(c.dispose);
      final ids = [for (final r in refs) r.id]..shuffle(rnd);

      await open(c, list(ids, title: 'Big'));
      expect(deck(c).remaining, 300);
      expect(deck(c).newFiles, 0);
      expect(await swipe(c, 300), ids);
      expect(deck(c).newFiles, 0);
      expect(deck(c).isFinished, isTrue);
    },
  );

  test(
    'runOutsideDeck: 3 trash rows, undoable; main keeps its position',
    () async {
      var c = await launch();
      addTearDown(c.dispose);
      final main = photos.reversed.toList();
      await swipe(c, 5);
      final session = deck(c).session;
      final targets = [
        for (final id in screenshots.sublist(0, 3)) (await files.stat(id))!,
      ];

      final n = await c
          .read(swipeSourceLauncherProvider.notifier)
          .runOutsideDeck(
            sessionId: session.id,
            origin: SwipeSourceOrigin.similar,
            title: 'Keep best',
            body: () async {
              final dispatcher = c.read(swipeActionDispatcherProvider);
              for (final f in targets) {
                dispatcher.dispatch(session, f, SwipeAction.trash);
              }
              return targets.length;
            },
          );
      expect(n, 3);
      await c.read(swipeDeckControllerProvider.future);
      await flush(c);
      expect(await pending(), hasLength(3));
      expect(current(c), main[5]);
      expect(deck(c).swiped, 8);

      c = await restart(c);
      expect(current(c), main[5]);

      // Undoable from the swipe tab, newest first.
      await controller(c).undo();
      expect(current(c), screenshots[2]);
      await flush(c);
      expect(await pending(), hasLength(2));
    },
  );

  test(
    'closing a source after 12 trashes commits nothing; Done does',
    () async {
      final c = await launch();
      addTearDown(c.dispose);
      await open(c, list(photos.sublist(0, 20)));
      await swipe(c, 12, direction: SwipeDirection.left);
      await flush(c);
      final before = await pending();
      expect(before, hasLength(12));
      expect(
        before.every((r) => r.status == PendingDeleteStatus.queued),
        isTrue,
      );

      await controller(c).closeSource();
      await flush(c);
      final after = await pending();
      expect(
        [for (final r in after) (r.fileId, r.status)],
        [for (final r in before) (r.fileId, r.status)],
      );

      final result = await controller(c).finish();
      expect(result.sessionEnded, isTrue);
      await flush(c);
      expect(
        (await pending()).every(
          (r) => r.status == PendingDeleteStatus.committed,
        ),
        isTrue,
      );
    },
  );

  test('a second open replaces the first', () async {
    final c = await launch();
    addTearDown(c.dispose);
    await open(c, list(photos.sublist(0, 5), title: 'First'));
    await swipe(c, 1);
    await open(c, list(photos.sublist(20, 25), title: 'Second'));
    expect(deck(c).source?.title, 'Second');
    expect(current(c), photos[20]);
    await flush(c);
    final rows = await db.select(db.swipeSources).get();
    expect(rows.where((r) => r.closedAt == null), hasLength(1));
    expect(await db.select(db.swipeSourceItems).get(), hasLength(5));
  });

  test('X1: a file kept in the "Shared files" deck is still offered by the '
      'main deck (position and count unchanged); a trashed one is not', () async {
    var c = await launch();
    addTearDown(c.dispose);
    final main = photos.reversed.toList();
    expect(await swipe(c, 2), main.sublist(0, 2));

    // Shared from the gallery: the next main file, kept there.
    await open(
      c,
      FilesSourceRequest(
        origin: SwipeSourceOrigin.sharedIn,
        title: 'Shared files',
        fileIds: [main[2]],
      ),
    );
    expect(await swipe(c, 1), [main[2]]);
    await controller(c).closeSource();
    expect(deck(c).source, isNull);
    expect(current(c), main[2]);
    expect(deck(c).swiped, 2);

    c = await restart(c);
    expect(current(c), main[2]);
    expect(deck(c).swiped, 2);

    // Trashed in the shared deck: it is going away, so main skips it.
    await open(
      c,
      FilesSourceRequest(
        origin: SwipeSourceOrigin.sharedIn,
        title: 'Shared files',
        fileIds: [main[2]],
      ),
    );
    expect(
      await swipe(c, 1, direction: SwipeDirection.left),
      [main[2]],
    );
    await controller(c).closeSource();
    expect(current(c), main[3]);

    // Other sources keep the SS1 rule: acted files are skipped in main.
    await open(c, list([main[3]]));
    await swipe(c, 1);
    await controller(c).closeSource();
    expect(current(c), main[4]);
  });

  test('a restart with a source open continues it at the next file', () async {
    var c = await launch();
    addTearDown(c.dispose);
    await open(c, list(photos.sublist(0, 6), title: 'Six'));
    await swipe(c, 2);
    c = await restart(c);
    expect(deck(c).source?.title, 'Six');
    expect(current(c), photos[2]);
    expect(deck(c).restored, isTrue);
    expect(deck(c).swiped, 2);
  });

  test('without a source the main deck runs as before', () async {
    var c = await launch();
    addTearDown(c.dispose);
    final main = photos.reversed.toList();
    expect(deck(c).source, isNull);
    expect(deck(c).groupPosition, isNull);
    expect(deck(c).remaining, 50);
    await swipe(c, 3);
    c = await restart(c);
    expect(current(c), main[3]);
    await controller(c).undo();
    expect(current(c), main[2]);
    // closeSource without a source does nothing.
    await controller(c).closeSource();
    expect(current(c), main[2]);
  });
}
