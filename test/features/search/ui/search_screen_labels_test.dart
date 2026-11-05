import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/ai_labels/data/ai_labels_providers.dart';
import 'package:kfm/features/ai_labels/domain/label_map.dart';
import 'package:kfm/features/browse/data/recent_searches.dart';
import 'package:kfm/features/search/data/label_keywords.dart';
import 'package:kfm/features/search/data/search_vocabulary.dart';
import 'package:kfm/features/search/ui/search_controller.dart';
import 'package:kfm/features/search/ui/search_screen.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../../../core/files/fake_file_source.dart';
import '../../../helpers/pump_app.dart';
import '../../ai_labels/ai_models_ui_test.dart' show FakeStore;
import '../fixture_bundle.dart';

const _cam = '/storage/emulated/0/DCIM/Camera';
final AppLocalizations _l10n = lookupAppLocalizations(const Locale('en'));

String _id(String name) => 'path:$_cam/$name';

FakeFileSource _library() {
  final files = FakeFileSource();
  final t = DateTime.utc(2025);
  var i = 0;
  for (final name in [
    'tom.jpg',
    'rex.jpg',
    'shore.jpg',
    'blurred.jpg',
    'cat-notes.txt',
  ]) {
    files.addFile('$_cam/$name', modifiedAt: t.add(Duration(minutes: i++)));
  }
  return files;
}

