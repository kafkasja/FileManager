import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/features/browse/data/recent_searches.dart';
import 'package:kfm/features/browse/ui/browse_screen.dart';
import 'package:kfm/features/browse/ui/collection_screen.dart';
import 'package:kfm/features/browse/ui/text_viewer_screen.dart';
import 'package:kfm/features/browse/ui/widgets/file_tile.dart';
import 'package:kfm/features/browse/ui/widgets/sources_carousel.dart';
import 'package:kfm/features/swipe/ui/file_viewer.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/files/fake_open_with.dart';
import '../../core/platform/permissions/fake_permission_service.dart';
import '../../helpers/pump_app.dart';

const _root = '/storage/emulated/0';

FakeFileSource _library() {
  final files = FakeFileSource();
  final t = DateTime.utc(2025);
  var i = 0;
  void add(String path, {List<int>? bytes}) => files.addFile(
    '$_root/$path',
    modifiedAt: t.add(Duration(minutes: i++)),
    bytes: bytes ?? const [1, 2, 3],
  );
  add('DCIM/Camera/c1.jpg');
  add('DCIM/Camera/c2.jpg');
  add('DCIM/Tapo/t1.jpg');
  add('Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images/w1.jpg');
  add('Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents/w.pdf');
  add('Download/manual.pdf');
  add('Download/notes.txt', bytes: 'hello KFM'.codeUnits);
  add('Notes/.secret.txt');
  return files;
}

Future<void> _openBrowse(WidgetTester tester) async {
  await tester.tap(find.text('Browse'));
  await tester.pumpAndSettle();
}

Finder _tile(String name) => find.bySemanticsLabel(name);

