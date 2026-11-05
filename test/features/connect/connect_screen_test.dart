import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/features/connect/data/camera_access.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/discovery.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/device_identity.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
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
  final List<({String fp, List<ShareAddress> candidates})> knownCalls = [];
  Completer<PairingSuccess> next = Completer();
  final List<SessionPurpose> purposes = [];

  @override
  Future<PairingSuccess> pairKnown({
    required String fingerprint,
    required String name,
    required List<ShareAddress> candidates,
    PairingWaiting? onWaiting,
    PairingCancel? cancel,
    SessionPurpose purpose = SessionPurpose.connect,
  }) {
    purposes.add(purpose);
    knownCalls.add((fp: fingerprint, candidates: candidates));
    onWaiting?.call(name, const ['acorn', 'zebra', 'tulip', 'river']);
    return next.future;
  }

  @override
  Future<PairingSuccess> pairWithCode({
    required Uri base,
    required ShortCode code,
    String? expectedFingerprint,
    PairingWaiting? onWaiting,
    PairingCancel? cancel,
    SessionPurpose purpose = SessionPurpose.connect,
  }) {
    purposes.add(purpose);
    codeCalls.add((base: base, code: code, fp: expectedFingerprint));
    onWaiting?.call('Phone A', const ['acorn', 'zebra', 'tulip', 'river']);
    return next.future;
  }

  @override
  Future<PairingSuccess> pairWithQr(
    PairingOffer offer, {
    PairingWaiting? onWaiting,
    PairingCancel? cancel,
    SessionPurpose purpose = SessionPurpose.connect,
  }) {
    purposes.add(purpose);
    qrCalls.add(offer);
    onWaiting?.call(offer.deviceName, const [
      'acorn',
      'zebra',
      'tulip',
      'river',
    ]);
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
    await tester.scrollUntilVisible(find.text('Connect a device'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connect a device'));
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
    // N3: the same 4 words as the accept dialog on the other device.
    expect(find.text('acorn zebra tulip river'), findsOneWidget);
    expect(
      find.text('Check that both devices show these words'),
      findsOneWidget,
    );

    final http = FakeRemoteHttp()..bearerToken = 't';
    pairing.next.complete(
      PairingSuccess(
        http: http,
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
    expect(find.text('Phone A hasn’t shared any folders yet'), findsOneWidget);

    // N5: a 5 s heartbeat (GET /v1/session) with the token; while no
    // roots are shared each beat also re-reads them.
    http
      ..on('GET', ApiRoutes.session, (_) => const {})
      ..on(
        'GET',
        ApiRoutes.roots,
        (_) => const {
          'roots': [
            {'id': 'r1', 'label': 'Camera', 'readOnly': true},
          ],
        },
      );
    await tester.pump(const Duration(seconds: 5));
    await _settle(tester);
    expect(
      http.calls.map((c) => c.path),
      containsAllInOrder([ApiRoutes.session, ApiRoutes.roots]),
    );
    expect(http.calls.first.token, 't');
    expect(find.text('1 shared folder'), findsOneWidget);

    // N5: the connection outlives the screen.
    await tester.pageBack();
    await _settle(tester);
    await tester.tap(find.text('Connect a device'));
    await _settle(tester);
    expect(find.text('Connected to Phone A'), findsOneWidget);

    // Revoked on the other device: the next heartbeat gets 401.
    http.fail('GET', ApiRoutes.session, ApiErrorCode.unauthorized);
    await tester.pump(const Duration(seconds: 5));
    await _settle(tester);
    expect(find.text('Disconnected from Phone A'), findsOneWidget);
    expect(http.bearerToken, isNull);
    expect(http.closed, isTrue);
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

  PairingSuccess success(FakeRemoteHttp http) => PairingSuccess(
    http: http,
    accepted: const PairAcceptedDto(
      token: 't',
      serverDeviceId: 'srv-a',
      roots: [],
    ),
    peerName: 'Phone A',
    peerFingerprint: 'ab' * 32,
  );

  Future<void> codeToWaiting(WidgetTester tester) async {
    await tester.tap(find.text('Type a code'));
    await _settle(tester);
    discovery.nearby.add([
      NearbyDevice(
        name: 'Phone A',
        address: const (host: '192.168.1.23', port: 4433),
        fingerprintHint: 'ab' * 32,
      ),
    ]);
    await _settle(tester);
    await tester.tap(find.text('Phone A'));
    await _settle(tester);
    await tester.enterText(
      find.byKey(const ValueKey('connect-code-field')),
      'ABCD0119',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('connect-code-submit')));
    await _settle(tester);
  }

  testWidgets('N6: "Remember this device" (on by default) on the waiting '
      'screen saves the peer after accept; Reconnect from Remembered '
      'devices pairs without a code', (tester) async {
    final app = await pump(tester);
    await openConnect(tester);
    await codeToWaiting(tester);
    final box = find.byKey(const ValueKey('connect-remember'));
    expect(find.text('Remember this device'), findsOneWidget);
    expect(tester.widget<CheckboxListTile>(box).value, isTrue);

    final http = FakeRemoteHttp(base: Uri.parse('https://192.168.1.23:4433'))
      ..on(
        'GET',
        ApiRoutes.info,
        (_) => const ServerInfoDto(
          deviceId: 'srv-a',
          name: 'Phone A',
          platform: 'android',
          fingerprint: 'abab',
          protocolVersion: kProtocolVersion,
        ).toJson(),
      )
      ..on('GET', ApiRoutes.session, (_) => const {});
    pairing.next.complete(success(http));
    await _settle(tester);
    expect(find.text('Connected to Phone A'), findsOneWidget);
    await tester.runAsync(
      () => app.container.read(dbWriteQueueProvider).flush(),
    );
    final row = (await tester.runAsync(
      () => app.db.select(app.db.knownDevices).getSingle(),
    ))!;
    expect(row.publicKeyFingerprint, 'ab' * 32);
    expect(row.peerDeviceId, 'srv-a');
    expect(row.platform, 'android');
    expect(row.canShareToUs, isTrue);
    expect(row.lastAddresses, '["192.168.1.23:4433"]');

    // Disconnect, then reconnect from the list: no code.
    await tester.tap(find.text('Disconnect'));
    await _settle(tester);
    await tester.tap(find.text('Remembered devices'));
    await _settle(tester);
    expect(find.text('Phone A'), findsOneWidget);
    expect(find.text('Not sharing right now'), findsOneWidget);
    pairing.next = Completer();
    await tester.tap(find.text('Reconnect'));
    await _settle(tester);
    expect(pairing.knownCalls.single.fp, 'ab' * 32);
    expect(pairing.knownCalls.single.candidates, [
      (host: '192.168.1.23', port: 4433),
    ]);
    // Back on the Connect screen, waiting; no remember box (already).
    expect(find.text('Waiting for Phone A to accept…'), findsOneWidget);
    expect(find.byKey(const ValueKey('connect-remember')), findsNothing);
    final again = FakeRemoteHttp(base: Uri.parse('https://192.168.1.23:4433'))
      ..on('GET', ApiRoutes.session, (_) => const {});
    pairing.next.complete(success(again));
    await _settle(tester);
    expect(find.text('Connected to Phone A'), findsOneWidget);
    await tester.tap(find.text('Disconnect'));
    await _settle(tester);
  });

  testWidgets('N6: unchecking "Remember this device" saves nothing', (
    tester,
  ) async {
    final app = await pump(tester);
    await openConnect(tester);
    await codeToWaiting(tester);
    // E1: the link checkboxes come first.
    expect(find.byKey(const ValueKey('link-let-see')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('connect-remember')));
    await tester.tap(find.byKey(const ValueKey('connect-remember')));
    await _settle(tester);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('connect-remember')),
          )
          .value,
      isFalse,
    );
    pairing.next.complete(
      success(FakeRemoteHttp()..on('GET', ApiRoutes.session, (_) => const {})),
    );
    await _settle(tester);
    expect(find.text('Connected to Phone A'), findsOneWidget);
    // E1: the link details (what this side lets Phone A do).
    expect(find.byKey(const ValueKey('link-details')), findsOneWidget);
    expect(find.text('Phone A can see your files'), findsOneWidget);
    expect(find.byKey(const ValueKey('link-limit-folders')), findsOneWidget);
    await tester.runAsync(
      () => app.container.read(dbWriteQueueProvider).flush(),
    );
    final rows = await tester.runAsync(
      () => app.db.select(app.db.knownDevices).get(),
    );
    expect(rows, isEmpty);
    await tester.tap(find.text('Disconnect'));
    await _settle(tester);
  });

  testWidgets('N6: a failed reconnect shows its message; Try again '
      'reconnects', (tester) async {
    final app = await pump(tester);
    await tester.runAsync(
      () => app.container
          .read(knownDevicesRepositoryProvider)
          .saveAfterPairing(
            PairedPeer(
              fingerprint: 'ab' * 32,
              peerDeviceId: 'srv-a',
              name: 'Phone A',
              platform: 'android',
              addresses: const ['192.168.1.23:4433'],
              canShareToUs: true,
            ),
            temporary: false,
          ),
    );
    await openConnect(tester);
    await tester.tap(find.text('Remembered devices'));
    await _settle(tester);
    await tester.tap(find.text('Reconnect'));
    await _settle(tester);
    pairing.next.completeError(
      const PairingException(PairingFailure.notAllowed),
    );
    await _settle(tester);
    expect(find.text('Not allowed. Scan the QR code again.'), findsOneWidget);
    pairing.next = Completer();
    await tester.tap(find.text('Try again'));
    await _settle(tester);
    expect(pairing.knownCalls, hasLength(2));
    pairing.next.completeError(const PairingException(PairingFailure.offline));
    await _settle(tester);
    expect(
      find.text('Can’t reach Phone A. Open “Share this device” on Phone A.'),
      findsOneWidget,
    );
  });

  testWidgets('every PairingFailure has a message', (tester) async {
    await pump(tester);
    final context = tester.element(find.byType(Scaffold).first);
    final l10n = AppLocalizations.of(context);
    for (final f in PairingFailure.values) {
      expect(pairingFailureMessage(l10n, f, null), isNotEmpty);
    }
  });
}
