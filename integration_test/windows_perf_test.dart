// Windows speed checks (TASK-PL1 acceptance, TASK-PL3): the real desktop app
// on its own database, frame timings from the engine. Needs test images:
//   python tool/make_perf_images.py %USERPROFILE%\Pictures\KFM-perf\big50k 50000
//   python tool/make_perf_images.py %USERPROFILE%\Pictures\KFM-perf\folder10k 10000
// Run in profile mode (one mode per run; `flutter test` only builds debug):
//   flutter run --profile -d windows -t integration_test/windows_perf_test.dart
//     --dart-define=KFM_PERF_MODE=browse   (or sort)
//     --dart-define=KFM_PERF_ROOT=C:/Users/<me>/Pictures/KFM-perf/big50k
//     --dart-define=KFM_PERF_DIR=<scratch folder: db + thumbnail cache>
// Results are printed (`PERF {...}`) and written to KFM_PERF_DIR/<mode>.json.
// Without KFM_PERF_ROOT the test is skipped.
@TestOn('windows')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kfm/app/app.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/core/platform/windows/shell_thumbnails.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';
import 'package:kfm/desktop/browse/desktop_browse_controller.dart';
import 'package:kfm/desktop/widgets/explorer_view.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:window_manager/window_manager.dart';

const _mode = String.fromEnvironment('KFM_PERF_MODE', defaultValue: 'browse');
const _root = String.fromEnvironment('KFM_PERF_ROOT');
const _dir = String.fromEnvironment('KFM_PERF_DIR');

/// The thumbnail cache folder under KFM_PERF_DIR (a new name = cold cache).
const _thumbs = String.fromEnvironment(
  'KFM_PERF_THUMBS',
  defaultValue: 'thumbs',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('speed: $_mode', skip: _root.isEmpty || _dir.isEmpty, (
    tester,
  ) async {
    final results = <String, Object?>{'mode': _mode, 'root': _root};
    final app = await _startApp(tester, binding);
    final c = app.container;
    results['window'] =
        '${tester.view.physicalSize.width.round()}x${tester.view.physicalSize.height.round()}';

    // --- first index ---------------------------------------------------
    final indexClock = Stopwatch()..start();
    await _waitFor(() {
      final s = c.read(indexStatusProvider).value;
      return s is IndexIdle && s.lastScan != null;
    }, timeout: const Duration(minutes: 20));
    indexClock.stop();
    final dao = c.read(mediaIndexDaoProvider);
    const folderQuery = IndexQuery(
      folderPath: _root,
      sort: FileSort(FileSortField.name),
    );
    final indexed = await dao.count(folderQuery);
    results['firstIndex'] = {
      'files': indexed,
      'ms': indexClock.elapsedMilliseconds,
    };
    _log('first index: $indexed files in ${indexClock.elapsedMilliseconds} ms');

    if (_mode == 'sort') {
      results['open'] = await _openFolder(tester, c);
      results['sort'] = await _sortRun(tester, c);
    } else {
      results['open'] = await _openFolder(tester, c);
      final cache = await c.read(thumbnailCacheProvider.future);
      // Thumbnails of the part scrolled below (Shell → disk → memory).
      final files = <FileRef>[];
      IndexCursor? next;
      do {
        final page = await dao.page(folderQuery, after: next);
        files.addAll(page.items);
        next = page.next;
      } while (next != null && files.length < 3000);
      final warm = Stopwatch()..start();
      for (var i = 0; i < files.length; i += 64) {
        await Future.wait([
          for (final f in files.skip(i).take(64)) cache.get(f),
        ]);
      }
      results['thumbWarmup'] = {
        'files': files.length,
        'ms': warm.elapsedMilliseconds,
      };
      _log(
        'thumbnails for ${files.length} files: ${warm.elapsedMilliseconds} ms',
      );

      final nav = c.read(desktopBrowseControllerProvider.notifier);
      for (final layout in [ExplorerLayout.grid, ExplorerLayout.details]) {
        nav.setLayout(layout);
        await _settle();
        for (var run = 1; run <= 2; run++) {
          results['${layout.name}Cached$run'] = await _scrollRun(
            tester,
            c,
            pxPerSecond: 3000,
            seconds: 6,
            layout: layout,
          );
        }
      }
      // Baseline: the same rows drawn again every frame (1 px back and
      // forth), so nothing is built, loaded or decoded.
      nav.setLayout(ExplorerLayout.grid);
      await _settle();
      final pos = _explorerScroll<BrowseEntry>(tester)..jumpTo(400);
      await _settle(500);
      results['gridRedrawOnly'] = await _frames(() async {
        for (var i = 0; i < 480; i++) {
          pos.jumpTo(i.isEven ? 401 : 400);
          await SchedulerBinding.instance.endOfFrame;
        }
      });
      _log('redraw only: ${results['gridRedrawOnly']}');
      // Into rows that aren't cached (Shell thumbnails being made).
      nav.setLayout(ExplorerLayout.grid);
      await _settle();
      results['gridUncached'] = await _scrollRun(
        tester,
        c,
        pxPerSecond: 6000,
        seconds: 8,
        from: 2800,
        layout: ExplorerLayout.grid,
      );
    }
    final json = const JsonEncoder.withIndent('  ').convert(results);
    _log('PERF $json');
    File('$_dir/$_mode.json').writeAsStringSync(json);
    await app.dispose();
  }, timeout: const Timeout(Duration(minutes: 40)));
}

