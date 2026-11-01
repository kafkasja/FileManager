import 'dart:io';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/features/connect/data/accept_gate.dart';
import 'package:kfm/features/connect/data/camera_access.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/device_identity_repository_impl.dart';
import 'package:kfm/features/connect/data/discovery.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/pair_nonce_store.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/data/pairing_secret_store.dart';
import 'package:kfm/features/connect/data/routes/pair_routes.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/device_identity.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connect_providers.g.dart';

/// Secure storage for the device identity (TASK-N1).
@Riverpod(keepAlive: true)
SecretStore secretStore(Ref ref) => PlatformSecretStore();

/// The device model, the default share name. Android: maker + model;
/// elsewhere the host name.
@Riverpod(keepAlive: true)
Future<String> deviceModelName(Ref ref) async {
  try {
    if (Platform.isAndroid) {
      final model = (await FilesChannel().deviceModel()).trim();
      if (model.isNotEmpty) return model;
    }
    return Platform.localHostname;
  } on Object {
    return 'KFM';
  }
}

/// The name other devices see: `connect.displayName`, or the device model
/// when it is empty.
Future<String> resolveShareDisplayName(Ref ref) async {
  final custom =
      (await ref
              .read(settingsRepositoryProvider)
              .read(AppSettings.connectDisplayName))
          .trim();
  if (custom.isNotEmpty) return custom;
  return await ref.read(deviceModelNameProvider.future);
}

/// 'android' | 'windows' | 'ios'.
String get currentPlatformName => Platform.operatingSystem;

@Riverpod(keepAlive: true)
DeviceIdentityRepository deviceIdentityRepository(Ref ref) =>
    DeviceIdentityRepositoryImpl(
      store: ref.watch(secretStoreProvider),
      displayName: () => resolveShareDisplayName(ref),
      platform: currentPlatformName,
    );

/// This install's identity; generated on first use (in an isolate).
@Riverpod(keepAlive: true)
Future<DeviceIdentity> deviceIdentity(Ref ref) =>
    ref.watch(deviceIdentityRepositoryProvider).loadOrCreate();

/// Pair nonces of the current sharing run (N2, N6).
@Riverpod(keepAlive: true)
PairNonceStore pairNonceStore(Ref ref) => PairNonceStore();

/// QR secret + short code of the current sharing run (N2).
@Riverpod(keepAlive: true)
PairingSecretStore pairingSecretStore(Ref ref) {
  final store = PairingSecretStore();
  ref.onDispose(store.clear);
  return store;
}

/// The pending accept decision of the current sharing run (N3).
@Riverpod(keepAlive: true)
AcceptGate acceptGate(Ref ref) {
  final gate = AcceptGate();
  ref.onDispose(gate.cancelAll);
  return gate;
}

/// Bearer-token sessions of the current sharing run (N3).
@Riverpod(keepAlive: true)
ClientSessionStore clientSessionStore(Ref ref) {
  final store = ClientSessionStore();
  ref.onDispose(store.clear);
  return store;
}

/// The request the accept dialog shows (N3); null when none.
@Riverpod(keepAlive: true)
class PendingRequest extends _$PendingRequest {
  @override
  ConnectionRequest? build() {
    final gate = ref.watch(acceptGateProvider);
    final sub = gate.events.listen((_) => state = gate.pending);
    ref.onDispose(sub.cancel);
    return gate.pending;
  }

  /// The dialog's answer.
  void decide(String requestId, ConnectionDecision decision) =>
      ref.read(acceptGateProvider).decide(requestId, decision);
}

/// Clients with a live session, oldest first (share screen list).
@riverpod
Stream<List<ClientSession>> connectedClients(Ref ref) async* {
  final store = ref.watch(clientSessionStoreProvider);
  yield store.sessions;
  yield* store.changes;
}

/// What happens to a verified pairing request: the accept prompt (N3).
@Riverpod(keepAlive: true)
PairHandOff pairHandOff(Ref ref) => promptHandOff(
  gate: ref.watch(acceptGateProvider),
  sessions: ref.watch(clientSessionStoreProvider),
  serverDeviceId: () async =>
      (await ref.read(deviceIdentityRepositoryProvider).loadOrCreate())
          .deviceId,
);

/// mDNS advertise + browse (N2).
@Riverpod(keepAlive: true)
ShareDiscovery shareDiscovery(Ref ref) => NsdShareDiscovery();

/// Nearby sharing devices while the Connect screen lists them.
@riverpod
Stream<List<NearbyDevice>> nearbyDevices(Ref ref) =>
    ref.watch(shareDiscoveryProvider).browse();

/// The connecting side of pairing (N2).
@Riverpod(keepAlive: true)
PairingClient pairingClient(Ref ref) =>
    PairingClient(identity: ref.watch(deviceIdentityRepositoryProvider));

/// Camera permission for "Scan QR".
@Riverpod(keepAlive: true)
CameraAccess cameraAccess(Ref ref) => const PlatformCameraAccess();

/// Every route the share server serves. N2/N3/N4/N7/N10 append theirs here.
@Riverpod(keepAlive: true)
List<ServerRoute> shareServerRoutes(Ref ref) {
  final identity = ref.watch(deviceIdentityRepositoryProvider);
  return [
    ...coreRoutes(
      info: () async {
        final id = await identity.loadOrCreate();
        return ServerInfoDto(
          deviceId: id.deviceId,
          name: id.displayName,
          platform: id.platform,
          fingerprint: id.fingerprint,
          protocolVersion: kProtocolVersion,
        );
      },
      nonces: ref.watch(pairNonceStoreProvider),
    ),
    ...pairRoutes(
      secrets: ref.watch(pairingSecretStoreProvider),
      nonces: ref.watch(pairNonceStoreProvider),
      handOff: (candidate) => ref.read(pairHandOffProvider)(candidate),
    ),
    pairCancelRoute(ref.watch(acceptGateProvider)),
  ];
}

@Riverpod(keepAlive: true)
ShareServer shareServer(Ref ref) {
  final server = ShareServer(
    ref.watch(deviceIdentityRepositoryProvider),
    (served) => buildSharePipeline(
      served: served,
      routes: ref.read(shareServerRoutesProvider),
      authenticate: authenticate(ref.read(clientSessionStoreProvider)),
    ),
  );
  ref.onDispose(server.stop);
  return server;
}
