import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/tables/pending_deletes_table.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/stats/data/stats_repository.dart';
import 'package:kfm/features/stats/domain/stats_periods.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/trash/data/trash_providers.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';

class _ThrowingTrash extends FakeFileSource {
  bool failListing = false;

  @override
  Future<List<TrashedItem>> listTrashed() async {
    if (failListing) throw StateError('no access');
    return await super.listTrashed();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _ThrowingTrash files;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    files = _ThrowingTrash();
    for (var i = 0; i < 6; i++) {
      files.addFile(
        '/s/DCIM/p$i.jpg',
        bytes: List.filled(100 * (i + 1), 1),
        modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
      );
    }
  });
  tearDown(() => db.close());

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
    addTearDown(c.dispose);
    c.listen(swipeDeckControllerProvider, (_, _) {});
    await c.read(mediaIndexerProvider).start();
    await c.read(swipeDeckControllerProvider.future);
    return c;
  }

  SwipeDeckController ctrl(ProviderContainer c) =>
      c.read(swipeDeckControllerProvider.notifier);

  /// Swipes [n] files; the first [trash] go left. Returns trashed sizes.
  Future<int> swipe(ProviderContainer c, int n, {int trash = 0}) async {
    var bytes = 0;
    for (var i = 0; i < n; i++) {
      final f = c.read(swipeDeckControllerProvider).value!.current!;
      if (i < trash) {
        bytes += f.sizeBytes;
        ctrl(c).swipe(SwipeDirection.left);
      } else {
        ctrl(c).swipe(SwipeDirection.right);
      }
    }
    await c.read(dbWriteQueueProvider).flush();
    return bytes;
  }

  test(
    'Done in trash mode: reviewed + moved to trash, nothing freed',
    () async {
      final c = await launch();
      final sessionId = c.read(swipeDeckControllerProvider).value!.session.id;
      final trashed = await swipe(c, 5, trash: 3);
      await ctrl(c).finish();
      final stats = c.read(statsRepositoryProvider);
      final s = await stats.forSession(sessionId);
      expect(s.reviewed, 5);
      expect(s.toTrashBytes, trashed);
      expect(s.freedBytes, 0);
      expect(await stats.inTrashBytes(), trashed);
      expect((await stats.totals()).freedBytes, 0);
      await c.read(sessionRepositoryProvider).flush();
    },
  );

  test('permanent mode: freed, nothing in trash', () async {
    final c = await launch();
    await ctrl(c).finish(); // end the trash-mode session
    await c
        .read(sessionRepositoryProvider)
        .getOrCreateActive(deleteMode: DeleteMode.permanent);
    c.invalidate(swipeDeckControllerProvider);
    await c.read(swipeDeckControllerProvider.future);
    final gone = await swipe(c, 2, trash: 2);
    await ctrl(c).finish();
    final stats = c.read(statsRepositoryProvider);
    expect((await stats.totals()).freedBytes, gone);
    expect(await stats.inTrashBytes(), 0);
    await c.read(sessionRepositoryProvider).flush();
  });

  test(
    'undo before Done lowers reviewed; nothing counts before commit',
    () async {
      final c = await launch();
      await swipe(c, 3, trash: 1);
      await ctrl(c).undo();
      final stats = c.read(statsRepositoryProvider);
      expect((await stats.totals()).reviewed, 2);
      expect(await stats.inTrashBytes(), 0);
      await c.read(sessionRepositoryProvider).flush();
    },
  );

  test(
    'delete forever / restore / disappearing items move the numbers',
    () async {
      final c = await launch();
      await swipe(c, 3, trash: 3);
      await ctrl(c).finish();
      final stats = c.read(statsRepositoryProvider);
      final ledger = c.read(trashLedgerProvider);
      final items = await files.listTrashed();
      expect(items, hasLength(3));
      final total = await stats.inTrashBytes();

      // Delete forever on one.
      final first = items[0];
      await files.deleteFromTrash([first]);
      await ledger.markLeft([first.trashId], TrashExit.purged);
      expect(await stats.inTrashBytes(), total - first.original.sizeBytes);
      expect((await stats.totals()).freedBytes, first.original.sizeBytes);

      // Restore another: leaves "in trash", never freed.
      final second = items[1];
      await files.restore(second);
      await ledger.reconcile(await files.listTrashed());
      expect(
        await stats.inTrashBytes(),
        total - first.original.sizeBytes - second.original.sizeBytes,
      );
      expect((await stats.totals()).freedBytes, first.original.sizeBytes);

      // The last one vanishes (Gallery bin emptied): freed.
      final third = items[2];
      await files.deleteFromTrash([third]);
      await ledger.reconcile(await files.listTrashed());
      expect(await stats.inTrashBytes(), 0);
      expect(
        (await stats.totals()).freedBytes,
        first.original.sizeBytes + third.original.sizeBytes,
      );
      await c.read(sessionRepositoryProvider).flush();
    },
  );

  test('a failing trash listing marks nothing', () async {
    final c = await launch();
    await swipe(c, 2, trash: 2);
    await ctrl(c).finish();
    final stats = c.read(statsRepositoryProvider);
    final before = await stats.inTrashBytes();
    files.failListing = true;
    await c.read(trashLedgerProvider).reconcileNow();
    expect(await stats.inTrashBytes(), before);
    expect((await stats.totals()).freedBytes, 0);
    await c.read(sessionRepositoryProvider).flush();
  });

  test('periods: Monday week start, month start', () {
    final wed = DateTime(2026, 10, 21, 15);
    expect(startOfWeek(wed), DateTime(2026, 10, 19));
    expect(
      startOfWeek(wed, firstWeekday: DateTime.sunday),
      DateTime(2026, 10, 18),
    );
    expect(startOfMonth(wed), DateTime(2026, 10));
    expect(laterOf(null, wed), wed);
  });
}
