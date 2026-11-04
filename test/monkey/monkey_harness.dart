// Randomized UI ("monkey") testing for lifecycle bugs: use-after-dispose,
// setState/ref after unmount, deactivated ancestors, overflows, uncaught
// async errors. Every run is seeded and prints its action log on failure,
// so `KFM_MONKEY_SEED=<seed>` replays it.
//
// Sizes: KFM_MONKEY_SEEDS (seeds per variant), KFM_MONKEY_ACTIONS (actions
// per seed), KFM_MONKEY_START (first seed), KFM_MONKEY_SEED (one seed only).
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/layout/text_scale.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../core/files/fake_file_source.dart';
import '../features/swipe/fake_video.dart';
import '../helpers/pump_app.dart';

int _envInt(String name, int fallback) =>
    int.tryParse(Platform.environment[name] ?? '') ?? fallback;

/// The seeds to run for a variant (default [defaultSeeds] seeds).
List<int> monkeySeeds({required int defaultSeeds, int offset = 0}) {
  final one = int.tryParse(Platform.environment['KFM_MONKEY_SEED'] ?? '');
  if (one != null) return [one];
  final count = _envInt('KFM_MONKEY_SEEDS', defaultSeeds);
  final start = _envInt('KFM_MONKEY_START', 1) + offset;
  return [for (var i = 0; i < count; i++) start + i];
}

/// KFM_MONKEY_VERBOSE=1 prints every action as it runs.
final bool _verbose = Platform.environment['KFM_MONKEY_VERBOSE'] == '1';

/// Actions per seed.
int monkeyActions(int fallback) => _envInt('KFM_MONKEY_ACTIONS', fallback);

/// A mixed library: photos, videos, documents, archives, hidden and odd
/// names, an empty folder.
FakeFileSource monkeyLibrary() {
  final files = FakeFileSource();
  DateTime at(int i) => DateTime.utc(2025, 3).add(Duration(hours: i * 7));
  var i = 0;
  for (var n = 0; n < 14; n++) {
    files.addFile(
      '/s/DCIM/Camera/IMG_${1000 + n}.jpg',
      modifiedAt: at(i++),
      takenAt: at(i),
      bytes: List.filled(200 + n * 37, n),
    );
  }
  for (var n = 0; n < 4; n++) {
    files.addFile(
      '/s/DCIM/Camera/VID_${2000 + n}.mp4',
      modifiedAt: at(i++),
      mimeType: 'video/mp4',
      bytes: List.filled(5000 + n, 7),
    );
  }
  files
    ..addFile('/s/Pictures/Screenshots/shot.png', modifiedAt: at(i++))
    ..addFile('/s/Pictures/.hidden/secret.jpg', modifiedAt: at(i++))
    ..addFile('/s/Pictures/ünïcödé näme 🎉.jpg', modifiedAt: at(i++))
    ..addFile(
      '/s/Pictures/${'a_very_long_file_name_' * 6}end.jpeg',
      modifiedAt: at(i++),
    )
    ..addFile('/s/Pictures/noextension', modifiedAt: at(i++))
    ..addFile('/s/Pictures/clip.webm', modifiedAt: at(i++))
    ..addFile('/s/Download/report.pdf', modifiedAt: at(i++))
    ..addFile(
      '/s/Download/notes.txt',
      modifiedAt: at(i++),
      bytes: 'hello\nworld\n'.codeUnits,
    )
    ..addFile('/s/Download/broken.zip', modifiedAt: at(i++))
    ..addFile('/s/Download/app.apk', modifiedAt: at(i++))
    ..addFile('/s/Music/song.mp3', modifiedAt: at(i++))
    ..addFile('/s/Documents/.nomedia', modifiedAt: at(i++))
    ..addFolder('/s/Empty')
    ..addFolder('/s/Nested/a/b/c');
  return files;
}

/// One reported error, described when reported: describing it later can
/// walk elements that are gone by then (and report a "deactivated widget's
/// ancestor" error of its own).
class ReportedError {
  new(this.details) : text = _describe(details);

  final FlutterErrorDetails details;
  final String text;

  static String _describe(FlutterErrorDetails d) {
    try {
      return d.toString();
    } on Object {
      return d.exceptionAsString();
    }
  }
}

/// Collects every FlutterError reported while installed.
class ErrorCollector {
  final List<ReportedError> errors = [];
  FlutterExceptionHandler? _previous;

  void install() {
    _previous = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(ReportedError(d));
  }

  void uninstall() => FlutterError.onError = _previous;
}

