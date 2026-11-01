import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/browse/ui/browse_screen.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/tags/domain/tag.dart';
import 'package:kfm/features/tags/ui/collections_screen.dart';
import 'package:kfm/features/tags/ui/tag_files_screen.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

const _camera = '/storage/emulated/0/DCIM/Camera';

/// p0 … p{n-1}, one minute apart.
FakeFileSource _photos(int n) {
  final files = FakeFileSource();
  final t = DateTime.utc(2025);
  for (var i = 0; i < n; i++) {
    files.addFile('$_camera/p$i.jpg', modifiedAt: t.add(Duration(minutes: i)));
  }
  return files;
}

String _id(int i) => 'path:$_camera/p$i.jpg';

Finder _tile(String name) => find.bySemanticsLabel(name);

Finder _tagRow(String name) => find.descendant(
  of: find.byType(CollectionsScreen),
  matching: find.widgetWithText(ListTile, name),
);

Finder _inDialog(Finder f) =>
    find.descendant(of: find.byType(AlertDialog), matching: f);

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _openCollections(WidgetTester tester) async {
  await tester.tap(find.text('Browse'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Tags & favorites'));
  await tester.pumpAndSettle();
  expect(find.byType(CollectionsScreen), findsOneWidget);
}

Future<void> _tagMenu(WidgetTester tester, String tag, String item) async {
  await _tap(
    tester,
    find.descendant(of: _tagRow(tag), matching: find.byTooltip('Tag options')),
  );
  await _tap(tester, find.text(item).last);
}

/// Lets the undo snackbar time out.
Future<void> _finish(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Browse toolbar → Collections: Favorites and tag counts; a tag '
      'shows only its files; back returns to Browse', (tester) async {
    final app = await pumpApp(tester, files: _photos(6));
    final tags = app.container.read(tagRepositoryProvider);
    final holiday = await tags.create('Holiday', kTagColors[0]);
    final beach = await tags.create('Beach', kTagColors[1]);
    await tags.addToFiles(holiday.id, [_id(0), _id(1), _id(2)]);
    await tags.addToFiles(beach.id, [_id(3)]);
    await app.container.read(favoritesRepositoryProvider).addFiles([
      _id(4),
      _id(5),
    ]);
    await tester.pumpAndSettle();

    await _openCollections(tester);
    final favorites = find.ancestor(
      of: find.text('Favorites'),
      matching: find.byType(InkWell),
    );
    expect(
      find.descendant(of: favorites.first, matching: find.text('2 files')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _tagRow('Holiday'), matching: find.text('3 files')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _tagRow('Beach'), matching: find.text('1 file')),
      findsOneWidget,
    );
    // Sorted by name.
    expect(
      tester.getTopLeft(_tagRow('Beach')).dy,
      lessThan(tester.getTopLeft(_tagRow('Holiday')).dy),
    );

    await _tap(tester, _tagRow('Holiday'));
    expect(find.byType(TagFilesScreen), findsOneWidget);
    for (final i in [0, 1, 2]) {
      expect(_tile('p$i.jpg'), findsOneWidget, reason: 'p$i');
    }
    for (final i in [3, 4, 5]) {
      expect(_tile('p$i.jpg'), findsNothing, reason: 'p$i');
    }

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(CollectionsScreen), findsOneWidget);
    await _tap(tester, find.text('Favorites'));
    expect(_tile('p4.jpg'), findsOneWidget);
    expect(_tile('p5.jpg'), findsOneWidget);
    expect(_tile('p0.jpg'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(CollectionsScreen), findsNothing);
    expect(find.byType(BrowseScreen), findsOneWidget);
    expect(_tile('p0.jpg'), findsOneWidget);
  });

  testWidgets('no tags: empty message', (tester) async {
    await pumpApp(tester, files: _photos(1));
    await _openCollections(tester);
    expect(find.textContaining('No tags yet.'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CollectionsScreen),
        matching: find.text('No files'),
      ),
      findsOneWidget,
      reason: 'Favorites card',
    );
  });

  testWidgets('rename: clash in any case rejected, case-only change and '
      'recolor saved', (tester) async {
    final app = await pumpApp(tester, files: _photos(1));
    final tags = app.container.read(tagRepositoryProvider);
    final holiday = await tags.create('holiday', kTagColors[0]);
    await tags.create('Beach', kTagColors[1]);
    await _openCollections(tester);

    await _tagMenu(tester, 'holiday', 'Rename or change color');
    expect(find.text('Edit tag'), findsOneWidget);
    final field = _inDialog(find.byType(TextField));

    await tester.enterText(field, '   ');
    await _tap(tester, _inDialog(find.text('Save')));
    expect(find.text('Use 1 to 40 characters'), findsOneWidget);

    await tester.enterText(field, 'BEACH');
    await _tap(tester, _inDialog(find.text('Save')));
    expect(find.text('A tag with this name already exists'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.enterText(field, 'Holiday');
    await _tap(
      tester,
      _inDialog(
        find.byWidgetPredicate(
          (w) => w is CircleAvatar && w.backgroundColor == Color(kTagColors[2]),
        ),
      ),
    );
    await _tap(tester, _inDialog(find.text('Save')));
    expect(find.byType(AlertDialog), findsNothing);

    final saved = app.container.read(tagsByIdProvider).value![holiday.id]!;
    expect(saved.name, 'Holiday');
    expect(saved.color, kTagColors[2]);
    expect(_tagRow('Holiday'), findsOneWidget);
    expect(_tagRow('holiday'), findsNothing);
    final icon = tester.widget<Icon>(
      find.descendant(
        of: _tagRow('Holiday'),
        matching: find.byIcon(Icons.label),
      ),
    );
    expect(icon.color, Color(kTagColors[2]));

    // Long-press opens the same dialog; Cancel changes nothing.
    await tester.longPress(_tagRow('Beach'));
    await tester.pumpAndSettle();
    await tester.enterText(_inDialog(find.byType(TextField)), 'Sea');
    await _tap(tester, _inDialog(find.text('Cancel')));
    expect(_tagRow('Beach'), findsOneWidget);
  });

  testWidgets('delete → gone, files untouched; Undo restores the same id and '
      'its files', (tester) async {
    final app = await pumpApp(tester, files: _photos(3));
    final tags = app.container.read(tagRepositoryProvider);
    final holiday = await tags.create('Holiday', kTagColors[0]);
    await tags.addToFiles(holiday.id, [_id(0), _id(1), _id(2)]);
    await _openCollections(tester);

    await _tagMenu(tester, 'Holiday', 'Delete tag');
    expect(find.text('Delete tag “Holiday”?'), findsOneWidget);
    expect(
      find.text('The 3 files stay; only the tag is removed.'),
      findsOneWidget,
    );
    expect(find.textContaining('Used in'), findsNothing);
    await _tap(tester, _inDialog(find.text('Delete')));

    expect(_tagRow('Holiday'), findsNothing);
    expect(app.container.read(tagsByIdProvider).value, isEmpty);
    expect(app.files.files, hasLength(3));
    expect(find.text('Tag “Holiday” deleted'), findsOneWidget);

    await _tap(tester, find.text('Undo'));
    final back = app.container.read(tagsByIdProvider).value!;
    expect(back.keys, [holiday.id]);
    expect(back[holiday.id]!.name, 'Holiday');
    expect(await tags.tagCountsAmong([for (var i = 0; i < 3; i++) _id(i)]), {
      holiday.id: 3,
    });
    expect(
      find.descendant(of: _tagRow('Holiday'), matching: find.text('3 files')),
      findsOneWidget,
    );

    // Cancel keeps it.
    await _tagMenu(tester, 'Holiday', 'Delete tag');
    await _tap(tester, _inDialog(find.text('Cancel')));
    expect(_tagRow('Holiday'), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('delete of a tag used by a preset and the current swipe setup '
      'warns where it is used', (tester) async {
    final app = await pumpApp(tester, files: _photos(1));
    final tags = app.container.read(tagRepositoryProvider);
    final holiday = await tags.create('Holiday', kTagColors[0]);
    final other = await tags.create('Other', kTagColors[1]);
    final usesHoliday = SwipeLayout.basic.withDirection(
      SwipeDirection.up,
      SwipeAction(SwipeActionType.addTag, tagId: holiday.id),
    );
    await app.container
        .read(presetRepositoryProvider)
        .create(name: 'Trip', layout: usesHoliday);
    await app.container
        .read(presetRepositoryProvider)
        .create(name: 'Plain', layout: SwipeLayout.basic);
    // The current setup uses it in the action bar.
    await app.container
        .read(settingsRepositoryProvider)
        .write(
          AppSettings.swipeLayoutCurrent,
          jsonEncode(
            SwipeLayout.basic.withActionBar([
              SwipeAction(SwipeActionType.addTag, tagId: holiday.id),
            ]).toJson(),
          ),
        );
    await _openCollections(tester);

    await _tagMenu(tester, 'Holiday', 'Delete tag');
    expect(find.text('No files have this tag.'), findsOneWidget);
    expect(
      find.textContaining('Used in: Trip, current swipe setup.'),
      findsOneWidget,
    );
    await _tap(tester, _inDialog(find.text('Cancel')));

    await _tagMenu(tester, 'Other', 'Delete tag');
    expect(find.textContaining('Used in'), findsNothing);
    await _tap(tester, _inDialog(find.text('Delete')));
    expect(app.container.read(tagsByIdProvider).value!.keys, [holiday.id]);
    expect(other.id, isNot(holiday.id));
    await _finish(tester);
  });

  testWidgets('tag deleted while its files view is open → pops with '
      '"This tag was deleted"', (tester) async {
    final app = await pumpApp(tester, files: _photos(2));
    final tags = app.container.read(tagRepositoryProvider);
    final holiday = await tags.create('Holiday', kTagColors[0]);
    await tags.addToFiles(holiday.id, [_id(0)]);
    await _openCollections(tester);
    await _tap(tester, _tagRow('Holiday'));
    expect(find.byType(TagFilesScreen), findsOneWidget);
    expect(_tile('p0.jpg'), findsOneWidget);

    // A rename elsewhere keeps the view and updates its title.
    await tags.rename(holiday.id, 'Trip');
    await tester.pumpAndSettle();
    expect(find.byType(TagFilesScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Trip'), findsOneWidget);

    await tags.deleteWithSnapshot(holiday.id);
    await tester.pumpAndSettle();
    expect(find.byType(TagFilesScreen), findsNothing);
    expect(find.byType(CollectionsScreen), findsOneWidget);
    expect(find.text('This tag was deleted'), findsOneWidget);
    await _finish(tester);
  });
}
