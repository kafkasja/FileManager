import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/tables/pending_deletes_table.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

/// PL1: trash-mode deletes on a drive without a Recycle Bin ask once per
/// batch; Cancel keeps them queued, Delete permanently deletes them.
Future<TestApp> _swipeTwoAndFinish(WidgetTester tester) async {
  final files = FakeFileSource();
  for (var i = 0; i < 3; i++) {
    final f = files.addFile(
      '/s/DCIM/p$i.jpg',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
    );
    files.noTrash.add(f.id);
  }
  final app = await pumpApp(tester, files: files);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
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

void main() {
  testWidgets('Cancel keeps the files queued', (tester) async {
    final app = await _swipeTwoAndFinish(tester);
    expect(
      find.text(
        'This drive has no Recycle Bin. Delete these 2 files permanently?',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(app.files.files, hasLength(3), reason: 'nothing deleted');
    final rows = await app.db.select(app.db.pendingDeletes).get();
    expect(rows, hasLength(2));
    expect(rows.every((r) => r.status == PendingDeleteStatus.queued), isTrue);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Delete permanently deletes them as permanent deletes', (
    tester,
  ) async {
    final app = await _swipeTwoAndFinish(tester);
    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();
    expect(app.files.files, hasLength(1));
    final rows = await app.db.select(app.db.pendingDeletes).get();
    expect(rows, hasLength(2));
    expect(rows.every((r) => r.committedMode == 'permanent'), isTrue);
    expect(find.textContaining('Recycle Bin'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });
}
