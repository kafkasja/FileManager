import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/platform/screen_awake.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/pairing_secret_store.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/device_identity.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
import 'package:kfm/features/connect/ui/accept_dialog.dart';
import 'package:kfm/features/connect/ui/share_server_controller.dart';
import 'package:shelf/shelf.dart';

import '../../helpers/pump_app.dart';
import 'fake_discovery.dart';

class _FakeAwake implements ScreenAwake {
  final List<bool> calls = [];

  @override
  Future<void> keepOn({required bool on}) async => calls.add(on);
}

class _FakeServer extends ShareServer {
  new(DeviceIdentityRepository identity)
    : super(
        identity,
        (_) =>
            (_) => Response.ok(''),
      );

  ShareServerState next = ShareServerState(
    status: ShareServerStatus.running,
    addresses: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
    port: 45123,
    fingerprint: 'ab' * 32,
  );
  int starts = 0;
  int stops = 0;
  bool _running = false;

  @override
  bool get isRunning => _running;

  @override
  Future<ShareServerState> start() async {
    starts++;
    _running = next.status == ShareServerStatus.running;
    return next;
  }

  @override
  Future<void> stop() async {
    if (_running) stops++;
    _running = false;
  }
}

class _FakeIdentity implements DeviceIdentityRepository {
  @override
  Future<DeviceIdentity> loadOrCreate() async => const DeviceIdentity(
    deviceId: '00',
    displayName: 'Kaf phone',
    platform: 'android',
    certPem: '',
    fingerprint: 'ab',
  );

  @override
  Future<String> privateKeyPem() async => '';

  @override
  Future<Uint8List> rootIdSalt() async => Uint8List(32);

  @override
  Future<Uint8List> sign(Uint8List message) async => Uint8List(0);

  @override
  Future<DeviceIdentity> reset() => loadOrCreate();
}