/// Screen sizes the monkey switches between (physical px, dpr).
const List<(Size, double)> _phoneSizes = [
  (Size(1080, 2340), 3), // phone portrait
  (Size(2340, 1080), 3), // phone landscape
  (Size(640, 1136), 2), // 320 × 568 dp
  (Size(1280, 720), 2), // small phone landscape, 640 × 360 dp
  (Size(1600, 2560), 2), // tablet portrait
  (Size(2560, 1600), 2), // tablet landscape
];

const List<(Size, double)> _desktopSizes = [
  (Size(1280, 800), 1),
  (Size(800, 600), 1), // the window's minimum
  (Size(1920, 1080), 1),
  (Size(1600, 1000), 1.25),
];

/// Runs [actions] random actions on the app; throws a [TestFailure] with
/// the replayable log on the first error.
Future<void> runMonkey(
  WidgetTester tester, {
  required int seed,
  required int actions,
  required Future<TestApp> Function(
    WidgetTester,
    FakeFileSource,
    FakeVideoFactory,
  )
  pump,
  bool desktop = false,
}) async {
  final random = Random(seed);
  final log = <String>[];
  final sizes = desktop ? _desktopSizes : _phoneSizes;
  final first = sizes.first;
  tester.view
    ..physicalSize = first.$1
    ..devicePixelRatio = first.$2;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final collector = ErrorCollector()..install();
  try {
    final app = await pump(tester, monkeyLibrary(), FakeVideoFactory());
    final monkey = _Monkey(tester, app, random, sizes, desktop: desktop);
    // Back to a steady state so the teardown's timers and queries drain
    // (also after a failure, or the teardown can wait forever).
    Future<void> drain() async {
      await monkey.lifecycle(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 30));
      // Zero-length timers started by disposals during the last frame
      // (drift closing a stream query).
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
    }

    try {
      _check(tester, collector, monkey, seed, log, 'start');
      for (var step = 0; step < actions; step++) {
        final what = await monkey.step();
        log.add('$step: $what');
        if (_verbose) debugPrint('monkey $seed/$step: $what');
        _check(tester, collector, monkey, seed, log, what);
      }
      await drain();
      _check(tester, collector, monkey, seed, log, 'drain');
    } on TestFailure {
      await drain();
      tester.takeException();
      collector.errors.clear();
      rethrow;
    }
  } finally {
    collector.uninstall();
  }
}

/// What is open: modal routes, snack bars and their texts (for triage).
String _screenSummary() {
  String texts(Finder of) => find
      .descendant(of: of, matching: find.byType(Text))
      .evaluate()
      .map((e) => (e.widget as Text).data ?? '')
      .where((t) => t.isNotEmpty)
      .take(8)
      .join(' | ');
  final out = StringBuffer();
  try {
    for (final type in [SnackBar, AlertDialog, Dialog, BottomSheet]) {
      final f = find.byType(type);
      if (f.evaluate().isEmpty) continue;
      out.writeln('$type: ${texts(f.first)}');
    }
  } on Object catch (e) {
    // A tree whose layout just failed can't always be walked.
    return '(screen summary failed: $e)';
  }
  return out.isEmpty ? '(no modal or snack bar)' : out.toString().trimRight();
}

/// Known Flutter framework assertions that are not app bugs (see
/// archive/notes/monkey-notes.md): TextPainter's paint-only paragraph
/// rebuild measuring a different size after a text-scale change, and the
/// ones listed inline.
/// Also a SnackBar whose action label is wider than the bar: Material
/// can't shrink or wrap the action (its overflow row is built by the
/// Scaffold; the test font's 1 em glyphs make labels extra wide).
bool _isFrameworkNoise(ReportedError e) {
  final text = e.text;
  final stack = e.details.stack?.toString() ?? '';
  return text.contains("'debugSize == size'") ||
      // A Tooltip's OverlayPortal laid out before its nested Overlay got
      // the new size (sidebar animating / details pane toggled).
      text.contains("'size == theater.size'") ||
      // The same overlay child's layout callback scheduled while it is
      // already laid out ('debugNeedsLayout', from _OverlayPortalElement).
      (text.contains("'debugNeedsLayout'") &&
          stack.contains('_OverlayPortalElement')) ||
      // A popup menu's semantics rect while its route animates in a
      // resized window.
      text.contains('tried to set a non-finite rect') ||
      // TabBarView.didChangeDependencies jumps its PageView during build
      // and the TabBar's tab styles rebuild (desktop Devices → Transfers
      // when the section is left mid tab change).
      (text.contains('called during build') &&
          stack.contains('_TabBarViewState')) ||
      // An open DropdownButton menu dismissed from the button's build when
      // the window turns (its route's secondary animation notifies).
      (text.contains('called during build') &&
          stack.contains('_DropdownButtonState._removeDropdownRoute')) ||
      (text.contains('overflowed by') &&
          text.contains('Scaffold:file:///') &&
          find.byType(SnackBar).evaluate().isNotEmpty);
}

