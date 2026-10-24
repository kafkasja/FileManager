import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/ui/active_preset_controller.dart';
import 'package:kfm/features/reviewed/data/reviewed_repository.dart';
import 'package:kfm/features/reviewed/domain/reviewed_rules.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/domain/swipe_deck_state.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeFileSource files;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    files = FakeFileSource();
    for (var i = 0; i < 6; i++) {
      files.addFile(
        '/s/DCIM/p$i.jpg',
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
  SwipeDeckController ctrl(ProviderContainer c) =>
      c.read(swipeDeckControllerProvider.notifier);

  Future<void> flush(ProviderContainer c) =>
      c.read(dbWriteQueueProvider).flush();

  Future<void> done(ProviderContainer c) async {
    await ctrl(c).finish();
    await c.read(swipeDeckControllerProvider.future);
  }

  test('a swipe writes a label; undo deletes it', () async {
    final c = await launch();
    final f = deck(c).current!;
    ctrl(c).swipe(SwipeDirection.right);
    await flush(c);
    final repo = c.read(reviewedRepositoryProvider);
    expect(await repo.reviewedAmong(0, [f]), {f.id});
    await ctrl(c).undo();
    expect(await repo.reviewedAmong(0, [f]), isEmpty);
  });

  test(
    'Basic shows reviewed files again in a new session, with a badge',
    () async {
      final c = await launch();
      final kept = [
        for (var i = 0; i < 2; i++)
          () {
            final id = deck(c).current!.id;
            ctrl(c).swipe(SwipeDirection.right);
            return id;
          }(),
      ];
      await done(c);
      expect(deck(c).remaining, 6);
      expect(deck(c).showReviewedBadge, isTrue);
      expect(deck(c).reviewedIds, containsAll(kept));
      expect(deck(c).reviewedIds, hasLength(2));
      await c.read(sessionRepositoryProvider).flush();
    },
  );

  test(
    "a preset skips what it already reviewed; other presets don't",
    () async {
      final c = await launch();
      final repo = c.read(presetRepositoryProvider);
      final quick = await repo.create(name: 'Quick', layout: SwipeLayout.basic);
      final other = await repo.create(name: 'Other', layout: SwipeLayout.basic);
      await c.read(activePresetControllerProvider.notifier).switchTo(quick);
      await c.read(swipeDeckControllerProvider.future);
      ctrl(c)
        ..swipe(SwipeDirection.right)
        ..swipe(SwipeDirection.right);
      await done(c);
      expect(deck(c).session.presetId, quick);
      expect(deck(c).remaining, 4);
      expect(deck(c).showReviewedBadge, isFalse);

      await c.read(activePresetControllerProvider.notifier).switchTo(other);
      await c.read(swipeDeckControllerProvider.future);
      expect(deck(c).remaining, 6);

      // Session-only include in Quick brings them back.
      await c.read(activePresetControllerProvider.notifier).switchTo(quick);
      await c.read(swipeDeckControllerProvider.future);
      await ctrl(c).applyFilter(const FileFilter(includeReviewed: true));
      expect(deck(c).remaining, 6);
      expect(deck(c).showReviewedBadge, isTrue);
      await c.read(sessionRepositoryProvider).flush();
    },
  );

  test(
    'an edited file (new modified second) is not reviewed any more',
    () async {
      final c = await launch();
      final f = deck(c).current!;
      ctrl(c).swipe(SwipeDirection.right);
      await flush(c);
      final repo = c.read(reviewedRepositoryProvider);
      final sameSecond = f.copyWith(
        modifiedAt: f.modifiedAt.add(const Duration(milliseconds: 400)),
      );
      final edited = f.copyWith(
        modifiedAt: f.modifiedAt.add(const Duration(seconds: 5)),
      );
      expect(await repo.reviewedAmong(0, [sameSecond]), {f.id});
      expect(await repo.reviewedAmong(0, [edited]), isEmpty);
    },
  );

  test('the index predicate matches the Dart rule', () async {
    final c = await launch();
    final f = deck(c).current!;
    ctrl(c).swipe(SwipeDirection.right);
    await flush(c);
    final dao = c.read(mediaIndexDaoProvider);
    final reviewed = await dao.page(
      const IndexQuery(reviewed: ReviewedClause(presetKey: 0, reviewed: true)),
    );
    expect(reviewed.items.map((x) => x.id), [f.id]);
    final not = await dao.count(
      const IndexQuery(reviewed: ReviewedClause(presetKey: 0, reviewed: false)),
    );
    expect(not, 5);
  });

  test(
    'reset one preset leaves the others; reset all clears everything',
    () async {
      final c = await launch();
      ctrl(c).swipe(SwipeDirection.right);
      await flush(c);
      await db.customStatement(
        'INSERT INTO reviewed_labels (action_id, file_id, preset_key, '
        "action_type, reviewed_at, file_modified_at_ms) VALUES (999, 'x', 7, "
        "'keep', 1, 1)",
      );
      final repo = c.read(reviewedRepositoryProvider);
      expect(await repo.fileCounts(), {0: 1, 7: 1});
      await repo.resetPreset(0);
      expect(await repo.fileCounts(), {7: 1});
      await repo.resetAll();
      expect(await repo.fileCounts(), isEmpty);
    },
  );

  test('deckReviewedClause: explicit filter wins, else include decides', () {
    expect(
      deckReviewedClause(
        presetKey: 3,
        mode: ReviewedFilterMode.any,
        includeReviewed: false,
      ),
      const ReviewedClause(presetKey: 3, reviewed: false),
    );
    expect(
      deckReviewedClause(
        presetKey: 3,
        mode: ReviewedFilterMode.any,
        includeReviewed: true,
      ),
      isNull,
    );
    expect(
      deckReviewedClause(
        presetKey: 0,
        mode: ReviewedFilterMode.reviewed,
        includeReviewed: false,
      ),
      const ReviewedClause(presetKey: 0, reviewed: true),
    );
  });

  test('the badge setting off hides it', () async {
    await db
        .into(db.settings)
        .insert(
          SettingRow(
            key: AppSettings.showReviewedBadge.name,
            value: AppSettings.showReviewedBadge.encodeToDb(false),
          ),
        );
    final c = await launch();
    expect(deck(c).showReviewedBadge, isFalse);
    await c.read(sessionRepositoryProvider).flush();
  });
}