/// TASK-C4 in B8's search screen (real term files and label map).
void main() {
  late FakeStore store;

  Future<TestApp> open(
    WidgetTester tester, {
    bool enabled = false,
    bool installed = false,
    bool labeled = true,
  }) async {
    store = FakeStore(installed: installed);
    final app = await pumpApp(
      tester,
      files: _library(),
      overrides: [
        aiSupportProvider.overrideWith((ref) async => AiSupport.supported),
        // Synchronous reads: rootBundle's async asset loads don't finish
        // reliably under the widget tester's fake clock.
        labelMapJsonProvider.overrideWith(
          (ref) async => File(LabelMap.assetPath).readAsStringSync(),
        ),
        searchAssetBundleProvider.overrideWithValue(
          FixtureTermsBundle({
            searchTermsAsset('en'): searchTermsAsset('en'),
            kLabelExpansionsAsset: kLabelExpansionsAsset,
          }),
        ),
        aiModelStoreProvider.overrideWith((ref) async {
          await store.verifyInstalled();
          return store;
        }),
      ],
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    if (labeled) {
      await app.db.customStatement(
        'INSERT INTO ai_labels (file_id, label, confidence) VALUES '
        "('${_id('tom.jpg')}', 'cat', 0.9), "
        "('${_id('tom.jpg')}', 'pet', 0.9), "
        "('${_id('tom.jpg')}', 'animal', 0.9), "
        "('${_id('rex.jpg')}', 'dog', 0.9), "
        "('${_id('rex.jpg')}', 'animal', 0.9), "
        "('${_id('shore.jpg')}', 'beach', 0.9), "
        "('${_id('shore.jpg')}', 'color:blue', 0.9), "
        "('${_id('blurred.jpg')}', 'beach', 0.9)",
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      // Two of four images processed (50%).
      await app.db.customStatement(
        'INSERT INTO ai_label_status (file_id, outcome, model_version, '
        'file_modified_at_ms, processed_at_ms) '
        "SELECT id, 'labeled', 1, modified_at_ms, $now FROM media_index "
        "WHERE id IN ('${_id('tom.jpg')}', '${_id('rex.jpg')}')",
      );
    }
    await app.db.customStatement(
      'INSERT INTO image_signals (file_id, status, d_hash, blur_score, '
      'file_modified_at_ms, algo_version) VALUES '
      "('${_id('blurred.jpg')}', 'ok', 1, 10.0, 1, 1), "
      "('${_id('shore.jpg')}', 'ok', 2, 900.0, 1, 1)",
    );
    if (enabled) {
      await app.container
          .read(settingsRepositoryProvider)
          .write(AppSettings.aiLabelsEnabled, true);
    }
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(_l10n.searchOpen));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    return app;
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField).first, text);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  Finder file(String name) => find.byWidgetPredicate(
    (w) =>
        (w is Text && (w.data == name || w.textSpan?.toPlainText() == name)) ||
        (w is Semantics && w.properties.label == name),
  );

  Finder chip(String label) => find.widgetWithText(InputChip, label);

  SearchState state(TestApp app) =>
      app.container.read(searchScreenControllerProvider(null));

  /// Lets the "record this search" timer run out, flushes the queue.
  Future<void> settle(WidgetTester tester, TestApp app) async {
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await app.container.read(dbWriteQueueProvider).flush();
  }

  testWidgets('cat / kitten: content chip + cat photos only', (tester) async {
    final app = await open(tester, enabled: true, installed: true);
    await type(tester, 'kitten');
    expect(chip('Content: cat'), findsOneWidget);
    expect(file('tom.jpg'), findsOneWidget);
    expect(file('rex.jpg'), findsNothing);
    expect(file('cat-notes.txt'), findsNothing);
    expect(state(app).query.labelTerms, [
      {'cat'},
    ]);
    await settle(tester, app);
  });

  testWidgets('animal also finds dogs; blue beach needs both', (tester) async {
    final app = await open(tester, enabled: true, installed: true);
    await type(tester, 'animal');
    expect(file('tom.jpg'), findsOneWidget);
    expect(file('rex.jpg'), findsOneWidget);
    expect(file('shore.jpg'), findsNothing);

    await type(tester, 'blue beach');
    expect(file('shore.jpg'), findsOneWidget);
    expect(file('blurred.jpg'), findsNothing);
    await settle(tester, app);
  });

  testWidgets("blurry uses C2's scores; not gated by labeling", (tester) async {
    final app = await open(tester, labeled: false);
    await type(tester, 'blurry');
    expect(chip(_l10n.searchChipBlurry), findsOneWidget);
    expect(file('blurred.jpg'), findsOneWidget);
    expect(file('shore.jpg'), findsNothing);
    // No label chip → no labeling hint.
    expect(find.text(_l10n.searchLabelingOff), findsNothing);
    await settle(tester, app);
  });

  testWidgets('still labeling: banner with the percentage', (tester) async {
    final app = await open(tester, enabled: true, installed: true);
    await type(tester, 'beach');
    expect(find.text(_l10n.searchStillLabeling(0.5)), findsOneWidget);
    expect(find.textContaining('50%'), findsOneWidget);
    await settle(tester, app);
  });

  testWidgets('labeling at 0%: banner, empty results, no error', (
    tester,
  ) async {
    final app = await open(
      tester,
      enabled: true,
      installed: true,
      labeled: false,
    );
    await type(tester, 'cat');
    expect(find.text(_l10n.searchStillLabeling(0)), findsOneWidget);
    expect(find.text(_l10n.searchNoMatch), findsOneWidget);
    await settle(tester, app);
  });

  testWidgets('labeling off, nothing labeled: "turn on" hint, the word is '
      'searched as a name (no ai_labels term); Turn on opens Settings → '
      'Photo labels', (tester) async {
    final app = await open(tester, labeled: false);
    await type(tester, 'cat');
    expect(chip('Content: cat'), findsOneWidget);
    expect(find.text(_l10n.searchLabelingOff), findsOneWidget);
    expect(state(app).query.labelTerms, isEmpty);
    expect(state(app).query.nameContains, 'cat');
    expect(file('cat-notes.txt'), findsOneWidget);

    await tester.tap(find.text(_l10n.searchLabelingOffTurnOn));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('setting-smart.aiLabels')),
      findsOneWidget,
    );
    expect(store.downloads, 0);
    await settle(tester, app);
  });

  testWidgets('labeling off, models installed: Turn on enables labeling', (
    tester,
  ) async {
    final app = await open(tester, installed: true, labeled: false);
    await type(tester, 'dog');
    expect(find.text(_l10n.searchLabelingOff), findsOneWidget);
    await tester.tap(find.text(_l10n.searchLabelingOffTurnOn));
    await tester.pumpAndSettle();
    await app.container.read(dbWriteQueueProvider).flush();
    expect(
      await app.container
          .read(settingsRepositoryProvider)
          .read(AppSettings.aiLabelsEnabled),
      isTrue,
    );
    expect(find.text(_l10n.searchLabelingOff), findsNothing);
    // Now a content term.
    expect(state(app).query.labelTerms, [
      {'dog'},
    ]);
    await settle(tester, app);
  });

  testWidgets('labeling off but labels from before: they still work', (
    tester,
  ) async {
    final app = await open(tester);
    await type(tester, 'cat');
    expect(find.text(_l10n.searchLabelingOff), findsOneWidget);
    expect(file('tom.jpg'), findsOneWidget);
    expect(file('cat-notes.txt'), findsNothing);
    await settle(tester, app);
  });

  testWidgets('chip ✕ turns the content word into a name search', (
    tester,
  ) async {
    final app = await open(tester, enabled: true, installed: true);
    await type(tester, 'cat');
    await tester.tap(
      find
          .descendant(of: chip('Content: cat'), matching: find.byType(Icon))
          .last,
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(state(app).query.labelTerms, isEmpty);
    expect(file('cat-notes.txt'), findsOneWidget);
    await settle(tester, app);
  });

  testWidgets('a content search becomes a recent with its content part', (
    tester,
  ) async {
    final app = await open(tester, enabled: true, installed: true);
    await type(tester, 'blue beach');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester, app);
    final recents = RecentSearchesRepository.decode(
      await app.container
          .read(settingsRepositoryProvider)
          .read(AppSettings.browseRecentSearches),
    );
    expect(recents.first.title, 'blue beach');
    expect(recents.first.query.labelTerms, [
      {'color:blue'},
      {'beach'},
    ]);
  });

  testWidgets('Swipe these on cat: contentSearch origin, the cat photos', (
    tester,
  ) async {
    final app = await open(tester, enabled: true, installed: true);
    await type(tester, 'cat');
    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.browseSwipeThese).last);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final router = app.container.read(routerProvider);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.swipe,
    );
    final deck = app.container.read(swipeDeckControllerProvider).value!;
    expect(deck.source?.origin, SwipeSourceOrigin.contentSearch);
    expect([for (final f in deck.upcoming) f.name], ['tom.jpg']);
    await settle(tester, app);
  });

  testWidgets('a result tap opens the viewer, not the swipe deck', (
    tester,
  ) async {
    final app = await open(tester, enabled: true, installed: true);
    final before = app.container.read(swipeDeckControllerProvider).value;
    await type(tester, 'cat');
    await tester.tap(file('tom.jpg').first);
    await tester.pumpAndSettle();
    final router = app.container.read(routerProvider);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      isNot(AppRoutes.swipe),
    );
    final after = app.container.read(swipeDeckControllerProvider).value;
    expect(after?.current?.id, before?.current?.id);
    await tester.pageBack();
    await settle(tester, app);
  });
}
