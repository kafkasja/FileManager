import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/settings/ui/settings_sections.dart';

import '../desktop/desktop_helpers.dart';

/// TASK-E2 §5: the desktop app never calls the PC a phone. Texts that name
/// a phone on purpose (the other device) are allowed.
const _allowed = {
  'Connect a phone or another PC',
  'Show a QR code and a code for your phone',
  'See and send files between your phone and PC over Wi-Fi.',
};

/// Every text on screen that says "phone" and isn't allowed.
List<String> _phoneTexts(WidgetTester tester) => [
  for (final w in tester.widgetList<RichText>(find.byType(RichText)))
    if (w.text.toPlainText() case final t
        when t.toLowerCase().contains('phone') && !_allowed.contains(t))
      t,
];

void main() {
  testWidgets('desktop Settings: no text says "phone"', (tester) async {
    final app = await pumpDesktopApp(tester, files: desktopLibrary(3));
    await tester.tap(find.byKey(const ValueKey('desktop-nav-settings')));
    await tester.pumpAndSettle();
    final offenders = <String>[];
    for (final s in app.container.read(settingsSectionsProvider)) {
      final cat = find.byKey(ValueKey('settings-cat-${s.id}'));
      if (cat.evaluate().isEmpty) continue;
      await tester.tap(cat);
      await tester.pumpAndSettle();
      offenders.addAll(_phoneTexts(tester));
    }
    expect(offenders, isEmpty);
    // E2 §5: Photo labels is visible on desktop, with the reason.
    await tester.tap(find.byKey(const ValueKey('settings-cat-smart')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ai-labels-unsupported')), findsOneWidget);
  });

  testWidgets('desktop Sort, Browse and Trash: no text says "phone"', (
    tester,
  ) async {
    await pumpDesktopApp(tester, files: desktopLibrary(3));
    final offenders = <String>[];
    for (final nav in ['sort', 'browse', 'trash']) {
      await tester.tap(find.byKey(ValueKey('desktop-nav-$nav')));
      await tester.pumpAndSettle();
      offenders.addAll(_phoneTexts(tester));
    }
    expect(offenders, isEmpty);
  });
}
