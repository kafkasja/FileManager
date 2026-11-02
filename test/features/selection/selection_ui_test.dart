import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/selection/domain/selection_state.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';
import 'package:kfm/features/swipe/ui/file_viewer.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

const _root = '/storage/emulated/0';

FakeFileSource _library() {
  final files = FakeFileSource();
  final t = DateTime.utc(2025);
  var i = 0;
  for (final name in ['c1.jpg', 'c2.jpg', 'c3.jpg']) {
    files.addFile(
      '$_root/DCIM/Camera/$name',
      modifiedAt: t.add(Duration(minutes: i++)),
    );
  }
  return files;
}

Finder _tile(String name) => find.bySemanticsLabel(name);

void main() {
  testWidgets('select adds only, edit removes only, clear all can be undone', (
    tester,
  ) async {
    final app = await pumpApp(tester, files: _library());
    SelectionState state() =>
        app.container.read(selectionControllerProvider).value!;
    String id(String name) => 'path:$_root/DCIM/Camera/$name';

    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();

    // Long-press enters Select mode with that file selected.
    await tester.longPress(_tile('c1.jpg'));
    await tester.pumpAndSettle();
    expect(state().mode, SelectionMode.select);
    expect(state().ids, {id('c1.jpg')});
    expect(
      find.text('Tap to add · Long-press and drag to add many'),
      findsOneWidget,
    );

    // Tapping a selected file again keeps it (first time: the tip).
    await tester.tap(_tile('c1.jpg'));
    await tester.pumpAndSettle();
    expect(state().ids, {id('c1.jpg')});
    expect(find.textContaining('use Edit selection'), findsOneWidget);
    await tester.tap(_tile('c2.jpg'));
    await tester.pumpAndSettle();
    expect(state().ids, {id('c1.jpg'), id('c2.jpg')});

    // Leaving Select mode keeps the selection and the bar.
    await tester.tap(find.byTooltip('Leave select mode'));
    await tester.pumpAndSettle();
    expect(state().mode, SelectionMode.normal);
    expect(find.textContaining('2 selected'), findsOneWidget);

    // Snackbars sit above the shell's menus.
    void hideSnackBars() => tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .removeCurrentSnackBar();
    hideSnackBars();
    await tester.pumpAndSettle();

    // Edit selection: tap removes a selected file, unselected do nothing.
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    // X2's "Share" made the More menu longer.
    await tester.ensureVisible(find.text('Edit selection').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit selection').last);
    await tester.pumpAndSettle();
    expect(state().mode, SelectionMode.edit);
    await tester.tap(_tile('c3.jpg'));
    await tester.pumpAndSettle();
    expect(state().ids, {id('c1.jpg'), id('c2.jpg')});
    await tester.tap(_tile('c1.jpg'));
    await tester.pumpAndSettle();
    expect(state().ids, {id('c2.jpg')});
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(state().ids, {id('c1.jpg'), id('c2.jpg')});
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(state().mode, SelectionMode.select);

    // Clear all, then Undo.
    hideSnackBars();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    // N11's "Move to device" made the More sheet longer.
    await tester.ensureVisible(find.text('Clear all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(state().isEmpty, isTrue);
    expect(find.text('Selection cleared (2 files)'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(state().ids, {id('c1.jpg'), id('c2.jpg')});

    // Back leaves Select mode; then a tap opens the file again.
    final back = find.byTooltip('Leave select mode');
    await tester.tap(back);
    await tester.pumpAndSettle();
    await tester.tap(_tile('c3.jpg'));
    await tester.pumpAndSettle();
    expect(find.byType(PagedFileViewer), findsOneWidget);
    expect(state().count, 2);
  });
}
