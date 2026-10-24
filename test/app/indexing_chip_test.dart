import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/theme/app_theme.dart';
import 'package:kfm/app/widgets/indexing_chip.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:kfm/l10n/generated/app_localizations_en.dart';
import 'package:mocktail/mocktail.dart';

class _MockIndexer extends Mock implements MediaIndexer;

final AppLocalizations _l10n = AppLocalizationsEn();

Future<void> _pump(
  WidgetTester tester,
  Stream<IndexStatus> status, {
  MediaIndexer? indexer,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        indexStatusProvider.overrideWith((ref) => status),
        if (indexer != null) mediaIndexerProvider.overrideWithValue(indexer),
      ],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: IndexingChip()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('idle: hidden', (tester) async {
    await _pump(tester, Stream.value(const IndexIdle(null)));
    expect(find.byType(Chip), findsNothing);
    expect(find.byType(ActionChip), findsNothing);
  });

  testWidgets('scanning: count and spinner', (tester) async {
    await _pump(
      tester,
      Stream.value(const IndexScanning(found: 1, isFirstScan: true)),
    );
    expect(find.text(_l10n.indexingCount(1)), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('scanning: large counts use the generated formatting', (
    tester,
  ) async {
    await _pump(
      tester,
      Stream.value(const IndexScanning(found: 12345, isFirstScan: true)),
    );
    expect(find.text(_l10n.indexingCount(12345)), findsOneWidget);
  });

  testWidgets('failed: paused chip; tap starts the indexer again', (
    tester,
  ) async {
    final indexer = _MockIndexer();
    when(indexer.start).thenAnswer((_) => Future<void>.value());
    await _pump(
      tester,
      Stream.value(IndexFailed(Exception('x'), StackTrace.empty)),
      indexer: indexer,
    );
    expect(
      find.widgetWithText(ActionChip, _l10n.indexingPaused),
      findsOneWidget,
    );
    await tester.tap(find.byType(ActionChip));
    verify(indexer.start).called(1);
  });

  testWidgets('scanning then idle: the chip disappears', (tester) async {
    final status = StreamController<IndexStatus>();
    addTearDown(status.close);
    await _pump(tester, status.stream);
    status.add(const IndexScanning(found: 3, isFirstScan: false));
    await tester.pump();
    await tester.pump();
    expect(find.byType(Chip), findsOneWidget);
    status.add(const IndexIdle(null));
    await tester.pump();
    await tester.pump();
    expect(find.byType(Chip), findsNothing);
  });
}
