import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/theme/app_theme.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/updates/data/github_release_client.dart';
import 'package:kfm/features/updates/data/update_checker.dart';
import 'package:kfm/features/updates/domain/app_version.dart';
import 'package:kfm/features/updates/domain/release_info.dart';
import 'package:kfm/features/updates/domain/update_status.dart';
import 'package:kfm/features/updates/ui/open_release_page.dart';
import 'package:kfm/features/updates/ui/update_banner.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

ReleaseInfo release(String v) => ReleaseInfo(
  version: AppVersion.tryParse(v)!,
  title: 'KFM $v',
  notes: 'Notes $v',
  pageUrl: Uri.parse('${releasePagePrefix}tag/v$v'),
  publishedAt: DateTime.utc(2026, 11),
);

class FakeReleaseClient implements ReleaseClient {
  int calls = 0;
  ReleaseInfo? next;
  Exception? error;

  @override
  Future<ReleaseInfo?> latest() async {
    calls++;
    if (error != null) throw error!;
    return next;
  }
}

void main() {
  late AppDatabase db;
  late FakeReleaseClient client;
  late DateTime now;
  late ProviderContainer container;

  ProviderContainer make() {
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        releaseClientProvider.overrideWithValue(client),
        updateClockProvider.overrideWithValue(() => now),
        currentAppVersionProvider.overrideWithValue(const AppVersion(0, 1, 0)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    client = FakeReleaseClient()..next = release('0.2.0');
    now = DateTime.utc(2026, 11, 2, 12);
    container = make();
  });

  UpdateChecker checker() => container.read(updateCheckerProvider.notifier);
  Future<void> enable() => container
      .read(settingsRepositoryProvider)
      .write(AppSettings.updateCheckEnabled, true);

  test('off by default: automatic checks never send a request', () async {
    expect(AppSettings.updateCheckEnabled.defaultValue, isFalse);
    for (var i = 0; i < 3; i++) {
      expect(await checker().checkNow(manual: false), isNull);
      now = now.add(const Duration(days: 2));
    }
    expect(client.calls, 0);
  });

  test('on: at most one automatic request a day', () async {
    await enable();
    expect(await checker().checkNow(manual: false), isA<UpdateAvailable>());
    now = now.add(const Duration(hours: 1));
    expect(await checker().checkNow(manual: false), isNull);
    now = now.add(const Duration(hours: 22));
    expect(await checker().checkNow(manual: false), isNull);
    expect(client.calls, 1);
    now = now.add(const Duration(hours: 1));
    await checker().checkNow(manual: false);
    expect(client.calls, 2);
    // Clock moved back: a last check "in the future" is stale.
    now = now.subtract(const Duration(days: 3));
    await checker().checkNow(manual: false);
    expect(client.calls, 3);
  });

  test('concurrent triggers share one request', () async {
    await enable();
    await Future.wait([
      checker().checkNow(manual: false),
      checker().checkNow(manual: false),
    ]);
    expect(client.calls, 1);
  });

  test('newer / same / older / none', () async {
    expect(await checker().checkNow(manual: true), isA<UpdateAvailable>());
    client.next = release('0.1.0');
    expect(await checker().checkNow(manual: true), isA<UpToDate>());
    client.next = release('0.0.9');
    expect(await checker().checkNow(manual: true), isA<UpToDate>());
    client.next = null;
    final none = await checker().checkNow(manual: true);
    expect(none, isA<UpToDate>().having((s) => s.noReleases, 'none', true));
    // Manual checks work with the switch off and don't touch lastCheckAt.
    expect(
      await container
          .read(settingsRepositoryProvider)
          .read(AppSettings.updateLastCheckAt),
      '',
    );
  });

  test('failures go to state; a failing request still counts', () async {
    await enable();
    client.error = const ReleaseCheckException(
      ReleaseCheckFailure.offline,
      'no network',
    );
    final r = await checker().checkNow(manual: false);
    expect(
      r,
      isA<UpdateCheckFailed>().having((s) => s.manual, 'manual', false),
    );
    expect(container.read(updateCheckerProvider), isA<UpdateCheckFailed>());
    now = now.add(const Duration(hours: 2));
    await checker().checkNow(manual: false);
    expect(client.calls, 1);
  });

  test('an odd tag is "no update", not an error', () async {
    client.error = const ReleaseCheckException(
      ReleaseCheckFailure.unparsableTag,
      'tag nightly',
    );
    expect(await checker().checkNow(manual: true), isA<UpToDate>());
  });

  test('a newer release survives a restart without a request', () async {
    await checker().checkNow(manual: true);
    await container.read(dbWriteQueueProvider).flush();
    final second = make()..read(updateCheckerProvider);
    await pumpEventQueue();
    expect(second.read(updateCheckerProvider), isA<UpdateAvailable>());
    expect(client.calls, 1);
  });

  group('UpdateBanner', () {
    Future<List<Uri>> pumpBanner(
      WidgetTester tester, {
      String dismissed = '',
    }) async {
      final opened = <Uri>[];
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          releaseClientProvider.overrideWithValue(client),
          currentAppVersionProvider.overrideWithValue(
            const AppVersion(0, 1, 0),
          ),
          updateDismissedVersionProvider.overrideWith(
            (ref) => Stream.value(dismissed),
          ),
          urlOpenerProvider.overrideWithValue((u) async {
            opened.add(u);
            return true;
          }),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: UpdateBanner()),
          ),
        ),
      );
      await tester.runAsync(
        () => c.read(updateCheckerProvider.notifier).checkNow(manual: true),
      );
      await tester.pumpAndSettle();
      return opened;
    }

    testWidgets('Download opens the page', (tester) async {
      final opened = await pumpBanner(tester);
      expect(find.text('KFM 0.2.0 is available'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('update-download')));
      await tester.pumpAndSettle();
      expect(opened.single.toString(), startsWith(releasePagePrefix));
    });

    testWidgets('a dismissed version shows no banner', (tester) async {
      await pumpBanner(tester, dismissed: '0.2.0');
      expect(find.byKey(const ValueKey('update-banner')), findsNothing);
    });

    testWidgets('no banner when up to date', (tester) async {
      client.next = release('0.1.0');
      await pumpBanner(tester);
      expect(find.byKey(const ValueKey('update-banner')), findsNothing);
    });
  });
}
