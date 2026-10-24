import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

Future<TestApp> _pump(WidgetTester tester) async {
  final files = FakeFileSource()
    ..addFile(
      '/s/Pictures/Screenshots/s1.png',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, 1),
    )
    ..addFile(
      '/s/Pictures/Screenshots/s2.png',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, 2),
    )
    ..addFile(
      '/s/DCIM/Camera/p1.jpg',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, 3),
    )
    ..addFile(
      '/s/DCIM/Camera/v1.mp4',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, 4),
    );
  final app = await pumpApp(tester, files: files);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return app;
}

List<String> _deckNames(TestApp app) => [
  for (final f
      in app.container.read(swipeDeckControllerProvider).value!.upcoming)
    f.name,
];

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.filter_list));
  await tester.pumpAndSettle();
}

Future<void> _settleCount(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('screenshots only: live count, then the deck shows only them', (
    tester,
  ) async {
    final app = await _pump(tester);
    expect(_deckNames(app), hasLength(4));
    await _openSheet(tester);
    await _settleCount(tester);
    expect(find.text('4 files match'), findsOneWidget);

    await tester.tap(find.text('Screenshots only'));
    await _settleCount(tester);
    expect(find.text('2 files match'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(_deckNames(app), ['s2.png', 's1.png']);
    expect(find.text('0 done · 2 left'), findsOneWidget);

    // Stored on the session: a restart keeps it.
    await app.container.read(dbWriteQueueProvider).flush();
    final session = await app.container
        .read(sessionRepositoryProvider)
        .active();
    expect(
      FileFilter.decode(session!.filterJson),
      const FileFilter(screenshotsOnly: true),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('no matches: empty state with "Change filter"; Reset clears', (
    tester,
  ) async {
    final app = await _pump(tester);
    await _openSheet(tester);
    await tester.tap(find.text('Videos'));
    await tester.tap(find.text('Screenshots only'));
    await _settleCount(tester);
    expect(find.text('No files match'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(find.text('No files match this filter'), findsOneWidget);

    await tester.tap(find.text('Change filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Reset'));
    await _settleCount(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(_deckNames(app), hasLength(4));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the live count equals the files then swiped', (tester) async {
    final app = await _pump(tester);
    await _openSheet(tester);
    await tester.tap(find.text('Photos'));
    await _settleCount(tester);
    expect(find.text('3 files match'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(_deckNames(app), hasLength(3));
    await tester.pump(const Duration(seconds: 1));
  });
}