void _log(String s) => debugPrint('[perf] $s');

class _App {
  new(this.container, this.db);

  final ProviderContainer container;
  final AppDatabase db;

  Future<void> dispose() async {
    container.dispose();
  }
}

Future<_App> _startApp(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  // The worst case: a maximized window shows the most tiles.
  await windowManager.ensureInitialized();
  await windowManager.maximize();
  await _settle(500);
  final dbDir = Directory('$_dir/db-$_mode');
  if (dbDir.existsSync()) dbDir.deleteSync(recursive: true);
  dbDir.createSync(recursive: true);
  final db = AppDatabase(
    driftDatabase(
      name: 'kfm',
      native: DriftNativeOptions(
        databaseDirectory: () async => dbDir,
        setup: AppDatabase.setupConnection,
      ),
    ),
  );
  for (final (name, value) in [
    (
      AppSettings.onboardingTutorialDone.name,
      AppSettings.onboardingTutorialDone.encodeToDb(true),
    ),
    (
      AppSettings.windowsIndexRoots.name,
      AppSettings.windowsIndexRoots.encodeToDb([_root]),
    ),
  ]) {
    await db.into(db.settings).insert(SettingRow(key: name, value: value));
  }
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      thumbnailCacheProvider.overrideWith((ref) async {
        final settings = ref.watch(settingsRepositoryProvider);
        return DiskThumbnailCache(
          dir: Directory('$_dir/$_thumbs'),
          generator: shellThumbnailGenerator(ref.watch(windowsChannelProvider)),
          maxDiskBytes: () async =>
              await settings.read(AppSettings.thumbCacheMaxMb) * 1024 * 1024,
        );
      }),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  // Real frames from here on (the engine's vsync, not the test's pumps).
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  return _App(container, db);
}

