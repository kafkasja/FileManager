import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/platform/windows/windows_clipboard.dart';
import 'package:kfm/desktop/browse/desktop_browse_controller.dart';

import '../core/files/fake_file_source.dart';
import '../helpers/pump_app.dart';
import 'desktop_helpers.dart';

/// The Windows clipboard, in memory.
class _FakeClipboard implements SystemFileClipboard {
  List<String> paths = const [];
  bool cut = false;
  int sequence = 1;

  /// What Explorer does on Ctrl+C / Ctrl+X.
  void explorerPut(List<String> p, {bool isCut = false}) {
    paths = p;
    cut = isCut;
    sequence++;
  }

  @override
  Future<int?> write(List<String> p, {required bool cut}) async {
    explorerPut(p, isCut: cut);
    return sequence;
  }

  @override
  Future<SystemClip?> read() async =>
      SystemClip(paths: paths, cut: cut, sequence: sequence);

  @override
  Future<void> clear() async {
    paths = const [];
    sequence++;
  }
}

FakeFileSource _library() => FakeFileSource()
  ..addFile('/s/DCIM/a.jpg', modifiedAt: DateTime.utc(2025))
  ..addFile('/s/Other/o.jpg', modifiedAt: DateTime.utc(2025))
  ..addFile('/x/Explorer/e.jpg', modifiedAt: DateTime.utc(2025));

Future<(TestApp, _FakeClipboard)> _open(WidgetTester tester) async {
  final clip = _FakeClipboard();
  final app = await pumpDesktopApp(
    tester,
    files: _library(),
    overrides: [systemFileClipboardProvider.overrideWithValue(clip)],
  );
  await tester.tap(find.byKey(const ValueKey('desktop-nav-browse')));
  await tester.pumpAndSettle();
  app.container.read(desktopBrowseControllerProvider.notifier).open('/s/DCIM');
  await tester.pumpAndSettle();
  return (app, clip);
}

Future<void> _ctrl(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

List<String> _folders(TestApp app, String name) => [
  for (final f in app.files.files)
    if (f.name == name) f.folderPath,
];

void main() {
  testWidgets('Ctrl+C puts the files on the Windows clipboard too', (
    tester,
  ) async {
    final (_, clip) = await _open(tester);
    await tester.tap(find.text('a.jpg'));
    await tester.pumpAndSettle();
    await _ctrl(tester, LogicalKeyboardKey.keyX);
    expect(clip.paths, ['/s/DCIM/a.jpg']);
    expect(clip.cut, isTrue);
  });

  testWidgets('files copied in Explorer paste into Browse (copy)', (
    tester,
  ) async {
    final (app, clip) = await _open(tester);
    clip.explorerPut(['/x/Explorer/e.jpg']);
    await _ctrl(tester, LogicalKeyboardKey.keyV);
    expect(_folders(app, 'e.jpg'), unorderedEquals(['/x/Explorer', '/s/DCIM']));
    expect(clip.paths, isNotEmpty);
  });

  testWidgets('an Explorer cut moves (with Undo) and empties the clipboard; '
      "a newer Explorer copy wins over KFM's older one", (tester) async {
    final (app, clip) = await _open(tester);
    // KFM copy first, then Explorer cuts something else: Explorer's wins.
    await tester.tap(find.text('a.jpg'));
    await tester.pumpAndSettle();
    await _ctrl(tester, LogicalKeyboardKey.keyC);
    clip.explorerPut(['/x/Explorer/e.jpg'], isCut: true);
    await _ctrl(tester, LogicalKeyboardKey.keyV);
    expect(_folders(app, 'e.jpg'), ['/s/DCIM']);
    expect(_folders(app, 'a.jpg'), ['/s/DCIM']);
    expect(clip.paths, isEmpty);
    await tester.tap(find.byKey(const ValueKey('browse-undo')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(_folders(app, 'e.jpg'), ['/x/Explorer']);
  });
}
