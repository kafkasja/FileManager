import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/settings/ui/settings_search.dart';

import '../../helpers/pump_app.dart';

Future<TestApp> _settings(WidgetTester tester, {String? lang}) async {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final app = await pumpApp(tester);
  if (lang != null) {
    await app.container
        .read(settingsRepositoryProvider)
        .write(AppSettings.localeTag, lang);
    await tester.pump(const Duration(seconds: 1));
  }
  app.container.read(routerProvider).go(AppRoutes.settings);
  await tester.pumpAndSettle();
  return app;
}

Future<void> _search(WidgetTester tester, String text) async {
  await tester.tap(find.byKey(const ValueKey('settings-search')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('settings-search-field')),
    text,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('settingsTextMatches', () {
    test('every word, case and accents folded', () {
      expect(settingsTextMatches('CACHE', ['Thumbnail cache']), isTrue);
      expect(settingsTextMatches('turkce', ['Türkçe']), isTrue);
      expect(
        settingsTextMatches('thumb clear', ['Thumbnail', 'Clear']),
        isTrue,
      );
      expect(settingsTextMatches('thumb video', ['Thumbnail cache']), isFalse);
      expect(settingsTextMatches('  ', ['anything']), isFalse);
    });
  });

  testWidgets('"cache" finds the thumbnail cache; tapping jumps to it', (
    tester,
  ) async {
    await _settings(tester);
    await _search(tester, 'cache');
    final hit = find.byKey(const ValueKey('settings-hit-storage.thumbCache'));
    expect(hit, findsOneWidget);
    expect(find.text('Storage & cleanup'), findsOneWidget);
    await tester.tap(hit);
    await tester.pumpAndSettle();
    // The entry's section page, not the overview.
    expect(
      find.byKey(const ValueKey('settings-page-storage')),
      findsOneWidget,
    );
    final row = find.byKey(const ValueKey('setting-storage.thumbCache'));
    expect(row, findsOneWidget);
    final box = tester.getRect(row);
    final screen = tester.getRect(find.byType(Scaffold).first);
    expect(screen.overlaps(box), isTrue);
  });

  testWidgets('"vibration" finds the phone-only row', (tester) async {
    await _settings(tester);
    await _search(tester, 'vibration');
    expect(
      find.byKey(const ValueKey('settings-hit-a11y.haptics')),
      findsOneWidget,
    );
  });

  testWidgets('no match says so', (tester) async {
    await _settings(tester);
    await _search(tester, 'zzzqqq');
    expect(find.byKey(const ValueKey('settings-search-empty')), findsOneWidget);
  });

  testWidgets('Dutch: "groot" finds Big files start at', (tester) async {
    await _settings(tester, lang: 'nl');
    await _search(tester, 'groot');
    expect(
      find.byKey(const ValueKey('settings-hit-files.bigFileThreshold')),
      findsOneWidget,
    );
  });

  testWidgets('/settings?entry= scrolls to the entry', (tester) async {
    final app = await _settings(tester);
    app.container
        .read(routerProvider)
        .go(AppRoutes.settingsEntry('about.licences'));
    await tester.pumpAndSettle();
    expect(
      app.container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .path,
      '/settings/section/about',
    );
    final row = find.byKey(const ValueKey('setting-about.licences'));
    final screen = tester.getRect(find.byType(Scaffold).first);
    expect(screen.overlaps(tester.getRect(row)), isTrue);
    // Back goes to the overview.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(row, findsNothing);
    expect(
      find.byKey(const ValueKey('settings-section-about')),
      findsOneWidget,
    );
  });
}
