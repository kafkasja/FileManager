import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/settings/ui/settings_screen.dart';

/// Opens the phone's Settings section page [id] (`'general'`, `'files'`,
/// …): taps the Settings tab unless the overview already shows, then the
/// section's tile on the overview.
Future<void> openSettingsSection(WidgetTester tester, String id) async {
  if (find.byType(SettingsScreen).hitTestable().evaluate().isEmpty) {
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
  }
  final tile = find.byKey(ValueKey('settings-section-$id'));
  await tester.scrollUntilVisible(
    tile,
    200,
    scrollable: find
        .descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  // Fully on screen (scrollUntilVisible stops once its edge shows).
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}
