import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/search/data/search_vocabulary.dart';
import 'package:kfm/features/search/ui/search_settings_section.dart';
import 'package:kfm/features/settings/ui/settings_sections.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import 'fixture_bundle.dart';

Future<void> _pump(WidgetTester tester, AssetBundle bundle) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // No database: the setting is a fixed stream here.
        searchSecondaryLanguageProvider.overrideWith((ref) => Stream.value('')),
        searchAssetBundleProvider.overrideWithValue(bundle),
        searchMainLanguageProvider.overrideWith((ref) async => 'en'),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SearchLanguageRows()),
      ),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
}

void main() {
  testWidgets('"Also search in" is hidden with only one term file', (
    tester,
  ) async {
    await _pump(
      tester,
      FixtureTermsBundle.langs({'en': 'assets/search/terms_en.json'}),
    );
    expect(find.text('Also search in'), findsNothing);
    expect(find.byKey(const ValueKey('searchSecondaryLanguage')), findsNothing);
  });

  testWidgets('a second term file shows the row, main greyed out', (
    tester,
  ) async {
    await _pump(
      tester,
      FixtureTermsBundle.langs({
        'en': 'assets/search/terms_en.json',
        'xx': fixture('xx'),
      }),
    );
    expect(find.text('Also search in'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('English (already included)'), findsWidgets);
    expect(find.text('xx'), findsWidgets);
    final item = tester.widget<DropdownMenuItem<String>>(
      find
          .byWidgetPredicate(
            (w) => w is DropdownMenuItem<String> && w.value == 'en',
          )
          .last,
    );
    expect(item.enabled, isFalse);
  });

  test('the search language entry is registered', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect([
      for (final s in container.read(settingsSectionsProvider))
        for (final e in s.entries) e.id,
    ], contains('general.searchLanguage'));
  });
}
