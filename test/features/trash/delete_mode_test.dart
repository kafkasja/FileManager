import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

void main() {
  test('DeleteMode.parse falls back to trash', () {
    expect(DeleteMode.parse(null), DeleteMode.trash);
    expect(DeleteMode.parse('xyz'), DeleteMode.trash);
    expect(DeleteMode.parse('trash'), DeleteMode.trash);
    expect(DeleteMode.parse('permanent'), DeleteMode.permanent);
  });

  Future<TestApp> pumpWithPermanentSetting(
    WidgetTester tester, {
    FakeFileSource? files,
  }) async {
    final app = await pumpApp(tester, files: files);
    await app.container
        .read(settingsRepositoryProvider)
        .write(AppSettings.deleteMode, 'permanent');
    // The default trash session started on first launch: end it so the next
    // session is a new one.
    await app.container.read(sessionRepositoryProvider).endActive();
    app.container.invalidate(needsDeleteModeChoiceProvider);
    await tester.pumpAndSettle();
    return app;
  }

  testWidgets(
    'permanent mode asks once; "Use trash instead" keeps the setting',
    (tester) async {
      final app = await pumpWithPermanentSetting(tester);
      expect(find.text('Delete permanently this session?'), findsOneWidget);

      await tester.tap(find.text('Use trash instead'));
      await tester.pumpAndSettle();
      expect(find.text('Delete permanently this session?'), findsNothing);
      final session = await app.container
          .read(sessionRepositoryProvider)
          .active();
      expect(session!.deleteMode, DeleteMode.trash);
      expect(
        await app.container
            .read(settingsRepositoryProvider)
            .read(AppSettings.deleteMode),
        'permanent',
      );

      // A resumed session never asks again.
      app.container.invalidate(needsDeleteModeChoiceProvider);
      await tester.pumpAndSettle();
      expect(find.text('Delete permanently this session?'), findsNothing);
    },
  );

  testWidgets('"Delete permanently" starts a permanent session', (
    tester,
  ) async {
    final app = await pumpWithPermanentSetting(tester);
    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();
    final session = await app.container
        .read(sessionRepositoryProvider)
        .active();
    expect(session!.deleteMode, DeleteMode.permanent);
  });

  testWidgets('trash mode starts without asking', (tester) async {
    await pumpApp(tester);
    expect(find.text('Delete permanently this session?'), findsNothing);
  });

  testWidgets('V1 bug 6: after Done the next permanent session asks again', (
    tester,
  ) async {
    final files = FakeFileSource();
    for (var i = 0; i < 3; i++) {
      files.addFile(
        '/s/DCIM/p$i.jpg',
        modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
      );
    }
    final app = await pumpWithPermanentSetting(tester, files: files);
    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(SwipeCard), const Offset(500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Finish'));
    await tester.pumpAndSettle();
    if (find.widgetWithText(FilledButton, 'OK').evaluate().isNotEmpty) {
      await tester.tap(find.widgetWithText(FilledButton, 'OK'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Delete permanently this session?'), findsOneWidget);
    expect(
      await app.container.read(sessionRepositoryProvider).active(),
      isNull,
    );
    await tester.pump(const Duration(seconds: 1));
  });
}
