import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_setup_strip.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

Future<TestApp> _pump(WidgetTester tester) async {
  final files = FakeFileSource();
  for (var i = 0; i < 3; i++) {
    files.addFile(
      '/s/DCIM/p$i.jpg',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
    );
  }
  final app = await pumpApp(tester, files: files);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return app;
}

Finder _inStrip(Finder f) =>
    find.descendant(of: find.byType(SwipeSetupStrip), matching: f);

Finder _inSheet(String text) =>
    find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

void main() {
  testWidgets('new user: "Basic · ← trash · → keep" + tune, nothing else', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(SwipeSetupStrip), findsOneWidget);
    expect(_inStrip(find.text('Basic')), findsOneWidget);
    expect(_inStrip(find.textContaining('Move to trash')), findsOneWidget);
    expect(_inStrip(find.textContaining('Keep')), findsOneWidget);
    expect(_inStrip(find.byTooltip('Swipe setup')), findsOneWidget);
    // No presets yet: no ▾, no chips; no filter: no filter icon.
    expect(_inStrip(find.byIcon(Icons.arrow_drop_down)), findsNothing);
    expect(_inStrip(find.byType(ChoiceChip)), findsNothing);
    expect(find.byTooltip('Filter on'), findsNothing);
    // The app bar lost the old preset chip and filter button.
    expect(find.byTooltip('Filter'), findsNothing);
    expect(find.byTooltip('Switch preset'), findsNothing);
  });

  testWidgets('tune → sheet; ↑ → favorite updates the deck and the strip', (
    tester,
  ) async {
    final app = await _pump(tester);
    await tester.tap(find.byTooltip('Swipe setup'));
    await tester.pumpAndSettle();
    expect(_inSheet('Swipe setup'), findsOneWidget);
    expect(_inSheet('Swipe directions'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byIcon(Icons.arrow_upward),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      _inSheet('Add to favorites'),
      100,
      scrollable: find
          .descendant(
            of: find.byType(BottomSheet).last,
            matching: find.byType(Scrollable),
          )
          .last,
    );
    await tester.tap(_inSheet('Add to favorites'));
    await tester.pumpAndSettle();

    final deck = app.container.read(swipeDeckControllerProvider).value!;
    expect(
      deck.session.layout.actionFor(SwipeDirection.up)?.type,
      SwipeActionType.favorite,
    );
    expect(_inStrip(find.textContaining('Add to favorites')), findsOneWidget);
  });

  testWidgets('a filter shows the strip filter icon', (tester) async {
    final app = await _pump(tester);
    await app.container
        .read(swipeDeckControllerProvider.notifier)
        .applyFilter(const FileFilter(screenshotsOnly: true));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Filter on'), findsOneWidget);
  });
}
