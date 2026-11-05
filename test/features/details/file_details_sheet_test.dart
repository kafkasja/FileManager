import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/details/data/file_details_repository.dart';
import 'package:kfm/features/details/domain/known_files.dart';
import 'package:kfm/features/details/domain/path_app.dart';
import 'package:kfm/features/details/ui/file_details_sheet.dart';
import 'package:kfm/features/details/ui/selection_summary_sheet.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';
import 'file_details_repository_test.dart' show FakeDetailsPlatform, fileAt;

const _root = '/storage/emulated/0';
const _stickers =
    '$_root/Android/media/com.whatsapp/WhatsApp/Backups/Stickers/x';
const _sticker = '$_stickers/tHXZq4Vwsz+idGdjU4klUwvh.crypt14';

Future<TestApp> _pump(
  WidgetTester tester,
  FakeDetailsPlatform platform, {
  FakeFileSource? files,
}) {
  // Tall enough that the whole sheet is built (ListView is lazy).
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return pumpApp(
    tester,
    files: files,
    overrides: [
      detailsPlatformProvider.overrideWithValue(platform),
      // Read synchronously: rootBundle I/O can race the fake clock (the 5 s
      // details timeout) while the spinner keeps frames coming.
      knownFilesProvider.overrideWith(
        (ref) async => KnownFiles.parse(
          File('assets/details/known_files_en.json').readAsStringSync(),
        ),
      ),
      knownAppsProvider.overrideWith(
        (ref) async => KnownApps.parse(
          File('assets/details/known_apps.json').readAsStringSync(),
        ),
      ),
    ],
  );
}

Future<void> _open(WidgetTester tester, FileRef file) async {
  final context = tester.element(find.byType(Scaffold).first);
  // Completes when the sheet closes.
  unawaited(showFileDetails(context, file));
  await tester.pumpAndSettle();
}

/// No row may show "null", an empty value or an epoch-0 date.
void _expectNoJunk(WidgetTester tester) {
  final texts = [
    for (final w in tester.widgetList<Text>(find.byType(Text))) w.data ?? '',
    for (final w in tester.widgetList<SelectableText>(
      find.byType(SelectableText),
    ))
      w.data ?? '',
  ];
  for (final t in texts) {
    expect(t, isNot(contains('null')));
    expect(t, isNot(contains('1970')));
  }
}

