import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/layout/text_scale.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

import '../core/files/fake_file_source.dart';
import '../helpers/pump_app.dart';

/// Trashed files land in the pending folder (listed by name).
class _PendingTrashSource extends FakeFileSource {
  @override
  Future<List<TrashedItem>> listTrashed() async => [
    for (final t in await super.listTrashed())
      TrashedItem(
        trashId: t.trashId,
        original: t.original,
        location: TrashLocation.pendingFolder,
        trashedAt: t.trashedAt,
        expiresAt: t.trashedAt.add(const Duration(days: 7)),
      ),
  ];
}

/// 360×640 dp, platform font 1.25 × Extra large = the 2.0 cap.
Future<TestApp> _pumpBig(
  WidgetTester tester, {
  FakeFileSource? files,
  AppTextSize size = AppTextSize.extraLarge,
}) async {
  tester.view
    ..physicalSize = const Size(1080, 1920)
    ..devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = 1.25;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final library = files ?? FakeFileSource();
  if (files == null) {
    for (var i = 0; i < 3; i++) {
      library.addFile(
        '/s/DCIM/a_rather_long_photo_file_name_$i.jpg',
        modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
      );
    }
  }
  final app = await pumpApp(tester, files: library);
  await app.container
      .read(settingsRepositoryProvider)
      .write(AppSettings.textSize, size);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return app;
}

Finder _tab(IconData icon) => find.descendant(
  of: find.byType(NavigationBar),
  matching: find.byIcon(icon),
);

double _bodyScale(WidgetTester tester) =>
    MediaQuery.textScalerOf(tester.element(find.byType(Scaffold).first))
        .scale(14);

void main() {
  testWidgets('the app applies the combined scale (capped at 2.0)', (
    tester,
  ) async {
    await _pumpBig(tester);
    expect(_bodyScale(tester), closeTo(28, 1e-9));
  });

  testWidgets('swipe screen: no overflow, the card keeps its height', (
    tester,
  ) async {
    final app = await _pumpBig(tester, size: AppTextSize.system);
    final normal = tester.getSize(find.byType(SwipeCard)).height;
    await app.container
        .read(settingsRepositoryProvider)
        .write(AppSettings.textSize, AppTextSize.extraLarge);
    await tester.pumpAndSettle();
    expect(_bodyScale(tester), closeTo(28, 1e-9));
    expect(tester.takeException(), isNull);
    expect(find.byType(SwipeCard), findsOneWidget);
    final card = tester.getSize(find.byType(SwipeCard)).height;
    // 360×640 with app bar + navigation bar: the default layout itself is
    // ~59% of the screen, so the check is on the body and against normal.
    final body =
        tester.getTopLeft(find.byType(NavigationBar)).dy -
        tester.getBottomLeft(find.byType(AppBar)).dy;
    expect(card / body, greaterThanOrEqualTo(0.6));
    expect(card / normal, greaterThanOrEqualTo(0.95));
  });

  testWidgets('swipe screen with P9 buttons + P4 bar: no overflow', (
    tester,
  ) async {
    final app = await _pumpBig(tester);
    final settings = app.container.read(settingsRepositoryProvider);
    await settings.write(AppSettings.swipeButtonsMode, true);
    await settings.write(AppSettings.actionBarEnabled, true);
    final deck = app.container.read(swipeDeckControllerProvider).value!;
    await app.container
        .read(sessionRepositoryProvider)
        .saveLayout(
          deck.session.id,
          SwipeLayout.basic.withActionBar(const [
            SwipeAction.keep,
            SwipeAction(SwipeActionType.favorite),
            SwipeAction(SwipeActionType.renameBatch),
          ]),
        );
    await app.container
        .read(swipeDeckControllerProvider.notifier)
        .reloadSession();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Favorite'), findsOneWidget);
  });

  testWidgets('Trash with a selection: no overflow', (tester) async {
    final files = _PendingTrashSource();
    await files.trashBatch([
      files.addFile('/s/Download/a_long_document_name_for_testing.pdf'),
      files.addFile('/s/DCIM/p0.jpg'),
    ]);
    await _pumpBig(tester, files: files);
    await tester.tap(_tab(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final pdf = find.text('a_long_document_name_for_testing.pdf');
    await tester.ensureVisible(pdf);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.longPress(pdf);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Delete forever'), findsOneWidget);
  });

  testWidgets('Settings: no overflow from top to bottom', (tester) async {
    await _pumpBig(tester);
    await tester.tap(_tab(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final list = find.byType(Scrollable).first;
    var sawTextSize = false;
    var sawVersion = false;
    final position = tester.state<ScrollableState>(list).position;
    for (var i = 0; i < 200; i++) {
      sawTextSize |= find.text('Text size').evaluate().isNotEmpty;
      sawVersion |= find.text('Version 0.1.0').evaluate().isNotEmpty;
      if (i > 0 && position.pixels >= position.maxScrollExtent) break;
      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'after drag $i');
    }
    expect(sawTextSize, isTrue);
    expect(sawVersion, isTrue);
  });

  testWidgets('Browse: no overflow', (tester) async {
    await _pumpBig(tester);
    await tester.tap(_tab(Icons.folder_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 10; i++) {
      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'after drag $i');
    }
  });

  testWidgets('text size picker: preview and setting follow the choice', (
    tester,
  ) async {
    final app = await _pumpBig(tester, size: AppTextSize.system);
    expect(_bodyScale(tester), closeTo(14 * 1.25, 1e-9));
    await tester.tap(_tab(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Large'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Large'));
    await tester.pumpAndSettle();
    await app.container.read(dbWriteQueueProvider).flush();
    await tester.pumpAndSettle();
    expect(
      await app.container
          .read(settingsRepositoryProvider)
          .read(AppSettings.textSize),
      AppTextSize.large,
    );
    final preview = tester.widget<Text>(
      find.byKey(const ValueKey('text-size-preview')),
    );
    expect(preview.textScaler!.scale(14), closeTo(14 * 1.25 * 1.3, 1e-9));
    expect(_bodyScale(tester), closeTo(14 * 1.25 * 1.3, 1e-9));
  });
}
