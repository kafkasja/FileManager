import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/tables/swipe_sources_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/core/platform/device_space.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/features/storage/ui/storage_overview_screen.dart';
import 'package:kfm/features/swipe/ui/swipe_source_bar.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';
import '../../helpers/pump_app.dart';

const _root = '/storage/emulated/0';
const int _mb = 1024 * 1024;
const int _gb = 1024 * _mb;

class _FakeSpace implements DeviceSpaceSource {
  new([this.error]);

  final Exception? error;

  @override
  Future<DeviceSpace> read() async {
    if (error case final e?) throw e;
    return const DeviceSpace(totalBytes: 128 * _gb, freeBytes: 32 * _gb);
  }
}

/// Small real files: camera photos, screenshots, a video, Downloads.
FakeFileSource _library() {
  final files = FakeFileSource();
  final t = DateTime.utc(2025);
  var i = 0;
  void add(String path) =>
      files.addFile('$_root/$path', modifiedAt: t.add(Duration(minutes: i++)));
  add('DCIM/Camera/c1.jpg');
  add('DCIM/Camera/c2.jpg');
  add('DCIM/Camera/v1.mp4');
  add('Pictures/Screenshots/Screenshot_1.png');
  add('Pictures/Screenshots/Screenshot_2.png');
  add('Download/manual.pdf');
  add('Download/d1.jpg');
  return files;
}

/// Index-only rows with real sizes (fake files can't be 120 MB). A high
/// generation keeps them through the indexer's full scans.
Future<void> _seedBig(TestApp app) => MediaIndexDao(app.db).upsertBatch([
  for (final (name, kind, mb) in [
    ('big.pdf', FileKind.document, 120),
    ('mid.mp4', FileKind.video, 60),
  ])
    FileRef(
      id: 'path:$_root/Movies/$name',
      uri: '$_root/Movies/$name',
      name: name,
      kind: kind,
      sizeBytes: mb * _mb,
      modifiedAt: DateTime.utc(2024),
      folderPath: '$_root/Movies',
      origin: FileOrigin.local,
    ),
], 1 << 30);

Future<TestApp> _pump(
  WidgetTester tester, {
  DeviceSpaceSource? space,
  FakePermissionService? permissions,
  Stream<IndexStatus>? status,
  bool seedBig = false,
}) async {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final app = await pumpApp(
    tester,
    files: _library(),
    permissions: permissions,
    overrides: [
      deviceSpaceSourceProvider.overrideWithValue(space ?? _FakeSpace()),
      if (status != null) indexStatusProvider.overrideWith((ref) => status),
    ],
  );
  // Indexer scan → index change (debounced).
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  if (seedBig) {
    await _seedBig(app);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }
  return app;
}

Future<void> _openStorage(WidgetTester tester, TestApp app) async {
  unawaited(app.container.read(routerProvider).push<void>(AppRoutes.storage));
  await tester.pumpAndSettle();
  expect(find.byType(StorageOverviewScreen), findsOneWidget);
}

Finder _row(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(ListTile));

Finder _inRow(String title, Finder matching) =>
    find.descendant(of: _row(title), matching: matching);

Finder _cleanUp(String title) => _inRow(title, find.text('Clean up'));

