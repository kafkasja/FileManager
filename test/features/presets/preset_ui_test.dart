import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/presets/ui/preset_chip.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

Future<TestApp> _pump(WidgetTester tester) async {
  final files = FakeFileSource();
  for (var i = 0; i < 4; i++) {
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

Finder _chipLabel(String text) =>
    find.descendant(of: find.byType(PresetChip), matching: find.text(text));

void main() {
  testWidgets('fresh install: no chip; Presets shows the examples', (
    tester,
  ) async {
    final app = await _pump(tester);
    expect(find.byType(ActionChip), findsNothing);
    app.container.read(routerProvider).go(AppRoutes.presets);
    await tester.pumpAndSettle();
    expect(find.text('No presets yet'), findsOneWidget);
    expect(find.text('Quick cleanup'), findsOneWidget);
  });

  testWidgets('save as preset → chip appears → switching uses it', (
    tester,
  ) async {
    final app = await _pump(tester);
    app.container.read(routerProvider).go(AppRoutes.customizeSwipes);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save as preset…'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save as preset…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Mine');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Saved “Mine”'), findsOneWidget);

    app.container.read(routerProvider).go(AppRoutes.swipe);
    await tester.pump(const Duration(seconds: 5)); // let the snackbar go
    await tester.pumpAndSettle();
    expect(_chipLabel('Basic'), findsOneWidget);
    await tester.tap(find.byType(PresetChip));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mine'));
    await tester.pumpAndSettle();
    expect(_chipLabel('Mine'), findsOneWidget);
    final deck = app.container.read(swipeDeckControllerProvider).value!;
    expect(deck.session.presetId, isNotNull);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('the editor changes the saved preset; Back without saving '
      'asks first', (tester) async {
    final app = await _pump(tester);
    final id = await app.container
        .read(presetRepositoryProvider)
        .create(name: 'Edit me', layout: SwipeLayout.basic);
    app.container.read(routerProvider).go(AppRoutes.presetEditorFor(id));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Swipe up'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Keep'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    final saved = await app.container.read(presetRepositoryProvider).byId(id);
    expect(
      (saved! as Preset).layout.actionFor(SwipeDirection.up),
      SwipeAction.keep,
    );
  });
}
