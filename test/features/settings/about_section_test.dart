import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/diagnostics/error_log.dart';
import 'package:kfm/core/diagnostics/error_log_providers.dart';
import 'package:kfm/features/settings/ui/about_section.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:kfm/l10n/generated/app_localizations_en.dart';

import '../../core/diagnostics/fake_error_log.dart';

final AppLocalizations _l10n = AppLocalizationsEn();

const _header = ExportHeader(
  appVersion: '0.1.0',
  buildNumber: '1',
  locale: 'en',
  schemaVersion: 20,
);

class _Shares {
  final List<(File, String)> calls = [];
  bool result = true;

  Future<bool> call(File file, String subject) async {
    calls.add((file, subject));
    return result;
  }
}

Future<void> _pump(
  WidgetTester tester,
  FakeErrorLog log,
  _Shares shares,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        errorLogProvider.overrideWithValue(log),
        errorLogSharerProvider.overrideWithValue(shares.call),
        errorLogExportHeaderProvider.overrideWith((ref) async => _header),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: AboutSection())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ErrorLogEntry _entry(String error) => ErrorLogEntry(
  at: DateTime.utc(2026, 11, 2),
  source: ErrorSource.flutter,
  error: error,
);

ListTile _tile(WidgetTester tester, String title) => tester.widget<ListTile>(
  find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
);

void main() {
  testWidgets('no errors: both tiles disabled', (tester) async {
    await _pump(tester, FakeErrorLog(), _Shares());
    expect(find.text(_l10n.errorLogEmpty), findsOneWidget);
    expect(_tile(tester, _l10n.errorLogShare).enabled, isFalse);
    expect(_tile(tester, _l10n.errorLogClear).enabled, isFalse);
  });

  testWidgets('share builds the export and opens the share sheet', (
    tester,
  ) async {
    final log = FakeErrorLog();
    await log.record(_entry('a'));
    await log.record(_entry('b'));
    final shares = _Shares();
    await _pump(tester, log, shares);
    expect(find.text(_l10n.errorLogShareSubtitle(2)), findsOneWidget);

    await tester.tap(find.text(_l10n.errorLogShare));
    await tester.pumpAndSettle();
    expect(log.exports.single.schemaVersion, 20);
    expect(shares.calls.single.$2, _l10n.errorLogShareSubject);
    expect(find.text(_l10n.errorLogShareFailed), findsNothing);
  });

  testWidgets('no app to share with: a message', (tester) async {
    final log = FakeErrorLog();
    await log.record(_entry('a'));
    final shares = _Shares()..result = false;
    await _pump(tester, log, shares);
    await tester.tap(find.text(_l10n.errorLogShare));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.errorLogShareFailed), findsOneWidget);
  });

  testWidgets('clear asks first, then empties the log', (tester) async {
    final log = FakeErrorLog();
    await log.record(_entry('a'));
    await _pump(tester, log, _Shares());

    await tester.tap(find.text(_l10n.errorLogClear));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.errorLogClearConfirm), findsOneWidget);
    await tester.tap(find.text(_l10n.cancel));
    await tester.pumpAndSettle();
    expect(log.clears, 0);

    await tester.tap(find.text(_l10n.errorLogClear));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.clearConfirm));
    await tester.pumpAndSettle();
    expect(log.clears, 1);
    expect(find.text(_l10n.errorLogCleared), findsOneWidget);
    expect(find.text(_l10n.errorLogEmpty), findsOneWidget);
  });
}
