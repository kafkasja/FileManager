// Android scroll speed checks (TASK-E4 §2): the real phone app on its own
// database, frame timings from the engine, flings through Browse.
// Seed the emulator first (photos for grid/sametime, documents for list):
//   ADB=… ANDROID_SERIAL=emulator-5554 bash tool/seed_photos.sh -n 5000 -d /sdcard/DCIM/KfmPerf
//   ADB=… ANDROID_SERIAL=emulator-5554 bash tool/seed_docs.sh -n 3000 -d /sdcard/Download/KfmPerfDocs
//   adb shell appops set com.kaf.kfm MANAGE_EXTERNAL_STORAGE allow
//   adb shell pm grant com.kaf.kfm android.permission.READ_MEDIA_IMAGES (+ _VIDEO)
// Run in profile mode, one mode per run (`flutter test test/` never runs it):
//   flutter run --profile -d emulator-5554 -t integration_test/android_scroll_perf_test.dart
//     --dart-define=KFM_PERF_MODE=grid   (or list, sametime)
//     [--dart-define=KFM_PERF_THUMBS=cold1  for a cold thumbnail cache]
// Results: `adb logcat -s flutter | grep PERF` and <appDocs>/perf/<mode>.json.
@TestOn('android')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kfm/app/app.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/browse/ui/same_time_view.dart';
import 'package:kfm/features/browse/ui/widgets/file_results_view.dart';
import 'package:path_provider/path_provider.dart';

const _mode = String.fromEnvironment('KFM_PERF_MODE');

/// The thumbnail cache folder under `<appDocs>/perf` (a new name = cold).
const _thumbs = String.fromEnvironment(
  'KFM_PERF_THUMBS',
  defaultValue: 'thumbs',
);

/// The key placeholder tiles (not loaded yet) carry; counted as blank.
const ValueKey<String> placeholderKey = ValueKey('results-placeholder');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scroll speed: $_mode', skip: _mode.isEmpty, (tester) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/perf')..createSync(recursive: true);
    final results = <String, Object?>{'mode': _mode};
    final app = await _startApp(tester, binding, dir);
    final c = app.container;
    final view = tester.view;
    results['screen'] =
        '${view.physicalSize.width.round()}x${view.physicalSize.height.round()}'
        ' @${view.devicePixelRatio}';

    // --- first index ---------------------------------------------------
    final indexClock = Stopwatch()..start();
    await _waitFor(() {
      final s = c.read(indexStatusProvider).value;
      return s is IndexIdle && s.lastScan != null;
    }, timeout: const Duration(minutes: 20));
    results['firstIndexMs'] = indexClock.elapsedMilliseconds;

    // Browse's view state is auto-disposed without a listener.
    final keep = c.listen(browseViewControllerProvider, (_, _) {});
    final nav = c.read(browseViewControllerProvider.notifier);
    c.read(routerProvider).go(AppRoutes.browse);
    await _settle();
    switch (_mode) {
      case 'list':
        nav
          ..setLayout(BrowseLayout.all)
          ..setKind(FileKind.document);
      case 'sametime':
        nav
          ..setLayout(BrowseLayout.sameTime)
          ..setKind(FileKind.image);
      default:
        nav
          ..setLayout(BrowseLayout.all)
          ..setKind(FileKind.image);
    }
    await _settle(3000);
    final query = c.read(browseViewControllerProvider).query;
    final dao = c.read(mediaIndexDaoProvider);
    final count = await dao.count(query);
    results['files'] = count;

    // Page time of the keyset query (H7 budget: ≤ 50 ms per 1,000 rows).
    final pageClock = Stopwatch()..start();
    var pageRows = 0;
    IndexCursor? next;
    var pages = 0;
    final warmFiles = <FileRef>[];
    do {
      final page = await dao.page(query, after: next, limit: 1000);
      pageRows += page.items.length;
      if (warmFiles.length < 600) warmFiles.addAll(page.items.take(600));
      next = page.next;
      pages++;
    } while (next != null && pages < 5);
    results['pageMsPer1000'] = pageRows == 0
        ? 0
        : (pageClock.elapsedMilliseconds * 1000 / pageRows).round();

    if (_mode != 'list') {
      final cache = await c.read(thumbnailCacheProvider.future);
      final warm = Stopwatch()..start();
      for (var i = 0; i < warmFiles.length; i += 32) {
        await Future.wait([
          for (final f in warmFiles.skip(i).take(32)) cache.get(f),
        ]);
      }
      results['thumbWarmupMs'] = warm.elapsedMilliseconds;
    }

    // The results' own vertical scroll view (not the chips or carousel).
    final scrollable = find
        .descendant(
          of: find.byType(_mode == 'sametime' ? SameTimeView : FileResultsView),
          matching: find.byType(Scrollable),
        )
        .first;
    final position = tester.state<ScrollableState>(scrollable).position
      ..jumpTo(0);
    await _settle(1000);

    var deadStops = 0;
    var blankAfterSettle = 0;
    var tilesSeen = 0;
    var atEnd = false;
    void watchEnd() {
      final hasMore = c.read(filePagesProvider(query)).value?.hasMore ?? false;
      final hit =
          hasMore &&
          position.pixels >= position.maxScrollExtent - 0.5 &&
          position.maxScrollExtent > 0;
      if (hit && !atEnd) deadStops++;
      atEnd = hit;
    }

    position.addListener(watchEnd);
    final frames = await _frames(() async {
      for (final dy in [
        for (var i = 0; i < 10; i++) -2500.0,
        for (var i = 0; i < 10; i++) 2500.0,
      ]) {
        await tester.fling(scrollable, Offset(0, dy), 6000);
        await _waitFor(
          () => !position.isScrollingNotifier.value,
          timeout: const Duration(seconds: 20),
        );
        await _settle(300);
        final (blank, seen) = _blankTiles();
        blankAfterSettle += blank;
        tilesSeen += seen;
      }
    });
    position.removeListener(watchEnd);
    results['flings'] = {
      'deadStops': deadStops,
      'blankAfterSettle': '$blankAfterSettle of $tilesSeen',
      'loaded': c.read(filePagesProvider(query)).value?.items.length,
      ...frames,
    };

    keep.close();
    final json = const JsonEncoder.withIndent('  ').convert(results);
    _log('PERF ${jsonEncode(results)}');
    File('${dir.path}/$_mode.json').writeAsStringSync(json);
    app.container.dispose();
  }, timeout: const Timeout(Duration(minutes: 40)));
}

