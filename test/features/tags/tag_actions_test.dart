import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/features/browse/ui/collection_screen.dart';
import 'package:kfm/features/browse/ui/widgets/file_tile.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';
import 'package:kfm/features/swipe/ui/file_viewer.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/tags/domain/tag.dart';
import 'package:kfm/features/tags/ui/collections_screen.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

const _camera = '/storage/emulated/0/DCIM/Camera';

/// p00 … p{n-1}, one minute apart (newest first in Browse).
FakeFileSource _photos(int n) {
  final files = FakeFileSource();
  final t = DateTime.utc(2025);
  for (var i = 0; i < n; i++) {
    files.addFile(
      '$_camera/${_name(i)}',
      modifiedAt: t.add(Duration(minutes: i)),
    );
  }
  return files;
}

String _name(int i) => 'p${i.toString().padLeft(2, '0')}.jpg';
String _id(int i) => 'path:$_camera/${_name(i)}';

Finder _tile(String name) =>
    find.bySemanticsLabel(RegExp('^${RegExp.escape(name)}, '));

Finder _menuOf(String name) => find.descendant(
  of: find.byWidgetPredicate((w) => w is FileGridTile && w.file.name == name),
  matching: find.byTooltip('File actions'),
);

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) =>
    _tap(tester, find.text(text).last);

Future<void> _openBrowse(WidgetTester tester) async {
  await tester.tap(find.text('Browse'));
  await tester.pumpAndSettle();
}

void _hideSnackBars(WidgetTester tester) => tester
    .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
    .removeCurrentSnackBar();

/// Lets the undo snackbar time out.
Future<void> _finish(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpAndSettle();
}

Future<void> _selectionTags(WidgetTester tester, String choice) async {
  await _tap(tester, find.byTooltip('More'));
  await _tapText(tester, 'Tags & favorites…');
  await _tapText(tester, choice);
}

