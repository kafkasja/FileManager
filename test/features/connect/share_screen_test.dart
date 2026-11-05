import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/platform/screen_awake.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/pairing_secret_store.dart';
import 'package:kfm/features/connect/data/path_guard.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/share_background.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/data/shared_folder_fs.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/device_identity.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:kfm/features/connect/ui/accept_dialog.dart';
import 'package:kfm/features/connect/ui/share_server_controller.dart';
import 'package:kfm/features/connect/ui/shared_folders_picker.dart';
import 'package:shelf/shelf.dart';

import '../../helpers/pump_app.dart';
import 'fake_discovery.dart';
import 'share_fakes.dart';

/// E1: the share screen fits without scrolling; notes that don't fit sit
/// behind the (i) button. Opens it when [note] isn't shown, checks [note]
/// and closes the dialog again.
Future<void> expectNote(WidgetTester tester, Finder note) async {
  if (note.evaluate().isEmpty) {
    await tester.tap(find.byKey(const ValueKey('share-info')));
    await tester.pumpAndSettle();
  }
  expect(note, findsOneWidget);
  final dialog = find.byKey(const ValueKey('share-info-dialog'));
  if (dialog.evaluate().isNotEmpty) {
    await tester.tap(
      find.descendant(of: dialog, matching: find.byType(TextButton)),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  late FakeAwake awake;
  late FakeServer server;
  late FakeDiscovery discovery;
  var now = DateTime(2026, 11);

  Future<TestApp> pump(
    WidgetTester tester, {
    bool stopsInBackground = false,
    ShareBackground background = const NoShareBackground(),
    ClientSessionStore? sessions,
  }) {
    awake = FakeAwake();
    final identity = FakeIdentity();
    server = FakeServer(identity);
    discovery = FakeDiscovery();
    return pumpApp(
      tester,
      overrides: [
        screenAwakeProvider.overrideWithValue(awake),
        secretStoreProvider.overrideWithValue(InMemorySecretStore()),
        deviceIdentityRepositoryProvider.overrideWithValue(identity),
        shareServerProvider.overrideWithValue(server),
        shareDiscoveryProvider.overrideWithValue(discovery),
        sharedFolderFsProvider.overrideWithValue(FakeFolderFs()),
        lifecycleStopsSharingProvider.overrideWithValue(stopsInBackground),
        shareBackgroundProvider.overrideWithValue(background),
        if (sessions != null)
          clientSessionStoreProvider.overrideWithValue(sessions),
        pathGuardProvider.overrideWithValue(
          PathGuard(resolver: (p) async => p),
        ),
        pairingSecretStoreProvider.overrideWithValue(
          PairingSecretStore(autoRefresh: false, clock: () => now),
        ),
      ],
    );
  }

  // E2: Settings has one "Connect a device" row (E1 decides where sharing
  // starts); the share screen is opened by its route from Settings.
  Future<void> openShare(WidgetTester tester) async {
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    unawaited(
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
          .read(routerProvider)
          .push(AppRoutes.connectShare),
    );
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
    await expectNote(tester, find.text('192.168.1.23:45123'));
    expect(server.starts, 1);
    expect(awake.calls, [true]);
    expect(
      app.container.read(shareServerControllerProvider).status,
      ShareServerStatus.running,
    );

    // The tab bar is covered (top-level route).
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byKey(const ValueKey('share-stop')));
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

    // N4: the folder picker opens after Accept; nothing is pre-checked.
    expect(find.byType(SharedFoldersPicker), findsOneWidget);
    expect(find.text('Folders Phone B can see'), findsOneWidget);
    const camera = '/storage/emulated/0/DCIM';
    final cameraBox = find.byKey(const ValueKey('shared-folder-$camera'));
    expect(tester.widget<CheckboxListTile>(cameraBox).value, isFalse);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('Pictures'), findsNothing); // doesn't exist
    await tester.tap(cameraBox);
    await tester.pumpAndSettle();
    final write = find.byKey(const ValueKey('shared-folder-write-$camera'));
    expect(tester.widget<SwitchListTile>(write).value, isFalse);
    await tester.tap(find.byKey(const ValueKey('shared-folders-done')));
    await tester.pumpAndSettle();
    expect(find.byType(SharedFoldersPicker), findsNothing);
    final scope = app.container
        .read(shareScopeStoreProvider)
        .scopeOf('cd' * 32);
    expect(scope.roots.single.path, camera);
    expect(scope.roots.single.label, 'Camera');
    expect(scope.roots.single.readOnly, isTrue);
    expect(scope.roots.single.id, PathGuard.rootId(Uint8List(32), camera));

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
        shareServerProvider.overrideWithValue(_ThrowingServer(FakeIdentity())),
        appDatabaseProvider.overrideWithValue(
          AppDatabase(NativeDatabase.memory()),
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

  testWidgets('N5: on a phone, going to the background stops sharing; '
      'inactive keeps it; resume does not restart', (tester) async {
    await pump(tester, stopsInBackground: true);
    await openShare(tester);
    expect(server.isRunning, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(server.isRunning, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pumpAndSettle();
    expect(server.isRunning, isFalse);
    // No frames while hidden: check the screen after coming back.
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(server.isRunning, isFalse);
    expect(find.text('Sharing stopped'), findsOneWidget);
  });

  testWidgets('N5: on desktop the background keeps sharing (hint says so)', (
    tester,
  ) async {
    await pump(tester);
    await openShare(tester);
    final hint = find.text('Sharing stops when you leave this screen.');
    await expectNote(tester, hint);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pumpAndSettle();
    expect(server.isRunning, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  });

  testWidgets('N5b: Android keeps sharing in the background behind a '
      'notification naming the connected devices; its Stop ends sharing', (
    tester,
  ) async {
    final bg = FakeBackground();
    final app = await pump(tester, stopsInBackground: true, background: bg);
    await openShare(tester);
    expect(bg.shown.single.title, 'Sharing this device');
    expect(bg.shown.single.stop, 'Stop');
    final hint = find.text(
      'Sharing keeps running when you leave the app. Stop it here or from '
      'the notification.',
    );
    await expectNote(tester, hint);

    final sessions = app.container.read(clientSessionStoreProvider)
      ..issue(
        clientFingerprint: 'cd' * 32,
        clientDeviceId: 'dev-b',
        clientName: 'Phone B',
      );
    await tester.pumpAndSettle();
    expect(bg.shown.last.title, 'Sharing with Phone B');
    sessions.issue(
      clientFingerprint: 'ef' * 32,
      clientDeviceId: 'dev-c',
      clientName: 'PC',
    );
    await tester.pumpAndSettle();
    expect(bg.shown.last.title, 'Sharing with Phone B and 1 more');

    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(server.isRunning, isTrue);

    bg.requests.add(null);
    await tester.pump();
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(server.isRunning, isFalse);
    expect(bg.stops, 1);
    expect(sessions.sessions, isEmpty);
    expect(find.text('Sharing stopped'), findsOneWidget);
  });

  testWidgets('Q8: Back while a transfer runs asks first; Keep sharing '
      'stays, Stop sharing stops', (tester) async {
    final app = await pump(tester);
    await openShare(tester);
    final sessions = app.container.read(clientSessionStoreProvider);
    final s = sessions.issue(
      clientFingerprint: 'cd' * 32,
      clientDeviceId: 'dev-b',
      clientName: 'Phone B',
    );
    // A download stream of that client is running.
    final body = StreamController<int>();
    final unregister = sessions.registerStream(
      s.session.sessionId,
      body.stream.listen((_) {}),
    );
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Stop sharing?'), findsOneWidget);
    await tester.tap(find.text('Keep sharing'));
    await tester.pumpAndSettle();
    expect(server.stops, 0);
    expect(find.text('Sharing'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('share-stop-confirm')),
        matching: find.text('Stop sharing'),
      ),
    );
    await tester.pumpAndSettle();
    expect(server.stops, 1);
    expect(find.text('Sharing'), findsNothing);
    unregister();
    sessions.clear();
    unawaited(body.close());
  });

  testWidgets('Q8: a client without a heartbeat for 20 s shows as '
      'disconnected; a request shows it connected again', (tester) async {
    var clock = DateTime(2026, 11, 4, 12);
    final sessions = ClientSessionStore(clock: () => clock);
    await pump(tester, sessions: sessions);
    await openShare(tester);
    final s = sessions.issue(
      clientFingerprint: 'cd' * 32,
      clientDeviceId: 'dev-b',
      clientName: 'Phone B',
    );
    await tester.pumpAndSettle();
    expect(find.text('Connected: Phone B'), findsOneWidget);
    clock = clock.add(const Duration(seconds: 25));
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Disconnected: Phone B'), findsOneWidget);
    expect(find.text('Connected: Phone B'), findsNothing);
    sessions.verify(s.token);
    await tester.pumpAndSettle();
    expect(find.text('Connected: Phone B'), findsOneWidget);
    sessions.clear();
  });

  testWidgets('Q8: with notifications denied the share screen does not '
      'promise a notification', (tester) async {
    final bg = FakeBackground()..notifications = false;
    await pump(tester, stopsInBackground: true, background: bg);
    await openShare(tester);
    final hint = find.text(
      'Sharing keeps running when you leave the app. Notifications are off '
      'for KFM, so come back here to stop it.',
    );
    await expectNote(tester, hint);
    expect(find.textContaining('from the notification'), findsNothing);
  });

  testWidgets('N5b: leaving the share screen stops the service', (
    tester,
  ) async {
    final bg = FakeBackground();
    await pump(tester, stopsInBackground: true, background: bg);
    await openShare(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(server.stops, 1);
    expect(bg.stops, 1);
  });

  testWidgets('N5b: when the system refuses the service, going to the '
      'background stops sharing (N5 rule)', (tester) async {
    final bg = FakeBackground()..refuse = true;
    await pump(tester, stopsInBackground: true, background: bg);
    await openShare(tester);
    expect(server.isRunning, isTrue);
    final hint = find.text(
      'Sharing stops when you leave this screen or the app.',
    );
    await expectNote(tester, hint);
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pumpAndSettle();
    expect(server.isRunning, isFalse);
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  });

  test('a stop while starting shuts the late server down', () async {
    final server = FakeServer(FakeIdentity());
    final container = ProviderContainer(
      overrides: [
        shareServerProvider.overrideWithValue(server),
        appDatabaseProvider.overrideWithValue(
          AppDatabase(NativeDatabase.memory()),
        ),
      ],
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

  testWidgets('N4: Choose folder… → chooser; whole storage needs a '
      'confirmation; Allow changes makes the root writable', (tester) async {
    final app = await pump(tester);
    await openShare(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).last);
    unawaited(
      showSharedFoldersPicker(
        nav.context,
        clientFingerprint: 'fp',
        clientName: 'Phone B',
      ),
    );
    await tester.pumpAndSettle();
    // Chooser: dot/Android-data folders never listed (fs filters), Music
    // picked after browsing down and up.
    await tester.tap(find.byKey(const ValueKey('shared-folders-choose')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a folder'), findsOneWidget);
    await tester.tap(find.text('DCIM'));
    await tester.pumpAndSettle();
    expect(find.text('Camera'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('chooser-up')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Music'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('chooser-share-this')));
    await tester.pumpAndSettle();
    const music = '/storage/emulated/0/Music';
    expect(find.byKey(const ValueKey('shared-folder-$music')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('shared-folder-write-$music')));
    await tester.pumpAndSettle();

    // Whole storage: cancel keeps it out, confirm adds it.
    await tester.tap(find.byKey(const ValueKey('shared-folders-choose')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('chooser-share-this')));
    await tester.pumpAndSettle();
    expect(find.text('Share all your files?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('All storage'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('shared-folders-choose')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('chooser-share-this')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('whole-storage-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('All storage'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('shared-folders-done')));
    await tester.pumpAndSettle();
    final roots = app.container
        .read(shareScopeStoreProvider)
        .scopeOf('fp')
        .roots;
    expect(roots.map((r) => (r.path, r.readOnly)), [
      (music, false),
      ('/storage/emulated/0', true),
    ]);
  });

  Future<KnownDeviceRow?> rowOf(WidgetTester tester, TestApp app) async {
    await tester.runAsync(
      () => app.container.read(dbWriteQueueProvider).flush(),
    );
    return await tester.runAsync<KnownDeviceRow?>(
      () =>
          (app.db.select(app.db.knownDevices)
                ..where((d) => d.publicKeyFingerprint.equals('cd' * 32)))
              .getSingleOrNull(),
    );
  }

  testWidgets('N6: accept dialog has "Remember this device" (on) and '
      '"Always allow this device" (off, needs Remember); Accept saves the '
      'device and the picker saves its folders', (tester) async {
    final app = await pump(tester);
    await openShare(tester);
    final gate = app.container.read(acceptGateProvider);
    final decision = gate.open(request('r1'))!;
    await tester.pumpAndSettle();
    final remember = find.byKey(const ValueKey('accept-remember'));
    final always = find.byKey(const ValueKey('accept-always-allow'));
    expect(find.text('Remember this device'), findsOneWidget);
    expect(find.text('Always allow this device'), findsOneWidget);
    expect(tester.widget<CheckboxListTile>(remember).value, isTrue);
    expect(tester.widget<CheckboxListTile>(always).value, isFalse);
    // Without Remember, Always allow is off and disabled.
    await tester.tap(remember);
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(always).enabled, isFalse);
    await tester.tap(remember);
    await tester.pump();
    await tester.tap(always);
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(always).value, isTrue);
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(await decision, ConnectionDecision.accepted);

    var row = await rowOf(tester, app);
    expect(row!.name, 'Phone B');
    expect(row.peerDeviceId, 'dev-b');
    expect(row.autoAccept, isTrue);
    expect(row.canShareToUs, isFalse);

    // The picker's folders are stored for next time.
    const camera = '/storage/emulated/0/DCIM';
    await tester.tap(find.byKey(const ValueKey('shared-folder-$camera')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shared-folders-done')));
    await tester.pumpAndSettle();
    row = await rowOf(tester, app);
    expect(
      row!.allowedRootsJson,
      '[{"path":"$camera","label":"Camera","readOnly":true}]',
    );
  });

  testWidgets('N6: with Remember unchecked nothing is saved', (tester) async {
    final app = await pump(tester);
    await openShare(tester);
    final gate = app.container.read(acceptGateProvider);
    final decision = gate.open(request('r1'))!;
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('accept-remember')));
    await tester.pump();
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(await decision, ConnectionDecision.accepted);
    expect(await rowOf(tester, app), isNull);
    await tester.tap(find.byKey(const ValueKey('shared-folders-done')));
    await tester.pumpAndSettle();
    expect(await rowOf(tester, app), isNull);
  });

  testWidgets('N6: a remembered device with stored folders skips the picker '
      '("Sharing 1 folder · Change"); a missing folder is reported', (
    tester,
  ) async {
    final app = await pump(tester);
    final repo = app.container.read(knownDevicesRepositoryProvider);
    await tester.runAsync(() async {
      await repo.saveAfterPairing(
        PairedPeer(
          fingerprint: 'cd' * 32,
          peerDeviceId: 'dev-b',
          name: 'Phone B',
          platform: 'android',
        ),
        temporary: false,
      );
      await repo.setAllowedRoots('cd' * 32, const [
        SharedRoot(
          id: 'old',
          path: '/storage/emulated/0/DCIM',
          label: 'Camera',
          readOnly: true,
        ),
      ]);
    });
    await openShare(tester);
    final gate = app.container.read(acceptGateProvider);
    final d1 = gate.open(request('r1', remembered: true))!;
    await tester.pumpAndSettle();
    expect(find.text('Phone B (remembered) wants to connect'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(await d1, ConnectionDecision.accepted);
    expect(find.byType(SharedFoldersPicker), findsNothing);
    expect(find.text('Sharing 1 folder'), findsOneWidget);
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    expect(find.byType(SharedFoldersPicker), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // The stored folder is gone: hint, and the picker opens.
    await tester.runAsync(
      () => repo.setAllowedRoots('cd' * 32, const [
        SharedRoot(
          id: 'old',
          path: '/storage/emulated/0/Gone',
          label: 'Gone',
          readOnly: true,
        ),
      ]),
    );
    final d2 = gate.open(request('r2', remembered: true))!;
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(await d2, ConnectionDecision.accepted);
    expect(find.byType(SharedFoldersPicker), findsOneWidget);
    expect(find.text('Some shared folders no longer exist'), findsOneWidget);
  });

  testWidgets('N6: an "Always allow" connect shows "<name> connected" '
      'without a dialog', (tester) async {
    final app = await pump(tester);
    await openShare(tester);
    final gate = app.container.read(acceptGateProvider);
    expect(gate.autoAccept(request('r1', remembered: true)), isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(AcceptDialog), findsNothing);
    expect(find.text('Phone B connected'), findsOneWidget);
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
