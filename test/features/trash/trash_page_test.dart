import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/tables/session_actions_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/trash/ui/trash_controller.dart';
import 'package:kfm/features/trash/ui/widgets/expiry_badge.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

/// Fake whose trashed items carry locations + expiry like the real ones.
class _TrashSource extends FakeFileSource {
  final Map<String, TrashLocation> location = {};

  @override
  Future<List<TrashedItem>> listTrashed() async => [
    for (final t in await super.listTrashed())
      TrashedItem(
        trashId: t.trashId,
        original: t.original,
        location: location[t.original.id] ?? TrashLocation.systemTrash,
        trashedAt: t.trashedAt,
        expiresAt: t.trashedAt.add(
          location[t.original.id] == TrashLocation.pendingFolder
              ? const Duration(days: 7)
              : const Duration(days: 30),
        ),
      ),
  ];
}

Future<(TestApp, _TrashSource)> _pumpTrash(WidgetTester tester) async {
  final files = _TrashSource();
  final photos = [for (var i = 0; i < 3; i++) files.addFile('/s/DCIM/p$i.jpg')];
  final pdf = files.addFile('/s/Download/a.pdf');
  files.location[pdf.id] = TrashLocation.pendingFolder;
  await files.trashBatch([...photos, pdf]);
  final app = await pumpApp(tester, files: files);
  await tester.tap(find.text('Trash').last);
  await tester.pumpAndSettle();
  return (app, files);
}

void main() {
  test('days left rounds down; under a day = today', () {
    final now = DateTime.utc(2026);
    expect(daysLeft(now.add(const Duration(hours: 10)), now), 0);
    expect(daysLeft(now.add(const Duration(hours: 45)), now), 1);
    expect(daysLeft(now.subtract(const Duration(days: 1)), now), 0);
  });

  testWidgets('both sections on one page with counts', (tester) async {
    await _pumpTrash(tester);
    expect(find.text('System trash'), findsOneWidget);
    expect(find.text('Pending delete'), findsOneWidget);
    expect(find.textContaining('3 items'), findsOneWidget);
    expect(find.textContaining('1 item ·'), findsOneWidget);
    expect(find.text('a.pdf'), findsOneWidget);
  });

  testWidgets('select and restore: items come back and leave the page', (
    tester,
  ) async {
    final (app, files) = await _pumpTrash(tester);
    await tester.tap(find.text('a.pdf'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(find.text('1 item restored'), findsOneWidget);
    expect(find.text('a.pdf'), findsNothing);
    expect(files.trash, hasLength(3));
    expect(await files.stat('path:/s/Download/a.pdf'), isNotNull);
    expect(
      app.container.read(trashControllerProvider).value!.selecting,
      isFalse,
    );
  });

  testWidgets('declined restore dialog keeps items and selection', (
    tester,
  ) async {
    final (app, files) = await _pumpTrash(tester);
    files.declineDialogs = true;
    await tester.tap(find.text('a.pdf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('a.pdf'), findsOneWidget);
    expect(
      app.container.read(trashControllerProvider).value!.selectedIds,
      hasLength(1),
    );
  });

  testWidgets('delete forever asks first, then removes', (tester) async {
    final (_, files) = await _pumpTrash(tester);
    await tester.tap(find.text('a.pdf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete forever'));
    await tester.pumpAndSettle();
    expect(find.text('Delete 1 item forever?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete forever'));
    await tester.pumpAndSettle();
    expect(find.text('a.pdf'), findsNothing);
    expect(files.trash, hasLength(3));
  });

  testWidgets('restoring a file swiped in this session marks its undo row', (
    tester,
  ) async {
    final (app, files) = await _pumpTrash(tester);
    final session = await app.container
        .read(sessionRepositoryProvider)
        .getOrCreateActive();
    final undo = app.container.read(undoRepositoryProvider);
    await undo.prepare(session.id);
    final pdf = files.trash.values
        .singleWhere((t) => t.original.name == 'a.pdf')
        .original;
    undo.record(
      session.id,
      pdf,
      SwipeAction.trash,
      const TrashPreviousState(mode: 'trash'),
    );
    await app.container.read(dbWriteQueueProvider).flush();
    await undo.markCommitted(
      (await undo.top(session.id))!.id,
      const TrashPreviousState(mode: 'trash'),
    );

    await tester.tap(find.text('a.pdf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    final rows = await app.db.select(app.db.sessionActions).get();
    expect(rows.single.status, ActionStatus.undone);
    expect(pdf.kind, FileKind.document);
  });
}