void main() {
  testWidgets('All shows every visible file; type chips filter; hidden files '
      'stay out', (tester) async {
    await pumpApp(tester, files: _library());
    await _openBrowse(tester);
    expect(find.byType(BrowseScreen), findsOneWidget);
    for (final name in ['c1.jpg', 'c2.jpg', 't1.jpg', 'w1.jpg', 'w.pdf']) {
      expect(_tile(name), findsOneWidget, reason: name);
    }
    expect(_tile('.secret.txt'), findsNothing);

    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    expect(find.text('manual.pdf'), findsOneWidget);
    expect(_tile('c1.jpg'), findsNothing);

    await tester.tap(find.text('All').first);
    await tester.pumpAndSettle();
    expect(_tile('c1.jpg'), findsOneWidget);
  });

  Future<void> openCard(WidgetTester tester, String title) async {
    final card = find.widgetWithText(InkWell, title);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
  }

  testWidgets('source cards open their own page; WhatsApp + Documents; '
      'empty sources are hidden; no cards in folder mode', (tester) async {
    await pumpApp(tester, files: _library());
    await _openBrowse(tester);
    expect(find.text('Snapchat'), findsNothing);
    expect(find.text('WhatsApp'), findsOneWidget);
    await openCard(tester, 'WhatsApp');
    expect(find.byType(CollectionScreen), findsOneWidget);
    expect(_tile('w1.jpg'), findsOneWidget);
    expect(_tile('c1.jpg'), findsNothing);
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    expect(find.text('w.pdf'), findsOneWidget);
    expect(find.text('manual.pdf'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Folders'));
    await tester.pumpAndSettle();
    expect(find.byType(SourcesCarousel), findsNothing);
  });

  testWidgets('Other apps groups by folder; Hidden shows dot-files', (
    tester,
  ) async {
    await pumpApp(tester, files: _library());
    await _openBrowse(tester);
    await openCard(tester, 'Other apps');
    expect(find.text('Tapo'), findsOneWidget);
    await tester.tap(find.text('Tapo'));
    await tester.pumpAndSettle();
    expect(_tile('t1.jpg'), findsOneWidget);
    // Back leaves the group, then the page.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Tapo'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await openCard(tester, 'Hidden');
    expect(find.text('.secret.txt'), findsOneWidget);
  });

  testWidgets('recent searches come first; long-press removes one', (
    tester,
  ) async {
    final app = await pumpApp(tester, files: _library());
    await app.container
        .read(recentSearchesRepositoryProvider)
        .add('manual', const IndexQuery(nameContains: 'manual'));
    await _openBrowse(tester);
    expect(find.text('manual'), findsOneWidget);
    await openCard(tester, 'manual');
    expect(find.text('manual.pdf'), findsOneWidget);
    expect(_tile('c1.jpg'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.longPress(find.widgetWithText(InkWell, 'manual'));
    await tester.pumpAndSettle();
    expect(find.text('manual'), findsNothing);
  });

  testWidgets('file sizes: on by default, switchable; big files highlight', (
    tester,
  ) async {
    final files = _library()
      ..addFile('$_root/DCIM/Camera/huge.mp4', bytes: List.filled(10, 1));
    final app = await pumpApp(tester, files: files);
    await _openBrowse(tester);
    expect(find.text('3 B'), findsWidgets);

    final settings = app.container.read(settingsRepositoryProvider);
    await settings.write(AppSettings.browseShowSizes, false);
    await tester.pumpAndSettle();
    expect(find.text('3 B'), findsNothing);
  });

  testWidgets('a big file gets a highlighted size even with sizes off', (
    tester,
  ) async {
    // 100 MB is too big for a fake file: the tile on its own. A document
    // has no thumbnail, so no thumbnail cache is needed.
    final file = _library().files
        .firstWhere((f) => f.name == 'manual.pdf')
        .copyWith(sizeBytes: 200 * 1024 * 1024);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(extensions: const [AppTokens.light]),
          home: Scaffold(
            body: SizedBox.square(
              dimension: 128,
              child: FileGridTile(file: file, onTap: () {}, highlightBig: true),
            ),
          ),
        ),
      ),
    );
    expect(find.text('200 MB'), findsOneWidget);
  });

  testWidgets('folder mode: volumes, drill down, breadcrumb back up', (
    tester,
  ) async {
    await pumpApp(tester, files: _library());
    await _openBrowse(tester);
    await tester.tap(find.text('Folders'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Internal storage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DCIM'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Camera'));
    await tester.pumpAndSettle();
    expect(_tile('c1.jpg'), findsOneWidget);
    expect(_tile('t1.jpg'), findsNothing);

    // Breadcrumb: "DCIM" goes back up.
    await tester.tap(find.widgetWithText(TextButton, 'DCIM'));
    await tester.pumpAndSettle();
    expect(find.text('Tapo'), findsOneWidget);
  });

  testWidgets('tapping opens: photo → preview, txt → text page, pdf → Open '
      'with; no app → message', (tester) async {
    final openWith = FakeOpenWith();
    await pumpApp(tester, files: _library(), openWith: openWith);
    await _openBrowse(tester);

    await tester.tap(_tile('c1.jpg'));
    await tester.pumpAndSettle();
    expect(find.byType(PagedFileViewer), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('notes.txt'));
    await tester.pumpAndSettle();
    expect(find.byType(TextViewerBody), findsOneWidget);
    expect(find.text('hello KFM'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('manual.pdf'));
    await tester.pumpAndSettle();
    expect(openWith.opened.single.name, 'manual.pdf');

    openWith.noApp = true;
    await tester.tap(find.text('manual.pdf'));
    await tester.pumpAndSettle();
    expect(find.text('No app can open this file'), findsOneWidget);
  });

  testWidgets('without All files access: media only, Documents explains', (
    tester,
  ) async {
    final permissions = FakePermissionService(
      grantedAccess.copyWith(allFiles: AllFilesAccess.notGranted),
    );
    await pumpApp(tester, files: _library(), permissions: permissions);
    await _openBrowse(tester);
    expect(_tile('c1.jpg'), findsOneWidget);
    expect(_tile('w.pdf'), findsNothing);
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    expect(
      find.text('Grant access to see documents, downloads and hidden files'),
      findsOneWidget,
    );
    // Below the source cards: scroll down to the empty state.
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(find.text('No files here'), findsOneWidget);
  });
}
