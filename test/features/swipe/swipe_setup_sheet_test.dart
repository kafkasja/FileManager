import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/presets/ui/active_preset_controller.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/session/domain/remote_deck_root.dart';
import 'package:kfm/features/session/domain/session_source.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_setup_sheet.dart';
import 'package:kfm/features/swipe/ui/swipe_setup_strip.dart';

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

Finder _inSheet(String text) =>
    find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

Finder _sheetScrollable() => find
    .descendant(
      of: find.byType(BottomSheet).last,
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _openSetup(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Swipe setup'));
  await tester.pumpAndSettle();
}

Future<void> _assignUp(WidgetTester tester, String action) async {
  final up = find.descendant(
    of: find.byType(BottomSheet),
    matching: find.byIcon(Icons.arrow_upward),
  );
  await tester.scrollUntilVisible(up, -100, scrollable: _sheetScrollable());
  await tester.pumpAndSettle();
  await tester.tap(up);
  await tester.pumpAndSettle();
  final option = find.descendant(
    of: find.byType(BottomSheet).last,
    matching: find.text(action),
  );
  await tester.scrollUntilVisible(option, 100, scrollable: _sheetScrollable());
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Future<void> _tapInSheet(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    _inSheet(text),
    100,
    scrollable: _sheetScrollable(),
  );
  // Keep it clear of whatever sits at the bottom edge.
  await tester.drag(_sheetScrollable(), const Offset(0, -150));
  await tester.pumpAndSettle();
  await tester.tap(_inSheet(text));
  await tester.pumpAndSettle();
}

SwipeLayout _deckLayout(TestApp app) =>
    app.container.read(swipeDeckControllerProvider).value!.session.layout;

void main() {
  testWidgets('switching in the sheet is one tap; an edit marks the preset '
      'modified; Save, Revert and Save as new', (tester) async {
    final app = await _pump(tester);
    final repo = app.container.read(presetRepositoryProvider);
    final id = await repo.create(name: 'Screens', layout: SwipeLayout.basic);
    await tester.pumpAndSettle();

    await _openSetup(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.widgetWithText(ChoiceChip, 'Screens'),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      app.container.read(swipeDeckControllerProvider).value!.session.presetId,
      id,
    );
    expect(_inSheet('Changes not saved to Screens'), findsNothing);

    // S6-3 a: applies at once, the preset isn't touched.
    await _assignUp(tester, 'Add to favorites');
    expect(
      _deckLayout(app).actionFor(SwipeDirection.up)?.type,
      SwipeActionType.favorite,
    );
    expect(find.byKey(const ValueKey('preset-modified-dot')), findsOneWidget);
    expect(((await repo.byId(id))! as Preset).layout, SwipeLayout.basic);

    // Save → into the preset; not modified any more.
    await _tapInSheet(tester, 'Save');
    await app.container.read(dbWriteQueueProvider).flush();
    await tester.pumpAndSettle();
    expect(find.text('Saved to “Screens”'), findsOneWidget);
    final saved = (await repo.byId(id))! as Preset;
    expect(
      saved.layout.actionFor(SwipeDirection.up)?.type,
      SwipeActionType.favorite,
    );
    expect(_inSheet('Changes not saved to Screens'), findsNothing);
    expect(find.byKey(const ValueKey('preset-modified-dot')), findsNothing);

    // Another edit, then Revert → back to the saved preset.
    await _assignUp(tester, 'Keep');
    expect(find.byKey(const ValueKey('preset-modified-dot')), findsOneWidget);
    await tester.scrollUntilVisible(
      _inSheet('Changes not saved to Screens'),
      100,
      scrollable: _sheetScrollable(),
    );
    await _tapInSheet(tester, 'Revert');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      _deckLayout(app).actionFor(SwipeDirection.up)?.type,
      SwipeActionType.favorite,
    );
    expect(find.byKey(const ValueKey('preset-modified-dot')), findsNothing);

    // Save as new… → a second preset, active at once (X6 note) with the
    // same session; Screens keeps its saved setup.
    final sessionId = app.container
        .read(swipeDeckControllerProvider)
        .value!
        .session
        .id;
    await _assignUp(tester, 'Keep');
    await _tapInSheet(tester, 'Save as new…');
    await tester.enterText(find.byType(TextField).last, 'Copy');
    await tester.tap(find.widgetWithText(FilledButton, 'Save').last);
    await tester.pumpAndSettle();
    final all = app.container.read(presetsProvider).value!;
    expect(all.map((p) => p.name), containsAll(['Screens', 'Copy']));
    final copy = all.firstWhere((p) => p.name == 'Copy').id;
    expect(app.container.read(activePresetIdProvider).value, copy);
    final session = app.container
        .read(swipeDeckControllerProvider)
        .value!
        .session;
    expect(session.presetId, copy);
    expect(session.id, sessionId);
    expect(find.byKey(const ValueKey('preset-modified-dot')), findsNothing);
    expect(
      ((await repo.byId(id))! as Preset).layout
          .actionFor(SwipeDirection.up)
          ?.type,
      SwipeActionType.favorite,
    );
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('one-tap switching from the strip; Basic again', (tester) async {
    final app = await _pump(tester);
    await app.container
        .read(presetRepositoryProvider)
        .create(name: 'Holiday', layout: SwipeLayout.basic);
    await tester.pumpAndSettle();
    final strip = find.byType(SwipeSetupStrip);
    await tester.tap(find.descendant(of: strip, matching: find.text('Basic')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: strip, matching: find.byType(ChoiceChip)),
      findsNWidgets(2),
    );
    await tester.tap(
      find.descendant(of: strip, matching: find.text('Holiday')),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    // The row folds back; the pill names the new preset.
    expect(
      find.descendant(of: strip, matching: find.byType(ChoiceChip)),
      findsNothing,
    );
    expect(
      find.descendant(of: strip, matching: find.text('Holiday')),
      findsOneWidget,
    );
    expect(app.container.read(activePresetControllerProvider).error, isNull);
    expect(
      app.container.read(swipeDeckControllerProvider).value!.session.presetId,
      isNotNull,
    );
  });

  testWidgets('remote: no presets or filter; blocked actions not offered', (
    tester,
  ) async {
    final app = await _pump(tester);
    final fp = 'ef' * 32;
    await tester.runAsync(
      () => app.container
          .read(sessionRepositoryProvider)
          .startRemote(fp, const RemoteDeckRoot(rootId: 'R1', device: 'Phone')),
    );
    final context = tester.element(find.byType(SwipeSetupStrip));
    unawaited(
      showSwipeSetupSheet(
        context,
        sourceId: remoteSourceId(fp),
        deviceName: 'Phone',
      ),
    );
    await tester.pumpAndSettle();
    expect(_inSheet('Setup for swiping on Phone'), findsOneWidget);
    expect(_inSheet('Presets'), findsNothing);
    expect(_inSheet('Filter'), findsNothing);
    expect(_inSheet('Swipe directions'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byIcon(Icons.arrow_upward),
      ),
    );
    await tester.pumpAndSettle();
    ListTile tile(String text) => tester.widget<ListTile>(
      find.ancestor(of: _inSheet(text), matching: find.byType(ListTile)),
    );
    expect(tile('Move to folder…').enabled, isFalse);
    expect(tile('Add to rename batch').enabled, isFalse);
    expect(tile('Add to favorites').enabled, isTrue);
  });
}