void main() {
  testWidgets('used/free from DeviceSpace; rows with counts; biggest files', (
    tester,
  ) async {
    final app = await _pump(tester, seedBig: true);
    await _openStorage(tester, app);
    expect(find.text('96 GB used · 32 GB free'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(_inRow('Screenshots', find.text('2 files · 6 B')), findsOneWidget);
    // v1.mp4 (3 B) + mid.mp4 (60 MB).
    expect(_inRow('Videos', find.text('2 files · 60 MB')), findsOneWidget);
    expect(find.text('A file can be in more than one category.'), findsOne);
    expect(find.text('Biggest files'), findsOneWidget);
    expect(find.text('big.pdf'), findsOneWidget);
    expect(find.text('120 MB'), findsWidgets);
    // Sorted by size: Big files (120 MB) above Videos (60 MB).
    expect(
      tester.getTopLeft(_row('Big files (over 100 MB)')).dy,
      lessThan(tester.getTopLeft(_row('Videos')).dy),
    );
    expect(find.text('Still scanning… the numbers keep growing'), findsNothing);
  });

  testWidgets(
    'a failing DeviceSpace → "Free space unknown", the rest renders',
    (tester) async {
      final app = await _pump(
        tester,
        space: _FakeSpace(Exception('statfs failed')),
      );
      await _openStorage(tester, app);
      expect(find.text('Free space unknown'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(_row('Screenshots'), findsOneWidget);
      expect(_row('Downloads'), findsOneWidget);
    },
  );

  testWidgets('"Still scanning…" banner while the index scans', (tester) async {
    final status = StreamController<IndexStatus>.broadcast();
    addTearDown(status.close);
    final app = await _pump(
      tester,
      status: () async* {
        yield IndexIdle(DateTime.utc(2026));
        yield* status.stream;
      }(),
    );
    await _openStorage(tester, app);
    expect(find.text('Still scanning… the numbers keep growing'), findsNothing);

    status.add(const IndexScanning(found: 3, isFirstScan: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Still scanning… the numbers keep growing'), findsOne);
    // The rows keep showing meanwhile.
    expect(_row('Screenshots'), findsOneWidget);

    status.add(IndexIdle(DateTime.utc(2026, 2)));
    await tester.pumpAndSettle();
    expect(find.text('Still scanning… the numbers keep growing'), findsNothing);
  });

  testWidgets('Clean up on Screenshots opens a filter source and the swipe '
      'tab shows "Screenshots"; no Clean up for nothing to swipe', (
    tester,
  ) async {
    final app = await _pump(tester, seedBig: true);
    await _openStorage(tester, app);
    // Big files = the PDF only; WhatsApp is empty.
    expect(_cleanUp('Big files (over 100 MB)'), findsNothing);
    expect(_inRow('WhatsApp', find.text('No files')), findsOneWidget);
    expect(_cleanUp('WhatsApp'), findsNothing);
    expect(_cleanUp('Screenshots'), findsOneWidget);

    await tester.tap(_cleanUp('Screenshots'));
    await tester.pumpAndSettle();

    final rows = await (app.db.select(
      app.db.swipeSources,
    )..where((s) => s.closedAt.isNull())).get();
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.kind, SwipeSourceKind.filter);
    expect(row.origin, SwipeSourceOrigin.storage);
    expect(row.title, 'Screenshots');
    expect(row.returnRoute, AppRoutes.storage);
    expect(row.filterJson, isNotNull);

    expect(
      app.container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .path,
      AppRoutes.swipe,
    );
    expect(
      find.descendant(
        of: find.byType(SwipeSourceBar),
        matching: find.text('Screenshots'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('changing the threshold 100 → 50 MB updates Big files', (
    tester,
  ) async {
    final app = await _pump(tester, seedBig: true);
    await _openStorage(tester, app);
    expect(
      _inRow('Big files (over 100 MB)', find.text('1 file · 120 MB')),
      findsOneWidget,
    );
    await app.container
        .read(settingsRepositoryProvider)
        .write(AppSettings.storageBigFileThresholdBytes, 50 * _mb);
    await tester.pumpAndSettle();
    expect(find.text('Big files (over 100 MB)'), findsNothing);
    expect(
      _inRow('Big files (over 50 MB)', find.text('2 files · 180 MB')),
      findsOneWidget,
    );
    // mid.mp4 is swipeable now.
    expect(_cleanUp('Big files (over 50 MB)'), findsOneWidget);
  });

  testWidgets('without All files access: Downloads shows the access button '
      'instead of its totals, tapping it explains', (tester) async {
    final permissions = FakePermissionService(
      grantedAccess.copyWith(allFiles: AllFilesAccess.notGranted),
    );
    final app = await _pump(tester, permissions: permissions);
    await _openStorage(tester, app);
    const prompt = 'Turn on All files access to see these files';
    expect(_inRow('Downloads', find.text(prompt)), findsOneWidget);
    // d1.jpg is visible, but the incomplete total isn't shown.
    expect(_inRow('Downloads', find.text('1 file · 3 B')), findsNothing);
    expect(_cleanUp('Downloads'), findsOneWidget);
    expect(_inRow('Screenshots', find.text(prompt)), findsNothing);
    expect(
      find.text("Includes WhatsApp's hidden Sent and Status folders"),
      findsNothing,
    );

    await tester.tap(_inRow('Downloads', find.text(prompt)));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('Browse ⋮ → Storage overview', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show menu').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Storage overview'));
    await tester.pumpAndSettle();
    expect(find.byType(StorageOverviewScreen), findsOneWidget);
    expect(find.text('96 GB used · 32 GB free'), findsOneWidget);
  });
}
