import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/theme/app_theme.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/app/theme/theme_providers.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';

import '../../helpers/pump_app.dart';

MaterialApp _app(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp));

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Settings').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every accent x brightness themes the swipe screen', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    final settings = app.container.read(settingsRepositoryProvider);
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await settings.write(AppSettings.themeMode, mode.name);
      for (final accent in AppAccent.values) {
        await settings.write(AppSettings.themeAccent, accent);
        await tester.pumpAndSettle();
        final m = _app(tester);
        final brightness = mode == ThemeMode.light
            ? Brightness.light
            : Brightness.dark;
        final theme = mode == ThemeMode.light ? m.theme! : m.darkTheme!;
        expect(
          theme.colorScheme.primary,
          accentScheme(
            brightness,
            // System has no palette in host tests: blue.
            seed: accentSeed(accent),
            monochrome: accent == AppAccent.mono,
          ).primary,
          reason: '${accent.name} ${mode.name}',
        );
        // Swipe colors are the same tokens in every accent.
        expect(
          theme.extension<AppTokens>(),
          mode == ThemeMode.light ? AppTokens.light : AppTokens.dark,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Swipe'), findsWidgets);
      }
    }
  });

  testWidgets('picker writes the setting and re-themes live', (tester) async {
    final app = await pumpApp(tester);
    await _openSettings(tester);
    expect(find.text('Color'), findsOneWidget);
    // No wallpaper palette on the host: System colors is hidden.
    expect(find.byTooltip('System colors'), findsNothing);
    for (final name in ['Blue', 'Green', 'Purple', 'Orange', 'Mono']) {
      expect(find.byTooltip(name), findsOneWidget);
    }

    await tester.tap(find.byTooltip('Green'));
    await tester.pumpAndSettle();
    await app.container.read(dbWriteQueueProvider).flush();
    await tester.pumpAndSettle();

    expect(
      await app.container
          .read(settingsRepositoryProvider)
          .read(AppSettings.themeAccent),
      AppAccent.green,
    );
    expect(
      _app(tester).theme!.colorScheme.primary,
      accentScheme(
        Brightness.light,
        seed: kAccentSeeds[AppAccent.green]!,
      ).primary,
    );
    // The theme mode key is untouched.
    expect(
      await app.container
          .read(settingsRepositoryProvider)
          .read(AppSettings.themeMode),
      'system',
    );
  });

  testWidgets('System colors shows with a wallpaper palette and uses it', (
    tester,
  ) async {
    const wallpaper = Color(0xFF00897B);
    final app = await pumpApp(
      tester,
      overrides: [systemAccentSeedProvider.overrideWith((ref) => wallpaper)],
    );
    await _openSettings(tester);
    await tester.tap(find.byTooltip('System colors'));
    await tester.pumpAndSettle();
    await app.container.read(dbWriteQueueProvider).flush();
    await tester.pumpAndSettle();

    expect(
      _app(tester).darkTheme!.colorScheme.primary,
      accentScheme(Brightness.dark, seed: wallpaper).primary,
    );
  });

  testWidgets('corrupt or unknown stored accent starts as blue', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    for (final raw in ['"teal"', 'not json']) {
      await app.db
          .into(app.db.settings)
          .insertOnConflictUpdate(SettingRow(key: 'theme.accent', value: raw));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        _app(tester).theme!.colorScheme.primary,
        accentScheme(Brightness.light).primary,
      );
    }
  });
}
