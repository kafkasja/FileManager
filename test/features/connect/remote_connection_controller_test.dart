import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';

import 'fake_remote_http.dart';

void main() {
  late ProviderContainer container;
  late FakeRemoteHttp http;
  late List<RemoteConnectionState> states;

  RemoteConnectionController ctl() =>
      container.read(remoteConnectionControllerProvider.notifier);
  RemoteConnectionState state() =>
      container.read(remoteConnectionControllerProvider);
  int beats() => http.calls.where((c) => c.path == ApiRoutes.session).length;

  void connect({List<RootDto> roots = const []}) => ctl().connect(
    PairingSuccess(
      http: http,
      accepted: PairAcceptedDto(token: 't', serverDeviceId: 's', roots: roots),
      peerName: 'Phone A',
      peerFingerprint: 'ab' * 32,
    ),
  );

  setUp(() {
    container = ProviderContainer(
      overrides: [remoteFollowsAppLifecycleProvider.overrideWithValue(false)],
    );
    states = [];
    // Keeps the provider listened (Riverpod 3 pauses unlistened ones).
    container.listen(
      remoteConnectionControllerProvider,
      (_, next) => states.add(next),
    );
    http = FakeRemoteHttp()
      ..bearerToken = 't'
      ..on('GET', ApiRoutes.session, (_) => const {})
      ..on('GET', ApiRoutes.roots, (_) => const {'roots': <Object?>[]})
      ..on('POST', ApiRoutes.sessionClose, (_) => const {});
  });
  tearDown(() => container.dispose());

  DisconnectReason? reason() => switch (state()) {
    RemoteDisconnected(:final reason) => reason,
    _ => null,
  };

  void expectTornDown() {
    expect(ctl().http, isNull);
    expect(http.bearerToken, isNull);
    expect(http.closed, isTrue);
  }

  test('beats every 5 s with the token; roots refresh while empty, then '
      'every 3rd beat', () {
    fakeAsync((async) {
      connect();
      expect(state(), isA<RemoteConnected>());
      async.elapse(const Duration(seconds: 4));
      expect(beats(), 0);
      async.elapse(const Duration(seconds: 1));
      expect(beats(), 1);
      expect(http.calls.first.token, 't');
      async.elapse(const Duration(seconds: 10));
      expect(beats(), 3);
      // Empty roots: re-read after every beat.
      expect(http.calls.where((c) => c.path == ApiRoutes.roots).length, 3);
      http.on(
        'GET',
        ApiRoutes.roots,
        (_) => const {
          'roots': [
            {'id': 'r', 'label': 'Camera', 'readOnly': true},
          ],
        },
      );
      async.elapse(const Duration(seconds: 5));
      expect((state() as RemoteConnected).roots.single.label, 'Camera');
      final before = http.calls.where((c) => c.path == ApiRoutes.roots).length;
      async.elapse(const Duration(seconds: 15));
      expect(
        http.calls.where((c) => c.path == ApiRoutes.roots).length,
        before + 1,
      );
    });
  });

  test('401 → unauthorized; token dropped, client closed, no more beats', () {
    fakeAsync((async) {
      connect();
      http.fail('GET', ApiRoutes.session, ApiErrorCode.unauthorized);
      async.elapse(const Duration(seconds: 5));
      expect(reason(), DisconnectReason.unauthorized);
      expect((state() as RemoteDisconnected).peerName, 'Phone A');
      expectTornDown();
      final n = http.calls.length;
      async.elapse(const Duration(seconds: 20));
      expect(http.calls.length, n);
    });
  });

  test('network errors: each tick retries once; 3 failed ticks → '
      'networkLost; one success resets the count', () {
    fakeAsync((async) {
      connect();
      http.failAll = const RemoteUnavailableException(
        RemoteUnavailableReason.network,
      );
      async.elapse(const Duration(seconds: 10));
      expect(beats(), 4); // 2 ticks × (try + retry)
      expect(state(), isA<RemoteConnected>());
      http.failAll = null;
      async.elapse(const Duration(seconds: 5));
      http.failAll = const RemoteUnavailableException(
        RemoteUnavailableReason.timeout,
      );
      async.elapse(const Duration(seconds: 10));
      expect(state(), isA<RemoteConnected>());
      async.elapse(const Duration(seconds: 5));
      expect(reason(), DisconnectReason.networkLost);
      expectTornDown();
    });
  });

  test('connection refused → the other device stopped sharing', () {
    fakeAsync((async) {
      connect();
      http.failAll = const RemoteUnavailableException(
        RemoteUnavailableReason.refused,
      );
      async.elapse(const Duration(seconds: 5));
      expect(reason(), DisconnectReason.remoteStopped);
      expectTornDown();
    });
  });

  test('a hanging beat times out after 4 s and overlapping beats are '
      'skipped', () {
    fakeAsync((async) {
      connect();
      http.on(
        'GET',
        ApiRoutes.session,
        (_) => Future.delayed(const Duration(minutes: 1), () => const {}),
      );
      async.elapse(const Duration(seconds: 5));
      expect(beats(), 1);
      async.elapse(const Duration(seconds: 4));
      // The 4 s timeout fired: the retry is running now.
      expect(beats(), 2);
      async.elapse(const Duration(seconds: 1));
      // Tick at 10 s skipped: the retry still runs.
      expect(beats(), 2);
    });
  });

  test('background stops the heartbeat; resume beats at once', () {
    fakeAsync((async) {
      connect();
      ctl().onLifecycle(AppLifecycleState.inactive);
      async.elapse(const Duration(seconds: 5));
      expect(beats(), 1);
      ctl().onLifecycle(AppLifecycleState.hidden);
      async.elapse(const Duration(seconds: 30));
      expect(beats(), 1);
      ctl().onLifecycle(AppLifecycleState.resumed);
      async.flushMicrotasks();
      expect(beats(), 2);
      async.elapse(const Duration(seconds: 5));
      expect(beats(), 3);
    });
  });

  test('Disconnect sends session/close and ends as userClosed; app exit '
      'sends close too', () {
    fakeAsync((async) {
      connect();
      unawaited(ctl().disconnect());
      async.flushMicrotasks();
      expect(http.calls.last.path, ApiRoutes.sessionClose);
      expect(reason(), DisconnectReason.userClosed);
      expectTornDown();

      http = FakeRemoteHttp()
        ..bearerToken = 't'
        ..on('POST', ApiRoutes.sessionClose, (_) => const {});
      connect();
      ctl().onLifecycle(AppLifecycleState.detached);
      async.flushMicrotasks();
      expect(http.calls.single.path, ApiRoutes.sessionClose);
    });
  });

  test('a new connection replaces the old one (old one is closed)', () {
    fakeAsync((async) {
      connect();
      final old = http;
      http = FakeRemoteHttp()..bearerToken = 't2';
      connect();
      async.flushMicrotasks();
      expect(old.closed, isTrue);
      expect(old.calls.last.path, ApiRoutes.sessionClose);
      expect(ctl().http, same(http));
    });
  });

  test('reportUnauthorized (e.g. from the media proxy) ends the link', () {
    connect();
    ctl().reportUnauthorized();
    expect(reason(), DisconnectReason.unauthorized);
    expectTornDown();
  });

  test('every disconnect closes the media proxy, clears thumbnails and '
      'bumps the epoch', () async {
    connect();
    final proxy = await ctl().mediaProxy();
    expect(proxy.port, isNotNull);
    expect(await ctl().mediaProxy(), same(proxy));
    final cache = container.read(remoteThumbnailCacheProvider)
      ..put('k', Uint8List(10));
    final epoch = ctl().epoch;
    ctl().reportUnauthorized();
    expect(cache.length, 0);
    expect(ctl().epoch, epoch + 1);
    await expectLater(ctl().mediaProxy(), throwsStateError);
  });

  test('PinnedClient maps a refused connect to `refused`', () async {
    final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = s.port;
    await s.close();
    final client = PinnedClient.pinned(
      Uri.parse('https://127.0.0.1:$port'),
      'ab' * 32,
    );
    addTearDown(client.close);
    await expectLater(
      client.getJson<void>(ApiRoutes.session, decode: (_) {}),
      throwsA(
        isA<RemoteUnavailableException>().having(
          (e) => e.reason,
          'reason',
          RemoteUnavailableReason.refused,
        ),
      ),
    );
  });
}
