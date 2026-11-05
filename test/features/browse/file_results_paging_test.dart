import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/theme/app_theme.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/browse/ui/widgets/file_results_view.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../../core/platform/permissions/fake_permission_service.dart';

/// E4 (H1/H3): Browse results never stop a fling dead at a page end, and
/// tiles survive a reload that shifts their indexes.
void main() {
  const query = IndexQuery(kinds: {FileKind.image});

  Future<(_PagedDao, ScrollPosition, ProviderContainer)> pump(
    WidgetTester tester, {
    int count = 1200,
  }) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase.memory());
    final thumbs = Directory.systemTemp.createTempSync('kfm_paging_thumbs');
    late _PagedDao dao;
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        permissionServiceProvider.overrideWithValue(FakePermissionService()),
        mediaIndexDaoProvider.overrideWith(
          (ref) => dao = _PagedDao(ref.watch(appDatabaseProvider), count),
        ),
        thumbnailCacheProvider.overrideWith(
          (ref) async => DiskThumbnailCache(
            dir: thumbs,
            generator: (_, _) async => null,
            maxDiskBytes: () async => 1 << 20,
          ),
        ),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await db.close();
      thumbs.deleteSync(recursive: true);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: FileResultsView(query: query)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The count arrives with the first page; its rebuild is the next frame.
    await tester.pump();
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    return (dao, position, container);
  }

  testWidgets('a fling through 1,200 files never hits the end while more '
      'pages exist; placeholders fill rows not loaded yet', (tester) async {
    final (dao, position, container) = await pump(tester);
    var deadStops = 0;
    position.addListener(() {
      final hasMore =
          container.read(filePagesProvider(query)).value?.hasMore ?? false;
      if (hasMore && position.pixels >= position.maxScrollExtent - 0.5) {
        deadStops++;
      }
    });
    // The extent covers every file from the first page on.
    final data = container.read(filePagesProvider(query)).value!;
    expect(data.items, hasLength(FilePages.pageSize));
    expect(data.hasMore, isTrue);
    final extentAtStart = position.maxScrollExtent;

    for (var i = 0; i < 12; i++) {
      await tester.fling(
        find.byType(FileResultsView),
        const Offset(0, -2500),
        8000,
      );
      await tester.pumpAndSettle();
    }
    expect(deadStops, 0);
    expect(position.pixels, position.maxScrollExtent);
    final loaded = container.read(filePagesProvider(query)).value!;
    expect(loaded.items, hasLength(1200));
    expect(loaded.hasMore, isFalse);
    // Later pages are the big ones (1,000 rows).
    expect(dao.limits.first, FilePages.pageSize);
    expect(dao.limits.last, FilePages.morePageSize);
    // Stable: the extent at the end is the one computed at the start.
    expect(position.maxScrollExtent, closeTo(extentAtStart, 1));
    expect(find.byKey(const ValueKey('results-placeholder')), findsNothing);
  });

  testWidgets('a jump far ahead shows placeholders, then the files', (
    tester,
  ) async {
    final (_, position, container) = await pump(tester);
    position.jumpTo(position.maxScrollExtent / 2);
    await tester.pump();
    expect(find.byKey(const ValueKey('results-placeholder')), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('results-placeholder')), findsNothing);
    expect(
      container.read(filePagesProvider(query)).value!.items,
      hasLength(1200),
    );
  });
}

FileRef _file(int i) => FileRef(
  id: 'ms:$i',
  uri: 'content://media/$i',
  name: 'IMG_${i.toString().padLeft(5, '0')}.jpg',
  kind: FileKind.image,
  sizeBytes: 1000,
  modifiedAt: DateTime.utc(2025).subtract(Duration(minutes: i)),
  folderPath: '/storage/emulated/0/DCIM/Camera',
  origin: FileOrigin.local,
);

/// Serves [count] photos in keyset pages (the cursor id is the position),
/// a little slower than instant, like the real query.
class _PagedDao extends MediaIndexDao {
  new(super.attachedDatabase, int count)
    : files = [for (var i = 0; i < count; i++) _file(i)];

  List<FileRef> files;
  final List<int> limits = [];

  @override
  Future<IndexPage> page(
    IndexQuery q, {
    IndexCursor? after,
    int limit = 200,
  }) async {
    limits.add(limit);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final start = after == null
        ? 0
        : files.indexWhere((f) => f.id == after.id) + 1;
    final items = files.skip(start).take(limit).toList();
    final next = start + items.length < files.length && items.length == limit
        ? IndexCursor(0, items.last.id)
        : null;
    return IndexPage(List.unmodifiable(items), next);
  }

  @override
  Future<int> count(IndexQuery q) async => files.length;
}