void main() {
  late _FakeAwake awake;
  late _FakeServer server;
  late FakeDiscovery discovery;
  var now = DateTime(2026, 11);

  Future<TestApp> pump(WidgetTester tester) {
    awake = _FakeAwake();
    final identity = _FakeIdentity();
    server = _FakeServer(identity);
    discovery = FakeDiscovery();
    return pumpApp(
      tester,
      overrides: [
        screenAwakeProvider.overrideWithValue(awake),
        secretStoreProvider.overrideWithValue(InMemorySecretStore()),
        deviceIdentityRepositoryProvider.overrideWithValue(identity),
        shareServerProvider.overrideWithValue(server),
        shareDiscoveryProvider.overrideWithValue(discovery),
        pairingSecretStoreProvider.overrideWithValue(
          PairingSecretStore(autoRefresh: false, clock: () => now),
        ),
      ],
    );
  }

  Future<void> openShare(WidgetTester tester) async {
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Share this device'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share this device'));
    await tester.pumpAndSettle();
  }

  testWidgets('Settings → Connect a device → Share this device: sharing runs '
      'while the screen is open, screen stays on', (tester) async {
    final app = await pump(tester);
    await openShare(tester);

    expect(find.text('Sharing'), findsOneWidget);
    expect(find.textContaining('Kaf phone'), findsOneWidget);
    // N2: QR, typed code, address for manual entry, countdown.
    expect(find.byKey(const ValueKey('share-qr')), findsOneWidget);
    expect(find.text('No camera? Type this code'), findsOneWidget);
    expect(
      find.textContaining(
        RegExp(r'^[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$'),
      ),
      findsOneWidget,
    );
    expect(find.text('Address: 192.168.1.23:45123'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'^New code in [45]:[0-5][0-9]$')),
      findsNWidgets(2),
    );
    // mDNS advert with TXT {v, id, name, fp}.
    expect(discovery.adverts.single.port, 45123);
    expect(discovery.adverts.single.txt, {
      'v': '1',
      'id': '00',
      'name': 'Kaf phone',
      'fp': 'ab',
    });
    // Debug build: address + port.
    await tester.scrollUntilVisible(
      find.text('192.168.1.23:45123'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('192.168.1.23:45123'), findsOneWidget);
    expect(server.starts, 1);
    expect(awake.calls, [true]);
    expect(
      app.container.read(shareServerControllerProvider).status,
      ShareServerStatus.running,
    );

    // The tab bar is covered (top-level route).
    expect(find.byType(NavigationBar), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Stop sharing'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Stop sharing'));
    await tester.pumpAndSettle();
    expect(find.text('Sharing'), findsNothing);
    expect(server.stops, 1);
    expect(discovery.stops, greaterThanOrEqualTo(1));
    expect(app.container.read(pairingSecretStoreProvider).isActive, isFalse);
    expect(awake.calls, [true, false]);
    expect(
      app.container.read(shareServerControllerProvider).status,
      ShareServerStatus.stopped,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('code locks show "New code generated", a cooldown, and after '
      'the 3rd lock typed codes are off while the QR stays', (tester) async {
    final app = await pump(tester);
    await openShare(tester);
    final store = app.container.read(pairingSecretStoreProvider);
    final firstCode = (store.state as SecretActive).code;

    for (var lock = 1; lock <= 3; lock++) {
      for (var i = 0; i < 5; i++) {
        expect(store.beginCodeAttempt('192.168.1.40'), isA<CodeStartGranted>());
      }
      await tester.pump();
      await tester.pump();
      expect(
        find.text('Too many wrong attempts. New code generated'),
        findsOneWidget,
      );
      if (lock < 3) {
        expect(
          find.textContaining('Typed codes work again in'),
          findsOneWidget,
        );
      }
      now = now.add(const Duration(seconds: 31));
      store.refresh();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }
    expect((store.state as SecretActive).code, isNot(firstCode));
    expect(find.byKey(const ValueKey('share-typed-off')), findsOneWidget);
    expect(find.byKey(const ValueKey('share-code')), findsNothing);
    expect(find.byKey(const ValueKey('share-qr')), findsOneWidget);
  });

  testWidgets('an mDNS failure shows a hint; sharing keeps running', (
    tester,
  ) async {
    final app = await pump(tester);
    discovery.advertiseError = Exception('mdns blocked');
    await openShare(tester);
    expect(
      app.container.read(shareServerControllerProvider).status,
      ShareServerStatus.running,
    );
    await tester.scrollUntilVisible(
      find.textContaining('Nearby devices can’t list'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      find.text(
        'Nearby devices can’t list this one. They can enter the address '
        'instead.',
      ),
      findsOneWidget,
    );
  });

  ConnectionRequest request(String id, {bool remembered = false}) =>
      ConnectionRequest(
        requestId: id,
        pairAttemptId: 'att-$id',
        remoteIp: '192.168.1.40',
        clientDeviceId: 'dev-b',
        clientName: 'Phone B',
        clientPlatform: 'android',
        clientFingerprint: 'cd' * 32,
        remembered: remembered,
        receivedAt: DateTime.now(),
        words: const ['acorn', 'zebra', 'tulip', 'river'],
      );

  testWidgets('N3: accept dialog with name, platform and 4 words; Decline '
      'has focus; Accept decides', (tester) async {
    final app = await pump(tester);
    await openShare(tester);
    final gate = app.container.read(acceptGateProvider);
    final decision = gate.open(request('r1'))!;
    await tester.pumpAndSettle();
    expect(find.text('Phone B wants to connect'), findsOneWidget);
    expect(find.text('Device type: android'), findsOneWidget);
    expect(find.text('acorn zebra tulip river'), findsOneWidget);
    expect(
      find.text('Check that both devices show these words'),
      findsOneWidget,
    );
    final decline = tester.widget<TextButton>(
      find.byKey(const ValueKey('accept-decline')),
    );
    expect(decline.autofocus, isTrue);
    expect(app.container.read(pendingRequestProvider)?.requestId, 'r1');
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(await decision, ConnectionDecision.accepted);
    expect(find.byType(AcceptDialog), findsNothing);
    expect(app.container.read(pendingRequestProvider), isNull);

    final d2 = gate.open(request('r2', remembered: true))!;
    await tester.pumpAndSettle();
    expect(find.text('Phone B (remembered) wants to connect'), findsOneWidget);
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(await d2, ConnectionDecision.declined);
  });

  testWidgets('N3: the client cancels → dialog closes with "Request '
      'cancelled"; no answer for 60 s → closes too', (tester) async {
    final app = await pump(tester);
    await openShare(tester);
    final gate = app.container.read(acceptGateProvider);
    final cancelled = gate.open(request('r1'))!;
    await tester.pumpAndSettle();
    expect(gate.cancel('att-r1', '192.168.1.99'), isFalse);
    expect(gate.cancel('att-r1', '192.168.1.40'), isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(AcceptDialog), findsNothing);
    expect(find.text('Request cancelled'), findsOneWidget);
    expect(await cancelled, ConnectionDecision.cancelled);

    final timedOut = gate.open(request('r2'))!;
    await tester.pumpAndSettle();
    expect(find.byType(AcceptDialog), findsOneWidget);
    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();
    expect(await timedOut, ConnectionDecision.timedOut);
    expect(find.byType(AcceptDialog), findsNothing);
    expect(
      find.text('No answer in time. The request was declined.'),
      findsOneWidget,
    );
  });

  testWidgets('N3: connected clients are listed with Disconnect; stopping '
      'sharing ends sessions and a pending prompt', (tester) async {
    final app = await pump(tester);
    await openShare(tester);
    final sessions = app.container.read(clientSessionStoreProvider);
    final issued = sessions.issue(
      clientFingerprint: 'cd' * 32,
      clientDeviceId: 'dev-b',
      clientName: 'Phone B',
    );
    await tester.pumpAndSettle();
    expect(find.text('Connected: Phone B'), findsOneWidget);
    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();
    expect(find.text('Connected: Phone B'), findsNothing);
    expect(sessions.verify(issued.token), isNull);

    final again = sessions.issue(
      clientFingerprint: 'cd' * 32,
      clientDeviceId: 'dev-b',
      clientName: 'Phone B',
    );
    await tester.pumpAndSettle();
    expect(find.text('Connected: Phone B'), findsOneWidget);
    await app.container
        .read(shareServerControllerProvider.notifier)
        .stopSharing();
    await tester.pumpAndSettle();
    expect(sessions.verify(again.token), isNull);
    expect(find.text('Connected: Phone B'), findsNothing);
  });

  testWidgets('Back also stops sharing', (tester) async {
    await pump(tester);
    await openShare(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(server.stops, 1);
    expect(awake.calls.last, isFalse);
  });

  testWidgets('no Wi-Fi: error with retry', (tester) async {
    await pump(tester);
    server.next = const ShareServerState(
      status: ShareServerStatus.error,
      error: NoLocalNetworkException(),
    );
    await openShare(tester);
    expect(find.text('Connect to Wi-Fi or turn on hotspot'), findsOneWidget);
    server.next = ShareServerState(
      status: ShareServerStatus.running,
      addresses: [LocalAddress(InternetAddress('10.0.0.5'), 24, 'wlan0')],
      port: 1,
      fingerprint: 'cd',
    );
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Sharing'), findsOneWidget);
    expect(server.starts, 2);
    await tester.pageBack();
    await tester.pumpAndSettle();
  });

  test('a start failure lands in the error state (rule 8)', () async {
    final container = ProviderContainer(
      overrides: [
        shareServerProvider.overrideWithValue(_ThrowingServer(_FakeIdentity())),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(shareServerControllerProvider.notifier);
    await controller.startSharing();
    final state = container.read(shareServerControllerProvider);
    expect(state.status, ShareServerStatus.error);
    expect(state.error, isA<SocketException>());
    await controller.stopSharing();
    expect(
      container.read(shareServerControllerProvider),
      same(ShareServerState.stopped),
    );
  });

  test('a stop while starting shuts the late server down', () async {
    final server = _FakeServer(_FakeIdentity());
    final container = ProviderContainer(
      overrides: [shareServerProvider.overrideWithValue(server)],
    );
    addTearDown(container.dispose);
    final controller = container.read(shareServerControllerProvider.notifier);
    final starting = controller.startSharing();
    await controller.stopSharing();
    await starting;
    expect(server.isRunning, isFalse);
    expect(
      container.read(shareServerControllerProvider).status,
      ShareServerStatus.stopped,
    );
  });
}

class _ThrowingServer extends ShareServer {
  new(DeviceIdentityRepository identity)
    : super(
        identity,
        (_) =>
            (_) => Response.ok(''),
      );

  @override
  Future<ShareServerState> start() async =>
      throw const SocketException('bind failed');

  @override
  Future<void> stop() async {}
}
