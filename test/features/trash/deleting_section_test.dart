import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/trash/ui/deleting_section.dart';

import '../../helpers/pump_app.dart';

Future<TestApp> _open(WidgetTester tester) async {
  final app = await pumpApp(tester);
  app.container.read(routerProvider).go(AppRoutes.settings);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byType(DropdownButton<int>),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  return app;
}

Future<int> _days(TestApp app) => app.container
    .read(settingsRepositoryProvider)
    .read(AppSettings.pendingFolderRetentionDays);

Future<void> _openCustom(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButton<int>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Custom…').last);
  await tester.pumpAndSettle();
}

Finder get _save => find.widgetWithText(FilledButton, 'Save');

void main() {
  testWidgets('Custom… → 12 → Save stores 12 and shows "12 days"', (
    tester,
  ) async {
    final app = await _open(tester);
    await _openCustom(tester);
    await tester.enterText(find.byType(TextField), '12');
    await tester.pump();
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(await _days(app), 12);
    expect(
      find.descendant(
        of: find.byType(DeletingSection),
        matching: find.text('12 days'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('0, 91 and empty are rejected', (tester) async {
    final app = await _open(tester);
    await _openCustom(tester);
    for (final input in ['0', '91', '']) {
      await tester.enterText(find.byType(TextField), input);
      await tester.pump();
      expect(find.text('Enter a number from 1 to 90'), findsOneWidget);
      expect(tester.widget<FilledButton>(_save).onPressed, isNull);
    }
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await _days(app), 7);
  });

  testWidgets('a background permission error shows "Turn on"', (tester) async {
    final app = await _open(tester);
    expect(find.textContaining('Automatic cleanup'), findsNothing);
    await app.container
        .read(settingsRepositoryProvider)
        .write(AppSettings.pendingLastPurgeError, 'permissionDenied');
    await tester.pumpAndSettle();
    expect(
      find.text("Automatic cleanup couldn't run: permission needed"),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(DeletingSection),
        matching: find.widgetWithText(TextButton, 'Turn on'),
      ),
      findsOneWidget,
    );
  });
}
