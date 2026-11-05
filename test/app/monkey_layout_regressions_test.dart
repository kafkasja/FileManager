import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/layout/adaptive_list_tile.dart';
import 'package:kfm/app/widgets/hiding_header.dart';
import 'package:kfm/features/browse/ui/widgets/sources_row.dart';
import 'package:kfm/features/filters/ui/filter_sheet.dart';
import 'package:kfm/features/presets/ui/save_preset_dialog.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_setup_strip.dart';

import '../core/files/fake_file_source.dart';
import '../helpers/pump_app.dart';

/// Layout bugs the monkey test (test/monkey) found on the phone.
FakeFileSource _library() {
  final files = FakeFileSource();
  for (var i = 0; i < 4; i++) {
    files.addFile(
      '/s/DCIM/p$i.jpg',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
    );
  }
  files.addFile('/s/Download/a.pdf', modifiedAt: DateTime.utc(2025));
  return files;
}

Future<void> _browse(
  WidgetTester tester, {
  required Size dp,
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = dp * 2
    ..devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await pumpApp(tester, files: _library());
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.folder_outlined).last);
  await tester.pumpAndSettle();
}

void main() {
  // E4: one header rule at every height (HidingHeaderSliver).
  testWidgets('Browse fits a phone in landscape (the header hides)', (
    tester,
  ) async {
    await _browse(tester, dp: const Size(780, 360), textScale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.byType(HidingHeaderSliver), findsOneWidget);
  });

  testWidgets('Browse uses the same hiding header on a portrait phone', (
    tester,
  ) async {
    await _browse(tester, dp: const Size(360, 780));
    expect(tester.takeException(), isNull);
    expect(find.byType(HidingHeaderSliver), findsOneWidget);
    expect(find.byType(NestedScrollView), findsNothing);
  });

  testWidgets('the sort sheet scrolls on a phone in landscape', (tester) async {
    await _browse(tester, dp: const Size(640, 360));
    await tester.tap(find.byIcon(Icons.sort).first);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kind chips grow with big text instead of being clipped', (
    tester,
  ) async {
    await _browse(tester, dp: const Size(360, 780), textScale: 2);
    final chip = find.descendant(
      of: find.byType(KindChipsRow),
      matching: find.byType(ChoiceChip),
    );
    expect(
      tester.getSize(find.byType(KindChipsRow)).height,
      greaterThanOrEqualTo(tester.getSize(chip.first).height),
    );
    expect(tester.getSize(find.byType(KindChipsRow)).height, greaterThan(48));
  });

  testWidgets('AdaptiveListTile moves a wide trailing widget under the text '
      'in a narrow row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: ListView(
                children: [
                  AdaptiveListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text('Taken within'),
                    trailing: DropdownButton<int>(
                      value: 600,
                      onChanged: (_) {},
                      items: const [
                        DropdownMenuItem(
                          value: 600,
                          child: Text('600 seconds, ten minutes'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.trailing, isNull);
  });

  testWidgets('the filter sheet buttons fit a phone at the biggest text', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester, files: _library());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    unawaited(showFilterSheet(tester.element(find.byType(SwipeSetupStrip))));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Apply'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialogs with a text field scroll on a small phone at big text', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(640, 1136)
      ..devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester, files: _library());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    unawaited(
      showSavePresetDialog(
        tester.element(find.byType(SwipeSetupStrip)),
        layout: SwipeLayout.decode(''),
        filterJson: '{"v":1}',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
