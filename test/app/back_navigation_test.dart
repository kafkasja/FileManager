import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/browse/ui/browse_screen.dart';
import 'package:kfm/features/browse/ui/widgets/file_results_view.dart';
import 'package:kfm/features/settings/ui/settings_screen.dart';
import 'package:kfm/features/swipe/ui/swipe_screen.dart';
import 'package:kfm/features/trash/ui/trash_screen.dart';

import '../core/files/fake_file_source.dart';
import '../helpers/pump_app.dart';

/// TASK-E4 (A6): system back on the root of Browse, Trash or Settings goes
/// to the Swipe tab first; the tabs' own back steps (folder up) run first.
void main() {
  FakeFileSource library() =>
      FakeFileSource()..addFile('/storage/emulated/0/DCIM/Camera/c1.jpg');

  Future<bool> systemBack(WidgetTester tester) async {
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    return handled;
  }

  for (final (tab, type) in [
    ('Browse', BrowseScreen),
    ('Trash', TrashScreen),
    ('Settings', SettingsScreen),
  ]) {
    testWidgets('back on $tab goes to Swipe', (tester) async {
      await pumpApp(tester, files: library());
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(find.byType(type), findsOneWidget);
      expect(await systemBack(tester), isTrue);
      expect(find.byType(SwipeScreen), findsOneWidget);
      expect(find.byType(type), findsNothing);
    });
  }

  testWidgets('in a Browse folder, back goes up first', (tester) async {
    final app = await pumpApp(tester, files: library());
    await tester.tap(find.text('Browse').last);
    await tester.pumpAndSettle();
    app.container.read(browseViewControllerProvider.notifier)
      ..setLayout(BrowseLayout.folders)
      ..openFolder('/storage/emulated/0/DCIM');
    await tester.pumpAndSettle();
    await systemBack(tester);
    expect(find.byType(BrowseScreen), findsOneWidget);
    expect(
      app.container.read(browseViewControllerProvider).folder,
      '/storage/emulated/0',
    );
  });

  testWidgets('tapping Browse again scrolls its list to the top', (
    tester,
  ) async {
    final files = FakeFileSource();
    for (var i = 0; i < 120; i++) {
      files.addFile(
        '/storage/emulated/0/DCIM/Camera/p$i.jpg',
        modifiedAt: DateTime.utc(2025).add(Duration(minutes: i)),
      );
    }
    await pumpApp(tester, files: files);
    await tester.tap(find.text('Browse').last);
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(FileResultsView),
          matching: find.byType(Scrollable),
        )
        .first;
    final position = tester.state<ScrollableState>(scrollable).position
      ..jumpTo(1500);
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0));
    await tester.tap(find.text('Browse').last);
    await tester.pumpAndSettle();
    expect(position.pixels, 0);
  });

  testWidgets('back on Swipe leaves the app (not handled)', (tester) async {
    await pumpApp(tester, files: library());
    expect(find.byType(SwipeScreen), findsOneWidget);
    expect(await systemBack(tester), isFalse);
  });
}
