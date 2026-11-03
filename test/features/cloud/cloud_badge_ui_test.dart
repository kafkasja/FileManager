import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/cloud/data/cloud_providers.dart';
import 'package:kfm/features/cloud/domain/cloud_destination.dart';
import 'package:kfm/features/cloud/domain/cloud_state.dart';
import 'package:kfm/features/cloud/ui/cloud_badge.dart';
import 'package:kfm/features/cloud/ui/cloud_badge_cache.dart';
import 'package:kfm/features/filters/ui/filter_sheet.dart';
import 'package:kfm/features/privacy/data/privacy_providers.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_setup_strip.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';
import 'cloud_test_seed.dart';

Future<TestApp> _pump(WidgetTester tester) async {
  final files = FakeFileSource()
    ..addFile(
      '/s/DCIM/Camera/p1.jpg',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, 1, 2, 345),
    )
    ..addFile(
      '/s/DCIM/Camera/p2.jpg',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, 3),
    );
  final app = await pumpApp(
    tester,
    files: files,
    // X2's temp cleanup has no path_provider here; its retries would
    // outlive these longer tests.
    overrides: [privacyStartupCleanupProvider.overrideWith((ref) async => 0)],
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return app;
}

Future<void> _openSheet(WidgetTester tester) async {
  unawaited(showFilterSheet(tester.element(find.byType(SwipeSetupStrip))));
  await tester.pumpAndSettle();
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 600));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
  }
  await tester.pumpAndSettle();
}

const ValueKey<String> _onCloud = ValueKey('cloud-badge-onCloud');

void main() {
  testWidgets('no uploads: no icon, no filter row, cache never built', (
    tester,
  ) async {
    final app = await _pump(tester);
    expect(find.byKey(_onCloud), findsNothing);
    expect(app.container.exists(cloudBadgeCacheProvider), isFalse);
    await _openSheet(tester);
    // The favorites switch comes right after where the row would be.
    final favorites = find.text('Favorites only');
    await tester.scrollUntilVisible(
      favorites,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const ValueKey('filter-cloud-row')), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('an upload: card badge, setting off hides it, filter row '
      'narrows the deck', (tester) async {
    final app = await _pump(tester);
    final deck = app.container.read(swipeDeckControllerProvider).value!;
    final current = deck.current!;
    await tester.runAsync(() async {
      final dest = await seedDestination(app.db, 'Drive');
      await seedUpload(app.db, current, dest);
    });
    await _settle(tester);
    expect(find.byKey(_onCloud), findsWidgets);

    await tester.runAsync(
      () => app.container
          .read(settingsRepositoryProvider)
          .write(AppSettings.cloudShowBadge, false),
    );
    await _settle(tester);
    expect(find.byKey(_onCloud), findsNothing);

    await _openSheet(tester);
    const row = ValueKey('filter-cloud-row');
    await tester.scrollUntilVisible(
      find.byKey(row),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(row), findsOneWidget);
    // Clear of the sheet's bottom bar.
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('On cloud'));
    await _settle(tester);
    expect(find.text('1 file matches'), findsOneWidget);
    await tester.tap(find.text('Not on cloud'));
    await _settle(tester);
    expect(find.text('1 file matches'), findsOneWidget);
    await tester.tap(find.text('On cloud'));
    await _settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(
      [
        for (final f
            in app.container.read(swipeDeckControllerProvider).value!.upcoming)
          f.id,
      ],
      [current.id],
    );
    await _settle(tester);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('viewer lines: one per upload, removed and changed noted', (
    tester,
  ) async {
    final file = FileRef(
      id: 'f',
      uri: 'content://f',
      name: 'f.jpg',
      kind: FileKind.image,
      sizeBytes: 100,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(5000, isUtc: true),
      folderPath: '/s/DCIM',
      origin: FileOrigin.local,
    );
    CloudDestination dest(int id, String label, {DateTime? removedAt}) =>
        CloudDestination(
          id: id,
          label: label,
          provider: CloudProviderGuess.googleDrive,
          location: 'content://$id',
          addedAt: DateTime.utc(2026),
          removedAt: removedAt,
        );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudHasUploadsProvider.overrideWith((ref) => Stream.value(true)),
          cloudUploadsOfFileProvider('f').overrideWith(
            (ref) => Stream.value(const [
              CloudUploadFact(
                destinationId: 1,
                sizeBytes: 100,
                sourceModifiedAtMs: 5000,
                uploadedAtMs: 0,
              ),
              CloudUploadFact(
                destinationId: 2,
                sizeBytes: 100,
                sourceModifiedAtMs: 5000,
                uploadedAtMs: 0,
              ),
              CloudUploadFact(
                destinationId: 3,
                sizeBytes: 99,
                sourceModifiedAtMs: 5000,
                uploadedAtMs: 0,
              ),
            ]),
          ),
          cloudDestinationsByIdProvider.overrideWith(
            (ref) => Stream.value({
              1: dest(1, 'Drive › Photos'),
              2: dest(2, 'Box', removedAt: DateTime.utc(2026)),
              3: dest(3, 'OneDrive'),
            }),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CloudInfoLines(file: file)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Uploaded by KFM to Drive › Photos · '),
      findsOneWidget,
    );
    expect(
      find.textContaining('Uploaded by KFM to Box (removed) · '),
      findsOneWidget,
    );
    expect(find.text('Changed since upload to OneDrive'), findsOneWidget);
  });
}
