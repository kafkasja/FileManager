import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/tables/session_actions_table.dart';
import 'package:kfm/desktop/compare/compare_view.dart';
import 'package:kfm/desktop/sort/desktop_sort_screen.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

import 'desktop_helpers.dart';

Finder _inCompare(String text) =>
    find.descendant(of: find.byType(CompareView), matching: find.text(text));

void main() {
  testWidgets('Compare: best kept, number keys switch, zoom is shared, '
      'Remove runs C2 removal', (tester) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(3));
    final members = app.container
        .read(swipeDeckControllerProvider)
        .value!
        .upcoming
        .toList();
    final context = tester.element(find.byType(DesktopSortScreen));
    unawaited(showCompareView(context, members: members));
    await tester.pumpAndSettle();
    expect(find.byType(CompareView), findsOneWidget);
    expect(_inCompare('Keep'), findsOneWidget);
    expect(_inCompare('Remove'), findsNWidgets(2));
    expect(_inCompare('Remove 2 (Enter)'), findsOneWidget);
    // 2 = keep the second one too.
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pumpAndSettle();
    expect(_inCompare('Keep'), findsNWidgets(2));
    expect(_inCompare('Remove 1 (Enter)'), findsOneWidget);
    // One zoom for all panels.
    await tester.tap(find.byKey(const ValueKey('compare-zoom-in')));
    await tester.pumpAndSettle();
    final viewers = tester
        .widgetList<InteractiveViewer>(find.byType(InteractiveViewer))
        .toList();
    expect(viewers, hasLength(3));
    expect(
      viewers.map((v) => v.transformationController).toSet(),
      hasLength(1),
    );
    expect(
      viewers.first.transformationController!.value.getMaxScaleOnAxis(),
      closeTo(1.5, 0.001),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(CompareView), findsNothing);
    await app.container.read(dbWriteQueueProvider).flush();
    final rows = await app.db.select(app.db.sessionActions).get();
    expect([
      for (final r in rows)
        if (r.status == ActionStatus.applied) '${r.actionType}:${r.fileId}',
    ], contains('trash:${members.last.id}'));
    await tester.pump(const Duration(seconds: 5));
  });
}
