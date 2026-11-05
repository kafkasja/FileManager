import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/platform/screen_awake.dart';
import 'package:kfm/desktop/connect/desktop_devices_screen.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/offer_service.dart';
import 'package:kfm/features/connect/data/pairing_secret_store.dart';
import 'package:kfm/features/connect/data/path_guard.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/share_background.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/data/shared_folder_fs.dart';
import 'package:kfm/features/connect/data/upload_store.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/offer_protocol.dart';
import 'package:kfm/features/connect/ui/link_dialog.dart';
import 'package:kfm/features/connect/ui/offer_dialog.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/connect/ui/share_screen.dart';
import 'package:kfm/features/connect/ui/share_server_controller.dart';

import '../../desktop/desktop_helpers.dart';
import '../../helpers/pump_app.dart';
import 'fake_discovery.dart';
import 'share_fakes.dart';

/// TASK-E1 issue 2: "when i pressed stop sharing immediately after the app
/// screen went black" (PC), then the phone. Each hypothesis (H1–H3 in the
/// plan) has a test here.
void main() {
  late FakeServer server;

  List<Override> shareOverrides() {
    final identity = FakeIdentity();
    server = FakeServer(identity);
    return [
      screenAwakeProvider.overrideWithValue(FakeAwake()),
      secretStoreProvider.overrideWithValue(InMemorySecretStore()),
      deviceIdentityRepositoryProvider.overrideWithValue(identity),
      shareServerProvider.overrideWithValue(server),
      shareDiscoveryProvider.overrideWithValue(FakeDiscovery()),
      sharedFolderFsProvider.overrideWithValue(FakeFolderFs()),
      lifecycleStopsSharingProvider.overrideWithValue(false),
      shareBackgroundProvider.overrideWithValue(const NoShareBackground()),
      pathGuardProvider.overrideWithValue(PathGuard(resolver: (p) async => p)),
      pairingSecretStoreProvider.overrideWithValue(
        PairingSecretStore(autoRefresh: false, clock: DateTime.now),
      ),
    ];
  }

  Future<void> openDesktopShare(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('desktop-nav-devices')));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('devices-share')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byType(ShareScreen), findsOneWidget);
  }

  void expectDevicesStart(TestApp app) {
    expect(find.byType(DesktopDevicesScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('devices-share')), findsOneWidget);
    expect(find.byType(ShareScreen), findsNothing);
    expect(
      app.container.read(shareServerControllerProvider).status,
      ShareServerStatus.stopped,
    );
  }

  group('H1 desktop: the share pane is embedded, not a route', () {
    testWidgets('Stop sharing goes back to the Devices start pane', (
      tester,
    ) async {
      final app = await pumpDesktopApp(tester, overrides: shareOverrides());
      await openDesktopShare(tester);
      await tester.tap(find.byKey(const ValueKey('share-stop')));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expectDevicesStart(app);
      expect(server.stops, 1);
      // Five times in a row (the hand check).
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const ValueKey('devices-share')));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        expect(server.isRunning, isTrue, reason: 'restart $i');
        await tester.tap(find.byKey(const ValueKey('share-stop')));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        expectDevicesStart(app);
      }
    });

    testWidgets('Stop with running transfers asks first, then stops', (
      tester,
    ) async {
      final app = await pumpDesktopApp(tester, overrides: shareOverrides());
      await openDesktopShare(tester);
      final sessions = app.container.read(clientSessionStoreProvider);
      final s = sessions.issue(
        clientFingerprint: 'cd' * 32,
        clientDeviceId: 'dev-b',
        clientName: 'Phone B',
      );
      final body = StreamController<int>();
      final unregister = sessions.registerStream(
        s.session.sessionId,
        body.stream.listen((_) {}),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('share-stop')));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('share-stop-confirm')), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('share-stop-confirm')),
          matching: find.text('Stop sharing'),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expectDevicesStart(app);
      unregister();
      sessions.clear();
      unawaited(body.close());
    });

    testWidgets('Esc and the system back key never empty the pane', (
      tester,
    ) async {
      await pumpDesktopApp(tester, overrides: shareOverrides());
      await openDesktopShare(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DesktopDevicesScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DesktopDevicesScreen), findsOneWidget);
    });
  });

  testWidgets('H2: an accept prompt ended elsewhere closes only itself, not '
      'the dialog above it', (tester) async {
    final app = await pumpDesktopApp(tester, overrides: shareOverrides());
    await openDesktopShare(tester);
    final gate = app.container.read(acceptGateProvider);
    unawaited(
      gate.open(
        ConnectionRequest(
          requestId: 'r1',
          pairAttemptId: 'att-r1',
          remoteIp: '192.168.1.40',
          clientDeviceId: 'dev-b',
          clientName: 'Phone B',
          clientPlatform: 'android',
          clientFingerprint: 'cd' * 32,
          remembered: false,
          receivedAt: DateTime.now(),
          words: const ['acorn', 'zebra', 'tulip', 'river'],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LinkDialog), findsOneWidget);
    // Something else opens above the prompt (a sheet, the close dialog).
    final context = tester.element(find.byType(LinkDialog));
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) =>
            const AlertDialog(key: ValueKey('above'), content: Text('above')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    // Stop sharing cancels the pending prompt.
    unawaited(
      app.container.read(shareServerControllerProvider.notifier).stopSharing(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LinkDialog), findsNothing);
    expect(find.byKey(const ValueKey('above')), findsOneWidget);
    expect(find.byType(DesktopDevicesScreen), findsOneWidget);
  });

  group('H3 phone', () {
    testWidgets('/connect?send=1 as the only location with no pending send '
        'goes to Swipe instead of popping the last page', (tester) async {
      final app = await pumpApp(tester, overrides: shareOverrides());
      app.container.read(routerProvider).go(AppRoutes.connectSend);
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        app.container
            .read(routerProvider)
            .routerDelegate
            .currentConfiguration
            .uri
            .path,
        AppRoutes.swipe,
      );
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    group('offers', () {
      late Directory staging;
      late OfferService service;

      setUp(() => staging = Directory.systemTemp.createTempSync('kfm_e1'));
      tearDown(() => staging.deleteSync(recursive: true));

      Override offers() => offerServiceProvider.overrideWith((ref) {
        service = OfferService(
          repo: ref.watch(offerRepositoryProvider),
          devices: ref.watch(knownDevicesRepositoryProvider),
          sessions: ClientSessionStore.new,
          uploads: UploadStore(staging: () async => staging),
          freeBytes: (_) async => null,
          downloadsRoot: '/storage/emulated/0/Download',
        );
        ref.onDispose(service.dispose);
        return service;
      });

      testWidgets('an offer ended elsewhere closes its prompt, not the sheet '
          'opened above it', (tester) async {
        final app = await pumpApp(tester, overrides: [offers()]);
        app.container.read(offerServiceProvider);
        await tester.runAsync(
          () => service.create(
            ClientSession(
              sessionId: 's',
              clientFingerprint: 'aa' * 32,
              clientDeviceId: 'd',
              clientName: 'Pixel',
              tokenHash: '',
              createdAt: DateTime.now(),
              lastUsedAt: DateTime.now(),
              purpose: SessionPurpose.send,
            ),
            CreateOfferDto(
              offerId: 'a' * 32,
              files: const [OfferFileDto(name: 'a.jpg', size: 3)],
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(find.byType(OfferDialog), findsOneWidget);
        final context = tester.element(find.byType(OfferDialog));
        unawaited(
          showModalBottomSheet<void>(
            context: context,
            useRootNavigator: true,
            builder: (_) =>
                const SizedBox(key: ValueKey('sheet-above'), height: 100),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.runAsync(
          () => service.cancelBySender('aa' * 32, 'a' * 32),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(OfferDialog), findsNothing);
        expect(find.byKey(const ValueKey('sheet-above')), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
        await tester.pump(const Duration(minutes: 3));
      });
    });

    OfferDto inboxOffer() => const OfferDto(
      id: 'in1',
      status: OfferWireStatus.pending,
      expiresInSeconds: 120,
      senderName: 'KAF-PC',
      files: [OfferFileDto(name: 'cat.mp4', size: 5, id: 'f1')],
    );

    testWidgets('the PC stops while an inbox offer is being looked up: the '
        'inbox empties, nothing is popped', (tester) async {
      final app = await pumpApp(
        tester,
        overrides: [
          ...shareOverrides(),
          remoteConnectionControllerProvider.overrideWith(FakeConnected.new),
        ],
      );
      app.container.read(remoteInboxProvider.notifier)
        ..publish([inboxOffer()])
        // RemoteConnectionController._end in the same tick.
        ..publish(const []);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(OfferDialog), findsNothing);
      dropFakeConnection(app.container);
      await tester.pump(const Duration(minutes: 3));
    });

    testWidgets('the PC stops with its inbox prompt open and a sheet above '
        'it: only the prompt closes', (tester) async {
      final app = await pumpApp(
        tester,
        overrides: [
          ...shareOverrides(),
          remoteConnectionControllerProvider.overrideWith(FakeConnected.new),
        ],
      );
      app.container.read(remoteInboxProvider.notifier).publish([inboxOffer()]);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(OfferDialog), findsOneWidget);
      final context = tester.element(find.byType(OfferDialog));
      unawaited(
        showModalBottomSheet<void>(
          context: context,
          useRootNavigator: true,
          builder: (_) =>
              const SizedBox(key: ValueKey('sheet-above'), height: 100),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      app.container.read(remoteInboxProvider.notifier).publish(const []);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(OfferDialog), findsNothing);
      expect(find.byKey(const ValueKey('sheet-above')), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      dropFakeConnection(app.container);
      await tester.pump(const Duration(minutes: 3));
    });
  });
}
