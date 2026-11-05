import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/features/settings/ui/settings_sections.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// TASK-E2 §2: the rules of the Settings structure, per form factor.
void main() {
  final container = ProviderContainer();
  tearDownAll(container.dispose);
  final sections = container.read(settingsSectionsProvider);

  test('9 sections in order', () {
    expect(sections.map((s) => s.id), [
      'general',
      'swipe',
      'files',
      'smart',
      'storage',
      'connect',
      'privacy',
      'a11y',
      'about',
    ]);
    final orders = sections.map((s) => s.order).toList();
    expect(orders, [...orders]..sort());
  });

  test('entry ids are unique', () {
    final ids = [
      for (final s in sections)
        for (final e in s.entries) e.id,
    ];
    expect(ids.toSet().length, ids.length);
  });

  test('every entry has a description or is self-explanatory', () {
    for (final s in sections) {
      for (final e in s.entries) {
        expect(
          e.subtitleBuilder != null || e.selfExplanatory,
          isTrue,
          reason: '${e.id} needs a description',
        );
      }
    }
  });

  for (final ff in FormFactor.values) {
    test('${ff.name}: every shown section has at least two entries', () {
      for (final s in sections.where((s) => s.appliesTo(ff))) {
        expect(
          s.entriesFor(ff).length,
          greaterThanOrEqualTo(2),
          reason: '${s.id} on ${ff.name}',
        );
      }
      expect(sections.where((s) => s.appliesTo(ff)).length, 9);
    });
  }

  test('desktop shows no phone-only rows', () {
    final desktopIds = {
      for (final s in sections)
        for (final e in s.entriesFor(FormFactor.desktop)) e.id,
    };
    for (final id in [
      'swipe.customize',
      'swipe.buttonsMode',
      'a11y.haptics',
      'a11y.leftHanded',
      'general.tutorial',
      'privacy.permissions',
      'about.backup',
      'storage.retention',
    ]) {
      expect(desktopIds, isNot(contains(id)), reason: id);
    }
  });

  testWidgets('every entry text builds in every language', (tester) async {
    for (final locale in AppLocalizations.supportedLocales) {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );
      for (final s in sections) {
        expect(s.title(ctx, FormFactor.mobile), isNotEmpty);
        expect(s.title(ctx, FormFactor.desktop), isNotEmpty);
        for (final e in s.entries) {
          expect(e.titleBuilder(ctx), isNotEmpty, reason: e.id);
          expect(e.subtitleBuilder?.call(ctx) ?? 'x', isNotEmpty);
          expect(e.keywordsBuilder?.call(ctx) ?? 'x', isNotEmpty);
        }
      }
    }
  });
}