void main() {
  testWidgets('crypt14: WhatsApp explanation, "Saved by WhatsApp" from the '
      'path, full path; empty rows hidden', (tester) async {
    await _pump(tester, FakeDetailsPlatform());
    await _open(tester, fileAt(_sticker));

    expect(find.text('tHXZq4Vwsz+idGdjU4klUwvh.crypt14'), findsOneWidget);
    expect(find.text('What is this?'), findsOneWidget);
    expect(find.text('WhatsApp sticker backup (encrypted)'), findsOneWidget);
    expect(find.text('Careful: deleting it can lose data'), findsOneWidget);
    expect(find.text('Saved by WhatsApp'), findsOneWidget);
    expect(find.text('com.whatsapp (not installed)'), findsOneWidget);
    expect(find.text(_sticker), findsOneWidget);
    expect(find.text('Internal storage'), findsOneWidget);
    expect(find.text('Modified'), findsOneWidget);
    // No data → no row.
    expect(find.text('Added to phone'), findsNothing);
    expect(find.text('Taken'), findsNothing);
    expect(find.textContaining('Downloaded from'), findsNothing);
    expect(find.textContaining('Taken with'), findsNothing);
    expect(find.text('App info'), findsNothing);
    expect(find.text("Couldn't read some details"), findsNothing);
    _expectNoJunk(tester);
  });

  testWidgets('download: host only, the full address on tap; app info for a '
      'visible owner; camera row', (tester) async {
    final platform = FakeDetailsPlatform()
      ..row = {
        'exists': true,
        'dateAdded': 1761998400,
        'mime': 'image/jpeg',
        'owner': 'com.android.chrome',
        'downloadUri': 'https://files.example.com/a.jpg?token=secret',
      }
      ..apps = {
        'com.android.chrome': {'label': 'Chrome'},
      }
      ..exifRow = {'id': 1, 'make': 'Google', 'model': 'Pixel 8', 'iso': 100};
    await _pump(tester, platform);
    await _open(
      tester,
      fileAt('$_root/Download/a.jpg', id: 'ms:1', kind: FileKind.image),
    );

    expect(find.text('Saved by Chrome'), findsOneWidget);
    expect(find.text('Downloaded from files.example.com'), findsOneWidget);
    expect(find.textContaining('token=secret'), findsNothing);
    expect(find.text('Taken with Google Pixel 8'), findsOneWidget);
    expect(find.text('ISO 100'), findsOneWidget);
    expect(find.text('Added to phone'), findsOneWidget);
    expect(find.text('image/jpeg (.jpg)'), findsOneWidget);

    await tester.tap(find.text('Downloaded from files.example.com'));
    await tester.pumpAndSettle();
    expect(
      find.text('https://files.example.com/a.jpg?token=secret'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('App info'));
    await tester.tap(find.text('App info'));
    await tester.pumpAndSettle();
    expect(platform.openedAppInfo, ['com.android.chrome']);
    _expectNoJunk(tester);
  });

  testWidgets('copy path puts the path on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester, FakeDetailsPlatform());
    await _open(tester, fileAt(_sticker));
    await tester.tap(find.byTooltip('Copy path'));
    await tester.pumpAndSettle();
    expect(copied, _sticker);
    expect(find.text('Path copied'), findsOneWidget);
  });

  testWidgets('open folder: closes the sheet, Browse in folder mode there', (
    tester,
  ) async {
    final app = await _pump(tester, FakeDetailsPlatform());
    await _open(tester, fileAt(_sticker));
    await tester.ensureVisible(find.text('Open folder'));
    await tester.tap(find.text('Open folder'));
    await tester.pumpAndSettle();
    expect(find.byType(FileDetailsView), findsNothing);
    final view = app.container.read(browseViewControllerProvider);
    expect(view.layout, BrowseLayout.folders);
    expect(view.folder, _stickers);
  });

  testWidgets('a gone file says so and disables Open folder', (tester) async {
    await _pump(tester, FakeDetailsPlatform()..row = {'exists': false});
    await _open(tester, fileAt(_sticker));
    expect(find.text('This file no longer exists'), findsOneWidget);
    final button = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Open folder'),
        matching: find.byWidgetPredicate((w) => w is TextButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('a failing native call shows a partial result inline', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeDetailsPlatform()..detailsError = Exception('channel down'),
    );
    await _open(tester, fileAt(_sticker));
    expect(find.text("Couldn't read some details"), findsOneWidget);
    expect(find.text('WhatsApp sticker backup (encrypted)'), findsOneWidget);
  });

  testWidgets('⋮ menu ends with Details; selection Details: one → sheet, '
      'three → summary', (tester) async {
    final files = FakeFileSource();
    final t = DateTime.utc(2025);
    var i = 0;
    for (final name in ['c1.jpg', 'c2.jpg', 'c3.jpg']) {
      files.addFile(
        '$_root/DCIM/Camera/$name',
        modifiedAt: t.add(Duration(days: i++)),
        bytes: List.filled(1000, 1),
      );
    }
    await _pump(tester, FakeDetailsPlatform(), files: files);
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('File actions').first);
    await tester.pumpAndSettle();
    final menuTexts = [
      for (final w in tester.widgetList<ListTile>(find.byType(ListTile)))
        if (w.title case final Text t) t.data,
    ];
    expect(menuTexts.last, 'Details');
    await tester.tap(find.text('Details').last);
    await tester.pumpAndSettle();
    expect(find.byType(FileDetailsView), findsOneWidget);
    Navigator.of(tester.element(find.byType(FileDetailsView))).pop();
    await tester.pumpAndSettle();

    await tester.longPress(find.bySemanticsLabel(RegExp(r'^c1\.jpg, ')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp(r'^c2\.jpg, ')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp(r'^c3\.jpg, ')));
    await tester.pumpAndSettle();
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Details').last);
    await tester.pumpAndSettle();
    expect(find.byType(SelectionSummaryView), findsOneWidget);
    Finder inSummary(String text) => find.descendant(
      of: find.byType(SelectionSummaryView),
      matching: find.text(text),
    );
    expect(inSummary('3 files'), findsOneWidget);
    expect(inSummary('In 1 folder'), findsOneWidget);
    expect(inSummary('Images: 3'), findsOneWidget);
    expect(inSummary('Oldest'), findsOneWidget);
    expect(inSummary('Newest'), findsOneWidget);
  });

  test('selection summary totals', () {
    final a = fileAt('$_root/A/a.jpg', kind: FileKind.image);
    final b = fileAt(
      '$_root/B/b.mp4',
      kind: FileKind.video,
    ).copyWith(modifiedAt: DateTime.utc(2020));
    final s = SelectionSummary.of([a, b]);
    expect(s.count, 2);
    expect(s.totalBytes, 2468);
    expect(s.kinds, {FileKind.image: 1, FileKind.video: 1});
    expect(s.folderCount, 2);
    expect(s.oldest, DateTime.utc(2020));
    expect(s.newest, a.modifiedAt);
  });
}
