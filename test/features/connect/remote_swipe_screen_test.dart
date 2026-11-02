import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/session/domain/remote_deck_root.dart';
import 'package:kfm/features/session/domain/session_source.dart';

import '../../helpers/pump_app.dart';

final String _fp = 'ef' * 32;

void main() {
  testWidgets('offline: "Waiting for Phone…" with Connect again; the Connect '
      'screen offers to continue or discard the session', (tester) async {
    final app = await pumpApp(tester);
    final sessions = app.container.read(sessionRepositoryProvider);
    await tester.runAsync(
      () => sessions.startRemote(
        _fp,
        const RemoteDeckRoot(rootId: 'R1', device: 'Phone'),
      ),
    );

    app.container.read(routerProvider).go(AppRoutes.connectSwipeFor(_fp));
    await tester.pumpAndSettle();
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Waiting for Phone…'), findsOneWidget);
    expect(find.text('Connect again'), findsOneWidget);
    // No local-only controls in a remote session.
    expect(find.byTooltip('Filter'), findsNothing);

    app.container.read(routerProvider).go(AppRoutes.connect);
    await tester.pumpAndSettle();
    expect(find.text('Continue swiping on Phone'), findsOneWidget);
    // Not remembered and not connected: orphaned.
    expect(find.text("Phone isn't remembered any more"), findsOneWidget);

    await tester.tap(find.byTooltip('Discard session'));
    await tester.pumpAndSettle();
    expect(find.text('Discard the swipe session on Phone?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Discard session'));
    await tester.pumpAndSettle();
    expect(find.text('Continue swiping on Phone'), findsNothing);
    final left = await tester.runAsync(
      () => sessions.active(sourceId: remoteSourceId(_fp)),
    );
    expect(left, isNull);
  });
}
