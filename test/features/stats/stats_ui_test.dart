import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';

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

void main() {
  testWidgets('Done shows the session summary', (tester) async {
    await _pump(tester);
    for (var i = 0; i < 2; i++) {
      await tester.drag(find.byType(SwipeCard), const Offset(500, 0));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Finish'));
    await tester.pumpAndSettle();
    expect(find.text('Session finished'), findsOneWidget);
    expect(find.text('You reviewed 2 files'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pumpAndSettle();
    expect(find.text('Session finished'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the Stats screen shows the totals', (tester) async {
    final app = await _pump(tester);
    await tester.drag(find.byType(SwipeCard), const Offset(500, 0));
    await tester.pumpAndSettle();
    app.container.read(routerProvider).go(AppRoutes.stats);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('All time'), findsOneWidget);
    expect(find.textContaining('1 file reviewed'), findsWidgets);
    expect(find.textContaining('in trash'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });
}
