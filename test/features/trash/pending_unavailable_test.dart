import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/tables/pending_deletes_table.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

Future<TestApp> _pumpAndFail(WidgetTester tester) async {
  final files = FakeFileSource();
  for (var i = 0; i < 3; i++) {
    final f = files.addFile(
      '/s/DCIM/p$i.jpg',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
    );
    files.folderUnavailable.add(f.id);
  }
  final app = await pumpApp(tester, files: files);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  // Two swipes left, then Done: both hit the unusable folder.
  for (var i = 0; i < 2; i++) {
    await tester.drag(find.byType(SwipeCard), const Offset(-500, 0));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Finish'));
  await tester.pumpAndSettle();
  return app;
}

Finder _inSheet(Finder f) =>
    find.descendant(of: find.byType(BottomSheet), matching: f);

void main() {
  testWidgets('Done → snackbar → Options → sheet; confirm before deleting', (
    tester,
  ) async {
    final app = await _pumpAndFail(tester);
    expect(
      find.text("2 files weren't deleted. Find them in Trash."),
      findsOneWidget,
    );
    expect(app.files.files, hasLength(3), reason: 'nothing deleted');
    await tester.tap(find.text('Options'));
    await tester.pumpAndSettle();
    expect(
      _inSheet(find.text("Couldn't move to the pending-delete folder")),
      findsOneWidget,
    );
    expect(_inSheet(find.textContaining("can't be restored")), findsOneWidget);
    expect(_inSheet(find.text('p2.jpg')), findsOneWidget);

    // Cancel: nothing happens.
    await tester.tap(_inSheet(find.text('Delete all 2 permanently')));
    await tester.pumpAndSettle();
    expect(
      find.text("Delete 2 files permanently? This can't be undone."),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(app.files.files, hasLength(3));

    // One file, confirmed.
    await tester.tap(_inSheet(find.byTooltip('Delete permanently')).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete permanently'));
    await tester.pumpAndSettle();
    expect(app.files.files, hasLength(2));
    final rows = await app.db.select(app.db.pendingDeletes).get();
    expect(rows.where((r) => r.committedMode == 'permanent'), hasLength(1));
    expect(find.text('1 file deleted permanently'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('the Trash page lists them after Done; Keep removes the row', (
    tester,
  ) async {
    final app = await _pumpAndFail(tester);
    app.container.read(routerProvider).go(AppRoutes.trash);
    await tester.pumpAndSettle();
    expect(find.text("Couldn't move to the pending folder"), findsOneWidget);
    await tester.tap(find.text('Keep').first);
    await tester.pumpAndSettle();
    final rows = await app.db.select(app.db.pendingDeletes).get();
    expect(
      rows.where((r) => r.status == PendingDeleteStatus.failed),
      hasLength(1),
    );
    expect(app.files.files, hasLength(3));
    await tester.tap(find.text('Keep').first);
    await tester.pumpAndSettle();
    expect(find.text("Couldn't move to the pending folder"), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });
}
