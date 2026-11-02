import 'dart:async';

import 'package:drift/drift.dart' show OrderingTerm, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/selection/domain/selection_state.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';

const _mediaOnly = StorageAccess(
  media: MediaAccess.granted,
  allFiles: AllFilesAccess.notGranted,
  mediaManagement: false,
  mediaManagementSupported: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeFileSource files;
  late List<FileRef> photos;
  final closed = <ProviderContainer>{};

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    files = FakeFileSource();
    final t0 = DateTime.utc(2026, 10);
    photos = [
      for (var i = 0; i < 6; i++)
        files.addFile(
          '/s/DCIM/p$i.jpg',
          modifiedAt: t0.add(Duration(minutes: i)),
        ),
    ];
    files
      ..addFile('/s/DCIM/v.mp4', modifiedAt: t0, bytes: List.filled(10, 0))
      ..addFile('/s/Download/a.pdf', modifiedAt: t0);
  });

  tearDown(() => db.close());

  Future<void> close(ProviderContainer c) async {
    closed.add(c);
    await c.read(selectionControllerProvider.notifier).flush();
    await c.read(dbWriteQueueProvider).flush();
    c.dispose();
  }

  /// One "app process" over the shared DB + files.
  Future<ProviderContainer> launch({
    StorageAccess access = grantedAccess,
  }) async {
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        fileSourceProvider.overrideWithValue(files),
        permissionServiceProvider.overrideWithValue(
          FakePermissionService(access),
        ),
        mediaChangesProvider.overrideWithValue(const Stream.empty()),
      ],
    );
    await c.read(storageAccessControllerProvider.future);
    await c.read(mediaIndexerProvider).start();
    // Keep it listened: Riverpod 3 pauses unlistened providers.
    c
      ..read(fileIdRekeyerProvider)
      ..listen(selectionControllerProvider, (_, _) {});
    await c.read(selectionControllerProvider.future);
    addTearDown(() async {
      if (!closed.contains(c)) await close(c);
    });
    return c;
  }

  SelectionController ctl(ProviderContainer c) =>
      c.read(selectionControllerProvider.notifier);
  SelectionState st(ProviderContainer c) =>
      c.read(selectionControllerProvider).value!;

  Future<List<String>> storedIds() async => [
    for (final r in await (db.select(
      db.selectionItems,
    )..orderBy([(s) => OrderingTerm.asc(s.seq)])).get())
      r.fileId,
  ];

  test('tapping a selected file again never removes it', () async {
    final c = await launch();
    ctl(c).enterSelect();
    expect(ctl(c).add(photos[0]), isTrue);
    expect(ctl(c).add(photos[0]), isFalse);
    expect(st(c).ids, {photos[0].id});
    expect(st(c).totalBytes, photos[0].sizeBytes);
    expect(st(c).mode, SelectionMode.select);
  });

  test('drag over selected tiles again only adds', () async {
    final c = await launch();
    expect(ctl(c).addAll(photos.sublist(0, 4)), 4);
    expect(ctl(c).addAll(photos.sublist(2, 6)), 2);
    expect(ctl(c).addAll(photos.sublist(0, 6)), 0);
    expect(st(c).count, 6);
    await ctl(c).flush();
    expect(await storedIds(), [for (final p in photos) p.id]);
  });

  test('remove happens only through Edit; Undo puts it back', () async {
    final c = await launch();
    ctl(c).addAll(photos.sublist(0, 3));
    ctl(c)
      ..enterEdit()
      ..remove(photos[0])
      ..remove(photos[1]);
    expect(st(c).ids, {photos[2].id});
    ctl(c).undoRemove();
    expect(st(c).ids, {photos[1].id, photos[2].id});
    await ctl(c).flush();
    // The restored file keeps its old place in the order.
    expect(await storedIds(), [photos[1].id, photos[2].id]);
  });

  // U2 follow-up (d): a move job started from the selection drops its
  // files; the rest stays selected and it survives a restart.
  test('dropAll removes only the given selected files', () async {
    final c = await launch();
    ctl(c).addAll(photos.sublist(0, 4));
    ctl(c).dropAll([photos[1].id, photos[2].id, photos[5].id]);
    expect(st(c).ids, {photos[0].id, photos[3].id});
    expect(st(c).totalBytes, photos[0].sizeBytes + photos[3].sizeBytes);
    expect(ctl(c).canUndoRemove, isFalse);
    await close(c);
    final next = await launch();
    expect(st(next).ids, {photos[0].id, photos[3].id});
  });

  test('clear all then restore gives the same set and order', () async {
    final c = await launch();
    ctl(c).addAll([photos[3], photos[1], photos[4]]);
    expect(await ctl(c).clearAll(), 3);
    expect(st(c).isEmpty, isTrue);
    expect(st(c).canRestoreCleared, isTrue);
    await ctl(c).restoreCleared();
    expect(st(c).count, 3);
    expect(st(c).canRestoreCleared, isFalse);
    expect(await ctl(c).orderedIds(), [
      photos[3].id,
      photos[1].id,
      photos[4].id,
    ]);
  });

  test('clear twice restores only the last selection', () async {
    final c = await launch();
    ctl(c).add(photos[0]);
    await ctl(c).clearAll();
    ctl(c).add(photos[1]);
    await ctl(c).clearAll();
    await ctl(c).restoreCleared();
    expect(st(c).ids, {photos[1].id});
  });

  test('restore merges with files selected after the clear', () async {
    final c = await launch();
    ctl(c).addAll([photos[0], photos[1]]);
    await ctl(c).clearAll();
    ctl(c).addAll([photos[2], photos[0]]);
    await ctl(c).restoreCleared();
    expect(st(c).count, 3);
    // Restored rows keep their old seq: they come first.
    expect(await ctl(c).orderedIds(), [
      photos[0].id,
      photos[1].id,
      photos[2].id,
    ]);
  });

  test('an add queued just before Clear all does not come back', () async {
    final c = await launch();
    ctl(c).add(photos[0]);
    // Still inside the 100 ms add window.
    await ctl(c).clearAll();
    await ctl(c).flush();
    expect(await storedIds(), isEmpty);
    final c2 = await launch();
    expect(st(c2).isEmpty, isTrue);
  });

  test('the selection survives a restart', () async {
    final c = await launch();
    ctl(c).addAll(photos.sublist(0, 3));
    await close(c);
    final c2 = await launch();
    expect(st(c2).ids, {for (final p in photos.sublist(0, 3)) p.id});
    expect(st(c2).totalBytes, 9);
    expect(st(c2).mode, SelectionMode.normal);
  });

  test('a clear survives a restart and can still be restored', () async {
    final c = await launch();
    ctl(c).addAll(photos.sublist(0, 2));
    await ctl(c).clearAll();
    await close(c);
    final c2 = await launch();
    expect(st(c2).isEmpty, isTrue);
    expect(st(c2).canRestoreCleared, isTrue);
    await ctl(c2).restoreCleared();
    expect(st(c2).count, 2);
  });

  test('select all adds every video, loaded or not', () async {
    final c = await launch();
    final added = await ctl(c)
        .selectAll(const IndexQuery(kinds: {FileKind.video}));
    expect(added, 1);
    expect(st(c).count, 1);
    expect(st(c).totalBytes, 10);
    // Again: nothing new.
    expect(await ctl(c).selectAll(IndexQuery.all), 7);
    expect(st(c).count, 8);
  });

  test('select all follows the sort order', () async {
    final c = await launch();
    await ctl(c).selectAll(
      const IndexQuery(
        folderPath: '/s/DCIM',
        kinds: {FileKind.image},
        sort: FileSort(FileSortField.date, descending: false),
      ),
    );
    expect(await ctl(c).orderedIds(), [for (final p in photos) p.id]);
  });

  test('without All files access select all adds only media', () async {
    final c = await launch(access: _mediaOnly);
    await ctl(c).selectAll(IndexQuery.all);
    expect(st(c).ids, isNot(contains('path:/s/Download/a.pdf')));
    expect(st(c).count, 7);
    expect(
      await ctl(c).selectAll(const IndexQuery(kinds: {FileKind.document})),
      0,
    );
  });

  test('a moved file stays selected under its new id', () async {
    final c = await launch();
    ctl(c).add(photos[0]);
    await ctl(c).flush();
    files.addFolder('/s/Pictures');
    final moved = await files.move(photos[0], '/s/Pictures');
    await pumpEventQueue();
    await ctl(c).flush();
    expect(st(c).ids, {moved.id});
    expect(await storedIds(), [moved.id]);
  });

  test('files that leave the index leave the selection', () async {
    final c = await launch();
    ctl(c).addAll(photos.sublist(0, 2));
    await ctl(c).flush();
    await (db.delete(
      db.mediaIndex,
    )..where((t) => t.id.equals(photos[0].id))).go();
    // mediaIndexChanges is debounced 300 ms.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await ctl(c).flush();
    expect(st(c).ids, {photos[1].id});
    expect(st(c).totalBytes, photos[1].sizeBytes);
    expect(await storedIds(), [photos[1].id]);
  });

  test('select all of 50,000 files takes under a second', () async {
    final c = await launch();
    await db.batch((b) {
      for (var i = 0; i < 50000; i++) {
        b.customStatement(
          'INSERT INTO media_index (id, uri, name, name_lower, kind, '
          'size_bytes, modified_at_ms, sort_date_ms, folder_path, origin, '
          'indexed_at_ms, scan_generation, source, hidden, extension) '
          "VALUES ('x$i', 'u', 'n$i.jpg', 'n$i.jpg', 0, 1, $i, $i, "
          "'/s/Big', 0, 1, 1, 0, 0, 'jpg')",
        );
      }
    });
    final watch = Stopwatch()..start();
    final added = await ctl(c)
        .selectAll(const IndexQuery(folderPath: '/s/Big'));
    watch.stop();
    expect(added, 50000);
    expect(watch.elapsedMilliseconds, lessThan(1000));
    // Tapping with 50k selected: the set copy stays well under a frame.
    final tap = Stopwatch()..start();
    ctl(c).add(photos[0]);
    tap.stop();
    expect(tap.elapsedMilliseconds, lessThan(16));
  });
}