void main() {
  testWidgets('♡ in the preview → in Favorites; unfavorite there → gone at '
      'once', (tester) async {
    final app = await pumpApp(tester, files: _photos(3));
    Set<String> favorites() =>
        app.container.read(favoriteIdsProvider).value ?? const {};
    await _openBrowse(tester);

    await _tap(tester, _tile(_name(1)));
    expect(find.byType(PagedFileViewer), findsOneWidget);
    await _tap(tester, find.byTooltip('Add to favorites'));
    expect(favorites(), {_id(1)});
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    expect(find.text('Added 1 file to favorites'), findsWidgets);
    await _tap(tester, find.byTooltip('Close'));
    _hideSnackBars(tester);

    await _tap(tester, find.byTooltip('Tags & favorites'));
    expect(
      find.descendant(
        of: find.byType(CollectionsScreen),
        matching: find.text('1 file'),
      ),
      findsOneWidget,
    );
    await _tap(tester, find.text('Favorites'));
    expect(find.byType(CollectionScreen), findsOneWidget);
    expect(_tile(_name(1)), findsOneWidget);
    expect(_tile(_name(0)), findsNothing);

    await _tap(tester, _tile(_name(1)));
    await _tap(tester, find.byTooltip('Remove from favorites'));
    expect(favorites(), isEmpty);
    // Its only page left the view, so the preview may already be closed.
    if (find.byType(PagedFileViewer).evaluate().isNotEmpty) {
      await _tap(tester, find.byTooltip('Close'));
    }
    expect(_tile(_name(1)), findsNothing, reason: 'live, no restart');

    // Undo from the snackbar brings it back into the view.
    await _tap(tester, find.text('Undo').last);
    expect(favorites(), {_id(1)});
    await tester.pump(MediaIndexDao.changeDebounce);
    await tester.pumpAndSettle();
    expect(_tile(_name(1)), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('select 30 → Tags & favorites… → Add tag… → +30; Undo keeps '
      'the files that already had it', (tester) async {
    final app = await pumpApp(tester, files: _photos(30));
    final tags = app.container.read(tagRepositoryProvider);
    final holiday = await tags.create('Holiday', kTagColors[0]);
    final had = [_id(0), _id(1), _id(2)];
    await tags.addToFiles(holiday.id, had);
    final all = [for (var i = 0; i < 30; i++) _id(i)];
    Future<int> count() async =>
        (await tags.tagCountsAmong(all))[holiday.id] ?? 0;

    await _openBrowse(tester);
    app.container
        .read(selectionControllerProvider.notifier)
        .addAll(app.files.files);
    await tester.pumpAndSettle();

    await _selectionTags(tester, 'Add tag…');
    expect(find.text('Choose a tag'), findsOneWidget);
    await _tapText(tester, 'Holiday');
    expect(await count(), 30);
    expect(find.text('Tagged 27 files “Holiday”'), findsOneWidget);
    expect(
      app.container.read(selectionControllerProvider).value!.count,
      30,
      reason: 'the selection stays',
    );

    await _tap(tester, find.text('Undo'));
    expect(await count(), 3);
    expect((await tags.tagCountsAmong(had))[holiday.id], 3);

    // Again with everything tagged: nothing to undo.
    await tags.addToFiles(holiday.id, all);
    await _selectionTags(tester, 'Add tag…');
    await _tapText(tester, 'Holiday');
    expect(find.text('All files already had “Holiday”'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
    await _finish(tester);
  });

  testWidgets('selection: Add tag… → New tag… creates and tags; Remove tag… '
      'lists tags with counts; favorites add/remove', (tester) async {
    final app = await pumpApp(tester, files: _photos(4));
    final tags = app.container.read(tagRepositoryProvider);
    await _openBrowse(tester);
    final some = [app.files.files[0], app.files.files[1]];
    app.container.read(selectionControllerProvider.notifier).addAll(some);
    await tester.pumpAndSettle();

    await _selectionTags(tester, 'Add tag…');
    await _tapText(tester, 'New tag…');
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Trip',
    );
    await _tapText(tester, 'Create');
    final trip = app.container.read(tagsByIdProvider).value!.values.single;
    expect(trip.name, 'Trip');
    expect(find.text('Tagged 2 files “Trip”'), findsOneWidget);
    _hideSnackBars(tester);
    await tester.pumpAndSettle();

    await _selectionTags(tester, 'Remove tag…');
    expect(find.text('Remove a tag'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Trip'),
        matching: find.text('2 files'),
      ),
      findsOneWidget,
    );
    await _tapText(tester, 'Trip');
    expect(find.text('Removed “Trip” from 2 files'), findsOneWidget);
    expect(await tags.tagCountsAmong([_id(0), _id(1)]), isEmpty);
    await _tap(tester, find.text('Undo'));
    expect((await tags.tagCountsAmong([_id(0), _id(1)]))[trip.id], 2);

    await _selectionTags(tester, 'Add to favorites');
    expect(find.text('Added 2 files to favorites'), findsOneWidget);
    expect(app.container.read(favoriteIdsProvider).value, {_id(0), _id(1)});
    _hideSnackBars(tester);
    await tester.pumpAndSettle();
    await _selectionTags(tester, 'Remove from favorites');
    expect(find.text('Removed 2 files from favorites'), findsOneWidget);
    expect(app.container.read(favoriteIdsProvider).value, isEmpty);
    await _finish(tester);
  });

  testWidgets('file ⋮ menu: favorite toggle and the Tags sheet toggles', (
    tester,
  ) async {
    final app = await pumpApp(tester, files: _photos(2));
    final tags = app.container.read(tagRepositoryProvider);
    final holiday = await tags.create('Holiday', kTagColors[0]);
    final beach = await tags.create('Beach', kTagColors[1]);
    await _openBrowse(tester);
    final name = _name(0);

    await _tap(tester, _menuOf(name));
    await _tapText(tester, 'Add to favorites');
    expect(app.container.read(favoriteIdsProvider).value, {_id(0)});
    _hideSnackBars(tester);
    await _tap(tester, _menuOf(name));
    expect(find.text('Remove from favorites'), findsOneWidget);
    await _tapText(tester, 'Remove from favorites');
    expect(app.container.read(favoriteIdsProvider).value, isEmpty);
    _hideSnackBars(tester);

    await _tap(tester, _menuOf(name));
    await _tapText(tester, 'Tags…');
    Finder box(String tag) => find.widgetWithText(CheckboxListTile, tag);
    bool? checked(String tag) =>
        tester.widget<CheckboxListTile>(box(tag)).value;
    expect(checked('Holiday'), isFalse);
    expect(checked('Beach'), isFalse);

    await _tap(tester, box('Holiday'));
    expect(checked('Holiday'), isTrue);
    expect(await tags.tagIdsOf(_id(0)), {holiday.id});
    await _tap(tester, box('Beach'));
    expect(await tags.tagIdsOf(_id(0)), {holiday.id, beach.id});
    await _tap(tester, box('Holiday'));
    expect(checked('Holiday'), isFalse);
    expect(await tags.tagIdsOf(_id(0)), {beach.id});
    expect(await tags.tagIdsOf(_id(1)), isEmpty);

    // The checkbox is the undo: no snackbar covers the sheet.
    expect(find.byType(SnackBar), findsNothing);

    // New tag… creates it and checks it for this file.
    await _tapText(tester, 'New tag…');
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Trip',
    );
    await _tapText(tester, 'Create');
    final trip = app.container
        .read(tagsByIdProvider)
        .value!
        .values
        .singleWhere((t) => t.name == 'Trip');
    expect(checked('Trip'), isTrue);
    expect(await tags.tagIdsOf(_id(0)), {beach.id, trip.id});

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsNothing);
    await _finish(tester);
  });

  testWidgets('preview Tags button opens the same sheet', (tester) async {
    final app = await pumpApp(tester, files: _photos(1));
    final tags = app.container.read(tagRepositoryProvider);
    final holiday = await tags.create('Holiday', kTagColors[0]);
    await _openBrowse(tester);
    await _tap(tester, _tile(_name(0)));
    await _tap(tester, find.byTooltip('Tags'));
    await _tap(tester, find.widgetWithText(CheckboxListTile, 'Holiday'));
    expect(await tags.tagIdsOf(_id(0)), {holiday.id});
    await _finish(tester);
  });
}