void _log(String s) => debugPrint('[perf] $s');

class _App {
  new(this.container);

  final ProviderContainer container;
}

Future<_App> _startApp(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  Directory dir,
) async {
  final dbDir = Directory('${dir.path}/db-$_mode');
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
      AppSettings.onboardingExistingChecked.name,
      AppSettings.onboardingExistingChecked.encodeToDb(true),
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
          dir: Directory('${dir.path}/$_thumbs'),
          generator: androidThumbnailGenerator(),
          maxDiskBytes: () async =>
              await settings.read(AppSettings.thumbCacheMaxMb) * 1024 * 1024,
        );
      }),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  return _App(container);
}

Future<void> _waitFor(
  bool Function() test, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final clock = Stopwatch()..start();
  while (!test()) {
    if (clock.elapsed > timeout) throw TimeoutException('waitFor', timeout);
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }
}

Future<void> _settle([int ms = 1500]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

Future<Map<String, Object?>> _frames(Future<void> Function() body) async {
  final timings = <FrameTiming>[];
  void onTimings(List<FrameTiming> t) => timings.addAll(t);
  SchedulerBinding.instance.addTimingsCallback(onTimings);
  try {
    await body();
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
  const budget = 1000 / 60;
  final buildOver = build.where((b) => b > budget).length;
  return {
    'frames': t.length,
    'buildOver16': buildOver,
    'buildOverPct': t.isEmpty
        ? '0'
        : (buildOver * 100 / t.length).toStringAsFixed(2),
    'rasterOver16': raster.where((b) => b > budget).length,
    'buildP50': r(pct(build, .5)),
    'buildP90': r(pct(build, .9)),
    'buildWorst': r(build.fold(0, math.max)),
    'rasterP50': r(pct(raster, .5)),
    'rasterP90': r(pct(raster, .9)),
    'rasterWorst': r(raster.fold(0, math.max)),
  };
}

/// Tiles on screen still blank: thumbnails fading in or not loaded, plus
/// placeholder tiles of rows not loaded yet. (blank, all).
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
    if (!_onScreen(e)) continue;
    seen++;
    if ((e.widget as AnimatedOpacity).opacity < 1) blank++;
  }
  for (final e in find.byKey(placeholderKey).evaluate()) {
    if (!_onScreen(e)) continue;
    seen++;
    blank++;
  }
  return (blank, seen);
}

/// Built inside the viewport (slivers build a cache extent past it).
bool _onScreen(Element e) {
  final box = e.renderObject;
  if (box is! RenderBox || !box.hasSize || !box.attached) return false;
  final top = box.localToGlobal(Offset.zero).dy;
  final screen =
      e.findAncestorWidgetOfExactType<MediaQuery>()?.data.size.height ?? 0;
  return top + box.size.height > 0 && top < screen;
}
