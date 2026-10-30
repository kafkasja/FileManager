import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/browse/ui/widgets/file_tile.dart';
import 'package:kfm/features/swipe/data/swipe_queue_repository.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

const _root = '/storage/emulated/0';

FakeFileSource _library() {
  final files = FakeFileSource();
  final t = DateTime.utc(2025);
  // (name, size, minutes after t): sizes and dates in different orders.
  for (final (name, size, minutes) in [
    ('b_mid.jpg', 50, 3),
    ('a_big.jpg', 900, 1),
    ('c_small.jpg', 5, 2),
  ]) {
    files.addFile(
      '$_root/DCIM/Camera/$name',
      bytes: List.filled(size, 1),
      modifiedAt: t.add(Duration(minutes: minutes)),
    );
  }
  files.addFile('$_root/DCIM/Other/z.jpg', modifiedAt: t);
  return files;
}

List<String> _gridNames(WidgetTester tester) => [
  for (final t in tester.widgetList<FileGridTile>(find.byType(FileGridTile)))
    t.file.name,
];

void main() {
  test('a corrupt stored sort field reads as date (newest first)', () {
    expect(
      AppSettings.browseSortField.decodeFromDb('"bogus"'),
      FileSortField.date,
    );
  });

  testWidgets('sheet: Size = largest first, Size again = smallest first; '
      'Name = A–Z; the label follows', (tester) async {
    await pumpApp(tester, files: _library());
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InkWell, 'Camera'));
    await tester.pumpAndSettle();
    expect(find.text('Newest first'), findsOneWidget);
    expect(_gridNames(tester), ['b_mid.jpg', 'c_small.jpg', 'a_big.jpg']);

    await tester.tap(find.byTooltip('Sort by').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Size'));
    await tester.pumpAndSettle();
    expect(_gridNames(tester), ['a_big.jpg', 'b_mid.jpg', 'c_small.jpg']);
    expect(find.text('Largest first'), findsWidgets);

    await tester.tap(find.text('Size'));
    await tester.pumpAndSettle();
    expect(_gridNames(tester), ['c_small.jpg', 'b_mid.jpg', 'a_big.jpg']);

    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    expect(_gridNames(tester), ['a_big.jpg', 'b_mid.jpg', 'c_small.jpg']);
    expect(find.text('A–Z'), findsWidgets);
  });

  testWidgets('changing the sort keeps the open folder', (tester) async {
    final app = await pumpApp(tester, files: _library());
    app.container.read(browseViewControllerProvider.notifier)
      ..setLayout(BrowseLayout.folders)
      ..openFolder('$_root/DCIM/Camera')
      ..setSort(const FileSort(FileSortField.size));
    final view = app.container.read(browseViewControllerProvider);
    expect(view.folder, '$_root/DCIM/Camera');
    expect(view.query.sort.field, FileSortField.size);
    // The swipe deck's order is its own.
    expect(swipeQuery.sort.field, FileSortField.date);
    await tester.pumpAndSettle();
  });

  test('the chosen sort survives a restart', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    ProviderContainer launch() {
      // Watched like the Browse screen does (unwatched providers pause).
      return ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      )..listen(browseViewControllerProvider, (_, _) {});
    }

    final first = launch();
    first
        .read(browseViewControllerProvider.notifier)
        .setSort(const FileSort(FileSortField.name, descending: false));
    await first.read(dbWriteQueueProvider).flush();
    first.dispose();

    final second = launch();
    addTearDown(second.dispose);
    // The stored sort arrives with the settings streams' first events.
    var sort = second.read(browseViewControllerProvider).sort;
    for (var i = 0; i < 100 && sort.field != FileSortField.name; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      sort = second.read(browseViewControllerProvider).sort;
    }
    expect(sort.field, FileSortField.name);
    expect(sort.descending, isFalse);
  });
}
