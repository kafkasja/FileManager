import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/features/browse/data/recent_searches.dart';
import 'package:kfm/features/search/data/builtin_keywords.dart';
import 'package:kfm/features/search/data/search_keywords.dart';
import 'package:kfm/features/search/data/search_vocabulary.dart';
import 'package:kfm/features/search/domain/search_keyword.dart';
import 'package:kfm/features/search/ui/search_screen.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../../../core/files/fake_file_source.dart';
import '../../../core/platform/permissions/fake_permission_service.dart';
import '../../../helpers/pump_app.dart';

const _root = '/storage/emulated/0';
final AppLocalizations _l10n = lookupAppLocalizations(const Locale('en'));

SearchVocabulary _vocab() {
  const families = [typeKeywords, sourceKeywords, attributeKeywords];
  SearchKeyword kw(String id) => resolveKeywordId(id, families)!;
  return SearchVocabulary(
    phrases: {
      'whatsapp': kw('source:whatsapp'),
      'video': kw('type:video'),
      'videos': kw('type:video'),
    },
  );
}

FakeFileSource _library({DateTime? now}) {
  final files = FakeFileSource();
  final t = DateTime.utc(2025);
  var i = 0;
  void add(String path, {List<int>? bytes, DateTime? at}) => files.addFile(
    '$_root/$path',
    modifiedAt: at ?? t.add(Duration(minutes: i++)),
    bytes: bytes ?? const [1, 2, 3],
  );
  add('DCIM/Camera/c1.jpg');
  add('DCIM/Camera/clip.mp4', bytes: List.filled(2 * 1024 * 1024, 1));
  add('DCIM/Camera/tiny.mp4');
  add('Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images/w1.jpg');
  add('Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents/w.pdf');
  add('Download/manual.pdf');
  add('Download/pdf-guide.txt');
  if (now != null) add('DCIM/Camera/recent.jpg', at: now);
  return files;
}

