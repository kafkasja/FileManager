import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';

/// U2 follow-up (a): a local job moved a photo of the open deck to the SD
/// card; the deck kept a card with the original's (dead) id.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const camera = '/storage/emulated/0/DCIM/Camera';
  const sd = '/storage/1234-ABCD/DCIM';
  late AppDatabase db;
  late FakeFileSource files;
  late List<FileRef> photos;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    files = FakeFileSource()..addFolder(sd);
    final t0 = DateTime.now().toUtc().subtract(const Duration(days: 1));
    photos = [
      for (var i = 0; i < 3; i++)
        files.addFile(
          '$camera/p$i.jpg',
          modifiedAt: t0.subtract(Duration(minutes: 10 - i)),
        ),
    ];
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
    await c.read(mediaIndexerProvider).start();
    await c.read(swipeDeckControllerProvider.future);
    return c;
  }

  List<String> upcoming(ProviderContainer c) => [
    for (final f in c.read(swipeDeckControllerProvider).value!.upcoming) f.id,
  ];

  /// What a U2 move job does: the copy is indexed, the original goes, the
  /// move is announced.
  Future<FileRef> jobMove(ProviderContainer c, FileRef f) async {
    final copy = await files.copy(f, sd);
    await c.read(mediaIndexerProvider).addFiles([copy]);
    await files.deletePermanentlyBatch([f]);
    files.emitIdChange(FileIdChange(f.id, copy));
    for (var i = 0; i < 200 && upcoming(c).contains(f.id); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    return copy;
  }

  test(
    'still in the deck filter: the card follows the file to its new id',
    () async {
      final c = await launch();
      final moved = photos[1];
      expect(upcoming(c), contains(moved.id));
      final copy = await jobMove(c, moved);
      expect(upcoming(c), isNot(contains(moved.id)));
      expect(upcoming(c), contains(copy.id));
    },
  );

  test('outside the deck filter now: the card goes', () async {
    final c = await launch();
    await c
        .read(swipeDeckControllerProvider.notifier)
        .applyFilter(const FileFilter(folderPaths: {camera}));
    final moved = photos[1];
    expect(upcoming(c), contains(moved.id));
    final copy = await jobMove(c, moved);
    expect(upcoming(c), isNot(contains(moved.id)));
    expect(upcoming(c), isNot(contains(copy.id)));
    expect(upcoming(c), hasLength(2));
  });
}
