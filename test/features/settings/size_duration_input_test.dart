import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/utils/human_units.dart';
import 'package:kfm/features/settings/ui/widgets/unit_input_row.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:kfm/l10n/generated/app_localizations_en.dart';

const int _mb = 1024 * 1024;
final AppLocalizations _l10n = AppLocalizationsEn();

/// Pumps a size or duration row; returns the saved values.
Future<List<int>> _pump(
  WidgetTester tester, {
  required bool size,
  required int value,
}) async {
  final saved = <int>[];
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => size
                ? UnitInputRow.size(
                    title: 'Big files start at',
                    subtitle: 'sub',
                    value: value,
                    presets: const [50 * _mb, 100 * _mb],
                    format: (v) => formatSizeSetting(context, v),
                    onSaved: saved.add,
                  )
                : UnitInputRow.duration(
                    title: 'Same time window',
                    subtitle: 'sub',
                    value: value,
                    presets: const [5, 60],
                    format: (v) => formatShortDuration(_l10n, v),
                    onSaved: saved.add,
                  ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byType(UnitInputRow));
  await tester.pumpAndSettle();
  return saved;
}

Future<void> _type(WidgetTester tester, String text, {String? unit}) async {
  await tester.enterText(find.byKey(const ValueKey('unit-input-field')), text);
  await tester.pumpAndSettle();
  if (unit != null) {
    await tester.tap(find.byKey(const ValueKey('unit-input-unit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(unit).last);
    await tester.pumpAndSettle();
  }
}

bool _canSave(WidgetTester tester) =>
    tester
        .widget<FilledButton>(find.byKey(const ValueKey('unit-input-save')))
        .onPressed !=
    null;

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('unit-input-save')));
  await tester.pumpAndSettle();
}

void main() {
  group('formatShortDuration', () {
    test('seconds, minutes, hours', () {
      expect(formatShortDuration(_l10n, 45), '45 s');
      expect(formatShortDuration(_l10n, 120), '2 min');
      expect(formatShortDuration(_l10n, 90), '1 min 30 s');
      expect(formatShortDuration(_l10n, 3600), '1 h');
      expect(formatShortDuration(_l10n, 5400), '1 h 30 min');
    });
  });

  group('parseAmount / unitFor', () {
    test('parses decimals with either separator', () {
      expect(parseAmount('1.5', InputUnit.gigabytes), 1536 * _mb);
      expect(parseAmount('1,5', InputUnit.minutes), 90);
      expect(parseAmount('abc', InputUnit.seconds), isNull);
      expect(parseAmount('0', InputUnit.seconds), isNull);
      expect(parseAmount('-2', InputUnit.seconds), isNull);
    });
    test('picks the largest whole unit', () {
      expect(unitFor(7200, InputUnit.durationUnits), InputUnit.hours);
      expect(unitFor(90, InputUnit.durationUnits), InputUnit.seconds);
      expect(unitFor(250 * _mb, InputUnit.sizeUnits), InputUnit.megabytes);
      expect(unitFor(2048 * _mb, InputUnit.sizeUnits), InputUnit.gigabytes);
    });
  });

  testWidgets('big files accept 75 MB and 2 GB', (tester) async {
    var saved = await _pump(tester, size: true, value: 100 * _mb);
    await _type(tester, '75');
    await _save(tester);
    expect(saved, [75 * _mb]);

    saved = await _pump(tester, size: true, value: 100 * _mb);
    await _type(tester, '2', unit: 'GB');
    await _save(tester);
    expect(saved, [2048 * _mb]);
  });

  testWidgets('same time accepts 90 s and 1 h; presets fill the field', (
    tester,
  ) async {
    var saved = await _pump(tester, size: false, value: 5);
    await _type(tester, '90');
    await _save(tester);
    expect(saved, [90]);

    saved = await _pump(tester, size: false, value: 5);
    await _type(tester, '1', unit: 'h');
    await _save(tester);
    expect(saved, [3600]);

    saved = await _pump(tester, size: false, value: 5);
    await tester.tap(find.byKey(const ValueKey('unit-preset-60')));
    await tester.pumpAndSettle();
    await _save(tester);
    expect(saved, [60]);
  });

  testWidgets('0, letters and too much cannot be saved', (tester) async {
    final saved = await _pump(tester, size: false, value: 5);
    for (final bad in ['0', 'abc', '']) {
      await _type(tester, bad);
      expect(_canSave(tester), isFalse, reason: bad);
    }
    await _type(tester, '25', unit: 'h');
    expect(_canSave(tester), isFalse);
    expect(find.textContaining('Enter a value from'), findsOneWidget);
    await _type(tester, '24');
    expect(_canSave(tester), isTrue);
    expect(saved, isEmpty);
  });
}
