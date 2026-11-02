import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/discovery.dart';
import 'package:kfm/features/connect/data/remote_source_provider.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/domain/device_identity.dart';
import 'package:kfm/features/connect/domain/fingerprint_words.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';

import '../../helpers/pump_app.dart';
import 'fake_discovery.dart';

class _FakeIdentity implements DeviceIdentityRepository {
  int resets = 0;

  @override
  Future<DeviceIdentity> loadOrCreate() async => DeviceIdentity(
    deviceId: '00',
    displayName: 'Me',
    platform: 'android',
    certPem: '',
    fingerprint: 'ee$resets',
  );

  @override
  Future<String> privateKeyPem() async => '';

  @override
  Future<Uint8List> rootIdSalt() async => Uint8List(32);

  @override
  Future<Uint8List> sign(Uint8List message) async => Uint8List(0);

  @override
  Future<DeviceIdentity> reset() async {
    resets++;
    return await loadOrCreate();
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late _FakeIdentity identity;
  late FakeDiscovery discovery;
  final fpA = 'aa' * 32;
  final fpB = 'bb' * 32;
  final fpC = 'cc' * 32;

  Future<TestApp> pump(
    WidgetTester tester, {
    List<Override> extra = const [],
  }) async {
    identity = _FakeIdentity();
    discovery = FakeDiscovery();
    final app = await pumpApp(
      tester,
      overrides: [
        secretStoreProvider.overrideWithValue(InMemorySecretStore()),
        deviceIdentityRepositoryProvider.overrideWithValue(identity),
        shareDiscoveryProvider.overrideWithValue(discovery),
        ...extra,
      ],
    );
    final repo = app.container.read(knownDevicesRepositoryProvider);
    await tester.runAsync(() async {
      // A PC that shared with us, a phone that connected to us, and a
      // second "Phone B" (reinstalled: another key).
      await repo.saveAfterPairing(
        PairedPeer(
          fingerprint: fpA,
          peerDeviceId: 'pc',
          name: 'Kaf PC',
          platform: 'windows',
          addresses: const ['192.168.1.10:4433'],
          canShareToUs: true,
        ),
        temporary: false,
      );
      await repo.saveAfterPairing(
        PairedPeer(
          fingerprint: fpB,
          peerDeviceId: 'b',
          name: 'Phone B',
          platform: 'android',
        ),
        temporary: false,
      );
      await repo.saveAfterPairing(
        PairedPeer(
          fingerprint: fpC,
          peerDeviceId: 'b',
          name: 'Phone B',
          platform: 'android',
        ),
        temporary: false,
      );
      // Hidden: only kept to resume a transfer.
      await repo.saveAfterPairing(
        PairedPeer(
          fingerprint: 'dd' * 32,
          peerDeviceId: 'd',
          name: 'Temp',
          platform: 'android',
        ),
        temporary: true,
      );
    });
    return app;
  }

  Future<void> openList(WidgetTester tester) async {
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Remembered devices'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remembered devices'));
    await _settle(tester);
  }

  Future<List<String>> fingerprints(WidgetTester tester, TestApp app) async {
    await tester.runAsync(
      () => app.container.read(dbWriteQueueProvider).flush(),
    );
    final rows = await tester.runAsync(
      () => app.db.select(app.db.knownDevices).get(),
    );
    return [for (final r in rows!) r.publicKeyFingerprint];
  }

  testWidgets('Settings → Remembered devices lists them: online dot from '
      'mDNS, Reconnect vs "Share from this device", 4 words when names '
      'collide, temporary rows hidden', (tester) async {
    await pump(tester);
    await openList(tester);
    expect(find.text('Kaf PC'), findsOneWidget);
    expect(find.text('Phone B'), findsNWidgets(2));
    expect(find.text('Temp'), findsNothing);
    expect(find.text('Not sharing right now'), findsOneWidget);
    expect(find.text('Reconnect'), findsOneWidget);
    expect(find.text('Share from this device'), findsNWidgets(2));
    final words = fingerprintWords(fpB, fpB).join(' ');
    expect(find.text('Connects to this device · $words'), findsOneWidget);

    discovery.nearby.add([
      NearbyDevice(
        name: 'Kaf PC',
        address: const (host: '192.168.1.10', port: 4433),
        fingerprintHint: fpA,
      ),
    ]);
    await _settle(tester);
    expect(find.text('Sharing now'), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsOneWidget);
  });

  testWidgets('a device we are connected to shows "Connected" and Browse, '
      'even when mDNS never sees it', (tester) async {
    await pump(
      tester,
      extra: [remotePeerConnectedProvider(fpA).overrideWithValue(true)],
    );
    await openList(tester);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Not sharing right now'), findsNothing);
    expect(find.text('Browse Kaf PC'), findsOneWidget);
    expect(find.text('Reconnect'), findsNothing);
    expect(find.byIcon(Icons.circle), findsOneWidget);
  });

  testWidgets('"Always allow" switch is stored per device', (tester) async {
    final app = await pump(tester);
    await openList(tester);
    final sw = find.byKey(ValueKey('remembered-always-$fpB'));
    await tester.scrollUntilVisible(sw, 200);
    expect(tester.widget<SwitchListTile>(sw).value, isFalse);
    await tester.tap(sw);
    await _settle(tester);
    await tester.runAsync(
      () => app.container.read(dbWriteQueueProvider).flush(),
    );
    await _settle(tester);
    expect(tester.widget<SwitchListTile>(sw).value, isTrue);
    final b = await tester.runAsync(
      () =>
          app.container.read(knownDevicesRepositoryProvider).byFingerprint(fpB),
    );
    expect(b!.autoAccept, isTrue);
  });

  testWidgets('Remove (confirmed) deletes the row, ends its live session '
      'and its folders', (tester) async {
    final app = await pump(tester);
    final sessions = app.container.read(clientSessionStoreProvider);
    final issued = sessions.issue(
      clientFingerprint: fpB,
      clientDeviceId: 'b',
      clientName: 'Phone B',
    );
    app.container
        .read(shareScopeStoreProvider)
        .set(
          fpB,
          const ShareScope([
            SharedRoot(id: 'r', path: '/x', label: 'X', readOnly: true),
          ]),
        );
    await openList(tester);
    final remove = find.byKey(ValueKey('remembered-remove-$fpB'));
    await tester.scrollUntilVisible(remove, 200);
    await tester.tap(remove);
    await _settle(tester);
    expect(find.text('Remove Phone B?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('remembered-remove-confirm')));
    await tester.runAsync(
      () => app.container.read(dbWriteQueueProvider).flush(),
    );
    await _settle(tester);
    expect(await fingerprints(tester, app), isNot(contains(fpB)));
    expect(sessions.verify(issued.token), isNull);
    expect(
      app.container.read(shareScopeStoreProvider).scopeOf(fpB).isEmpty,
      isTrue,
    );
    expect(find.text('Phone B'), findsOneWidget); // the other key's row
  });

  testWidgets('Remove all forgets every device (temporary ones too)', (
    tester,
  ) async {
    final app = await pump(tester);
    await openList(tester);
    await tester.tap(find.byKey(const ValueKey('remembered-menu')));
    await _settle(tester);
    await tester.tap(find.text('Remove all'));
    await _settle(tester);
    await tester.tap(
      find.byKey(const ValueKey('remembered-remove-all-confirm')),
    );
    await tester.runAsync(
      () => app.container.read(dbWriteQueueProvider).flush(),
    );
    await _settle(tester);
    expect(await fingerprints(tester, app), isEmpty);
    expect(find.textContaining('No remembered devices yet'), findsOneWidget);
  });

  testWidgets("Settings → Reset this device's identity: new identity, every "
      'device forgotten', (tester) async {
    final app = await pump(tester);
    final before = await tester.runAsync(
      () => app.container.read(deviceIdentityProvider.future),
    );
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Reset this device’s identity'),
      200,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset this device’s identity'));
    await _settle(tester);
    expect(find.text('Reset this device’s identity?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reset-identity-confirm')));
    await tester.runAsync(
      () => app.container.read(dbWriteQueueProvider).flush(),
    );
    await _settle(tester);
    expect(identity.resets, 1);
    expect(await fingerprints(tester, app), isEmpty);
    final after = await tester.runAsync(
      () => app.container.read(deviceIdentityProvider.future),
    );
    expect(after!.fingerprint, isNot(before!.fingerprint));
    expect(
      find.text('New identity created. Other devices must scan again.'),
      findsOneWidget,
    );
  });
}
