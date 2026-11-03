import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';

/// U1 follow-up (g): the SD card was unmounted while its photo was the
/// deck's current card; the card stayed (only queries hid the card's rows).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const camera = '/storage/emulated/0/DCIM/Camera';
  const card = '/storage/1234-ABCD';
  late AppDatabase db;
  late FakeFileSource files;
  late List<FileRef> local;
  late List<FileRef> onCard;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    files = FakeFileSource();
    final t0 = DateTime.now().toUtc().subtract(const Duration(days: 1));
    local = [
      for (var i = 0; i < 2; i++)
        files.addFile(
          '$camera/p$i.jpg',
          modifiedAt: t0.subtract(Duration(minutes: 30 + i)),
        ),
    ];
    // Newer: the deck shows these first, so one of them is the current card.
    onCard = [
      for (var i = 0; i < 2; i++)
        files.addFile(
          '$card/DCIM/s$i.jpg',
          modifiedAt: t0.subtract(Duration(minutes: i)),
        ),
    ];
  });

  tearDown(() => db.close());

  test('unmounting a card drops all its cards, the current one too', () async {
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
    await c.read(mediaIndexerProvider).start();
    // A listener keeps the deck (and its index listener) active.
    c.listen(swipeDeckControllerProvider, (_, _) {});
    await c.read(swipeDeckControllerProvider.future);
    List<String> upcoming() => [
      for (final f in c.read(swipeDeckControllerProvider).value!.upcoming) f.id,
    ];
    expect(upcoming(), hasLength(4));
    expect(upcoming().first, isIn([for (final f in onCard) f.id]));

    c.read(mediaIndexDaoProvider).setExcludedRoots({card});
    for (var i = 0; i < 200 && upcoming().length > 2; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(upcoming(), unorderedEquals(local.map((f) => f.id)));
  });

  test('isExcludedFolder matches the root and below, not look-alikes', () {
    final dao = MediaIndexDao(db)..setExcludedRoots({card});
    expect(dao.isExcludedFolder(card), isTrue);
    expect(dao.isExcludedFolder('$card/DCIM'), isTrue);
    expect(dao.isExcludedFolder('${card}0/DCIM'), isFalse);
    expect(dao.isExcludedFolder(camera), isFalse);
  });
}
