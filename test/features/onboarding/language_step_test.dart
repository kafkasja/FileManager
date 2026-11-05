import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/onboarding/ui/language_step.dart';

import '../../helpers/pump_app.dart';

/// TASK-E2: the language is asked once at first launch.
void main() {
  testWidgets('first launch asks; the choice is stored and not asked again', (
    tester,
  ) async {
    final app = await pumpApp(
      tester,
      tutorialDone: false,
      languageAsked: false,
    );
    expect(find.byType(LanguageStep), findsOneWidget);
    expect(find.text('System (English)'), findsOneWidget);
    expect(find.text('Nederlands'), findsOneWidget);
    expect(find.text('Türkçe'), findsOneWidget);

    await tester.tap(find.text('Nederlands'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('language-step-continue')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(LanguageStep), findsNothing);
    final settings = app.container.read(settingsRepositoryProvider);
    expect(await settings.read(AppSettings.localeTag), 'nl');
    expect(await settings.read(AppSettings.onboardingLanguageAsked), isTrue);
  });

  testWidgets('an existing install is not asked', (tester) async {
    final app = await pumpApp(tester, languageAsked: false);
    expect(find.byType(LanguageStep), findsNothing);
    expect(
      await app.container
          .read(settingsRepositoryProvider)
          .read(AppSettings.onboardingLanguageAsked),
      isTrue,
    );
  });
}
