import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/platform/screen_awake.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/device_identity.dart';
import 'package:kfm/features/connect/ui/share_server_controller.dart';
import 'package:shelf/shelf.dart';

import '../../helpers/pump_app.dart';

class _FakeAwake implements ScreenAwake {
  final List<bool> calls = [];

  @override
  Future<void> keepOn({required bool on}) async => calls.add(on);
}

class _FakeServer extends ShareServer {
  new(DeviceIdentityRepository identity)
    : super(identity, (_) => (_) => Response.ok(''));

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

  Future<TestApp> pump(WidgetTester tester) {
    awake = _FakeAwake();
    final identity = _FakeIdentity();
    server = _FakeServer(identity);
    return pumpApp(
      tester,
      overrides: [
        screenAwakeProvider.overrideWithValue(awake),
        secretStoreProvider.overrideWithValue(InMemorySecretStore()),
        deviceIdentityRepositoryProvider.overrideWithValue(identity),
        shareServerProvider.overrideWithValue(server),
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
    // Debug build: address + port.
    expect(find.text('192.168.1.23:45123'), findsOneWidget);
    expect(server.starts, 1);
    expect(awake.calls, [true]);
    expect(
      app.container.read(shareServerControllerProvider).status,
      ShareServerStatus.running,
    );

    // The tab bar is covered (top-level route).
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Stop sharing'));
    await tester.pumpAndSettle();
    expect(find.text('Sharing'), findsNothing);
    expect(server.stops, 1);
    expect(awake.calls, [true, false]);
    expect(
      app.container.read(shareServerControllerProvider).status,
      ShareServerStatus.stopped,
    );
    await tester.pumpAndSettle();
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
        shareServerProvider.overrideWithValue(
          _ThrowingServer(_FakeIdentity()),
        ),
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
    : super(identity, (_) => (_) => Response.ok(''));

  @override
  Future<ShareServerState> start() async =>
      throw const SocketException('bind failed');

  @override
  Future<void> stop() async {}
}