/// Overflows seen outside the supported layout envelope (not failures).
final Set<String> layoutNotes = {};

bool _isOverflow(ReportedError e) => e.text.contains('overflowed by');

void _check(
  WidgetTester tester,
  ErrorCollector collector,
  _Monkey monkey,
  int seed,
  List<String> log,
  String what,
) {
  if (!monkey.layoutSupported) {
    for (final e in collector.errors.where(_isOverflow)) {
      final where = RegExp(r'(\w+):file:///\S*?/(lib/\S+)').firstMatch(e.text);
      final note =
          '${where?.group(2) ?? e.details.exceptionAsString()} '
          '(${monkey.envelope})';
      if (layoutNotes.add(note)) debugPrint('MONKEY NOTE overflow $note');
    }
    collector.errors.removeWhere(_isOverflow);
  }
  for (final e in collector.errors.where(_isFrameworkNoise)) {
    if (layoutNotes.add('framework: ${e.details.exceptionAsString()}')) {
      debugPrint(
        'MONKEY NOTE framework assert ${e.details.exceptionAsString()}',
      );
    }
  }
  collector.errors.removeWhere(_isFrameworkNoise);
  final pending = tester.takeException();
  if (collector.errors.isEmpty && pending == null) return;
  final buf = StringBuffer()
    ..writeln('MONKEY FAILURE seed=$seed after "$what"')
    ..writeln('Replay: KFM_MONKEY_SEED=$seed')
    ..writeln('--- last actions ---');
  log.skip(max(0, log.length - 40)).forEach(buf.writeln);
  buf
    ..writeln('--- screen (${monkey.envelope}) ---')
    ..writeln(_screenSummary())
    ..writeln('--- errors ---');
  if (pending != null) buf.writeln('uncaught: $pending');
  for (final e in collector.errors.take(3)) {
    // Includes the error-causing widget's creation location.
    buf
      ..writeln(e.text.split('\n').take(40).join('\n'))
      ..writeln(
        e.details.stack?.toString().split('\n').take(30).join('\n') ?? '',
      );
  }
  collector.errors.clear();
  throw TestFailure(buf.toString());
}

class _Monkey {
  new(this.tester, this.app, this.random, this.sizes, {required this.desktop});

  final WidgetTester tester;
  final TestApp app;
  final Random random;
  final List<(Size, double)> sizes;
  final bool desktop;
  AppLifecycleState _state = AppLifecycleState.resumed;
  double _platformScale = 1;
  AppTextSize _appSize = AppTextSize.system;

  Size get _logical => tester.view.physicalSize / tester.view.devicePixelRatio;

  double get _textScale => _appSize == AppTextSize.system
      ? _platformScale
      : max(
          _platformScale,
          min(_platformScale * kTextSizeFactor[_appSize]!, 2),
        );

  /// Where overflows count as bugs: portrait phones and desktop windows at
  /// least 700 px high up to the 2.0 text cap (L5); short screens (phones
  /// in landscape, an 800 × 600 window) up to 1.3.
  bool get layoutSupported =>
      _textScale <= 1.3 || _logical.height >= (desktop ? 700 : 500);

  String get envelope =>
      '${_logical.width.round()}×${_logical.height.round()}dp, '
      'text ${_textScale.toStringAsFixed(2)}';

  T _pick<T>(List<T> items) => items[random.nextInt(items.length)];

  String get _location {
    final router = app.container.read(routerProvider);
    return router.routerDelegate.currentConfiguration.uri.toString();
  }

  Future<String> step() async {
    // Wi-Fi connect screens open real sockets; leave them.
    if (_location.startsWith('/connect')) {
      await tester.binding.handlePopRoute();
      await _settleSome();
      return 'leave $_location';
    }
    final roll = random.nextInt(100);
    final String what;
    if (roll < 38) {
      what = await _tap();
    } else if (roll < 43) {
      what = await _tap(long: true);
    } else if (roll < 53) {
      what = await _swipeCard();
    } else if (roll < 58) {
      what = await _fling();
    } else if (roll < 65) {
      await tester.binding.handlePopRoute();
      what = 'system back';
    } else if (roll < 69) {
      what = await _lifecycleTrip();
    } else if (roll < 72) {
      what = _resize();
    } else if (roll < 74) {
      what = _changeTextScale();
    } else if (roll < 76) {
      what = await _setting();
    } else if (roll < 78) {
      what = _brightness();
    } else if (roll < 81) {
      what = await _enterText();
    } else if (roll < 86 && desktop) {
      what = await _key();
    } else if (roll < 90) {
      what = await _drag();
    } else {
      final ms = _pick([0, 16, 50, 120, 300, 800, 2000, 5000]);
      await tester.pump(Duration(milliseconds: ms));
      return 'pump ${ms}ms';
    }
    await _settleSome();
    return what;
  }

