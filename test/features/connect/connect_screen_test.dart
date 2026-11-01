import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/camera_access.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/discovery.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/domain/device_identity.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/ui/connect_controller.dart';
import 'package:kfm/features/connect/ui/connect_screen.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../../helpers/pump_app.dart';
import 'fake_discovery.dart';
import 'fake_remote_http.dart';

class _FakeCamera implements CameraAccess {
  new(this.result);

  CameraPermission result;
  int requests = 0;

  @override
  bool get canScan => true;

  @override
  Future<CameraPermission> request() async {
    requests++;
    return result;
  }

  @override
  Future<void> openSettings() async {}
}

class _FakeIdentity implements DeviceIdentityRepository {
  @override
  Future<DeviceIdentity> loadOrCreate() async => const DeviceIdentity(
    deviceId: '00',
    displayName: 'Me',
    platform: 'android',
    certPem: '',
    fingerprint: 'ee',
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

/// Records calls; each pairing completes when the test says so.
class _FakePairingClient extends PairingClient {
  new() : super(identity: _FakeIdentity());

  final List<({Uri base, ShortCode code, String? fp})> codeCalls = [];
  final List<PairingOffer> qrCalls = [];
  Completer<PairingSuccess> next = Completer();

  @override
  Future<PairingSuccess> pairWithCode({
    required Uri base,
    required ShortCode code,
    String? expectedFingerprint,
    void Function(String peerName)? onWaiting,
    PairingCancel? cancel,
  }) {
    codeCalls.add((base: base, code: code, fp: expectedFingerprint));
    onWaiting?.call('Phone A');
    return next.future;
  }

  @override
  Future<PairingSuccess> pairWithQr(
    PairingOffer offer, {
    void Function(String peerName)? onWaiting,
    PairingCancel? cancel,
  }) {
    qrCalls.add(offer);
    onWaiting?.call(offer.deviceName);
    return next.future;
  }
}

final String _validUri = PairingOffer(
  addresses: const [(host: '192.168.1.23', port: 4433)],
  serverFingerprint: 'ab' * 32,
  secret: Uint8List(32),
  deviceName: 'Phone A',
).toUri();

/// The nearby list and the waiting state animate forever (progress).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late _FakeCamera camera;
  late _FakePairingClient pairing;
  late FakeDiscovery discovery;

  Future<TestApp> pump(
    WidgetTester tester, {
    CameraPermission camResult = CameraPermission.granted,
  }) {
    camera = _FakeCamera(camResult);
    pairing = _FakePairingClient();
    discovery = FakeDiscovery();
    return pumpApp(
      tester,
      overrides: [
        secretStoreProvider.overrideWithValue(InMemorySecretStore()),
        deviceIdentityRepositoryProvider.overrideWithValue(_FakeIdentity()),
        cameraAccessProvider.overrideWithValue(camera),
        pairingClientProvider.overrideWithValue(pairing),
        shareDiscoveryProvider.overrideWithValue(discovery),
      ],
    );
  }

  Future<void> openConnect(WidgetTester tester) async {
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Connect to a device'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connect to a device'));
    await tester.pumpAndSettle();
  }

  testWidgets('Settings → Connect to a device: Scan QR and Type code; the '
      'camera is not asked for until Scan is tapped', (tester) async {
    await pump(tester);
    await openConnect(tester);
    expect(find.text('Scan QR code'), findsOneWidget);
    expect(find.text('Type a code'), findsOneWidget);
    expect(camera.requests, 0);
  });

  testWidgets('camera denied → explanation + Type code', (tester) async {
    await pump(tester, camResult: CameraPermission.denied);
    await openConnect(tester);
    await tester.tap(find.text('Scan QR code'));
    await _settle(tester);
    expect(camera.requests, 1);
    expect(
      find.text(
        'KFM needs the camera to scan the code. You can type the code '
        'instead.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('connect-denied-type')));
    await _settle(tester);
    expect(find.text('Nearby devices'), findsOneWidget);
  });

  testWidgets('type code: nearby device → normalised XXXX-XXXX field → '
      'waiting → connected', (tester) async {
    await pump(tester);
    await openConnect(tester);
    await tester.tap(find.text('Type a code'));
    await _settle(tester);
    expect(
      find.text('Looking for devices sharing on this Wi-Fi…'),
      findsOneWidget,
    );

    discovery.nearby.add([
      NearbyDevice(
        name: 'Phone A',
        address: const (host: '192.168.1.23', port: 4433),
        fingerprintHint: 'ab' * 32,
      ),
      // This device itself is hidden from the list.
      const NearbyDevice(
        name: 'Me',
        address: (host: '192.168.1.40', port: 1),
        fingerprintHint: 'ee',
      ),
    ]);
    await _settle(tester);
    expect(find.text('Me'), findsNothing);
    await tester.tap(find.text('Phone A'));
    await _settle(tester);
    expect(find.text('Type the code shown on Phone A'), findsOneWidget);

    final field = find.byKey(const ValueKey('connect-code-field'));
    await tester.enterText(field, 'abcdo1l9');
    await tester.pump();
    expect(find.text('ABCD-0119'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('connect-code-submit')));
    await _settle(tester);
    expect(pairing.codeCalls.single.code.value, 'ABCD0119');
    expect(pairing.codeCalls.single.fp, 'ab' * 32);
    expect(
      pairing.codeCalls.single.base,
      Uri.parse('https://192.168.1.23:4433'),
    );
    expect(find.text('Waiting for Phone A to accept…'), findsOneWidget);

    pairing.next.complete(
      PairingSuccess(
        http: FakeRemoteHttp(),
        accepted: const PairAcceptedDto(
          token: 't',
          serverDeviceId: 's',
          roots: [],
        ),
        peerName: 'Phone A',
        peerFingerprint: 'ab' * 32,
      ),
    );
    await _settle(tester);
    expect(find.text('Connected to Phone A'), findsOneWidget);
  });

  testWidgets('enter address: invalid input is refused, a valid one opens '
      'the code field; a failure shows its message with Try again', (
    tester,
  ) async {
    await pump(tester);
    await openConnect(tester);
    await tester.tap(find.text('Type a code'));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('connect-enter-address')));
    await _settle(tester);
    final field = find.byKey(const ValueKey('connect-address-field'));
    await tester.enterText(field, '192.168.1');
    await tester.tap(find.byKey(const ValueKey('connect-address-next')));
    await _settle(tester);
    expect(find.text('Enter it like 192.168.1.23:48211'), findsOneWidget);
    await tester.enterText(field, '192.168.1.23:48211');
    await tester.tap(find.byKey(const ValueKey('connect-address-next')));
    await _settle(tester);
    expect(
      find.text('Type the code shown on the other device'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('connect-code-field')),
      '7K3M9QPZ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('connect-code-submit')));
    await _settle(tester);
    pairing.next.completeError(
      const PairingException(PairingFailure.wrongCode),
    );
    await _settle(tester);
    expect(
      find.text(
        'Wrong code, or this isn’t Phone A. Check the code and try again.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Try again'));
    await _settle(tester);
    expect(find.byKey(const ValueKey('connect-code-field')), findsOneWidget);
  });

  test(
    'scanned values: not KFM, v=2, then a valid QR starts pairing',
    () async {
      final camera = _FakeCamera(CameraPermission.granted);
      final pairing = _FakePairingClient();
      final container = ProviderContainer(
        overrides: [
          cameraAccessProvider.overrideWithValue(camera),
          pairingClientProvider.overrideWithValue(pairing),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(connectControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final c = container.read(connectControllerProvider.notifier);
      expect(c.onScanned(_validUri), ScanOutcome.ignored); // not scanning yet
      await c.scan();
      expect(c.onScanned('https://example.com'), ScanOutcome.notKfm);
      expect(c.onScanned('WIFI:S:x;;'), ScanOutcome.notKfm);
      expect(
        c.onScanned(_validUri.replaceFirst('v=1', 'v=2')),
        ScanOutcome.unsupportedVersion,
      );
      expect(container.read(connectControllerProvider), isA<ConnectScanning>());
      expect(c.onScanned(_validUri), ScanOutcome.started);
      await Future<void>.delayed(Duration.zero);
      expect(pairing.qrCalls.single.deviceName, 'Phone A');
      expect(
        container.read(connectControllerProvider),
        isA<ConnectWaiting>().having((s) => s.name, 'name', 'Phone A'),
      );
      c.cancel();
      expect(container.read(connectControllerProvider), isA<ConnectChoose>());
    },
  );

  testWidgets('every PairingFailure has a message', (tester) async {
    await pump(tester);
    final context = tester.element(find.byType(Scaffold).first);
    final l10n = AppLocalizations.of(context);
    for (final f in PairingFailure.values) {
      expect(pairingFailureMessage(l10n, f, null), isNotEmpty);
    }
  });
}
