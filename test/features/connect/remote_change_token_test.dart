import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';

import 'fake_remote_http.dart';

void main() {
  late ProviderContainer container;
  late FakeRemoteHttp http;
  late Map<String, Object?> session;

  RemoteConnectionController ctl() =>
      container.read(remoteConnectionControllerProvider.notifier);
  String? token() => container.read(remoteChangeTokenProvider);

  setUp(() {
    container =
        ProviderContainer(
            overrides: [
              remoteFollowsAppLifecycleProvider.overrideWithValue(false),
            ],
          )
          ..listen(remoteConnectionControllerProvider, (_, _) {})
          ..listen(remoteChangeTokenProvider, (_, _) {});
    session = const {};
    http = FakeRemoteHttp()
      ..bearerToken = 't'
      ..on('GET', ApiRoutes.session, (_) => session)
      ..on('GET', ApiRoutes.roots, (_) => const {'roots': <Object?>[]})
      ..on('POST', ApiRoutes.sessionClose, (_) => const {});
    ctl().connect(
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
  });
  tearDown(() async {
    await ctl().disconnect();
    container.dispose();
  });

  test('the heartbeat publishes the change token', () async {
    expect(token(), isNull);
    session = const {'changeToken': 'a1'};
    await ctl().beat();
    expect(token(), 'a1');
    session = const {'changeToken': 'b2'};
    await ctl().beat();
    expect(token(), 'b2');
  });

  test('204 / empty body (older server) is still a good beat', () async {
    session = const {};
    for (var i = 0; i < 4; i++) {
      await ctl().beat();
    }
    expect(
      container.read(remoteConnectionControllerProvider),
      isA<RemoteConnected>(),
    );
    expect(token(), isNull);
    // A malformed token is ignored, not a failed beat.
    session = const {'changeToken': 5};
    for (var i = 0; i < 4; i++) {
      await ctl().beat();
    }
    expect(
      container.read(remoteConnectionControllerProvider),
      isA<RemoteConnected>(),
    );
  });

  test('the token is dropped on disconnect', () async {
    session = const {'changeToken': 'a1'};
    await ctl().beat();
    await ctl().disconnect();
    expect(token(), isNull);
  });
}