Future<TestApp> _open(
  WidgetTester tester, {
  FakeFileSource? files,
  FakePermissionService? permissions,
}) async {
  final app = await pumpApp(
    tester,
    files: files ?? _library(),
    permissions: permissions,
    overrides: [searchVocabularyProvider.overrideWith((ref) async => _vocab())],
  );
  await tester.tap(find.text('Browse'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip(_l10n.searchOpen));
  await tester.pumpAndSettle();
  expect(find.byType(SearchScreen), findsOneWidget);
  return app;
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

/// A file shown as a list row (maybe highlighted) or a grid tile.
Finder _file(String name) => find.byWidgetPredicate(
  (w) =>
      (w is Text && (w.data == name || w.textSpan?.toPlainText() == name)) ||
      (w is Semantics && w.properties.label == name),
);

/// Lets the "record this search" timer run out.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

Finder _chip(String label) => find.widgetWithText(InputChip, label);

Future<void> _deleteChip(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: _chip(label), matching: find.byType(Icon)).last,
  );
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('"whatsapp pdf" makes two chips and shows WhatsApp PDFs', (
    tester,
  ) async {
    await _open(tester);
    await _type(tester, 'whatsapp pdf');
    expect(_chip(_l10n.searchTokenExtension('pdf')), findsOneWidget);
    final whatsapp = _vocab().phrases['whatsapp']!.chipLabel(_l10n);
    expect(_chip(whatsapp), findsOneWidget);
    expect(_file('w.pdf'), findsOneWidget);
    expect(_file('manual.pdf'), findsNothing);
    expect(_file('w1.jpg'), findsNothing);
    await _settle(tester);
  });

  testWidgets('a chip ✕ turns its word into a name search', (tester) async {
    await _open(tester);
    await _type(tester, 'pdf');
    expect(_file('manual.pdf'), findsOneWidget);
    expect(_file('pdf-guide.txt'), findsNothing);

    await _deleteChip(tester, _l10n.searchTokenExtension('pdf'));
    expect(_chip(_l10n.searchTokenExtension('pdf')), findsNothing);
    expect(_file('manual.pdf'), findsOneWidget);
    expect(_file('pdf-guide.txt'), findsOneWidget);
    // Still the same text in the field.
    expect(find.widgetWithText(TextField, 'pdf'), findsOneWidget);
    await _settle(tester);
  });

  testWidgets('a keyword chip ✕ stays a name search (no re-parse back)', (
    tester,
  ) async {
    await _open(tester);
    final video = _vocab().phrases['video']!.chipLabel(_l10n);
    await _type(tester, 'video');
    expect(_chip(video), findsOneWidget);
    expect(_file('clip.mp4'), findsOneWidget);
    await _deleteChip(tester, video);
    expect(_chip(video), findsNothing);
    expect(find.text(_l10n.searchNoMatch), findsOneWidget);
    // Typing more keeps "video" a name word.
    await _type(tester, 'video clip');
    expect(_chip(video), findsNothing);
    await _settle(tester);
  });

  testWidgets('size chip + type chip: only small videos; min > max is '
      'rejected', (tester) async {
    await _open(tester);
    await tester.tap(_chip(_l10n.searchChipType));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.browseKindVideos));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.searchDone));
    await tester.pumpAndSettle();
    expect(_file('clip.mp4'), findsOneWidget);
    expect(_file('tiny.mp4'), findsOneWidget);
    expect(_file('c1.jpg'), findsNothing);

    await tester.tap(_chip(_l10n.searchChipSize));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.searchSizeUnder('1 MB')));
    await tester.pumpAndSettle();
    expect(_file('tiny.mp4'), findsOneWidget);
    expect(_file('clip.mp4'), findsNothing);

    // Custom: 5 MB … 1 MB is refused.
    await tester.tap(_chip(_l10n.searchSizeUnder('1 MB')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.searchSizeCustom));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('search-size-min')), '5');
    await tester.enterText(find.byKey(const ValueKey('search-size-max')), '1');
    await tester.tap(find.text(_l10n.ok));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.searchSizeInvalid), findsOneWidget);
    await tester.tap(find.text(_l10n.cancel));
    await tester.pumpAndSettle();
    expect(_file('tiny.mp4'), findsOneWidget);

    // ✕ on the size chip removes the condition.
    await _deleteChip(tester, _l10n.searchSizeUnder('1 MB'));
    expect(_file('clip.mp4'), findsOneWidget);
    await _settle(tester);
  });

  testWidgets('typed "video" + Type chip: the chip narrows; nothing in '
      'common = "No files match"', (tester) async {
    await _open(tester);
    await _type(tester, 'video');
    expect(_file('clip.mp4'), findsOneWidget);
    await tester.tap(_chip(_l10n.searchChipType));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.browseKindImages));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.searchDone));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.searchNoMatch), findsOneWidget);
    expect(find.text(_l10n.browseFileCount(0)), findsOneWidget);
    expect(_file('clip.mp4'), findsNothing);
    expect(_file('c1.jpg'), findsNothing);
    await _settle(tester);
  });

  testWidgets('date chip: Last 7 days', (tester) async {
    await _open(tester, files: _library(now: DateTime.now()));
    await tester.tap(_chip(_l10n.searchChipDate));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.searchDateWeek));
    await tester.pumpAndSettle();
    expect(_chip(_l10n.searchDateWeek), findsOneWidget);
    expect(_file('recent.jpg'), findsOneWidget);
    expect(_file('c1.jpg'), findsNothing);
    await _settle(tester);
  });

  testWidgets('recent searches show when empty and re-apply on tap', (
    tester,
  ) async {
    final app = await pumpApp(
      tester,
      files: _library(),
      overrides: [
        searchVocabularyProvider.overrideWith((ref) async => _vocab()),
      ],
    );
    await app.container
        .read(recentSearchesRepositoryProvider)
        .add('manual', const IndexQuery(nameContains: 'manual'));
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(_l10n.searchOpen));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.searchRecent), findsOneWidget);
    expect(find.text(_l10n.searchSuggestLarge), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'manual'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'manual'), findsOneWidget);
    expect(_file('manual.pdf'), findsOneWidget);
    expect(_file('w.pdf'), findsNothing);
    await _settle(tester);
  });

  testWidgets('a submitted search becomes a Browse recent card', (
    tester,
  ) async {
    await _open(tester);
    await _type(tester, 'guide');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(_file('pdf-guide.txt'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InkWell, 'guide'), findsOneWidget);
    await _settle(tester);
  });

  testWidgets('no results: "No files match" + Clear filters', (tester) async {
    await _open(tester);
    await _type(tester, 'zzzz');
    expect(find.text(_l10n.searchNoMatch), findsOneWidget);
    await tester.tap(find.text(_l10n.searchClearFilters));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.searchNoMatch), findsNothing);
    expect(find.text(_l10n.searchSuggestions), findsOneWidget);
    expect(find.widgetWithText(TextField, 'zzzz'), findsNothing);
    await _settle(tester);
  });

  testWidgets('without All files access a PDF search shows the banner', (
    tester,
  ) async {
    final permissions = FakePermissionService(
      grantedAccess.copyWith(allFiles: AllFilesAccess.notGranted),
    );
    await _open(tester, permissions: permissions);
    // No Hidden chip without access.
    expect(_chip(_l10n.searchChipHidden), findsNothing);
    await _type(tester, 'pdf');
    expect(find.text(_l10n.browseNeedsAllFiles), findsOneWidget);
    expect(find.text(_l10n.searchNoMatch), findsNothing);
    await _settle(tester);
  });
}