Future<void> _waitFor(
  bool Function() test, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final clock = Stopwatch()..start();
  while (!test()) {
    if (clock.elapsed > timeout) throw TimeoutException('waitFor', timeout);
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<void> _settle([int ms = 1500]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

/// Collects the engine's frame timings while running [body].
Future<Map<String, Object?>> _frames(Future<void> Function() body) async {
  final timings = <FrameTiming>[];
  void onTimings(List<FrameTiming> t) => timings.addAll(t);
  SchedulerBinding.instance.addTimingsCallback(onTimings);
  try {
    await body();
    // Timings arrive in batches; let the last one in.
    await _settle(1200);
  } finally {
    SchedulerBinding.instance.removeTimingsCallback(onTimings);
  }
  return _summary(timings);
}

Map<String, Object?> _summary(List<FrameTiming> t) {
  double pct(List<double> v, double p) {
    if (v.isEmpty) return 0;
    final s = [...v]..sort();
    return s[math.min(s.length - 1, (p * s.length).floor())];
  }

  double ms(Duration d) => d.inMicroseconds / 1000;
  final build = [for (final f in t) ms(f.buildDuration)];
  final raster = [for (final f in t) ms(f.rasterDuration)];
  String r(double v) => v.toStringAsFixed(2);
  return {
    'frames': t.length,
    'buildP50': r(pct(build, .5)),
    'buildP90': r(pct(build, .9)),
    'buildP99': r(pct(build, .99)),
    'buildWorst': r(build.fold(0, math.max)),
    'rasterP50': r(pct(raster, .5)),
    'rasterP90': r(pct(raster, .9)),
    'rasterP99': r(pct(raster, .99)),
    'rasterWorst': r(raster.fold(0, math.max)),
    'over16ms': [
      for (var i = 0; i < t.length; i++)
        if (build[i] > 16 || raster[i] > 16) i,
    ].length,
    // Which frames (index of all, build/raster ms): start-up or periodic?
    'slow': [
      for (var i = 0; i < t.length; i++)
        if (build[i] > 16 || raster[i] > 16)
          '#$i ${r(build[i])}/${r(raster[i])}',
    ].join(', '),
  };
}

ScrollPosition _explorerScroll<T>(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(ExplorerView<T>),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;

/// Opens the folder in desktop Browse; time to the first rows on screen.
Future<Map<String, Object?>> _openFolder(
  WidgetTester tester,
  ProviderContainer c,
) async {
  c.read(routerProvider).go(AppRoutes.browse);
  await _settle();
  final nav = c.read(desktopBrowseControllerProvider.notifier)
    ..setLayout(ExplorerLayout.grid);
  await _settle();
  final clock = Stopwatch()..start();
  late int firstMs;
  final frames = await _frames(() async {
    nav.open(_root);
    await _waitFor(
      () =>
          find.byType(ExplorerView<BrowseEntry>).evaluate().isNotEmpty &&
          find.byType(Thumbnail).evaluate().isNotEmpty,
    );
    await SchedulerBinding.instance.endOfFrame;
    firstMs = clock.elapsedMilliseconds;
    await _settle(1000);
  });
  _log('open folder: first rows after $firstMs ms, $frames');
  return {'firstRowsMs': firstMs, ...frames};
}

/// A linear scroll of [seconds] at [pxPerSecond] (down, then back up),
/// starting at item [from].
Future<Map<String, Object?>> _scrollRun(
  WidgetTester tester,
  ProviderContainer c, {
  required double pxPerSecond,
  required int seconds,
  required ExplorerLayout layout,
  int from = 0,
}) async {
  final query = c.read(desktopBrowseControllerProvider).filesQuery!;
  final pages = c.read(filePagesProvider(query).notifier);
  while ((c.read(filePagesProvider(query)).value?.items.length ?? 0) <
      from + 200) {
    await pages.loadMore();
  }
  await _settle(300);
  final view = tester.state<ExplorerViewState<BrowseEntry>>(
    find.byType(ExplorerView<BrowseEntry>),
  );
  final pos = _explorerScroll<BrowseEntry>(tester);
  if (from == 0) {
    pos.jumpTo(0);
  } else {
    view.revealIndex(from);
  }
  await _settle(from == 0 ? 500 : 3000);
  final distance = pxPerSecond * seconds;
  final half = Duration(milliseconds: seconds * 500);
  final frames = await _frames(() async {
    await pos.animateTo(
      pos.pixels + distance / 2,
      duration: half,
      curve: Curves.linear,
    );
    await pos.animateTo(
      pos.pixels - distance / 2,
      duration: half,
      curve: Curves.linear,
    );
  });
  _log('scroll ${layout.name} from $from: $frames');
  return frames;
}

/// Desktop Sort: Home, then K (Keep) 200 times at 5 per second.
Future<Map<String, Object?>> _sortRun(
  WidgetTester tester,
  ProviderContainer c,
) async {
  c.read(routerProvider).go(AppRoutes.swipe);
  await _waitFor(
    () => c.read(swipeDeckControllerProvider).value?.current != null,
    timeout: const Duration(minutes: 2),
  );
  await _settle(3000); // the visible thumbnails load
  await _press(tester, LogicalKeyboardKey.home, PhysicalKeyboardKey.home);
  await _settle(500);
  final (blankBefore, seenBefore) = _blankTiles();
  final latencies = <double>[];
  var blankAfter = 0;
  var tilesSeen = 0;
  final frames = await _frames(() async {
    for (var i = 0; i < 200; i++) {
      final before = c.read(swipeDeckControllerProvider).value!.current!.id;
      final clock = Stopwatch()..start();
      await _press(
        tester,
        LogicalKeyboardKey.keyK,
        PhysicalKeyboardKey.keyK,
        'k',
      );
      try {
        await _waitFor(
          () =>
              c.read(swipeDeckControllerProvider).value?.current?.id != before,
          timeout: const Duration(seconds: 5),
        );
      } on TimeoutException {
        final deck = c.read(swipeDeckControllerProvider).value;
        _log(
          'key $i did nothing: current $before, '
          'upcoming ${deck?.upcoming.length}, '
          'focus ${FocusManager.instance.primaryFocus}',
        );
        rethrow;
      }
      // The frame that shows the change.
      await SchedulerBinding.instance.endOfFrame;
      latencies.add(clock.elapsedMicroseconds / 1000);
      // Tiles still waiting for their thumbnail in that frame.
      final (blank, seen) = _blankTiles();
      blankAfter += blank;
      tilesSeen += seen;
      final rest = 200 - clock.elapsedMilliseconds;
      if (rest > 0) await Future<void>.delayed(Duration(milliseconds: rest));
    }
  });
  latencies.sort();
  final out = {
    'keyToFrameP50Ms': latencies[latencies.length ~/ 2].toStringAsFixed(1),
    'keyToFrameP90Ms': latencies[(latencies.length * .9).floor()]
        .toStringAsFixed(1),
    'keyToFrameWorstMs': latencies.last.toStringAsFixed(1),
    'blankTilesBefore': '$blankBefore of $seenBefore',
    'blankTilesAfterKey': '$blankAfter of $tilesSeen',
    ...frames,
  };
  _log('sort: $out');
  return out;
}

/// A key press (profile builds have no key debug names, so the physical
/// key is given).
Future<void> _press(
  WidgetTester tester,
  LogicalKeyboardKey key,
  PhysicalKeyboardKey physical, [
  String? character,
]) async {
  await tester.sendKeyDownEvent(
    key,
    platform: 'windows',
    physicalKey: physical,
    character: character,
  );
  await tester.sendKeyUpEvent(key, platform: 'windows', physicalKey: physical);
}

/// Thumbnails on screen still showing their placeholder: (blank, all).
(int, int) _blankTiles() {
  var blank = 0;
  var seen = 0;
  for (final e
      in find
          .descendant(
            of: find.byType(Thumbnail),
            matching: find.byType(AnimatedOpacity),
          )
          .evaluate()) {
    seen++;
    if ((e.widget as AnimatedOpacity).opacity < 1) blank++;
  }
  return (blank, seen);
}
