import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/widgets/db_error_banner.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_startup_check.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/features/settings/ui/settings_sections.dart';

import '../core/platform/permissions/fake_permission_service.dart';
import '../helpers/pump_app.dart';

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Settings').last);
  await tester.pumpAndSettle();
}

ThemeMode _themeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

void main() {
  testWidgets('Dark theme applies instantly and is stored', (tester) async {
    final app = await pumpApp(tester);
    expect(_themeMode(tester), ThemeMode.system);
    await _openSettings(tester);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await app.container.read(dbWriteQueueProvider).flush();
    await tester.pumpAndSettle();

    expect(_themeMode(tester), ThemeMode.dark);
    expect(
      await app.container
          .read(settingsRepositoryProvider)
          .read(AppSettings.themeMode),
      'dark',
    );
  });

  testWidgets('language picker lists System + English and stores the choice', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await _openSettings(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('setting-general.language')),
        matching: find.byType(DropdownButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('English'), findsWidgets);
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    await app.container.read(dbWriteQueueProvider).flush();
    expect(
      await app.container
          .read(settingsRepositoryProvider)
          .read(AppSettings.localeTag),
      'en',
    );
  });

  testWidgets('Settings shows the sections in order', (tester) async {
    final app = await pumpApp(tester);
    await _openSettings(tester);
    final ids = [
      for (final s in app.container.read(settingsSectionsProvider)) s.id,
    ];
    expect(ids.first, 'general');
    expect(ids.last, 'about');
    expect(find.text('General'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Version 0.1.0'), 200);
    expect(find.text('About & advanced'), findsOneWidget);
    expect(find.text('Version 0.1.0'), findsOneWidget);
    // Scrolling disposed list rows' drift streams: let their close timers run.
    await tester.pumpAndSettle();
  });

  testWidgets('Permissions section shows each state and its action', (
    tester,
  ) async {
    final permissions = FakePermissionService(
      grantedAccess.copyWith(
        media: MediaAccess.limited,
        allFiles: AllFilesAccess.notGranted,
      ),
    );
    await pumpApp(tester, permissions: permissions);
    await _openSettings(tester);
    await tester.scrollUntilVisible(
      find.text('Skip confirmation dialogs'),
      200,
    );
    expect(find.text('Some photos only'), findsOneWidget);
    expect(find.text('Skip confirmation dialogs'), findsOneWidget);

    final turnOn = find.widgetWithText(TextButton, 'Turn on').first;
    await tester.ensureVisible(turnOn);
    await tester.pumpAndSettle();
    await tester.tap(turnOn);
    await tester.pumpAndSettle();
    expect(permissions.calls, contains('openAllFilesAccessSettings'));
  });

  testWidgets('Media management row is hidden where unsupported', (
    tester,
  ) async {
    await pumpApp(
      tester,
      permissions: FakePermissionService(
        grantedAccess.copyWith(mediaManagementSupported: false),
      ),
    );
    await _openSettings(tester);
    await tester.scrollUntilVisible(find.text('All files access'), 200);
    expect(find.text('Skip confirmation dialogs'), findsNothing);
  });

  testWidgets('limited access banner: shown on Swipe, dismissible', (
    tester,
  ) async {
    await pumpApp(
      tester,
      permissions: FakePermissionService(
        grantedAccess.copyWith(media: MediaAccess.limited),
      ),
    );
    expect(find.text('KFM can only see some photos.'), findsOneWidget);
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('KFM can only see some photos.'), findsNothing);
  });

  testWidgets('a failed DB write shows the banner for 5 s', (tester) async {
    final app = await pumpApp(tester);
    app.container
        .read(dbWriteQueueProvider)
        .enqueue(null, () async => throw StateError('disk full'))
        .fireAndForget();
    await tester.pump();
    await tester.pump();
    expect(find.text("Couldn't save your last change."), findsOneWidget);

    await tester.pump(DbErrorBanner.visibleFor);
    await tester.pumpAndSettle();
    expect(find.text("Couldn't save your last change."), findsNothing);
  });

  testWidgets('Q6: a reset damaged database is explained until dismissed', (
    tester,
  ) async {
    await pumpApp(
      tester,
      overrides: [
        dbStartupReportProvider.overrideWithValue(
          const DbStartupReport(
            DbStartupState.reset,
            backupName: 'kfm.sqlite.broken-20261104-120000-000',
          ),
        ),
      ],
    );
    expect(
      find.textContaining('kfm.sqlite.broken-20261104-120000-000'),
      findsOneWidget,
    );
    expect(find.textContaining('were not touched'), findsOneWidget);
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.textContaining('kfm.sqlite.broken'), findsNothing);
  });

  testWidgets('Q6: a database that cannot be opened says so', (tester) async {
    await pumpApp(
      tester,
      overrides: [
        dbStartupReportProvider.overrideWithValue(
          const DbStartupReport(DbStartupState.unavailable),
        ),
      ],
    );
    expect(find.textContaining("can't open its data"), findsOneWidget);
  });
}