  /// A few frames of random length (animations may still run).
  Future<void> _settleSome() async {
    // At least one frame: input never comes faster than the display, and a
    // back press before a pushed route's first frame trips a framework
    // assert (ModalRoute.willPop, scope == null).
    await tester.pump();
    final frames = random.nextInt(4);
    for (var i = 0; i < frames; i++) {
      await tester.pump(
        Duration(milliseconds: _pick([0, 16, 16, 50, 100, 250, 600])),
      );
    }
  }

  bool _tappable(Widget w, {required bool long}) => switch (w) {
    InkResponse(:final onTap, :final onLongPress) =>
      long ? onLongPress != null : onTap != null,
    GestureDetector(:final onTap, :final onLongPress, :final onTapUp) =>
      long ? onLongPress != null : (onTap != null || onTapUp != null),
    Switch(:final onChanged) => !long && onChanged != null,
    Checkbox(:final onChanged) => !long && onChanged != null,
    _ => false,
  };

  /// Taps that end the test on purpose: the debug-only "Throw test error"
  /// row (Settings → Developer, H5) throws an uncaught error by design.
  bool _excluded(Element e) {
    var hit = false;
    void visit(Element c) {
      final w = c.widget;
      if (w is Text && w.data == _l10n(c).devThrowTestError) hit = true;
      if (!hit) c.visitChildElements(visit);
    }

    visit(e);
    return hit;
  }

  AppLocalizations _l10n(Element e) => AppLocalizations.of(e);

  Future<String> _tap({bool long = false}) async {
    final candidates = find
        .byWidgetPredicate((w) => _tappable(w, long: long))
        .hitTestable()
        .evaluate()
        .where((e) => !_excluded(e))
        .toList();
    if (candidates.isEmpty) return 'tap: nothing';
    final element = _pick(candidates);
    final label = _describe(element);
    final center = tester.getCenter(
      find.byElementPredicate((e) => e == element),
    );
    if (long) {
      await tester.longPressAt(center);
    } else {
      await tester.tapAt(center);
    }
    return '${long ? 'long-press' : 'tap'} $label @${center.dx.round()},'
        '${center.dy.round()} on $_location';
  }

  String _describe(Element e) {
    final texts = <String>[];
    void visit(Element c) {
      final w = c.widget;
      if (w is Text && w.data != null) texts.add(w.data!);
      if (w is Icon && w.icon != null) {
        texts.add('icon:${w.icon!.codePoint.toRadixString(16)}');
      }
      if (texts.length < 3) c.visitChildElements(visit);
    }

    visit(e);
    return '${e.widget.runtimeType}${texts.isEmpty ? '' : texts.toString()}';
  }

  Future<String> _swipeCard() async {
    // The top card is painted last.
    final cards = find.byType(SwipeCard);
    final Offset from;
    if (cards.evaluate().isNotEmpty) {
      from = tester.getCenter(cards.last);
    } else {
      final size = tester.view.physicalSize / tester.view.devicePixelRatio;
      from = Offset(size.width / 2, size.height / 2);
    }
    final dir = _pick(const [
      Offset(1, 0),
      Offset(-1, 0),
      Offset(0, -1),
      Offset(0, 1),
      Offset(0.7, -0.7),
    ]);
    final distance = _pick([40.0, 120.0, 400.0, 900.0]);
    final offset = dir * distance;
    if (random.nextBool()) {
      await tester.flingFrom(from, offset, _pick([300.0, 1500.0, 4000.0]));
    } else {
      await tester.dragFrom(from, offset);
    }
    return 'swipe ${offset.dx.round()},${offset.dy.round()} '
        'from ${from.dx.round()},${from.dy.round()} on $_location';
  }

