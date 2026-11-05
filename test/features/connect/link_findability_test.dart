import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/desktop/shell/desktop_location.dart';
import 'package:kfm/desktop/tabs/desktop_tabs_controller.dart';
import 'package:kfm/features/browse/ui/widgets/file_actions_menu.dart';
import 'package:kfm/features/connect/domain/link.dart';
import 'package:kfm/features/connect/ui/connect_screen.dart';
import 'package:kfm/features/connect/ui/link_providers.dart';
import 'package:kfm/features/selection/ui/selection_actions.dart';

import '../../desktop/desktop_helpers.dart';
import '../../helpers/pump_app.dart';

const _fp = 'ab12';
const _link = DeviceLink(
  peerFingerprint: _fp,
  peerName: 'KAF-PC',
  connectedToThem: true,
  iSeeTheirs: true,
);

/// TASK-E1c: Connect is easy to find, a linked device shows, and "Send to
/// `device`" is the first file and selection action.
void main() {
  testWidgets('not linked: Browse has a Devices button and a Nearby card; '
      'no chip, no Send to entry', (tester) async {
    final app = await pumpApp(tester);
    expect(find.byKey(const ValueKey('link-chip')), findsNothing);
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('browse-nearby-devices')), findsOneWidget);
    final items = app.container.read(fileMenuItemsProvider);
    expect(items.first.order, greaterThan(1));
    expect(
      app.container.read(selectionActionsProvider).map((a) => a.id),
      isNot(contains('e1.sendLinked')),
    );
    await tester.tap(find.byKey(const ValueKey('browse-devices')));
    await tester.pumpAndSettle();
    expect(find.byType(ConnectScreen), findsOneWidget);
  });

  testWidgets('linked: chip above the tabs; Send to <device> comes first', (
    tester,
  ) async {
    final app = await pumpApp(
      tester,
      overrides: [currentLinkProvider.overrideWithValue(_link)],
    );
    expect(find.byKey(const ValueKey('link-chip')), findsOneWidget);
    expect(find.text('Connected to KAF-PC'), findsOneWidget);
    final first = app.container.read(fileMenuItemsProvider).first;
    expect(first.order, 1);
    final ctx = tester.element(find.byKey(const ValueKey('link-chip')));
    expect(first.label(ctx), 'Send to KAF-PC');
    final actions = app.container.read(selectionActionsProvider);
    expect(actions.first.id, 'e1.sendLinked');
    expect(actions.first.primary, isTrue);
    expect(actions.first.label(ctx), 'Send to KAF-PC');
  });

  testWidgets('desktop: the linked device is a nav pane row that opens its '
      'files; the status bar says Connected to', (tester) async {
    final app = await pumpDesktopApp(
      tester,
      overrides: [currentLinkProvider.overrideWithValue(_link)],
    );
    final row = find.byKey(const ValueKey('desktop-device-$_fp'));
    expect(row, findsOneWidget);
    expect(find.byKey(const ValueKey('link-status-chip')), findsOneWidget);
    await tester.tap(row);
    await tester.pump(const Duration(seconds: 1));
    expect(
      app.container.read(desktopTabsControllerProvider).current.location,
      const RouteLocation('/connect/browse/$_fp'),
    );
  });
}
