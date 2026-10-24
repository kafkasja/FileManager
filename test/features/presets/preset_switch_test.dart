import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/presets/ui/active_preset_controller.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/domain/swipe_deck_state.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_layout_controller.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';

class _Declining extends FakeFileSource {
  bool decline = false;

  @override
  Future<TrashResult> trashBatch(List<FileRef> files) async => decline
      ? const TrashResult(trashed: [], failed: {}, userCancelled: true)
      : await super.trashBatch(files);
}

const _quickLayout = SwipeLayout(
  directions: {
    SwipeDirection.left: SwipeAction.trash,
    SwipeDirection.right: SwipeAction.keep,
    SwipeDirection.up: SwipeAction(SwipeActionType.favorite),
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _Declining files;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    files = _Declining();
    for (var i = 0; i < 8; i++) {
      files.addFile(
        i.isEven ? '/s/Pictures/Screenshots/s$i.png' : '/s/DCIM/Camera/p$i.jpg',
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
    c
      ..listen(swipeDeckControllerProvider, (_, _) {})
      ..listen(activePresetIdProvider, (_, _) {});
    await c.read(mediaIndexerProvider).start();
    await c.read(swipeDeckControllerProvider.future);
    return c;
  }

  SwipeDeckState deck(ProviderContainer c) =>
      c.read(swipeDeckControllerProvider).value!;

  Future<void> switchTo(ProviderContainer c, int? id) async {
    await c.read(activePresetControllerProvider.notifier).switchTo(id);
    await c.read(swipeDeckControllerProvider.future);
  }

  Future<int> quickCleanup(ProviderContainer c) => c
      .read(presetRepositoryProvider)
      .create(
        name: 'Quick cleanup',
        layout: _quickLayout,
        filterJson: '{"v":1,"screenshots":true}',
      );

  group('repository', () {
    test('names are trimmed, 1–40 chars, unique ignoring case', () async {
      final c = await launch();
      final repo = c.read(presetRepositoryProvider);
      await repo.create(name: '  Trip ', layout: SwipeLayout.basic);
      await expectLater(
        repo.create(name: 'TRIP', layout: SwipeLayout.basic),
        throwsA(
          isA<PresetNameException>().having(
            (e) => e.problem,
            'problem',
            PresetNameProblem.taken,
          ),
        ),
      );
      expect(
        () => repo.create(name: ' ', layout: SwipeLayout.basic),
        throwsA(isA<PresetNameException>()),
      );
      expect(
        () => repo.create(name: 'x' * 41, layout: SwipeLayout.basic),
        throwsA(isA<PresetNameException>()),
      );
    });

    test('duplicate, reorder, rename; a corrupt row is a load error', () async {
      final c = await launch();
      final repo = c.read(presetRepositoryProvider);
      final a = await repo.create(name: 'A', layout: SwipeLayout.basic);
      final copy = await repo.duplicate(a);
      expect(((await repo.byId(copy))!).name, 'A (2)');
      await repo.reorder([copy, a]);
      await repo.rename(a, 'Alpha');
      final all = await repo.watchAll().first;
      expect(all.map((p) => p.name), ['A (2)', 'Alpha']);

      await db.customStatement(
        "UPDATE presets SET layout_json = 'nope' WHERE id = $a",
      );
      expect(await repo.byId(a), isA<PresetLoadError>());
    });
  });

  test('switching starts a session with the preset layout + filter; '
      'switching back resumes where Basic was', () async {
    final c = await launch();
    final basicFirst = deck(c).current!.id;
    c.read(swipeDeckControllerProvider.notifier)
      ..swipe(SwipeDirection.right)
      ..swipe(SwipeDirection.right);
    final id = await quickCleanup(c);

    await switchTo(c, id);
    expect(deck(c).session.presetId, id);
    expect(deck(c).session.layout, _quickLayout);
    expect(
      deck(c).upcoming.every((f) => f.folderPath.endsWith('Screenshots')),
      isTrue,
    );
    c.read(swipeDeckControllerProvider.notifier).swipe(SwipeDirection.right);

    await switchTo(c, null);
    expect(deck(c).session.presetId, isNull);
    expect(deck(c).swiped, 2);
    expect(deck(c).current!.id, isNot(basicFirst));
    await c.read(sessionRepositoryProvider).flush();
  });

  test(
    'a session-only layout change never touches the preset row; the '
    'paused session keeps it, the next session starts from the preset',
    () async {
      final c = await launch();
      final id = await quickCleanup(c);
      await switchTo(c, id);
      c.listen(swipeLayoutControllerProvider, (_, _) {});
      await c
          .read(swipeLayoutControllerProvider.notifier)
          .setDirection(SwipeDirection.down, SwipeAction.trash);
      final row = await (db.select(
        db.presets,
      )..where((p) => p.id.equals(id))).getSingle();
      expect(row.layoutJson, contains('"up"'));
      expect(row.layoutJson, isNot(contains('"down"')));
      // Basic's saved layout is unchanged too.
      expect(
        await c
            .read(settingsRepositoryProvider)
            .read(AppSettings.swipeLayoutCurrent),
        '',
      );

      await switchTo(c, null);
      await switchTo(c, id);
      expect(
        deck(c).session.layout.actionFor(SwipeDirection.down),
        SwipeAction.trash,
      );

      // Done → a new session for the preset starts from the saved preset.
      await c.read(swipeDeckControllerProvider.notifier).finish();
      await c.read(swipeDeckControllerProvider.future);
      expect(deck(c).session.layout, _quickLayout);
      expect(deck(c).session.presetId, id);
    },
  );

  test(
    'a declined trash dialog blocks the switch and keeps the deletes',
    () async {
      final c = await launch();
      final id = await quickCleanup(c);
      c.read(swipeDeckControllerProvider.notifier).swipe(SwipeDirection.left);
      await c.read(dbWriteQueueProvider).flush();
      files.decline = true;
      await c.read(activePresetControllerProvider.notifier).switchTo(id);
      expect(
        c.read(activePresetControllerProvider).error,
        isA<PresetSwitchBlocked>(),
      );
      expect(await c.read(activePresetIdProvider.future), 0);
      final pending = await db.select(db.pendingDeletes).get();
      expect(pending, hasLength(1));
    },
  );

  test(
    'deleting the active preset goes back to Basic and ends its sessions',
    () async {
      final c = await launch();
      final id = await quickCleanup(c);
      await switchTo(c, id);
      await c.read(activePresetControllerProvider.notifier).delete(id);
      await c.read(swipeDeckControllerProvider.future);
      expect(await c.read(activePresetIdProvider.future), 0);
      final sessions = await db.select(db.sessions).get();
      expect(
        sessions.where((s) => s.presetId == id).every((s) => s.endedAt != null),
        isTrue,
      );
      expect(await db.select(db.presets).get(), isEmpty);
      await c.read(sessionRepositoryProvider).flush();
    },
  );

  test('a missing active preset falls back to Basic', () async {
    await db
        .into(db.settings)
        .insert(
          SettingRow(
            key: AppSettings.activePresetId.name,
            value: AppSettings.activePresetId.encodeToDb(42),
          ),
        );
    final c = await launch();
    expect(deck(c).session.presetId, isNull);
    expect(await c.read(activePresetIdProvider.future), 0);
    await c.read(sessionRepositoryProvider).flush();
  });

  test('the filter is stored on the session, decoded by P5', () async {
    final c = await launch();
    final id = await quickCleanup(c);
    await switchTo(c, id);
    expect(
      FileFilter.decode(deck(c).session.filterJson),
      const FileFilter(screenshotsOnly: true),
    );
    await c.read(sessionRepositoryProvider).flush();
  });
}