  Future<String> _fling() async {
    final scrollables = find.byType(Scrollable).hitTestable().evaluate();
    if (scrollables.isEmpty) return 'fling: nothing';
    final target = _pick(scrollables.toList());
    final center = tester.getCenter(
      find.byElementPredicate((e) => e == target),
    );
    final up = random.nextBool();
    final horizontal = random.nextInt(4) == 0;
    final d = up ? -600.0 : 600.0;
    await tester.flingFrom(
      center,
      horizontal ? Offset(d, 0) : Offset(0, d),
      _pick([800.0, 3000.0, 8000.0]),
    );
    return 'fling ${horizontal ? 'h' : 'v'}${up ? '-' : '+'} on $_location';
  }

  Future<String> _drag() async {
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    final from = Offset(
      random.nextDouble() * size.width,
      random.nextDouble() * size.height,
    );
    final by = Offset(
      (random.nextDouble() - 0.5) * size.width,
      (random.nextDouble() - 0.5) * size.height,
    );
    final gesture = await tester.startGesture(
      from,
      kind: desktop ? PointerDeviceKind.mouse : PointerDeviceKind.touch,
    );
    const steps = 5;
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(by / steps.toDouble());
      await tester.pump(const Duration(milliseconds: 16));
    }
    // Sometimes the gesture is interrupted mid-way.
    if (random.nextInt(5) == 0) {
      await gesture.cancel();
    } else {
      await gesture.up();
    }
    return 'drag ${from.dx.round()},${from.dy.round()} by '
        '${by.dx.round()},${by.dy.round()} on $_location';
  }

  Future<void> lifecycle(AppLifecycleState target) async {
    const order = [
      AppLifecycleState.resumed,
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ];
    var i = order.indexOf(_state);
    final t = order.indexOf(target);
    while (i != t) {
      i += t > i ? 1 : -1;
      tester.binding.handleAppLifecycleStateChanged(order[i]);
      _state = order[i];
      await tester.pump();
    }
  }

  Future<String> _lifecycleTrip() async {
    final to = _pick(const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]);
    await lifecycle(to);
    await tester.pump(Duration(milliseconds: _pick([0, 100, 2000, 60000])));
    await lifecycle(AppLifecycleState.resumed);
    return 'lifecycle resumed→${to.name}→resumed';
  }

  String _resize() {
    final (size, dpr) = _pick(sizes);
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = dpr;
    return 'resize ${size.width / dpr}×${size.height / dpr}dp';
  }

  String _changeTextScale() {
    final scale = _pick([1.0, 1.0, 1.3, 2.0]);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    _platformScale = scale;
    return 'text scale $scale';
  }

  String _brightness() {
    final b = _pick(Brightness.values);
    tester.platformDispatcher.platformBrightnessTestValue = b;
    return 'platform brightness ${b.name}';
  }

  Future<String> _setting() async {
    final settings = app.container.read(settingsRepositoryProvider);
    switch (random.nextInt(4)) {
      case 0:
        final tag = _pick(['', 'en', 'nl', 'tr']);
        await settings.write(AppSettings.localeTag, tag);
        return 'locale "$tag"';
      case 1:
        final mode = _pick(['system', 'light', 'dark']);
        await settings.write(AppSettings.themeMode, mode);
        return 'theme $mode';
      case 2:
        final size = _pick(AppTextSize.values);
        await settings.write(AppSettings.textSize, size);
        _appSize = size;
        return 'text size ${size.name}';
      default:
        final left = random.nextBool();
        await settings.write(AppSettings.leftHanded, left);
        return 'left-handed $left';
    }
  }

  Future<String> _enterText() async {
    final fields = find.byType(EditableText).hitTestable().evaluate().toList();
    if (fields.isEmpty) return 'text: nothing';
    final field = _pick(fields);
    final text = _pick([
      '',
      'a',
      'IMG',
      'type:video',
      'größe 😀',
      'x' * 300,
      r'../..//\',
      'size>1mb',
    ]);
    await tester.enterText(find.byElementPredicate((e) => e == field), text);
    if (random.nextBool()) {
      await tester.testTextInput.receiveAction(TextInputAction.done);
    }
    return 'enter "${text.length > 20 ? '${text.substring(0, 20)}…' : text}" '
        'on $_location';
  }

  Future<String> _key() async {
    final key = _pick([
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.escape,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.delete,
      LogicalKeyboardKey.backspace,
      LogicalKeyboardKey.keyF,
      LogicalKeyboardKey.keyT,
      LogicalKeyboardKey.keyZ,
      LogicalKeyboardKey.keyC,
      LogicalKeyboardKey.keyV,
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.f2,
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.tab,
    ]);
    final ctrl = random.nextInt(3) == 0;
    if (ctrl) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(key);
    if (ctrl) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    return 'key ${ctrl ? 'ctrl+' : ''}${key.keyLabel} on $_location';
  }
}
