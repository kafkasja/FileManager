import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

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

/// 360×640 dp at text scale 1.3, app language [lang].
Future<TestApp> _pump(
  WidgetTester tester,
  String lang, {
  FakeFileSource? files,
}) async {
  tester.view
    ..physicalSize = const Size(1080, 1920)
    ..devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
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
      .write(AppSettings.localeTag, lang);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return app;
}

Finder _tab(IconData icon) => find.descendant(
  of: find.byType(NavigationBar),
  matching: find.byIcon(icon),
);

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(NavigationBar)));

/// TASK-L2: Dutch and Turkish (Dutch is usually the longest) fit on a small
/// phone with slightly larger text.
void main() {
  for (final lang in ['nl', 'tr']) {
    group(lang, () {
      testWidgets('the app switches language', (tester) async {
        await _pump(tester, lang);
        expect(_l10n(tester).localeName, lang);
        expect(find.text(_l10n(tester).tabTrash), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('swipe screen: no overflow', (tester) async {
        await _pump(tester, lang);
        expect(find.byType(SwipeCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Trash with a selection: no overflow', (tester) async {
        final files = _PendingTrashSource();
        await files.trashBatch([
          files.addFile('/s/Download/a_long_document_name_for_testing.pdf'),
          files.addFile('/s/DCIM/p0.jpg'),
        ]);
        await _pump(tester, lang, files: files);
        await tester.tap(_tab(Icons.delete_outline));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final pdf = find.text('a_long_document_name_for_testing.pdf');
        await tester.ensureVisible(pdf);
        await tester.pumpAndSettle();
        await tester.longPress(pdf);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('Settings: no overflow from top to bottom', (tester) async {
        await _pump(tester, lang);
        await tester.tap(_tab(Icons.settings_outlined));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final list = find.byType(Scrollable).first;
        final position = tester.state<ScrollableState>(list).position;
        for (var i = 0; i < 200; i++) {
          if (i > 0 && position.pixels >= position.maxScrollExtent) break;
          await tester.drag(list, const Offset(0, -300));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'after drag $i');
        }
      });

      testWidgets('Browse: no overflow', (tester) async {
        await _pump(tester, lang);
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
    });
  }
}
