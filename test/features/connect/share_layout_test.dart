import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/connect/ui/share_screen.dart';

import '../../desktop/desktop_helpers.dart';
import '../../helpers/pump_app.dart';
import 'share_fakes.dart';

/// TASK-E1 issue 1: "the qr code showed up but it was scrollable … dont
/// make it scrollable, it should all be on screen". Issue 5: the Connected
/// screen isn't centered.
/// Unmounts the app so stream providers close inside the test (their
/// drift close timers fire before the pending-timer check).
Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  void expectFits(WidgetTester tester, Size window, {double minQr = 120}) {
    expect(tester.takeException(), isNull, reason: 'overflow at $window');
    expect(find.byType(ShareScreen), findsOneWidget);
    // SelectableText has its own one-line Scrollable: not a page scroll.
    final scrolls = find
        .descendant(
          of: find.byType(ShareScreen),
          matching: find.byType(Scrollable),
        )
        .evaluate()
        .where((e) => e.findAncestorWidgetOfExactType<EditableText>() == null);
    expect(scrolls, isEmpty, reason: 'scrolls at $window');
    final qr = tester.getRect(find.byKey(const ValueKey('share-qr')));
    expect(qr.width, greaterThanOrEqualTo(minQr), reason: 'QR at $window');
    expect(
      (Offset.zero & window).contains(qr.topLeft) &&
          (Offset.zero & window).contains(qr.bottomRight - const Offset(1, 1)),
      isTrue,
      reason: 'QR $qr outside $window',
    );
    final stop = tester.getRect(find.byKey(const ValueKey('share-stop')));
    expect(stop.bottom, lessThanOrEqualTo(window.height), reason: '$window');
  }

  for (final size in const [
    Size(800, 600),
    Size(1280, 720),
    Size(360, 640),
    Size(412, 915),
  ]) {
    for (final scale in const [1.0, 1.3]) {
      testWidgets('the share screen fits ${size.width.toInt()}×'
          '${size.height.toInt()} at text $scale without scrolling', (
        tester,
      ) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final app = await pumpApp(
          tester,
          overrides: shareTestOverrides().overrides,
        );
        app.container.read(routerProvider).go(AppRoutes.connectShare);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        // Big text on the smallest phone: a smaller QR (still ~180 px on a
        // 3× screen), never a scroll.
        expectFits(
          tester,
          size,
          minQr: size.height < 700 && scale > 1 ? 56 : 120,
        );
        await tester.pump();
        // The notes that don't fit are one tap away.
        if (find.byKey(const ValueKey('share-info')).evaluate().isEmpty) {
          expect(
            find.text(
              'While sharing, devices on this Wi-Fi can see this device’s '
              'name.',
            ),
            findsOneWidget,
          );
        }
        await _finish(tester);
      });
    }
  }

  for (final size in const [desktopWindow, Size(800, 600)]) {
    testWidgets('the desktop Devices share pane fits ${size.width.toInt()}×'
        '${size.height.toInt()}', (tester) async {
      await pumpDesktopApp(tester, overrides: shareTestOverrides().overrides);
      tester.view.physicalSize = size;
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('desktop-nav-devices')));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('devices-share')));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expectFits(tester, size);
      await _finish(tester);
    });
  }

  testWidgets('the info button shows the notes that did not fit', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await pumpApp(
      tester,
      overrides: shareTestOverrides().overrides,
    );
    app.container.read(routerProvider).go(AppRoutes.connectShare);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('share-info')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('share-info-dialog')), findsOneWidget);
    expect(
      find.text(
        'While sharing, devices on this Wi-Fi can see this device’s name.',
      ),
      findsOneWidget,
    );
    await _finish(tester);
  });

  testWidgets('issue 5: the Connect screen message is centered', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await pumpApp(
      tester,
      overrides: [
        ...shareTestOverrides().overrides,
        remoteConnectionControllerProvider.overrideWith(FakeConnected.new),
      ],
    );
    app.container.read(routerProvider).go(AppRoutes.connect);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Connected to KAF-PC'), findsOneWidget);
    final box = find.byKey(const ValueKey('connect-message'));
    final rect = tester.getRect(box.first);
    expect((rect.center.dx - 412 / 2).abs(), lessThan(1));
    final title = tester.getRect(find.text('Connected to KAF-PC'));
    expect((title.center.dx - 412 / 2).abs(), lessThan(1));
    dropFakeConnection(app.container);
    await tester.pump(const Duration(seconds: 5));
    await _finish(tester);
  });
}
